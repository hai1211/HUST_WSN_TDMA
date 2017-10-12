#include "messages.h"
interface TDMALinkProtocol{
	 
#pragma mark - Start stop part 
	command error_t start(uint32_t system_time, uint8_t slot_id);
	event void startDone(error_t err, bool is_head);
	command void stop();
	event void stopDone(error_t err);
	
#pragma mark - Send and recv
	command error_t sendData(THL_msg_t *msg);	// get the data from main and compress it, send to another sensor
	event void sendDone(error_t error);	// After the data is sent, this will be call if anything happens
	event void sendTime();	// When this fired, please pack the data up and use sendData to send

#pragma mark - Get set other data
	command uint8_t getCurrentSlot();
	
#pragma mark - Debug
	command bool isRunning();
	command void debug();
}