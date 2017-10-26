interface SlotScheduler {
	command error_t start(uint32_t system_time, uint8_t firstSlot);
	command bool isRunning();
	command error_t stop();
	command void syncSystemTime(uint32_t reference_time);
	command uint32_t getSystemTime();
	command uint8_t getScheduledSlot();
	command void startPreparingSlot(uint8_t slotId);
	event void preparingSlotStarted(uint8_t slotId);	// This fired when it's time the sensor read the data
	event void preparingSlotEnded(uint8_t slotId);	// This fired when it's time the sensor stop reading the data to start transmitting data
	event void transmittingSlotStarted(uint8_t slotId);	// This fired when it's time the sensor should transmit data (Wake up)
	event uint8_t transmittingSlotEnded(uint8_t slotId);// This fired when it's time the sensor stop doing transmitting data, blah blah blah and wait till it's next turn
}
