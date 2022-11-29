--[[- Library for formatting numbers
    @module numberformatter
]]

--[[ numberformatter.lua
_  _ _  _ _  _ ___  ____ ____
|\ | |  | |\/| |__] |___ |__/
| \| |__| |  | |__] |___ |  \
____ ____ ____ _  _ ____ ___ ___ ____ ____
|___ |  | |__/ |\/| |__|  |   |  |___ |__/
|    |__| |  \ |  | |  |  |   |  |___ |  \
]]

local NumberFormatter = {
    --- "Metadata" - Version
    _VERSION     = "1.1.0",
    --- "Metadata" - Description
    _DESCRIPTION = "Library for formatting numbers",
    --- "Metadata" - Homepage / Url
    _URL         = "https://github.com/Commandcracker/YouCube",
    --- "Metadata" - License
    _LICENSE     = "GPL-3.0"
}
--[[
    NumberFormatter.compact and NumberFormatter.abbreviate based on:
    https://devforum.roblox.com/t/how-can-i-turn-a-number-to-a-shorter-number-i-dont-know-how-to-explain-click-to-understand-3/649496/3
]]

local Suffixes = { "k", "M", "B", "T", "qd", "Qn", "sx", "Sp", "O", "N", "de", "Ud", "DD", "tdD", "qdD", "QnD", "sxD",
    "SpD", "OcD", "NvD", "Vgn", "UVg", "DVg", "TVg", "qtV", "QnV", "SeV", "SPG", "OVG", "NVG", "TGN", "UTG", "DTG",
    "tsTG", "qtTG", "QnTG", "ssTG", "SpTG", "OcTG", "NoTG", "QdDR", "uQDR", "dQDR", "tQDR", "qdQDR", "QnQDR", "sxQDR",
    "SpQDR", "OQDDr", "NQDDr", "qQGNT", "uQGNT", "dQGNT", "tQGNT", "qdQGNT", "QnQGNT", "sxQGNT", "SpQGNT", "OQQGNT",
    "NQQGNT", "SXGNTL" }

--[[- Format number by LDML's specification for [Compact Number Formats](http://unicode.org/reports/tr35/tr35-numbers.html#Compact_Number_Formats)
    @tparam number number The number to format
    @treturn string formatted number
    @usage Example:

        local numberformatter = require("numberformatter")
        print(numberformatter.compact(1000))
    
    Output: `1k`
]]
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

--[[- Format number - separate thousands by comma
    @tparam number number The number to format
    @treturn string formatted number
    @usage Example:

        local numberformatter = require("numberformatter")
        print(numberformatter.abbreviate(1000))
    
    Output: `1,000`
]]
function NumberFormatter.abbreviate(number)
    local left, num, right = string.match(number, '^([^%d]*%d)(%d*)(.-)$')
    return left .. num:reverse():gsub('(%d%d%d)', '%1,'):reverse() .. right
end

return NumberFormatter
