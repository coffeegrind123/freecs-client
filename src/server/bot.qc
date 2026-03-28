/*
 * Copyright (c) 2016-2021 Marco Cawthorne <marco@icculus.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

vector getEntityCenterPos(entity e) {
	vector newVec;
	newVec[0] = e.absmin[0] + (0.5 * (e.absmax[0] - e.absmin[0]));
	newVec[1] = e.absmin[1] + (0.5 * (e.absmax[1] - e.absmin[1]));
	newVec[2] = e.absmin[2] + (0.5 * (e.absmax[2] - e.absmin[2]));
	return newVec;
}

/* YaPB personality types */
#define YAPB_PERS_NORMAL  0
#define YAPB_PERS_RUSHER  1
#define YAPB_PERS_CAREFUL 2

/* YaPB difficulty levels */
#define YAPB_DIFF_NOOB    0
#define YAPB_DIFF_EASY    1
#define YAPB_DIFF_NORMAL  2
#define YAPB_DIFF_HARD    3
#define YAPB_DIFF_EXPERT  4

/* Task types — priorities in parentheses */
#define YAPB_TASK_NORMAL      0
#define YAPB_TASK_PAUSE       1
#define YAPB_TASK_CAMP        2
#define YAPB_TASK_FOLLOW      3
#define YAPB_TASK_PICKUP      4
#define YAPB_TASK_HUNT        5
#define YAPB_TASK_MOVETOPOS   6
#define YAPB_TASK_DEFUSE      7
#define YAPB_TASK_PLANT       8
#define YAPB_TASK_ATTACK      9
#define YAPB_TASK_SEEKCOVER   10
#define YAPB_TASK_HIDE        11
#define YAPB_TASK_THROWHE     12
#define YAPB_TASK_THROWFB     13
#define YAPB_TASK_THROWSM     14
#define YAPB_TASK_BLIND       15
#define YAPB_TASK_ESCAPEBOMB  16
#define YAPB_TASK_COUNT       17

#define YAPB_TASKSTACK_MAX 8

/* Task priorities (higher = more urgent) */
var float g_yapbTaskPri[] = {
	35,  /* NORMAL */
	36,  /* PAUSE */
	37,  /* CAMP */
	39,  /* FOLLOW */
	42,  /* PICKUP */
	45,  /* HUNT */
	50,  /* MOVETOPOS */
	89,  /* DEFUSE */
	89,  /* PLANT */
	90,  /* ATTACK */
	91,  /* SEEKCOVER */
	92,  /* HIDE */
	99,  /* THROWHE */
	99,  /* THROWFB */
	99,  /* THROWSM */
	100, /* BLIND */
	100  /* ESCAPEBOMB */
};

/* Buy states */
#define YAPB_BUY_PRIMARY    0
#define YAPB_BUY_ARMOR      1
#define YAPB_BUY_SECONDARY  2
#define YAPB_BUY_AMMO       3
#define YAPB_BUY_GRENADES   4
#define YAPB_BUY_DEFKIT     5
#define YAPB_BUY_NVG        6
#define YAPB_BUY_DONE       7

class csbot:NSBot
{
	void(void) csbot;

	virtual void(void) RunToConfront;
	virtual void(void) RunToBomb;
	virtual void(int)  RunToBombsite;
	virtual void(void) RunToRandomBombsite;
	virtual void(int)  RunToEscapeZone;
	virtual void(void) RunToRandomEscapeZone;
	virtual void(int)  RunToVIPSafetyZone;
	virtual void(void) RunToRandomVIPSafetyZone;
	virtual void(void) RunToHostages;
	virtual void(vector, int) Roam;

	virtual void(void) CreateObjective;
	virtual void(void) PostFrame;
	virtual void(void) WeaponThink;
	virtual void(void) SeeThink;
	virtual void(void) RunAI;

	virtual entity(string, int) GetEntityByNameAndIndex;
	virtual entity(int) GetBombsiteByIndex;
	virtual entity(int) GetEscapeZoneByIndex;
	virtual entity(int) GetVIPSafetyZoneByIndex;
	virtual void(vector, float) AimLerp;

	/* YaPB core */
	nonvirtual void(void) YaPB_Init;
	nonvirtual void(void) YaPB_CombatThink;
	nonvirtual void(void) YaPB_AimThink;
	nonvirtual void(void) YaPB_SoundAwareness;
	nonvirtual void(void) YaPB_StuckCheck;
	nonvirtual bool(entity, float) YaPB_IsInFOV;

	/* task system */
	nonvirtual void(int, vector, float) YaPB_TaskPush;
	nonvirtual void(void) YaPB_TaskPop;
	nonvirtual void(void) YaPB_TaskClear;
	nonvirtual int(void) YaPB_TaskGetType;
	nonvirtual void(void) YaPB_TaskFilter;
	nonvirtual void(void) YaPB_TaskExecute;

	/* task handlers */
	nonvirtual void(void) YaPB_TaskNormal;
	nonvirtual void(void) YaPB_TaskAttack;
	nonvirtual void(void) YaPB_TaskHunt;
	nonvirtual void(void) YaPB_TaskSeekCover;
	nonvirtual void(void) YaPB_TaskHide;
	nonvirtual void(void) YaPB_TaskPlant;
	nonvirtual void(void) YaPB_TaskDefuse;
	nonvirtual void(void) YaPB_TaskCamp;
	nonvirtual void(void) YaPB_TaskEscapeBomb;
	nonvirtual void(void) YaPB_TaskBlind;
	nonvirtual void(void) YaPB_TaskThrowGrenade;

	/* weapon selection */
	nonvirtual void(void) YaPB_SelectBestWeapon;
	nonvirtual bool(int, float) YaPB_IsWeaponBadAtDist;
	nonvirtual int(int) YaPB_GetWeaponAmmo;

	/* grenade system */
	nonvirtual int(void) YaPB_BestGrenade;
	nonvirtual void(void) YaPB_CheckGrenadeThrow;

	/* radio */
	nonvirtual void(float) YaPB_Radio;
	nonvirtual void(void) YaPB_RadioThink;

	/* navigation helpers */
	nonvirtual void(void) YaPB_LadderThink;
	nonvirtual void(void) YaPB_DoorThink;

	int m_actionIsPlanting;
	int m_actionIsDefusing;

	int m_gflagsBackup;

	/* YaPB state */
	int m_yapbPersonality;
	int m_yapbDifficulty;
	float m_yapbAggression;
	float m_yapbFear;
	float m_yapbBaseAggression;
	float m_yapbBaseFear;
	float m_yapbShootTime;
	float m_yapbSeeTime;
	float m_yapbHeardTime;
	vector m_yapbHeardPos;
	float m_yapbStuckTime;
	vector m_yapbPrevOrigin;
	int m_yapbStuckCount;
	float m_yapbLookYawVel;
	float m_yapbLookPitchVel;
	bool m_yapbInitialized;

	/* task stack (max 8 entries) */
	int m_yapbTaskStack[8];
	float m_yapbTaskTime[8];
	vector m_yapbTaskData[8];
	int m_yapbTaskCount;

	/* weapon selection */
	float m_yapbWeaponCheckTime;

	/* buy state */
	int m_yapbBuyState;
	int m_yapbEconomyOk;

	/* grenade */
	float m_yapbNadeCheckTime;
	int m_yapbNadeType;
	vector m_yapbNadeTarget;
	float m_yapbNadeThrowTime;

	/* camping */
	float m_yapbCampEnd;
	vector m_yapbCampLookA;
	vector m_yapbCampLookB;
	float m_yapbCampLookSwitch;
	int m_yapbCampHealth;

	/* radio */
	float m_yapbRadioTime;
	int m_yapbRadioRoundSpot;

	/* navigation */
	int m_yapbDoorRetries;
	float m_yapbDoorWaitTime;

	/* tracking */
	vector m_yapbLastEnemyOrigin;
	float m_yapbLastEnemySeen;
	entity m_yapbLastEnemyEnt;

	/* body-part aiming */
	int m_yapbEnemyParts;
	int m_yapbAimPart;
	entity m_yapbAimPartEnt;

	/* blind tracking */
	float m_yapbBlindEnd;
};

/* Difficulty presets from YaPB config.cpp:618-636
 * Format: [noob, easy, normal, hard, expert]
 * reaction = min/max delay before spotting enemy (seconds)
 * headshot = probability of aiming for head (0.0-1.0, from 0-100 int)
 * seenThru/hearThru = chance to detect through walls (0.0-1.0)
 * maxRecoil = recoil control (YaPB: 38-21 where lower=better, normalized to 0-1)
 * aimError = aim offset in units (x,y,z per difficulty) */
var float g_yapbReactMin[]  = {0.8, 0.6, 0.4, 0.2, 0.1};
var float g_yapbReactMax[]  = {1.0, 0.8, 0.6, 0.4, 0.2};
var float g_yapbHeadshot[]  = {0.05, 0.30, 0.50, 0.75, 1.00};
var float g_yapbHearing[]   = {0.30, 0.50, 0.70, 0.90, 1.00};
var float g_yapbAimErrX[]   = {30.0, 15.0, 5.0, 0.0, 0.0};
var float g_yapbAimErrY[]   = {30.0, 15.0, 5.0, 0.0, 0.0};
var float g_yapbAimErrZ[]   = {40.0, 24.0, 10.0, 0.0, 0.0};
var float g_yapbSeenThru[]  = {0.00, 0.10, 0.30, 0.60, 0.90};
var float g_yapbHearThru[]  = {0.00, 0.10, 0.40, 0.70, 0.90};
var float g_yapbMaxRecoil[] = {0.38, 0.32, 0.26, 0.23, 0.21};

