#include "messages.h"
module Run_20171P{
	uses {
		interface Leds;
		interface Boot;
		interface TDMALinkProtocol as TDMAControl;
		interface ReadData as Read;
		interface Timer<TMilli> as TimerDbg;		
	}
}
implementation{
	DataMsg *dataToSend;

	event void Boot.booted(){
		call Leds.led0On();
		call TDMAControl.start(0,0);
		call TimerDbg.startPeriodic(2048);
	}
	
	event void Read.readDone(error_t error, DataMsg *msg){
		if(error == SUCCESS){
			dataToSend = msg;
			call TDMAControl.dataIsReady(msg);
		}
	}

	event void TDMAControl.sendDone(error_t error){
		// TODO Future task
		#ifdef DEBUG_1
		printf("[DEBUG] TDMA Data Send Done!\n");
		printfflush();
		#endif
	}

	event void TDMAControl.startDone(error_t err, bool is_head){
		// TODO Future task
		call TDMAControl.debug();
	}

	event void TDMAControl.stopDone(error_t err){
		// TODO Future task
	}

	event void TimerDbg.fired(){
		call Leds.led1Toggle();
		#ifdef DEBUG_1
		if(call TDMAControl.isRunning())
			printf("Running\n");
		printfflush();
		#endif
	}

	event void TDMAControl.preparePacket(){
		// TODO Auto-generated method stub
		call Read.read();
	}
}
