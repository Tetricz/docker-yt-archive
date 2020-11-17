#!/bin/bash
currentver="$(/usr/bin/youtube-dl --version)";
echo "youtube-dl version $currentver installed"

chown -R ${UID}:${GID} /config/
chown -R ${UID}:${GID} /ytdl/

graceful_exit()
{
    echo "[debug] Shutting down..."
    cp -vf "/tmp/.downloaded" "/config/.downloaded"
    echo "[debug] Clearing temp files"
    rm /tmp/*
    exit 0
}

runChannels()
{
    cp -vf "/config/channels.txt" "/tmp/.channels.txt.copy"
    dos2unix "/tmp/.channels.txt.copy"
    n=0;
    while IFS= read -r line
    do
        readarray -d " " -t strarr <<< "$line"
        channelUrl=$(echo "${strarr[0]}" | tr -d '\n')
        channelName=$(echo "${strarr[1]}" | tr -d '\n')
        if ! test -f "/tmp/pid.${n}"; then
        {
            echo "[debug] checking ${channelName}"
            LC_ALL=en_US.UTF-8 /usr/bin/youtube-dl ${quiet_mode} --download-archive '/tmp/.downloaded' ${cookies_enabled} ${DATE} -f ${FORMAT} -ciw -o /ytdl/${channelName}/${NAMING_CONVENTION} ${channelUrl} &
            echo $! > "/tmp/pid.${n}"
        }
        else
            echo "[debug] checking ${channelName}"
            if ps -p $(cat /tmp/pid.${n}) > /dev/null; then
                echo "[debug] ${channelName} still running... SKIPPING"
            else
                rm /tmp/pid.${n}
                echo "[debug] checking ${channelName}"
                LC_ALL=en_US.UTF-8 /usr/bin/youtube-dl ${quiet_mode} --download-archive '/tmp/.downloaded' ${cookies_enabled} ${DATE} -f ${FORMAT} -ciw -o /ytdl/${channelName}/${NAMING_CONVENTION} ${channelUrl} &
                echo $! > "/tmp/pid.${n}"
            fi
        fi
        let n=n+1;
    done < /tmp/.channels.txt.copy
    line="";
    rm -vf "/tmp/.channels.txt.copy"
}


if ! test -f "/config/channels.txt"; then
    cp -v channels.txt /config/channels.txt
fi
if ! test -f "/config/.downloaded"; then
    touch "/config/.downloaded"
fi
if [ "${COOKIES}" == "true" ] || [ "${COOKIES}" == "TRUE" ];
then
    cookies_enabled="--cookies /config/cookies.txt";
else
    cookies_enabled="";
fi
if [ "${QUIET}" == "true" ] || [ "${QUIET}" == "TRUE" ];
then
    quiet_mode="--quiet";
else
    quiet_mode="";
fi
cp -vf "/config/.downloaded" "/tmp/.downloaded"

while true
do
    trap graceful_exit SIGTERM SIGKILL SIGINT
    runChannels
    cp -vf "/tmp/.downloaded" "/config/.downloaded"
    sleep ${TIME_INTERVAL}
done
