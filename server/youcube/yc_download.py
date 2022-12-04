#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Download Functionality of YC
"""

# Built-in modules
from tempfile import TemporaryDirectory
from asyncio import run_coroutine_threadsafe
from os import listdir
from os.path import join, dirname, abspath
from os import getenv

# Local modules
from yc_logging import YTDLPLogger, logger, NO_COLOR
from yc_magic import run_with_live_output
from yc_colours import Foreground, RESET
from yc_utils import (
    remove_ansi_escape_codes,
    remove_whitespace,
    cap_width_and_height,
    fix_data_fodler,
    is_audio_already_downloaded,
    is_video_already_downloaded,
    get_audio_name,
    get_video_name
)

# pip modules
from yt_dlp import YoutubeDL
from aiohttp.web import WebSocketResponse

# pylint settings
# pylint: disable=pointless-string-statement
# pylint: disable=fixme
# pylint: disable=too-many-locals

DATA_FOLDER = join(dirname(abspath(__file__)), "data")
FFMPEG_PATH = getenv("FFMPEG_PATH") or "ffmpeg"
SANJUUNI_PATH = getenv("SANJUUNI_PATH") or "sanjuuni"


# pylint: disable-next=too-many-arguments
def download_video(
    temp_dir: str,
    media_id: str,
    resp: WebSocketResponse,
    loop,
    width: int,
    height: int
):
    """
    Converts the downloaded video to 32vid
    """
    run_coroutine_threadsafe(resp.send_json({
        "action": "status",
        "message": "Converting video to 32vid ..."
    }), loop)

    if NO_COLOR:
        prefix = "[Sanjuuni]"
    else:
        prefix = f"{Foreground.BRIGHT_YELLOW}[Sanjuuni]{RESET} "

    def handler(line):
        logger.debug("%s%s", prefix, line)
        run_coroutine_threadsafe(resp.send_json({
            "action": "status",
            "message": line
        }), loop)

    returncode = run_with_live_output(
        [
            SANJUUNI_PATH,
            "--width=" + str(width),
            "--height=" + str(height),
            "-i", join(temp_dir, listdir(temp_dir)[0]),
            "--raw",
            "-o", join(
                DATA_FOLDER,
                get_video_name(media_id, width, height)
            )
        ],
        handler
    )

    if returncode != 0:
        run_coroutine_threadsafe(resp.send_json({
            "action": "error",
            "message": "Faild to convert video!"
        }), loop)


def download_audio(temp_dir: str, media_id: str, resp: WebSocketResponse, loop):
    """
    Converts the downloaded audio to dfpwm
    """
    run_coroutine_threadsafe(resp.send_json({
        "action": "status",
        "message": "Converting audio to dfpwm ..."
    }), loop)

    if NO_COLOR:
        prefix = "[FFmpeg]"
    else:
        prefix = f"{Foreground.BRIGHT_GREEN}[FFmpeg]{RESET} "

    def handler(line):
        logger.debug("%s%s", prefix, line)
        # TODO: send message to resp

    returncode = run_with_live_output(
        [
            FFMPEG_PATH,
            "-i", join(temp_dir, listdir(temp_dir)[0]),
            "-f", "dfpwm",
            "-ar", "48000",
            "-ac", "1",
            join(DATA_FOLDER, get_audio_name(media_id))
        ],
        handler
    )

    if returncode != 0:
        run_coroutine_threadsafe(resp.send_json({
            "action": "error",
            "message": "Faild to convert audio!"
        }), loop)


def download(url: str, resp: WebSocketResponse, loop, width: int, height: int) -> str:
    """
    Downloads and converts the media from the give URL
    """

    def my_hook(info):
        """https://github.com/yt-dlp/yt-dlp#adding-logger-and-progress-hook"""
        if info.get('status') == "downloading":
            run_coroutine_threadsafe(resp.send_json({
                "action": "status",
                "message": remove_ansi_escape_codes(
                    # pylint: disable-next=line-too-long
                    f"download {remove_whitespace(info.get('_percent_str'))} ETA {info.get('_eta_str')}"
                )
            }), loop)

    with TemporaryDirectory(prefix="youcube-") as temp_dir:
        yt_dl_options = {
            "format": "mp4",
            "outtmpl": join(temp_dir, "%(id)s.%(ext)s"),
            "default_search": "auto",
            "restrictfilenames": True,
            "extract_flat": "in_playlist",
            "progress_hooks": [my_hook],
            'logger': YTDLPLogger(),
        }

        yt_dl = YoutubeDL(yt_dl_options)

        run_coroutine_threadsafe(resp.send_json({
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

        if width is None or height is None:
            video = False
        else:
            video = True
            # cap height and width
            width, height = cap_width_and_height(width, height)

        fix_data_fodler()

        audio_downloaded = is_audio_already_downloaded(media_id)
        video_downloaded = is_video_already_downloaded(media_id, width, height)

        if not audio_downloaded or (not video_downloaded and video):
            run_coroutine_threadsafe(resp.send_json({
                "action": "status",
                "message": "Downloading resource ..."
            }), loop)

            yt_dl.process_video_result(data, download=True)

        # TODO: Thread audio & video download

        if not audio_downloaded:
            download_audio(temp_dir, media_id, resp, loop)

        if not video_downloaded and video:
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
