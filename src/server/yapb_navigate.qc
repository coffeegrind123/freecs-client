/*
 * yapb_navigate.qc — Bot navigation using YaPB graph
 * All functions run in bot context (self = bot entity)
 */

/* Per-bot navigation state (entity fields) */
.int yapb_path[ASTAR_MAX_PATH];
.int yapb_pathLen;
.int yapb_pathCur;
.float yapb_pathTimeout;

/*
 * Find a path from self's position to destination using A*.
 * Must be called in bot context (self = bot).
 */
void YaPB_Nav_FindPath(vector dest) {
	if (!g_graphLoaded) return;

	int srcNode = Graph_NearestNode(self.origin);
	int destNode = Graph_NearestNode(dest);

	if (srcNode < 0 || destNode < 0) return;

	int pathLen = AStar_Find(srcNode, destNode);
	if (pathLen <= 0) return;

	self.yapb_pathLen = pathLen;
	self.yapb_pathCur = 0;
	self.yapb_pathTimeout = time + 30.0;

	for (int i = 0; i < pathLen && i < ASTAR_MAX_PATH; i++)
		self.yapb_path[i] = g_astarPath[i];
}

/*
 * Follow the current path. Returns TRUE if navigating.
 * Must be called in bot context (self = bot).
 */
float YaPB_Nav_Follow(void) {
	if (!g_graphLoaded) return FALSE;
	if (self.yapb_pathLen <= 0) return FALSE;
	if (self.yapb_pathCur >= self.yapb_pathLen) {
		self.yapb_pathLen = 0;
		return FALSE;
	}

	if (time > self.yapb_pathTimeout) {
		self.yapb_pathLen = 0;
		return FALSE;
	}

	int nodeIdx = self.yapb_path[self.yapb_pathCur];
	vector nodePos = Graph_NodeOrigin(nodeIdx);
	float nodeRad = Graph_NodeRadius(nodeIdx);
	if (nodeRad < 64) nodeRad = 64;
	int nodeFlags = Graph_NodeFlags(nodeIdx);

	float dist = vlen(nodePos - self.origin);

	if (dist < nodeRad) {
		self.yapb_pathCur++;
		self.yapb_pathTimeout = time + 30.0;

		if (self.yapb_pathCur >= self.yapb_pathLen) {
			self.yapb_pathLen = 0;
			return FALSE;
		}

		nodeIdx = self.yapb_path[self.yapb_pathCur];
		nodePos = Graph_NodeOrigin(nodeIdx);
		nodeFlags = Graph_NodeFlags(nodeIdx);
	}

	/* movement is set by the calling csbot class, not here */

	/* node flag handling done by calling csbot class */

	/* jump/narrow handling done by calling csbot class */

	return TRUE;
}

void YaPB_Nav_Clear(void) {
	self.yapb_pathLen = 0;
	self.yapb_pathCur = 0;
}

float YaPB_Nav_HasPath(void) {
	return (self.yapb_pathLen > 0 && self.yapb_pathCur < self.yapb_pathLen);
}

int Graph_FindGoalNode(int flagMask) {
	if (!g_graphLoaded) return -1;

	int candidates[64];
	int count = 0;

	for (int i = 0; i < g_graphNodeCount && count < 64; i++) {
		if (g_graphFlags[i] & flagMask)
			candidates[count++] = i;
	}

	if (count == 0) return -1;
	return candidates[(int)(random() * count) % count];
}

int Graph_FindCampNode(vector near, float maxDist) {
	if (!g_graphLoaded) return -1;

	int bestNode = -1;
	float bestDist = maxDist;

	for (int i = 0; i < g_graphNodeCount; i++) {
		if (!(g_graphFlags[i] & (YAPB_NF_CAMP | YAPB_NF_SNIPER)))
			continue;
		vector npos = Graph_NodeOrigin(i);
		float d = vlen(npos - near);
		if (d < bestDist) {
			bestDist = d;
			bestNode = i;
		}
	}
	return bestNode;
}

void YaPB_Graph_Init(void) {
	Graph_Load(mapname);
}
