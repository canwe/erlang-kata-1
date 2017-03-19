#!/bin/bash

RULE="block drop quick on lo0 proto tcp from any to any port = $2"

case $1 in
    block)
        echo "Blocking port $2"
        (pfctl -sr 2>/dev/null; echo $RULE) | pfctl -f -
        ;;
    unblock)
        echo "Unblocking all"
        (pfctl -sr 2>/dev/null | fgrep -v "$RULE") | pfctl -f -
        ;;
    clear)
        pfctl -f /etc/pf.conf
        ;;
esac

