#!/system/bin/sh

# Delete Morpheus dir
rm -rf /storage/emulated/0/Morpheus-Render

# Uninstall toast
pm uninstall bellavita.toast

swapoff /data/swap/swapfile
rm -rf /data/swap

for a in $(cmd package list packages |grep -v ia.mo|cut -f2 -d:);do cmd appops reset "$a";done