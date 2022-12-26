--[[
_ _  _ ____ ___ ____ _    _    ____ ____
| |\ | [__   |  |__| |    |    |___ |__/
| | \| ___]  |  |  | |___ |___ |___ |  \

Github Repository: https://github.com/Commandcracker/YouCube
License: GPL-3.0
]]

-- OpenInstaller v1.0.0 (based on wget)

local BASE_URL = "https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/"

local files = {
    ["./youcube.lua"] = BASE_URL .. "youcube.lua",
    ["./lib/youcubeapi.lua"] = BASE_URL .. "lib/youcubeapi.lua",
    ["./lib/numberformatter.lua"] = BASE_URL .. "lib/numberformatter.lua",
    ["./lib/semver.lua"] = BASE_URL .. "lib/semver.lua",
    ["./lib/argparse.lua"] = BASE_URL .. "lib/argparse.lua",
    ["./lib/string_pack.lua"] = BASE_URL .. "lib/string_pack.lua"
}

if not http then
    printError("OpenInstaller requires the http API")
    printError("Set http.enabled to true in the ComputerCraft config")
    return
end

local function question(_question)

    term.setTextColour(colors.orange)
    term.write(_question .. "? [")
    term.setTextColour(colors.lime)
    term.write('Y')
    term.setTextColour(colors.orange)
    term.write('/')
    term.setTextColour(colors.red)
    term.write('n')
    term.setTextColour(colors.orange)
    term.write("] ")
    term.setTextColour(colors.white)

    local input = string.lower(string.sub(read(), 1, 1))

    if input == 'y' or input == 'j' or input == '' then
        return true
    else
        return false
    end
end

local function get(sUrl)
    -- Check if the URL is valid
    local ok, err = http.checkURL(sUrl)
    if not ok then
        printError("\"" .. sUrl .. "\" ", err or "Invalid URL.")
        return
    end

    --term.setTextColour(colors.lightGray)
    --write("Connecting to " .. sUrl .. "... ")

    local response, http_err = http.get(sUrl, nil, true)
    if not response then
        printError("Failed to download \"" .. sUrl .. "\" (" .. http_err .. ")")
        return nil
    end

    local sResponse = response.readAll()
    response.close()
    return sResponse or ""
end

for path, dl_link in pairs(files) do
    local sPath = shell.resolve(path)
    if fs.exists(sPath) then
        if not question("\"" .. path .. "\" already exists. Override") then
            return
        end
    end

    local res = get(dl_link)
    if not res then return end

    local file, err = fs.open(sPath, "wb")
    if not file then
        printError("Failed to save \"" .. path .. "\" (" .. err .. ")")
        return
    end

    file.write(res)
    file.close()

    term.setTextColour(colors.lime)
    print("Downloaded \"" .. path .. "\"")
end
