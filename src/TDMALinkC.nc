#include "messages.h"
#ifndef SLOT_DURATION
#define SLOT_DURATION	20 	// Millis
#endif
#ifndef MAX_SLAVES
#define MAX_SLAVES		5	// Num of slaves
#endif

#ifndef SLOT_DURATION
#error SLOT_DURATION not set
#endif

#ifndef MAX_SLAVES
#error MAX_SLAVES not set
#endif

configuration TDMALinkC{
	provides interface TDMALinkProtocol;
}
implementation{
	components TDMALinkP as TDMALink;
	TDMALinkProtocol = TDMALink.TDMAProtocol;
	
	components new SlotSchedulerC(SLOT_DURATION, MAX_SLAVES) as SlotScheduler;
	TDMALink.SlotScheduler 	->	SlotScheduler;

	components ActiveMessageC;
	TDMALink.AMPacket		->	ActiveMessageC.AMPacket;
	TDMALink.RadioControl	->	ActiveMessageC.SplitControl;	
	
	components CC2420TimeSyncMessageC as TimeSync;
	TDMALink.TSSend			->	TimeSync.TimeSyncAMSend32khz[AM_SYNCMSG];
	TDMALink.TSPacket		->	TimeSync.TimeSyncPacket32khz;
	TDMALink.TSReceiver		->	TimeSync.Receive[AM_SYNCMSG];
	
	components new AMSenderC(AM_JOINREQMSG) as JoinReqSend;
	TDMALink.JoinReqSend	->	JoinReqSend.AMSend;

	components new AMReceiverC(AM_JOINREQMSG) as JoinReqRecv;
	TDMALink.JoinReqRecv	->	JoinReqRecv.Receive;
	
	components new AMSenderC(AM_JOINANSMSG) as JoinAnsSend;
	TDMALink.JoinAnsSend	->	JoinAnsSend.AMSend;

	components new AMReceiverC(AM_JOINANSMSG) as JoinAnsRecv;
	TDMALink.JoinAnsRecv	->	JoinAnsRecv.Receive;	
}