/*
 * yapb_graph.qc — YaPB native .graph file loader with ULZ decompression
 * Reads .graph files directly from the yapb/graphs repository.
 * No external conversion step needed.
 *
 * File format (from YaPB storage.h / graph.h):
 *   StorageHeader (24 bytes):
 *     int32 magic        — 0x59415042 ("YAPB") or 0x544f4255 ("UBTO")
 *     int32 version      — StorageVersion (2 for current)
 *     int32 options      — StorageOption bitmask
 *     int32 length       — node count
 *     int32 compressed   — compressed data size
 *     int32 uncompressed — decompressed data size
 *   [compressed Path data] — ULZ compressed
 *   [optional ExtenHeader] — 68 bytes if StorageOption::Exten set
 *
 * Each Path struct (220 bytes = 55 int32s):
 *   [0]    number (int32)
 *   [1]    flags (int32)
 *   [2-4]  origin x,y,z (float)
 *   [5-7]  campStart x,y,z (float)
 *   [8-10] campEnd x,y,z (float)
 *   [11]   radius (float)
 *   [12]   light (float)
 *   [13]   display (float)
 *   [14-53] 8 PathLinks, each 5 int32s:
 *     velocity x,y,z (float), distance (int32), flags|index (uint16+int16)
 *   [54]   PathVis: stand(uint16) + crouch(uint16)
 */

/* Node flags (from YaPB graph.h NodeFlag enum) */
#define YAPB_NF_BUTTON      0x001
#define YAPB_NF_LIFT        0x002
#define YAPB_NF_CROUCH      0x004
#define YAPB_NF_CROSSING    0x008
#define YAPB_NF_GOAL        0x010
#define YAPB_NF_LADDER      0x020
#define YAPB_NF_RESCUE      0x040
#define YAPB_NF_CAMP        0x080
#define YAPB_NF_NOHOSTAGE   0x100
#define YAPB_NF_DOUBLEJUMP  0x200
#define YAPB_NF_NARROW      0x400
#define YAPB_NF_SNIPER      0x10000000
#define YAPB_NF_TONLY       0x20000000
#define YAPB_NF_CTONLY      0x40000000

/* Link flags (from YaPB graph.h PathFlag enum) */
#define YAPB_LF_JUMP        0x0001

/* Limits */
#define YAPB_MAX_NODES      4096
#define YAPB_MAX_LINKS      8
#define YAPB_GRAPH_LOADED   1

/* StorageHeader magic values */
#define YAPB_MAGIC          0x59415042
#define YAPB_MAGIC_UB       0x544f4255

/* ULZ decompression constants (from YaPB crlib/ulz.h) */
#define ULZ_MIN_MATCH       4
#define ULZ_EXCESS          16

/* ============================================================
 * GRAPH DATA — flat arrays for QuakeC compatibility
 * ============================================================ */

var int g_graphNodeCount;
var int g_graphLoaded;

var float *g_graphOriginX;
var float *g_graphOriginY;
var float *g_graphOriginZ;
var int *g_graphFlags;
var float *g_graphRadius;
var float *g_graphCampStartX;
var float *g_graphCampStartY;
var float *g_graphCampStartZ;
var float *g_graphCampEndX;
var float *g_graphCampEndY;
var float *g_graphCampEndZ;

/* Link arrays indexed by node * YAPB_MAX_LINKS + slot */
var int *g_graphLinkIndex;
var int *g_graphLinkDist;
var int *g_graphLinkFlags;

/* Spatial hash for nearest-node lookup */
#define GRAPH_HASH_SIZE     4096
#define GRAPH_BUCKET_MAX    32
var int *g_graphHashBuckets;
var int *g_graphHashCounts;

/* ============================================================
 * BYTE-LEVEL ACCESS HELPERS
 * FTEQW memory-mapped files return int*; these helpers extract
 * and set individual bytes at arbitrary byte offsets.
 * Assumes little-endian (x86/ARM).
 * ============================================================ */

static int _RB(int *data, int off) {
	return (data[off >> 2] >> ((off & 3) << 3)) & 0xFF;
}

static void _WB(int *data, int off, int val) {
	int idx = off >> 2;
	int shift = (off & 3) << 3;
	data[idx] = (data[idx] & ~(0xFF << shift)) | ((val & 0xFF) << shift);
}

static int _R16LE(int *data, int off) {
	return _RB(data, off) | (_RB(data, off + 1) << 8);
}

/* ============================================================
 * ULZ DECOMPRESSION (from YaPB crlib/ulz.h)
 *
 * Token byte layout:
 *   bits 7-5: literal run length (0 if token < 32)
 *             if == 7, extended by decodeVarInt
 *   bit  4:   high bit of match distance
 *   bits 3-0: match length - 4
 *             if == 15, extended by decodeVarInt
 *
 * Match distance = (bit4 << 12) + uint16_LE
 *   giving 17-bit range (max 131071)
 * ============================================================ */

