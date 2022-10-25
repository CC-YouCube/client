# YouCube

[![Lua Lint Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Illuaminate%20Lint?label=Lua%20Lint&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/illuaminate-lint.yml)
[![Python Lint Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Pylint?label=Python%20Lint&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/pylint.yml)
[![Spellcheck Workflow Status](https://img.shields.io/github/workflow/status/Commandcracker/YouCube/Spellcheck?label=Spell-check&logo=github&style=for-the-badge)](https://github.com/Commandcracker/YouCube/actions/workflows/spellcheck.yml)
[![Project license](https://img.shields.io/github/license/Commandcracker/YouCube?style=for-the-badge)](https://github.com/Commandcracker/YouCube/blob/main/LICENSE.txt)
[![CC: Tweaked Version: 1.100+](https://img.shields.io/badge/CC:%20tweaked-1.100+-green?style=for-the-badge&logo=GNOME%20Terminal)](https://tweaked.cc/)
[![Python Version: 3.7+](https://img.shields.io/badge/Python-3.7+-green?style=for-the-badge&logo=Python&logoColor=white)](https://www.python.org/downloads/)

YouCube is a tool that streams [dfpwm](https://wiki.vexatos.com/dfpwm) files to [ComputerCraft: Tweaked](https://github.com/cc-tweaked/CC-Tweaked). The YouCube server uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds) to provide media from Services like [YouTube](https://www.youtube.com/) as [dfpwm](https://wiki.vexatos.com/dfpwm) files. \
**Project Status: Proof of concept**

## Inastallation

### Server

If you dont want to host your own server: \
YouCube has a public server. \
The public server is set by default in the client, so you can just run the client and your good to go. \
For anyone who is curious, the server "IP" is `wss://youcube.onrender.com`

#### Requirements

- [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds)
- [Python 3.7+](https://www.python.org/downloads/)
  - [aiohttp](https://pypi.org/project/aiohttp/)
  - [yt-dlp](https://pypi.org/project/yt-dlp/)

[aiohttp](https://pypi.org/project/aiohttp/) and [yt-dlp](https://pypi.org/project/yt-dlp/) can be installed through [pip](https://pip.pypa.io/en/stable/installation/). \
This can be archived by running `pip install -r server/requirements.txt`

#### Running the Server

```bash
python server/youcube.py
```

### Client

The client can be installed by running the following command:

```shell
wget https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```

#### Running the Client

```text
youcube
```

#### Trying out YouCube

```shell
wget run https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```
