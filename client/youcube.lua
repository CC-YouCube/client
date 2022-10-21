if periphemu then -- CraftOS-PC
    periphemu.create("top", "speaker")
end

local speaker = peripheral.find("speaker")

if speaker == nil then
    error("You need a speaker in order to use YouCube!")
end

local websocket, websocket_error = http.websocket("ws://localhost:5000")

if websocket == false then
    error(websocket_error)
end

print("Enter Url or Search Term")
url = read()

websocket.send(textutils.serialiseJSON({
    ["action"] = "request_media",
    ["url"] = url
}))

local data = websocket.receive()
data = textutils.unserialiseJSON(data)
local file = data.file

local chunkindex = 0
websocket.send(textutils.serialiseJSON({
    ["action"] = "get_chunk",
    ["chunkindex"] = chunkindex,
    ["file"] = file
}))

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

while true do
    local chunk = websocket.receive()

    if chunk == "mister, the media has finished playing" then
        print("mister, the media has finished playing")
        websocket.close()
        return
    end

    local buffer = decoder(chunk)

    while not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end

    chunkindex = chunkindex + 1

    local request = textutils.serialiseJSON({
        ["action"] = "get_chunk",
        ["chunkindex"] = chunkindex,
        ["file"] = file
    })

    print("Request:", request)

    websocket.send(request)
end
