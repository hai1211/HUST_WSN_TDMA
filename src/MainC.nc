#define LIGHT_SHOW
configuration MainC{
	
}
implementation{
	components MainC;
	components MainP as Main;
	
	#ifdef DEBUG
	components SerialStartC;
	components PrintfC;
	#endif
	
	#ifdef LIGHT_SHOW
	components LedsC;
	Main.Leds -> LedsC.Leds;
	#endif
}