motelist
sleep 30 && make xm1000 install.0x0000 bsl,/dev/ttyUSB0
sleep 10 && java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:115200	> log_main.txt