--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
Client Version: poc0.0.0
]]

-- Libraries - OpenLibrarieLoader v1.0.0 --
--TODO: Optional libs - for something like JSON lib that is only needed for older CC Versions

local function is_lib(Table, Item)
    for key, value in ipairs(Table) do
        if value == Item or value .. ".lua" == Item then
            return true, value
        end
    end
    return false
end

local libs = { "youcubeapi", "numberformatter" }
local lib_paths = { ".", "./lib", "./apis", "./modules", "/", "/lib", "/apis", "/modules" }

if _G.lOS then
    table.insert(lib_paths, "/Program_Files/YouCube/lib")
end

for i, path in pairs(lib_paths) do
    if fs.exists(path) then
        for _i, file_name in pairs(fs.list(path)) do
            local found, lib = is_lib(libs, file_name)
            if found and libs[lib] == nil then
                if require then
                    libs[lib] = require(path .. "/" .. file_name:gsub(".lua", ""))
                else
                    libs[lib] = dofile(path .. "/" .. file_name)
                end
            end
        end
    end
end

for key, lib in ipairs(libs) do
    if libs[lib] == nil then
        error("Library \"" .. lib .. "\" not found")
    end
end

-- CraftOS-PC support --

if periphemu then
    periphemu.create("top", "speaker")
end

-- main --

local speaker = peripheral.find("speaker")
local tape = peripheral.find("tape_drive")

if speaker == nil and tape == nil then
    error("You need a tapedrive or speaker in order to use YouCube!")
end

local youcubeapi = libs.youcubeapi.API.new()

local audiodevice

if speaker == nil then
    audiodevice = libs.youcubeapi.Tape.new(tape)
else
    audiodevice = libs.youcubeapi.Speaker.new(speaker)
end

audiodevice:validate()
youcubeapi:detect_bestest_server()

local function run(url, no_close)
    print("Requesting media ...")
    local data = youcubeapi:request_media(url)

    if data.action == "error" then
        error(data.message)
    end

    local chunkindex = 0

    term.write("Playing: ")
    term.setTextColor(colors.lime)
    print(data.title)
    term.setTextColor(colors.white)

    if data.like_count then
        print("Likes: " .. libs.numberformatter.compact(data.like_count))
    end

    if data.view_count then
        print("Views: " .. libs.numberformatter.compact(data.view_count))
    end

    local x, y = term.getCursorPos()
    term.write("Chunkindex: ")
    term.setTextColor(colors.gray)
    term.write(chunkindex)
    term.setTextColor(colors.white)

    audiodevice:reset()
    audiodevice:setLabel(data.title)

    while true do
        local chunk = youcubeapi:get_chunk(chunkindex, data.id)

        if chunk == "mister, the media has finished playing" then
            audiodevice:play()
            print()

            if data.playlist_videos then
                return data.playlist_videos
            end

            if no_close then
                return
            end

            youcubeapi.websocket.close()
            return
        end

        audiodevice:write(chunk)

        chunkindex = chunkindex + 1

        term.setCursorPos(x, y)
        term.write("Chunkindex: ")
        term.setTextColor(colors.gray)
        term.write(chunkindex)
        term.setTextColor(colors.white)

        youcubeapi:get_chunk(chunkindex, data.id)

    end
end

print("Enter Url or Search Term:")
term.setTextColor(colors.lightGray)
local _url = read()
term.setTextColor(colors.white)

local playlist_videos = run(_url)

if playlist_videos then
    for i, id in pairs(playlist_videos) do
        run(id, true)
    end
end
