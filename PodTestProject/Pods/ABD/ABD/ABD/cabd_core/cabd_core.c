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

#include "cabd_core.h"

#include "mmap_util.h"
#include "construct_data.h"
#include "cJSON.h"
#include "json_util.h"
#include "zlib_util.h"
#include "aes_util.h"
#include "directory_util.h"
#include "base_util.h"
#include "console_util.h"
#include "cabd_status.h"

static int is_init_ok = 0;
static int is_open_ok = 0;

static unsigned char *_abd_buffer = NULL; //缓存Buffer (不释放)

static char *_dir_path = NULL; //目录路径 (不释放)

static char *_mmap_file_path = NULL; //mmap文件路径 (不释放)

static int buffer_length = 0; //缓存区域的大小

static unsigned char *_cache_buffer_buffer = NULL; //临时缓存文件 (不释放)

static int buffer_type; //缓存区块的类型

static long max_file_len = ABD_LOGFILE_MAXLENGTH;

static cAbd_model *abd_model = NULL; //(不释放)

int init_file_cabd(cAbd_model *abd_model) {
    int is_ok = 0;
    if (ABD_FILE_OPEN == abd_model->file_stream_type) {
        return 1;
    } else {
        FILE *file_temp = fopen(abd_model->file_path, "ab+");
        if (NULL != file_temp) {  //初始化文件流开启
            abd_model->file = file_temp;
            fseek(file_temp, 0, SEEK_END);
            long longBytes = ftell(file_temp);
            abd_model->file_len = longBytes;
            abd_model->file_stream_type = ABD_FILE_OPEN;
            is_ok = 1;
        } else {
            abd_model->file_stream_type = ABD_FILE_NONE;
        }
    }
    return is_ok;
}

void init_encrypt_key_cabd(cAbd_model *abd_model) {
    aes_inflate_iv_cabd(abd_model->aes_iv);
}

void write_mmap_data_cabd(char *path, unsigned char *temp) {
    abd_model->total_point = temp;
    abd_model->file_path = path;
    char len_array[] = {'\0', '\0', '\0', '\0'};
    len_array[0] = *temp;
    temp++;
    len_array[1] = *temp;
    temp++;
    len_array[2] = *temp;

    adjust_byteorder_cabd(len_array);//调整字节序,默认为低字节序,在读取的地方处理

    int *total_len = (int *) len_array;

    int t = *total_len;
    printf_cabd("write_mmapdata_cabd > buffer total length %d\n", t);
    if (t > ABD_WRITEPROTOCOL_HEAER_LENGTH && t < ABD_MMAP_LENGTH) {
        abd_model->total_len = t;
        if (NULL != abd_model) {
            if (init_file_cabd(abd_model)) {
                abd_model->is_ok = 1;
                abd_model->zlib_type = ABD_ZLIB_NONE;
                cabd_flush();
                fclose(abd_model->file);
                abd_model->file_stream_type = ABD_FILE_CLOSE;

            }
        }
    } else {
        abd_model->file_stream_type = ABD_FILE_NONE;
    }
    abd_model->total_len = 0;
    abd_model->file_path = NULL;
}

