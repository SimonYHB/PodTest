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

#ifndef ABD_MMAP_MMAP
#define ABD_MMAP_MMAP 1
#endif

#ifndef ABD_MMAP_MEMORY
#define ABD_MMAP_MEMORY 0
#endif

#ifndef ABD_MMAP_FAIL
#define ABD_MMAP_FAIL -1
#endif

#ifndef ABD_MMAP_LENGTH
#define ABD_MMAP_LENGTH 150 * 1024 //150k
#endif

#ifndef ABD_MEMORY_LENGTH
#define ABD_MEMORY_LENGTH 150 * 1024 //150k
#endif

#ifndef CABD_MMAP_UTIL_H
#define CABD_MMAP_UTIL_H

#include <stdio.h>
#include <unistd.h>
#include<sys/mman.h>
#include <fcntl.h>
#include <string.h>

int open_mmap_file_cabd(char *_filepath, unsigned char **buffer, unsigned char **cache);

#endif //CABD_MMAP_UTIL_H
