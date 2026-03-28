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

/** @brief Get the absolute center pos of a entity */
vector getEntityCenterPos(entity e) {
	vector newVec;
	newVec[0] = e.absmin[0] + (0.5 * (e.absmax[0] - e.absmin[0]));
	newVec[1] = e.absmin[1] + (0.5 * (e.absmax[1] - e.absmin[1]));
	newVec[2] = e.absmin[2] + (0.5 * (e.absmax[2] - e.absmin[2]));
	return newVec;
}

/* YaPB personality types */
#define YAPB_NORMAL   0
#define YAPB_RUSHER   1
#define YAPB_CAREFUL  2

/* YaPB difficulty levels */
#define YAPB_NOOB     0
#define YAPB_EASY     1
#define YAPB_NORMAL   2
#define YAPB_HARD     3
#define YAPB_EXPERT   4

class csbot:NSBot
{
	void(void) csbot;

	/* some objectives */
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

	/* helpers */
	virtual entity(string, int) GetEntityByNameAndIndex;
	virtual entity(int) GetBombsiteByIndex;
	virtual entity(int) GetEscapeZoneByIndex;
	virtual entity(int) GetVIPSafetyZoneByIndex;
	virtual void(vector, float) AimLerp;

	/* YaPB enhanced combat */
	nonvirtual void(void) YaPB_Init;
	nonvirtual void(void) YaPB_CombatThink;
	nonvirtual void(void) YaPB_AimThink;
	nonvirtual void(void) YaPB_SoundAwareness;
	nonvirtual void(void) YaPB_StuckCheck;
	nonvirtual bool(entity, float) YaPB_IsInFOV;

	int m_actionIsPlanting;
	int m_actionIsDefusing;

	/* Workaround:
	* gflags is not yet set when CSBot_BuyStart_Shop() or CreateObjective()
	* are called, so we back it up on PostFrame() and use that instead.
	* Known issues it solves:
	* - Check if the bot is in a Bomb Zone (gflags & GF_BOMBZONE)
	* - Check if the bot is in a Buy Zone (gflags & GF_BUYZONE) */
	int m_gflagsBackup;

	/* YaPB state — server-only, not serialized */
	int m_yapbPersonality;
	int m_yapbDifficulty;
	float m_yapbAggression;
	float m_yapbFear;
	float m_yapbShootTime;
	float m_yapbSeeTime;
	float m_yapbHeardTime;
	vector m_yapbHeardPos;
	float m_yapbStuckTime;
	vector m_yapbPrevOrigin;
	int m_yapbStuckCount;
	float m_yapbCampEnd;
	float m_yapbLookYawVel;
	float m_yapbLookPitchVel;
	bool m_yapbInitialized;
};

void
csbot::RunToConfront(void)
{
	entity t;
	if (team == TEAM_T) {
		t = Route_SelectRandom("info_player_start");
	} else {
		t = Route_SelectRandom("info_player_deathmatch");
	}

	ChatSayTeam("Going to run to the Enemy Spawn!");

	if (t)
		RouteToPosition(t.origin);
}
/* go to the planted bomb */
void
csbot::RunToBomb(void)
{
	entity e = world;
	e = find(e, ::model, "models/w_c4.mdl");

	if (e) {
		RouteToPosition(e.origin);
		ChatSayTeam("Going to run to the Bomb!");
	}
}

/* go to given bombsite */
void
csbot::RunToBombsite(int bombsiteIndex)
{
	entity e = GetBombsiteByIndex(bombsiteIndex);
	RouteToPosition(getEntityCenterPos(e));
	ChatSayTeam(strcat("Going to run to Bomb Site ", itos(bombsiteIndex), "!"));
}

/* go to random bombsite */
void
csbot::RunToRandomBombsite(void)
{
	RunToBombsite(random(0, g_cs_bombzones));
}

/* go to given escape zone */
void
csbot::RunToEscapeZone(int index)
{
	entity e = GetEscapeZoneByIndex(index);
	RouteToPosition(getEntityCenterPos(e));
	ChatSayTeam(strcat("Going to run to Escape Zone ", itos(index), "!"));
}

