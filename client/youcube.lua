--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
]]

local _VERSION = "0.0.0-poc.0.3.0"

-- Libraries - OpenLibrarieLoader v1.0.0 --

--TODO: Optional libs
-- For something like a JSON lib that is only needed for older CC Versions or
-- optional logging.lua support

local function is_lib(Table, Item)
    for key, value in ipairs(Table) do
        if value == Item or value .. ".lua" == Item then
            return true, value
        end
    end
    return false
end

local libs = { "youcubeapi", "numberformatter", "semver", "argparse" }
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

-- args --

local program_name
if arg then
    program_name = arg[0]
else
    program_name = fs.getName(shell.getRunningProgram()):gsub("[\\.].*$", "")
end

local parser = libs.argparse {
    help_max_width = ({ term.getSize() })[1],
    help_usage_margin = 1,
    help_description_margin = 23,
    name = program_name
}
    :description "Official YouCube client for accessing media from services like YouTube"

parser:argument "URL"
    :args "*"
    :description "URL or search term."

parser:flag "-v" "--verbose"
    :description "Enables verbose output."
    :target "verbose"
    :action "store_true"

parser:option "-V" "--volume"
    :description "Sets the volume of the audio. A value from 0-100"
    :target "volume"

parser:option "-s" "--server"
    :description "The server that YC should use."
    :target "server"
    :args(1)

parser:flag "--nv" "--no-video"
    :description "Disables video."
    :target "no_video"
    :action "store_true"

parser:flag "--na" "--no-audio"
    :description "Disables audio."
    :target "no_audio"
    :action "store_true"

parser:flag "-l" "--loop"
    :description "Loops the media."
    :target "loop"
    :action "store_true"

parser:flag "--lp" "--loop-playlist"
    :description "Loops the playlist."
    :target "loop_playlist"
    :action "store_true"

local args = parser:parse { ... }

if args.volume then
    args.volume = tonumber(args.volume)
    if args.volume == nil then
        parser:error("Volume must be a number")
    end

    if args.volume > 100 then
        parser:error("Volume cant be over 100")
    end

    if args.volume < 0 then
        parser:error("Volume cant be below 0")
    end
    args.volume = args.volume / 100
end

if #args.URL > 0 then
    args.URL = table.concat(args.URL, " ")
else
    args.URL = nil
end

if args.no_video and args.no_audio then
    parser:error("Nothing will happen, when audio and video is disabled!")
end

-- CraftOS-PC support --

if periphemu then
    periphemu.create("top", "speaker")
    -- Fuck the max websocket message police
    config.set("http_max_websocket_message", 2 ^ 30)
end

-- main --

local speakers = { peripheral.find("speaker") }
local tapes = { peripheral.find("tape_drive") }

if #speakers == 0 and #tapes == 0 then
    error("You need a tapedrive or speaker in order to use YouCube!")
end

local youcubeapi = libs.youcubeapi.API.new()

local audiodevices = {}

if #speakers == 0 then
    for _, tape in pairs(tapes) do
        table.insert(audiodevices, libs.youcubeapi.Tape.new(tape))
    end
else
    for _, speaker in pairs(speakers) do
        table.insert(audiodevices, libs.youcubeapi.Speaker.new(speaker))
    end
end

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
    can_update(
        "argparse",
        libs.argparse.version,
        versions.client.libraries.argparse.version
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

local function play_audio(buffer, title)
    for _, audiodevice in pairs(audiodevices) do
        audiodevice:reset()
        audiodevice:setLabel(title)
        audiodevice:setVolume(args.volume)
    end

    while true do
        local chunk = buffer:next()

        -- Adjust buffer size on first chunk
        if buffer.filler.chunkindex == 1 then
            buffer.size = math.ceil(1024 / (#chunk / 16))
        end

        if chunk == "" then
            local play_functions = {}
            for _, audiodevice in pairs(audiodevices) do
                table.insert(play_functions, function()
                    audiodevice:play()
                end)
            end

            parallel.waitForAll(table.unpack(play_functions))
            return
        end

        local write_functions = {}
        for _, audiodevice in pairs(audiodevices) do
            table.insert(write_functions, function()
                audiodevice:write(chunk)
            end)
        end

        parallel.waitForAll(table.unpack(write_functions))
    end
end

local function play(url)
    print("Requesting media ...")

    if not args.no_video then
        youcubeapi:request_media(url, term.getSize())
    else
        youcubeapi:request_media(url)
    end

    local data
    local x, y = term.getCursorPos()

    repeat
        data = youcubeapi:receive()
        if data.action == "status" then
            term.setCursorPos(x, y)
            term.clearLine()
            term.write("Status: ")
            term.setTextColor(colors.green)
            os.queueEvent("youcube:status", data)
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

    if not args.no_video then
        -- wait, that the user can see the video info
        sleep(2)
    end

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

    if args.verbose then
        term.clear()
        term.setCursorPos(1, 1)
        term.write("[DEBUG MODE]")
    end

    parallel.waitForAny(
        function()
            -- Fill Buffers
            while true do
                os.queueEvent("youcube:fill_buffers")
                os.pullEvent()

                if not args.no_audio then
                    audio_buffer:fill()
                end

                if args.verbose then
                    term.setCursorPos(1, ({ term.getSize() })[2])
                    term.clearLine()
                    term.write("Audio_Buffer: " .. #audio_buffer.buffer)
                end

                if not args.no_video then
                    video_buffer:fill()
                end
            end
        end,
        function()
            os.queueEvent("youcube:playing")
            parallel.waitForAll(
                function()
                    if not args.no_video then
                        os.queueEvent("youcube:vid_playing", data)
                        libs.youcubeapi.play_vid(video_buffer)
                        os.queueEvent("youcube:vid_eof", data)
                    end
                end,
                function()
                    if not args.no_audio then
                        os.queueEvent("youcube:audio_playing", data)
                        play_audio(audio_buffer, data.title)
                        os.queueEvent("youcube:audio_eof", data)
                    end
                end
            )
        end
    )

    if data.playlist_videos then
        return data.playlist_videos
    end
end

local function play_playlist(playlist)
    for _, id in pairs(playlist) do
        play(id)
    end
end

local function main()
    for _, audiodevice in pairs(audiodevices) do
        audiodevice:validate()
    end
    youcubeapi:detect_bestest_server(args.server, args.verbose)
    pcall(update_checker)

    if not args.URL then
        print("Enter Url or Search Term:")
        term.setTextColor(colors.lightGray)
        args.URL = read()
        term.setTextColor(colors.white)
    end

    local playlist_videos = play(args.URL)

    if args.loop == true then
        while true do
            play(args.URL)
        end
    end

    if playlist_videos then
        if args.loop_playlist == true then
            while true do
                if playlist_videos then
                    play_playlist(playlist_videos)
                end
            end
        end
        play_playlist(playlist_videos)
    end

    youcubeapi.websocket.close()
    os.queueEvent("youcube:playback_ended")
end

main()