/* Weapon preferences per personality: primary weapons in priority order */
var int g_yapbWeapPrefNormal[] = {
	WEAPON_AK47, WEAPON_M4A1, WEAPON_MP5, WEAPON_P90, WEAPON_AUG,
	WEAPON_SG552, WEAPON_SCOUT, WEAPON_UMP45, WEAPON_M3, WEAPON_MAC10,
	WEAPON_TMP, WEAPON_XM1014
};
var int g_yapbWeapPrefRusher[] = {
	WEAPON_P90, WEAPON_MP5, WEAPON_AK47, WEAPON_M4A1, WEAPON_MAC10,
	WEAPON_UMP45, WEAPON_SG552, WEAPON_AUG, WEAPON_TMP, WEAPON_M3,
	WEAPON_XM1014, WEAPON_SCOUT
};
var int g_yapbWeapPrefCareful[] = {
	WEAPON_AWP, WEAPON_SCOUT, WEAPON_AUG, WEAPON_SG552, WEAPON_M4A1,
	WEAPON_AK47, WEAPON_SG550, WEAPON_G3SG1, WEAPON_MP5, WEAPON_P90,
	WEAPON_UMP45, WEAPON_M3
};

/* Team coordination globals */
var entity g_yapbLeaderT;
var entity g_yapbLeaderCT;
var int g_yapbLastWinnerTeam;
var int g_yapbPrevRoundsWonT;
var int g_yapbPrevRoundsWonCT;

/* ============================================================
 * Routing helpers (unchanged from original)
 * ============================================================ */

void
csbot::RunToConfront(void)
{
	entity t;
	if (team == TEAM_T)
		t = Route_SelectRandom("info_player_start");
	else
		t = Route_SelectRandom("info_player_deathmatch");

	if (t)
		RouteToPosition(t.origin);
}

void
csbot::RunToBomb(void)
{
	entity e = find(world, ::model, "models/w_c4.mdl");
	if (e)
		RouteToPosition(e.origin);
}

void
csbot::RunToBombsite(int bombsiteIndex)
{
	entity e = GetBombsiteByIndex(bombsiteIndex);
	RouteToPosition(getEntityCenterPos(e));
}

void
csbot::RunToRandomBombsite(void)
{
	RunToBombsite(random(0, g_cs_bombzones));
}

void
csbot::RunToEscapeZone(int index)
{
	entity e = GetEscapeZoneByIndex(index);
	RouteToPosition(getEntityCenterPos(e));
}

void
csbot::RunToRandomEscapeZone(void)
{
	RunToEscapeZone(random(0, g_cs_escapezones));
}

void
csbot::RunToVIPSafetyZone(int index)
{
	entity e = GetVIPSafetyZoneByIndex(index);
	RouteToPosition(getEntityCenterPos(e));
}

void
csbot::RunToRandomVIPSafetyZone(void)
{
	RunToVIPSafetyZone(random(0, g_cs_vipzones));
}

void
csbot::RunToHostages(void)
{
	entity e = find(world, ::classname, "hostage_entity");
	if (e)
		RouteToPosition(e.origin);
}

void csbot::Roam(vector roamOrigin, int maxDistance) {
	int angle = random(0, 360);
	int distance = random(0, maxDistance);
	float radian = angle * 3.145238095238 / 180;
	vector randLoc = roamOrigin;
	randLoc.x += sin(radian) * distance;
	randLoc.y += cos(radian) * distance;

	float flBestDist = COST_INFINITE;
	int iBestNodeIndex = -1;
	for (int i = 0; i < g_iNodes; i++) {
		float fDist = vlen(g_pNodes[i].origin - randLoc) - g_pNodes[i].radius;
		if (fDist > (float)maxDistance)
			continue;
		if (fDist < flBestDist) {
			flBestDist = fDist;
			iBestNodeIndex = i;
		}
	}

	if (iBestNodeIndex == -1)
		return;

	RouteToPosition(g_pNodes[iBestNodeIndex].origin);
}

/* ============================================================
 * Entity helpers (unchanged)
 * ============================================================ */

entity
csbot::GetEntityByNameAndIndex(string name, int index)
{
	int curIndex = 0;
	for (entity a = world; (a = find(a, ::classname, name));) {
		if (curIndex == index)
			return a;
		++curIndex;
	}
	return world;
}

entity csbot::GetBombsiteByIndex(int index) {
	return GetEntityByNameAndIndex("func_bomb_target", index);
}
entity csbot::GetEscapeZoneByIndex(int index) {
	return GetEntityByNameAndIndex("func_escapezone", index);
}
entity csbot::GetVIPSafetyZoneByIndex(int index) {
	return GetEntityByNameAndIndex("func_vip_safetyzone", index);
}

void csbot::AimLerp(vector aimpos, float flLerp) {
	vector aimdir, vecNewAngles;
	vector oldAngle = v_angle;
	makevectors(v_angle);
	vecNewAngles = v_forward;
	aimdir = vectoangles(aimpos - origin);
	makevectors(aimdir);
	vecNewAngles[0] = Math_Lerp(vecNewAngles[0], v_forward[0], flLerp);
	vecNewAngles[1] = Math_Lerp(vecNewAngles[1], v_forward[1], flLerp);
	vecNewAngles[2] = Math_Lerp(vecNewAngles[2], v_forward[2], flLerp);
	v_angle = vectoangles(vecNewAngles);
	v_angle[0] = Math_FixDelta(v_angle[0]);
	v_angle[1] = Math_FixDelta(v_angle[1]);
	v_angle[2] = Math_FixDelta(v_angle[2]);
	angles[0] = Math_FixDelta(v_angle[0]);
	angles[1] = Math_FixDelta(v_angle[1]);
	angles[2] = Math_FixDelta(v_angle[2]);
	input_angles = v_angle;
}

/* ============================================================
 * Constructor / PostFrame
 * ============================================================ */

void
csbot::csbot(void)
{
	targetname = "_csbot_";
	team = infokeyf(this, "*team");
	m_actionIsPlanting = FALSE;
	m_actionIsDefusing = FALSE;
	m_gflagsBackup = 0;
}

void
csbot::PostFrame(void)
{
	if (team == 0)
		CSEv_JoinAuto();

	team = infokeyf(this, "*team");
	m_gflagsBackup = gflags;
}

/* ============================================================
 * YaPB Init
 * ============================================================ */

void
csbot::YaPB_Init(void)
{
	m_yapbPersonality = (int)floor(random(0, 3));
	m_yapbDifficulty = bound(0, (int)cvar("bot_skill"), 4);
	switch (m_yapbPersonality) {
	case YAPB_PERS_RUSHER:
		m_yapbBaseAggression = 0.7; m_yapbBaseFear = 0.1; break;
	case YAPB_PERS_CAREFUL:
		m_yapbBaseAggression = 0.2; m_yapbBaseFear = 0.6; break;
	default:
		m_yapbBaseAggression = 0.4; m_yapbBaseFear = 0.3; break;
	}
	m_yapbAggression = m_yapbBaseAggression;
	m_yapbFear = m_yapbBaseFear;
	m_yapbShootTime = 0;
	m_yapbSeeTime = 0;
	m_yapbHeardTime = 0;
	m_yapbStuckTime = 0;
	m_yapbStuckCount = 0;
	m_yapbCampEnd = 0;
	m_yapbLookYawVel = 0;
	m_yapbLookPitchVel = 0;
	m_yapbTaskCount = 0;
	m_yapbWeaponCheckTime = 0;
	m_yapbBuyState = 0;
	m_yapbEconomyOk = TRUE;
	m_yapbNadeCheckTime = 0;
	m_yapbNadeType = 0;
	m_yapbRadioTime = 0;
	m_yapbRadioRoundSpot = FALSE;
	m_yapbDoorRetries = 0;
	m_yapbDoorWaitTime = 0;
	m_yapbLastEnemySeen = 0;
	m_yapbInitialized = true;
}

/* ============================================================
 * TASK SYSTEM — priority-sorted stack
 * ============================================================ */

void
csbot::YaPB_TaskPush(int type, vector data, float duration)
{
	float pri = g_yapbTaskPri[type];

	for (int i = 0; i < m_yapbTaskCount; i++) {
		if (m_yapbTaskStack[i] == type)
			return;
	}

	if (m_yapbTaskCount >= YAPB_TASKSTACK_MAX) {
		if (pri <= g_yapbTaskPri[m_yapbTaskStack[m_yapbTaskCount - 1]])
			return;
		m_yapbTaskCount--;
	}

	int slot = m_yapbTaskCount;
	for (int i = 0; i < m_yapbTaskCount; i++) {
		if (pri > g_yapbTaskPri[m_yapbTaskStack[i]]) {
			for (int j = m_yapbTaskCount; j > i; j--) {
				m_yapbTaskStack[j] = m_yapbTaskStack[j - 1];
				m_yapbTaskTime[j] = m_yapbTaskTime[j - 1];
				m_yapbTaskData[j] = m_yapbTaskData[j - 1];
			}
			slot = i;
			break;
		}
	}

	m_yapbTaskStack[slot] = type;
	m_yapbTaskTime[slot] = (duration > 0) ? time + duration : 0;
	m_yapbTaskData[slot] = data;
	m_yapbTaskCount++;
}

