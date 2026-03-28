/*
 * yapb_pathfind.qc — A* pathfinder with binary heap for YaPB graph
 */

#define ASTAR_NEW    0
#define ASTAR_OPEN   1
#define ASTAR_CLOSED 2

/* Binary min-heap for A* open list */
var float *g_heapCost;
var int *g_heapNode;
var int g_heapCount;
var int g_heapCapacity;

static void Heap_Init(int capacity) {
	g_heapCapacity = capacity;
	g_heapCount = 0;
	g_heapCost = (float *)memalloc(capacity * 4);
	g_heapNode = (int *)memalloc(capacity * 4);
}

static void Heap_Free(void) {
	if (g_heapCost) { memfree(g_heapCost); g_heapCost = 0; }
	if (g_heapNode) { memfree(g_heapNode); g_heapNode = 0; }
	g_heapCount = 0;
}

static void Heap_Push(int node, float cost) {
	if (g_heapCount >= g_heapCapacity) return;

	int i = g_heapCount++;
	g_heapCost[i] = cost;
	g_heapNode[i] = node;

	/* bubble up */
	while (i > 0) {
		int parent = (i - 1) / 2;
		if (g_heapCost[parent] <= g_heapCost[i]) break;
		/* swap */
		float tc = g_heapCost[i]; g_heapCost[i] = g_heapCost[parent]; g_heapCost[parent] = tc;
		int tn = g_heapNode[i]; g_heapNode[i] = g_heapNode[parent]; g_heapNode[parent] = tn;
		i = parent;
	}
}

static int Heap_Pop(void) {
	if (g_heapCount <= 0) return -1;

	int result = g_heapNode[0];
	g_heapCount--;

	if (g_heapCount > 0) {
		g_heapCost[0] = g_heapCost[g_heapCount];
		g_heapNode[0] = g_heapNode[g_heapCount];

		/* bubble down */
		int i = 0;
		while (TRUE) {
			int left = 2 * i + 1;
			int right = 2 * i + 2;
			int smallest = i;

			if (left < g_heapCount && g_heapCost[left] < g_heapCost[smallest])
				smallest = left;
			if (right < g_heapCount && g_heapCost[right] < g_heapCost[smallest])
				smallest = right;

			if (smallest == i) break;

			float tc = g_heapCost[i]; g_heapCost[i] = g_heapCost[smallest]; g_heapCost[smallest] = tc;
			int tn = g_heapNode[i]; g_heapNode[i] = g_heapNode[smallest]; g_heapNode[smallest] = tn;
			i = smallest;
		}
	}
	return result;
}

/* A* state arrays (allocated per search) */
var float *g_astarG;
var float *g_astarF;
var int *g_astarParent;
var int *g_astarState;

/* A* path result */
#define ASTAR_MAX_PATH 256
var int g_astarPath[ASTAR_MAX_PATH];
var int g_astarPathLen;

/* Heuristic: Euclidean distance between two nodes */
static float AStar_Heuristic(int a, int b) {
	float dx = g_graphOriginX[a] - g_graphOriginX[b];
	float dy = g_graphOriginY[a] - g_graphOriginY[b];
	float dz = g_graphOriginZ[a] - g_graphOriginZ[b];
	return sqrt(dx*dx + dy*dy + dz*dz);
}

/*
 * A* pathfinding from src to dest.
 * Returns path length (0 = no path found).
 * Path stored in g_astarPath[] (reversed: [0] = first node to visit).
 */
int AStar_Find(int src, int dest) {
	if (!g_graphLoaded || src < 0 || dest < 0) return 0;
	if (src == dest) {
		g_astarPath[0] = dest;
		g_astarPathLen = 1;
		return 1;
	}

	int n = g_graphNodeCount;

	/* allocate state arrays */
	g_astarG = (float *)memalloc(n * 4);
	g_astarF = (float *)memalloc(n * 4);
	g_astarParent = (int *)memalloc(n * 4);
	g_astarState = (int *)memalloc(n * 4);

	for (int i = 0; i < n; i++) {
		g_astarG[i] = 999999.0;
		g_astarF[i] = 999999.0;
		g_astarParent[i] = -1;
		g_astarState[i] = ASTAR_NEW;
	}

	Heap_Init(n);

	g_astarG[src] = 0;
	g_astarF[src] = AStar_Heuristic(src, dest);
	g_astarState[src] = ASTAR_OPEN;
	Heap_Push(src, g_astarF[src]);

	int found = 0;

	while (g_heapCount > 0) {
		int current = Heap_Pop();

		if (current == dest) {
			found = 1;
			break;
		}

		if (g_astarState[current] == ASTAR_CLOSED)
			continue;
		g_astarState[current] = ASTAR_CLOSED;

		/* expand neighbors */
		for (int s = 0; s < YAPB_MAX_LINKS; s++) {
			int neighbor = g_graphLinkIndex[current * YAPB_MAX_LINKS + s];
			if (neighbor < 0 || neighbor >= n) continue;
			if (g_astarState[neighbor] == ASTAR_CLOSED) continue;

			float edgeCost = (float)g_graphLinkDist[current * YAPB_MAX_LINKS + s];
			if (edgeCost <= 0)
				edgeCost = AStar_Heuristic(current, neighbor);

			float tentG = g_astarG[current] + edgeCost;

			if (tentG < g_astarG[neighbor]) {
				g_astarG[neighbor] = tentG;
				g_astarF[neighbor] = tentG + AStar_Heuristic(neighbor, dest);
				g_astarParent[neighbor] = current;

				if (g_astarState[neighbor] != ASTAR_OPEN) {
					g_astarState[neighbor] = ASTAR_OPEN;
				}
				Heap_Push(neighbor, g_astarF[neighbor]);
			}
		}
	}

	Heap_Free();

	/* reconstruct path */
	g_astarPathLen = 0;
	if (found) {
		/* trace back from dest to src */
		int tempPath[ASTAR_MAX_PATH];
		int tempLen = 0;
		int cur = dest;

		while (cur != -1 && tempLen < ASTAR_MAX_PATH) {
			tempPath[tempLen++] = cur;
			if (cur == src) break;
			cur = g_astarParent[cur];
		}

		/* reverse into g_astarPath (so [0] = first node after src) */
		g_astarPathLen = 0;
		for (int i = tempLen - 2; i >= 0; i--) {
			if (g_astarPathLen < ASTAR_MAX_PATH)
				g_astarPath[g_astarPathLen++] = tempPath[i];
		}
	}

	/* free state arrays */
	memfree(g_astarG); g_astarG = 0;
	memfree(g_astarF); g_astarF = 0;
	memfree(g_astarParent); g_astarParent = 0;
	memfree(g_astarState); g_astarState = 0;

	return g_astarPathLen;
}