void read_mmap_data_cabd(const char *path_dirs) {
    if (buffer_type == ABD_MMAP_MMAP) {
        unsigned char *temp = _abd_buffer;
        unsigned char *temp2 = NULL;
        char i = *temp;
        if (ABD_MMAP_HEADER_PROTOCOL == i) {
            temp++;
            char len_array[] = {'\0', '\0', '\0', '\0'};
            len_array[0] = *temp;
            temp++;
            len_array[1] = *temp;
            adjust_byteorder_cabd(len_array);
            int *len_p = (int *) len_array;
            temp++;
            temp2 = temp;
            int len = *len_p;

            printf_cabd("read_mmapdata_cabd > path's json length : %d\n", len);

            if (len > 0 && len < 1024) {
                temp += len;
                i = *temp;
                if (ABD_MMAP_TAIL_PROTOCOL == i) {
                    char dir_json[len];
                    memset(dir_json, 0, len);
                    memcpy(dir_json, temp2, len);
                    printf_cabd("dir_json %s\n", dir_json);
                    cJSON *cjson = cJSON_Parse(dir_json);

                    if (NULL != cjson) {
                        cJSON *dir_str = cJSON_GetObjectItem(cjson,
                                                             ABD_VERSION_KEY);  //删除json根元素释放
                        cJSON *path_str = cJSON_GetObjectItem(cjson, ABD_PATH_KEY);
                        if ((NULL != dir_str && cJSON_Number == dir_str->type &&
                             CABD_VERSION_NUMBER == dir_str->valuedouble) &&
                            (NULL != path_str && path_str->type == cJSON_String &&
                             !is_string_empty_cabd(path_str->valuestring))) {

                            printf_cabd(
                                    "read_mmapdata_cabd > dir , path and version : %s || %s || %lf\n",
                                    path_dirs, path_str->valuestring, dir_str->valuedouble);

                            size_t dir_len = strlen(path_dirs);
                            size_t path_len = strlen(path_str->valuestring);
                            size_t length = dir_len + path_len + 1;
                            char file_path[length];
                            memset(file_path, 0, length);
                            memcpy(file_path, path_dirs, dir_len);
                            strcat(file_path, path_str->valuestring);
                            temp++;
                            write_mmap_data_cabd(file_path, temp);
                        }
                        cJSON_Delete(cjson);
                    }
                }
            }
        }
    }
}

/**
 * Abd初始化
 * @param cachedirs 缓存路径
 * @param pathdirs  目录路径
 * @param max_file  日志文件最大值
 */
