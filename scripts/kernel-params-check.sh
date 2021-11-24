#!/bin/bash

if grep -q "hugepagesz=1G" /proc/cmdline
then
  echo "[+] Kernel is ready for Fastclick experiments"
else 
  if grep -q "hugepagesz=2M" /proc/cmdline
  then
    echo "[+] Kernel is ready for MICA experiments"
  else
    echo "[-] Missing kernel hugepage parameters!"
  fi
fi
