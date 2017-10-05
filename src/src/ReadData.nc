#include "messages.h"
interface ReadData{
	command error_t read();
	event void readDone(error_t error, THL_msg_t msg);
}