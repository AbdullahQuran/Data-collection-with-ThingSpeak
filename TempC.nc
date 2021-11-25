#include "Timer.h"
#include "Temp.h"

module TempC {
  uses {
    
    interface SplitControl as RadioControl;
    interface Boot;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Packet;
    interface Read<uint16_t>;
  }
}
implementation {

  message_t packet;

  bool locked = FALSE;
  
  event void Boot.booted() {
    dbg("boot","Application booted.\n");
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("radio","Radio on \n");
      call MilliTimer.startPeriodic(1000);
    }
  }

  event void RadioControl.stopDone(error_t err) {}

  event void MilliTimer.fired() {
    dbg("role","start sensing temp \n");
    call Read.read();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    dbg("role","value is \n");

    if (locked) {
      dbg("role","Can't read value, Channel is blocked");
      return;
    }

    else {
    	temp_msg_t* rsm;
    	rsm = (temp_msg_t*)call Packet.getPayload(&packet, sizeof(temp_msg_t));

    	dbg("radio_packet","[Temp Sensor]: Packeting the data");

      if (rsm == NULL) {
        return;
      }

      rsm->data = data;
      rsm->msg_type = 1;
      
      if (call Packet.maxPayloadLength() < sizeof(temp_msg_t)) {
        dbg("radio_packet","Data is too large");
        return;
      }

      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(temp_msg_t)) == SUCCESS) {
        locked = TRUE;
        dbg("radio","Sending value to sink\n");
      }
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t err) {
    dbg("radio","Packet sent ");
    if (&packet == bufPtr) {
      locked = FALSE;
      dbg("radio","[Temp Sensor]: Channel is open again");
    }
  }
}
