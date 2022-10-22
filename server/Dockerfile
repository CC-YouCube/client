FROM python:3

WORKDIR /opt/server

COPY requirements.txt .

ENV XDG_CACHE_HOME="/opt/server/.yt-dlp-cache"

RUN set -x \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && chown 1000 /opt/server/ \
    && wget https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz \
    && tar -xf ffmpeg-master-latest-linux64-gpl.tar.xz \
    && mv ffmpeg-master-latest-linux64-gpl/bin/* /bin/ -v

USER 1000

COPY youcube.py .

CMD ["python", "youcube.py"]
