# Maintainer https://github.com/Tetricz
# https://hub.docker.com/_/python?tab=description

FROM alpine:latest as downloader
# https://github.com/ytdl-org/youtube-dl/releases
ARG YTDL_VERSION=2021.04.26
RUN apk add --no-cache curl \
 && curl -L https://github.com/ytdl-org/youtube-dl/releases/download/${YTDL_VERSION}/youtube-dl -o /youtube-dl

FROM python:3-alpine

COPY ./entrypoint.bash ./
COPY ./data/* ./
COPY --from=downloader /youtube-dl /usr/bin/youtube-dl

ENV UID="1000" \
 GID="1000" \
 TIME_INTERVAL="600" \
 COOKIES="false" \
 QUIET="TRUE" \
 FORMAT="bestvideo+bestaudio/best" \
 NAMING_CONVENTION="%(format_id)s-%(title)s.%(ext)s" \
 PROXY= \
 DATE=

RUN apk add --no-cache bash dos2unix ffmpeg procps \
 && mkdir -p /config/ \
 && mkdir -p /data/ \
 && chmod a+rx ./entrypoint.bash /usr/bin/youtube-dl

ENTRYPOINT ["./entrypoint.bash"]