/*
 * Copyright (c) 2005 Topspin Communications.  All rights reserved.
 *
 * This software is available to you under a choice of one of two
 * licenses.  You may choose to be licensed under the terms of the GNU
 * General Public License (GPL) Version 2, available from the file
 * COPYING in the main directory of this source tree, or the
 * OpenIB.org BSD license below:
 *
 *     Redistribution and use in source and binary forms, with or
 *     without modification, are permitted provided that the following
 *     conditions are met:
 *
 *      - Redistributions of source code must retain the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer.
 *
 *      - Redistributions in binary form must reproduce the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer in the documentation and/or other materials
 *        provided with the distribution.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
#define _GNU_SOURCE
#include <config.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <netdb.h>
#include <malloc.h>
#include <getopt.h>
#include <arpa/inet.h>
#include <time.h>
#include <inttypes.h>

#include "pingpong.h"
#include "cpu_profile.h"

#include <ccan/minmax.h>

enum {
	PINGPONG_RECV_WRID = 1,
	PINGPONG_SEND_WRID = 2,
};

static int page_size;
static int validate_buf;
static int use_dm;
static int use_dmcpy;
static int use_reverse;
static struct ibv_device_attr_ex attrx;

struct pingpong_context {
	struct ibv_context	*context;
	struct ibv_pd		*pd;
	struct ibv_mr		*mr;
	struct ibv_dm		*dm;
	char			*dstbuf;
	int			 dstsize;
};

static struct pingpong_context *pp_init_ctx(struct ibv_device *ib_dev, int size)
{
	struct pingpong_context *ctx;
	int access_flags = IBV_ACCESS_LOCAL_WRITE;

	ctx = calloc(1, sizeof *ctx);
	if (!ctx)
		return NULL;


	ctx->dstsize = size;
	ctx->dstbuf = memalign(page_size, size);
	if (!ctx->dstbuf) {
		fprintf(stderr, "Couldn't allocate work dstbuf.\n");
		goto clean_ctx;
	}

	memset(ctx->dstbuf, 0x7b, size);

	ctx->context = ibv_open_device(ib_dev);
	if (!ctx->context) {
		fprintf(stderr, "Couldn't get context for %s\n",
			ibv_get_device_name(ib_dev));
		goto clean_buffer;
	}

	ctx->pd = ibv_alloc_pd(ctx->context);
	if (!ctx->pd) {
		fprintf(stderr, "Couldn't allocate PD\n");
		goto clean_device;
	}

	if (use_dm) {
		if (ibv_query_device_ex(ctx->context, NULL, &attrx)) {
			fprintf(stderr, "Couldn't query device for its features\n");
			goto clean_pd;
		}

		if (use_dm) {
			struct ibv_alloc_dm_attr dm_attr = {};

			//printf("max_dm_size %lu using size %lu\n", attrx.max_dm_size, size);

			if (!attrx.max_dm_size) {
				fprintf(stderr, "Device doesn't support dm allocation\n");
				goto clean_pd;
			}

			if (attrx.max_dm_size < size) {
				fprintf(stderr, "Device memory is insufficient\n");
				goto clean_pd;
			}

			dm_attr.length = size;
			//dm_attr.length = attrx.max_dm_size;
			ctx->dm = ibv_alloc_dm(ctx->context, &dm_attr);
			if (!ctx->dm) {
				fprintf(stderr, "Dev mem allocation failed\n");
				goto clean_pd;
			}

			access_flags |= IBV_ACCESS_ZERO_BASED;
		}
	}

	//ctx->mr = use_dm ? ibv_reg_dm_mr(ctx->pd, ctx->dm, 0, size, access_flags) :
	//		   ibv_reg_mr(ctx->pd, ctx->dstbuf, size, access_flags);

	//if (!ctx->mr) {
	//	fprintf(stderr, "Couldn't register MR\n");
	//	goto clean_dm;
	//}

	return ctx;

clean_dm:
	if (ctx->dm)
		ibv_free_dm(ctx->dm);

clean_pd:
	ibv_dealloc_pd(ctx->pd);

clean_device:
	ibv_close_device(ctx->context);

clean_buffer:
	free(ctx->dstbuf);

clean_ctx:
	free(ctx);

	return NULL;
}

static int pp_close_ctx(struct pingpong_context *ctx)
{
	//if (ibv_dereg_mr(ctx->mr)) {
	//	fprintf(stderr, "Couldn't deregister MR\n");
	//	return 1;
	//}

	if (ctx->dm) {
		if (ibv_free_dm(ctx->dm)) {
			fprintf(stderr, "Couldn't free DM\n");
			return 1;
		}
	}

	//if (ibv_dealloc_pd(ctx->pd)) {
	//	fprintf(stderr, "Couldn't deallocate PD\n");
	//	return 1;
	//}

	if (ibv_close_device(ctx->context)) {
		fprintf(stderr, "Couldn't release context\n");
		return 1;
	}

	free(ctx->dstbuf);
	free(ctx);

	return 0;
}

static void memcpy_dm1(struct ibv_dm *dm, void *dst, void *src, int size)
{
	memcpy(ibv_get_dm(dm), src, size);
	//printf("%08x %08x\n", ((int *)ibv_get_dm(dm))[0], ((int *)ibv_get_dm(dm))[1]);
}

static void memcpy_dm1_reverse(struct ibv_dm *dm, void *dst, void *src, int size)
{
	memcpy(src, ibv_get_dm(dm), size);
	//printf("%08x %08x\n", ((int *)ibv_get_dm(dm))[0], ((int *)ibv_get_dm(dm))[1]);
}

static void memcpy_dm2(struct ibv_dm *dm, void *dst, void *src, int size)
{
	ibv_memcpy_to_dm(dm, 0, src, size);
}

static void memcpy_dm2_reverse(struct ibv_dm *dm, void *dst, void *src, int size)
{
	ibv_memcpy_from_dm(src, dm, 0, size);
}

static void memcpy_dm3(struct ibv_dm *dm, void *dst, void *src, int size)
{
	memcpy(dst, src, size);
}

static void memcpy_dm3_reverse(struct ibv_dm *dm, void *dst, void *src, int size)
{
	memcpy(src, dst, size);
}

#define FREQ (2000)
static uint64_t cycles2sec(double cycles)
{
	return cycles / 2000 / (1000 * 1000 * 1000);
}

/* run over srcbuf_size */
static void run_test(struct pingpong_context *ctx, int iters)
{
	void (*my_memcpy)(struct ibv_dm *dm, void *dst, void *src, int size);
	uint64_t calib, start, end;
	size_t srcsize[] = {1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072,\
		262144, 524288, 1048576, 2097152, 4194304, 8388608, 16777216,\
		33554432, 67108864, 134217728, 268435456, 536870912, 1073741824};
	size_t size_i, offset;

	if (!use_reverse) {
		if (use_dm && use_dmcpy) {
			my_memcpy = memcpy_dm1;
			//printf("Fast dmcpy\n");
		} else if (use_dm) {
			my_memcpy = memcpy_dm2;
			//printf("Slow dmcpy\n");
		} else {
			my_memcpy = memcpy_dm3;
			//printf("normal memcpy\n");
		}
	} else {
		if (use_dm && use_dmcpy) {
			my_memcpy = memcpy_dm1_reverse;
		} else if (use_dm) {
			my_memcpy = memcpy_dm2_reverse;
		} else {
			my_memcpy = memcpy_dm3_reverse;
		}
	}

	calib = calibrate();
	//printf("#%5s,  %18s, %11s, %6s\n", "size", "rate(B/cycle)", "cycles", "count");
	printf("#%9s,  %18s, %11s, %6s\n", "size", "rate(B/cycle)", "cycles", "count");

	if (use_reverse && use_dm) {
		char *tmpbuf = memalign(page_size, ctx->dstsize);
		memset(tmpbuf, 0x88, ctx->dstsize);
		memcpy_dm1(ctx->dm, NULL, tmpbuf, ctx->dstsize);
		free(tmpbuf);
	}

	for (size_i = 0; size_i < sizeof(srcsize) / sizeof(srcsize[0]); size_i++) {
		uint64_t sum = 0;
		double avg = 0;
		int size = srcsize[size_i], remaining, copy;
		int sizename = size;
		char *srcbuf = memalign(page_size, size);
		int it, count = 0;
		char suffix = ' ';

		memset(srcbuf, 0x77, size);

		for (it = 0; it < iters; it++) {
			offset = 0;

			while (offset < size) {
				remaining = size - offset;
				copy = (ctx->dstsize > remaining) ? remaining : ctx->dstsize;
				{
					start = my_read_cycles();
					my_memcpy(ctx->dm, ctx->dstbuf,
						  srcbuf + offset, copy);
					end = my_update_cycles();
					sum += end - start - calib;
				}
				offset += copy;

			}
			count++;
		}

		if (size >= 1000000) {
			suffix = 'M';
			sizename /= 1000000;
		} else if (size >= 1000) {
			suffix = 'K';
			sizename /= 1000;
		}
		avg = sum / count;
		//printf("%5d%c,  %18.2f, %11.0llu, %6d\n", sizename,
		//       suffix, size / avg, sum, count);
		printf("%10d,  %18.2f, %11.0llu, %6d\n",
		       size, size / avg, sum, count);
	}
}

