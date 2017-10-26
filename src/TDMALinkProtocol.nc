#include "messages.h"
interface TDMALinkProtocol{
	 
#pragma mark - Start stop part 
	command error_t start(uint32_t system_time, uint8_t slot_id);
	event void startDone(error_t err, bool is_head);
	command void stop();
	event void stopDone(error_t err);
	
#pragma mark - Prepare data and make it ready for transmission
	event void preparePacket();
	command error_t dataIsReady(DataMsg *msg);

#pragma mark - Send and recv
	event void sendDone(error_t error);	// After the data is sent, this will be call if anything happens

#pragma mark - Get set other data
	command uint8_t getCurrentSlot();
	
#pragma mark - Debug
	command bool isRunning();
	command void debug();
}