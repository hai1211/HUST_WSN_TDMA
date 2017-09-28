#include <Timer.h>
#include "messages.h"

#define HEAD_ADDR	0x0000
#define SYNC_SLOT	0
#define JOIN_SLOT	1

module TDMALinkP{
	provides interface TDMALinkProtocol as TDMAProtocol;
	uses {
		interface SlotScheduler;
		
		interface AMPacket as Packet;
		interface SplitControl as RadioControl;
		
		// Time sync with system
		interface TimeSyncAMSend<T32khz, uint32_t> as TSSend;
		interface Receive as TSReceiver;
		interface TimeSyncPacket<T32khz, uint32_t> as TSPacket;
		
		// Send and receive Join Req
		interface AMSend as JoinReqSend;
		interface Receive as JoinReqRecv;
		
		interface AMSend as JoinAnsSend; 
		interface Receive as JoinAnsRecv;
	}
}
implementation{
#pragma mark - Global var
	bool running = FALSE;
	am_addr_t head_addr = HEAD_ADDR;
	bool syncMode = TRUE;
	bool is_started = FALSE;
	bool syncReceived = FALSE;
	
#pragma mark - Define all functions here
	void sendSyncBeacon();
	void startSlotTask();
#pragma mark - All
	event void RadioControl.startDone(error_t error){
		if(error != SUCCESS && error != EALREADY)
			call RadioControl.start();
		#ifdef DEBUG
		printf("[DEBUG] Radio On");
		printfflush();
		#endif
		
		//Check if radio was turned on by slot scheduler
		if(call SlotScheduler.isRunning())
			startSlotTask();
		
		//FOR CONTROL INTERFACE: Signal that master is ready only when radio is on for the first time
		if(TOS_NODE_ID == head_addr && is_started == FALSE) {
				is_started = TRUE;
				signal TDMAProtocol.startDone(SUCCESS, TRUE);
		}
	}

	event void RadioControl.stopDone(error_t error){
		if(error != SUCCESS && error != EALREADY)
			call RadioControl.stop();
		#ifdef DEBUG
		printf("[DEBUG] Radio Off");
		printfflush();
		#endif
		// TODO Auto-generated method stub
	}
	
#pragma mark - Head
	// These are for head
	command void TDMAProtocol.start(uint32_t system_time, uint8_t slot_id) {
		call SlotScheduler.start(system_time, slot_id);
	}
	
	event void SlotScheduler.slotStarted(uint8_t slot_id) {
		#ifdef DEBUG
		printf("[DEBUG] Slot scheduler started with slot no: %d", slot_id);
		printfflush();
		#endif

		//Turn radio on, if it's already on execute slot task immediately
		if(call RadioControl.start() == EALREADY)
			startSlotTask();
	}
	
	void startSlotTask() {
		//At this point it is guaranteed that the radio is already on

		uint8_t slot = call SlotScheduler.getScheduledSlot();
		if(head_addr == TOS_NODE_ID) {
			if(slot == SYNC_SLOT)
				sendSyncBeacon();
			return;
		}

		if(slot == SYNC_SLOT)
			syncReceived = FALSE;
		else if (slot == JOIN_SLOT)
			sendJoinRequest();
		else
			signal TDMAProtocol.sendTime();
	}
	
	event uint8_t SlotScheduler.slotEnded(uint8_t slotId) {
		return SUCCESS;
	}
	
	event void TSSend.sendDone(message_t *msg, error_t error){
		#ifdef DEBUG
		printf("[DEBUG] Time sync packet sent!");
		printfflush();
		#endif
	}
	
	event message_t * TSReceiver.receive(message_t *msg, void *payload, uint8_t len){
		#ifdef DEBUG
		printf("[DEBUG] Time sync packet received")
		printfflush();
		#endif
		uint32_t ref_time;
		if (len != sizeof(SyncMsg))
			return msg;

		//Remember master address to send unicast messages
		masterAddr = call AMPacket.source(msg);

		//Invalid sync message
		if (call TSPacket.isValid(msg) == FALSE || length != sizeof(SyncMsg))
			return msg;

		ref_time = call TSPacket.eventTime(msg);

		if(syncMode) {
			//If sync mode was active switch to slotted mode
			syncMode = FALSE;		
			if(hasJoined) {
				//Already joined, just desynchronized
				call SlotScheduler.start(ref_time, assignedSlot);
			} else {
				//Join phase never completed
				call SlotScheduler.start(ref_time, JOIN_SLOT);
			}
			#ifdef DEBUG
			printf("DEBUG: Local scheduler started and synchronized with master scheduler\n");
			printf("DEBUG: Entering SLOTTED MODE\n");	
			printfflush();
			#endif
		} else {
			//Synchronize the running scheduler
			call SlotScheduler.syncEpochTime(ref_time);
			#ifdef DEBUG
			printf("DEBUG: Local scheduler synchronized with master scheduler\n");
			printfflush();
			#endif
		}

		syncReceived = TRUE;
		missedSyncCount = 0;

		return msg;
	}
	
		event message_t * JoinReqRecv.receive(message_t *msg, void *payload, uint8_t len){
		// TODO Auto-generated method stub
		return msg;
	}

	event void JoinAnsSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

#pragma mark - Member	
	// These are for member
	event void JoinReqSend.sendDone(message_t *msg, error_t error){
		// TODO Auto-generated method stub
	}

	event message_t * JoinAnsRecv.receive(message_t *msg, void *payload, uint8_t len){
		// TODO Auto-generated method stub
		return msg;
	}

	command error_t TDMAProtocol.sendData(){
		// TODO Auto-generated method stub
		return SUCCESS;
	}

	command uint8_t TDMAProtocol.getCurrentSlot(){
		// TODO Auto-generated method stub
		return call SlotScheduler.getScheduledSlot();
	}
}