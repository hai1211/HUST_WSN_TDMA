#include "messages.h"
#define LIGHT_SHOW
#ifdef DEBUG
#include "printf.h"
#endif

configuration Run_20171C{
	
}
implementation{
	components MainC;
	components Run_20171P as App;
	App.Boot			->	MainC.Boot;
	
	components TDMALinkC;
	App.TDMAControl		->	TDMALinkC.TDMALinkProtocol;
	components ReadDataC;
	App.Read			->	ReadDataC.ReadData;
	
	components new TimerMilliC() as TimerDebug;
	App.TimerDbg		->	TimerDebug;	
	
	#ifdef DEBUG
	components SerialStartC;
	components PrintfC;
	#endif
	
	#ifdef LIGHT_SHOW
	components LedsC;
	App.Leds -> LedsC.Leds;
	#endif
}