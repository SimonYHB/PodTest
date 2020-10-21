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

#include <stdlib.h>
#include <string.h>
#include "json_util.h"

Json_map_abd *create_json_map_abd(void) {
    Json_map_abd *item = malloc(sizeof(Json_map_abd));
    if (NULL != item)
        memset(item, 0, sizeof(Json_map_abd));
    return item;
}

int is_empty_json_map_cabd(Json_map_abd *item) {
    Json_map_abd temp;
    memset(&temp, 0, sizeof(Json_map_abd));
    if (memcmp(item, &temp, sizeof(Json_map_abd)) == 0) {
        return 1;
    }
    return 0;
}

void add_item_string_cabd(Json_map_abd *map, const char *key, const char *value) {
    if (NULL != map && NULL != value && NULL != key && strnlen(key, 128) > 0) {
        Json_map_abd *item = map;
        Json_map_abd *temp = item;
        if (!is_empty_json_map_cabd(item)) {
            while (NULL != item->nextItem) {
                item = item->nextItem;
            }
            temp = create_json_map_abd();
            item->nextItem = temp;
        }
        if (NULL != temp) {
            temp->type = CABD_JSON_MAP_STRING;
            temp->key = (char *) key;
            temp->valueStr = value;
        }
    }
}

void add_item_number_cabd(Json_map_abd *map, const char *key, double number) {
    if (NULL != map && NULL != key && strnlen(key, 128) > 0) {
        Json_map_abd *item = map;
        Json_map_abd *temp = item;
        if (!is_empty_json_map_cabd(item)) {
            while (NULL != item->nextItem) {
                item = item->nextItem;
            }
            temp = create_json_map_abd();
            item->nextItem = temp;
        }
        if (NULL != temp) {
            temp->type = CABD_JSON_MAP_NUMBER;
            temp->key = (char *) key;
            temp->valueNumber = number;
        }
    }
}

void add_item_bool_cabd(Json_map_abd *map, const char *key, int boolValue) {
    if (NULL != map && NULL != key && strnlen(key, 128) > 0) {
        Json_map_abd *item = map;
        Json_map_abd *temp = item;
        if (!is_empty_json_map_cabd(item)) {
            while (NULL != item->nextItem) {
                item = item->nextItem;
            }
            temp = create_json_map_abd();
            item->nextItem = temp;
        }
        if (NULL != temp) {
            temp->type = CABD_JSON_MAP_BOOL;
            temp->key = (char *) key;
            temp->valueBool = boolValue;
        }
    }
}

void delete_json_map_cabd(Json_map_abd *map) {
    if (NULL != map) {
        Json_map_abd *item = map;
        Json_map_abd *temp = NULL;
        do {
            temp = item->nextItem;
            free(item);
            item = temp;
        } while (NULL != item);
    }
}

void inflate_json_by_map_cabd(cJSON *root, Json_map_abd *map) {
    if (NULL != root && NULL != map) {
        Json_map_abd *item = map;
        do {
            switch (item->type) {
                case CABD_JSON_MAP_STRING:
                    if (NULL != item->valueStr) {
                        cJSON_AddStringToObject(root, item->key, item->valueStr);
                    }
                    break;
                case CABD_JSON_MAP_NUMBER:
                    cJSON_AddNumberToObject(root, item->key, item->valueNumber);
                    break;
                case CABD_JSON_MAP_BOOL:
                    cJSON_AddBoolToObject(root, item->key, item->valueBool);
                    break;
                default:
                    break;
            }
            item = item->nextItem;
        } while (NULL != item);
    }
}
