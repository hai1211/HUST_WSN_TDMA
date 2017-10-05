#include "messages.h"
// #define LIGHT_SHOW
configuration Run_20171C{
	
}
implementation{
	components MainC;
	components Run_20171P as App;
	components TDMALinkC;
	components ReadDataC;
	
	#ifdef DEBUG
	components SerialStartC;
	components PrintfC;
	#endif
	
	#ifdef LIGHT_SHOW
	components LedsC;
	Main.Leds -> LedsC.Leds;
	#endif
}