/* go to a random escape zone */
void
csbot::RunToRandomEscapeZone(void)
{
	RunToEscapeZone(random(0, g_cs_escapezones));
}

/* go to given VIP Safety Zone */
void
csbot::RunToVIPSafetyZone(int index)
{
	entity e = GetVIPSafetyZoneByIndex(index);
	RouteToPosition(getEntityCenterPos(e));
	ChatSayTeam(strcat("Going to run to VIP Safety Zone ", itos(index), "!"));
}

/* go to a random VIP Safety Zone */
void
csbot::RunToRandomVIPSafetyZone(void)
{
	RunToVIPSafetyZone(random(0, g_cs_vipzones));
}

void
csbot::RunToHostages(void)
{
	entity e = world;

	e = find(e, ::classname, "hostage_entity");

	RouteToPosition(e.origin);
	ChatSayTeam("Going to run to the hostages!");
}

/** @brief Let the bot roam within a maximum distance from a given origin. */
void csbot::Roam(vector roamOrigin, int maxDistance) {
	/* Get random point whitin a radius from the given origin */
	int angle = random(0, 360); /* random angle. */
	int distance = random(0, maxDistance); /* random distance */
	float radian = angle * 3.145238095238 / 180;
	vector randLoc = roamOrigin;
	randLoc.x += sin(radian) * distance;
	randLoc.y += cos(radian) * distance;

	/* Find closest waypoint to our random location. */
	float flBestDist = COST_INFINITE;
	int iBestNodeIndex = -1;
	for (int i = 0; i < g_iNodes; i++) {
		float fDist = vlen(g_pNodes[i].origin - randLoc) - g_pNodes[i].radius;

		if (fDist > (float)maxDistance) {
			/* Distance is greater then our maxDistance */
			continue;
		}

		if (fDist < flBestDist) {
			flBestDist = fDist;
			iBestNodeIndex = i;
		}
	}

	if (iBestNodeIndex == -1) {
		/* TODO No waypoint in range found */
		print("WARNING!: Roaming failed, could not find waypoint in range.\n");
		return;
	}

	/* Go to the random waypoint. */
	RouteToPosition(g_pNodes[iBestNodeIndex].origin);
}