void
csbot::YaPB_TaskPop(void)
{
	if (m_yapbTaskCount <= 0)
		return;
	for (int i = 0; i < m_yapbTaskCount - 1; i++) {
		m_yapbTaskStack[i] = m_yapbTaskStack[i + 1];
		m_yapbTaskTime[i] = m_yapbTaskTime[i + 1];
		m_yapbTaskData[i] = m_yapbTaskData[i + 1];
	}
	m_yapbTaskCount--;
}

void
csbot::YaPB_TaskClear(void)
{
	m_yapbTaskCount = 0;
}

int
csbot::YaPB_TaskGetType(void)
{
	if (m_yapbTaskCount <= 0)
		return YAPB_TASK_NORMAL;
	return m_yapbTaskStack[0];
}

/* ============================================================
 * TASK FILTER — per-frame brain
 * ============================================================ */

void
csbot::YaPB_TaskFilter(void)
{
	int curTask = YaPB_TaskGetType();

	if (m_yapbTaskCount > 0 && m_yapbTaskTime[0] > 0 && time > m_yapbTaskTime[0])
		YaPB_TaskPop();

	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		m_yapbLastEnemyOrigin = m_eTarget.origin;
		m_yapbLastEnemySeen = time;
		if (curTask != YAPB_TASK_ATTACK && curTask != YAPB_TASK_THROWHE &&
		    curTask != YAPB_TASK_THROWFB && curTask != YAPB_TASK_THROWSM &&
		    curTask != YAPB_TASK_BLIND) {
			YaPB_TaskPush(YAPB_TASK_ATTACK, m_eTarget.origin, 0);
		}
	} else {
		if (curTask == YAPB_TASK_ATTACK)
			YaPB_TaskPop();

		if (m_yapbLastEnemySeen > 0 && (time - m_yapbLastEnemySeen) < 5.0) {
			if (curTask != YAPB_TASK_HUNT && curTask != YAPB_TASK_SEEKCOVER &&
			    curTask != YAPB_TASK_HIDE && curTask != YAPB_TASK_CAMP) {
				float huntChance = m_yapbAggression;
				if (random() < huntChance)
					YaPB_TaskPush(YAPB_TASK_HUNT, m_yapbLastEnemyOrigin, 10.0);
			}
		}
	}

	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		float hpRatio = health / 100.0;
		if (hpRatio < 0.3 && m_yapbFear > 0.5 && curTask != YAPB_TASK_SEEKCOVER &&
		    curTask != YAPB_TASK_HIDE) {
			YaPB_TaskPush(YAPB_TASK_SEEKCOVER, m_yapbLastEnemyOrigin, 8.0);
		}
	}

	if (g_cs_bombplanted) {
		entity eBomb = find(world, ::model, "models/w_c4.mdl");
		if (eBomb != world) {
			if (team == TEAM_CT && curTask != YAPB_TASK_DEFUSE) {
				YaPB_TaskPush(YAPB_TASK_DEFUSE, eBomb.origin, 0);
			}
			float bombDist = vlen(eBomb.origin - origin);
			if (team == TEAM_T && bombDist < 1200) {
				/* nothing — T roams near bomb via normal task */
			}
		}
	}

	if (team == TEAM_T && (g_items & ITEM_C4BOMB) && !g_cs_bombplanted) {
		if (m_gflagsBackup & GF_BOMBZONE) {
			if (curTask != YAPB_TASK_PLANT)
				YaPB_TaskPush(YAPB_TASK_PLANT, origin, 0);
		}
	}

	YaPB_CheckGrenadeThrow();
}

/* ============================================================
 * TASK EXECUTE — dispatch to handlers
 * ============================================================ */

void
csbot::YaPB_TaskExecute(void)
{
	int task = YaPB_TaskGetType();
	switch (task) {
	case YAPB_TASK_NORMAL:    YaPB_TaskNormal(); break;
	case YAPB_TASK_ATTACK:    YaPB_TaskAttack(); break;
	case YAPB_TASK_HUNT:      YaPB_TaskHunt(); break;
	case YAPB_TASK_SEEKCOVER: YaPB_TaskSeekCover(); break;
	case YAPB_TASK_HIDE:      YaPB_TaskHide(); break;
	case YAPB_TASK_PLANT:     YaPB_TaskPlant(); break;
	case YAPB_TASK_DEFUSE:    YaPB_TaskDefuse(); break;
	case YAPB_TASK_CAMP:      YaPB_TaskCamp(); break;
	case YAPB_TASK_ESCAPEBOMB: YaPB_TaskEscapeBomb(); break;
	case YAPB_TASK_BLIND:     YaPB_TaskBlind(); break;
	case YAPB_TASK_THROWHE:
	case YAPB_TASK_THROWFB:
	case YAPB_TASK_THROWSM:   YaPB_TaskThrowGrenade(); break;
	case YAPB_TASK_FOLLOW:
		if (m_yapbTaskCount > 0) {
			entity leader = (team == TEAM_T) ? g_yapbLeaderT : g_yapbLeaderCT;
			if (leader != world && leader.health > 0)
				RouteToPosition(leader.origin);
			else
				YaPB_TaskPop();
		}
		break;
	default:
		YaPB_TaskNormal();
		break;
	}
}

/* ============================================================
 * TASK HANDLERS
 * ============================================================ */

void
csbot::YaPB_TaskNormal(void)
{
	/* YaPB tasks.cpp:18-313 normal_() */

	/* reload if clip low and not in combat */
	if (a_ammo1 < 5 && a_ammo2 > 0 && m_eTarget == __NULL__) {
		input_buttons |= INPUT_BUTTON4;
	}

	/* walk if heard enemy recently (creep speed) */
	if (m_yapbHeardTime > 0 && (time - m_yapbHeardTime) < 3.0) {
		input_movevalues[0] = GetRunSpeed() * 0.4;
	}

	CreateObjective();

	/* if reached goal (no route), radio + camp chance */
	if (m_iNodes <= 0 && m_eTarget == __NULL__) {
		if (random() < 0.15)
			YaPB_Radio(RADIO_CLEAR);
	}
}

void
csbot::YaPB_TaskAttack(void)
{
	if (m_eTarget == __NULL__ || m_eTarget.health <= 0) {
		/* enemy killed �� radio event */
		if (random() < 0.4)
			YaPB_Radio(RADIO_ENEMYDOWN);
		YaPB_TaskPop();
		return;
	}

	/* YaPB attackMovement: sniper approach cap */
	float approach = health * m_yapbAggression * 0.01;
	bool isSniper = (activeweapon == WEAPON_AWP || activeweapon == WEAPON_SCOUT ||
	                 activeweapon == WEAPON_G3SG1 || activeweapon == WEAPON_SG550);
	if (isSniper && approach > 49)
		approach = 49;

	/* seek cover if health/armor low */
	if (health < 25 || (health < 40 && m_yapbFear > 0.5)) {
		if (YaPB_TaskGetType() != YAPB_TASK_SEEKCOVER)
			YaPB_TaskPush(YAPB_TASK_SEEKCOVER, m_yapbLastEnemyOrigin, 8.0);
	}

	YaPB_CombatThink();
}

void
csbot::YaPB_TaskHunt(void)
{
	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		YaPB_TaskPop();
		YaPB_TaskPush(YAPB_TASK_ATTACK, m_eTarget.origin, 0);
		return;
	}

	vector huntPos = (m_yapbTaskCount > 0) ? m_yapbTaskData[0] : m_yapbLastEnemyOrigin;
	float dist = vlen(huntPos - origin);

	if (dist < 80) {
		YaPB_TaskPop();
		return;
	}

	if (m_iNodes <= 0)
		RouteToPosition(huntPos);

	/* YaPB: creep speed at Normal+ in narrow areas */
	if (m_yapbDifficulty >= YAPB_DIFF_NORMAL)
		input_movevalues[0] = GetRunSpeed() * 0.7;
	else
		input_movevalues[0] = GetRunSpeed() * 0.5;
}

void
csbot::YaPB_TaskSeekCover(void)
{
	/* YaPB tasks.cpp:419-505 — graph-based cover finding */
	if (m_iNodes <= 0) {
		/* find cover node: iterate waypoints for one with no LOS to enemy */
		float bestDist = COST_INFINITE;
		int bestNode = -1;
		vector enemyPos = m_yapbLastEnemyOrigin;

		for (int i = 0; i < g_iNodes; i++) {
			vector nodePos = g_pNodes[i].origin;
			float nodeDist = vlen(nodePos - origin);
			float enemyDist = vlen(nodePos - enemyPos);

			if (nodeDist > 1024 || enemyDist < 300)
				continue;

			/* check no LOS from node to enemy */
			traceline(nodePos + [0, 0, 36], enemyPos, MOVE_NORMAL, this);
			if (trace_fraction < 0.98) {
				if (nodeDist < bestDist) {
					bestDist = nodeDist;
					bestNode = i;
				}
			}
		}

		if (bestNode >= 0)
			RouteToPosition(g_pNodes[bestNode].origin);
		else {
			/* fallback: run away from enemy */
			vector awayDir = normalize(origin - enemyPos);
			Roam(origin + awayDir * 500, 300);
		}
	}

	if (m_iNodes <= 0) {
		YaPB_TaskPop();
		YaPB_TaskPush(YAPB_TASK_HIDE, origin, random(3, 12));
		return;
	}

	input_movevalues[0] = GetRunSpeed();
}