int cabd_init(const char *cache_dirs, const char *path_dirs, int max_file, const char *encrypt_key16,
            const char *encrypt_iv16) {
    int back = CABD_INIT_FAIL_HEADER;
    if (is_init_ok ||
        NULL == cache_dirs || strnlen(cache_dirs, 11) == 0 ||
        NULL == path_dirs || strnlen(path_dirs, 11) == 0 ||
        NULL == encrypt_key16 || NULL == encrypt_iv16) {
        back = CABD_INIT_FAIL_HEADER;
        return back;
    }

    if (max_file > 0) {
        max_file_len = max_file;
    } else {
        max_file_len = ABD_LOGFILE_MAXLENGTH;
    }

    if (NULL != _dir_path) { // 初始化时 , _dir_path和_mmap_file_path是非空值,先释放,再NULL
        free(_dir_path);
        _dir_path = NULL;
    }
    if (NULL != _mmap_file_path) {
        free(_mmap_file_path);
        _mmap_file_path = NULL;
    }

    aes_init_key_iv(encrypt_key16, encrypt_iv16);

    size_t path1 = strlen(cache_dirs);
    size_t path2 = strlen(ABD_CACHE_DIR);
    size_t path3 = strlen(ABD_CACHE_FILE);
    size_t path4 = strlen(ABD_DIVIDE_SYMBOL);

    int isAddDivede = 0;
    char d = *(cache_dirs + path1 - 1);
    if (d != '/') {
        isAddDivede = 1;
    }

    size_t total = path1 + (isAddDivede ? path4 : 0) + path2 + path4 + path3 + 1;
    char *cache_path = malloc(total);
    if (NULL != cache_path) {
        _mmap_file_path = cache_path; //保持mmap文件路径,如果初始化失败,注意释放_mmap_file_path
    } else {
        is_init_ok = 0;
        printf_cabd("cabd_init > malloc memory fail for mmap_file_path \n");
        back = CABD_INIT_FAIL_NOMALLOC;
        return back;
    }

    memset(cache_path, 0, total);
    strcpy(cache_path, cache_dirs);
    if (isAddDivede)
        strcat(cache_path, ABD_DIVIDE_SYMBOL);

    strcat(cache_path, ABD_CACHE_DIR);
    strcat(cache_path, ABD_DIVIDE_SYMBOL);


    //创建目录
    makedir_cabd(cache_path); //创建保存mmap文件的目录



    strcat(cache_path, ABD_CACHE_FILE);

    size_t dirLength = strlen(path_dirs);

    isAddDivede = 0;
    d = *(path_dirs + dirLength - 1);
    if (d != '/') {
        isAddDivede = 1;
    }
    total = dirLength + (isAddDivede ? path4 : 0) + 1;

    char *dirs = (char *) malloc(total); //缓存文件目录

    if (NULL != dirs) {
        _dir_path = dirs; //日志写入的文件目录
    } else {
        is_init_ok = 0;
        printf_cabd("cabd_init > malloc memory fail for _dir_path \n");
        back = CABD_INIT_FAIL_NOMALLOC;
        return back;
    }
    memset(dirs, 0, total);
    memcpy(dirs, path_dirs, dirLength);
    if (isAddDivede)
        strcat(dirs, ABD_DIVIDE_SYMBOL);
    makedir_cabd(_dir_path); //创建缓存目录,如果初始化失败,注意释放_dir_path

    int flag = ABD_MMAP_FAIL;
    if (NULL == _abd_buffer) {
        if (NULL == _cache_buffer_buffer) {
            flag = open_mmap_file_cabd(cache_path, &_abd_buffer, &_cache_buffer_buffer);
        } else {
            flag = ABD_MMAP_MEMORY;
        }
    } else {
        flag = ABD_MMAP_MMAP;
    }

    if (flag == ABD_MMAP_MMAP) {
        buffer_length = ABD_MMAP_LENGTH;
        buffer_type = ABD_MMAP_MMAP;
        is_init_ok = 1;
        back = CABD_INIT_SUCCESS_MMAP;
    } else if (flag == ABD_MMAP_MEMORY) {
        buffer_length = ABD_MEMORY_LENGTH;
        buffer_type = ABD_MMAP_MEMORY;
        is_init_ok = 1;
        back = CABD_INIT_SUCCESS_MEMORY;
    } else if (flag == ABD_MMAP_FAIL) {
        is_init_ok = 0;
        back = CABD_INIT_FAIL_NOCACHE;
    }

    if (is_init_ok) {
        if (NULL == abd_model) {
            abd_model = malloc(sizeof(cAbd_model));
            if (NULL != abd_model) { //堆非空判断 , 如果为null , 就失败
                memset(abd_model, 0, sizeof(cAbd_model));
            } else {
                is_init_ok = 0;
                printf_cabd("cabd_init > malloc memory fail for abd_model\n");
                back = CABD_INIT_FAIL_NOMALLOC;
                return back;
            }
        }
        if (flag == ABD_MMAP_MMAP) //MMAP的缓存模式,从缓存的MMAP中读取数据
            read_mmap_data_cabd(_dir_path);
        printf_cabd("cabd_init > abd init success\n");
    } else {
        printf_cabd("cabd_open > abd init fail\n");
        // 初始化失败，删除所有路径
        if (NULL == _dir_path) {
            free(_dir_path);
            _dir_path = NULL;
        }
        if (NULL == _mmap_file_path) {
            free(_mmap_file_path);
            _mmap_file_path = NULL;
        }
    }
    return back;
}

/*
 * 对mmap添加header和确定总长度位置
 */
void add_mmap_header_cabd(char *content, cAbd_model *model) {
    size_t content_len = strlen(content) + 1;
    size_t total_len = content_len;
    char *temp = (char *) model->buffer_point;
    *temp = ABD_MMAP_HEADER_PROTOCOL;
    temp++;
    *temp = total_len;
    temp++;
    *temp = total_len >> 8;
    printf_cabd("\n add_mmap_header_cabd len %d\n", total_len);
    temp++;
    memcpy(temp, content, content_len);
    temp += content_len;
    *temp = ABD_MMAP_TAIL_PROTOCOL;
    temp++;
    model->total_point = (unsigned char *) temp; // 总数据的total_length的指针位置
    model->total_len = 0;
}

