#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
YouCube Server
"""

# built-in modules
import logging
import os
import tempfile
import json
import re
import asyncio
import threading
from typing import Any, Callable
from base64 import b64encode
import subprocess
import sys

# pip modules
import yt_dlp
from aiohttp import web

VERSION = "0.0.0-poc.0.0.0"
API_VERSION = "0.0.0-poc.0.0.0"  # https://commandcracker.github.io/YouCube/
CHUNK_SIZE = 16 * 1024
DATA_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
VIDEO_FORMAT = "32vid"
AUDIO_FORMAT = "dfpwm"
FFMPEG_PATH = "ffmpeg" # TODO: costomizable path + checking if the path is valid
SANJUUNI_PATH = "sanjuuni" # TODO: costomizable path + checking if the path is valid

# pylint settings
# pylint: disable=pointless-string-statement
# pylint: disable=fixme


def is_id_valide(string: str) -> bool:
    """
    Returns True if the given string does not contain special characters
    """
    return bool(re.match('^[a-zA-Z0-9-_]*$', string))


def fix_data_fodler():
    """
    Creates the data folder if it does not exist
    """
    if not os.path.exists(DATA_FOLDER):
        os.mkdir(DATA_FOLDER)


def is_audio_already_downloaded(media_id: str) -> bool:
    """
    Returns True if the given audio is already downloaded
    """
    return os.path.exists(os.path.join(DATA_FOLDER, f"{media_id}.{AUDIO_FORMAT}"))


def is_video_already_downloaded(media_id: str, width: int, height: int) -> bool:
    """
    Returns True if the given video is already downloaded
    """
    return os.path.exists(os.path.join(DATA_FOLDER, f"{media_id}({width}x{height}).{VIDEO_FORMAT}"))


def download_video(
    temp_dir: str,
    media_id: str,
    resp: web.WebSocketResponse,
    loop,
    width: int,
    height: int
):
    """
    Converts the downloaded video to 32vid
    """
    asyncio.run_coroutine_threadsafe(resp.send_json({
        "action": "status",
        "message": f"Converting video to {VIDEO_FORMAT} ..."
    }), loop)

    def handler(line):
        asyncio.run_coroutine_threadsafe(resp.send_json({
            "action": "status",
            "message": line
        }), loop)

    returncode = run_with_live_output(
        [
            SANJUUNI_PATH,
            "--width=" + str(width),
            "--height=" + str(height),
            "-i", os.path.join(temp_dir, os.listdir(temp_dir)[0]),
            "--raw",
            "-o", os.path.join(
                DATA_FOLDER,
                f"{media_id}({width}x{height}).{VIDEO_FORMAT}"
            )
        ],
        handler
    )

    if returncode != 0:
        asyncio.run_coroutine_threadsafe(resp.send_json({
            "action": "error",
            "message": "Faild to convert audio!"
        }), loop)


def download_audio(temp_dir: str, media_id: str, resp: web.WebSocketResponse, loop):
    asyncio.run_coroutine_threadsafe(resp.send_json({
        "action": "status",
        "message": f"Converting audio to {AUDIO_FORMAT} ..."
    }), loop)

    returncode = run_with_live_output(
        [
            FFMPEG_PATH,
            "-i", os.path.join(temp_dir, os.listdir(temp_dir)[0]),
            "-f", "dfpwm",
            "-ar", "48000",
            "-ac", "1",
            os.path.join(DATA_FOLDER, f"{media_id}.{AUDIO_FORMAT}")
        ],
        print  # TODO: handel ffmpeg output correctly
    )

    if returncode != 0:
        asyncio.run_coroutine_threadsafe(resp.send_json({
            "action": "error",
            "message": "Faild to convert audio!"
        }), loop)


def download(url: str, resp: web.WebSocketResponse, loop, width: int, height: int) -> str:
    """
    Downloads and converts the media from the give URL
    """
    with tempfile.TemporaryDirectory(prefix="youcube-") as temp_dir:
        yt_dl_options = {
            # "bestaudio/worstvideo+bestaudio/worstaudio/worstvideo+worstaudio/best",
            # "worstvideo+bestaudio",
            "format": "mp4",
            "outtmpl": os.path.join(temp_dir, "%(id)s.%(ext)s"),
            "default_search": "auto",
            "restrictfilenames": True,
            "extract_flat": "in_playlist"
        }

        yt_dl = yt_dlp.YoutubeDL(yt_dl_options)

        asyncio.run_coroutine_threadsafe(resp.send_json({
            "action": "status",
            "message": "Getting resource information ..."
        }), loop)

        data = yt_dl.extract_info(url, download=False)

        """
        If the data is a playlist, we need to get the first video and return it,
        also, we need to grep all video in the playlist to provide support.
        """
        playlist_videos = []

        if data.get("_type") == "playlist":
            for video in data.get("entries"):
                playlist_videos.append(video.get("id"))

            playlist_videos.pop(0)

            data = data["entries"][0]

        """
        If the video is extract from a playlist,
        the video is extracted flat,
        so we need to get missing information by running the extractor again.
        """
        if data.get("view_count") is None or data.get("like_count") is None:
            data = yt_dl.extract_info(data.get("id"), download=False)

        media_id = data.get("id")

        if data.get("is_live"):
            return {
                "action": "error",
                "message": "Livestreams are not supported"
            }

        fix_data_fodler()

        audio_downloaded = is_audio_already_downloaded(media_id)
        video_downloaded = is_video_already_downloaded(media_id, width, height)

        if not audio_downloaded or not video_downloaded:
            asyncio.run_coroutine_threadsafe(resp.send_json({
                "action": "status",
                "message": "Downloading resource ..."
            }), loop)

            yt_dl.process_video_result(data, download=True)

        # TODO: Thread audio & video download

        if not audio_downloaded:
            download_audio(temp_dir, media_id, resp, loop)

        if not video_downloaded:
            download_video(temp_dir, media_id, resp, loop, width, height)

    out = {
        "action": "media",
        "id": media_id,
        # "fulltitle": data.get("fulltitle"),
        "title": data.get("title"),
        "like_count": data.get("like_count"),
        "view_count": data.get("view_count"),
        # "upload_date": data.get("upload_date"),
        # "tags": data.get("tags"),
        # "description": data.get("description"),
        # "categories": data.get("categories"),
        # "channel_name": data.get("channel"),
        # "channel_id": data.get("channel_id")
    }

    # Only return playlist_videos if there are videos in playlist_videos
    if len(playlist_videos) > 0:
        out["playlist_videos"] = playlist_videos

    return out


# TODO: Colord logging + improvement to the style
def setup_logging() -> logging.Logger:
    """
    Creates the main YouCube Logger
    """
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    logging_handler = logging.StreamHandler()
    formatter = logging.Formatter(
        fmt='[%(asctime)s %(levelname)s] [YouCube] %(message)s', datefmt="%H:%M:%S")
    logging_handler.setFormatter(formatter)

    logger.addHandler(logging_handler)

    return logger


def get_vid(vid_file: str, line: int) -> bytes:
    """
    Returns given line of 32vid file
    """
    with open(vid_file, "r", encoding="utf-8") as file:
        lines = file.readlines()
        out = lines[line]
        file.close()

    return out[:-1]  # remove \n


def get_chunk(media_file: str, chunkindex: int) -> bytes:
    """
    Returns a chunk of the given media file
    """
    with open(media_file, "rb") as file:
        file.seek(chunkindex * CHUNK_SIZE)
        chunk = file.read(CHUNK_SIZE)
        file.close()

    return chunk


def get_peername_host(request: web.Request) -> str:
    """
    Returns the Host of the web-request
    """
    peername = request.transport.get_extra_info('peername')

    if peername is not None:
        host, *_ = peername
        return host

    return None


class UntrustedProxy(Exception):
    """
    Occurs when someone connects through an untrusted proxy
    """

    def __str__(self) -> str:
        return "A client is not using a trusted proxy!"


def get_client_ip(request: web.Request, trusted_proxies: list) -> str:
    """
    Returns the real client IP
    """
    peername_host = get_peername_host(request)

    if trusted_proxies is None:
        return peername_host

    if peername_host in trusted_proxies:
        x_forwarded_for = request.headers.get('X-Forwarded-For')

        if x_forwarded_for is not None:
            x_forwarded_for = x_forwarded_for.split(",")[0]

        return x_forwarded_for or request.headers.get('True-Client-Ip')

    raise UntrustedProxy


class ThreadSaveAsyncioEventWithReturnValue(asyncio.Event):
    """
    Thread-save version of asyncio.Event with result / Return value
    """

    def __init__(self) -> None:
        super().__init__()
        self.result = None

    # TODO: clear() method

    def set(self):
        # FIXME: The _loop attribute is not documented as public api!
        self._loop.call_soon_threadsafe(super().set)


def run_with_thread_save_asyncio_event_with_return_value(
    event: ThreadSaveAsyncioEventWithReturnValue,
    func: Callable[[], Any],
    *args
) -> None:
    """
    Runs a function and calls a ThreadSaveAsyncioEventWithReturnValue
    This function is meant to run in a thread
    """
    result = func(*args)
    event.result = result
    event.set()


async def run_function_in_thread_from_async_function(
    func: Callable[[], Any],
    *args
) -> object:
    """
    Runs a function in a thread from an async function
    """
    event = ThreadSaveAsyncioEventWithReturnValue()
    threading.Thread(
        target=run_with_thread_save_asyncio_event_with_return_value,
        args=(event, func, *args)
    ).start()
    await event.wait()
    return event.result


class KillableThread(threading.Thread):
    """
    A Thread that can be canceled by running kill on it
    https://www.geeksforgeeks.org/python-different-ways-to-kill-a-thread/
    """

    def __init__(self, *args, **keywords):
        threading.Thread.__init__(self, *args, **keywords)
        self.killed = False

    def start(self):
        # pylint: disable-next=attribute-defined-outside-init
        self.__run_backup = self.run
        self.run = self.__run
        threading.Thread.start(self)

    def __run(self):
        sys.settrace(self.globaltrace)
        self.__run_backup()
        self.run = self.__run_backup

    # pylint: disable-next=unused-argument
    def globaltrace(self, frame, event, arg):
        if event == 'call':
            return self.localtrace
        return None

    # pylint: disable-next=unused-argument
    def localtrace(self, frame, event, arg):
        if self.killed:
            if event == 'line':
                raise SystemExit()
        return self.localtrace

    def kill(self):
        self.killed = True


def run_with_live_output(cmd: list, handler: Callable[[], Any]) -> int:
    """
    Runs a subprocess and allows handling output live
    """
    with subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    ) as process:

        def live_output():
            line = ""
            while True:
                read = process.stderr.read(1)
                if read in (b"\r", b"\n"):  # handle \n and \r as new line characters
                    if line != "":  # ignore empy line
                        handler(line)
                    line = ""
                else:
                    line += read.decode("utf-8")

        thread = KillableThread(target=live_output)
        thread.start()

        process.wait()
        thread.kill()

        return process.returncode

# pylint: disable=unused-argument


class Actions():
    """
    Default set of actions
    Every action needs to be called with a message and needs to return a dict response
    """

    @staticmethod
    async def request_media(message: dict, resp: web.WebSocketResponse):
        loop = asyncio.get_event_loop()
        # TODO: check if the width and height is not too big
        return await run_function_in_thread_from_async_function(
            download,
            message.get("url"),
            resp,
            loop,
            message.get("width"),
            message.get("height")
        )

    @staticmethod
    async def get_chunk(message: dict, resp: web.WebSocketResponse):
        chunkindex = message.get("chunkindex")

        media_id = message.get("id")

        if is_id_valide(media_id):
            file = os.path.join(
                DATA_FOLDER,
                message.get("id") +
                ".dfpwm"
            )

            chunk = get_chunk(file, chunkindex)

            if len(chunk) == 0:
                return {
                    "action": "error",
                    "message": "mister, the media has finished playing"
                }

            return {
                "action": "chunk",
                "chunk": b64encode(chunk).decode("ascii")
            }

        return {
            "action": "error",
            "message": "You dare not use special Characters"
        }

    @staticmethod
    async def get_vid(message: dict, resp: web.WebSocketResponse):
        lineindex = message.get("line")
        media_id = message.get("id")

        if is_id_valide(media_id):
            file = os.path.join(
                DATA_FOLDER,
                f"{message.get('id')}({message.get('width')}x{message.get('height')}).{VIDEO_FORMAT}"
            )

            return {
                "action": "vid",
                "line": get_vid(file, lineindex)
            }

        return {
            "action": "error",
            "message": "You dare not use special Characters"
        }

    @staticmethod
    async def handshake(message: dict, resp: web.WebSocketResponse):
        return {
            "api-version": API_VERSION
        }
# pylint: enable=unused-argument


class Server():
    """
    The Web socket server Object
    """

    def __init__(self, logger: logging.Logger, trusted_proxies: list) -> None:
        self.logger = logger
        self.trusted_proxies = trusted_proxies
        self.actions = {}

        # add all actions from default action set

        for method in dir(Actions):
            if not method.startswith('__'):
                self.actions[method] = Actions.__getattribute__(
                    Actions,
                    method
                )

    async def on_shutdown(self, app: web.Application):
        """
        Clears all web-sockets from the list
        """

        for websocket in app["sockets"]:
            await websocket.close()

    def init(self):
        """
        Initialize the web-socket server
        """
        app = web.Application()
        app["sockets"] = []
        app.router.add_get("/", self.wshandler)
        app.on_shutdown.append(self.on_shutdown)
        return app

    def register_action(self, name: str, func: Callable[[], Any]):
        """
        Add and action / "endpoint" to the ws server
        """
        if name in self.actions:
            return False, f"action \"{name}\" is already registerd!"
        self.actions[name] = func
        return True

    async def wshandler(self, request: web.Request):
        """
        Handels web-socket requests
        """
        resp = web.WebSocketResponse()
        available = resp.can_prepare(request)
        if not available:
            return web.Response(
                body="You cannot access a WebSocket server directly. You need a WebSocket client.",
                content_type="text"
            )

        await resp.prepare(request)

        try:
            request.app["sockets"].append(resp)

            prefix = f"[{get_client_ip(request, self.trusted_proxies)}] "
            self.logger.info(prefix + "Connected!")

            self.logger.debug(
                prefix +
                "My headers are: " +
                str(request.headers)
            )

            async for msg in resp:
                resp: web.WebSocketResponse
                if msg.type == web.WSMsgType.TEXT:
                    self.logger.debug(prefix + "Message: " + msg.data)
                    message: dict = json.loads(msg.data)

                    if message.get("action") in self.actions:
                        response = await self.actions[message.get("action")](message, resp)
                        await resp.send_json(response)

                else:
                    return resp
            return resp

        finally:
            request.app["sockets"].remove(resp)
            self.logger.info(prefix + "Disconnected!")


def main() -> None:
    """
    Run all needed services
    """
    logger = setup_logging()
    port = int(os.environ.get("PORT", "5000"))
    trusted_proxies = os.environ.get("TRUSTED_PROXIES")

    proxies = None

    if trusted_proxies is not None:
        proxies = []
        for proxy in trusted_proxies.split(","):
            proxies.append(proxy)

    server = Server(logger, proxies)

    web.run_app(server.init(), port=port)


if __name__ == "__main__":
    main()
