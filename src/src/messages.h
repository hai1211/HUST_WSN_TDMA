#ifndef MESSAGES_H
#define MESSAGES_H

enum {
	AM_SYNCMSG = 130,
	AM_JOINREQMSG = 131,
	AM_JOINANSMSG = 132,
	AM_DATAMSG = 133,
	MAX_SENSORS = 5
};
typedef nx_struct THL_msg{
	nx_uint16_t vref;
	nx_uint16_t temperature;
	nx_uint16_t humidity;
	nx_uint16_t photo;
	nx_uint16_t radiation;
	
} THL_msg_t;

typedef nx_struct {
} SyncMsg;

typedef nx_struct {
} JoinReqMsg;

typedef nx_struct {
	nx_uint8_t slot;
} JoinAnsMsg;

#endif
