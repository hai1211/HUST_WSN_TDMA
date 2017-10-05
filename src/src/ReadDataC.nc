#include "messages.h"
#define LIGHT_SHOW
configuration ReadDataC{
	provides interface ReadData;
}
implementation{
	components ReadDataP as Read;
	ReadData = Read;
	components new SensirionSht11C() as SensorHT;
	Read.Temperature 	-> SensorHT.Temperature;  
  	Read.Humidity 	  	-> SensorHT.Humidity;
	
	components new HamamatsuS1087ParC() as SensorPhoto;
	Read.Photo-> SensorPhoto;
	components  new HamamatsuS10871TsrC() as SensorTotal;
	Read.Radiation-> SensorTotal;
	components ActiveMessageC ;
	components LedsC;
	Read.Leds -> LedsC.Leds;
	
}