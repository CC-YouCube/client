--[[
_  _ _  _ _  _ ___  ____ ____
|\ | |  | |\/| |__] |___ |__/
| \| |__| |  | |__] |___ |  \
____ ____ ____ _  _ ____ ___ ___ ____ ____
|___ |  | |__/ |\/| |__|  |   |  |___ |__/
|    |__| |  \ |  | |  |  |   |  |___ |  \

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
Libary Version: 1.0.0
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

return NumberFormatter
