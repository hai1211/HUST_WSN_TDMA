#!/bin/bash

if [[ $# -lt 2 ]]; then
	echo -e "Usage:"
	echo -e "    ./run-general.sh usb_no node_addr"
	echo -e "        usb_no: use command motelist for usb port number"
	echo -e "        node_addr: enter the node address you desire, it should be xxxx\n            x: 0-9 a-f"
else
	motelist
	sleep 30 && make xm1000 install.0x$2 bsl,/dev/ttyUSB$1
fi