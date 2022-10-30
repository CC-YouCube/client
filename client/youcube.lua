--[[
_  _ _  _ _  _ ___  ____ ____              
|\ | |  | |\/| |__] |___ |__/              
| \| |__| |  | |__] |___ |  \              
____ ____ ____ _  _ ____ ___ ___ ____ ____ 
|___ |  | |__/ |\/| |__|  |   |  |___ |__/ 
|    |__| |  \ |  | |  |  |   |  |___ |  \ 
]]

local NumberFormatter = {}
-- https://devforum.roblox.com/t/how-can-i-turn-a-number-to-a-shorter-number-i-dont-know-how-to-explain-click-to-understand-3/649496/3

local Suffixes = { "k", "M", "B", "T", "qd", "Qn", "sx", "Sp", "O", "N", "de", "Ud", "DD", "tdD", "qdD", "QnD", "sxD",
    "SpD", "OcD", "NvD", "Vgn", "UVg", "DVg", "TVg", "qtV", "QnV", "SeV", "SPG", "OVG", "NVG", "TGN", "UTG", "DTG",
    "tsTG", "qtTG", "QnTG", "ssTG", "SpTG", "OcTG", "NoTG", "QdDR", "uQDR", "dQDR", "tQDR", "qdQDR", "QnQDR", "sxQDR",
    "SpQDR", "OQDDr", "NQDDr", "qQGNT", "uQGNT", "dQGNT", "tQGNT", "qdQGNT", "QnQGNT", "sxQGNT", "SpQGNT", "OQQGNT",
    "NQQGNT", "SXGNTL" }

function NumberFormatter.compact(number)
    local Negative = number < 0
    number = math.abs(number)

    local Paired = false
    for i in pairs(Suffixes) do
        if not (number >= 10 ^ (3 * i)) then
            number = number / 10 ^ (3 * (i - 1))
            local isComplex = string.find(tostring(number), ".") and string.sub(tostring(number), 4, 4) ~= "."
            number = string.sub(tostring(number), 1, isComplex and 4 or 3) .. (Suffixes[i - 1] or "")
            Paired = true
            break
        end
    end
    if not Paired then
        local Rounded = math.floor(number)
        number = tostring(Rounded)
    end
    if Negative then
        return "-" .. number
    end
    return number -- returns 1.0k for example
end

function NumberFormatter.abbreviate(number)
    local left, num, right = string.match(number, '^([^%d]*%d)(%d*)(.-)$')
    return left .. num:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. right -- returns for example 1,000, it gets every 3 zeros and adds a  comma
end

--[[
_   _ ____ _  _ ____ _  _ ___  ____ ____ ___  _ 
 \_/  |  | |  | |    |  | |__] |___ |__| |__] | 
  |   |__| |__| |___ |__| |__] |___ |  | |    | 
]]

local YouCubeAPI = {}

function YouCubeAPI.new(websocket)
    return setmetatable({
        websocket = websocket,
    }, { __index = YouCubeAPI })
end

local servers = {
    "ws://localhost:5000",
    "ws://oxygen.knijn.one:5000", -- By EmmaKnijn, Contact EmmaKnijn#0043 on Discord if this doesn't work
    "wss://youcube.onrender.com"
}

if settings then
    local server = settings.get("youcube.server")
    if server then
        table.insert(servers, 1, server)
    end
end

function YouCubeAPI:detect_bestest_server()
    for i, server in pairs(servers) do
        local websocket, websocket_error = http.websocket(server)

        if websocket ~= false then
            term.write("Using the YouCube server: ")
            term.setTextColor(colors.blue)
            print(server)
            term.setTextColor(colors.white)
            self.websocket = websocket
            break
        elseif i == #servers then
            error(websocket_error)
        end

    end
end

function YouCubeAPI:get_chunk(chunkindex, id)
    self.websocket.send(textutils.serialiseJSON({
        ["action"] = "get_chunk",
        ["chunkindex"] = chunkindex,
        ["id"] = id
    }))
end

function YouCubeAPI:request_media(url)
    --local status, retval = pcall(self.websocket.send, textutils.serialiseJSON({
    self.websocket.send(textutils.serialiseJSON({
        ["action"] = "request_media",
        ["url"] = url
    }))

    --if not status then
    --    print("Lost connection to server -> Reconnection ...")
    --    self:detect_bestest_server()
    --    self:request_media(url)
    --end
end

--[[
_  _ ____ _ _  _    ____ _    _ 
|\/| |__| | |\ |    |    |    | 
|  | |  | | | \|    |___ |___ | 
]]

if periphemu then -- CraftOS-PC
    periphemu.create("top", "speaker")
end

local speaker = peripheral.find("speaker")
local tape = peripheral.find("tape_drive")

if speaker == nil and tape == nil then
    error("You need a tapedrive or speaker in order to use YouCube!")
end

local youcubeapi = YouCubeAPI.new()
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
        print("Likes: " .. NumberFormatter.compact(data.like_count))
    end

    if data.view_count then
        print("Views: " .. NumberFormatter.compact(data.view_count))
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
