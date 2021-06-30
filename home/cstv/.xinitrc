#!/usr/bin/env bash

# window manager

# Allow root permission to X server so Docker can use it
# TODO: Is this insecure? Is there a better alternative?
xhost +local:root

# Disable any form of screen saver / screen blanking / power management
xset s off
xset s noblank
xset -dpms

# Set background to black
hsetroot -solid '#000000'


if [ -z "$XDG_RUNTIME_DIR" ]; then
    printf "XDG_RUNTIME_DIR isn't set\n" >&2
    exit 6
fi

_DISPLAY="$(systemd-escape -- "$DISPLAY")"
trap "rm -f $(printf '%q' "${XDG_RUNTIME_DIR}/x11-wm@${_DISPLAY}")" EXIT
mkfifo "${XDG_RUNTIME_DIR}/x11-wm@${_DISPLAY}"

cat < "${XDG_RUNTIME_DIR}/x11-wm@${_DISPLAY}" &
systemctl --user start "X11@${_DISPLAY}.target" &
wait
systemctl --user stop "X11@${_DISPLAY}.target"
