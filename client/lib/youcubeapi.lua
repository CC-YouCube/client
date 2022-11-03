--[[
_   _ ____ _  _ ____ _  _ ___  ____ ____ ___  _
 \_/  |  | |  | |    |  | |__] |___ |__| |__] |
  |   |__| |__| |___ |__| |__] |___ |  | |    |

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0

Lib Version: 0.0.poc0
API Version: 0.0.poc0 (https://commandcracker.github.io/YouCube/)
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
    "wss://youcube.onrender.com" -- By Commandcracker
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
function YouCubeAPI:handshake()
    local version = "0.0.poc0"
    self.websocket.send(textutils.serialiseJSON({
        ["action"] = "handshake",
        ["version"] = version
    }))
end
]]

return YouCubeAPI
