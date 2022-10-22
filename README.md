# YouCube

YouCube is a tool that streams [dfpwm](https://wiki.vexatos.com/dfpwm) files to [ComputerCraft: Tweaked](https://github.com/cc-tweaked/CC-Tweaked). The YouCube server uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) and [yt-dlp/FFmpeg](https://github.com/yt-dlp/FFmpeg-Builds) to provide media from Services like [YouTube](https://www.youtube.com/) as [dfpwm](https://wiki.vexatos.com/dfpwm) files.

## Inastallation

### Server

If you dont want to host your own server then you can use the public server: `wss://youcube.onrender.com` \
It might be slow, but it will do the job.

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

```bash
wget run https://raw.githubusercontent.com/Commandcracker/YouCube/main/client/youcube.lua
```

#### Running the Client

```bash
youcube
```
