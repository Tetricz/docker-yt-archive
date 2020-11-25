#!/bin/bash
/usr/bin/youtube-dl --version

chown -R ${UID}:${GID} /config/
chown -R ${UID}:${GID} /ytdl/

graceful_exit() #copy download archive and remove files in ram
{
    cp -vf "/tmp/.downloaded" "/config/.downloaded"
    echo "Clearing temp files"
    rm -fr /tmp/*
    echo "Shutting down..."
    exit 0
}

completion_check() #this is mainly to facilitate the copying of the download archive once a process finishes
{
    if test -f "/tmp/wait.lock"; then
        exit
    fi
    touch "/tmp/wait.lock"
    sleep 25
    m=0;
    for f in "/tmp/pids/*"
    do
        pidstring=$(cat $f|sort -n)
        IFS=$'\n' read -rd '' -a pidarray <<< "$pidstring";
        for i in "${pidarray[@]}"
        do
            if ps -p $i > /dev/null; then
                while [ -e /proc/$i ]; do sleep 0.1; done
                echo "Process ${i} has finished" && cp -f "/tmp/.downloaded" "/config/.downloaded"
                rm -f "/tmp/pids/pid.${m}"
            else
                rm -f "/tmp/pids/pid.${m}"
            fi
            let m=m+1;
        done
    done
    rm -f "/tmp/wait.lock"
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
        if ! test -f "/tmp/pids/pid.${n}"; then
        {
            echo "[debug] starting ${channelName}"
            LC_ALL=en_US.UTF-8 /usr/bin/youtube-dl ${quiet_mode} --download-archive '/tmp/.downloaded' ${cookies_enabled} ${DATE} -f ${FORMAT} -ciw -o /ytdl/${channelName}/${NAMING_CONVENTION} ${channelUrl} &
            echo $! > "/tmp/pids/pid.${n}"
        }
        else
            #this is a backup check if the process is completed but not yet caught by the completion check
            if ps -p $(cat /tmp/pids/pid.${n}) > /dev/null; then
                echo "[debug] ${channelName} still running... SKIPPING"
            else
                rm -f /tmp/pids/pid.${n}
                echo "[debug] starting ${channelName}"
                LC_ALL=en_US.UTF-8 /usr/bin/youtube-dl ${quiet_mode} --download-archive '/tmp/.downloaded' ${cookies_enabled} ${DATE} -f ${FORMAT} -ciw -o /ytdl/${channelName}/${NAMING_CONVENTION} ${channelUrl} &
                echo $! > "/tmp/pids/pid.${n}"
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
mkdir -p /tmp/pids/

trap graceful_exit SIGTERM SIGKILL SIGINT
while true
do
    runChannels
    completion_check &
    sleep ${TIME_INTERVAL}
done
