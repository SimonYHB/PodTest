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

#ifndef CABD_ZLIB_UTIL_H
#define CABD_ZLIB_UTIL_H

#include "abd_config.h"
#include <zlib.h>
#include <stdlib.h>
#include <string.h>

#define ABD_CHUNK 16384

//定义Abd_zlib的状态类型

#define ABD_ZLIB_NONE 0
#define ABD_ZLIB_INIT 1
#define ABD_ZLIB_ING  2
#define ABD_ZLIB_END  3
#define ABD_ZLIB_FAIL 4

int init_zlib_cabd(cAbd_model *model); //初始化Abd

void cabd_zlib_compress(cAbd_model *model, char *data, int data_len); //压缩文件

void cabd_zlib_end_compress(cAbd_model *model); //压缩结束

void cabd_zlib_delete_stream(cAbd_model *model); //删除初始化的z_stream

#endif //CABD_ZLIB_UTIL_H
