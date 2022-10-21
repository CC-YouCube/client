# YouCube

YouCube is a tool that streams [dfpwm](https://wiki.vexatos.com/dfpwm) files to [ComputerCraft: Tweaked](https://github.com/cc-tweaked/CC-Tweaked). The YouCube server uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds) to provide media from Services like [YouTube](https://www.youtube.com/) as [dfpwm](https://wiki.vexatos.com/dfpwm) files.

## Inastallation

### Server

#### Requirements

- [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds)
- [Python 3.7+](https://www.python.org/downloads/)
  - [websockets](https://pypi.org/project/websockets/)
  - [yt-dlp](https://pypi.org/project/yt-dlp/)

[websockets](https://pypi.org/project/websockets/) and [yt-dlp](https://pypi.org/project/yt-dlp/) can be installed through [pip](https://pip.pypa.io/en/stable/installation/). \
This can be archived by running `pip install -r server/requirements.txt`

#### Running the Server

```bash
python server/youcube.py
```

### Client

The client can be installed by running the following command:

```bash
wget run https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```

#### Running the Client

```bash
youcube
```
