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

# pip modules
import yt_dlp
from aiohttp import web

CHUNK_SIZE = 16 * 1024
DATA_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")


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


def is_already_downloaded(media_id: str) -> bool:
    """
    Returns True if the given media is already downloaded
    """
    return os.path.exists(os.path.join(DATA_FOLDER, media_id + ".dfpwm"))


def download(url: str) -> str:
    """
    Downloads and converts the media from the give URL
    """
    with tempfile.TemporaryDirectory(prefix="youcube-") as temp_dir:
        yt_dl_options = {
            "format": "bestaudio/worstvideo+bestaudio/worstaudio/worstvideo+worstaudio/best",
            "outtmpl": os.path.join(temp_dir, "%(id)s.%(ext)s"),
            "default_search": "auto",
            "restrictfilenames": True,
            "noplaylist": True,  # currently playlist are not supported
        }

        yt_dl = yt_dlp.YoutubeDL(yt_dl_options)

        print("STATUS: extract_info")

        data = yt_dl.extract_info(url, download=False)

        if data.get("_type") == "playlist":
            data = data["entries"][0]

        media_id = data.get("id")

        if data.get("is_live"):
            return {
                "action": "error",
                "message": "Livestreams are not supported"
            }

        fix_data_fodler()

        if not is_already_downloaded(media_id):

            print("STATUS: process_video_result")

            yt_dl.process_video_result(data, download=True)

            print("STATUS: convert to dfpwm")

            final_file = os.path.join(DATA_FOLDER, media_id + ".dfpwm")

            media_file = os.path.join(temp_dir, os.listdir(temp_dir)[0])

            # pylint: disable-next=fixme
            # TODO: use yt_dl.utils.py Popen(subprocess.Popen) for ffmpeg
            os.system(
                f"ffmpeg -i {media_file} -f dfpwm -ar 48000 -ac 1 {final_file}"
            )

    return {
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

    # pylint: disable-next=fixme
    # TODO: clear() method

    def set(self):
        # pylint: disable-next=fixme
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


class Server():
    """
    The Web socket server Object
    """

    def __init__(self, logger: logging.Logger, trusted_proxies: list) -> None:
        self.logger = logger
        self.trusted_proxies = trusted_proxies

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

                    if message.get("action") == "request_media":
                        url = message.get("url")
                        response = await run_function_in_thread_from_async_function(
                            download,
                            url
                        )
                        await resp.send_json(response)

                    if message.get("action") == "get_chunk":
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
                                await resp.send_str("mister, the media has finished playing")
                            else:
                                await resp.send_bytes(chunk)

                        else:
                            await resp.send_json({
                                "action": "error",
                                "message": "You dare not use special Characters"
                            })

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
