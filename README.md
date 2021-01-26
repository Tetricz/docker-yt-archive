# yt-dl channels

## Quick Start
If you happen to enable cookies, make sure there is a cookies.txt file in your appdata location.
volume mapping
```
/your/directory:/config/   (channels.txt and .downloaded archive)
/your/directory:/data/     (the folders for the youtube channels)
```
### Docker Compose
```
version: '3'
services:
    yt-dl:
        restart: unless-stopped
        container_name: yt-archive
        image: tetricz/yt-archive
        volumes:
         - </your/directory>:/config
         - </your/directory>:/data
        environment:
         - COOKIES="FALSE"
         - TIME_INTERVAL="600"
         - QUIET="TRUE"
         - UID="1000"
         - GID="1000"
        tmpfs:
         - /tmp:rw,noexec,nosuid,size=1g
```
### Docker Run
```
docker run -dit --tmpfs /tmp:rw,noexec,nosuid,size=1g -v </your/directory>:/data -v </your/directory>:/config --name yt-archive tetricz/yt-archive
```