void
csbot::YaPB_TaskHide(void)
{
	input_movevalues = [0, 0, 0];
	input_buttons |= INPUT_BUTTON8;

	/* reload while hiding (YaPB tasks.cpp:715-780) */
	if (a_ammo1 < 5 && a_ammo2 > 0 && m_eTarget == __NULL__) {
		input_buttons |= INPUT_BUTTON4;
	}

	/* delay reaction — don't instantly pop on enemy appearance */
	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		YaPB_TaskPop();
		return;
	}
}

void
csbot::YaPB_TaskPlant(void)
{
	if (!(g_items & ITEM_C4BOMB)) {
		m_actionIsPlanting = FALSE;
		YaPB_TaskPop();
		return;
	}

	if (!(m_gflagsBackup & GF_BOMBZONE)) {
		if (g_cs_bombzones > 0)
			RunToRandomBombsite();
		YaPB_TaskPop();
		return;
	}

	if (activeweapon != WEAPON_C4BOMB) {
		activeweapon = WEAPON_C4BOMB;
		Weapons_Draw((player)self);
	}

	if (!m_actionIsPlanting) {
		YaPB_Radio(RADIO_COM_GO);
		m_actionIsPlanting = TRUE;
	}

	gflags = m_gflagsBackup;
	input_buttons = (INPUT_BUTTON0 | INPUT_BUTTON8);
	input_movevalues = [0, 0, 0];
}

void
csbot::YaPB_TaskDefuse(void)
{
	entity eBomb = find(world, ::model, "models/w_c4.mdl");
	if (eBomb == world || !g_cs_bombplanted) {
		m_actionIsDefusing = FALSE;
		YaPB_TaskPop();
		return;
	}

	if (team != TEAM_CT) {
		YaPB_TaskPop();
		return;
	}

	if (g_cs_bombbeingdefused && !m_actionIsDefusing) {
		Roam(eBomb.origin, 300);
		YaPB_TaskPop();
		return;
	}

	if (m_actionIsDefusing) {
		if (!g_cs_bombbeingdefused) {
			m_actionIsDefusing = FALSE;
			YaPB_TaskPop();
		} else {
			input_buttons |= (INPUT_BUTTON5 | INPUT_BUTTON8);
			input_movevalues = [0, 0, 0];
			button5 = input_buttons & INPUT_BUTTON5;
		}
		return;
	}

	int distToBomb = floor(vlen(eBomb.origin - origin));
	if (distToBomb > 60) {
		RunToBomb();
	} else {
		input_buttons |= INPUT_BUTTON8;
		if (flags & FL_ONUSABLE) {
			YaPB_Radio(RADIO_BOMBDEF);
			input_buttons |= INPUT_BUTTON5;
			input_movevalues = [0, 0, 0];
			button5 = input_buttons & INPUT_BUTTON5;
			m_actionIsDefusing = TRUE;
		} else {
			float flLerp = bound(0.0f, frametime * 45, 1.0f);
			AimLerp(eBomb.origin + [0, 0, -6], flLerp);
		}
	}
}

void
csbot::YaPB_TaskCamp(void)
{
	/* YaPB tasks.cpp:623-713 camp_() */
	input_movevalues = [0, 0, 0];
	input_buttons |= INPUT_BUTTON8;

	/* halve reaction time while camping */
	m_yapbSeeTime = min(m_yapbSeeTime, time + 0.1);

	/* select best weapon for defense */
	YaPB_SelectBestWeapon();

	/* reload if safe */
	if (a_ammo1 < 5 && a_ammo2 > 0 && m_eTarget == __NULL__)
		input_buttons |= INPUT_BUTTON4;

	if (time > m_yapbCampLookSwitch) {
		m_yapbCampLookSwitch = time + random(1, 4);
		vector lookDir;
		if ((int)floor(time) & 1)
			lookDir = m_yapbCampLookA;
		else
			lookDir = m_yapbCampLookB;

		/* wall detection: don't look into walls */
		vector aimPos = origin + lookDir * 200;
		traceline(origin + view_ofs, aimPos, MOVE_NORMAL, this);
		if (trace_fraction < 0.5)
			aimPos = origin + m_yapbCampLookB * 200;

		float flLerp = bound(0.0f, frametime * 20, 1.0f);
		AimLerp(aimPos, flLerp);
	}

	/* radio: in position */
	if (time < m_yapbCampEnd - 14 && random() < 0.01)
		YaPB_Radio(RADIO_CT_INPOS);

	if (health < m_yapbCampHealth) {
		YaPB_TaskPop();
		return;
	}

	if (g_cs_bombplanted && team == TEAM_T) {
		YaPB_TaskPop();
		return;
	}
}

void
csbot::YaPB_TaskEscapeBomb(void)
{
	entity eBomb = find(world, ::model, "models/w_c4.mdl");
	if (eBomb == world) {
		YaPB_TaskPop();
		return;
	}

	vector awayDir = normalize(origin - eBomb.origin);
	vector escapePos = origin + awayDir * 1500;

	if (m_iNodes <= 0)
		Roam(escapePos, 500);

	input_movevalues[0] = GetRunSpeed();
}

void
csbot::YaPB_TaskBlind(void)
{
	/* YaPB tasks.cpp:565-621 blind_() */
	if (time > m_yapbBlindEnd) {
		YaPB_TaskPop();
		return;
	}

	input_movevalues[0] = GetRunSpeed() * 0.5 * (random() < 0.5 ? 1 : -1);
	input_movevalues[1] = GetRunSpeed() * 0.3 * (random() < 0.5 ? 1 : -1);

	/* fire at last enemy with error */
	if (m_yapbDifficulty >= YAPB_DIFF_NORMAL && m_yapbLastEnemySeen > 0) {
		if (random() < 0.5) {
			input_buttons |= INPUT_BUTTON0;
			/* aim toward last enemy with large error */
			float dist = vlen(m_yapbLastEnemyOrigin - origin);
			float errScale = dist * 0.1;
			vector blindAim = m_yapbLastEnemyOrigin;
			blindAim += [crandom() * errScale, crandom() * errScale, 0];
			vector blindAng = vectoangles(blindAim - origin);
			input_angles = v_angle = angles = blindAng;
		}
	}

	/* node-based movement for Hard+ */
	if (m_yapbDifficulty >= YAPB_DIFF_HARD && m_iNodes <= 0) {
		float bestDist = COST_INFINITE;
		int bestNode = -1;
		for (int i = 0; i < g_iNodes && i < 100; i++) {
			float d = vlen(g_pNodes[i].origin - origin);
			if (d > 50 && d < 500 && d < bestDist) {
				bestDist = d;
				bestNode = i;
			}
		}
		if (bestNode >= 0)
			RouteToPosition(g_pNodes[bestNode].origin);
	}

	if (random() < 0.2)
		input_buttons |= INPUT_BUTTON8;
}

/* ============================================================
 * GRENADE SYSTEM
 * ============================================================ */

int
csbot::YaPB_BestGrenade(void)
{
	player pl = (player)self;
	if (pl.g_items & ITEM_HEGRENADE) return WEAPON_HEGRENADE;
	if (pl.g_items & ITEM_FLASHBANG) return WEAPON_FLASHBANG;
	if (pl.g_items & ITEM_SMOKEGRENADE) return WEAPON_SMOKEGRENADE;
	return 0;
}

void
csbot::YaPB_CheckGrenadeThrow(void)
{
	if (time < m_yapbNadeCheckTime)
		return;
	m_yapbNadeCheckTime = time + 0.6;

	if (m_eTarget == __NULL__ || m_eTarget.health <= 0)
		return;

	int curTask = YaPB_TaskGetType();
	if (curTask == YAPB_TASK_THROWHE || curTask == YAPB_TASK_THROWFB ||
	    curTask == YAPB_TASK_THROWSM || curTask == YAPB_TASK_PLANT ||
	    curTask == YAPB_TASK_DEFUSE)
		return;

	float dist = vlen(m_eTarget.origin - origin);
	float throwChance = 0.25 * m_yapbDifficulty;

	if (random() > throwChance)
		return;

	player pl = (player)self;

	if ((pl.g_items & ITEM_HEGRENADE) && dist > 300 && dist < 900) {
		for (entity e = world; (e = find(e, ::classname, "player"));) {
			if (e == this || e.health <= 0) continue;
			if (e.team == this.team && vlen(e.origin - m_eTarget.origin) < 256)
				return;
		}
		m_yapbNadeType = WEAPON_HEGRENADE;
		m_yapbNadeTarget = m_eTarget.origin + [0, 0, 110];
		m_yapbNadeThrowTime = time + 1.0;
		YaPB_TaskPush(YAPB_TASK_THROWHE, m_yapbNadeTarget, 3.0);
		return;
	}

	if ((pl.g_items & ITEM_FLASHBANG) && dist > 400 && dist < 1200 && random() < 0.6) {
		m_yapbNadeType = WEAPON_FLASHBANG;
		m_yapbNadeTarget = m_eTarget.origin + m_eTarget.velocity * 0.5 + [0, 0, 110];
		m_yapbNadeThrowTime = time + 1.0;
		YaPB_TaskPush(YAPB_TASK_THROWFB, m_yapbNadeTarget, 3.0);
		return;
	}

	if ((pl.g_items & ITEM_SMOKEGRENADE) && dist > 500 && dist < 1500) {
		makevectors(m_eTarget.v_angle);
		vector edir = normalize(origin - m_eTarget.origin);
		if (edir * v_forward < 0.9) {
			m_yapbNadeType = WEAPON_SMOKEGRENADE;
			m_yapbNadeTarget = m_eTarget.origin + [0, 0, 80];
			m_yapbNadeThrowTime = time + 1.0;
			YaPB_TaskPush(YAPB_TASK_THROWSM, m_yapbNadeTarget, 3.0);
		}
	}
}

