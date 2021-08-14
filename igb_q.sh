#!/bin/bash
# intel I211
# https://github.com/pcengines/apu2-documentation/issues/190
# igb modprobe
# options igb IntMode=2 QueuePairs=0 RSS=2

## enable rss 2 queues
# ethtool -K enp4s0 rx-hashing on
# ethtool -X enp4s0 equal 2
#
## enable rps
# echo FFFFFFFF > /sys/class/net/enp4s0/queues/rx-0/rps_cpus
# echo FFFFFFFF > /sys/class/net/enp4s0/queues/rx-1/rps_cpus

## enable rfs
# sudo sysctl -w net.core.rps_sock_flow_entries=32768
# echo 16384 > /sys/class/net/enp4s0/queues/rx-0/rps_flow_cnt
# echo 16384 > /sys/class/net/enp4s0/queues/rx-1/rps_flow_cnt
# ethtool -N enp4s0 rx-flow-hash tcp4 sdfn
# ethtool -N enp4s0 rx-flow-hash udp4 sdfn

## enable ntuple-filters
# ethtool -K enp4s0 ntuple on

## enable xps
# echo FFFFFFFF > /sys/class/net/enp4s0/queues/tx-0/xps_cpus
# echo FFFFFFFF > /sys/class/net/enp4s0/queues/tx-1/xps_cpus

## Set IRQ affinity
# IRQS=$(egrep  "enp4s0-[r|t]x-[0-9]" /proc/interrupts | awk -F: '{sub(/^[ ]+/, ""); print $1}')
# for IRQ in "$IRQS"; do
#    echo FFFFFFFF > /proc/irq/"$IRQ"/smp_affinity
# done

DEVICE="enp4s0"

echo RSS
echo ==========
ethtool -k "$DEVICE" | grep receive-hashing
echo
ethtool  -x "$DEVICE"
echo

echo RPS_RFS
echo ==========
if [[ -f /proc/sys/net/core/rps_sock_flow_entries ]]; then
    echo "rps_sock_flow_entries: $(cat /proc/sys/net/core/rps_sock_flow_entries)"
else
    echo FOO
fi
echo

RX_QS=$(find /sys/class/net/"$DEVICE"/queues -type d -name "rx-*" -printf "%f\n" | sort)
for Q in "$RX_QS"; do
    echo "queue: $Q"
    if [[ -f /sys/class/net/"$DEVICE"/queues/"$Q"/rps_cpus ]]; then
        echo "rps_cpus: $(cat /sys/class/net/"$DEVICE"/queues/"$Q"/rps_cpus)"
    else
        echo FOO
    fi
    if [[ -f /sys/class/net/"$DEVICE"/queues/"$Q"/rps_flow_cnt ]]; then
        echo "rps_flow_cnt: $(cat /sys/class/net/"$DEVICE"/queues/"$Q"/rps_flow_cnt)"
    else
        echo FOO
    fi
    echo
done

echo XPS
echo ==========
TX_QS=$(find /sys/class/net/"$DEVICE"/queues -type d -name "tx-*" -printf "%f\n" | sort)
for Q in "$TX_QS"; do
    echo "queue: $Q"
    if [[ -f /sys/class/net/"$DEVICE"/queues/"$Q"/xps_cpus ]]; then
        echo "xps_cpus: $(cat /sys/class/net/"$DEVICE"/queues/"$Q"/xps_cpus)"
    else
        echo FOO
    fi
    if [[ -f /sys/class/net/"$DEVICE"/queues/"$Q"/xps_rxqs ]]; then
        echo "xps_rxqs: $(cat /sys/class/net/"$DEVICE"/queues/"$Q"/xps_rxqs)"
    else
        echo FOO
    fi
    echo
done

echo NTUPLE
echo ==========
ethtool -k "$DEVICE" | grep ntuple-filters
# https://netdev.vger.kernel.narkive.com/zcXYZRz4/ethtool-not-displaying-ntuple-nfc-rule-settings
# echo
# ethtool -n enp4s0 rx-flow-hash tcp4
# ethtool -n enp4s0 rx-flow-hash udp4
# echo

echo STATS
echo ==========
ethtool -S enp4s0 | grep queue | grep -E 'bytes|packets' | sort | awk '{$1=$1;print}'