static int g_ulzSrcPos;

static int ULZ_DecodeVarInt(int *data, int end) {
	int val = 0;
	for (int i = 0; i <= 21; i += 7) {
		if (g_ulzSrcPos >= end) return val;
		int cur = _RB(data, g_ulzSrcPos);
		g_ulzSrcPos++;
		val += cur << i;
		if (cur < 128) break;
	}
	return val;
}

static int ULZ_Decompress(int *src, int srcLen, int *dst, int dstLen) {
	g_ulzSrcPos = 0;
	int dp = 0;

	while (g_ulzSrcPos < srcLen) {
		int token = _RB(src, g_ulzSrcPos);
		g_ulzSrcPos++;

		/* literal run (top 3 bits) */
		if (token >= 32) {
			int run = token >> 5;
			if (run == 7)
				run += ULZ_DecodeVarInt(src, srcLen);

			if ((dstLen - dp) < run || (srcLen - g_ulzSrcPos) < run)
				return -1;

			for (int i = 0; i < run; i++) {
				_WB(dst, dp, _RB(src, g_ulzSrcPos));
				dp++;
				g_ulzSrcPos++;
			}

			if (g_ulzSrcPos >= srcLen) break;
		}

		/* match length (bottom 4 bits + MIN_MATCH) */
		int length = (token & 15) + ULZ_MIN_MATCH;
		if (length == (15 + ULZ_MIN_MATCH))
			length += ULZ_DecodeVarInt(src, srcLen);

		if ((srcLen - g_ulzSrcPos) < 2) return -1;
		if ((dstLen - dp) < length) return -1;

		/* match distance: bit 4 gives high bit, plus 16-bit LE value */
		int dist = ((token & 16) << 12) + _R16LE(src, g_ulzSrcPos);
		g_ulzSrcPos += 2;

		if (dist == 0 || dp < dist) return -1;

		/* copy match from earlier in output */
		int cp = dp - dist;
		if (dist >= length) {
			/* non-overlapping: try word-aligned bulk copy */
			int words = length >> 2;
			int rem = length & 3;
			if ((cp & 3) == 0 && (dp & 3) == 0 && words > 0) {
				for (int i = 0; i < words; i++)
					dst[(dp >> 2) + i] = dst[(cp >> 2) + i];
				cp += words << 2;
				dp += words << 2;
				for (int i = 0; i < rem; i++) {
					_WB(dst, dp, _RB(dst, cp));
					dp++;
					cp++;
				}
			} else {
				for (int i = 0; i < length; i++) {
					_WB(dst, dp, _RB(dst, cp));
					dp++;
					cp++;
				}
			}
		} else {
			/* overlapping: must copy byte by byte */
			for (int i = 0; i < length; i++) {
				_WB(dst, dp, _RB(dst, cp));
				dp++;
				cp++;
			}
		}
	}

	return dp;
}

/* ============================================================
 * SPATIAL HASH
 * ============================================================ */

static int Graph_SpatialHash(vector pos) {
	int hx = (int)(pos[0] + 4096) / 256;
	int hy = (int)(pos[1] + 4096) / 256;
	return ((hx * 37 + hy * 17) & (GRAPH_HASH_SIZE - 1));
}

static void Graph_BuildSpatialHash(void) {
	g_graphHashBuckets = (int *)memalloc(GRAPH_HASH_SIZE * GRAPH_BUCKET_MAX * 4);
	g_graphHashCounts = (int *)memalloc(GRAPH_HASH_SIZE * 4);
	for (int i = 0; i < GRAPH_HASH_SIZE; i++)
		g_graphHashCounts[i] = 0;

	for (int i = 0; i < g_graphNodeCount; i++) {
		vector pos;
		pos[0] = g_graphOriginX[i];
		pos[1] = g_graphOriginY[i];
		pos[2] = g_graphOriginZ[i];

		int h = Graph_SpatialHash(pos);
		int c = g_graphHashCounts[h];
		if (c < GRAPH_BUCKET_MAX) {
			g_graphHashBuckets[h * GRAPH_BUCKET_MAX + c] = i;
			g_graphHashCounts[h]++;
		}
	}
}

/* ============================================================
 * NODE ACCESSORS
 * ============================================================ */

