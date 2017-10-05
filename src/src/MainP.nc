#include "messages.h"
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
		// TODO Auto-generated method stub
		
	}
	event void Timer.fired(){
		// TODO Auto-generated method stub
	}
	event void TDMALinkSnd.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	

	 event void Read.readDone(error_t error,THL_msg_t msg){
		if(error != SUCCESS || msg != NULL){
			dataToSend.humidity = msg.humidity;
			dataToSend.photo =  msg.photo;
			dataToSend.temperature = msg.temperature;
			dataToSend.vref=  msg.vref;
	}
}

	event void TDMAControl.sendTime(){
		// TODO Auto-generated method stub
		 call Read.read();
		if(dataToSend != NULL){
			call TDMAControl.sendData(dataToSend);
		}
	}

	event void TDMAControl.sendDone(error_t error){
		// TODO Auto-generated method stub
		if(error == SUCCESS ){	
		}
	}

	event void TDMAControl.startDone(error_t err, bool is_head){
		// TODO Auto-generated method stub
	}

	event message_t * TDMALinkRcv.receive(message_t *msg, void *payload, uint8_t len){
		// TODO Auto-generated method stub
		return msg;
	}
}
