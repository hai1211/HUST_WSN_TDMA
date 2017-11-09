#include <Timer.h>
#ifdef DEBUG
#include "printf.h"
#endif

generic module SlotSchedulerP(uint32_t slotDuration, uint8_t maxSlotId) {
	provides interface SlotScheduler;

	uses {
		interface Timer<T32khz> as EpochTimer;
		interface Timer<T32khz> as TransmitSlotTimer;
	}
} implementation {
#ifdef DEBUG
#define DEBUG_NOW
#endif

	//Defined at compile time
	uint32_t epochDuration = slotDuration * ((uint16_t) maxSlotId + 1);

	bool isStarted = FALSE;
	bool isTransmitSlotActive = FALSE;
	bool isPrepareSlotActive = FALSE;
	uint32_t epoch_reference_time;
	uint8_t transmitSlot = 0;
	uint8_t prepareSlot = 0;

	command error_t SlotScheduler.start(uint32_t system_time, uint8_t firstSlot) {
		if(isStarted == TRUE) {
			#ifdef DEBUG_1
			printf("[DEBUG] Slot Scheduler already started!\n");
			printf("[DEBUG] Slot: %u\n", transmitSlot);
			printf("[DEBUG] Attempt Slot: %u\n", firstSlot);
			printfflush();
			#endif
			return EALREADY;
		} else {
			#ifdef DEBUG_1
			printf("[DEBUG] Slot Scheduler start first time!\n");
			printf("[DEBUG] Slot: %u\n", transmitSlot);
			printf("[DEBUG] Attempt Slot: %u\n", firstSlot);
			printfflush();
			#endif
		}
		if(firstSlot > maxSlotId)
			return FAIL;

		isStarted = TRUE;
		transmitSlot = firstSlot;
		epoch_reference_time = system_time;

		call TransmitSlotTimer.startOneShotAt(system_time, slotDuration * firstSlot);
		call EpochTimer.startPeriodicAt(system_time, epochDuration);

		return SUCCESS;
	}

	command bool SlotScheduler.isRunning() {
		return isStarted;
	}

	command error_t SlotScheduler.stop() {
		bool wasStarted = isStarted;
		call TransmitSlotTimer.stop();
		call EpochTimer.stop();
		isStarted = FALSE;
		return (wasStarted) ? EALREADY : SUCCESS;
	}

	command void SlotScheduler.syncSystemTime(uint32_t reference_time) {
		epoch_reference_time = reference_time;
		call EpochTimer.startPeriodicAt(reference_time, epochDuration);
	}

	command uint32_t SlotScheduler.getSystemTime() {
		return epoch_reference_time;
	}

	command uint8_t SlotScheduler.getScheduledSlot() {
		return transmitSlot;
	}

	event void EpochTimer.fired() {
		epoch_reference_time += epochDuration;
	}

	event void TransmitSlotTimer.fired() {
		uint8_t nextSlot;		
		if(!isTransmitSlotActive) {
			isTransmitSlotActive = TRUE;
			call TransmitSlotTimer.startOneShot(slotDuration);
			signal SlotScheduler.transmittingSlotStarted(transmitSlot);
			return;
		}

		isTransmitSlotActive = FALSE;

		nextSlot = signal SlotScheduler.transmittingSlotEnded(transmitSlot);
	
		//If scheduler is not running don't schedule other slots
		if(!isStarted)
			return;

		//Next slot in the same epoch or current and next slot are one just after the other between current and next epoch
		if (nextSlot > transmitSlot || (transmitSlot == maxSlotId && nextSlot == 0)) {
			transmitSlot = nextSlot;
			call TransmitSlotTimer.startOneShotAt(epoch_reference_time, slotDuration * transmitSlot);
		} else {
			//Next slot is in next epoch
			transmitSlot = nextSlot;
			call TransmitSlotTimer.startOneShotAt(epoch_reference_time + epochDuration, slotDuration * transmitSlot);
		}
	}
}
