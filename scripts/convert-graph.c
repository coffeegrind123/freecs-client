/*
 * convert-graph.c — Convert YaPB .graph files to uncompressed .yapb format
 * Usage: convert-graph input.graph output.yapb
 *        convert-graph --batch input_dir/ output_dir/
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <dirent.h>
#include <sys/stat.h>

#define STORAGE_MAGIC 0x59415042  /* "BPAY" */
#define STORAGE_MAGIC2 0x544f4255 /* "UBTO" compat */
#define MIN_MATCH 4
#define ULZ_EXCESS 16

typedef struct {
    int32_t magic;
    int32_t version;
    int32_t options;
    int32_t length;
    int32_t compressed;
    int32_t uncompressed;
} StorageHeader;

typedef struct {
    char author[32];
    int32_t mapSize;
    char modified[32];
} ExtenHeader;

/* ULZ decompression (from YaPB crlib/ulz.h) */
static uint16_t load16(const uint8_t *p) {
    uint16_t r; memcpy(&r, p, 2); return r;
}

static uint32_t decodeVarInt(const uint8_t **ptr, const uint8_t *end) {
    uint32_t val = 0;
    for (int i = 0; i <= 21; i += 7) {
        if (*ptr >= end) return val;
        uint32_t cur = *(*ptr)++;
        val += cur << i;
        if (cur < 128) break;
    }
    return val;
}

static int ulz_uncompress(const uint8_t *in, int inputLength, uint8_t *out, int outLength) {
    uint8_t *op = out;
    const uint8_t *ip = in;
    const uint8_t *opEnd = op + outLength;
    const uint8_t *ipEnd = ip + inputLength;

    while (ip < ipEnd) {
        uint8_t token = *ip++;

        if (token >= 32) {
            int run = (int)(token >> 5);
            if (run == 7) run += decodeVarInt(&ip, ipEnd);
            if ((opEnd - op) < run || (ipEnd - ip) < run) return -1;
            memcpy(op, ip, run);
            op += run;
            ip += run;
            if (ip >= ipEnd) break;
        }

        int length = (int)((token & 15) + MIN_MATCH);
        if (length == (15 + MIN_MATCH)) length += decodeVarInt(&ip, ipEnd);
        if ((ipEnd - ip) < 2) return -1;
        if ((opEnd - op) < length) return -1;

        int dist = (int)(((token & 16) << 12) + load16(ip));
        ip += 2;
        if (dist == 0 || (op - out) < dist) return -1;

        uint8_t *cp = op - dist;
        if (dist >= 8) {
            memcpy(op, cp, length);
            op += length;
        } else {
            for (int i = 0; i < length; i++)
                *op++ = *cp++;
        }
    }
    return (ip == ipEnd) ? (int)(op - out) : -1;
}

static int convert_file(const char *inpath, const char *outpath) {
    FILE *fin = fopen(inpath, "rb");
    if (!fin) { fprintf(stderr, "Cannot open %s\n", inpath); return 1; }

    StorageHeader hdr;
    if (fread(&hdr, sizeof(hdr), 1, fin) != 1) {
        fprintf(stderr, "Failed to read header from %s\n", inpath);
        fclose(fin); return 1;
    }

    if (hdr.magic != STORAGE_MAGIC && hdr.magic != STORAGE_MAGIC2) {
        fprintf(stderr, "Bad magic in %s: 0x%08x\n", inpath, hdr.magic);
        fclose(fin); return 1;
    }

    if (hdr.length <= 0 || hdr.length > 4096) {
        fprintf(stderr, "Bad node count in %s: %d\n", inpath, hdr.length);
        fclose(fin); return 1;
    }

    uint8_t *compressed = malloc(hdr.compressed + ULZ_EXCESS);
    uint8_t *decompressed = malloc(hdr.uncompressed + ULZ_EXCESS);
    if (!compressed || !decompressed) {
        fprintf(stderr, "Out of memory for %s\n", inpath);
        fclose(fin); free(compressed); free(decompressed); return 1;
    }

    if ((int)fread(compressed, 1, hdr.compressed, fin) != hdr.compressed) {
        fprintf(stderr, "Failed to read compressed data from %s\n", inpath);
        fclose(fin); free(compressed); free(decompressed); return 1;
    }
    fclose(fin);

    int result = ulz_uncompress(compressed, hdr.compressed, decompressed, hdr.uncompressed);
    free(compressed);

    if (result < 0) {
        fprintf(stderr, "Decompression failed for %s\n", inpath);
        free(decompressed); return 1;
    }

    /* Write output: header (node count) + raw node data */
    FILE *fout = fopen(outpath, "wb");
    if (!fout) {
        fprintf(stderr, "Cannot create %s\n", outpath);
        free(decompressed); return 1;
    }

    fwrite(&hdr.length, sizeof(int32_t), 1, fout);
    fwrite(decompressed, 1, hdr.uncompressed, fout);
    fclose(fout);
    free(decompressed);

    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s input.graph output.yapb\n", argv[0]);
        fprintf(stderr, "       %s --batch input_dir/ output_dir/\n", argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "--batch") == 0) {
        if (argc < 4) { fprintf(stderr, "Need input and output dirs\n"); return 1; }
        const char *indir = argv[2];
        const char *outdir = argv[3];

        mkdir(outdir, 0755);

        DIR *d = opendir(indir);
        if (!d) { fprintf(stderr, "Cannot open dir %s\n", indir); return 1; }

        struct dirent *ent;
        int converted = 0, failed = 0;
        while ((ent = readdir(d))) {
            char *ext = strrchr(ent->d_name, '.');
            if (!ext || strcmp(ext, ".graph") != 0) continue;

            char inpath[1024], outpath[1024], basename[256];
            snprintf(inpath, sizeof(inpath), "%s/%s", indir, ent->d_name);
            strncpy(basename, ent->d_name, ext - ent->d_name);
            basename[ext - ent->d_name] = 0;
            snprintf(outpath, sizeof(outpath), "%s/%s.yapb", outdir, basename);

            if (convert_file(inpath, outpath) == 0) {
                converted++;
            } else {
                failed++;
            }
        }
        closedir(d);
        printf("Converted %d files, %d failed\n", converted, failed);
        return (failed > 0) ? 1 : 0;
    }

    return convert_file(argv[1], argv[2]);
}
