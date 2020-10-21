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

#ifndef CABD_ABD_CONFIG_H
#define CABD_ABD_CONFIG_H

#include <zlib.h>
#include <stdio.h>

#define ABD_VERSION_KEY "abd_version"
#define ABD_PATH_KEY "file"

#define  ABD_WRITE_PROTOCOL_HEADER '\1'
#define  ABD_WRITE_PROTOCOL_TAIL '\0'

#define ABD_CACHE_DIR "abd_cache"
#define ABD_CACHE_FILE "abd.mmap2"

#define ABD_MMAP_HEADER_PROTOCOL '\15' //MMAP的头文件标识符
#define ABD_MMAP_TAIL_PROTOCOL '\16' //MMAP尾文件标识符
#define ABD_MMAP_TOTALLEN  3 //MMAP文件长度

#define ABD_MAX_GZIP_UTIL 5 * 1024 //压缩单元的大小

#define ABD_WRITEPROTOCOL_HEAER_LENGTH 5 //Abd写入协议的头和写入数据的总长度

#define ABD_WRITEPROTOCOL_DEVIDE_VALUE 3 //多少分之一写入

#define ABD_DIVIDE_SYMBOL "/"

#define ABD_LOGFILE_MAXLENGTH 10 * 1024 * 1024

#define ABD_WRITE_SECTION 20 * 1024 //多大长度做分片

#define ABD_RETURN_SYMBOL "\n"

#define ABD_FILE_NONE 0
#define ABD_FILE_OPEN 1
#define ABD_FILE_CLOSE 2

#define CABD_EMPTY_FILE 0

#define CABD_VERSION_NUMBER 3 //Abd的版本号(2)版本

typedef struct abd_model_struct {
    int total_len; //数据长度
    char *file_path; //文件路径

    int is_malloc_zlib;
    z_stream *strm;
    int zlib_type; //压缩类型
    char remain_data[16]; //剩余空间
    int remain_data_len; //剩余空间长度

    int is_ready_gzip; //是否可以gzip

    int file_stream_type; //文件流类型
    FILE *file; //文件流

    long file_len; //文件大小

    unsigned char *buffer_point; //缓存的指针 (不变)
    unsigned char *last_point; //最后写入位置的指针
    unsigned char *total_point; //总数的指针 (可能变) , 给c看,低字节
    unsigned char *content_lent_point;//协议内容长度指针 , 给java看,高字节
    int content_len; //内容的大小

    unsigned char aes_iv[16]; //aes_iv
    int is_ok;

} cAbd_model;

#endif //CABD_ABD_CONFIG_H
