/*
 * YaPB Enhancement Layer for FreeCS — Rules-Only Implementation
 * Based on YaPB by YaPB Project Developers (MIT License)
 *
 * All bot state is stored in a global array indexed by entity slot,
 * avoiding any changes to csPlayer class or entity serialization.
 * This file is compiled ONLY into progs/counterstrike.dat.
 */

/* Personalities */
#define PERSONALITY_NORMAL   0
#define PERSONALITY_RUSHER   1
#define PERSONALITY_CAREFUL  2

/* Difficulty levels */
#define DIFFICULTY_NOOB      0
#define DIFFICULTY_EASY      1
#define DIFFICULTY_NORMAL    2
#define DIFFICULTY_HARD      3
#define DIFFICULTY_EXPERT    4

/* Sensing states */
#define YSTATE_SEEING_ENEMY  (1<<0)
#define YSTATE_HEARING_ENEMY (1<<1)

#define YAPB_MAX_SLOTS 32

/* Per-bot state — stored externally, not on entity */
typedef struct {
	bool initialized;
	int personality;
	int difficulty;
	float aggression;
	float fear;
	float lastThink;
	float shootTime;
	float stuckTime;
	vector prevOrigin;
	int stuckCount;
	float campEnd;
	float heardTime;
	vector heardPos;
	int senseStates;
	float seeEnemyTime;
	entity lastEnemy;
	vector lastEnemyPos;
} yapb_state_t;

yapb_state_t g_yapb[YAPB_MAX_SLOTS];

/* Difficulty data arrays */
var float g_yDiffReactMin[] = {0.8, 0.4, 0.2, 0.1, 0.0};
var float g_yDiffReactMax[] = {1.5, 0.8, 0.5, 0.3, 0.1};
var float g_yDiffHeadshot[] = {0.00, 0.10, 0.30, 0.60, 0.90};
var float g_yDiffHearing[]  = {0.30, 0.50, 0.70, 0.90, 1.00};
var float g_yDiffAimErrMin[]= {50.0, 30.0, 15.0, 5.0, 0.0};
var float g_yDiffAimErrMax[]= {80.0, 50.0, 30.0, 15.0, 5.0};

/*
 * YaPB_GetSlot — Get slot index for an entity.
 */
int
YaPB_GetSlot(entity e)
{
	return (int)(num_for_edict(e) - 1);
}

/*
 * YaPB_InitBot — Initialize YaPB state for a bot.
 */
void
YaPB_InitBot(entity bot)
{
	int s = YaPB_GetSlot(bot);
	if (s < 0 || s >= YAPB_MAX_SLOTS) return;

	g_yapb[s].initialized = true;
	g_yapb[s].personality = (int)floor(random(0, 3));
	g_yapb[s].difficulty = bound(0, (int)cvar("bot_skill"), 4);

	switch (g_yapb[s].personality) {
	case PERSONALITY_RUSHER:
		g_yapb[s].aggression = 0.7;
		g_yapb[s].fear = 0.1;
		break;
	case PERSONALITY_CAREFUL:
		g_yapb[s].aggression = 0.2;
		g_yapb[s].fear = 0.6;
		break;
	default:
		g_yapb[s].aggression = 0.4;
		g_yapb[s].fear = 0.3;
		break;
	}

	g_yapb[s].lastThink = time;
	g_yapb[s].shootTime = 0;
	g_yapb[s].stuckTime = 0;
	g_yapb[s].stuckCount = 0;
	g_yapb[s].campEnd = 0;
	g_yapb[s].heardTime = 0;
	g_yapb[s].senseStates = 0;
	g_yapb[s].seeEnemyTime = 0;
	g_yapb[s].lastEnemy = __NULL__;
}

/*
 * YaPB_IsInFOV — Check if target is in bot's field of view.
 */
bool
YaPB_IsInFOV(entity bot, entity target, float fov)
{
	makevectors(self.v_angle);
	vector dir = normalize(target.origin - self.origin);
	float dot = dir * v_forward;
	float threshold = cos((fov / 2.0) * (M_PI / 180.0));
	return (dot >= threshold);
}

/*
 * YaPB_SoundCheck — Listen for nearby enemy activity.
 */
void
YaPB_SoundCheck(entity bot, int s)
{
	int diff = g_yapb[s].difficulty;
	if (random() > g_yDiffHearing[diff])
		return;

	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == bot || e.team == self.team || e.health <= 0)
			continue;

		float dist = vlen(e.origin - self.origin);

		/* gunfire */
		if (e.button0 && dist < 900.0) {
			g_yapb[s].heardPos = e.origin;
			g_yapb[s].heardTime = time;
			g_yapb[s].senseStates |= YSTATE_HEARING_ENEMY;
			return;
		}
		/* footsteps */
		if (vlen(e.velocity) > 150.0 && dist < 500.0) {
			g_yapb[s].heardPos = e.origin;
			g_yapb[s].heardTime = time;
			g_yapb[s].senseStates |= YSTATE_HEARING_ENEMY;
			return;
		}
	}

	if (time > g_yapb[s].heardTime + 6.0)
		g_yapb[s].senseStates &= ~YSTATE_HEARING_ENEMY;
}

/*
 * YaPB_CombatThink — Enhanced combat for a bot entity.
 */