static void usage(const char *argv0)
{
	printf("Usage:\n");
	printf("  %s            calculate the number of cycles required to copy various buffer sizes to device memory\n", argv0);
	printf("\n");
	printf("Options:\n");
	printf("  -d, --ib-dev=<dev>     use IB device <dev> (default first device found)\n");
	printf("  -s, --size=<size>      size of message to exchange (default 4096)\n");
	printf("  -n, --iters=<iters>    number of inner loop iterations (default 1000)\n");
	printf("  -t, --trials=<trials>    number of outer loop iteratiosn (default 1000)\n");
	printf("  -c, --chk	            validate received buffer\n");
	printf("  -j, --dm	            use device memory\n");
	printf("  -k, --dmcpy               use device memory memcpy\n");
	printf("  -r, --revese              reverse the copy direction, e.g. copy from dm memory\n");
}

int main(int argc, char *argv[])
{
	struct ibv_device      **dev_list;
	struct ibv_device	*ib_dev;
	struct pingpong_context *ctx;
	char                    *ib_devname = NULL;
	unsigned int             size = 4096;
	int			 iters = 1000;

	srand48(getpid() * time(NULL));

	while (1) {
		int c;

		static struct option long_options[] = {
			{ .name = "ib-dev",   .has_arg = 1, .val = 'd' },
			{ .name = "size",     .has_arg = 1, .val = 's' },
			{ .name = "iters",    .has_arg = 1, .val = 'n' },
			{ .name = "chk",      .has_arg = 0, .val = 'c' },
			{ .name = "dm",       .has_arg = 0, .val = 'j' },
			{ .name = "dmcpy",    .has_arg = 0, .val = 'k' },
			{ .name = "reverse",  .has_arg = 0, .val = 'r' },
			{}
		};

		c = getopt_long(argc, argv, "d:s:n:cjkr",
				long_options, NULL);

		if (c == -1)
			break;

		switch (c) {
		case 'd':
			ib_devname = strdupa(optarg);
			break;

		case 's':
			size = strtoul(optarg, NULL, 0);
			if ((size & (size - 1)) != 0) {
				printf("size must be a power of two!\n");
				return 1;
			}
			break;

		case 'n':
			iters = strtoul(optarg, NULL, 0);
			break;

		case 'c':
			validate_buf = 1;
			break;

		case 'j':
			use_dm = 1;
			break;

		case 'k':
			use_dmcpy = 1;
			break;

		case 'r':
			use_reverse = 1;
			break;

		default:
			usage(argv[0]);
			return 1;
		}
	}

	if (optind < argc) {
		usage(argv[0]);
		return 1;
	}

	page_size = sysconf(_SC_PAGESIZE);

	dev_list = ibv_get_device_list(NULL);
	if (!dev_list) {
		perror("Failed to get IB devices list");
		return 1;
	}

	if (!ib_devname) {
		ib_dev = *dev_list;
		if (!ib_dev) {
			fprintf(stderr, "No IB devices found\n");
			return 1;
		}
	} else {
		int i;
		for (i = 0; dev_list[i]; ++i)
			if (!strcmp(ibv_get_device_name(dev_list[i]), ib_devname))
				break;
		ib_dev = dev_list[i];
		if (!ib_dev) {
			fprintf(stderr, "IB device %s not found\n", ib_devname);
			return 1;
		}
	}

	ctx = pp_init_ctx(ib_dev, size);
	if (!ctx)
		return 1;

	if (validate_buf)
		for (int i = 0; i < size; i += page_size) {
			ctx->dstbuf[i] = i / page_size % sizeof(char);
		}

	run_test(ctx, iters);

	if (pp_close_ctx(ctx))
		return 1;

	ibv_free_device_list(dev_list);

	return 0;
}
