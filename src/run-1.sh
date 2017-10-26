motelist
sleep 30 && make xm1000 install.0x6969 bsl,/dev/ttyUSB1
sleep 10 && java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB1:115200	> log_1.txt
