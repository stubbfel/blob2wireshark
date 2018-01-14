#ifndef B2WS_EXAMPLE_PROTO_T_H
#define B2WS_EXAMPLE_PROTO_T_H

#include <stdint.h>

#pragma pack (push, 1)

typedef struct b2ws_first_layer_sTag
{
    int32_t id;
    uint16_t size;
    uint8_t other_four_header_options[4];
    uint8_t second_layer[];
} b2ws_first_layer_s,  *ptr_b2ws_first_layer_s;

typedef struct b2ws_second_layer_sTag
{
    uint8_t enabled:1;
    uint8_t other_flag:1;
    uint8_t bigger_flag:6;
    uint8_t ip_count;
    uint32_t ip_addresses[];
} b2ws_second_layer_s,  *ptr_b2ws_second_layer_s;

#pragma pack (pop)

#endif
