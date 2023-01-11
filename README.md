# YouCube

[![CC: Tweaked Version: 1.100+](https://img.shields.io/badge/CC:%20tweaked-1.100+-green?style=for-the-badge&logo=GNOME%20Terminal)](https://tweaked.cc/)
![or](.README/slash.svg)
[![CC: Tweaked Version: 1.80pr1.3+](https://img.shields.io/badge/CC:%20tweaked-1.80pr1.3+-green?style=for-the-badge&logo=GNOME%20Terminal)](https://tweaked.cc/)
![+](.README/plus.svg)
[![Computronics Version: 0.1.0+](https://img.shields.io/badge/Computronics-0.1.0+-green?style=for-the-badge)](https://wiki.vexatos.com/wiki:computronics)

[![Page deployment](https://img.shields.io/github/actions/workflow/status/CC-YouCube/client/deploy-page.yml?branch=main&label=Page%20deployment&logo=github&style=for-the-badge)](https://github.com/CC-YouCube/client/actions/workflows/deploy-page.yml)
[![Illuaminate lint](https://img.shields.io/github/actions/workflow/status/CC-YouCube/client/illuaminate-lint.yml?branch=main&label=Illuaminate%20lint&logo=github&style=for-the-badge)](https://github.com/CC-YouCube/client/actions/workflows/illuaminate-lint.yml)

YouCube streams media from services like YouTube to [ComputerCraft: Tweaked](https://github.com/cc-tweaked/CC-Tweaked). \
**Project Status: Proof of concept**

![preview](.README/preview-client.png)

<https://user-images.githubusercontent.com/49335821/207105983-f3887269-51d2-4ea2-b8f5-4c4af87ccad4.mp4>

## Installation

The client can be installed by running the following command:

```shell
pastebin run swsmNAf7
```

or

```shell
wget run https://raw.githubusercontent.com/Commandcracker/YouCube/main/installer.lua
```

### Starting the Client

```text
youcube
```

### Libraries

All libraries that are used by the [client](https://github.com/Commandcracker/YouCube/blob/main/client/youcube.lua).

| Library                                                                                               |
|-------------------------------------------------------------------------------------------------------|
| [argparse](https://github.com/Commandcracker/cc-argparse)                                             |
| [numberformatter](https://github.com/Commandcracker/YouCube/blob/main/client/lib/numberformatter.lua) |
| [semver](https://github.com/kikito/semver.lua)                                                        |
| [youcubeapi](https://github.com/Commandcracker/YouCube/blob/main/client/lib/youcubeapi.lua)           |
| [string_pack](https://gist.github.com/MCJack123/d5973e4d8b7e46991c5f99ac4b076aec)                     |

### UnicornPKG (Experimental)

YouCube can be installed with [unicornpkg](https://unicornpkg.madefor.cc/). \
Just run `hoof install youcube` to install it.

### LevelOS / lStore

[![lStore Package](https://img.shields.io/github/actions/workflow/status/CC-YouCube/client/lstore-put.yml?branch=main&label=lStore%20Package&logo=github&style=for-the-badge)](https://github.com/CC-YouCube/client/actions/workflows/lstore-put.yml)

On [LevelOS](https://discord.com/invite/vBsjGqy99U) YouCube can be installed by running `lStore get YouCube <path>` or `lStore get bpBYV1aG <path>` or by Using the StoreUI.

![preview](.README/levelos.png)

### Settings

Settings that can be set with the CC: Tweaked [settings module](https://tweaked.cc/module/settings.html#v:get)

| name                  | default | Description                                     |
|-----------------------|---------|-------------------------------------------------|
| `youcube.server`      |         | First server that should be used                |
| `youcube.keys.skip`   |   32 (d)|Key code to skip song                            |
| `youcube.keys.back`   |   30 (a)|Key code to head to previous song                |
| `youcube.max_back`    |   32    |Maximum ammount of songs that can be gone back to|

## Events

List of events that are [queued](https://tweaked.cc/module/os.html#v:queueEvent) by youcube

| Name                     | Arguments | Description                                     |
|--------------------------|-----------|-------------------------------------------------|
| `youcube:vid_eof`        | `data`    | Called, when Video playback has ended           |
| `youcube:audio_eof`      | `data`    | Called, when Audio playback has ended           |
| `youcube:fill_buffers`   |           | Internal event (called when buffers are filled) |
| `youcube:status`         | `data`    | Status of the serversided media download        |
| `youcube:playback_ended` |           | Called, when all playback has ended             |
| `youcube:vid_playing`    | `data`    | Called, when Video playback has started         |
| `youcube:audio_playing`  | `data`    | Called, when Audio playback has started         |
| `youcube:playing`        |           | Called, when playback has started               |
