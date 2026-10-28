#!/vendor/bin/sh
# Mark every block device of the internal UFS (1d84000.ufshc) read-only and
# link the modem EFS partitions for rmtfs. Android never mounts the UFS; it
# is probed only so that rmtfs can read the EFS (with RAM shadows). If any
# step fails, the property is not set and rmtfs and tqftpserv do not start.
links=/dev/block/rmtfs
mkdir -p $links || exit 1
for sysdev in /sys/class/block/*; do
    case "$(readlink -f $sysdev)" in
        */1d84000.ufshc/*) ;;
        *) continue ;;
    esac
    dev=/dev/block/${sysdev##*/}
    blockdev --setro $dev || exit 1
    [ "$(blockdev --getro $dev)" = 1 ] || exit 1
    label=$(sed -n 's/^PARTNAME=//p' $sysdev/uevent)
    case "$label" in
        modemst1|modemst2|fsg|fsc) ln -sf $dev $links/$label || exit 1 ;;
    esac
done
for label in modemst1 modemst2 fsg; do
    [ -b $links/$label ] || exit 1
done
setprop vendor.curtana.efs_readonly 1
