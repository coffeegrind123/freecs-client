/*
 * yapb_integrate.qc — Integration layer between YaPB graph and csbot class
 * Provides routing wrappers, Floyd-Warshall, teammate avoidance
 */

/* Floyd-Warshall all-pairs shortest paths */
var int *g_floydNext;
var int g_floydBuilt;

void Floyd_Build(void) {
	if (!g_graphLoaded || g_graphNodeCount > 1500) {
		g_floydBuilt = 0;
		return;
	}

	int n = g_graphNodeCount;
	int matSize = n * n;

	g_floydNext = (int *)memalloc(matSize * 4);

	/* initialize: direct edges */
	for (int i = 0; i < matSize; i++)
		g_floydNext[i] = -1;

	/* set direct connections */
	for (int i = 0; i < n; i++) {
		g_floydNext[i * n + i] = i;
		for (int s = 0; s < YAPB_MAX_LINKS; s++) {
			int j = Graph_LinkIndex(i, s);
			if (j >= 0 && j < n)
				g_floydNext[i * n + j] = j;
		}
	}

	/* Floyd-Warshall: find all-pairs next hops */
	/* We track reachability via g_floydNext != -1 */
	for (int k = 0; k < n; k++) {
		for (int i = 0; i < n; i++) {
			if (g_floydNext[i * n + k] < 0) continue;
			for (int j = 0; j < n; j++) {
				if (g_floydNext[k * n + j] < 0) continue;
				if (g_floydNext[i * n + j] < 0) {
					g_floydNext[i * n + j] = g_floydNext[i * n + k];
				}
			}
		}
	}

	g_floydBuilt = 1;
	dprint(sprintf("Floyd-Warshall built for %f nodes\n", (float)n));
}

int Floyd_NextHop(int from, int to) {
	if (!g_floydBuilt || from < 0 || to < 0) return -1;
	if (from >= g_graphNodeCount || to >= g_graphNodeCount) return -1;
	return g_floydNext[from * g_graphNodeCount + to];
}

void Floyd_Free(void) {
	if (g_floydNext) { memfree(g_floydNext); g_floydNext = 0; }
	g_floydBuilt = 0;
}

/* Per-bot YaPB navigation state */
.int yapb_curTarget;
.float yapb_navTime;

/*
 * Route to a position using YaPB graph (called from csbot methods).
 * Falls back to Nuclide RouteToPosition if no graph.
 * Must be called in bot context (self = csbot).
 */
void YaPB_RouteTo(vector dest) {
	if (g_graphLoaded) {
		YaPB_Nav_FindPath(dest);
		self.yapb_curTarget = Graph_NearestNode(dest);
		self.yapb_navTime = time;
	}
}

/*
 * Get the current navigation target position.
 * Returns the next node origin if following a YaPB path.
 */
vector YaPB_GetNavTarget(void) {
	if (g_graphLoaded && self.yapb_pathLen > 0 && self.yapb_pathCur < self.yapb_pathLen) {
		int nodeIdx = self.yapb_path[self.yapb_pathCur];
		return Graph_NodeOrigin(nodeIdx);
	}
	return self.origin;
}

/*
 * Get flags of the current navigation node.
 */
int YaPB_GetNavFlags(void) {
	if (g_graphLoaded && self.yapb_pathLen > 0 && self.yapb_pathCur < self.yapb_pathLen) {
		int nodeIdx = self.yapb_path[self.yapb_pathCur];
		return Graph_NodeFlags(nodeIdx);
	}
	return 0;
}

/*
 * Check if jump is needed to reach current node.
 */
int YaPB_NavNeedsJump(void) {
	if (!g_graphLoaded || self.yapb_pathLen <= 0) return FALSE;
	if (self.yapb_pathCur <= 0) return FALSE;

	int prevNode = self.yapb_path[self.yapb_pathCur - 1];
	int curNode = self.yapb_path[self.yapb_pathCur];

	for (int s = 0; s < YAPB_MAX_LINKS; s++) {
		if (Graph_LinkIndex(prevNode, s) == curNode) {
			return (Graph_LinkFlags(prevNode, s) & YAPB_LF_JUMP);
		}
	}
	return FALSE;
}

/* ============================================================
 * TEAMMATE AVOIDANCE (from YaPB navigate.cpp doPlayerAvoidance)
 * ============================================================ */

/*
 * Check for nearby teammates and strafe to avoid collisions.
 * Called each frame from RunAI. Modifies input_movevalues.
 * Must be called in bot context (self = csbot).
 */
void YaPB_TeamAvoidance(void) {
	entity hindrance = world;
	float bestDist = 250 * 250;

	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == self || e.health <= 0) continue;
		if (e.team != self.team) continue;

		float dx = e.origin[0] - self.origin[0];
		float dy = e.origin[1] - self.origin[1];
		float dz = e.origin[2] - self.origin[2];
		float distSq = dx*dx + dy*dy + dz*dz;

		if (distSq < bestDist) {
			bestDist = distSq;
			hindrance = e;
		}
	}

	if (hindrance == world) return;

	/* strafe away from teammate */
	makevectors(self.v_angle);
	vector toMate = normalize(hindrance.origin - self.origin);
	float side = toMate * v_right;

	if (side > 0)
		input_movevalues[1] -= 100;
	else
		input_movevalues[1] += 100;
}

/* ============================================================
 * MAP INITIALIZATION
 * ============================================================ */

void YaPB_Navigation_Init(void) {
	YaPB_Graph_Init();
	if (g_graphLoaded && g_graphNodeCount <= 1500)
		Floyd_Build();
}

void YaPB_Navigation_Shutdown(void) {
	Floyd_Free();
}
