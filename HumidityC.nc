#include "Timer.h"
#include "Humidity.h"

module HumidityC {
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
      dbg("radio","Radio on!\n");
      call MilliTimer.startPeriodic(1000);
    }
  }

  event void RadioControl.stopDone(error_t err) {}

  event void MilliTimer.fired() {
    dbg("role","start sensing humidity value...\n");
    call Read.read();
  }

  event void Read.readDone(error_t result, uint16_t data) {
    dbg("role","value is \n");

    if (locked) {
      dbg("role","Error in reading the value, Channel is blocked.");
      return;
    }

    else {
    	hum_msg_t* rsm;
    	rsm = (hum_msg_t*)call Packet.getPayload(&packet, sizeof(hum_msg_t));

    	dbg("radio_packet","Packetizing");

      if (rsm == NULL) {
        return;
      }

      rsm->data = data;
      rsm->msg_type = 2;
      
      if (call Packet.maxPayloadLength() < sizeof(hum_msg_t)) {
        dbg("radio_packet","[Hum Sensor]: The data is larger than max length");
        return;
      }

      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(hum_msg_t)) == SUCCESS) {
        locked = TRUE;
        dbg("radio","Sending value to sink. \n");
      }
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t err) {
    dbg("radio","Packet sent.");
    if (&packet == bufPtr) {
      locked = FALSE;
      dbg("radio","[Hum Sensor]: Channel is open again");
    }
  } 
}