void
csbot::YaPB_TaskThrowGrenade(void)
{
	if (m_yapbNadeType == 0) {
		YaPB_TaskPop();
		return;
	}

	if (activeweapon != m_yapbNadeType) {
		activeweapon = m_yapbNadeType;
		Weapons_Draw((player)self);
		return;
	}

	input_movevalues = [0, 0, 0];

	vector throwDir = m_yapbNadeTarget - origin;
	float throwDist = vlen(throwDir);
	float pitchUp = -10 - (throwDist / 100);
	if (pitchUp < -45) pitchUp = -45;

	vector throwAng = vectoangles(throwDir);
	throwAng[0] = pitchUp;
	input_angles = v_angle = angles = throwAng;

	if (time >= m_yapbNadeThrowTime) {
		input_buttons |= INPUT_BUTTON0;

		if (time >= m_yapbNadeThrowTime + 0.3) {
			m_yapbNadeType = 0;
			YaPB_TaskPop();
			YaPB_SelectBestWeapon();
		}
	}
}

/* ============================================================
 * WEAPON SELECTION
 * ============================================================ */

int
csbot::YaPB_GetWeaponAmmo(int weap)
{
	player pl = (player)self;
	switch (weap) {
	case WEAPON_AK47:
	case WEAPON_SG552:     return pl.ammo_762mm;
	case WEAPON_M4A1:
	case WEAPON_AUG:
	case WEAPON_SG550:
	case WEAPON_SCOUT:     return pl.ammo_556mm;
	case WEAPON_AWP:
	case WEAPON_G3SG1:     return pl.ammo_338mag;
	case WEAPON_MP5:
	case WEAPON_TMP:
	case WEAPON_MAC10:
	case WEAPON_GLOCK18:   return pl.ammo_9mm;
	case WEAPON_P90:
	case WEAPON_FIVESEVEN: return pl.ammo_57mm;
	case WEAPON_UMP45:
	case WEAPON_USP45:     return pl.ammo_45acp;
	case WEAPON_DEAGLE:    return pl.ammo_50ae;
	case WEAPON_P228:
	case WEAPON_ELITES:    return pl.ammo_357sig;
	case WEAPON_M3:
	case WEAPON_XM1014:    return pl.ammo_buckshot;
	case WEAPON_PARA:      return pl.ammo_556mmbox;
	case WEAPON_KNIFE:     return 999;
	}
	return 0;
}

bool
csbot::YaPB_IsWeaponBadAtDist(int weap, float dist)
{
	if (weap == WEAPON_AWP || weap == WEAPON_SCOUT ||
	    weap == WEAPON_G3SG1 || weap == WEAPON_SG550) {
		if (dist < 400)
			return true;
	}
	if (weap == WEAPON_M3 || weap == WEAPON_XM1014) {
		if (dist > 750)
			return true;
	}
	return false;
}

void
csbot::YaPB_SelectBestWeapon(void)
{
	if (time < m_yapbWeaponCheckTime)
		return;
	m_yapbWeaponCheckTime = time + 1.5;

	player pl = (player)self;
	float dist = (m_eTarget != __NULL__) ? m_flEnemyDist : 500;

	if (m_yapbDifficulty >= YAPB_DIFF_HARD && dist < 100 && health > 80 &&
	    (pl.g_items & ITEM_KNIFE)) {
		if (activeweapon != WEAPON_KNIFE) {
			activeweapon = WEAPON_KNIFE;
			Weapons_Draw(pl);
		}
		return;
	}

	int bestWeap = WEAPON_KNIFE;
	int bestWeight = -1;

	for (int i = 0; i < g_weapons.length; i++) {
		if (!(pl.g_items & g_weapons[i].id))
			continue;
		if (i == WEAPON_C4BOMB || i == WEAPON_KNIFE)
			continue;
		if (i == WEAPON_HEGRENADE || i == WEAPON_FLASHBANG || i == WEAPON_SMOKEGRENADE)
			continue;
		if (YaPB_IsWeaponBadAtDist(i, dist))
			continue;
		if (YaPB_GetWeaponAmmo(i) <= 0 && a_ammo1 <= 0)
			continue;

		int w = g_weapons[i].weight;
		if (g_weapons[i].slot == 0)
			w += 50;

		if (w > bestWeight) {
			bestWeight = w;
			bestWeap = i;
		}
	}

	if (bestWeap != activeweapon && bestWeap != WEAPON_KNIFE) {
		activeweapon = bestWeap;
		Weapons_Draw(pl);
	}
}

/* ============================================================
 * WeaponThink — enhanced with weapon selection
 * ============================================================ */

void
csbot::WeaponThink(void)
{
	if (m_actionIsPlanting || m_actionIsDefusing)
		return;

	int curTask = YaPB_TaskGetType();
	if (curTask == YAPB_TASK_THROWHE || curTask == YAPB_TASK_THROWFB ||
	    curTask == YAPB_TASK_THROWSM)
		return;

	YaPB_SelectBestWeapon();

	if (activeweapon == WEAPON_KNIFE)
		return;

	if (a_ammo1 == 0) {
		if (a_ammo2 != 0) {
			input_buttons &= ~INPUT_BUTTON0;
			input_buttons |= INPUT_BUTTON4;
		} else {
			Weapons_SwitchBest(this);
		}
	}
}

/* ============================================================
 * RADIO SYSTEM
 * ============================================================ */

void
csbot::YaPB_Radio(float msg)
{
	if (time < m_yapbRadioTime)
		return;
	m_yapbRadioTime = time + 3.0;

	float personalityScale = 0.5;
	switch (m_yapbPersonality) {
	case YAPB_PERS_CAREFUL: personalityScale = 0.7; break;
	case YAPB_PERS_RUSHER:  personalityScale = 0.3; break;
	}

	if (random() > personalityScale)
		return;

	float fTeam = this.team;
	if (fTeam == TEAM_VIP) fTeam = TEAM_CT;
	Radio_TeamMessage(msg, fTeam);
}

void
csbot::YaPB_RadioThink(void)
{
	if (time < m_yapbRadioTime)
		return;
	if (health <= 0)
		return;
	if (g_cs_gamestate != GAME_ACTIVE)
		return;

	/* enemy spotted (once per round) */
	if (m_eTarget != __NULL__ && m_eTarget.health > 0 && !m_yapbRadioRoundSpot) {
		m_yapbRadioRoundSpot = TRUE;
		if (random() < 0.5)
			YaPB_Radio(RADIO_CT_ENEMYS);
	}

	/* taking damage / need backup */
	if (health < 50 && m_eTarget != __NULL__ && random() < 0.2)
		YaPB_Radio(RADIO_CT_IMHIT);
	if (health < 30 && m_eTarget != __NULL__ && random() < 0.3)
		YaPB_Radio(RADIO_CT_BACKUP);

	/* retreating */
	int curTask = YaPB_TaskGetType();
	if (curTask == YAPB_TASK_SEEKCOVER && random() < 0.2)
		YaPB_Radio(RADIO_FALLBACK);

	/* check for dead teammates nearby */
	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == this || e.team != this.team) continue;
		if (e.health <= 0 && vlen(e.origin - origin) < 600) {
			if (random() < 0.35)
				YaPB_Radio(RADIO_MATEDOWN);
			break;
		}
	}
}

/* ============================================================
 * NAVIGATION HELPERS
 * ============================================================ */

void
csbot::YaPB_LadderThink(void)
{
	entity e;
	for (e = findradius(origin, 128); e; e = e.chain) {
		if (e.classname == "func_ladder") {
			if (m_iNodes > 0 && m_iCurNode >= 0) {
				vector dest = m_pRoute[m_iCurNode].dest;
				if (dest[2] > origin[2] + 16) {
					input_movevalues[0] = GetRunSpeed();
					v_angle[0] = -60;
					input_angles = v_angle;
				} else if (dest[2] < origin[2] - 16) {
					input_movevalues[0] = GetRunSpeed();
					v_angle[0] = 60;
					input_angles = v_angle;
				}
			}
			return;
		}
	}
}

void
csbot::YaPB_DoorThink(void)
{
	entity e;
	for (e = findradius(origin, 128); e; e = e.chain) {
		if (e.classname == "func_door" || e.classname == "func_door_rotating") {
			if (time < m_yapbDoorWaitTime)
				return;

			input_buttons |= INPUT_BUTTON5;
			m_yapbDoorRetries++;
			m_yapbDoorWaitTime = time + 1.0;

			if (m_yapbDoorRetries > 5) {
				RouteClear();
				m_yapbDoorRetries = 0;
				m_yapbStuckCount = 0;
			}
			return;
		}
	}
}

/* ============================================================
 * YaPB_StuckCheck — enhanced with navigation helpers
 * ============================================================ */

