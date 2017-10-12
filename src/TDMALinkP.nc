#include <Timer.h>
#include "messages.h"

#ifdef DEBUG
#include "printf.h"
#endif

// 
#define RESYNC_THRESHOLD 5
// Minimum inactive slots to enter power saving
#define SLEEP_SLOTS_THRESHOLD 1

#ifndef SLOT_DURATION
#define SLOT_DURATION	20 	// Millis
#endif
#ifndef MAX_SLAVES
#define MAX_SLAVES		5	// Num of slaves
#endif

#define HEAD_ADDR	0x0000
#define SYNC_SLOT	0
#define JOIN_SLOT	1
#define TOTAL_SLOTS (MAX_SLAVES+2)
#define LAST_SLOT (TOTAL_SLOTS-1)
#define SLOTS_UNAVAILABLE 0

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
		interface Leds;
		interface Random as JoinReqRandom;
		interface Timer<T32khz> as JoinReqDelayTimer;
	}
}
implementation{
#pragma mark - Global var
	am_addr_t head_addr = HEAD_ADDR;
	bool sync_mode = FALSE;
	bool is_started = FALSE;
	bool sync_received = FALSE;
	uint8_t assigned_slot;
	bool has_joined = FALSE;
	uint8_t missed_sync_count = 0;
	am_addr_t allocated_slots[MAX_SENSORS];
	uint8_t next_free_slot_pos;
	
	bool data_ready = FALSE;
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
//		call Leds.led2Toggle();
		#ifdef DEBUG
		printf("[DEBUG] Radio On\n");
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
		printf("[DEBUG] Radio Off\n");
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
			printf("[DEBUG] Master node %u started [SLAVE SLOTS:%u | SLOT DURATION:%ums | EPOCH DURATION:%ums]\n", TOS_NODE_ID, MAX_SLAVES, SLOT_DURATION, (MAX_SLAVES + 2) * SLOT_DURATION);
			printfflush();
			#endif
		} else {
			join_req_msg = (JoinReqMsg*) call JoinReqSend.getPayload(&join_req_packet, sizeof(JoinReqMsg));
			#ifdef DEBUG
			printf("[DEBUG] Slave node %u started\n", TOS_NODE_ID);
			printf("[DEBUG] Entering SYNC MODE\n");
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
		printf("[DEBUG] Slot scheduler started with slot no: %d\n", slot_id);
		printfflush();
		#endif

		//Turn radio on, if it's already on execute slot task immediately
		if(call RadioControl.start() == EALREADY) {
			#ifdef DEBUG
			printf("[DEBUG] Radio already started!\n");
			printfflush();
			#endif
			startSlotTask();
		}
	}
	
	void startSlotTask() {
		//At this point it is guaranteed that the radio is already on

		uint8_t slot = call SlotScheduler.getScheduledSlot();
		if(head_addr == TOS_NODE_ID) {
			if(slot == SYNC_SLOT) {
				sendSyncBeacon();
			}
			return;
		}

		if(slot == SYNC_SLOT)
			sync_received = FALSE;
		else if (slot == JOIN_SLOT)
			sendJoinRequest();
		else
			signal TDMAProtocol.sendTime();
	}
	
	uint8_t getNextMasterSlot(uint8_t slot) {
		//Listen for join requests
		if(slot == SYNC_SLOT)
			return JOIN_SLOT;

		//Schedule for next allocated data slot
		if(slot < next_free_slot_pos + 1)
			return slot+1;

		//No more allocated data slots to listen to, schedule for next epoch sync beaconing
		return SYNC_SLOT;
	}
	
	uint8_t getNextSlaveSlot(uint8_t slot) {
		if(slot == SYNC_SLOT && sync_received == FALSE) {
			missed_sync_count++;
			#ifdef DEBUG
			printf("[DEBUG] Missed synchronization beacon %d/%d\n", missed_sync_count, RESYNC_THRESHOLD);
			printfflush();
			#endif

			//Go to resync mode
			if(missed_sync_count >= RESYNC_THRESHOLD) {
				sync_mode = TRUE;
				return SYNC_SLOT;
			}
		}

		//If node needs to join try to join in next slot
		if(slot == SYNC_SLOT && has_joined == FALSE)
			return JOIN_SLOT;

		//If join failed, retry in the next epoch
		if(slot == JOIN_SLOT && has_joined == FALSE) {
			#ifdef DEBUG
			printf("[DEBUG] Missing join answer\n");
			printfflush();
			#endif
			return SYNC_SLOT;
		}

		//Reschedule for sync in next epoch
		if(slot == assigned_slot)
			return SYNC_SLOT;

		//Transmit data (if any) in the assigned slot
		if(data_ready == TRUE)
			return assigned_slot;
		else
			return SYNC_SLOT;
	}
	
	event uint8_t SlotScheduler.slotEnded(uint8_t slot) {
		uint8_t nextSlot;
		uint8_t inactivePeriod;
		
		#ifdef DEBUG
		printf("[DEBUG] Slot %d ended\n", slot);
		printfflush();
		#endif

		nextSlot = (TOS_NODE_ID == 0x0000) ? getNextMasterSlot(slot) : getNextSlaveSlot(slot);

		//In sync mode the radio is always on and scheduler is not running
		if(sync_mode) {
			#ifdef DEBUG
			printf("[DEBUG] Entering SYNC MODE\n");
			printfflush();
			#endif
			call SlotScheduler.stop();
			return SYNC_SLOT;
		}

		//Count inactive slots
		if(slot < nextSlot) //next slot in same epoch
			inactivePeriod = nextSlot - slot - 1;
		else //next slot in next epoch
			inactivePeriod = TOTAL_SLOTS - (slot - nextSlot) - 1;

		//Special case with last slot immediately followed by first slot of next epoch
		if(slot == LAST_SLOT && nextSlot == SYNC_SLOT)
			inactivePeriod = 0;

		//Radio is turned off only if the number of inactive slots between this and the next slot is >= of a threshold
		if(inactivePeriod >= SLEEP_SLOTS_THRESHOLD) {
			#ifdef DEBUG
			printf("[DEBUG] Keeping radio off for the next %u inactive slots\n", inactivePeriod);
			printfflush();
			#endif
			call RadioControl.stop();
		}

		return nextSlot;
	}
	
	event void TSSend.sendDone(message_t *msg, error_t error){
		#ifdef DEBUG
		printf("[DEBUG] Time sync packet sent!\n");
		printfflush();
		#endif
	}
	
	event message_t * TSReceiver.receive(message_t *msg, void *payload, uint8_t len){
		uint32_t ref_time;
		#ifdef DEBUG
		printf("[DEBUG] Time sync packet received\n");
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
				#ifdef DEBUG
				printf("[DEBUG] Joined, start with assigned_slot: %u\n", assigned_slot);
				printfflush();
				#endif
				call SlotScheduler.start(ref_time, assigned_slot);
			} else {
				//Join phase never completed
				#ifdef DEBUG
				printf("[DEBUG] Join phase start here!\n");
				printfflush();
				#endif
				call SlotScheduler.start(ref_time, JOIN_SLOT);
			}
			#ifdef DEBUG
			printf("[DEBUG] Local scheduler started and synchronized with master scheduler\n");
			printf("[DEBUG] Entering SLOTTED MODE\n");	
			printfflush();
			#endif
		} else {
			//Synchronize the running scheduler
			call SlotScheduler.syncSystemTime(ref_time);
			#ifdef DEBUG
			printf("[DEBUG] Local scheduler synchronized with master scheduler\n");
			printfflush();
			#endif
		}

		sync_received = TRUE;
		missed_sync_count = 0;

		return msg;
	}
	
	uint8_t allocateSlot(am_addr_t slave) {
		uint8_t slot;
		//Check if slot was already allocated to the slave
		for(slot=0; slot<MAX_SLAVES; slot++) {
			if(allocated_slots[slot] == slave)
				return slot+2;
		}

		if(next_free_slot_pos >= MAX_SLAVES)
			return SLOTS_UNAVAILABLE;

		allocated_slots[next_free_slot_pos] = slave;
		return (next_free_slot_pos++) + 2;
	}
	
	void sendJoinAnswer(am_addr_t slave, uint8_t slot) {
		join_ans_msg->slot = slot;
		#ifdef DEBUG
		printf("[DEBUG] Sending join answer to 0x%04x\n", slave);
		printfflush();
		#endif
		call JoinAnsSend.send(slave, &join_ans_packet, sizeof(JoinAnsMsg));
	}

	event message_t * JoinReqRecv.receive(message_t *msg, void *payload, uint8_t len){
		am_addr_t slave;
		uint8_t alloc_slot;
		if (len != sizeof(JoinReqMsg))
			return msg;

		slave = call AMPacket.source(msg);
		#ifdef DEBUG
		printf("[DEBUG] Received join request from 0x%04x\n", slave);
		printfflush();
		#endif

		alloc_slot = allocateSlot(slave);

		//Send answer only if there are slots available
		if(alloc_slot != SLOTS_UNAVAILABLE)
			sendJoinAnswer(slave, alloc_slot);
		else {
			#ifdef DEBUG
			printf("WARNING: No slots available for slave 0x%04x\n", slave);
			printfflush();
			#endif
		}
		
		return msg;
	}

	event void JoinAnsSend.sendDone(message_t *msg, error_t error){
		#ifdef DEBUG
		if (error == SUCCESS) {
			printf("[DEBUG] JoinAns sent!\n");
			printfflush();
		}
		#endif
	}

