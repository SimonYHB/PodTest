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

#ifndef CABD_DEMO_CABD_STATUS_H
#define CABD_DEMO_CABD_STATUS_H

#define CLGOAN_INIT_STATUS "cabd_init" //初始化函数
#define CABD_INIT_SUCCESS_MMAP -1010 //初始化成功, mmap内存
#define CABD_INIT_SUCCESS_MEMORY -1020 //初始化成功, 堆内存
#define CABD_INIT_FAIL_NOCACHE -1030 //初始化失败 , 没有缓存
#define CABD_INIT_FAIL_NOMALLOC  -1040 //初始化失败 , 没有堆内存
#define CABD_INIT_FAIL_HEADER  -1050 //初始化失败 , 初始化头失败
#define CABD_INIT_INITPUBLICKEY_ERROR  -1061//初始化失败，初始化公钥失败
#define CABD_INIT_INITBLICKENCRYPT_ERROR -1062//初始化失败，公钥加密失败
#define CABD_INIT_INITBASE64_ERROR -1063 //初始化失败，base64失败
#define CABD_INIT_INITMALLOC_ERROR -1064 //初始化失败 malloc分配失败

#define CABD_OPEN_STATUS "cabd_open" //打开文件函数
#define CABD_OPEN_SUCCESS -2010 //打开文件成功
#define CABD_OPEN_FAIL_IO -2020 //打开文件IO失败
#define CABD_OPEN_FAIL_ZLIB -2030 //打开文件zlib失败
#define CABD_OPEN_FAIL_MALLOC -2040 //打开文件malloc失败
#define CABD_OPEN_FAIL_NOINIT -2050 //打开文件没有初始化失败
#define CABD_OPEN_FAIL_HEADER -2060 //打开文件头失败

#define CABD_WRITE_STATUS "cabd_write" //写入函数
#define CABD_WRITE_SUCCESS -4010 //写入日志成功
#define CABD_WRITE_FAIL_PARAM -4020 //写入失败, 可变参数错误
#define CLOAGN_WRITE_FAIL_MAXFILE -4030 //写入失败,超过文件最大值
#define CABD_WRITE_FAIL_MALLOC -4040 //写入失败,malloc失败
#define CABD_WRITE_FAIL_HEADER -4050 //写入头失败

#define CABD_FLUSH_STATUS "cabd_flush" //强制写入函数
#define CABD_FLUSH_SUCCESS -5010 //fush日志成功
#define CABD_FLUSH_FAIL_INIT -5020 //初始化失败,日志flush不成功

#endif //CABD_DEMO_CABD_STATUS_H
