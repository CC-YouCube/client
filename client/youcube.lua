if periphemu then -- CraftOS-PC
    periphemu.create("top", "speaker")
end

local speaker = peripheral.find("speaker")

if speaker == nil then
    error("You need a speaker in order to use YouCube!")
end

local servers = {
    "ws://localhost:5000",
    "wss://youcube.onrender.com"
}

local websocket

for i, server in pairs(servers) do
    local websocket_error
    websocket, websocket_error = http.websocket(server)

    if websocket ~= false then
        term.write("Using the YouCube server: ")
        term.setTextColor(colors.blue)
        print(server)
        term.setTextColor(colors.white)
        break
    elseif i == #servers then
        error(websocket_error)
    end

end

print("Enter Url or Search Term:")
term.setTextColor(colors.lightGray)
url = read()
term.setTextColor(colors.white)

print("Requesting media ...")

websocket.send(textutils.serialiseJSON({
    ["action"] = "request_media",
    ["url"] = url
}))

local data = websocket.receive()
data = textutils.unserialiseJSON(data)

if data.action == "error" then
    error(data.message)
end

local id = data.id

local chunkindex = 0
websocket.send(textutils.serialiseJSON({
    ["action"] = "get_chunk",
    ["chunkindex"] = chunkindex,
    ["id"] = id
}))

term.write("Playing: ")
term.setTextColor(colors.lime)
print(data.title)
term.setTextColor(colors.white)

print("Likes: " .. data.like_count)
print("Views: " .. data.view_count)

local x, y = term.getCursorPos()
term.write("Chunkindex: ")
term.setTextColor(colors.gray)
term.write(chunkindex)
term.setTextColor(colors.white)

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

while true do
    local chunk = websocket.receive()

    if chunk == "mister, the media has finished playing" then
        print()
        websocket.close()
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

    websocket.send(textutils.serialiseJSON({
        ["action"] = "get_chunk",
        ["chunkindex"] = chunkindex,
        ["id"] = id
    }))
end
