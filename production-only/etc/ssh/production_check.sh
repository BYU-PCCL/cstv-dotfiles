#!/usr/bin/env bash

DATE_HOUR="$(date +%d%H)"
SAFETY_MESSAGE="Production safety check: Use ssh argument '-o SetEnv=\"FT_PRODUCTION=$DATE_HOUR\"' to connect to $(hostname)."

if [[ "$FT_PRODUCTION" != "$DATE_HOUR" ]]; then
  echo
  case "$TERM" in
    xterm*|rxvt*) echo "[1;33m$SAFETY_MESSAGE[0m";;
    *) echo "$SAFETY_MESSAGE";;
  esac
  echo
  exit 1
fi

if [[ -z "$SSH_ORIGINAL_COMMAND" ]]; then
  exec /bin/bash
else
  exec /bin/bash -c "$SSH_ORIGINAL_COMMAND"
fi
