# TODO: change from ffmpeg 5.1+ to yt-dlp/FFmpeg
FROM jrottenberg/ffmpeg:5.1-alpine AS ffmpeg

FROM alpine:3.17.0 as sanjuuni

# TODO: use the same ffmpeg for sanjuuni
RUN set -eux; \
    apk add --no-cache --update g++ zlib-dev poco-dev make ffmpeg-dev; \
    wget -O sanjuuni.tar.gz https://github.com/MCJack123/sanjuuni/archive/30dcabb4b56f1eb32c88e1bce384b0898367ebda.tar.gz; \
    echo "029eb0e8853eccc74ea328bb5933678e60e2c56f03f321bf5f982643768b2877 *sanjuuni.tar.gz" | sha256sum -c -; \
    mkdir -p sanjuuni; \
    tar -xC sanjuuni --strip-components=1 -f sanjuuni.tar.gz; \
    rm sanjuuni.tar.gz;

WORKDIR /sanjuuni

RUN set -eux; \
    ./configure; \
    make

FROM ghcr.io/commandcracker/alpine-pypy3.9-pip:3.17.0-pypy-7.3.10-pip-22.3.1 AS builder

COPY requirements.txt .
COPY youcube ./youcube
COPY compile.py .

RUN set -eux; \
    apk add --no-cache --update gcc libc-dev libstdc++-dev; \
    pip install --no-cache-dir --use-pep517 -r requirements.txt; \
    python3 compile.py; \
    pip uninstall pip -y

FROM alpine:3.17.0 

WORKDIR /opt/server

RUN set -eux; \
    apk add --no-cache --update \
    # pypy requirements
    libffi libbz2 \
    # ffmpeg requirements
    libgcc libstdc++ ca-certificates libcrypto1.1 libssl1.1 libgomp expat \
    # sanjuuni requirements
    poco; \
    chown 1000 /opt/server/

COPY --from=builder /opt/pypy /opt/pypy
# add ffmpeg
COPY --from=ffmpeg /usr/local /usr/local
# add sanjuuni
COPY --from=sanjuuni /sanjuuni/sanjuuni /usr/local/bin

ENV \
    # Make sure we use the virtualenv:
    PATH="/opt/pypy/bin:$PATH" \
    # Use ffmpeg libs
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
    # yt-dlp cache dir
    XDG_CACHE_HOME="/opt/server/.yt-dlp-cache"

USER 1000

COPY --from=builder /youcube/__pycache__ /opt/server

ENTRYPOINT ["python3", "youcube.pyc"]
