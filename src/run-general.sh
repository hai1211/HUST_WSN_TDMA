#!/bin/bash

if [[ $# -lt 2 ]]; then
	echo "Usage:"
	echo "    ./run-general.sh usb_no node_addr [--debug]"
	echo "        usb_no: use command motelist for usb port number"
	echo "        node_addr: enter the node address you desire, it should be xxxx"
	echo "            x: 0-9 a-f"
	echo "        Optional:"
	echo "            --debug: turn on logging mode"
else
	motelist
	sleep 7 && make xm1000 install.0x$2 bsl,/dev/ttyUSB$1
	if [[ $* == *--debug* ]]; then
		#statements
		sleep 5 && java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200	> log_$1.txt
	fi
fi