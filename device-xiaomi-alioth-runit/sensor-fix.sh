#!/bin/sh
case "$1" in
  post)
    (
      sleep 2
      /usr/bin/sv restart iio-sensor-proxy-libssc
      /usr/bin/sv restart hexagonrpcd-sdsp
      /usr/bin/sv restart iio-sensor-proxy-libssc
    ) >/dev/null 2>&1 &
  ;;
esac
