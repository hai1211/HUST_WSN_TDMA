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
	uint8_t numsensors = 0;

	event void Humidity.readDone(error_t result, uint16_t val){
		data.humidity = val;
		if (++numsensors == MAX_SENSORS){
			signal ReadData.readDone(SUCCESS, data);
			numsensors = 0;
		call Leds.led1On();
		}
	}

	event void Temperature.readDone(error_t result, uint16_t val){
		// TODO Auto-generated method stub
		data.temperature = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
			numsensors = 0;
		}
	}

	event void Vref.readDone(error_t result, uint16_t val){
		data.vref = val;
		if(++numsensors ==  MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
			numsensors = 0;
		}
	}

	event void Photo.readDone(error_t result, uint16_t val){
		data.photo = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
			numsensors = 0;
		}
	}

	event void Radiation.readDone(error_t result, uint16_t val){
		data.radiation = val;
		if(++numsensors == MAX_SENSORS){
			call Leds.led1On();
			signal ReadData.readDone(SUCCESS, data);
			numsensors = 0;
		}
	}	


	command error_t ReadData.read(){
		call Photo.read();
		call Vref.read();
		call Radiation.read();
		call Temperature.read();
		call Humidity.read();
		return SUCCESS;
	}
}