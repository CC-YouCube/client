local loaded_ld, ld = pcall(require, "LibDeflate")
--options
local opts = {...}
print("[build] #opts "..#opts)
local output = table.remove(opts,1)
print("[build] output_base "..output)
local extract_path = table.remove(opts,1)
print("[build] extraction path "..extract_path)
local files = opts


--to turn a folder into a table
local function gen_disk(ph)
    sleep()
    local path = ph or ""
    local pth = fs.getName(path)
    local tree = {}
    for _,v in pairs(fs.list(path)) do
        if fs.isDir(path.."/"..v) then
            if verbosity > 1 then print("[build] heading down to "..path.."/"..v) end
            tree[v] = gen_disk(path.."/"..v)
        else
            if verbosity > 1 then print("[build] adding "..path.."/"..v) end
            local chandle = fs.open(path.."/"..v,'rb')
            tree[v] = chandle.readAll()
            chandle.close()
        end
    end
    return tree
end
--we require LibDeflate for this (since we make compressed images)
if not loaded_ld then error("Unnable to load LibDeflate"..ld) end
--make sure the minimised and stripped LibDeflate is also here
if not fs.exists(fs.combine(fs.getDir(shell.getRunningProgram()),"LD.lua")) then error("Unnable to locate minified LibDeflate") end
--make sure all paths are valid
print("[build] validating files")
for _,v in ipairs(files) do
    local v = shell.resolve(v)
    if not fs.exists(v) then error("File/Folder does not exist: "..v) end
end
--get the base name for the outputs
local output_base_name = shell.resolve(output)
local final = {}
--add files to the table
print("[build] starting tree gen")
for _,v in ipairs(files) do
    local sr = shell.resolve(v)
    print("[build] adding: "..v)
    if fs.isDir(sr) then
        final[fs.getName(v)] = gen_disk(sr)
    else
        local hand = fs.open(sr,'rb')
        local con = hand.readAll()
        final[fs.getName(v)] = con
        hand.close()
    end
end
--uncompressed serialize (and write)
print("[build] serialising")
local ser = textutils.serialise(final)
print("[build] writing VFS")
local handle = fs.open(output_base_name..".vfs",'wb')
    handle.write(ser)
    handle.close()
print("[build] compressing")
--compress it with Gzip
local compressed = ld:CompressGzip(ser)
print("[build] writing compressed")
local handle = fs.open(output_base_name..".vgz",'wb')
    handle.write(compressed)
    handle.close()
--now make a Self-Extracting-Archive
print("[build] creating Self Extracting Archive")
local output_file = fs.open(output_base_name..".lua",'wb')
output_file.write('local I,c,o,f,C,t,s,D = table.unpack({\nloadstring([=[')
local ldh = fs.open(fs.combine(fs.getDir(shell.getRunningProgram()),"LD.lua"),'rb')
local ldc = ldh.readAll()
output_file.write(ldc)
ldh.close()
output_file.write(']=])()\n,(function()local u,g = fs.open(shell.getRunningProgram(),"rb")g=u.readAll()u.close()return g:match("%[===%[(.+)%]===%]") end)(),shell.resolve(""),fs.open,fs.combine,type,shell.setDir,shell.dir()})\nfunction u(p,z)fs.makeDir(C(o,p))s(C(o,p))for k, v in pairs(z) do if t(v) == "table" then u(p.."/"..k,v)elseif t(v) == "string" then local h = f(fs.combine(o,C(p,k)),"wb")h.write(v)h.close()end end end u("')
output_file.write(extract_path..'",textutils.unserialise(I:d(c)))s(o)')
output_file.write('\n--[===[')
output_file.write(compressed)
output_file.write(']===]')
print("[build] done")