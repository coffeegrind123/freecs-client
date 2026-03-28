/*
 * yapb_graph.qc — YaPB graph data structures, loader, spatial hash
 * Loads .yapb files (converted from YaPB .graph format)
 */

/* Node flags (from YaPB graph.h) */
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

/* Link flags */
#define YAPB_LF_JUMP        0x0001

/* Max constants */
#define YAPB_MAX_NODES      4096
#define YAPB_MAX_LINKS      8
#define YAPB_GRAPH_LOADED   1

/* Per-node data stored in flat arrays for QuakeC compatibility.
 * YaPB Path struct is 220 bytes with 8 links of 20 bytes each.
 * We store node fields and link fields in separate arrays. */

var int g_graphNodeCount;
var int g_graphLoaded;

/* Node arrays (indexed by node ID) */
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

/* Link arrays (indexed by node*8 + linkSlot) */
var int *g_graphLinkIndex;
var int *g_graphLinkDist;
var int *g_graphLinkFlags;

/* Spatial hash for nearest-node lookup */
#define GRAPH_HASH_SIZE     4096
#define GRAPH_BUCKET_MAX    32
var int *g_graphHashBuckets;
var int *g_graphHashCounts;

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

int Graph_NearestNode(vector pos) {
	if (!g_graphLoaded) return -1;

	int h = Graph_SpatialHash(pos);
	int bestNode = -1;
	float bestDist = 999999.0;

	/* check the hash bucket first */
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

	/* if nothing in bucket or too far, brute force */
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

int Graph_LinkIndex(int node, int slot) {
	return g_graphLinkIndex[node * YAPB_MAX_LINKS + slot];
}

int Graph_LinkDist(int node, int slot) {
	return g_graphLinkDist[node * YAPB_MAX_LINKS + slot];
}

int Graph_LinkFlags(int node, int slot) {
	return g_graphLinkFlags[node * YAPB_MAX_LINKS + slot];
}

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

/*
 * Load a .yapb file (pre-decompressed YaPB graph).
 * File format: int32 nodeCount, then nodeCount * 220 bytes of Path data.
 *
 * YaPB Path struct (220 bytes):
 *   int32 number, flags (8 bytes)
 *   float origin.x, .y, .z (12 bytes)
 *   float start.x, .y, .z (12 bytes)
 *   float end.x, .y, .z (12 bytes)
 *   float radius, light, display (12 bytes)
 *   PathLink links[8] (8 * 20 = 160 bytes)
 *     each link: float vel.x,.y,.z (12), int32 dist (4), uint16 flags (2), int16 index (2)
 *   PathVis: uint16 stand, crouch (4 bytes)
 *
 * Total per node: 8 + 12 + 12 + 12 + 12 + 160 + 4 = 220 bytes
 */
void Graph_Load(string mname) {
	Graph_Free();

	string filename = sprintf("graphs/%s.yapb", mname);
	filestream f = fopen(filename, FILE_READ);

	if (f < 0) {
		dprint(sprintf("YaPB graph not found: %s\n", filename));
		return;
	}

	/* read node count */
	int nodeCount = 0;
	fread(f, (void *)&nodeCount, 4);

	if (nodeCount <= 0 || nodeCount > YAPB_MAX_NODES) {
		dprint(sprintf("Bad node count %f in %s\n", (float)nodeCount, filename));
		fclose(f);
		return;
	}

	g_graphNodeCount = nodeCount;

	/* allocate arrays */
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

	/* read each node (220 bytes per YaPB Path struct) */
	for (int i = 0; i < nodeCount; i++) {
		int number, flags;
		float ox, oy, oz;
		float sx, sy, sz;
		float ex, ey, ez;
		float radius, light, display;

		fread(f, (void *)&number, 4);
		fread(f, (void *)&flags, 4);
		fread(f, (void *)&ox, 4); fread(f, (void *)&oy, 4); fread(f, (void *)&oz, 4);
		fread(f, (void *)&sx, 4); fread(f, (void *)&sy, 4); fread(f, (void *)&sz, 4);
		fread(f, (void *)&ex, 4); fread(f, (void *)&ey, 4); fread(f, (void *)&ez, 4);
		fread(f, (void *)&radius, 4);
		fread(f, (void *)&light, 4);
		fread(f, (void *)&display, 4);

		g_graphOriginX[i] = ox;
		g_graphOriginY[i] = oy;
		g_graphOriginZ[i] = oz;
		g_graphFlags[i] = flags;
		g_graphRadius[i] = radius;
		g_graphCampStartX[i] = sx;
		g_graphCampStartY[i] = sy;
		g_graphCampStartZ[i] = sz;
		g_graphCampEndX[i] = ex;
		g_graphCampEndY[i] = ey;
		g_graphCampEndZ[i] = ez;

		/* read 8 links (20 bytes each) */
		for (int j = 0; j < YAPB_MAX_LINKS; j++) {
			float vx, vy, vz;
			int dist;
			int flagsAndIndex;

			fread(f, (void *)&vx, 4);
			fread(f, (void *)&vy, 4);
			fread(f, (void *)&vz, 4);
			fread(f, (void *)&dist, 4);
			fread(f, (void *)&flagsAndIndex, 4);

			int linkFlags = flagsAndIndex & 0xFFFF;
			int linkIndex = (flagsAndIndex >> 16) & 0xFFFF;
			if (linkIndex == 0xFFFF) linkIndex = -1;
			if (linkIndex >= 0x8000) linkIndex -= 0x10000;

			int slot = i * YAPB_MAX_LINKS + j;
			g_graphLinkIndex[slot] = linkIndex;
			g_graphLinkDist[slot] = dist;
			g_graphLinkFlags[slot] = linkFlags;
		}

		/* skip PathVis (4 bytes) */
		int vis;
		fread(f, (void *)&vis, 4);
	}

	fclose(f);

	Graph_BuildSpatialHash();
	g_graphLoaded = YAPB_GRAPH_LOADED;
	dprint(sprintf("YaPB graph loaded: %s (%f nodes)\n", filename, (float)nodeCount));
}
