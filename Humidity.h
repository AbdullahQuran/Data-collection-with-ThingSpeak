#ifndef Humidity_H
#define Humidity_H

typedef nx_struct hum_msg {
  nx_uint8_t msg_type;
  nx_uint16_t data;
} hum_msg_t;

enum {
  RADIO_MSG = 6,
};

#endif
