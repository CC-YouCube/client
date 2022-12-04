#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Black Magic with threads, asyncio and subprocesses
"""

# Built-in modules
from typing import Any, Callable
from types import FrameType
from threading import Thread
from subprocess import Popen, PIPE
from asyncio import Event
from sys import settrace


class ThreadSaveAsyncioEventWithReturnValue(Event):
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
    Thread(
        target=run_with_thread_save_asyncio_event_with_return_value,
        args=(event, func, *args)
    ).start()
    await event.wait()
    return event.result


class KillableThread(Thread):
    """
    A Thread that can be canceled by running kill on it
    https://www.geeksforgeeks.org/python-different-ways-to-kill-a-thread/
    """

    def __init__(self, *args, **keywords) -> None:
        Thread.__init__(self, *args, **keywords)
        self.killed = False

    def start(self) -> None:
        # pylint: disable-next=attribute-defined-outside-init
        self.__run_backup = self.run
        self.run = self.__run
        Thread.start(self)

    def __run(self) -> None:
        settrace(self.globaltrace)
        self.__run_backup()
        self.run = self.__run_backup

    # pylint: disable-next=unused-argument
    def globaltrace(self, frame: FrameType, event: str, arg: Any) -> None:
        """
        Allows calling "localtrace" from global
        """
        if event == 'call':
            return self.localtrace
        return None

    # pylint: disable-next=unused-argument
    def localtrace(self, frame: FrameType, event: str, arg: Any) -> None:
        """
        Uses trace to check if the Thread needs to be killed
        """
        if self.killed and event == 'line':
            raise SystemExit()
        return self.localtrace

    def kill(self) -> None:
        """Kills the Thread"""
        self.killed = True


def run_with_live_output(cmd: list, handler: Callable[[str], None]) -> int:
    """
    Runs a subprocess and allows handling output live
    """
    with Popen(
        cmd,
        stdout=PIPE,
        stderr=PIPE
    ) as process:

        def live_output():
            line = []
            while True:
                read = process.stderr.read(1)
                if read in (b"\r", b"\n"):  # handle \n and \r as new line characters
                    if len(line) != 0:  # ignore empty line
                        handler("".join(line))
                        line.clear()
                else:
                    line.append(read.decode("utf-8"))

        thread = KillableThread(target=live_output)
        thread.start()

        process.wait()
        thread.kill()

        return process.returncode

# pylint: disable=unused-argument