int Graph_NearestNode(vector pos) {
	if (!g_graphLoaded) return -1;

	int h = Graph_SpatialHash(pos);
	int bestNode = -1;
	float bestDist = 999999.0;

	int c = g_graphHashCounts[h];
	for (int i = 0; i < c; i++) {
		int n = g_graphHashBuckets[h * GRAPH_BUCKET_MAX + i];
		vector npos;
		npos[0] = g_graphOriginX[n];
		npos[1] = g_graphOriginY[n];
		npos[2] = g_graphOriginZ[n];
		float d = vlen(npos - pos);
		if (d < bestDist) {
			bestDist = d;
			bestNode = n;
		}
	}

	if (bestNode == -1 || bestDist > 500) {
		for (int i = 0; i < g_graphNodeCount; i++) {
			vector npos;
			npos[0] = g_graphOriginX[i];
			npos[1] = g_graphOriginY[i];
			npos[2] = g_graphOriginZ[i];
			float d = vlen(npos - pos);
			if (d < bestDist) {
				bestDist = d;
				bestNode = i;
			}
		}
	}

	return bestNode;
}

vector Graph_NodeOrigin(int node) {
	vector v;
	v[0] = g_graphOriginX[node];
	v[1] = g_graphOriginY[node];
	v[2] = g_graphOriginZ[node];
	return v;
}

int Graph_NodeFlags(int node) {
	return g_graphFlags[node];
}

float Graph_NodeRadius(int node) {
	return g_graphRadius[node];
}

vector Graph_CampStart(int node) {
	vector v;
	v[0] = g_graphCampStartX[node];
	v[1] = g_graphCampStartY[node];
	v[2] = g_graphCampStartZ[node];
	return v;
}

vector Graph_CampEnd(int node) {
	vector v;
	v[0] = g_graphCampEndX[node];
	v[1] = g_graphCampEndY[node];
	v[2] = g_graphCampEndZ[node];
	return v;
}

int Graph_LinkIndex(int node, int slot) {
	return g_graphLinkIndex[node * YAPB_MAX_LINKS + slot];
}

int Graph_LinkDist(int node, int slot) {
	return g_graphLinkDist[node * YAPB_MAX_LINKS + slot];
}

int Graph_LinkFlags(int node, int slot) {
	return g_graphLinkFlags[node * YAPB_MAX_LINKS + slot];
}

/* ============================================================
 * MEMORY MANAGEMENT
 * ============================================================ */

static void Graph_Free(void) {
	if (g_graphOriginX) { memfree(g_graphOriginX); g_graphOriginX = 0; }
	if (g_graphOriginY) { memfree(g_graphOriginY); g_graphOriginY = 0; }
	if (g_graphOriginZ) { memfree(g_graphOriginZ); g_graphOriginZ = 0; }
	if (g_graphFlags) { memfree(g_graphFlags); g_graphFlags = 0; }
	if (g_graphRadius) { memfree(g_graphRadius); g_graphRadius = 0; }
	if (g_graphCampStartX) { memfree(g_graphCampStartX); g_graphCampStartX = 0; }
	if (g_graphCampStartY) { memfree(g_graphCampStartY); g_graphCampStartY = 0; }
	if (g_graphCampStartZ) { memfree(g_graphCampStartZ); g_graphCampStartZ = 0; }
	if (g_graphCampEndX) { memfree(g_graphCampEndX); g_graphCampEndX = 0; }
	if (g_graphCampEndY) { memfree(g_graphCampEndY); g_graphCampEndY = 0; }
	if (g_graphCampEndZ) { memfree(g_graphCampEndZ); g_graphCampEndZ = 0; }
	if (g_graphLinkIndex) { memfree(g_graphLinkIndex); g_graphLinkIndex = 0; }
	if (g_graphLinkDist) { memfree(g_graphLinkDist); g_graphLinkDist = 0; }
	if (g_graphLinkFlags) { memfree(g_graphLinkFlags); g_graphLinkFlags = 0; }
	if (g_graphHashBuckets) { memfree(g_graphHashBuckets); g_graphHashBuckets = 0; }
	if (g_graphHashCounts) { memfree(g_graphHashCounts); g_graphHashCounts = 0; }
	g_graphNodeCount = 0;
	g_graphLoaded = 0;
}

/* ============================================================
 * NODE PARSING — from decompressed Path array
 * ============================================================ */