/**
 * 确立最后的长度指针位置和最后的写入指针位置
 */
void restore_last_position_cabd(cAbd_model *model) {
    unsigned char *temp = model->last_point;
    *temp = ABD_WRITE_PROTOCOL_HEADER;
    model->total_len++;
    temp++;
    model->content_lent_point = temp; // 内容的指针地址
    *temp = model->content_len >> 24;
    model->total_len++;
    temp++;
    *temp = model->content_len >> 16;
    model->total_len++;
    temp++;
    *temp = model->content_len >> 8;
    model->total_len++;
    temp++;
    *temp = model->content_len;
    model->total_len++;
    temp++;
    model->last_point = temp;

    printf_cabd("restore_last_position_cabd > content_len : %d\n", model->content_len);
}

int cabd_open(const char *pathname) {
    int back = CABD_OPEN_FAIL_NOINIT;
    if (!is_init_ok) {
        back = CABD_OPEN_FAIL_NOINIT;
        return back;
    }

    is_open_ok = 0;
    if (NULL == pathname || 0 == strnlen(pathname, 128) || NULL == _abd_buffer ||
        NULL == _dir_path ||
        0 == strnlen(_dir_path, 128)) {
        back = CABD_OPEN_FAIL_HEADER;
        return back;
    }

    if (NULL != abd_model) { //回写到日志中
        if (abd_model->total_len > ABD_WRITEPROTOCOL_HEAER_LENGTH) {
            cabd_flush();
        }
        if (abd_model->file_stream_type == ABD_FILE_OPEN) {
            fclose(abd_model->file);
            abd_model->file_stream_type = ABD_FILE_CLOSE;
        }
        if (NULL != abd_model->file_path) {
            free(abd_model->file_path);
            abd_model->file_path = NULL;
        }
        abd_model->total_len = 0;
    } else {
        abd_model = malloc(sizeof(cAbd_model));
        if (NULL != abd_model) {
            memset(abd_model, 0, sizeof(cAbd_model));
        } else {
            abd_model = NULL; //初始化Abd_model失败,直接退出
            is_open_ok = 0;
            back = CABD_OPEN_FAIL_MALLOC;
            return back;
        }
    }
    char *temp = NULL;

    size_t file_path_len = strlen(_dir_path) + strlen(pathname) + 1;
    char *temp_file = malloc(file_path_len); // 日志文件路径
    if (NULL != temp_file) {
        memset(temp_file, 0, file_path_len);
        temp = temp_file;
        memcpy(temp, _dir_path, strlen(_dir_path));
        temp += strlen(_dir_path);
        memcpy(temp, pathname, strlen(pathname)); //创建文件路径
        abd_model->file_path = temp_file;

        if (!init_file_cabd(abd_model)) {  //初始化文件IO和文件大小
            is_open_ok = 0;
            back = CABD_OPEN_FAIL_IO;
            return back;
        }

        if (init_zlib_cabd(abd_model) != Z_OK) { //初始化zlib压缩
            is_open_ok = 0;
            back = CABD_OPEN_FAIL_ZLIB;
            return back;
        }

        abd_model->buffer_point = _abd_buffer;

        if (buffer_type == ABD_MMAP_MMAP) {  //如果是MMAP,缓存文件目录和文件名称
            cJSON *root = NULL;
            Json_map_abd *map = NULL;
            root = cJSON_CreateObject();
            map = create_json_map_abd();
            char *back_data = NULL;
            if (NULL != root) {
                if (NULL != map) {
                    add_item_number_cabd(map, ABD_VERSION_KEY, CABD_VERSION_NUMBER);
                    add_item_string_cabd(map, ABD_PATH_KEY, pathname);
                    inflate_json_by_map_cabd(root, map);
                    back_data = cJSON_PrintUnformatted(root);
                }
                cJSON_Delete(root);
                if (NULL != back_data) {
                    add_mmap_header_cabd(back_data, abd_model);
                    free(back_data);
                } else {
                    abd_model->total_point = _abd_buffer;
                    abd_model->total_len = 0;
                }
            } else {
                abd_model->total_point = _abd_buffer;
                abd_model->total_len = 0;
            }

            abd_model->last_point = abd_model->total_point + ABD_MMAP_TOTALLEN;

            if (NULL != map) {
                delete_json_map_cabd(map);
            }
        } else {
            abd_model->total_point = _abd_buffer;
            abd_model->total_len = 0;
            abd_model->last_point = abd_model->total_point + ABD_MMAP_TOTALLEN;
        }
        restore_last_position_cabd(abd_model);
        init_encrypt_key_cabd(abd_model);
        abd_model->is_ok = 1;
        is_open_ok = 1;
    } else {
        is_open_ok = 0;
        back = CABD_OPEN_FAIL_MALLOC;
        printf_cabd("cabd_open > malloc memory fail\n");
    }

    if (is_open_ok) {
        back = CABD_OPEN_SUCCESS;
        printf_cabd("cabd_open > abd open success\n");
    } else {
        printf_cabd("cabd_open > abd open fail\n");
    }
    return back;
}


