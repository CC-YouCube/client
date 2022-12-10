--[[- Lua library for accessing [YouCub's API](https://commandcracker.github.io/YouCube/)
    @module youcubeapi
]]

--[[ youcubeapi.lua
_   _ ____ _  _ ____ _  _ ___  ____ ____ ___  _
 \_/  |  | |  | |    |  | |__] |___ |__| |__] |
  |   |__| |__| |___ |__| |__] |___ |  | |    |
]]

--[[- "wrapper" for accessing [YouCub's API](https://commandcracker.github.io/YouCube/)
    @type API
    @usage Example:

        local youcubeapi  = require("youcubeapi")
        local api         = youcubeapi.API.new()
        api:detect_bestest_server()
        api:request_media(url)
        local data = api.websocket.receive()
]]
local API = {}

--- Create's a new API instance.
-- @param websocket [Websocket](https://tweaked.cc/module/http.html#ty:Websocket) The websocket.
-- @treturn API instance
function API.new(websocket)
    return setmetatable({
        websocket = websocket,
    }, { __index = API })
end

-- Look at the [Documentation](https://commandcracker.github.io/YouCube/) for moor information
local servers = {
    "ws://127.0.0.1:5000", -- Your server!
    "wss://youcube.knijn.one", -- By EmmaKnijn, Contact EmmaKnijn#0043 on Discord if this doesn't work
    "ws://lithium.knijn.one:5000", -- Insecure version of "wss://youcube.knijn.one", Dont Contact Emma if this doesn't work!
    "ws://oxygen.knijn.one:5000", -- By EmmaKnijn, Dont Contact! This is an old sever, use the server above!
    "wss://youcube.onrender.com" -- By Commandcracker, Contact Commandcracker#8528 on Discord, when the server is down
}

if settings then
    local server = settings.get("youcube.server")
    if server then
        table.insert(servers, 1, server)
    end
end

local function websocket_with_timeout(_url, _headers, _timeout)
    if http.websocketAsync then
        local websocket, websocket_error = http.websocketAsync(_url, _headers)
        if not websocket then
            return false, websocket_error
        end

        local timerID = os.startTimer(_timeout)

        while true do
            local event, param1, param2 = os.pullEvent()

            -- TODO: Close web-socket when the connection succeeds after the timeout
            if event == "websocket_success" and param1 == _url then
                return param2
            elseif event == "websocket_failure" and param1 == _url then
                return false, param2
            elseif event == "timer" and param1 == timerID then
                return false, "Timeout"
            end
        end
    end

    -- use websocket without timeout
    -- when the CC version dos not support websocketAsync
    return http.websocket(_url, _headers)
end

--- Connects to a YouCub Server
function API:detect_bestest_server(_server, _verbose)

    if _server then table.insert(servers, 1, _server) end

    for i, server in pairs(servers) do
        local ok, err = http.checkURL(server:gsub("^ws://", "http://"):gsub("^wss://", "https://"))

        if ok then
            if _verbose then
                print("Trying to connect to:", server)
            end
            local websocket, websocket_error = websocket_with_timeout(server, nil, 5)

            if websocket ~= false then
                term.write("Using the YouCube server: ")
                term.setTextColor(colors.blue)
                print(server)
                term.setTextColor(colors.white)
                self.websocket = websocket
                break
            elseif i == #servers then
                error(websocket_error)
            elseif _verbose then
                print(websocket_error)
            end
        elseif i == #servers then
            error(err)
        elseif _verbose then
            print(err)
        end
    end
end

--- Receive data from The YouCub Server
-- @tparam string filter action filter
-- @treturn table retval data
function API:receive(filter)
    local status, retval = pcall(
        self.websocket.receive
    )
    if not status then
        print("Lost connection to server -> Reconnection ...")
        self:detect_bestest_server()
        return self:receive(filter)
    end

    local data = textutils.unserialiseJSON(retval)

    if data == nil then
        error("Failed to parse message")
    end

    if filter then
        --if type(filter) == "table" then
        --    if not filter[data.action] then
        --        return self:receive(filter)
        --    end
        --else
        if data.action ~= filter then
            return self:receive(filter)
        end
    end

    return data
end

--- Send data to The YouCub Server
-- @tparam table data data to send
function API:send(data)
    local status, retval = pcall(
        self.websocket.send,
        textutils.serialiseJSON(data)
    )
    if not status then
        print("Lost connection to server -> Reconnection ...")
        self:detect_bestest_server()
        self:send(data)
    end
end

--[[- [Base64](https://wikipedia.org/wiki/Base64) functions
    @type Base64
]]
local Base64 = {}

local b64str = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- based on https://github.com/MCJack123/sanjuuni/blob/c64f8725a9f24dec656819923457717dfb964515/raw-player.lua
--- Decode base64 string
-- @tparam string str base64 string
-- @treturn string string decoded string
function Base64.decode(str)
    local retval = ""
    for s in str:gmatch "...." do
        if s:sub(3, 4) == '==' then
            retval = retval ..
                string.char(bit32.bor(bit32.lshift(b64str:find(s:sub(1, 1)) - 1, 2),
                    bit32.rshift(b64str:find(s:sub(2, 2)) - 1, 4)))
        elseif s:sub(4, 4) == '=' then
            local n = (b64str:find(s:sub(1, 1)) - 1) * 4096 + (b64str:find(s:sub(2, 2)) - 1) * 64 +
                (b64str:find(s:sub(3, 3)) - 1)
            retval = retval .. string.char(bit32.extract(n, 10, 8)) .. string.char(bit32.extract(n, 2, 8))
        else
            local n = (b64str:find(s:sub(1, 1)) - 1) * 262144 + (b64str:find(s:sub(2, 2)) - 1) * 4096 +
                (b64str:find(s:sub(3, 3)) - 1) * 64 + (b64str:find(s:sub(4, 4)) - 1)
            retval = retval ..
                string.char(bit32.extract(n, 16, 8)) ..
                string.char(bit32.extract(n, 8, 8)) .. string.char(bit32.extract(n, 0, 8))
        end
    end
    return retval
end

--- Request a `16 * 1024` bit chunk
-- @tparam number chunkindex The chunkindex
-- @tparam string id Media id
-- @treturn bytes chunk `16 * 1024` bit chunk
function API:get_chunk(chunkindex, id)
    self:send({
        ["action"]     = "get_chunk",
        ["chunkindex"] = chunkindex,
        ["id"]         = id
    })
    return Base64.decode(self:receive("chunk").chunk)
end

--- Get 32vid
-- @tparam number line The line to return
-- @tparam string id Media id
-- @tparam number width Video width
-- @tparam number height Video height
-- @treturn string line one line of the given 32vid
function API:get_vid(tracker, id, width, height)
    self:send({
        ["action"]  = "get_vid",
        ["tracker"] = tracker,
        ["id"]      = id,
        ["width"]   = width * 2,
        ["height"]  = height * 3
    })
    return self:receive("vid")
end

--- Request media
-- @tparam string url Url or Search Term
--@treturn table json response
function API:request_media(url, width, height)
    local request = {
        ["action"] = "request_media",
        ["url"]    = url
    }
    if width and height then
        request.width  = width * 2
        request.height = height * 3
    end
    self:send(request)
    --return self:receive({ ["media"] = true, ["status"] = true })
end

--- Handshake - get Server capabilities and version
--@treturn table json response
function API:handshake()
    self:send({
        ["action"] = "handshake"
    })
    return self:receive("handshake")
end

--[[- Abstraction for Audio Devices
    @type AudioDevice
]]
local AudioDevice = {}

--- Create's a new AudioDevice instance.
-- @tparam table object Base values
-- @treturn AudioDevice instance
function AudioDevice.new(object)
    -- @type AudioDevice
    local self = object or {}

    function self:validate() end

    function self:setLabel(lable) end

    function self:write(chunk) end

    function self:play() end

    function self:reset() end

    function self:setVolume(volume) end

    return self
end

--[[- @{AudioDevice} from a Speaker
    @type Speaker
    @usage Example:

        local youcubeapi  = require("youcubeapi")
        local speaker     = peripheral.find("speaker")
        local audiodevice = youcubeapi.Speaker.new(speaker)
]]
local Speaker = {}

local decoder
local status, dfpwm = pcall(require, "cc.audio.dfpwm")

if status then
    decoder = dfpwm.make_decoder()
end

--- Create's a new Tape instance.
-- @tparam speaker speaker The speaker
-- @treturn AudioDevice|Speaker instance
function Speaker.new(speaker)
    local self = AudioDevice.new { speaker = speaker }

    function self:validate()
        if not decoder then
            error("This ComputerCraft version dos not support DFPWM")
        end
    end

    function self:setVolume(volume)
        self.volume = volume
    end

    function self:write(chunk)
        local buffer = decoder(chunk)
        while not self.speaker.playAudio(buffer, self.volume) do
            os.pullEvent("speaker_audio_empty")
        end
    end

    return self
end

--[[- @{AudioDevice} from a [Computronics tape_drive](https://wiki.vexatos.com/wiki:computronics:tape)
    @type Tape
    @usage Example:

        local youcubeapi  = require("youcubeapi")
        local tape_drive  = peripheral.find("tape_drive")
        local audiodevice = youcubeapi.Tape.new(tape_drive)
]]
local Tape = {}

--- Create's a new Tape instance.
-- @tparam tape tape The tape_drive
-- @treturn AudioDevice|Tape instance
function Tape.new(tape)
    local self = AudioDevice.new { tape = tape }

    function self:validate()
        if not self.tape.isReady() then
            error("You need to insert a tape")
        end
    end

    function self:setVolume(volume)
        self.tape.setVolume(volume)
    end

    function self:play(chunk)
        self.tape.seek(-self.tape.getSize())
        self.tape.play()
    end

    function self:write(chunk)
        self.tape.write(chunk)
    end

    function self:setLabel(lable)
        self.tape.setLabel(lable)
    end

    function self:reset()
        -- based on https://github.com/Vexatos/Computronics/blob/b0ade53cab10529dbe91ebabfa882d1b4b21fa90/src/main/resources/assets/computronics/lua/peripheral/tape_drive/programs/tape_drive/tape#L109-L123
        local size = self.tape.getSize()
        self.tape.stop()
        self.tape.seek(-size)
        self.tape.stop()
        self.tape.seek(-90000)
        local s = string.rep(string.char(170), 8192)
        for i = 1, size + 8191, 8192 do
            self.tape.write(s)
        end
        self.tape.seek(-size)
        self.tape.seek(-90000)
    end

    return self
end

--[[- Abstract object for filling a @{Buffer}
    @type Filler
]]
local Filler = {}

--- Create's a new Filler instance.
-- @treturn Filler instance
function Filler.new()
    local self = {}
    function self:next() end

    return self
end

--[[- @{Filler} for Audio
    @type AudioFiller
]]
local AudioFiller = {}

--- Create's a new AudioFiller instance.
-- @tparam API youcubeapi API object
-- @tparam string id Media id
-- @treturn AudioFiller|Filler instance
function AudioFiller.new(youcubeapi, id)
    local self = {
        id         = id,
        chunkindex = 0,
        youcubeapi = youcubeapi
    }

    function self:next()
        local response = self.youcubeapi:get_chunk(self.chunkindex, self.id)
        self.chunkindex = self.chunkindex + 1
        return response
    end

    return self
end

--[[- @{Filler} for Video
    @type VideoFiller
]]
local VideoFiller = {}

--- Create's a new VideoFiller instance.
-- @tparam API youcubeapi API object
-- @tparam string id Media id
-- @tparam number width Video width
-- @tparam number height Video height
-- @treturn VideoFiller|Filler instance
function VideoFiller.new(youcubeapi, id, width, height)
    local self = {
        id         = id,
        width      = width,
        height     = height,
        tracker    = 0,
        youcubeapi = youcubeapi
    }

    function self:next()
        local response = self.youcubeapi:get_vid(self.tracker, self.id, self.width, self.height)
        for _, line in pairs(response.lines) do
            self.tracker = self.tracker + #line + 1
        end
        return response.lines
    end

    return self
end

--[[- Buffers Data
    @type Buffer
]]
local Buffer = {}

--- Create's a new Buffer instance.
-- @tparam Filler filler filler instance
-- @tparam number size buffer limit
-- @treturn Buffer instance
function Buffer.new(filler, size)
    local self = {
        filler = filler,
        size   = size
    }
    self.buffer = {}

    function self:next()
        while #self.buffer == 0 do os.pullEvent() end -- Wait until next is available
        local next = self.buffer[1]
        table.remove(self.buffer, 1)
        return next
    end

    function self:fill()
        if #self.buffer < self.size then
            local next = filler:next()
            if type(next) == "table" then
                for _, line in pairs(next) do
                    table.insert(self.buffer, line)
                end
            else
                table.insert(self.buffer, next)
            end
            return true
        end
        return false
    end

    return self
end

--[[- Create's a new Buffer instance.

    Based on [sanjuuni/raw-player.lua](https://github.com/MCJack123/sanjuuni/blob/c64f8725a9f24dec656819923457717dfb964515/raw-player.lua)
    and [sanjuuni/websocket-player.lua](https://github.com/MCJack123/sanjuuni/blob/30dcabb4b56f1eb32c88e1bce384b0898367ebda/websocket-player.lua)
    @tparam Buffer buffer filled with frames
]]
local function play_vid(buffer)
    local Fwidth, Fheight = term.getSize()
    local tracker = 0

    if buffer:next() ~= "32Vid 1.1" then
        error("Unsupported file")
    end

    local fps = tonumber(buffer:next())
    -- Adjust buffer size
    buffer.size = math.ceil(fps) * 2

    local first, second = buffer:next(), buffer:next()

    if second == "" or second == nil then
        fps = 0
    end
    term.clear()

    local start = os.epoch "utc"
    local frame_count = 0
    while true do
        frame_count = frame_count + 1
        local frame
        if first then
            frame, first = first, nil
        elseif second then
            frame, second = second, nil
        else
            frame = buffer:next()
        end
        if frame == "" or frame == nil then
            break
        end
        local mode = frame:match("^!CP([CD])")
        if not mode then
            error("Invalid file")
        end
        local b64data
        if mode == "C" then
            local len = tonumber(frame:sub(5, 8), 16)
            b64data = frame:sub(9, len + 8)
        else
            local len = tonumber(frame:sub(5, 16), 16)
            b64data = frame:sub(17, len + 16)
        end
        local data = Base64.decode(b64data)
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
                if n == 0 then
                    c, n, pos = string.unpack("c1B", data, pos)
                end
            end
        end
        c = c:byte()
        for y = 1, height do
            local fg, bg = "", ""
            for x = 1, width do
                fg, bg = fg .. ("%x"):format(bit32.band(c, 0x0F)), bg .. ("%x"):format(bit32.rshift(c, 4))
                n = n - 1
                if n == 0 then
                    c, n, pos = string.unpack("BB", data, pos)
                end
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
        if fps == 0 then
            read()
            break
        else
            while os.epoch "utc" < start + (frame_count + 1) / fps * 1000 do sleep(1 / fps) end
        end
    end
    for i = 0, 15 do
        term.setPaletteColor(2 ^ i, term.nativePaletteColor(2 ^ i))
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

return {
    --- "Metadata" - [YouCube API](https://commandcracker.github.io/YouCube/) Version
    _API_VERSION = "0.0.0-poc.1.0.0",
    --- "Metadata" - Library Version
    _VERSION     = "0.0.0-poc.1.0.0",
    --- "Metadata" - Description
    _DESCRIPTION = "Library for accessing YouCub's API",
    --- "Metadata" - Homepage / Url
    _URL         = "https://github.com/Commandcracker/YouCube",
    --- "Metadata" - License
    _LICENSE     = "GPL-3.0",
    API          = API,
    AudioDevice  = AudioDevice,
    Speaker      = Speaker,
    Tape         = Tape,
    Base64       = Base64,
    Filler       = Filler,
    AudioFiller  = AudioFiller,
    VideoFiller  = VideoFiller,
    Buffer       = Buffer,
    play_vid     = play_vid
}