static void Graph_ParseNodes(int *data, int nodeCount) {
	int n = nodeCount;

	g_graphOriginX = (float *)memalloc(n * 4);
	g_graphOriginY = (float *)memalloc(n * 4);
	g_graphOriginZ = (float *)memalloc(n * 4);
	g_graphFlags = (int *)memalloc(n * 4);
	g_graphRadius = (float *)memalloc(n * 4);
	g_graphCampStartX = (float *)memalloc(n * 4);
	g_graphCampStartY = (float *)memalloc(n * 4);
	g_graphCampStartZ = (float *)memalloc(n * 4);
	g_graphCampEndX = (float *)memalloc(n * 4);
	g_graphCampEndY = (float *)memalloc(n * 4);
	g_graphCampEndZ = (float *)memalloc(n * 4);
	g_graphLinkIndex = (int *)memalloc(n * YAPB_MAX_LINKS * 4);
	g_graphLinkDist = (int *)memalloc(n * YAPB_MAX_LINKS * 4);
	g_graphLinkFlags = (int *)memalloc(n * YAPB_MAX_LINKS * 4);

	for (int i = 0; i < nodeCount; i++) {
		int *p = data + i * 55;
		float *fp = (float *)p;

		g_graphFlags[i] = p[1];
		g_graphOriginX[i] = fp[2];
		g_graphOriginY[i] = fp[3];
		g_graphOriginZ[i] = fp[4];
		g_graphCampStartX[i] = fp[5];
		g_graphCampStartY[i] = fp[6];
		g_graphCampStartZ[i] = fp[7];
		g_graphCampEndX[i] = fp[8];
		g_graphCampEndY[i] = fp[9];
		g_graphCampEndZ[i] = fp[10];
		g_graphRadius[i] = fp[11];

		for (int j = 0; j < YAPB_MAX_LINKS; j++) {
			int linkOff = 14 + j * 5;
			int dist = p[linkOff + 3];
			int flagsAndIndex = p[linkOff + 4];

			int linkFlags = flagsAndIndex & 0xFFFF;
			int linkIndex = (flagsAndIndex >> 16) & 0xFFFF;
			if (linkIndex >= 0x8000) linkIndex -= 0x10000;

			int slot = i * YAPB_MAX_LINKS + j;
			g_graphLinkIndex[slot] = linkIndex;
			g_graphLinkDist[slot] = dist;
			g_graphLinkFlags[slot] = linkFlags;
		}
	}
}

/* ============================================================
 * GRAPH LOADING — reads native YaPB .graph files
 *
 * Search order:
 *   1. graphs/{mapname}.graph
 *   2. data/graphs/{mapname}.graph
 * ============================================================ */

void Graph_Load(string mname) {
	Graph_Free();

	string filename = sprintf("graphs/%s.graph", mname);
	filestream f = fopen(filename, FILE_MMAP_READ);

	if (f < 0) {
		filename = sprintf("data/graphs/%s.graph", mname);
		f = fopen(filename, FILE_MMAP_READ);
	}

	if (f < 0) {
		print(sprintf("YaPB graph not found for map: %s\n", mname));
		return;
	}

	int fileSize = fsize(f);
	int *rawData = (int *)fgets(f);

	if (!rawData || fileSize < 24) {
		dprint(sprintf("YaPB graph file too small: %s\n", filename));
		fclose(f);
		return;
	}

	/* StorageHeader (24 bytes = 6 int32s) */
	int magic = rawData[0];
	int version = rawData[1];
	int options = rawData[2];
	int nodeCount = rawData[3];
	int compressedSize = rawData[4];
	int uncompressedSize = rawData[5];

	if (magic != YAPB_MAGIC && magic != YAPB_MAGIC_UB) {
		dprint(sprintf("Bad magic in graph: %s (0x%x)\n", filename, magic));
		fclose(f);
		return;
	}

	if (nodeCount <= 0 || nodeCount > YAPB_MAX_NODES) {
		dprint(sprintf("Bad node count in graph %s: %d\n", filename, nodeCount));
		fclose(f);
		return;
	}

	if (fileSize < 24 + compressedSize) {
		dprint(sprintf("Graph file truncated: %s\n", filename));
		fclose(f);
		return;
	}

	int expectedBytes = nodeCount * 220;
	if (uncompressedSize < expectedBytes) {
		dprint(sprintf("Uncompressed size too small in %s: %d < %d\n",
			filename, uncompressedSize, expectedBytes));
		fclose(f);
		return;
	}

	/* allocate decompression buffer (round up to int boundary + excess) */
	int dstBytes = uncompressedSize + ULZ_EXCESS;
	int *decompressed = (int *)memalloc(((dstBytes + 3) >> 2) << 2);

	/* compressed data starts immediately after the 24-byte header */
	int *compressedData = rawData + 6;

	int result = ULZ_Decompress(compressedData, compressedSize,
		decompressed, uncompressedSize);

	fclose(f);

	if (result < 0) {
		dprint(sprintf("ULZ decompression failed for %s\n", filename));
		memfree(decompressed);
		return;
	}

	g_graphNodeCount = nodeCount;
	Graph_ParseNodes(decompressed, nodeCount);
	memfree(decompressed);

	Graph_BuildSpatialHash();
	g_graphLoaded = YAPB_GRAPH_LOADED;
	print(sprintf("YaPB graph loaded: %s (%i nodes)\n", filename, nodeCount));
}