void
csbot::CreateObjective(void)
{
	/* Bomb defuse map */
	if (g_cs_bombzones > 0) {
		/* Bomb is planted */
		if (g_cs_bombplanted) {
			entity eBomb = find(world, ::model, "models/w_c4.mdl");
			if (eBomb == world) {
				/* No bomb model found, but it is/was planted */

				/* RoundOver: Bomb is defused */
				if (g_cs_gamestate == GAME_END) {
					RunToRandomBombsite();
					return;
				}

				/* Error */
				print("WARNING! g_cs_bombplanted == TRUE, but bomb model "
					  "cannot be found in the world.\n");
				return;
			}

			if (team == TEAM_CT) {
				if (g_cs_bombbeingdefused && m_actionIsDefusing == FALSE) {
					/* Bomb is being defused but not by this bot */
					/* Go and roam the defuser */
					Roam(eBomb.origin, 300);
					return;
				}

				if (m_actionIsDefusing) {
					if (!g_cs_bombbeingdefused) {
						/* Defusing complete or somehow failed. */
						m_actionIsDefusing = FALSE;
					} else {
						/* Continue defusing. */
						input_buttons |= (INPUT_BUTTON5 | INPUT_BUTTON8);
						input_movevalues = [0,0,0];
						button5 = input_buttons & INPUT_BUTTON5; // don't release button5
					}
				}
				else {
					int distToBomb = floor(vlen(eBomb.origin - origin));
					if (distToBomb > 60) {
						/* To far away from the bomb to defuse it, run to it! */
						RunToBomb();
					} else {
						/* Aim at the bomb. */
						input_buttons |= INPUT_BUTTON8; // duck
						if ((flags & FL_ONUSABLE)) {
							// Aimed at the bomb, ready to defuse!
							ChatSayTeam("Defusing!");
							input_buttons |= INPUT_BUTTON5;
							input_movevalues = [0,0,0];
							button5 = input_buttons & INPUT_BUTTON5; // don't release button5
							m_actionIsDefusing = TRUE;
						} else {
							// Do the real aiming
							float flLerp = bound(0.0f, frametime * 45, 1.0f);  // aim speed
							AimLerp(eBomb.origin + [0, 0, -6], flLerp);
						}
					}
				}
			}
			/* team == TEAM_T */
			else {
				/* Let T bots roam around the planted bomb */
				Roam(eBomb.origin, 500);
			}
			return;
		}
		/* Bomb is NOT planted */
		else {
			if (team == TEAM_T) {
				/* T-bot: plant bomb */
				if ((g_items & ITEM_C4BOMB)) {
					/* We carry the bomb */
					if (m_gflagsBackup & GF_BOMBZONE) {
						/* We are at a bombsite and ready to plant the bomb */
						if (activeweapon != WEAPON_C4BOMB) {
							activeweapon = WEAPON_C4BOMB;
							Weapons_Draw((player)self);
						}

						if (!m_actionIsPlanting) {
							ChatSayTeam("Going to plant the bomb!");
							m_actionIsPlanting = TRUE;
						}

						/* Workaround */
						gflags = m_gflagsBackup;

						/* Duck and plant bomb. */
						input_buttons = (INPUT_BUTTON0 | INPUT_BUTTON8);
						input_movevalues = [0,0,0];
					}
					else {
						/* Go to a bombsite first */
						RunToRandomBombsite();
					}
					return;
				}
				else {
					/* T-bot: check if the bomb has been dropped */
					entity e = find(world, ::model, "models/w_backpack.mdl");
					if (e != world) {
						/* The bomb backpack has been dropped */
						/* Go fetch dropped bomb! */
						ChatSayTeam("Arrr! Bomb on the ground, going to fetch it!");
						RouteToPosition(getEntityCenterPos(e));
						return;
					}
				}
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
}

/** @brief Aim towards a given (vector)aimpos with a given (float)lerp speed.
 *
 * @note
 * Copied code from nuclide botlib (inside bot::RunAI), maybe make this a
 * method there, could be usefull for other stuff?
 **/
void csbot::AimLerp(vector aimpos, float flLerp) {
	vector aimdir, vecNewAngles;

	vector oldAngle = v_angle;

	/* that's the old angle */
	makevectors(v_angle);
	vecNewAngles = v_forward;

	/* aimdir = new final angle */
	aimdir = vectoangles(aimpos - origin);
	makevectors(aimdir);

	/* slowly lerp towards the final angle */
	vecNewAngles[0] = Math_Lerp(vecNewAngles[0], v_forward[0], flLerp);
	vecNewAngles[1] = Math_Lerp(vecNewAngles[1], v_forward[1], flLerp);
	vecNewAngles[2] = Math_Lerp(vecNewAngles[2], v_forward[2], flLerp);

	/* make sure we're aiming tight */
	v_angle = vectoangles(vecNewAngles);
	v_angle[0] = Math_FixDelta(v_angle[0]);
	v_angle[1] = Math_FixDelta(v_angle[1]);
	v_angle[2] = Math_FixDelta(v_angle[2]);
	angles[0] = Math_FixDelta(v_angle[0]);
	angles[1] = Math_FixDelta(v_angle[1]);
	angles[2] = Math_FixDelta(v_angle[2]);
	input_angles = v_angle;
}

void
csbot::PostFrame(void)
{
	if (team == 0) {
		CSEv_JoinAuto();
	}

	team = infokeyf(this, "*team");
	m_gflagsBackup = gflags;
};

void
csbot::WeaponThink(void)
{
	if (activeweapon == WEAPON_KNIFE)
		return;

	/* clip empty */
	if (a_ammo1 == 0) {
		/* still got ammo left, reload! */
		if (a_ammo2 != 0) {
			input_buttons &= ~INPUT_BUTTON0;
			input_buttons |= INPUT_BUTTON4;
		} else {
			Weapons_SwitchBest(this);
		}
	}
};

/** @brief Get entity by class name and index **/
entity
csbot::GetEntityByNameAndIndex(string name, int index)
{
	int curIndex = 0;
	for (entity a = world; (a = find(a, ::classname, name));) {
		if (curIndex == index) {
			return a;
		}
		++curIndex;
	}
	print("WARNING: cstrike/server/bot.qc GetEntityByNameAndIndex: no entity '",
		  name, "' with index ", itos(index), "!\n");
	return world;
}

/** @brief Get bombsite entity by bombsite index
 *
 *  @note
 *  When there are for example 2 bombsites (g_cs_bombzones == 2) then valid
 *  indexes would be 0 and 1.
 * */
entity
csbot::GetBombsiteByIndex(int index)
{
	return GetEntityByNameAndIndex("func_bomb_target", index);
}

/** @brief Get Escape Zone entity by index **/
entity
csbot::GetEscapeZoneByIndex(int index)
{
	return GetEntityByNameAndIndex("func_escapezone", index);
}

/** @brief Get VIP Safety Zone entity by index **/
entity
csbot::GetVIPSafetyZoneByIndex(int index)
{
	return GetEntityByNameAndIndex("func_vip_safetyzone", index);
}

void
csbot::csbot(void)
{
	targetname = "_csbot_";
	team = infokeyf(this, "*team");
	m_actionIsPlanting = FALSE;
	m_actionIsDefusing = FALSE;
	m_gflagsBackup = 0;
}

/* === YaPB ENHANCED BOT AI === */
/* Based on YaPB by YaPB Project Developers (MIT License) */

/* Difficulty presets: [noob, easy, normal, hard, expert] */
var float g_yapbReactMin[] = {0.8, 0.4, 0.2, 0.1, 0.0};
var float g_yapbReactMax[] = {1.5, 0.8, 0.5, 0.3, 0.1};
var float g_yapbHeadshot[] = {0.00, 0.10, 0.30, 0.60, 0.90};
var float g_yapbHearing[]  = {0.30, 0.50, 0.70, 0.90, 1.00};
var float g_yapbAimErrMin[]= {50.0, 30.0, 15.0, 5.0, 0.0};
var float g_yapbAimErrMax[]= {80.0, 50.0, 30.0, 15.0, 5.0};
/* Spring-damper stiffness per difficulty */
var float g_yapbStiffness[]= {13.0, 50.0, 120.0, 200.0, 300.0};
var float g_yapbDamping[]  = {0.22, 5.0, 15.0, 25.0, 30.0};

void
csbot::YaPB_Init(void)
{
	m_yapbPersonality = (int)floor(random(0, 3));
	m_yapbDifficulty = bound(0, (int)cvar("bot_skill"), 4);
	switch (m_yapbPersonality) {
	case YAPB_RUSHER:
		m_yapbAggression = 0.7; m_yapbFear = 0.1; break;
	case YAPB_CAREFUL:
		m_yapbAggression = 0.2; m_yapbFear = 0.6; break;
	default:
		m_yapbAggression = 0.4; m_yapbFear = 0.3; break;
	}
	m_yapbShootTime = 0;
	m_yapbSeeTime = 0;
	m_yapbHeardTime = 0;
	m_yapbStuckTime = 0;
	m_yapbStuckCount = 0;
	m_yapbCampEnd = 0;
	m_yapbLookYawVel = 0;
	m_yapbLookPitchVel = 0;
	m_yapbInitialized = true;
}

/** YaPB FOV check **/
bool
csbot::YaPB_IsInFOV(entity ent, float fov)
{
	makevectors(v_angle);
	vector dir = normalize(ent.origin - origin);
	float dot = dir * v_forward;
	return (dot >= cos((fov * 0.5) * (M_PI / 180.0)));
}

/** YaPB sound awareness — hear gunfire and footsteps **/
void
csbot::YaPB_SoundAwareness(void)
{
	int diff = m_yapbDifficulty;
	if (random() > g_yapbHearing[diff])
		return;

	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == this || e.team == this.team || e.health <= 0)
			continue;
		float dist = vlen(e.origin - origin);
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

/** YaPB spring-damper aiming — replaces linear lerp **/
void
csbot::YaPB_AimThink(void)
{
	int diff = m_yapbDifficulty;
	float dt = frametime;
	if (dt <= 0) dt = 0.01;

	vector aimTarget;
	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		/* headshot chance */
		if (random() < g_yapbHeadshot[diff])
			aimTarget = m_eTarget.origin + m_eTarget.view_ofs;
		else
			aimTarget = m_eTarget.origin + m_eTarget.view_ofs * 0.4;

		/* aim error */
		float errScale = g_yapbAimErrMin[diff] + random() * (g_yapbAimErrMax[diff] - g_yapbAimErrMin[diff]);
		aimTarget += [crandom() * errScale * 0.01, crandom() * errScale * 0.01, 0];
	} else {
		/* aim at navigation point */
		if (m_iNodes && m_iCurNode >= 0)
			aimTarget = m_pRoute[m_iCurNode].dest;
		else
			aimTarget = origin + v_forward * 128;
	}

	/* calculate desired angles */
	vector desiredAngles = vectoangles(aimTarget - (origin + view_ofs));
	if (desiredAngles[0] > 180) desiredAngles[0] -= 360;
	if (desiredAngles[1] > 180) desiredAngles[1] -= 360;

	vector curAngles = v_angle;
	if (curAngles[0] > 180) curAngles[0] -= 360;
	if (curAngles[1] > 180) curAngles[1] -= 360;

	float stiffness = g_yapbStiffness[diff];
	float damping = g_yapbDamping[diff];

	/* yaw (left-right) */
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

	/* pitch (up-down) — 2x stiffness for natural feel */
	float pitchOff = desiredAngles[0] - curAngles[0];
	while (pitchOff > 180) pitchOff -= 360;
	while (pitchOff < -180) pitchOff += 360;

	float accP = bound(-3000, 2.0 * stiffness * pitchOff - damping * m_yapbLookPitchVel, 3000);
	m_yapbLookPitchVel += dt * accP;
	curAngles[0] += dt * m_yapbLookPitchVel;
	curAngles[0] = bound(-89, curAngles[0], 89);

	/* apply */
	input_angles = v_angle = angles = curAngles;
}

/** YaPB enhanced combat — strafing, retreat, fire control **/
void
csbot::YaPB_CombatThink(void)
{
	if (m_eTarget == __NULL__ || m_eTarget.health <= 0)
		return;

	int diff = m_yapbDifficulty;
	float dist = m_flEnemyDist;

	/* fire control — dot product threshold + burst timing */
	if (time >= m_yapbShootTime) {
		makevectors(v_angle);
		vector dir = normalize(m_eTarget.origin - origin);
		float dot = dir * v_forward;

		/* close range: lower threshold */
		float threshold;
		if (dist < 128)
			threshold = 0.80;
		else if (dist < 768)
			threshold = 0.90;
		else
			threshold = 0.95;

		if (dot >= threshold) {
			input_buttons |= INPUT_BUTTON0;
			/* burst timing based on difficulty */
			float burstMin = 0.06 - diff * 0.01;
			float burstMax = 0.15 - diff * 0.02;
			if (burstMin < 0.02) burstMin = 0.02;
			if (burstMax < 0.05) burstMax = 0.05;
			m_yapbShootTime = time + burstMin + random() * burstMax;
		}
	}

	/* strafe during combat */
	if (diff >= YAPB_NORMAL && dist < 800 && dist > 90) {
		/* check walls before strafing */
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

	/* approach based on aggression vs fear */
	float approach = health * m_yapbAggression * 0.01;
	if (approach > 50 && dist > 200)
		input_movevalues[0] = GetRunSpeed();
	else if (approach < 30 && dist < 400)
		input_movevalues[0] = -GetRunSpeed() * 0.5;

	/* crouch at range for accuracy */
	if (dist > 400 && dist < 900 && diff >= YAPB_HARD)
		input_buttons |= INPUT_BUTTON8;

	/* retreat if low health */
	if (health < 25 || (health < 40 && m_yapbPersonality == YAPB_CAREFUL)) {
		input_movevalues[0] = -GetRunSpeed();
		if (random() < 0.3)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * GetRunSpeed() * 0.6;
	}

	/* jump occasionally in close combat */
	if (dist < 300 && diff >= YAPB_NORMAL && (flags & FL_ONGROUND) && random() < 0.02)
		input_buttons |= INPUT_BUTTON2;
}

/** YaPB stuck detection **/
void
csbot::YaPB_StuckCheck(void)
{
	if (time < m_yapbStuckTime) return;
	m_yapbStuckTime = time + 0.5;

	float speed = vlen(origin - m_yapbPrevOrigin);
	m_yapbPrevOrigin = origin;

	if (speed < 10.0 && vlen(input_movevalues) > 50.0) {
		m_yapbStuckCount++;
		if (m_yapbStuckCount > 4) input_buttons |= INPUT_BUTTON2;
		if (m_yapbStuckCount > 8) input_buttons |= INPUT_BUTTON8;
		if (m_yapbStuckCount > 12)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * GetRunSpeed();
		if (m_yapbStuckCount > 18) {
			RouteClear();
			m_yapbStuckCount = 0;
		}
	} else {
		m_yapbStuckCount = 0;
	}
}

/** YaPB-enhanced SeeThink — difficulty-based reaction time **/
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

	/* search for enemies in 75° FOV */
	for (entity w = world; (w = findfloat(w, ::takedamage, DAMAGE_YES));) {
		if (w.classname != "player")
			continue;
		if (w == this || w.health <= 0)
			continue;
		if (w.team == this.team)
			continue;
		if (!YaPB_IsInFOV(w, 75.0))
			continue;

		traceline(origin, w.origin, MOVE_NORMAL, this);
		if (trace_ent == w) {
			SetEnemy(w);
			return;
		}
	}
}

/** YaPB-enhanced RunAI — replaces aim section + adds combat **/
void
csbot::RunAI(void)
{
	if (!m_yapbInitialized) YaPB_Init();

	/* call parent RunAI for base behavior */
	super::RunAI();

	/* sound awareness (runs every frame, internally throttled) */
	YaPB_SoundAwareness();

	/* enhanced combat when enemy visible */
	if (m_eTarget != __NULL__ && m_eTarget.health > 0) {
		traceline(origin, m_eTarget.origin, MOVE_NORMAL, this);
		if (trace_ent == m_eTarget || trace_fraction >= 0.98) {
			YaPB_CombatThink();
		}
	}

	/* override aim with spring-damper model */
	YaPB_AimThink();

	/* stuck detection */
	YaPB_StuckCheck();

	/* personality-based fear/aggression updates */
	if (health < 40)
		m_yapbFear = bound(0.0, m_yapbFear + frametime * 0.5, 1.0);
	if (health > 80)
		m_yapbAggression = bound(0.0, m_yapbAggression + frametime * 0.2, 1.0);

	/* apply final inputs */
	button0 = input_buttons & INPUT_BUTTON0;
	button2 = input_buttons & INPUT_BUTTON2;
	button5 = input_buttons & INPUT_BUTTON5;
	button6 = input_buttons & INPUT_BUTTON6;
	button8 = input_buttons & INPUT_BUTTON8;
	movement = input_movevalues;
}

void
CSBot_BombPlantedNotify(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ;
			targ = (csbot)a;

			if (targ.team == TEAM_T)
				continue;
			if (targ.health <= 0)
				continue;

			targ.RunToRandomBombsite();
		}
	}
}