void
csbot::YaPB_StuckCheck(void)
{
	if (time < m_yapbStuckTime) return;
	m_yapbStuckTime = time + 0.5;

	float speed = vlen(origin - m_yapbPrevOrigin);
	m_yapbPrevOrigin = origin;

	if (speed < 10.0 && vlen(input_movevalues) > 50.0) {
		m_yapbStuckCount++;
		if (m_yapbStuckCount > 2) {
			YaPB_LadderThink();
			YaPB_DoorThink();
		}
		if (m_yapbStuckCount > 4) input_buttons |= INPUT_BUTTON2;
		if (m_yapbStuckCount > 8) input_buttons |= INPUT_BUTTON8;
		if (m_yapbStuckCount > 12)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * GetRunSpeed();
		if (m_yapbStuckCount > 18) {
			RouteClear();
			m_yapbStuckCount = 0;
			m_yapbDoorRetries = 0;
		}
	} else {
		m_yapbStuckCount = 0;
		m_yapbDoorRetries = 0;
	}
}

/* ============================================================
 * FOV / Sound Awareness / Aiming / Combat (from original YaPB port)
 * ============================================================ */

bool
csbot::YaPB_IsInFOV(entity ent, float fov)
{
	makevectors(v_angle);
	vector dir = normalize(ent.origin - origin);
	float dot = dir * v_forward;
	return (dot >= cos((fov * 0.5) * (M_PI / 180.0)));
}

void
csbot::YaPB_SoundAwareness(void)
{
	int diff = m_yapbDifficulty;
	float hearChance = g_yapbHearing[diff];

	if (random() > hearChance)
		return;

	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == this || e.team == this.team || e.health <= 0)
			continue;
		float dist = vlen(e.origin - origin);

		traceline(origin, e.origin, MOVE_NORMAL, this);
		bool lineOfSight = (trace_fraction >= 0.98);

		if (!lineOfSight && random() > g_yapbHearThru[diff])
			continue;

		if (e.button0 && dist < 900.0) {
			m_yapbHeardPos = e.origin;
			m_yapbHeardTime = time;
			if (m_eTarget == __NULL__)
				RouteToPosition(m_yapbHeardPos);
			return;
		}
		if (vlen(e.velocity) > 150.0 && dist < 500.0) {
			m_yapbHeardPos = e.origin;
			m_yapbHeardTime = time;
			return;
		}
	}
}

void
csbot::YaPB_AimThink(void)
{
	int diff = m_yapbDifficulty;
	float dt = frametime;
	if (dt <= 0) dt = 0.01;

	vector aimTarget;
	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		float dist = vlen(m_eTarget.origin - origin);
		vector spot = m_eTarget.origin;

		/* body-part based aiming (YaPB combat.cpp:681-750) */
		int parts = m_yapbEnemyParts;
		float hsChance = g_yapbHeadshot[diff];

		/* at long distance, no headshot (unless sniper) */
		float hsDistLimit = (diff >= YAPB_DIFF_NORMAL) ? 2000.0 : 1000.0;
		bool isSniper = (activeweapon == WEAPON_AWP || activeweapon == WEAPON_SCOUT ||
		                 activeweapon == WEAPON_G3SG1 || activeweapon == WEAPON_SG550);
		if ((parts & 2) && !isSniper && dist > hsDistLimit)
			parts &= ~1;
		/* close range with sniper — no headshot */
		if (dist < 800 && isSniper)
			parts &= ~1;

		if ((parts & 3) == 3) {
			/* head + body visible: use headshot chance */
			if (m_yapbAimPart == 1 && m_yapbAimPartEnt == m_eTarget) {
				/* sticky — keep aiming head */
				spot = m_eTarget.origin + [0, 0, m_eTarget.size[2] * 0.81];
			} else if (random() < hsChance) {
				spot = m_eTarget.origin + [0, 0, m_eTarget.size[2] * 0.81];
				m_yapbAimPart = 1;
				m_yapbAimPartEnt = m_eTarget;
			} else {
				spot = m_eTarget.origin;
				m_yapbAimPart = 2;
				m_yapbAimPartEnt = m_eTarget;
			}
		} else if (parts & 1) {
			/* only head visible */
			spot = m_eTarget.origin + [0, 0, m_eTarget.size[2] * 0.81];
		} else {
			/* only body or nothing — aim center mass */
			spot = m_eTarget.origin;
		}

		/* velocity compensation (YaPB combat.cpp:704-706) */
		if (!isSniper && activeweapon != WEAPON_KNIFE && dist > 272) {
			vector comp = (m_eTarget.velocity - velocity) * dt * 2.8;
			comp[2] = 0;
			spot += comp;
		}

		/* aim error (YaPB config.cpp: aimError x,y,z per difficulty) */
		spot[0] += crandom() * g_yapbAimErrX[diff];
		spot[1] += crandom() * g_yapbAimErrY[diff];
		spot[2] += crandom() * g_yapbAimErrZ[diff];

		aimTarget = spot;
	} else {
		m_yapbAimPart = 0;
		if (m_iNodes && m_iCurNode >= 0)
			aimTarget = m_pRoute[m_iCurNode].dest;
		else
			aimTarget = origin + v_forward * 128;
	}

	vector desiredAngles = vectoangles(aimTarget - (origin + view_ofs));
	if (desiredAngles[0] > 180) desiredAngles[0] -= 360;
	if (desiredAngles[1] > 180) desiredAngles[1] -= 360;

	vector curAngles = v_angle;
	if (curAngles[0] > 180) curAngles[0] -= 360;
	if (curAngles[1] > 180) curAngles[1] -= 360;

	/* YaPB vision.cpp:157-214 — spring-damper with fixed stiffness/damping */
	float stiffness = 200.0;
	float damping = 25.0;

	float yawOff = desiredAngles[1] - curAngles[1];
	while (yawOff > 180) yawOff -= 360;
	while (yawOff < -180) yawOff += 360;

	if (fabs(yawOff) < 1.0) {
		m_yapbLookYawVel = 0;
		curAngles[1] = desiredAngles[1];
	} else {
		float acc = bound(-3000, stiffness * yawOff - damping * m_yapbLookYawVel, 3000);
		m_yapbLookYawVel += dt * acc;
		curAngles[1] += dt * m_yapbLookYawVel;
	}

	float pitchOff = desiredAngles[0] - curAngles[0];
	while (pitchOff > 180) pitchOff -= 360;
	while (pitchOff < -180) pitchOff += 360;

	float accP = bound(-3000, 2.0 * stiffness * pitchOff - damping * m_yapbLookPitchVel, 3000);
	m_yapbLookPitchVel += dt * accP;
	curAngles[0] += dt * m_yapbLookPitchVel;
	curAngles[0] = bound(-89, curAngles[0], 89);

	input_angles = v_angle = angles = curAngles;
}

void
csbot::YaPB_CombatThink(void)
{
	if (m_eTarget == __NULL__ || m_eTarget.health <= 0)
		return;

	int diff = m_yapbDifficulty;
	float dist = m_flEnemyDist;

	if (time >= m_yapbShootTime) {
		makevectors(v_angle);
		vector dir = normalize(m_eTarget.origin - origin);
		float dot = dir * v_forward;

		float threshold;
		if (dist < 128)
			threshold = 0.80;
		else if (dist < 768)
			threshold = 0.90;
		else
			threshold = 0.95;

		if (dot >= threshold) {
			for (entity e = world; (e = find(e, ::classname, "player"));) {
				if (e == this || e.health <= 0 || e.team != this.team)
					continue;
				traceline(origin, m_eTarget.origin, MOVE_NORMAL, this);
				if (trace_ent == e)
					return;
				break;
			}

			input_buttons |= INPUT_BUTTON0;
			float burstMin = 0.06 - diff * 0.01;
			float burstMax = 0.15 - diff * 0.02;
			if (burstMin < 0.02) burstMin = 0.02;
			if (burstMax < 0.05) burstMax = 0.05;
			m_yapbShootTime = time + burstMin + random() * burstMax;
		}
	}

	if (diff >= YAPB_DIFF_NORMAL && dist < 800 && dist > 90) {
		makevectors(v_angle);
		float strafeDir;
		traceline(origin, origin + v_right * 134, MOVE_NORMAL, this);
		float rightClear = trace_fraction;
		traceline(origin, origin - v_right * 134, MOVE_NORMAL, this);
		float leftClear = trace_fraction;

		if (leftClear > rightClear)
			strafeDir = -1.0;
		else if (rightClear > leftClear)
			strafeDir = 1.0;
		else
			strafeDir = (random() < 0.5) ? -1.0 : 1.0;

		input_movevalues[1] = strafeDir * GetRunSpeed() * 0.8;
	}

	float approach = health * m_yapbAggression * 0.01;
	/* YaPB: sniper approach capped at 49 */
	bool isSniper = (activeweapon == WEAPON_AWP || activeweapon == WEAPON_SCOUT ||
	                 activeweapon == WEAPON_G3SG1 || activeweapon == WEAPON_SG550);
	if (isSniper && approach > 49)
		approach = 49;

	if (approach > 50 && dist > 200)
		input_movevalues[0] = GetRunSpeed();
	else if (approach < 30 && dist < 400)
		input_movevalues[0] = -GetRunSpeed() * 0.5;

	if (dist > 400 && dist < 900 && diff >= YAPB_DIFF_HARD)
		input_buttons |= INPUT_BUTTON8;

	if (health < 25 || (health < 40 && m_yapbPersonality == YAPB_PERS_CAREFUL)) {
		input_movevalues[0] = -GetRunSpeed();
		if (random() < 0.3)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * GetRunSpeed() * 0.6;
	}

	if (dist < 300 && diff >= YAPB_DIFF_NORMAL && (flags & FL_ONGROUND) && random() < 0.02)
		input_buttons |= INPUT_BUTTON2;
}

