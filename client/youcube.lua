--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
]]

local _VERSION = "0.0.0-poc.0.0.2"

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

local libs = { "youcubeapi", "numberformatter", "semver" }
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


-- update check --


local function get_versions()
    local url = "https://raw.githubusercontent.com/Commandcracker/YouCube/main/versions.json"

    -- Check if the URL is valid
    local ok, err = http.checkURL(url)
    if not ok then
        printError("Invalid Update URL.", "\"" .. url .. "\" ", err)
        return
    end

    local response, http_err = http.get(url, nil, true)
    if not response then
        printError("Failed to retreat data from update URL. \"" .. url .. "\" (" .. http_err .. ")")
        return
    end

    local sResponse = response.readAll()
    response.close()

    return textutils.unserialiseJSON(sResponse)
end

local function write_outdated(current, latest)
    if libs.semver(current) ^ libs.semver(latest) then
        term.setTextColor(colors.yellow)
    else
        term.setTextColor(colors.red)
    end

    term.write(current)
    term.setTextColor(colors.lightGray)
    term.write(" -> ")
    term.setTextColor(colors.lime)
    term.write(latest)
    term.setTextColor(colors.white)
end

local function can_update(name, current, latest)
    if libs.semver(current) < libs.semver(latest) then
        term.write(name .. " ")

        write_outdated(current, latest)
        print()
    end
end

local function update_checker()
    local versions = get_versions()
    if versions == nil then return end

    can_update(
        "youcube",
        _VERSION,
        versions.client.version
    )
    can_update(
        "youcubeapi",
        libs.youcubeapi._VERSION,
        versions.client.libraries.youcubeapi.version
    )
    can_update(
        "numberformatter",
        libs.numberformatter._VERSION,
        versions.client.libraries.numberformatter.version
    )
    can_update(
        "semver",
        tostring(libs.semver._VERSION),
        versions.client.libraries.semver.version
    )

    local handshake = youcubeapi:handshake()

    if libs.semver(handshake.server.version) < libs.semver(versions.server.version) then
        print("Tell the server owner to update their server!")
        write_outdated(handshake.server.version, versions.server.version)
        print()
    end

    if not libs.semver(libs.youcubeapi._API_VERSION) ^ libs.semver(handshake.api.version) then
        print("Client is not compatible with server")
        term.setTextColor(colors.red)
        term.write(libs.youcubeapi._API_VERSION)
        term.setTextColor(colors.lightGray)
        term.write(" ^ ")
        term.setTextColor(colors.red)
        term.write(handshake.api.version)
        term.setTextColor(colors.white)
        print()
    end

    if libs.semver(libs.youcubeapi._API_VERSION) < libs.semver(versions.api.version) then
        print("Your client is using an outdated API version")
        write_outdated(libs.youcubeapi._API_VERSION, versions.api.version)
        print()
    end

    if libs.semver(handshake.api.version) < libs.semver(versions.api.version) then
        print("The server is using an outdated API version")
        write_outdated(libs.youcubeapi._API_VERSION, versions.api.version)
        print()
    end
end

update_checker()

local function play_audio(buffer, title)
    --[[
    local chunkindex = 0

    local x, y = term.getCursorPos()
    term.write("Chunkindex: ")
    term.setTextColor(colors.gray)
    term.write(chunkindex)
    term.setTextColor(colors.white)
    ]]

    audiodevice:reset()
    audiodevice:setLabel(title)

    while true do
        local chunk = buffer:next()

        -- Adjust buffer size on first chunk
        if buffer.filler.chunkindex == 1 then
            buffer.size = math.ceil(1024 / (#chunk / 16))
        end

        if chunk == "" then
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

        --[[
        term.setCursorPos(x, y)
        term.write("Chunkindex: ")
        term.setTextColor(colors.gray)
        term.write(chunkindex)
        term.setTextColor(colors.white)
        ]]

    end
end

local function play(url)
    print("Requesting media ...")
    youcubeapi:request_media(url) --  term.getSize()

    local data
    local x, y = term.getCursorPos()

    repeat
        data = youcubeapi:receive()
        if data.action == "status" then
            term.setCursorPos(x, y)
            term.clearLine()
            term.write("Status: ")
            term.setTextColor(colors.green)
            term.write(data.message)
            term.setTextColor(colors.white)
        else
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

    local video_buffer = libs.youcubeapi.Buffer.new(
        libs.youcubeapi.VideoFiller.new(
            youcubeapi,
            data.id,
            term.getSize()
        ),
        --[[
            Most videos run on 30 fps, so we store 2s of video.
        ]]
        60
    )

    local audio_buffer = libs.youcubeapi.Buffer.new(
        libs.youcubeapi.AudioFiller.new(
            youcubeapi,
            data.id
        ),
        --[[
            We want to buffer 1024 chunks.
            One chunks is 16 bits.
            The server (with default settings) sends 32 chunks at once.
        ]]
        32
    )

    parallel.waitForAny(
        function()
            -- Fill Buffers
            while true do
                os.queueEvent("buffer_audio_and_video")
                os.pullEvent()

                audio_buffer:fill()
                --term.clear()
                --term.setCursorPos(1, 1)
                --print(#audio_buffer.buffer)
                --print(audio_buffer.buffer[1])
                --print(audio_buffer.buffer[2])

                --video_buffer:fill()
            end
        end,
        function()
            parallel.waitForAll(
            --function()
            --    libs.youcubeapi.play_vid(video_buffer)
            --end,
                function()
                    play_audio(audio_buffer, data.title)
                end
            )
        end
    )

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