void
YaPB_CombatThink(entity bot, entity enemy, int s)
{
	int diff = g_yapb[s].difficulty;
	float dist = vlen(enemy.origin - self.origin);

	/* difficulty-based strafing */
	if (diff >= DIFFICULTY_NORMAL && dist < 800.0) {
		float strafeDir = (random() < 0.5) ? -1.0 : 1.0;
		input_movevalues[1] = strafeDir * 190.0;
	}

	/* rush or retreat */
	if (g_yapb[s].aggression > g_yapb[s].fear && dist > 200.0) {
		input_movevalues[0] = 190.0;
	} else if (g_yapb[s].fear > g_yapb[s].aggression && dist < 300.0) {
		input_movevalues[0] = -133.0;
	}

	/* crouch at range */
	if (dist > 400.0 && dist < 900.0 && diff >= DIFFICULTY_HARD) {
		input_buttons |= INPUT_BUTTON8;
	}

	/* fire control */
	if (time >= g_yapb[s].shootTime) {
		makevectors(self.v_angle);
		vector dir = normalize(enemy.origin - self.origin);
		float dot = dir * v_forward;
		float threshold = 0.85 + (diff * 0.03);

		if (dot >= threshold) {
			input_buttons |= INPUT_BUTTON0;
			g_yapb[s].shootTime = time + 0.08 + random() * 0.04;
		}
	}

	/* retreat if low health */
	if (self.health < 25 || (self.health < 40 && g_yapb[s].personality == PERSONALITY_CAREFUL)) {
		input_movevalues[0] = -133.0;
		if (random() < 0.3)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * 152.0;
	}
}

/*
 * YaPB_AimEnhance — Difficulty-based aiming for a bot.
 */
void
YaPB_AimEnhance(entity bot, entity target, int s)
{
	int diff = g_yapb[s].difficulty;
	vector aimTarget;

	/* headshot chance */
	if (random() < g_yDiffHeadshot[diff])
		aimTarget = target.origin + target.view_ofs;
	else
		aimTarget = target.origin + target.view_ofs * 0.4;

	/* aim error */
	float errMin = g_yDiffAimErrMin[diff];
	float errMax = g_yDiffAimErrMax[diff];
	float err = errMin + random() * (errMax - errMin);
	aimTarget[0] += crandom() * err * 0.01;
	aimTarget[1] += crandom() * err * 0.01;

	/* aim speed */
	float aimSpeed = bound(0.0, frametime * (20 + diff * 12), 1.0);

	vector oldAngles = anglesToForward(self.v_angle);
	vector aimDir = vectorToAngles(aimTarget - (self.origin + self.view_ofs));
	vector newAngles = vectorLerp(oldAngles, anglesToForward(aimDir), aimSpeed);

	input_angles = self.angles = self.v_angle = vectorToAngles(newAngles);
}

/*
 * YaPB_StuckCheck — Detect and resolve stuck bots.
 */
void
YaPB_StuckCheck(entity bot, int s)
{
	if (time < g_yapb[s].stuckTime) return;
	g_yapb[s].stuckTime = time + 0.5;

	float speed = vlen(self.origin - g_yapb[s].prevOrigin);
	g_yapb[s].prevOrigin = self.origin;

	if (speed < 10.0 && vlen(input_movevalues) > 50.0) {
		g_yapb[s].stuckCount++;
		if (g_yapb[s].stuckCount > 4) input_buttons |= INPUT_BUTTON2; /* jump */
		if (g_yapb[s].stuckCount > 8) input_buttons |= INPUT_BUTTON8; /* crouch */
		if (g_yapb[s].stuckCount > 12) {
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * 152.0;
		}
	} else {
		g_yapb[s].stuckCount = 0;
	}
}

/*
 * YaPB_BotThink — Main per-bot think. Called from YaPB_FrameThink.
 */
void
YaPB_BotThink(entity bot)
{
	int s = YaPB_GetSlot(bot);
	if (s < 0 || s >= YAPB_MAX_SLOTS) return;

	if (!g_yapb[s].initialized)
		YaPB_InitBot(bot);

	int diff = g_yapb[s].difficulty;

	/* reaction time throttle */
	float reactMin = g_yDiffReactMin[diff];
	float reactMax = g_yDiffReactMax[diff];
	float react = reactMin + random() * (reactMax - reactMin);
	if (react < 0.02) react = 0.02;

	if (time - g_yapb[s].lastThink < react)
		return;
	g_yapb[s].lastThink = time;

	/* update aggression/fear from health */
	if (self.health < 40)
		g_yapb[s].fear = bound(0.0, g_yapb[s].fear + 0.15, 1.0);
	if (self.health > 80)
		g_yapb[s].aggression = bound(0.0, g_yapb[s].aggression + 0.05, 1.0);

	/* sound awareness */
	YaPB_SoundCheck(bot, s);

	/* find visible enemy */
	entity visEnemy = __NULL__;
	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == bot || e.health <= 0 || e.team == self.team)
			continue;
		if (!YaPB_IsInFOV(bot, e, 75.0))
			continue;
		traceline(self.origin + self.view_ofs, e.origin + e.view_ofs * 0.5, MOVE_NORMAL, bot);
		if (trace_ent == e || trace_fraction >= 0.98) {
			visEnemy = e;
			g_yapb[s].senseStates |= YSTATE_SEEING_ENEMY;
			g_yapb[s].seeEnemyTime = time;
			break;
		}
	}

	if (visEnemy == __NULL__ && time > g_yapb[s].seeEnemyTime + 3.0)
		g_yapb[s].senseStates &= ~YSTATE_SEEING_ENEMY;

	/* combat mode */
	if (visEnemy != __NULL__) {
		YaPB_CombatThink(bot, visEnemy, s);
		YaPB_AimEnhance(bot, visEnemy, s);
	}

	/* stuck detection */
	YaPB_StuckCheck(bot, s);
}

/*
 * YaPB_FrameThink — Called from CodeCallback_FrameStart().
 * Iterates all bots and runs enhanced AI.
 */
void
YaPB_FrameThink(void)
{
	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (clienttype(e) == CLIENTTYPE_REAL)
			continue;
		if (e.health <= 0)
			continue;
		YaPB_BotThink(e);
	}
}