/* ============================================================
 * SeeThink — with seenThru support
 * ============================================================ */

void
csbot::SeeThink(void)
{
	if (!m_yapbInitialized) YaPB_Init();

	int diff = m_yapbDifficulty;
	float reactMin = g_yapbReactMin[diff];
	float reactMax = g_yapbReactMax[diff];
	float react = reactMin + random() * (reactMax - reactMin);
	if (react < 0.05) react = 0.05;

	if (m_yapbSeeTime > time)
		return;
	m_yapbSeeTime = time + react;

	for (entity w = world; (w = findfloat(w, ::takedamage, DAMAGE_YES));) {
		if (w.classname != "player")
			continue;
		if (w == this || w.health <= 0)
			continue;
		if (w.team == this.team)
			continue;
		if (!YaPB_IsInFOV(w, 75.0))
			continue;

		/* body-part visibility (YaPB tracks Head|Body|Other) */
		int parts = 0;
		vector eyePos = origin + view_ofs;

		traceline(eyePos, w.origin + w.view_ofs, MOVE_NORMAL, this);
		if (trace_ent == w || trace_fraction >= 0.98)
			parts |= 1;

		traceline(eyePos, w.origin, MOVE_NORMAL, this);
		if (trace_ent == w || trace_fraction >= 0.98)
			parts |= 2;

		if (parts) {
			m_yapbEnemyParts = parts;

			/* re-acquisition: instant reaction for same enemy (YaPB combat.cpp:508-546) */
			if (w == m_yapbLastEnemyEnt)
				m_yapbSeeTime = time;

			m_yapbLastEnemyEnt = w;
			SetEnemy(w);
			return;
		}

		/* seenThru: chance to detect through walls */
		if (random() < g_yapbSeenThru[diff]) {
			m_yapbEnemyParts = 2;
			m_yapbLastEnemyEnt = w;
			SetEnemy(w);
			return;
		}
	}
}

/* ============================================================
 * CreateObjective — now used as fallback for NORMAL task
 * ============================================================ */

void
csbot::CreateObjective(void)
{
	if (g_cs_bombzones > 0) {
		if (g_cs_bombplanted) {
			return;
		}
		if (team == TEAM_T) {
			if (g_items & ITEM_C4BOMB) {
				RunToRandomBombsite();
				return;
			}
			entity e = find(world, ::model, "models/w_backpack.mdl");
			if (e != world) {
				RouteToPosition(getEntityCenterPos(e));
				return;
			}
		}
	}

	if (g_cs_escapezones && team == TEAM_T) {
		RunToRandomEscapeZone();
		return;
	}

	if (random() < 0.5 && g_cs_escapezones > 0 && team == TEAM_CT) {
		RunToRandomEscapeZone();
		return;
	}

	if (g_cs_vipzones > 0 && team == TEAM_CT) {
		RunToRandomVIPSafetyZone();
		return;
	}

	if (random() < 0.5 && g_cs_vipzones > 0 && team == TEAM_T) {
		RunToRandomVIPSafetyZone();
		return;
	}

	if (random() < 0.5) {
		if (g_cs_hostagestotal > 0)
			RunToHostages();
		if (g_cs_bombzones > 0)
			RunToRandomBombsite();
	} else {
		RunToConfront();
	}

	if (m_iNodes <= 0) {
		float campChance = 0.20;
		switch (m_yapbPersonality) {
		case YAPB_PERS_CAREFUL: campChance = 0.40; break;
		case YAPB_PERS_RUSHER:  campChance = 0.05; break;
		}

		if (random() < campChance && activeweapon != WEAPON_KNIFE) {
			bool canCamp = true;
			for (entity ce = world; (ce = find(ce, ::classname, "player"));) {
				if (ce == this || clienttype(ce) == CLIENTTYPE_REAL) continue;
				if (ce.health <= 0) continue;
				csbot cb = (csbot)ce;
				if (cb.YaPB_TaskGetType() == YAPB_TASK_CAMP &&
				    vlen(cb.origin - origin) < 200) {
					canCamp = false;
					break;
				}
			}
			if (canCamp) {
				float dur = random(15, 45);
				m_yapbCampEnd = time + dur;
				m_yapbCampHealth = health;
				makevectors(v_angle);
				m_yapbCampLookA = v_forward;
				m_yapbCampLookB = v_forward * -1;
				m_yapbCampLookSwitch = time + random(3, 5);
				YaPB_TaskPush(YAPB_TASK_CAMP, origin, dur);
			}
		}
	}
}

/* ============================================================
 * RunAI — main loop with task system
 * ============================================================ */

void
csbot::RunAI(void)
{
	if (!m_yapbInitialized) YaPB_Init();

	super::RunAI();

	YaPB_SoundAwareness();
	YaPB_TaskFilter();
	YaPB_TaskExecute();
	YaPB_AimThink();
	YaPB_StuckCheck();
	YaPB_RadioThink();

	if (health < 40)
		m_yapbFear = bound(0.0, m_yapbFear + frametime * 0.5, 1.0);
	else
		m_yapbFear = bound(0.0, m_yapbFear - frametime * 0.1, 1.0);
	if (health > 80)
		m_yapbAggression = bound(0.0, m_yapbAggression + frametime * 0.2, 1.0);
	else
		m_yapbAggression = bound(0.0, m_yapbAggression - frametime * 0.1, 1.0);

	if (g_cs_roundswon_t != g_yapbPrevRoundsWonT) {
		g_yapbLastWinnerTeam = TEAM_T;
		g_yapbPrevRoundsWonT = g_cs_roundswon_t;
	}
	if (g_cs_roundswon_ct != g_yapbPrevRoundsWonCT) {
		g_yapbLastWinnerTeam = TEAM_CT;
		g_yapbPrevRoundsWonCT = g_cs_roundswon_ct;
	}

	button0 = input_buttons & INPUT_BUTTON0;
	button2 = input_buttons & INPUT_BUTTON2;
	button5 = input_buttons & INPUT_BUTTON5;
	button6 = input_buttons & INPUT_BUTTON6;
	button8 = input_buttons & INPUT_BUTTON8;
	movement = input_movevalues;
}

/* ============================================================
 * Global bot events
 * ============================================================ */

void
CSBot_BombPlantedNotify(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ = (csbot)a;
			if (targ.health <= 0)
				continue;
			if (targ.team == TEAM_CT) {
				targ.YaPB_TaskPush(YAPB_TASK_DEFUSE, [0,0,0], 0);
				targ.YaPB_Radio(RADIO_BOMBPL);
			} else {
				targ.Roam(targ.origin, 500);
			}
		}
	}
}

void
CSBot_HostageRescueNotify(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ = (csbot)a;
			if (targ.team == TEAM_T || targ.health <= 0)
				continue;
			targ.RunToHostages();
		}
	}
}

/* ============================================================
 * BUYING SYSTEM — 8-stage state machine
 * ============================================================ */

