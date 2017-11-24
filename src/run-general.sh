#!/bin/bash

usage() {
	echo "Usage:"
	echo "    ./run-general.sh [option] node_addr"
	echo "        node_addr: enter the node address you desire, it should be xxxx"
	echo "            x: 0-9 a-f"
	echo "        Options:"
	echo "            -d, --debug: turn on logging mode"
}
port="null"
addr="null"
valid_addr=1

debug=0
is_telosb=0

parse_argument() {
	while [[ $# -gt 0 ]]; do
		if [[ $# == 1 ]]; then
			addr="$1"
			break
		fi
		key="$1"


		case $key in
			-t|--telosb)
			is_telosb=1
			shift # past argument
			;;
			-d|--debug)
			debug=1
			shift # past argument
			;;
			*)    # unknown option
			shift # past argument
			;;
		esac
	done
}

addr_validation() {
	re='^[0-9A-F]{4}$'
	if ! [[ $addr =~ $re ]]; then
		valid_addr=-1
	fi
}

clear_log() {
	rm -r motelist.txt
	rm -r log/*.txt
}

promt_to_continue() {
	echo "Port: /dev/ttyUSB$port"
	echo "Address: 0x$addr"
	IFS=','
	motelist -c | grep "/dev/ttyUSB$port" > motelist.txt
	while read -ra sensor_type; do
		echo "Device: ${sensor_type[2]}"
	done < motelist.txt
	while true; do
		read -p "Do you wish to install this program[Y/n]?" yn
		case $yn in
			"") break;;
			[Yy]* ) break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

promt_for_port() {
	motelist
	re='^[0-9]$'
	port="null"
	while true; do
		read -p "Please select a port: " port
		if [[ $port =~ $re ]]; then
			motelist -c | grep "/dev/ttyUSB$port" > motelist.txt
			if [[ -s motelist.txt ]]; then
				break
			fi
		fi
	done
}

if [[ ! -d log ]]; then
	mkdir log
fi
parse_argument $@
addr_validation
if [[ $valid_addr -le 0 ]]; then
	usage
	exit
fi
promt_for_port
promt_to_continue
motelist -c | grep "/dev/ttyUSB"$port	> motelist.txt
IFS=","
while read -ra sensor_type; do
	if [[ ${sensor_type[2]} == *"CM5000"* ]]; then
		is_telosb=1
	elif [[ ${sensor_type[2]} == *"XM1000"* ]]; then
		is_telosb=0
	else
		exit
	fi
done < motelist.txt
if [[ $is_telosb -eq 1 ]]; then
	echo "Using config file for CM5000"
	cd CM5000
	cp -f Makefile-telosb ../Makefile
	cd ..
else
	echo "Using config file for XM1000"
	cd XM1000
	cp -f Makefile-xm1000 ../Makefile
	cd ..
fi
if [[ $is_telosb -eq 1 ]]; then
	sleep 7 && make telosb install.0x"$addr" bsl,/dev/ttyUSB"$port"
else
	sleep 7 && make xm1000 install.0x"$addr" bsl,/dev/ttyUSB"$port"
fi
clear_log
if [[ $debug -eq 1 ]]; then
	echo ""	> log/log_"$port"_0x"$addr".txt
	gnome-terminal -e "tail -f log/log_"$port"_0x"$addr".txt"


	sleep 5 && java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB"$port":115200	> log/log_"$port"_0x"$addr".txt
fi
