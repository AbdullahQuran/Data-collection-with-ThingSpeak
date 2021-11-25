#ifndef SINK_H
#define SINK_H

typedef nx_struct sinks_msg {
  nx_uint16_t datat;
  nx_uint16_t datah;
} sinks_msg_t;

typedef nx_struct sink_msg {
  nx_uint8_t msg_type;
  nx_uint16_t data;
} sink_msg_t;

enum {
  SERIAL_MSG = 0x89,
  RADIO_MSG = 6,
};

#endif
