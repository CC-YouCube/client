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

-------------------------------------------------------------------------------------------

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
local url = read()
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

print("Likes: " .. NumberFormatter.compact(data.like_count))
print("Views: " .. NumberFormatter.compact(data.view_count))

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
