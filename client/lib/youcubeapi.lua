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

local servers = {
    "ws://localhost:5000",
    "ws://oxygen.knijn.one:5000", -- By EmmaKnijn, Contact EmmaKnijn#0043 on Discord if this doesn't work
    "wss://youcube.onrender.com" -- By Commandcracker
}

if settings then
    local server = settings.get("youcube.server")
    if server then
        table.insert(servers, 1, server)
    end
end

--- Connects to a YouCub Server
function API:detect_bestest_server()
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
function API:get_vid(line, id, width, height)
    self:send({
        ["action"] = "get_vid",
        ["line"]   = line,
        ["id"]     = id,
        ["width"]  = width * 2,
        ["height"] = height * 3
    })
    return self:receive("vid").line
end

--- Request media
-- @tparam string url Url or Search Term
--@treturn table json response
function API:request_media(url, width, height)
    self:send({
        ["action"] = "request_media",
        ["url"]    = url,
        ["width"]  = width * 2,
        ["height"] = height * 3
    })
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

    return self
end

--[[- AudioDevice from a Speaker
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
-- @treturn AudioDevice instance
function Speaker.new(speaker)
    local self = AudioDevice.new { speaker = speaker }

    function self:validate()
        if not decoder then
            error("This ComputerCraft version dos not support DFPWM")
        end
    end

    function self:write(chunk)
        local buffer = decoder(chunk)
        while not self.speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end

    return self
end

--[[- AudioDevice from a [Computronics tape_drive](https://wiki.vexatos.com/wiki:computronics:tape)
    @type Tape
    @usage Example:

        local youcubeapi  = require("youcubeapi")
        local tape_drive  = peripheral.find("tape_drive")
        local audiodevice = youcubeapi.Tape.new(tape_drive)
]]
local Tape = {}

--- Create's a new Tape instance.
-- @tparam tape tape The tape_drive
-- @treturn AudioDevice instance
function Tape.new(tape)
    local self = AudioDevice.new { tape = tape }

    function self:validate()
        if not self.tape.isReady() then
            error("You need to insert a tape")
        end
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

return {
    --- "Metadata" - [YouCube API](https://commandcracker.github.io/YouCube/) Version
    _API_VERSION = "0.0.0-poc.0.0.0",
    --- "Metadata" - Library Version
    _VERSION     = "0.0.0-poc.0.0.0",
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
    Base64       = Base64
}
