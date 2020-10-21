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

#ifndef CABD_JSON_UTIL_H
#define CABD_JSON_UTIL_H

#include "cJSON.h"

#define CABD_JSON_MAP_STRING 1
#define CABD_JSON_MAP_NUMBER 2
#define CABD_JSON_MAP_BOOL 3

typedef struct json_map {
    char *key;
    const char *valueStr;
    double valueNumber;
    int valueBool;
    int type;
    struct json_map *nextItem;
} Json_map_abd;

Json_map_abd *create_json_map_abd(void);

int is_empty_json_map_cabd(Json_map_abd *item);

void add_item_string_cabd(Json_map_abd *map, const char *key, const char *value);

void add_item_number_cabd(Json_map_abd *map, const char *key, double number);

void add_item_bool_cabd(Json_map_abd *map, const char *key, int boolValue);

void delete_json_map_cabd(Json_map_abd *item);

void inflate_json_by_map_cabd(cJSON *root, Json_map_abd *map);

#endif //CABD_JSON_UTIL_H
