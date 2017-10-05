#include "messages.h"
//#include <printf.h>
module MainP{
	uses {
		
		interface Leds;
		interface Boot;
		interface Timer<T32khz>;
		interface AMSend as TDMALinkSnd;
		interface Packet;
		interface Receive as TDMALinkRcv;
		interface TDMALinkProtocol as TDMAControl;
		interface ReadData as Read;		
	}
}
implementation{
	THL_msg_t dataToSend;
	message_t auxmsg;
	uint8_t numsensors = 0;
	

	event void Boot.booted(){
			call TDMAControl.start(0,0);
	}
	event void Timer.fired(){
		call Read.read();
	}
	event void TDMALinkSnd.sendDone(message_t *msg, error_t error){
		if(error != SUCCESS){
			//printf("Send fail..");
		}
	}

	

	 event void Read.readDone(error_t error,THL_msg_t msg){
		if(error != SUCCESS || msg != NULL){
			dataToSend.humidity = msg.humidity;
			dataToSend.photo =  msg.photo;
			dataToSend.temperature = msg.temperature;
			dataToSend.vref=  msg.vref;
			dataToSend.radiation = msg.radiation;
	}
}

	event void TDMAControl.sendTime(){
		if(dataToSend != NULL){
			call TDMAControl.sendData(dataToSend);
		}
	}

	event void TDMAControl.sendDone(error_t error){
		if(error == SUCCESS ){	
		}
	}

	event void TDMAControl.startDone(error_t err, bool is_head){
		if(is_head = FALSE){
			call Timer.startOneShot(20);
		}
	}

	event message_t * TDMALinkRcv.receive(message_t *msg, void *payload, uint8_t len){
		return msg;
	}
}
