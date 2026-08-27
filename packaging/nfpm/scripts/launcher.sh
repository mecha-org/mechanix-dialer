#!/bin/sh
APPDIR="/usr/share/mechanix/mechanix-dialer"
exec "$APPDIR/mechanix_dialer" --bundle="$APPDIR" "$@"
