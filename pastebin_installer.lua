--[[
_ _  _ ____ ___ ____ _    _    ____ ____
| |\ | [__   |  |__| |    |    |___ |__/
| | \| ___]  |  |  | |___ |___ |___ |  \

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
]]

-- OpenPastebinInstaller v1.0.0 (based on wget)

local url = "https://raw.githubusercontent.com/Commandcracker/YouCube/main/installer.lua"

if not http then
    printError("OpenPastebinInstaller requires the http API")
    printError("Set http.enabled to true in ComputerCraft config")
    return
end

local function getFilename(sUrl)
    sUrl = sUrl:gsub("[#?].*", ""):gsub("/+$", "")
    return sUrl:match("/([^/]+)$")
end

local function get(sUrl)
    -- Check if the URL is valid
    local ok, err = http.checkURL(url)
    if not ok then
        printError("\"" .. sUrl .. "\" ", err or "Invalid URL.")
        return
    end

    local response, http_err = http.get(sUrl, nil, true)
    if not response then
        printError("Failed to download \"" .. sUrl .. "\" (" .. http_err .. ")")
        return nil
    end

    term.setTextColour(colors.lime)
    print("Runnig " .. getFilename(url))
    term.setTextColour(colors.white)

    local sResponse = response.readAll()
    response.close()
    return sResponse or ""
end

local res = get(url)
if not res then return end

local func, err = load(res, getFilename(url), "t", _ENV)
if not func then
    printError(err)
    return
end

local ok, err = pcall(func)
if not ok then
    printError(err)
end