//更新总数据和最后的count的数据到内存中
void update_length_cabd(cAbd_model *model) {
    unsigned char *temp = NULL;
    if (NULL != model->total_point) {
        temp = model->total_point;
        *temp = model->total_len;
        temp++;
        *temp = model->total_len >> 8;
        temp++;
        *temp = model->total_len >> 16;
    }

    if (NULL != model->content_lent_point) {
        temp = model->content_lent_point;
        // 为了兼容java,采用高字节序
        *temp = model->content_len >> 24;
        temp++;
        *temp = model->content_len >> 16;
        temp++;
        *temp = model->content_len >> 8;
        temp++;
        *temp = model->content_len;
    }
}

//对cabd_model数据做还原
void clear_cabd(cAbd_model *abd_model) {
    abd_model->total_len = 0;

    if (abd_model->zlib_type == ABD_ZLIB_END) { //因为只有ZLIB_END才会释放掉内存,才能再次初始化
        memset(abd_model->strm, 0, sizeof(z_stream));
        abd_model->zlib_type = ABD_ZLIB_NONE;
        init_zlib_cabd(abd_model);
    }
    abd_model->remain_data_len = 0;
    abd_model->content_len = 0;
    abd_model->last_point = abd_model->total_point + ABD_MMAP_TOTALLEN;
    restore_last_position_cabd(abd_model);
    init_encrypt_key_cabd(abd_model);
    abd_model->total_len = 0;
    update_length_cabd(abd_model);
    abd_model->total_len = ABD_WRITEPROTOCOL_HEAER_LENGTH;
}

//对空的文件插入一行头文件做标示
void insert_header_file_cabd(cAbd_model *abdModel) {
    char *log = "cabd header";
    int flag = 1;
    long long local_time = get_system_current_cabd();
    char *thread_name = "cabd";
    long long thread_id = 1;
    int ismain = 1;
    Construct_Data_cAbd *data = construct_json_data_cabd(log, flag, local_time, thread_id, ismain, '\0', '\0');
    if (NULL == data) {
        return;
    }
    cAbd_model temp_model; //临时的cabd_model
    int status_header = 1;
    memset(&temp_model, 0, sizeof(cAbd_model));
    if (Z_OK != init_zlib_cabd(&temp_model)) {
        status_header = 0;
    }

    if (status_header) {
        init_encrypt_key_cabd(&temp_model);
        int length = data->data_len * 10;
        unsigned char temp_memory[length];
        memset(temp_memory, 0, length);
        temp_model.total_len = 0;
        temp_model.last_point = temp_memory;
        restore_last_position_cabd(&temp_model);
        cabd_zlib_compress(&temp_model, data->data, data->data_len);
        cabd_zlib_end_compress(&temp_model);
        update_length_cabd(&temp_model);

        fwrite(temp_memory, sizeof(char), temp_model.total_len, abdModel->file);//写入到文件中
        fflush(abd_model->file);
        abdModel->file_len += temp_model.total_len; //修改文件大小
    }

    if (temp_model.is_malloc_zlib) {
        free(temp_model.strm);
        temp_model.is_malloc_zlib = 0;
    }
    construct_data_delete_cabd(data);
}

