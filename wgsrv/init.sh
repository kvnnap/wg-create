#!/bin/bash

echo "Starting up tunnel interface.."
wg-quick up server

trap '[[ $SLEEP_PID ]] && kill $SLEEP_PID' SIGTERM
sleep infinity &
SLEEP_PID=$!
wait $SLEEP_PID

echo "Shutting down tunnel interface.."
wg-quick down server
