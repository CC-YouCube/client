-- MIT License
--
-- Copyright (c) 2021 JackMacWindows
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- If not using CC, replace `expect` with a suitable argument checking function.
--local expect = require "cc.expect".expect
local expect = dofile "/rom/modules/main/cc/expect.lua".expect

local ByteOrder = {BIG_ENDIAN = 1, LITTLE_ENDIAN = 2}
local isint = {b = 1, B = 1, h = 1, H = 1, l = 1, L = 1, j = 1, J = 1, T = 1}
local packoptsize_tbl = {b = 1, B = 1, x = 1, h = 2, H = 2, f = 4, j = 4, J = 4, l = 8, L = 8, T = 8, d = 8, n = 8}

local function round(n) if n % 1 >= 0.5 then return math.ceil(n) else return math.floor(n) end end

local function floatToRawIntBits(f)
    if f == 0 then return 0
    elseif f == -0 then return 0x80000000
    elseif f == math.huge then return 0x7F800000
    elseif f == -math.huge then return 0xFF800000 end
    local m, e = math.frexp(f)
    if e > 127 or e < -126 then error("number out of range", 3) end
    e, m = e + 126, round((math.abs(m) - 0.5) * 0x1000000)
    if m > 0x7FFFFF then e = e + 1 end
    return bit32.bor(f < 0 and 0x80000000 or 0, bit32.lshift(bit32.band(e, 0xFF), 23), bit32.band(m, 0x7FFFFF))
end

local function doubleToRawLongBits(f)
    if f == 0 then return 0, 0
    elseif f == -0 then return 0x80000000, 0
    elseif f == math.huge then return 0x7FF00000, 0
    elseif f == -math.huge then return 0xFFF00000, 0 end
    local m, e = math.frexp(f)
    if e > 1023 or e < -1022 then error("number out of range", 3) end
    e, m = e + 1022, round((math.abs(m) - 0.5) * 0x20000000000000)
    if m > 0xFFFFFFFFFFFFF then e = e + 1 end
    return bit32.bor(f < 0 and 0x80000000 or 0, bit32.lshift(bit32.band(e, 0x7FF), 20), bit32.band(m / 0x100000000, 0xFFFFF)), bit32.band(m, 0xFFFFFFFF)
end

local function intBitsToFloat(l)
    if l == 0 then return 0
    elseif l == 0x80000000 then return -0
    elseif l == 0x7F800000 then return math.huge
    elseif l == 0xFF800000 then return -math.huge end
    local m, e = bit32.band(l, 0x7FFFFF), bit32.band(bit32.rshift(l, 23), 0xFF)
    e, m = e - 126, m / 0x1000000 + 0.5
    local n = math.ldexp(m, e)
    return bit32.btest(l, 0x80000000) and -n or n
end

local function longBitsToDouble(lh, ll)
    if lh == 0 and ll == 0 then return 0
    elseif lh == 0x80000000 and ll == 0 then return -0
    elseif lh == 0x7FF00000 and ll == 0 then return math.huge
    elseif lh == 0xFFF00000 and ll == 0 then return -math.huge end
    local m, e = bit32.band(lh, 0xFFFFF) * 0x100000000 + bit32.band(ll, 0xFFFFFFFF), bit32.band(bit32.rshift(lh, 20), 0x7FF)
    e, m = e - 1022, m / 0x20000000000000 + 0.5
    local n = math.ldexp(m, e)
    return bit32.btest(lh, 0x80000000) and -n or n
end

local function packint(num, size, output, offset, alignment, endianness, signed)
    local total_size = 0
    if offset % math.min(size, alignment) ~= 0 and alignment > 1 then
        local i = 0
        while offset % math.min(size, alignment) ~= 0 and i < alignment do
            output[offset] = 0
            offset = offset + 1
            total_size = total_size + 1
            i = i + 1
        end
    end
    if endianness == ByteOrder.BIG_ENDIAN then
        local added_padding = 0
        if size > 8 then for i = 0, size - 9 do
            output[offset + i] = (signed and num >= 2^(size * 8 - 1) ~= 0) and 0xFF or 0
            added_padding = added_padding + 1
            total_size = total_size + 1
        end end
        for i = added_padding, size - 1 do
            output[offset + i] = bit32.band(bit32.rshift(num, ((size - i - 1) * 8)), 0xFF)
            total_size = total_size + 1
        end
    else
        for i = 0, math.min(size, 8) - 1 do
            output[offset + i] = num / 2^(i * 8) % 256
            total_size = total_size + 1
        end
        for i = 8, size - 1 do
            output[offset + i] = (signed and num >= 2^(size * 8 - 1) ~= 0) and 0xFF or 0
            total_size = total_size + 1
        end
    end
    return total_size
