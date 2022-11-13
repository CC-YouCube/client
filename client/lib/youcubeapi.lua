--[[- Lua library for accessing [YouCub's API](https://commandcracker.github.io/YouCube/)
    @module youcubeapi
]]

--[[
_   _ ____ _  _ ____ _  _ ___  ____ ____ ___  _
 \_/  |  | |  | |    |  | |__] |___ |__| |__] |
  |   |__| |__| |___ |__| |__] |___ |  | |    |

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0

Lib Version: poc0.0.0
API Version: 0.0.poc0 (https://commandcracker.github.io/YouCube/)
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
function API:receive()
    local status, retval = pcall(
        self.websocket.receive
    )
    if not status then
        print("Lost connection to server -> Reconnection ...")
        self:detect_bestest_server()
        return self:receive()
    end
    return retval
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

--- Request a `16 * 1024` bit chunk
-- @tparam number chunkindex The chunkindex
-- @tparam number id Media id
-- @treturn bytes chunk `16 * 1024` bit chunk
function API:get_chunk(chunkindex, id)
    self:send({
        ["action"] = "get_chunk",
        ["chunkindex"] = chunkindex,
        ["id"] = id
    })
    return self:receive()
end

--- Request media
-- @tparam string url Url or Search Term
-- @treturn table json response
function API:request_media(url)
    self:send({
        ["action"] = "request_media",
        ["url"] = url
    })
    return textutils.unserialiseJSON(self:receive())
end

--[[ handshake function coming soon
function YouCubeAPI:handshake()
    local version = "0.0.poc0"
    self.websocket.send(textutils.serialiseJSON({
        ["action"] = "handshake",
        ["version"] = version
    }))
end
]]

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
        -- https://github.com/Vexatos/Computronics/blob/b0ade53cab10529dbe91ebabfa882d1b4b21fa90/src/main/resources/assets/computronics/lua/peripheral/tape_drive/programs/tape_drive/tape#L109-L123
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
    API         = API,
    AudioDevice = AudioDevice,
    Speaker     = Speaker,
    Tape        = Tape
}
