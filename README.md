# YouCube

[![Project license](https://img.shields.io/github/license/Commandcracker/YouCube?style=for-the-badge)](https://github.com/Commandcracker/YouCube/blob/main/LICENSE.txt)
[![Spellcheck Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Spellcheck?label=Spell-check&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/spellcheck.yml)
[![API documentation](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/AsyncAPI%20documents%20processing?label=API%20documentation&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/asyncapi-doc.yml)

YouCube is a tool that streams [dfpwm](https://wiki.vexatos.com/dfpwm) files to [ComputerCraft: Tweaked](https://github.com/cc-tweaked/CC-Tweaked). The YouCube server uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds) to provide media from services like [YouTube](https://www.youtube.com/) as [dfpwm](https://wiki.vexatos.com/dfpwm) files. \
**Project Status: Proof of concept**

## Installation

### Client

[![CC: Tweaked Version: 1.100+](https://img.shields.io/badge/CC:%20tweaked-1.100+-green?style=for-the-badge&logo=GNOME%20Terminal)](https://tweaked.cc/)
![or](.README/slash.svg)
[![CC: Tweaked Version: 1.80pr1.3+](https://img.shields.io/badge/CC:%20tweaked-1.80pr1.3+-green?style=for-the-badge&logo=GNOME%20Terminal)](https://tweaked.cc/)
![+](.README/plus.svg)
[![Computronics Version: 0.1.0+](https://img.shields.io/badge/Computronics-0.1.0+-green?style=for-the-badge)](https://wiki.vexatos.com/wiki:computronics) \
[![Lua Lint Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Illuaminate%20Lint?label=Lua%20Lint&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/illuaminate-lint.yml)

![preview](.README/preview-client.png)

The client can be installed by running the following command:

```shell
pastebin run swsmNAf7
```

or

```shell
wget https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```

#### Starting the Client

```text
youcube
```

#### Trying out YouCube

If you dont want to install YouCube you can use this command:

```shell
wget run https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```

### Server

[![Python Version: 3.7+](https://img.shields.io/badge/Python-3.7+-green?style=for-the-badge&logo=Python&logoColor=white)](https://www.python.org/downloads/)
[![Python Lint Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Pylint?label=Python%20Lint&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/pylint.yml)

![preview](.README/preview-server.png)

YouCube has a public server, which you can use if you don't want to host your own server. \
The public server is a bit slow, but that's a trait you need to take if you don't want to self-host. \
The client has the public server set by default, so you can just run the client, and you're good to go. \
For anyone who is curious, the server "IP" is `wss://youcube.onrender.com`

#### Requirements

- [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds)
- [Python 3.7+](https://www.python.org/downloads/)
  - [aiohttp](https://pypi.org/project/aiohttp/)
  - [yt-dlp](https://pypi.org/project/yt-dlp/)

You can install the required packages with [pip](https://pip.pypa.io/en/stable/installation/) by running:

```shell
pip install -r server/requirements.txt
```

#### Starting the Server

```bash
python server/youcube.py
```
