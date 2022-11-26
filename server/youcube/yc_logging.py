#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Everything logging related
"""

# Built-in modules
from logging import (
    Formatter,
    Logger,
    StreamHandler,
    LogRecord,
    getLogger,
    DEBUG,
    INFO,
    WARNING,
    ERROR,
    CRITICAL
)
from os import getenv
from yc_colours import Foreground, RESET

LOGLEVEL = getenv("LOGLEVEL") or DEBUG
NO_COLOR = getenv("NO_COLOR") or False
# Don't call "getLogger" every time we need the logger
logger = getLogger("__main__")


class ColordFormatter(Formatter):
    """Logging colored formatter, adapted from https://stackoverflow.com/a/56944256/3638629"""

    # noinspection SpellCheckingInspection
    def __init__(self, fmt=None, datefmt="%H:%M:%S") -> None:
        super().__init__()
        self.fmt = fmt
        self.datefmt = datefmt
        self.formats = {
            DEBUG: f"{Foreground.BRIGHT_BLACK}{self.fmt}{RESET}",
            INFO: f"{Foreground.BRIGHT_WHITE}{self.fmt}{RESET}",
            WARNING: f"{Foreground.BRIGHT_YELLOW}{self.fmt}{RESET}",
            ERROR: f"{Foreground.BRIGHT_RED}{self.fmt}{RESET}",
            CRITICAL: f"{Foreground.RED}{self.fmt}{RESET}"
        }

    def format(self, record: LogRecord) -> str:
        log_fmt = self.formats.get(record.levelno)
        formatter = Formatter(log_fmt, datefmt=self.datefmt)
        return formatter.format(record)


class YTDLPLogger:
    """https://github.com/yt-dlp/yt-dlp#adding-logger-and-progress-hook"""

    def __init__(self) -> None:
        if NO_COLOR:
            self.prefix = "[yt-dlp] "
        else:
            self.prefix = f"{Foreground.BRIGHT_MAGENTA}[yt-dlp]{RESET} "

    def debug(self, msg: str) -> None:
        """Pass msg to the main logger"""

        # For compatibility with youtube-dl, both debug and info are passed into debug
        # You can distinguish them by the prefix '[debug] '
        if msg.startswith('[debug] '):
            pass
        else:
            self.info(msg)

    def info(self, msg: str) -> None:
        """Pass msg to the main logger"""
        logger.debug("%s%s", self.prefix, msg)

    def warning(self, msg: str) -> None:
        """Pass msg to the main logger"""
        logger.warning("%s%s", self.prefix, msg)

    def error(self, msg: str) -> None:
        """Pass msg to the main logger"""
        logger.error("%s%s", self.prefix, msg)


def setup_logging() -> Logger:
    """Sets the main logger up"""
    logger.setLevel(LOGLEVEL)

    # noinspection SpellCheckingInspection
    if NO_COLOR:
        formatter = Formatter(
            fmt="[%(asctime)s %(levelname)s] [YouCube] %(message)s"
        )
    else:
        formatter = ColordFormatter(
            # pylint: disable-next=line-too-long
            fmt=f"[%(asctime)s %(levelname)s] {Foreground.BRIGHT_WHITE}[You{Foreground.RED}Cube]{RESET} %(message)s"
        )

    logging_handler = StreamHandler()
    logging_handler.setFormatter(formatter)
    logger.addHandler(logging_handler)

    return logger
