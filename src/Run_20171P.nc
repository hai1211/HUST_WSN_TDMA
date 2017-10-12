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
	THL_msg_t dataToSend;

	event void Boot.booted(){
		call Leds.led0On();
		call TDMAControl.start(0,0);
		call TimerDbg.startPeriodic(2048);
	}
	
	event void Read.readDone(error_t error,THL_msg_t msg){
		if(error == SUCCESS){
			dataToSend = msg;
			call TDMAControl.sendData(&dataToSend);
		}
	}

	event void TDMAControl.sendTime(){
		call Read.read();
	}

	event void TDMAControl.sendDone(error_t error){
		// TODO Future task
	}

	event void TDMAControl.startDone(error_t err, bool is_head){
		// TODO Future task
	}

	event void TDMAControl.stopDone(error_t err){
		// TODO Future task
	}

	event void TimerDbg.fired(){
		call Leds.led1Toggle();
		#ifdef DEBUG
		if(call TDMAControl.isRunning())
			printf("Running\n");
		printfflush();
		#endif
	}
}
