--[[
_   _ ____ _  _ ____ _  _ ___  ____
 \_/  |  | |  | |    |  | |__] |___
  |   |__| |__| |___ |__| |__] |___

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
]]

local _VERSION = "0.0.0-poc.1.1.1"

-- Libraries - OpenLibrarieLoader v1.0.1 --

--TODO: Optional libs:
-- For something like a JSON lib that is only needed for older CC Versions or
-- optional logging.lua support

local function is_lib(libs, lib)
    for i = 1, #libs do
        local value = libs[i]
        if value == lib or value .. ".lua" == lib then
            return true, value
        end
    end
    return false
end

local libs = { "youcubeapi", "numberformatter", "semver", "argparse", "string_pack" }
local lib_paths = { ".", "./lib", "./apis", "./modules", "/", "/lib", "/apis", "/modules" }

-- LevelOS Support
if _G.lOS then
    lib_paths[#lib_paths + 1] = "/Program_Files/YouCube/lib"
end

local function load_lib(lib)
    if require then
        return require(lib:gsub(".lua", ""))
    end
    return dofile(lib)
end

for i_path = 1, #lib_paths do
    local path = lib_paths[i_path]
    if fs.exists(path) then
        local files = fs.list(path)
        for i_file = 1, #files do
            local found, lib = is_lib(libs, files[i_file])
            if found and lib ~= nil and libs[lib] == nil then
                libs[lib] = load_lib(path .. "/" .. files[i_file])
            end
        end
    end
end

for i = 1, #libs do
    local lib = libs[i]
    if libs[lib] == nil then
        error(('Library "%s" not found.'):format(lib))
    end
end

-- args --

local function get_program_name()
    if arg then
        return arg[0]
    end
    return fs.getName(shell.getRunningProgram()):gsub("[\\.].*$", "")
end

-- stylua: ignore start

local parser = libs.argparse {
    help_max_width = ({ term.getSize() })[1],
    name = get_program_name()
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

parser:flag "--sh" "--shuffle"
    :description "Shuffles audio before playing"
    :target "shuffle"
    :action "store_true"

parser:flag "-l" "--loop"
    :description "Loops the media."
    :target "loop"
    :action "store_true"

parser:flag "--lp" "--loop-playlist"
    :description "Loops the playlist."
    :target "loop_playlist"
    :action "store_true"

parser:option "--fps"
    :description "Force sanjuuni to use a specified frame rate"
    :target "force_fps"

-- stylua: ignore end

local args = parser:parse({ ... })

if args.force_fps then
    args.force_fps = tonumber(args.force_fps)
end

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

local function get_audiodevices()
    local audiodevices = {}

    local speakers = { peripheral.find("speaker") }
    for i = 1, #speakers do
        audiodevices[#audiodevices + 1] = libs.youcubeapi.Speaker.new(speakers[i])
    end

    local tapes = { peripheral.find("tape_drive") }
    for i = 1, #tapes do
        audiodevices[#audiodevices + 1] = libs.youcubeapi.Tape.new(tapes[i])
    end

    if #audiodevices == 0 then
        -- Disable audio when no audiodevice is found
        args.no_audio = true
        return audiodevices
    end

    -- Validate audiodevices
    local last_error
    local valid_audiodevices = {}

    for i = 1, #audiodevices do
        local audiodevice = audiodevices[i]
        local _error = audiodevice:validate()
        if _error == nil then
            valid_audiodevices[#valid_audiodevices + 1] = audiodevice
        else
            last_error = _error
        end
    end

    if #valid_audiodevices == 0 then
        error(last_error)
    end

    return valid_audiodevices
end

-- main --

local youcubeapi = libs.youcubeapi.API.new()
local audiodevices = get_audiodevices()

-- update check --

local function get_versions()
    local url = "https://raw.githubusercontent.com/CC-YouCube/installer/main/versions.json"

    -- Check if the URL is valid
    local ok, err = http.checkURL(url)
    if not ok then
        printError("Invalid Update URL.", '"' .. url .. '" ', err)
        return
    end

    local response, http_err = http.get(url, nil, true)
    if not response then
        printError('Failed to retreat data from update URL. "' .. url .. '" (' .. http_err .. ")")
        return
    end

    local sResponse = response.readAll()
    response.close()

    return textutils.unserialiseJSON(sResponse)
end

local function write_colored(text, color)
    term.setTextColor(color)
    term.write(text)
end

local function new_line()
    local w, h = term.getSize()
    local x, y = term.getCursorPos()
    if y + 1 <= h then
        term.setCursorPos(1, y + 1)
    else
        term.setCursorPos(1, h)
        term.scroll(1)
    end
end

local function write_outdated(current, latest)
    if libs.semver(current) ^ libs.semver(latest) then
        term.setTextColor(colors.yellow)
    else
        term.setTextColor(colors.red)
    end

    term.write(current)
    write_colored(" -> ", colors.lightGray)
    write_colored(latest, colors.lime)
    term.setTextColor(colors.white)
    new_line()
end

local function can_update(name, current, latest)
    if libs.semver(current) < libs.semver(latest) then
        term.write(name .. " ")
        write_outdated(current, latest)
    end
end

local function update_checker()
    local versions = get_versions()
    if versions == nil then
        return
    end

    can_update("youcube", _VERSION, versions.client.version)
    can_update("youcubeapi", libs.youcubeapi._VERSION, versions.client.libraries.youcubeapi.version)
    can_update("numberformatter", libs.numberformatter._VERSION, versions.client.libraries.numberformatter.version)
    can_update("semver", tostring(libs.semver._VERSION), versions.client.libraries.semver.version)
    can_update("argparse", libs.argparse.version, versions.client.libraries.argparse.version)

    local handshake = youcubeapi:handshake()

    if libs.semver(handshake.server.version) < libs.semver(versions.server.version) then
        print("Tell the server owner to update their server!")
        write_outdated(handshake.server.version, versions.server.version)
    end

    if not libs.semver(libs.youcubeapi._API_VERSION) ^ libs.semver(handshake.api.version) then
        print("Client is not compatible with server")
        write_colored(libs.youcubeapi._API_VERSION, colors.red)
        write_colored(" ^ ", colors.lightGray)
        write_colored(handshake.api.version, colors.red)
        term.setTextColor(colors.white)
        new_line()
    end

    if libs.semver(libs.youcubeapi._API_VERSION) < libs.semver(versions.api.version) then
        print("Your client is using an outdated API version")
        write_outdated(libs.youcubeapi._API_VERSION, versions.api.version)
    end

    if libs.semver(handshake.api.version) < libs.semver(versions.api.version) then
        print("The server is using an outdated API version")
        write_outdated(libs.youcubeapi._API_VERSION, versions.api.version)
    end
end

local function play_audio(buffer, title)
    for i = 1, #audiodevices do
        local audiodevice = audiodevices[i]
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
            for i = 1, #audiodevices do
                local audiodevice = audiodevices[i]
                play_functions[#play_functions + 1] = function()
                    audiodevice:play()
                end
            end

            parallel.waitForAll(table.unpack(play_functions))
            return
        end

        local write_functions = {}
        for i = 1, #audiodevices do
            local audiodevice = audiodevices[i]
            table.insert(write_functions, function()
                audiodevice:write(chunk)
            end)
        end

        parallel.waitForAll(table.unpack(write_functions))
    end
end

-- #region playback controll vars
local back_buffer = {}
local max_back = settings.get("youcube.max_back") or 32
local queue = {}
local restart = false
-- #endregion

-- keys
local skip_key = settings.get("youcube.keys.skip") or keys.d
local restart_key = settings.get("youcube.keys.restart") or keys.r
local back_key = settings.get("youcube.keys.back") or keys.a

local function play(url)
    restart = false
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
            os.queueEvent("youcube:status", data)
            term.setCursorPos(x, y)
            term.clearLine()
            term.write("Status: ")
            write_colored(data.message, colors.green)
            term.setTextColor(colors.white)
        else
            new_line()
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
        libs.youcubeapi.VideoFiller.new(youcubeapi, data.id, term.getSize()),
        60 -- Most videos run on 30 fps, so we store 2s of video.
    )

    local audio_buffer = libs.youcubeapi.Buffer.new(
        libs.youcubeapi.AudioFiller.new(youcubeapi, data.id),
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

    local function fill_buffers()
        while true do
            os.queueEvent("youcube:fill_buffers")

            local event = os.pullEventRaw()

            if event == "terminate" then
                libs.youcubeapi.reset_term()
            end

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
    end

    local function _play_video()
        if not args.no_video then
            local string_unpack
            if not string.unpack then
                string_unpack = libs.string_pack.unpack
            end

            os.queueEvent("youcube:vid_playing", data)
            libs.youcubeapi.play_vid(video_buffer, args.force_fps, string_unpack)
            os.queueEvent("youcube:vid_eof", data)
        end
    end

    local function _play_audio()
        if not args.no_audio then
            os.queueEvent("youcube:audio_playing", data)
            play_audio(audio_buffer, data.title)
            os.queueEvent("youcube:audio_eof", data)
        end
    end

    local function _play_media()
        os.queueEvent("youcube:playing")
        parallel.waitForAll(_play_video, _play_audio)
    end

    local function _hotkey_handler()
        while true do
            local _, key = os.pullEvent("key")

            if key == skip_key then
                back_buffer[#back_buffer + 1] = url --finished playing, push the value to the back buffer
                if #back_buffer > max_back then
                    back_buffer[1] = nil --remove it from the front of the buffer
                end
                if not args.no_video then
                    libs.youcubeapi.reset_term()
                end
                break
            end

            if key == restart_key then
                queue[#queue + 1] = url --add the current song to upcoming
                if not args.no_video then
                    libs.youcubeapi.reset_term()
                end
                restart = true
                break
            end
        end
    end

    parallel.waitForAny(fill_buffers, _play_media, _hotkey_handler)

    if data.playlist_videos then
        return data.playlist_videos
    end
end

local function shuffle_playlist(playlist)
    local shuffled = {}
    for i = 1, #queue do
        local pos = math.random(1, #shuffled + 1)
        shuffled[pos] = queue[i]
    end
    return shuffled
end

local function play_playlist(playlist)
    queue = playlist
    if args.shuffle then
        queue = shuffle_playlist(queue)
    end
    while #queue ~= 0 do
        local pl = table.remove(queue)

        local function handle_back_hotkey()
            while true do
                local _, key = os.pullEvent("key")
                if key == back_key then
                    queue[#queue + 1] = pl --add the current song to upcoming
                    local prev = table.remove(back_buffer)
                    if prev then --nil/false check
                        queue[#queue + 1] = prev --add previous song to upcoming
                    end
                    if not args.no_video then
                        libs.youcubeapi.reset_term()
                    end
                    break
                end
            end
        end

        parallel.waitForAny(handle_back_hotkey, function()
            play(pl) --play the url
        end)
    end
end

local function main()
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

    while restart do
        play(args.URL)
    end

    youcubeapi.websocket.close()

    if not args.no_video then
        libs.youcubeapi.reset_term()
    end

    os.queueEvent("youcube:playback_ended")
end

main()