#pragma mark - Member	
	// These are for member
	event void JoinReqSend.sendDone(message_t *msg, error_t error){
		#ifdef DEBUG
		if (error == SUCCESS) {
			printf("[DEBUG] JoinReq sent!\n");
			printfflush();
		}
		#endif
	}

	event message_t * JoinAnsRecv.receive(message_t *msg, void *payload, uint8_t len){
		if (len != sizeof(JoinAnsMsg))
			return msg;

		join_ans_msg = (JoinAnsMsg*) payload;

		assigned_slot = join_ans_msg->slot;

		#ifdef DEBUG
		printf("[DEBUG] Join completed to slot %u\n", assigned_slot);
		printfflush();
		#endif
		
		has_joined = TRUE;

		//FOR CONTROL INTERFACE: Signal that slave is ready
		is_started = TRUE;
		signal TDMAProtocol.startDone(SUCCESS, FALSE);

		return msg;
	}

	command error_t TDMAProtocol.sendData(THL_msg_t *msg){
		// TODO Auto-generated method stub
		return SUCCESS;
	}

	command uint8_t TDMAProtocol.getCurrentSlot(){
		return call SlotScheduler.getScheduledSlot();
	}
	
	void sendSyncBeacon() {
		uint8_t status;
		sync_msg = (SyncMsg *) call TSSend.getPayload(&sync_packet, sizeof(SyncMsg));
		status = call TSSend.send(AM_BROADCAST_ADDR, &sync_packet, sizeof(SyncMsg), call SlotScheduler.getSystemTime());
		#ifdef DEBUG
		printf("[DEBUG] Sending synchronization beacon\n");
//		printf("[DEBUG] SyncMsg size: %u\n", sizeof(SyncMsg));
//		printf("[DEBUG] message_t size: %u\n", sizeof(message_t));
//		printf("[DEBUG] SystemTime: %u\n", call SlotScheduler.getSystemTime());
//		printf("[DEBUG] Status: %u\n", status);
		printfflush();
		#endif
	}
	
	void sendJoinRequest() {
		// Doing Random delay before send to avoid collision
		uint32_t delay = call JoinReqRandom.rand16() % (SLOT_DURATION / 2);
		call JoinReqDelayTimer.startOneShot(delay);
	}
	
	event void JoinReqDelayTimer.fired(){
		// Delay done, sending data
		#ifdef DEBUG
		printf("[DEBUG] Sending join request to master 0x%04x\n", head_addr);
		printfflush();
		#endif
		call JoinReqSend.send(head_addr, &join_req_packet, sizeof(JoinReqMsg));
	}

	command void TDMAProtocol.debug() {
		// TODO
	}

}