//文件写入磁盘、更新文件大小
void write_dest_cabd(void *point, size_t size, size_t length, cAbd_model *abdModel) {
    if (!is_file_exist_cabd(abdModel->file_path)) { //如果文件被删除,再创建一个文件
        if (abd_model->file_stream_type == ABD_FILE_OPEN) {
            fclose(abd_model->file);
            abd_model->file_stream_type = ABD_FILE_CLOSE;
        }
        if (NULL != _dir_path) {
            if (!is_file_exist_cabd(_dir_path)) {
                makedir_cabd(_dir_path);
            }
            init_file_cabd(abd_model);
            printf_cabd("cabd_write > create log file , restore open file stream \n");
        }
    }
    //if (CABD_EMPTY_FILE == abdModel->file_len) { //如果是空文件插入一行CAbd的头文件
    //    insert_header_file_cabd(abdModel);
    //}
    fwrite(point, sizeof(char), abd_model->total_len, abd_model->file);//写入到文件中
    fflush(abd_model->file);
    abdModel->file_len += abdModel->total_len; //修改文件大小
}

void write_flush_cabd() {
    if (abd_model->zlib_type == ABD_ZLIB_ING) {
        cabd_zlib_end_compress(abd_model);
        update_length_cabd(abd_model);
    }
    if (abd_model->total_len > ABD_WRITEPROTOCOL_HEAER_LENGTH) {
        unsigned char *point = abd_model->total_point;
        point += ABD_MMAP_TOTALLEN;
        write_dest_cabd(point, sizeof(char), abd_model->total_len, abd_model);
        printf_cabd("write_flush_cabd > abd total len : %d \n", abd_model->total_len);
        clear_cabd(abd_model);
    }
}

void cabd_write2(char *data, int length) {
    if (NULL != abd_model && abd_model->is_ok) {
        cabd_zlib_compress(abd_model, data, length);
        update_length_cabd(abd_model); //有数据操作,要更新数据长度到缓存中
        int is_gzip_end = 0;

        if (!abd_model->file_len ||
            abd_model->content_len >= ABD_MAX_GZIP_UTIL) { //是否一个压缩单元结束
            cabd_zlib_end_compress(abd_model);
            is_gzip_end = 1;
            update_length_cabd(abd_model);
        }

        int isWrite = 0;
        if (!abd_model->file_len && is_gzip_end) { //如果是个空文件、第一条日志写入
            isWrite = 1;
            printf_cabd("cabd_write2 > write type empty file \n");
        } else if (buffer_type == ABD_MMAP_MEMORY && is_gzip_end) { //直接写入文件
            isWrite = 1;
            printf_cabd("cabd_write2 > write type memory \n");
        } else if (buffer_type == ABD_MMAP_MMAP &&
                   abd_model->total_len >=
                   buffer_length / ABD_WRITEPROTOCOL_DEVIDE_VALUE) { //如果是MMAP 且 文件长度已经超过三分之一
            isWrite = 1;
            printf_cabd("cabd_write2 > write type MMAP \n");
        }
        if (isWrite) { //写入
            write_flush_cabd();
        } else if (is_gzip_end) { //如果是mmap类型,不回写IO,初始化下一步
            abd_model->content_len = 0;
            abd_model->remain_data_len = 0;
            init_zlib_cabd(abd_model);
            restore_last_position_cabd(abd_model);
            init_encrypt_key_cabd(abd_model);
        }
    }
}

