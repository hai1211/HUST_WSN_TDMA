#include "messages.h"
#define LIGHT_SHOW
configuration MainC{
	
}
implementation{
	components MainC;
	components MainP as Main;
	components TDMALinkC; 
	components ReadDataC;
	
	#ifdef DEBUG
	components SerialStartC;
	components PrintfC;
	#endif
	
	#ifdef LIGHT_SHOW
	components LedsC;
	Main.Leds -> LedsC.Leds;
	components ActiveMessageC ;
	Main.Packet 	-> ActiveMessageC;
	
	
	//TDMA
	
	
	
	
	#endif
}