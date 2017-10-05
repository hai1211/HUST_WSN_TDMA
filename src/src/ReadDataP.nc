#include "messages.h"
module ReadDataP{
	provides interface ReadData;
	uses{
		interface Leds;
		interface Read<uint16_t> as Humidity;
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Vref;
		interface Read<uint16_t> as Photo;
		interface Read<uint16_t> as Radiation;
		}
}
implementation{
	THL_msg_t data;
	message_t auxmsg;
	uint8_t numsensors = 0;

	event void Humidity.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.humidity = val;
		if (++numsensors == MAX_SENSORS){
			signal ReadData.readDone(SUCCESS, data);
		call Leds.led1On();
		}
	}

	event void Temperature.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.temperature = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
		}
	}

	event void Vref.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.vref = val;
		if(++numsensors ==  MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
		}
	}

	event void Photo.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.photo = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
		}
	}

	event void Radiation.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.radiation = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
		}
	}	


	command error_t ReadData.read(){
		// TODO Auto-generated method stub
		call Photo.read();
		call Vref.read();
		call Radiation.read();
		call Temperature.read();
		call Humidity.read();
		return;
	}
}