void
CSBot_BuyStart_Shop(void)
{
	player pl = (player)self;
	csbot bot = (csbot)self;

	pl.team = infokeyf(pl, "*team");
	pl.gflags = bot.m_gflagsBackup;

	int state = bot.m_yapbBuyState;

	switch (state) {
	case YAPB_BUY_PRIMARY: {
		if (!bot.m_yapbEconomyOk && pl.money < 2000) {
			bot.m_yapbBuyState = YAPB_BUY_ARMOR;
			break;
		}

		int prefCount = 12;
		int moneyReserve = (int)random(500, 1000);
		if (g_yapbLastWinnerTeam == pl.team)
			moneyReserve = 0;

		/* personality economy multiplier (YaPB prostock concept) */
		float econMult = 1.0;
		switch (bot.m_yapbPersonality) {
		case YAPB_PERS_RUSHER:  econMult = 0.8; break;
		case YAPB_PERS_CAREFUL: econMult = 1.2; break;
		}

		/* collect up to 4 affordable candidates (YaPB pickBestWeapon) */
		int choices[4];
		int choiceCount = 0;

		for (int i = 0; i < prefCount && choiceCount < 4; i++) {
			int w = g_yapbWeapPrefNormal[i];
			switch (bot.m_yapbPersonality) {
			case YAPB_PERS_RUSHER:  w = g_yapbWeapPrefRusher[i]; break;
			case YAPB_PERS_CAREFUL: w = g_yapbWeapPrefCareful[i]; break;
			}

			if (pl.team == TEAM_T) {
				if (w == WEAPON_M4A1 || w == WEAPON_AUG || w == WEAPON_SG550 ||
				    w == WEAPON_FIVESEVEN || w == WEAPON_TMP)
					continue;
			} else if (pl.team == TEAM_CT) {
				if (w == WEAPON_AK47 || w == WEAPON_SG552 || w == WEAPON_G3SG1 ||
				    w == WEAPON_ELITES || w == WEAPON_MAC10)
					continue;
			}

			if ((g_cstrikeWeaponPrice[w] * econMult) + moneyReserve <= pl.money) {
				choices[choiceCount] = w;
				choiceCount++;
			}
		}

		/* pick from candidates: prefer earlier (higher priority) */
		if (choiceCount > 0) {
			int pick;
			if (choiceCount == 1)
				pick = 0;
			else if (random() < 0.6)
				pick = 0;
			else
				pick = (int)floor(random(0, choiceCount));
			CSEv_BuyWeapon_f((float)choices[pick]);
		}

		bot.m_yapbBuyState = YAPB_BUY_ARMOR;
		break;
	}

	case YAPB_BUY_ARMOR: {
		int armorThresh = (int)random(50, 80);
		if (pl.armor < armorThresh) {
			if (pl.money >= g_cstrikeUtilPrice[1])
				CSEv_BuyEquipment_f(1);
			else if (pl.money >= g_cstrikeUtilPrice[0])
				CSEv_BuyEquipment_f(0);
		} else if (!(pl.g_items & ITEM_HELMET)) {
			if (pl.money >= 350)
				CSEv_BuyEquipment_f(1);
		}
		bot.m_yapbBuyState = YAPB_BUY_SECONDARY;
		break;
	}

	case YAPB_BUY_SECONDARY: {
		/* YaPB botlib.cpp:1507-1573 — 4 conditions to upgrade pistol */
		bool hasDefaultPistol = TRUE;
		if (pl.g_items & (ITEM_DEAGLE | ITEM_P228 | ITEM_ELITES | ITEM_FIVESEVEN))
			hasDefaultPistol = FALSE;

		bool hasPrimary = FALSE;
		for (int i = 0; i < g_weapons.length; i++)
			if ((pl.g_items & g_weapons[i].id) && g_weapons[i].slot == 0)
				hasPrimary = TRUE;

		bool shouldBuy = FALSE;
		/* condition 1: first round + default pistol + 60% chance */
		if (hasDefaultPistol && g_cs_roundsplayed <= 1 && random() < 0.6)
			shouldBuy = TRUE;
		/* condition 2: won last round + default pistol + money > 2000-3000 */
		if (hasDefaultPistol && g_yapbLastWinnerTeam == pl.team &&
		    pl.money > random(2000, 3000))
			shouldBuy = TRUE;
		/* condition 3: has primary + default pistol + money > 7500-9000 */
		if (hasPrimary && hasDefaultPistol && pl.money > random(7500, 9000))
			shouldBuy = TRUE;
		/* condition 4: simple money threshold */
		if (hasDefaultPistol && pl.money > 1500)
			shouldBuy = TRUE;

		if (shouldBuy) {
			float r = random();
			int pistol;
			if (r < 0.5)
				pistol = WEAPON_DEAGLE;
			else if (r < 0.8)
				pistol = WEAPON_P228;
			else {
				if (pl.team == TEAM_CT)
					pistol = WEAPON_FIVESEVEN;
				else
					pistol = WEAPON_ELITES;
			}

			if (pl.team == TEAM_T && pistol == WEAPON_FIVESEVEN)
				pistol = WEAPON_ELITES;
			if (pl.team == TEAM_CT && pistol == WEAPON_ELITES)
				pistol = WEAPON_FIVESEVEN;

			if (g_cstrikeWeaponPrice[pistol] <= pl.money)
				CSEv_BuyWeapon_f((float)pistol);
		}
		bot.m_yapbBuyState = YAPB_BUY_AMMO;
		break;
	}

	case YAPB_BUY_AMMO:
		CSEv_AmmoBuyPrimary();
		CSEv_AmmoBuyPrimary();
		CSEv_AmmoBuyPrimary();
		CSEv_AmmoBuySecondary();
		CSEv_AmmoBuySecondary();
		CSEv_AmmoBuySecondary();
		bot.m_yapbBuyState = YAPB_BUY_GRENADES;
		break;

	case YAPB_BUY_GRENADES: {
		float heChance = 0.30, fbChance = 0.40, smChance = 0.15;
		switch (bot.m_yapbPersonality) {
		case YAPB_PERS_RUSHER:
			heChance = 0.40; fbChance = 0.30; smChance = 0.10; break;
		case YAPB_PERS_CAREFUL:
			heChance = 0.20; fbChance = 0.60; smChance = 0.35; break;
		}

		if (random() < heChance && !(pl.g_items & ITEM_HEGRENADE) &&
		    pl.money >= g_cstrikeWeaponPrice[WEAPON_HEGRENADE])
			CSEv_BuyWeapon_f((float)WEAPON_HEGRENADE);
		if (random() < fbChance && !(pl.g_items & ITEM_FLASHBANG) &&
		    pl.money >= g_cstrikeWeaponPrice[WEAPON_FLASHBANG])
			CSEv_BuyWeapon_f((float)WEAPON_FLASHBANG);
		if (random() < smChance && !(pl.g_items & ITEM_SMOKEGRENADE) &&
		    pl.money >= g_cstrikeWeaponPrice[WEAPON_SMOKEGRENADE])
			CSEv_BuyWeapon_f((float)WEAPON_SMOKEGRENADE);

		bot.m_yapbBuyState = YAPB_BUY_DEFKIT;
		break;
	}

	case YAPB_BUY_DEFKIT:
		if (pl.team == TEAM_CT && g_cs_bombzones > 0 &&
		    !(pl.g_items & ITEM_DEFUSAL) &&
		    pl.money >= g_cstrikeUtilPrice[5] && random() < 0.8) {
			CSEv_BuyEquipment_f(5);
		}
		bot.m_yapbBuyState = YAPB_BUY_NVG;
		break;

	case YAPB_BUY_NVG:
		/* YaPB botlib.cpp:1636-1650 — 30% chance, money > 2500, economy check */
		if (bot.m_yapbEconomyOk && !(pl.g_items & ITEM_NIGHTVISION) &&
		    pl.money > 2500 && random() < 0.30) {
			CSEv_BuyEquipment_f(6);
		}
		bot.m_yapbBuyState = YAPB_BUY_DONE;
		break;

	case YAPB_BUY_DONE:
		for (int i = 0; i < g_weapons.length; i++) {
			if (pl.g_items & g_weapons[i].id) {
				pl.activeweapon = i;
				Weapons_Draw(pl);
				break;
			}
		}
		return;
	}

	if (bot.m_yapbBuyState < YAPB_BUY_DONE) {
		self.think = CSBot_BuyStart_Shop;
		self.nextthink = time + 0.3;
	}
}

void
CSBot_BuyStart(void)
{
	int moneyT = 0, moneyC = 0;
	int countT = 0, countC = 0;

	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL && a.health > 0) {
			player pl = (player)a;
			if (pl.team == TEAM_T) {
				moneyT += pl.money;
				countT++;
			} else if (pl.team == TEAM_CT) {
				moneyC += pl.money;
				countC++;
			}
		}
	}

	int avgT = 0;
	int avgC = 0;
	if (countT > 0) avgT = moneyT / countT;
	if (countC > 0) avgC = moneyC / countC;

	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			if (a.health <= 0)
				continue;

			csbot bot = (csbot)a;
			bot.m_yapbBuyState = YAPB_BUY_PRIMARY;

			int avg;
			if (bot.team == TEAM_T)
				avg = avgT;
			else
				avg = avgC;

			if (avg > 3000 || g_yapbLastWinnerTeam == bot.team)
				bot.m_yapbEconomyOk = TRUE;
			else
				bot.m_yapbEconomyOk = FALSE;

			a.think = CSBot_BuyStart_Shop;
			a.nextthink = time + random(0, autocvar_mp_freezetime);
		}
	}
}

/* ============================================================
 * TEAM COORDINATION
 * ============================================================ */

void
YaPB_ElectLeaders(void)
{
	g_yapbLeaderT = world;
	g_yapbLeaderCT = world;
	float bestFragsT = -999;
	float bestFragsCT = -999;

	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL && a.health > 0) {
			csbot bot = (csbot)a;
			if (bot.team == TEAM_T) {
				if (bot.g_items & ITEM_C4BOMB) {
					g_yapbLeaderT = bot;
				} else if (bot.frags > bestFragsT && g_yapbLeaderT == world) {
					bestFragsT = bot.frags;
					g_yapbLeaderT = bot;
				}
			} else if (bot.team == TEAM_CT) {
				if (bot.frags > bestFragsCT) {
					bestFragsCT = bot.frags;
					g_yapbLeaderCT = bot;
				}
			}
		}
	}

	if (g_yapbLeaderT != world && random() < 0.3)
		Radio_TeamMessage(RADIO_FOLLOWME, TEAM_T);
	if (g_yapbLeaderCT != world && random() < 0.3)
		Radio_TeamMessage(RADIO_FOLLOWME, TEAM_CT);
}

/* ============================================================
 * Round lifecycle
 * ============================================================ */

void
CSBot_RoundStart(void)
{
	YaPB_ElectLeaders();

	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ = (csbot)a;
			if (targ.health <= 0)
				continue;

			targ.m_yapbRadioRoundSpot = FALSE;
			targ.YaPB_TaskClear();
			targ.m_yapbLastEnemySeen = 0;

			targ.m_yapbAggression = targ.m_yapbBaseAggression;
			targ.m_yapbFear = targ.m_yapbBaseFear;

			if (random() < 0.3) {
				float msg = Radio_DefaultStart();
				float fTeam = targ.team;
				if (fTeam == TEAM_VIP) fTeam = TEAM_CT;
				Radio_TeamMessage(msg, fTeam);
			}
		}
	}
}

void
CSBot_RestartRound(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ = (csbot)a;
			targ.m_actionIsPlanting = FALSE;
			targ.m_actionIsDefusing = FALSE;
			targ.YaPB_TaskClear();
		}
	}
}