//如果数据流非常大,切割数据,分片写入
void cabd_write_section(char *data, int length) {
    int size = ABD_WRITE_SECTION;
    int times = length / size;
    int remain_len = length % size;
    char *temp = data;
    int i = 0;
    for (i = 0; i < times; i++) {
        cabd_write2(temp, size);
        temp += size;
    }
    if (remain_len) {
        cabd_write2(temp, remain_len);
    }
}

/**
 @brief 写入数据 按照顺序和类型传值(强调、强调、强调)
 @param type 日志类型 (int)
 @param log 日志内容 (char*)
 @param local_time 日志发生的本地时间，形如1502100065601 (long long)
 @param thread_id 线程id (long long) 为了兼容JAVA
 @param ismain 是否为主线程，0为是主线程，1位非主线程 (int)
 @param extra 附加字段，非必填
 @param tag 标签，非必填
 */
int
cabd_write(int type, char *log, long long local_time, long long thread_id,
             int is_main, char *extra, char *tag) {
    int back = CABD_WRITE_FAIL_HEADER;
    if (!is_init_ok || NULL == abd_model || !is_open_ok) {
        back = CABD_WRITE_FAIL_HEADER;
        return back;
    }

    if (is_file_exist_cabd(abd_model->file_path)) {
        if (abd_model->file_len > max_file_len) {
            printf_cabd("cabd_write > beyond max file , cant write log\n");
            back = CLOAGN_WRITE_FAIL_MAXFILE;
            return back;
        }
    } else {
        if (abd_model->file_stream_type == ABD_FILE_OPEN) {
            fclose(abd_model->file);
            abd_model->file_stream_type = ABD_FILE_CLOSE;
        }
        if (NULL != _dir_path) {
            if (!is_file_exist_cabd(_dir_path)) {
                makedir_cabd(_dir_path);
            }
            init_file_cabd(abd_model);
            printf_cabd("cabd_write > create log file , restore open file stream \n");
        }
    }

    //判断MMAP文件是否存在,如果被删除,用内存缓存
    if (buffer_type == ABD_MMAP_MMAP && !is_file_exist_cabd(_mmap_file_path)) {
        if (NULL != _cache_buffer_buffer) {
            buffer_type = ABD_MMAP_MEMORY;
            buffer_length = ABD_MEMORY_LENGTH;

            printf_cabd("cabd_write > change to memory buffer");

            _abd_buffer = _cache_buffer_buffer;
            abd_model->total_point = _abd_buffer;
            abd_model->total_len = 0;
            abd_model->content_len = 0;
            abd_model->remain_data_len = 0;

            if (abd_model->zlib_type == ABD_ZLIB_INIT) {
                cabd_zlib_delete_stream(abd_model); //关闭已开的流
            }

            abd_model->last_point = abd_model->total_point + ABD_MMAP_TOTALLEN;
            restore_last_position_cabd(abd_model);
            init_zlib_cabd(abd_model);
            init_encrypt_key_cabd(abd_model);
            abd_model->is_ok = 1;
        } else {
            buffer_type = ABD_MMAP_FAIL;
            is_init_ok = 0;
            is_open_ok = 0;
            _abd_buffer = NULL;
        }
    }

    Construct_Data_cAbd *data = construct_json_data_cabd(log, type, local_time, thread_id, is_main, extra, tag);
    if (NULL != data) {
        cabd_write_section(data->data, data->data_len);
        construct_data_delete_cabd(data);
        back = CABD_WRITE_SUCCESS;
    } else {
        back = CABD_WRITE_FAIL_MALLOC;
    }
    return back;
}

int cabd_flush(void) {
    int back = CABD_FLUSH_FAIL_INIT;
    if (!is_init_ok || NULL == abd_model) {
        return back;
    }
    write_flush_cabd();
    back = CABD_FLUSH_SUCCESS;
    printf_cabd(" cabd_flush > write flush\n");
    return back;
}

void cabd_debug(int debug) {
    set_debug_cabd(debug);
}
