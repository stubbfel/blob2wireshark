#include <stdlib.h>
#include<stdio.h>
#include "b2ws_example_proto_t.h"

int main(void) {

    uint8_t ip_count = 8;
    uint16_t second_layer_size =  sizeof(b2ws_second_layer_s) + ip_count * sizeof(uint32_t);
    size_t blob_size =sizeof (b2ws_first_layer_s) + second_layer_size;

    ptr_b2ws_first_layer_s first_layer = (ptr_b2ws_first_layer_s) malloc(blob_size);
    first_layer->id = 4711;
    first_layer->size = second_layer_size;
    first_layer->other_four_header_options[0] = 16;
    first_layer->other_four_header_options[1] = 24;
    first_layer->other_four_header_options[2] = 32;
    first_layer->other_four_header_options[3] = 36;

    ptr_b2ws_second_layer_s second_layer = (ptr_b2ws_second_layer_s) &first_layer->second_layer[0];
    second_layer->enabled = 1;
    second_layer->bigger_flag = 4;
    second_layer->ip_count = ip_count;
    second_layer->ip_addresses[0] = 1;
    second_layer->ip_addresses[1] = (uint32_t)-1;
    second_layer->ip_addresses[2] = 255;
    second_layer->ip_addresses[3] = 1255;
    second_layer->ip_addresses[4] = 255255;
    second_layer->ip_addresses[5] = 1255255;
    second_layer->ip_addresses[6] = 255255255;
    second_layer->ip_addresses[7] = 1255255255;

    FILE * example_bin_file = fopen("b2ws_example.bin","wb");
    fwrite(first_layer, blob_size ,1,example_bin_file);
    fclose(example_bin_file);
    free(first_layer);
}
