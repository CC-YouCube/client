--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
Client Version: 0.0.poc0
]]

-- Libraries - OpenLibrarieLoader v1.0.0 --

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

local youcubeapi = libs.youcubeapi.new()
youcubeapi:detect_bestest_server()

-------------------------------

-- https://github.com/Vexatos/Computronics/blob/b0ade53cab10529dbe91ebabfa882d1b4b21fa90/src/main/resources/assets/computronics/lua/peripheral/tape_drive/programs/tape_drive/tape#L109-L123
local function wipe()
    local size = tape.getSize()
    tape.stop()
    tape.seek(-size)
    tape.stop()
    tape.seek(-90000)
    local s = string.rep(string.char(170), 8192)
    for i = 1, size + 8191, 8192 do
        tape.write(s)
    end
    tape.seek(-size)
    tape.seek(-90000)
end

-------------------------------

local function run(url, no_close)
    print("Requesting media ...")
    youcubeapi:request_media(url)

    local data = youcubeapi.websocket.receive()
    data = textutils.unserialiseJSON(data)

    if data.action == "error" then
        error(data.message)
    end

    local id = data.id

    local chunkindex = 0

    youcubeapi:get_chunk(chunkindex, id)

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

    if speaker then
        local dfpwm = require("cc.audio.dfpwm")
        local decoder = dfpwm.make_decoder()

        while true do
            local chunk = youcubeapi.websocket.receive()

            if chunk == "mister, the media has finished playing" then
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

            local buffer = decoder(chunk)

            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end

            chunkindex = chunkindex + 1

            term.setCursorPos(x, y)
            term.write("Chunkindex: ")
            term.setTextColor(colors.gray)
            term.write(chunkindex)
            term.setTextColor(colors.white)

            youcubeapi:get_chunk(chunkindex, id)

        end
    else
        tape.stop()
        tape.seek(-tape.getSize())
        wipe()
        tape.setLabel(data.title)

        while true do
            local chunk = youcubeapi.websocket.receive()

            if chunk == "mister, the media has finished playing" then
                tape.seek(-tape.getSize())
                tape.play()
                print()

                -- getState 0.2.1 allow 0.1.0
                while tape.getState() == "PLAYING" do
                    os.pullEvent("speaker_audio_empty")
                end

                if data.playlist_videos then
                    return data.playlist_videos
                end

                if no_close then
                    return
                end

                youcubeapi.websocket.close()
                return
            end

            tape.write(chunk)

            chunkindex = chunkindex + 1

            term.setCursorPos(x, y)
            term.write("Chunkindex: ")
            term.setTextColor(colors.gray)
            term.write(chunkindex)
            term.setTextColor(colors.white)

            youcubeapi:get_chunk(chunkindex, id)
        end
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
