local semver = require("/lib/semver")


print(semver '0.0.0-poc.1.0.0' < semver '0.0.0-poc.1.0.0')
print(semver '0.0.0-poc.1.0.0' < semver '0.0.0-poc.2.0.0')
print(semver '0.0.0-poc.1.0.0' < semver '0.0.0-poc.4.0.0')
print(semver '0.0.0-poc.4.0.0' < semver '0.0.0-poc.5.0.0')
print(semver '0.0.0-poc.4.0.0' < semver '0.0.0-poc.5.0.0')
print(semver '0.0.0-z' < semver '0.0.0-poc.5.0.0')
print(semver '0.0.0-poc.4.0.0' < semver '0.0.0-poc.1.0.0')

--[[
if v(version) < v(index.latestVersion) then
    error("Client outdated, Updating Musicify.",0) -- Update check
    -- this has broken so many times it's actually not even funny anymore
    update()
end
]]