end

local function unpackint(str, offset, size, endianness, alignment, signed)
    local result, rsize = 0, 0
    if offset % math.min(size, alignment) ~= 0 and alignment > 1 then
        for i = 0, alignment - 1 do
            if offset % math.min(size, alignment) == 0 then break end
            offset = offset + 1
            rsize = rsize + 1
        end
    end
    for i = 0, size - 1 do
        result = result + str:byte(offset + i) * 2^((endianness == ByteOrder.BIG_ENDIAN and size - i - 1 or i) * 8)
        rsize = rsize + 1
    end
    if (signed and result >= 2^(size * 8 - 1)) then result = result - 2^(size * 8) end
    return result, rsize
end

local function packoptsize(opt, alignment)
    local retval = packoptsize_tbl[opt] or 0
    if (alignment > 1 and retval % alignment ~= 0) then retval = retval + (alignment - (retval % alignment)) end
    return retval
end

--[[
 * string.pack (fmt, v1, v2, ...)
 *
 * Returns a binary string containing the values v1, v2, etc.
 * serialized in binary form (packed) according to the format string fmt.
 ]]
local function pack(...)
    local fmt = expect(1, ..., "string")
    local endianness = ByteOrder.LITTLE_ENDIAN
    local alignment = 1
    local pos = 1
    local argnum = 2
    local output = {}
    local i = 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        i = i + 1
        if c == '=' or c == '<' then
            endianness = ByteOrder.LITTLE_ENDIAN
        elseif c == '>' then
            endianness = ByteOrder.BIG_ENDIAN
        elseif c == '!' then
            local size = -1
            while (i <= #fmt and fmt:sub(i, i):match("%d")) do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (math.max(size, 0) * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16 or size == 0) then error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (size == -1) then alignment = 4
            else alignment = size end
        elseif isint[c] then
            local num = expect(argnum, select(argnum, ...), "number")
            argnum = argnum + 1
            if (num >= math.pow(2, (packoptsize(c, 0) * 8 - (c:match("%l") and 1 or 0))) or
                num < (c:match("%l") and -math.pow(2, (packoptsize(c, 0) * 8 - 1)) or 0)) then
                error(string.format("bad argument #%d to 'pack' (integer overflow)", argnum - 1), 2)
            end
            pos = pos + packint(num, packoptsize(c, 0), output, pos, alignment, endianness, false)
        elseif c:lower() == 'i' then
            local signed = c == 'i'
            local size = -1
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (math.max(size, 0) * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16 or size == 0) then
                error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (alignment > 1 and (size ~= 1 and size ~= 2 and size ~= 4 and size ~= 8 and size ~= 16)) then
                error("bad argument #1 to 'pack' (format asks for alignment not power of 2)", 2)
            elseif (size == -1) then size = 4 end
            local num = expect(argnum, select(argnum, ...), "number")
            argnum = argnum + 1
            if (num >= math.pow(2, (size * 8 - (c:match("%l") and 1 or 0))) or
                num < (c:match("%l") and -math.pow(2, (size * 8 - 1)) or 0)) then
                error(string.format("bad argument #%d to 'pack' (integer overflow)", argnum - 1), 2)
            end
            pos = pos + packint(num, size, output, pos, alignment, endianness, signed)
        elseif c == 'f' then
            local f = expect(argnum, select(argnum, ...), "number")
            argnum = argnum + 1
            local l = floatToRawIntBits(f)
            if (pos % math.min(4, alignment) ~= 0 and alignment > 1) then 
                for j = 0, alignment - 1 do
                    if pos % math.min(4, alignment) == 0 then break end
                    output[pos] = 0
                    pos = pos + 1
                end
            end
            for j = 0, 3 do output[pos + (endianness == ByteOrder.BIG_ENDIAN and 3 - j or j)] = bit32.band(bit32.rshift(l, (j * 8)), 0xFF) end
            pos = pos + 4
        elseif c == 'd' or c == 'n' then
            local f = expect(argnum, select(argnum, ...), "number")
            argnum = argnum + 1
            local lh, ll = doubleToRawLongBits(f)
            if (pos % math.min(8, alignment) ~= 0 and alignment > 1) then 
                for j = 0, alignment - 1 do
                    if pos % math.min(8, alignment) == 0 then break end
                    output[pos] = 0
                    pos = pos + 1
                end
            end
            for j = 0, 3 do output[pos + (endianness == ByteOrder.BIG_ENDIAN and 7 - j or j)] = bit32.band(bit32.rshift(ll, (j * 8)), 0xFF) end
            for j = 4, 7 do output[pos + (endianness == ByteOrder.BIG_ENDIAN and 7 - j or j)] = bit32.band(bit32.rshift(lh, ((j - 4) * 8)), 0xFF) end
            pos = pos + 8
        elseif c == 'c' then
            local size = 0
            if (i > #fmt or not fmt:sub(i, i):match("%d")) then
                error("missing size for format option 'c'", 2)
            end
            while (i <= #fmt and fmt:sub(i, i):match("%d")) do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (pos + size < pos or pos + size > 0xFFFFFFFF) then error("bad argument #1 to 'pack' (format result too large)", 2) end
            local str = expect(argnum, select(argnum, ...), "string")
            argnum = argnum + 1
            if (#str > size) then error(string.format("bad argument #%d to 'pack' (string longer than given size)", argnum - 1), 2) end
            if size > 0 then
                for j = 0, size - 1 do output[pos+j] = str:byte(j + 1) or 0 end
                pos = pos + size
            end
        elseif c == 'z' then
            local str = expect(argnum, select(argnum, ...), "string")
            argnum = argnum + 1
            for b in str:gmatch "." do if (b == '\0') then error(string.format("bad argument #%d to 'pack' (string contains zeros)", argnum - 1), 2) end end
            for j = 0, #str - 1 do output[pos+j] = str:byte(j + 1) end
            output[pos + #str] = 0
            pos = pos + #str + 1
        elseif c == 's' then
            local size = 0
            while (i <= #fmt and fmt:sub(i, i):match("%d")) do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then
                error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (size == 0) then size = 4 end
            local str = expect(argnum, select(argnum, ...), "string")
            argnum = argnum + 1
            if (#str >= math.pow(2, (size * 8))) then
                error(string.format("bad argument #%d to 'pack' (string length does not fit in given size)", argnum - 1), 2)
            end
            packint(#str, size, output, pos, 1, endianness, false)
            for j = size, #str + size - 1 do output[pos+j] = str:byte(j - size + 1) or 0 end
            pos = pos + #str + size
        elseif c == 'x' then
            output[pos] = 0
            pos = pos + 1
        elseif c == 'X' then
            if (i >= #fmt) then error("invalid next option for option 'X'", 2) end
            local size = 0
            local c = fmt:sub(i, i)
            i = i + 1
            if c:lower() == 'i' then
                while i <= #fmt and fmt:sub(i, i):match("%d") do
                    if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                    size = (size * 10) + tonumber(fmt:sub(i, i))
                    i = i + 1
                end
                if (size > 16 or size == 0) then
                    error(string.format("integral size (%d) out of limits [1,16]", size), 2)
                end
            else size = packoptsize(c, 0) end
            if (size < 1) then error("invalid next option for option 'X'", 2) end
            if (pos % math.min(size, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(size, alignment) == 0 then break end
                    output[pos] = 0
                    pos = pos + 1
                end
            end
        elseif c ~= ' ' then error(string.format("invalid format option '%s'", c), 2) end
    end
    return string.char(table.unpack(output))
end

--[[
 * string.packsize (fmt)
 *
 * Returns the size of a string resulting from string.pack with the given format.
 * The format string cannot have the variable-length options 's' or 'z'.
 ]]
local function packsize(fmt)
    local pos = 0
    local alignment = 1
    local i = 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        i = i + 1
        if c == '!' then
            local size = 0
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (size == 0) then alignment = 4
            else alignment = size end
        elseif isint[c] then
            local size = packoptsize(c, 0)
            if (pos % math.min(size, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(size, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            pos = pos + size
        elseif c:lower() == 'i' then
            local size = 0
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then
                error(string.format("integral size (%d) out of limits [1,16]", size))
            elseif (alignment > 1 and (size ~= 1 and size ~= 2 and size ~= 4 and size ~= 8 and size ~= 16)) then
                error("bad argument #1 to 'pack' (format asks for alignment not power of 2)", 2)
            elseif (size == 0) then size = 4 end
            if (pos % math.min(size, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(size, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            pos = pos + size
        elseif c == 'f' then
            if (pos % math.min(4, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(4, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            pos = pos + 4
        elseif c == 'd' or c == 'n' then
            if (pos % math.min(8, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(8, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            pos = pos + 8
        elseif c == 'c' then
            local size = 0
            if (i > #fmt or not fmt:sub(i, i):match("%d")) then
                error("missing size for format option 'c'", 2)
            end
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (pos + size < pos or pos + size > 0x7FFFFFFF) then error("bad argument #1 to 'packsize' (format result too large)", 2) end
            pos = pos + size
        elseif c == 'x' then
            pos = pos + 1
        elseif c == 'X' then
            if (i >= #fmt) then error("invalid next option for option 'X'", 2) end
            local size = 0
            local c = fmt:sub(i, i)
            i = i + 1
            if c:lower() == 'i' then
                while i <= #fmt and fmt:sub(i, i):match("%d") do
                    if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                    size = (size * 10) + tonumber(fmt:sub(i, i))
                    i = i + 1
                end
                if (size > 16 or size == 0) then
                    error(string.format("integral size (%d) out of limits [1,16]", size), 2)
                end
            else size = packoptsize(c, 0) end
            if (size < 1) then error("invalid next option for option 'X'", 2) end
            if (pos % math.min(size, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(size, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
        elseif c == 's' or c == 'z' then error("bad argument #1 to 'packsize' (variable-length format)", 2)
        elseif c ~= ' ' and c ~= '<' and c ~= '>' and c ~= '=' then error(string.format("invalid format option '%s'", c), 2) end
    end
    return pos
end

--[[
 * string.unpack (fmt, s [, pos])
 *
 * Returns the values packed in string s (see string.pack) according to the format string fmt.
 * An optional pos marks where to start reading in s (default is 1).
 * After the read values, this function also returns the index of the first unread byte in s.
 ]]
local function unpack(fmt, str, pos)
    expect(1, fmt, "string")
    expect(2, str, "string")
    expect(3, pos, "number", "nil")
    if pos then
        if (pos < 0) then pos = #str + pos
        elseif (pos == 0) then error("bad argument #3 to 'unpack' (initial position out of string)", 2) end
        if (pos > #str or pos < 0) then error("bad argument #3 to 'unpack' (initial position out of string)", 2) end
    else pos = 1 end
    local endianness = ByteOrder.LITTLE_ENDIAN
    local alignment = 1
    local retval = {}
    local i = 1
    while i <= #fmt do
        local c = fmt:sub(i, i)
        i = i + 1
        if c == '<' or c == '=' then
            endianness = ByteOrder.LITTLE_ENDIAN
        elseif c == '>' then
            endianness = ByteOrder.BIG_ENDIAN
        elseif c == '!' then
            local size = 0
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then
                error(string.format("integral size (%d) out of limits [1,16]", size))
            elseif (size == 0) then alignment = 4
            else alignment = size end
        elseif isint[c] then
            if (pos + packoptsize(c, 0) > #str + 1) then error("data string too short", 2) end
            local res, ressz = unpackint(str, pos, packoptsize(c, 0), endianness, alignment, c:match("%l") ~= nil)
            retval[#retval+1] = res
            pos = pos + ressz
        elseif c:lower() == 'i' then
            local signed = c == 'i'
            local size = 0
            while (i <= #fmt and fmt:sub(i, i):match("%d")) do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then
                error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (size > 8) then
                error(string.format("%d-byte integer does not fit into Lua Integer", size), 2)
            elseif (size == 0) then size = 4 end
            if (pos + size > #str + 1) then error("data string too short", 2) end
            local res, ressz = unpackint(str, pos, size, endianness, alignment, signed)
            retval[#retval+1] = res
            pos = pos + ressz
        elseif c == 'f' then
            if (pos % math.min(4, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(4, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            if (pos + 4 > #str + 1) then error("data string too short", 2) end
            local res = unpackint(str, pos, 4, endianness, alignment, false)
            retval[#retval+1] = intBitsToFloat(res)
            pos = pos + 4
        elseif c == 'd' or c == 'n' then
            if (pos % math.min(8, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(8, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
            if (pos + 8 > #str + 1) then error("data string too short", 2) end
            local lh, ll = 0, 0
            for j = 0, 3 do lh = bit32.bor(lh, bit32.lshift((str:byte(pos + j)), ((endianness == ByteOrder.BIG_ENDIAN and 3 - j or j) * 8))) end
            for j = 0, 3 do ll = bit32.bor(ll, bit32.lshift((str:byte(pos + j + 4)), ((endianness == ByteOrder.BIG_ENDIAN and 3 - j or j) * 8))) end
            if endianness == ByteOrder.LITTLE_ENDIAN then lh, ll = ll, lh end
            retval[#retval+1] = longBitsToDouble(lh, ll)
            pos = pos + 8
        elseif c == 'c' then
            local size = 0
            if (i > #fmt or not fmt:sub(i, i):match("%d")) then
                error("missing size for format option 'c'", 2)
            end
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)") end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (pos + size > #str + 1) then error("data string too short", 2) end
            retval[#retval+1] = str:sub(pos, pos + size - 1)
            pos = pos + size
        elseif c == 'z' then
            local size = 0
            while (str:byte(pos + size) ~= 0) do
                size = size + 1
                if (pos + size > #str) then error("unfinished string for format 'z'", 2) end
            end
            retval[#retval+1] = str:sub(pos, pos + size - 1)
            pos = pos + size + 1
        elseif c == 's' then
            local size = 0
            while i <= #fmt and fmt:sub(i, i):match("%d") do
                if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                size = (size * 10) + tonumber(fmt:sub(i, i))
                i = i + 1
            end
            if (size > 16) then
                error(string.format("integral size (%d) out of limits [1,16]", size), 2)
            elseif (size == 0) then size = 4 end
            if (pos + size > #str + 1) then error("data string too short", 2) end
            local num, numsz = unpackint(str, pos, size, endianness, alignment, false)
            pos = pos + numsz
            if (pos + num > #str + 1) then error("data string too short", 2) end
            retval[#retval+1] = str:sub(pos, pos + num - 1)
            pos = pos + num
        elseif c == 'x' then
            pos = pos + 1
        elseif c == 'X' then
            if (i >= #fmt) then error("invalid next option for option 'X'", 2) end
            local size = 0
            local c = fmt:sub(i, i)
            i = i + 1
            if c:lower() == 'i' then
                while i <= #fmt and fmt:sub(i, i):match("%d") do
                    if (size >= 0xFFFFFFFF / 10) then error("bad argument #1 to 'pack' (invalid format)", 2) end
                    size = (size * 10) + tonumber(fmt:sub(i, i))
                    i = i + 1
                end
                if (size > 16 or size == 0) then
                    error(string.format("integral size (%d) out of limits [1,16]", size), 2)
                elseif (size == -1) then size = 4 end
            else size = packoptsize(c, 0) end
            if (size < 1) then error("invalid next option for option 'X'", 2) end
            if (pos % math.min(size, alignment) ~= 0 and alignment > 1) then
                for j = 1, alignment do
                    if pos % math.min(size, alignment) == 0 then break end
                    pos = pos + 1
                end
            end
        elseif c ~= ' ' then error(string.format("invalid format option '%s'", c), 2) end
    end
    retval[#retval+1] = pos
    return table.unpack(retval)
end

return {
    pack = pack,
    packsize = packsize,
    unpack = unpack
}