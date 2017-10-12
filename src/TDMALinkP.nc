#include <Timer.h>
#include "messages.h"

#ifdef DEBUG
#include "printf.h"
#endif

#define HEAD_ADDR	0x0000
#define SYNC_SLOT	0
#define JOIN_SLOT	1

module TDMALinkP{
	provides interface TDMALinkProtocol as TDMAProtocol;
	uses {
		interface SlotScheduler;
		
		interface AMPacket;
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
	am_addr_t head_addr = HEAD_ADDR;
	bool sync_mode = TRUE;
	bool is_started = FALSE;
	bool sync_received = FALSE;
	uint8_t assigned_slot;
	bool has_joined;
	uint8_t missed_sync_count;
	
	message_t sync_packet;
	SyncMsg *sync_msg;
	message_t join_req_packet;
	JoinReqMsg *join_req_msg;
	message_t join_ans_packet;
	JoinAnsMsg *join_ans_msg;
	
#pragma mark - Define all functions here
	void sendSyncBeacon();
	void startSlotTask();
	void sendJoinRequest();
	
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
	
	command bool TDMAProtocol.isRunning() {
		return is_started;
	}
	
	command void TDMAProtocol.stop(){
		// This is so powerful that will shut everything down
		call SlotScheduler.stop();
		call RadioControl.stop();
	}
	
	event void RadioControl.stopDone(error_t error){
		if(error != SUCCESS && error != EALREADY)
			call RadioControl.stop();
		#ifdef DEBUG
		printf("[DEBUG] Radio Off");
		printfflush();
		#endif
		if (!is_started)
			signal TDMAProtocol.stopDone(SUCCESS);
	}
	
	command error_t TDMAProtocol.start(uint32_t system_time, uint8_t slot_id) {
		if(TOS_NODE_ID == 0x0000) {
			join_ans_msg = (JoinAnsMsg*) call JoinAnsSend.getPayload(&join_ans_packet, sizeof(JoinAnsMsg));
			call SlotScheduler.start(0, SYNC_SLOT);
			#ifdef DEBUG
			printf("DEBUG: Master node %u started [SLAVE SLOTS:%u | SLOT DURATION:%ums | EPOCH DURATION:%ums]\n", TOS_NODE_ID, MAX_SLAVES, SLOT_DURATION, (MAX_SLAVES + 2) * SLOT_DURATION);
			printfflush();
			#endif
		} else {
			join_req_msg = (JoinReqMsg*) call JoinReqSend.getPayload(&join_req_packet, sizeof(JoinReqMsg));
			#ifdef DEBUG
			printf("DEBUG: Slave node %u started\n", TOS_NODE_ID);
			printf("DEBUG: Entering SYNC MODE\n");
			printfflush();
			#endif
			sync_mode = TRUE;
			call RadioControl.start();
		}
		return SUCCESS;
	}
	
#pragma mark - Head
	// These are for head
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
			sync_received = FALSE;
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
		uint32_t ref_time;
		#ifdef DEBUG
		printf("[DEBUG] Time sync packet received");
		printfflush();
		#endif
		if (len != sizeof(SyncMsg))
			return msg;

		//Remember master address to send unicast messages
		head_addr = call AMPacket.source(msg);

		//Invalid sync message
		if (call TSPacket.isValid(msg) == FALSE || len != sizeof(SyncMsg))
			return msg;

		ref_time = call TSPacket.eventTime(msg);

		if(sync_mode) {
			//If sync mode was active switch to slotted mode
			sync_mode = FALSE;		
			if(has_joined) {
				//Already joined, just desynchronized
				call SlotScheduler.start(ref_time, assigned_slot);
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
			call SlotScheduler.syncSystemTime(ref_time);
			#ifdef DEBUG
			printf("DEBUG: Local scheduler synchronized with master scheduler\n");
			printfflush();
			#endif
		}

		sync_received = TRUE;
		missed_sync_count = 0;

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

	command error_t TDMAProtocol.sendData(THL_msg_t *msg){
		// TODO Auto-generated method stub
		return SUCCESS;
	}

	command uint8_t TDMAProtocol.getCurrentSlot(){
		// TODO Auto-generated method stub
		return call SlotScheduler.getScheduledSlot();
	}
	
	void sendSyncBeacon() {
		// TODO
		#ifdef DEBUG
		printf("DEBUG: Sending synchronization beacon\n");
		printfflush();
		#endif
		sync_msg = (SyncMsg *) call TSSend.getPayload(&sync_packet, sizeof(SyncMsg));
		call TSSend.send(AM_BROADCAST_ADDR, &sync_packet, sizeof(message_t), call SlotScheduler.getSystemTime());
	}
	
	void sendJoinRequest() {
		// TODO
	}

	command void TDMAProtocol.debug() {
		// TODO
	}
}