# TODO: change from ffmpeg 5.1+ to yt-dlp/FFmpeg
FROM jrottenberg/ffmpeg:5.1-alpine as ffmpeg

FROM alpine:latest as sanjuuni

# TODO: use the same ffmpeg for sanjuuni
RUN set -x \
    && apk add --update git g++ zlib-dev poco-dev make ffmpeg-dev \
    && git clone https://github.com/MCJack123/sanjuuni.git \
    && cd sanjuuni \
    && ./configure \
    && make

FROM alpine:latest AS builder

COPY requirements.txt .

ENV \
    # yt-dlp cache dir
    XDG_CACHE_HOME="/opt/server/.yt-dlp-cache" \
    # Make sure we use the virtualenv:
    PATH="/opt/venv/bin:$PATH"

RUN set -x \
    && apk add --update python3 py3-pip gcc libc-dev \
    # Create virtualenv
    && python3 -m venv /opt/venv \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --use-pep517 -r requirements.txt

FROM alpine:latest

WORKDIR /opt/server

RUN set -x \
    && apk add --update python3 \
    # ffmpeg requirements
    libgcc libstdc++ ca-certificates libcrypto1.1 libssl1.1 libgomp expat \
    # sanjuuni requirements
    poco \
    && chown 1000 /opt/server/

COPY --from=builder /opt/venv /opt/venv
# add ffmpeg
COPY --from=ffmpeg /usr/local /usr/local
# add sanjuuni
COPY --from=sanjuuni /sanjuuni/sanjuuni /usr/local/bin

ENV \
    # Make sure we use the virtualenv:
    PATH="/opt/venv/bin:$PATH" \
    # Use ffmpeg libs
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64

USER 1000

COPY youcube/* ./

ENTRYPOINT ["python3", "youcube.py"]