void
CSBot_HostageRescueNotify(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ;
			targ = (csbot)a;

			if (targ.team == TEAM_T)
				continue;
			if (targ.health <= 0)
				continue;

			targ.RunToHostages();
		}
	}
}

void
CSBot_BuyStart_Shop(void)
{
	int done = 0;
	int count = 0;
	player pl = (player)self;

	pl.team = infokeyf(pl, "*team");

	/* Workaround */
	pl.gflags = ((csbot)pl).m_gflagsBackup;

	count = 0;
	while (done != 1) {
		int r = floor(random(1,17));

		if (pl.team == TEAM_T) {
			if (r == WEAPON_M4A1) { continue; }
			if (r == WEAPON_AUG) { continue; }
			if (r == WEAPON_SG550) { continue; }
			if (r == WEAPON_FIVESEVEN) { continue; }
			if (r == WEAPON_TMP) { continue; }
		} else if (pl.team == TEAM_CT) {
			if (r == WEAPON_AK47) { continue; }
			if (r == WEAPON_SG552) { continue; }
			if (r == WEAPON_G3SG1) { continue; }
			if (r == WEAPON_ELITES) { continue; }
			if (r == WEAPON_MAC10) { continue; }
		}

		if (g_cstrikeWeaponPrice[r] <= pl.money) {
			CSEv_BuyWeapon_f((float)r);
			done = 1;
		}
		count++;

		/* give it enough attempts */
		if (count > 17)
			done = 1;
	}

	/* CT: Random buy bomb defuse kit when enough money left */
	if (pl.team == TEAM_CT && g_cs_bombzones > 0 &&
		g_cstrikeUtilPrice[(float)5] <= pl.money &&
		random() < 0.5)
	{
		CSEv_BuyEquipment_f((float)5);  // ITEM_DEFUSAL
	}

	/* need armor */
	if (pl.armor < 100) {
		if (pl.money >= g_cstrikeUtilPrice[1]) /* kevlar and helmet */
			CSEv_BuyEquipment_f(1);
		else if (pl.money >= g_cstrikeUtilPrice[0]) /* just kevlar */
			CSEv_BuyEquipment_f(0);
	} else if (!(pl.g_items & ITEM_HELMET)) { /* we need helmet */
		if (pl.money >= 350) /* kevlar and helmet */
			CSEv_BuyEquipment_f(1);
	}

	/* make SURE we switch to it */
	for (int i = 0; i < g_weapons.length; i++)
		if (pl.g_items & g_weapons[i].id) {
			pl.activeweapon = i;
			Weapons_Draw(pl);
			return;
		}

	/* force buy right now */
	CSEv_AmmoBuyPrimary();
	CSEv_AmmoBuySecondary();
}

void
CSBot_BuyStart(void)
{
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			if (a.health <= 0)
				continue;

			a.think = CSBot_BuyStart_Shop;
			a.nextthink = time + random(0, autocvar_mp_freezetime);
		}
	}
}

void
CSBot_RoundStart(void)
{
	/* if (g_cs_bombzones <= 0) {
		return;
	}
		for (entity a = world; (a = find(a, classname, "player"));) {
			if (clienttype(a) != CLIENTTYPE_REAL) {
				csbot targ;
				targ = (csbot)a;

				if (targ.team == TEAM_T)
					continue;
				if (targ.health <= 0)
					continue;
				
				targ.RunToRandomBombsite();
			}
		}
	} */
}

void
CSBot_RestartRound(void)
{
	// Reset some variables for all bots
	for (entity a = world; (a = find(a, classname, "player"));) {
		if (clienttype(a) != CLIENTTYPE_REAL) {
			csbot targ;
			targ = (csbot)a;

			if (targ.team == TEAM_T) {
				targ.m_actionIsPlanting = FALSE;
			}
			else {
				targ.m_actionIsDefusing = FALSE;
			}
		}
	}
}
