#!/bin/bash

consulCommand() {
    consul-cli --quiet --consul="${CONSUL}:8500" $*
}

onStart() {
    logDebug "onStart"

    while true
    do
        logDebug "Waiting for NATS"
        tries=$((tries + 1))
        local nats=$(consulCommand health service nats | jq '.[0].Node.Address' --raw-output)
        if [[ $? -eq 0 ]]; then
            exec natsboard --nats-mon-url http://$nats:8222 $*
            break
        elif [[ $tries -eq 60 ]]; then
            echo "No NATS server"
            exit 1
        fi
        sleep 1
    done
}

health() {
    logDebug "health"

    /usr/bin/curl -o /dev/null --fail -s http://localhost:3000/
    if [[ $? -ne 0 ]]; then
        echo "natsboard health endpoint failed"
        exit 1
    fi
}

onChange() {
  logDebug "Killing node process and restarting"
  pkill -SIGKILL node
}

logDebug() {
    if [[ "${LOG_LEVEL}" == "DEBUG" ]]; then
        echo "manage: $*"
    fi
}

help() {
    echo "Usage: ./manage.sh onStart        => first-run configuration"
    echo "       ./manage.sh onChange       => restart natsboard"
    echo "       ./manage.sh health         => health check natsboard"
}

until
    cmd=$1
    if [[ -z "$cmd" ]]; then
        help
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    help
    exit
done
