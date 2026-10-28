#!/vendor/bin/sh
# Start the ADSP remoteproc, found by name: its remoteproc index depends on
# probe order (the modem is probed as well).
for rproc in /sys/class/remoteproc/remoteproc*; do
    [ "$(cat $rproc/name)" = adsp ] || continue
    [ "$(cat $rproc/state)" = offline ] && echo start > $rproc/state
    exit 0
done
exit 1
