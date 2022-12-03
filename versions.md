# Versions

YouCube uses [Semantic Versioning](https://semver.org/)

All versions are stored in [versions.json](versions.json)

## Version changes

This section helps to change the version of a specific module by listing, where it needs to be changed.

In addition, all versions need to be changed in [versions.json](versions.json)

`api.version` -> [asyncapi.yml](asyncapi.yml), [server/youcube/youcube.py](server/youcube/youcube.py), [client/lib/youcubeapi.lua](client/lib/youcubeapi.lua)

`server.version` -> [server/youcube.py](server/youcube.py)

`client.version` -> [client/youcube.lua](client/youcube.lua)

`client.libraries.youcubeapi.version` -> [client/lib/youcubeapi.lua](client/lib/youcubeapi.lua)

`client.libraries.semver.version` -> [client/lib/semver.lua](client/lib/semver.lua)

`client.libraries.argparse.version` -> [client/lib/argparse.lua](client/lib/argparse.lua)

`client.libraries.numberformatter.version` -> [client/lib/numberformatter.lua](client/lib/numberformatter.lua)

## Tagging

When a version is changed a git tag needs to be created. \
(Tagging will be automated with gh-actions)

`api` -> `api-<VERSION>`

`server` -> `server-<VERSION>`

`client` -> `client-<VERSION>`

`client.libraries.youcubeapi` -> `youcubeapi-<VERSION>`

`client.libraries.semver` -> **-** [semver](https://github.com/kikito/semver.lua) has it own repository

`client.libraries.argparse` -> **-** [argparse](https://github.com/Commandcracker/cc-argparse) has it own repository

`client.libraries.numberformatter` -> `numberformatter-<VERSION>`
