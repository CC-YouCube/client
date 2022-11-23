--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
Client Version: 0.0.0-poc.0.0.0
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

local function play_audio(data)
    local chunkindex = 0

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

            --if data.playlist_videos then
            --    return data.playlist_videos
            --end

            --if no_close then
            --    return
            --end

            --youcubeapi.websocket.close()
            return
        end

        audiodevice:write(chunk)

        chunkindex = chunkindex + 1

        --[[
        term.setCursorPos(x, y)
        term.write("Chunkindex: ")
        term.setTextColor(colors.gray)
        term.write(chunkindex)
        term.setTextColor(colors.white)
        ]]

    end
end

-- https://github.com/MCJack123/sanjuuni/blob/c64f8725a9f24dec656819923457717dfb964515/raw-player.lua
local function play_vid(id)
    local Fwidth, Fheight = term.getSize()
    local lineindex = 0
    if youcubeapi:get_vid(lineindex, id, Fwidth, Fheight) ~= "32Vid 1.1" then error("Unsupported file") end
    lineindex = lineindex + 1
    local fps = tonumber(youcubeapi:get_vid(lineindex, id, Fwidth, Fheight))
    lineindex = lineindex + 1
    local first, second = youcubeapi:get_vid(lineindex, id, Fwidth, Fheight),
        youcubeapi:get_vid(lineindex + 1, id, Fwidth, Fheight)
    lineindex = lineindex + 2
    if second == "" or second == nil then fps = 0 end
    term.clear()
    while true do
        local frame
        if first then frame, first = first, nil
        elseif second then frame, second = second, nil
        else frame = youcubeapi:get_vid(lineindex, id, Fwidth, Fheight)
            lineindex = lineindex + 1
        end
        if frame == "" or frame == nil then break end
        local mode = frame:match("^!CP([CD])")
        if not mode then error("Invalid file") end
        local b64data
        if mode == "C" then
            local len = tonumber(frame:sub(5, 8), 16)
            b64data = frame:sub(9, len + 8)
        else
            local len = tonumber(frame:sub(5, 16), 16)
            b64data = frame:sub(17, len + 16)
        end
        local data = libs.youcubeapi.Base64.decode(b64data)
        -- TODO: maybe verify checksums?
        assert(data:sub(1, 4) == "\0\0\0\0" and data:sub(9, 16) == "\0\0\0\0\0\0\0\0", "Invalid file")
        local width, height = ("HH"):unpack(data, 5)
        local c, n, pos = string.unpack("c1B", data, 17)
        local text = {}
        for y = 1, height do
            text[y] = ""
            for x = 1, width do
                text[y] = text[y] .. c
                n = n - 1
                if n == 0 then c, n, pos = string.unpack("c1B", data, pos) end
            end
        end
        c = c:byte()
        for y = 1, height do
            local fg, bg = "", ""
            for x = 1, width do
                fg, bg = fg .. ("%x"):format(bit32.band(c, 0x0F)), bg .. ("%x"):format(bit32.rshift(c, 4))
                n = n - 1
                if n == 0 then c, n, pos = string.unpack("BB", data, pos) end
            end
            term.setCursorPos(1, y)
            term.blit(text[y], fg, bg)
        end
        pos = pos - 2
        local r, g, b
        for i = 0, 15 do
            r, g, b, pos = string.unpack("BBB", data, pos)
            term.setPaletteColor(2 ^ i, r / 255, g / 255, b / 255)
        end
        if fps == 0 then read() break
        else sleep(1 / fps) end
    end
    for i = 0, 15 do term.setPaletteColor(2 ^ i, term.nativePaletteColor(2 ^ i)) end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function play(url)
    print("Requesting media ...")
    youcubeapi:request_media(url, term.getSize())

    local data
    local x, y = term.getCursorPos()
    term.setCursorPos(x, y)

    repeat
        data = youcubeapi:receive()
        if data.action == "status" then
            term.setCursorPos(x, y)
            term.clearLine()
            term.write("Status: ")
            term.setTextColor(colors.green)
            term.write(data.message)
            term.setTextColor(colors.white)
            print()
        end
    until data.action == "media"

    if data.action == "error" then
        error(data.message)
    end

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

    -- wait, that the user can see the video info
    sleep(2)

    local function function1()
        play_vid(data.id)
    end

    local function function2()
        play_audio(data)
    end

    parallel.waitForAll(function1, function2)

    if data.playlist_videos then
        return data.playlist_videos
    end
end

print("Enter Url or Search Term:")
term.setTextColor(colors.lightGray)
local _url = read()
term.setTextColor(colors.white)

local playlist_videos = play(_url)

if playlist_videos then
    for i, id in pairs(playlist_videos) do
        play(id)
    end
end
