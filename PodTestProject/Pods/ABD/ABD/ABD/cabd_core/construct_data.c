/*
 * Copyright (c) 2018-present, PINGAN
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <string.h>
#include "construct_data.h"
#include "cJSON.h"
#include "stdlib.h"
#include "json_util.h"
#include "console_util.h"

static const char *log_key = "c";
static const char *type_key = "t";
static const char *localtime_key = "l";
//static const char *threadname_key = "n";
static const char *threadid_key = "i";
static const char *ismain_key = "m";
static const char *extra_key = "e";
static const char *tag_key = "g";

Construct_Data_cAbd *
construct_json_data_cabd(char *log, int type, long long local_time, long long thread_id, int is_main, char *extra, char *tag) {
    Construct_Data_cAbd *construct_data = NULL;
    cJSON *root = NULL;
    Json_map_abd *map = NULL;
    root = cJSON_CreateObject();
    map = create_json_map_abd();
    if (NULL != root) {
        if (NULL != map) {
            add_item_string_cabd(map, log_key, log);
            add_item_number_cabd(map, type_key, (double) type);
            add_item_number_cabd(map, localtime_key, (double) local_time);

            //add_item_string_cabd(map, threadname_key, thread_name);
            add_item_number_cabd(map, threadid_key, (double) thread_id);
            add_item_bool_cabd(map, ismain_key, is_main);

            if(NULL != extra){
                add_item_string_cabd(map, extra_key, extra);
            }

            if(NULL != tag){
                add_item_string_cabd(map, tag_key, tag);
            }

            inflate_json_by_map_cabd(root, map);
            char *back_data = cJSON_PrintUnformatted(root);
            construct_data = (Construct_Data_cAbd *) malloc(sizeof(Construct_Data_cAbd));

            if (NULL != construct_data) {
                memset(construct_data, 0, sizeof(Construct_Data_cAbd));
                size_t str_len = strlen(back_data);
                size_t length = str_len + 1;
                unsigned char *temp_data = (unsigned char *) malloc(length);
                if (NULL != temp_data) {
                    unsigned char *temp_point = temp_data;
                    memset(temp_point, 0, length);
                    memcpy(temp_point, back_data, str_len);
                    temp_point += str_len;
                    char return_data[] = {'\n'};
                    memcpy(temp_point, return_data, 1); //添加\n字符
                    construct_data->data = (char *) temp_data; //赋值
                    construct_data->data_len = (int) length;
                } else {
                    free(construct_data); //创建数据
                    construct_data = NULL;
                    printf_cabd(
                            "construct_json_data_cabd > malloc memory fail for temp_data\n");
                }
            }
            free(back_data);
        }
        cJSON_Delete(root);
    }
    if (NULL != map) {
        delete_json_map_cabd(map);
    }
    return construct_data;
}

void construct_data_delete_cabd(Construct_Data_cAbd *item) {
    if (NULL != item) {
        if (NULL != item->data) {
            free(item->data);
        }
        free(item);
    }
}
