/*
 * YaPB Enhancement Layer for FreeCS
 * Based on YaPB by YaPB Project Developers (MIT License)
 *
 * yapb_enhance.qc — Enhanced bot AI methods for csPlayer
 *
 * These methods hook into FreeCS's existing bot system to add
 * YaPB-style difficulty, personality, combat, and awareness.
 *
 * Integration: Replace Bot_CreateObjective() call chain with
 * YaPB_EnhancedThink() which wraps the existing objective system.
 */

#ifdef SERVER

/* Difficulty presets: reactionMin, reactionMax, headshotPct, hearingPct, aimErrMin, aimErrMax */
var float g_yapbDiff_reactionMin[] = {0.8, 0.4, 0.2, 0.1, 0.0};
var float g_yapbDiff_reactionMax[] = {1.5, 0.8, 0.5, 0.3, 0.1};
var float g_yapbDiff_headshotPct[] = {0.00, 0.10, 0.30, 0.60, 0.90};
var float g_yapbDiff_hearingPct[]  = {0.30, 0.50, 0.70, 0.90, 1.00};
var float g_yapbDiff_aimErrMin[]   = {50.0, 30.0, 15.0, 5.0, 0.0};
var float g_yapbDiff_aimErrMax[]   = {80.0, 50.0, 30.0, 15.0, 5.0};

/*
 * YaPB_Init — Initialize YaPB fields on a new bot.
 * Call this when a bot spawns.
 */
void
csPlayer::YaPB_Init(void)
{
	/* random personality */
	m_yapbPersonality = (int)floor(random(0, 3));

	/* random difficulty (or from cvar) */
	m_yapbDifficulty = bound(0, (int)cvar("bot_skill"), 4);

	/* set aggression/fear from personality */
	switch (m_yapbPersonality) {
	case PERSONALITY_RUSHER:
		m_yapbAggression = 0.7;
		m_yapbFear = 0.1;
		break;
	case PERSONALITY_CAREFUL:
		m_yapbAggression = 0.2;
		m_yapbFear = 0.6;
		break;
	default:
		m_yapbAggression = 0.4;
		m_yapbFear = 0.3;
		break;
	}

	m_yapbReactionTime = 0.0;
	m_yapbLastThink = time;
	m_yapbShootTime = 0.0;
	m_yapbStuckTime = 0.0;
	m_yapbStuckCount = 0;
	m_yapbCampEnd = 0.0;
	m_yapbHeardTime = 0.0;
	m_yapbSenseStates = 0;
	m_yapbAimFlags = AIM_NAVPOINT;
	m_yapbLastEnemy = __NULL__;
	m_yapbSeeEnemyTime = 0.0;
}

/*
 * YaPB_EnhancedThink — Main enhanced AI loop.
 * Call this from Bot_CreateObjective() or RunAI().
 * Wraps the existing FreeCS objective system with YaPB enhancements.
 */
void
csPlayer::YaPB_EnhancedThink(void)
{
	int diff = m_yapbDifficulty;

	/* reaction time throttle based on difficulty */
	float reactionMin = g_yapbDiff_reactionMin[diff];
	float reactionMax = g_yapbDiff_reactionMax[diff];
	float reactionTime = reactionMin + random() * (reactionMax - reactionMin);
	if (reactionTime < 0.02) reactionTime = 0.02;

	if (time - m_yapbLastThink < reactionTime)
		return;
	m_yapbLastThink = time;

	/* update personality-based aggression/fear */
	if (health < 40)
		m_yapbFear = bound(0.0, m_yapbFear + 0.15, 1.0);
	if (health > 80)
		m_yapbAggression = bound(0.0, m_yapbAggression + 0.05, 1.0);

	/* sound awareness */
	YaPB_SoundAwareness();

	/* detect enemies in FOV */
	entity visEnemy = __NULL__;
	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == this || e.health <= 0 || e.team == this.team)
			continue;
		if (YaPB_IsInFOV(e, 75.0)) {
			traceline(origin + view_ofs, e.origin + e.view_ofs * 0.5, MOVE_NORMAL, this);
			if (trace_ent == e || trace_fraction >= 0.98) {
				visEnemy = e;
				m_yapbSenseStates |= STATE_SEEING_ENEMY;
				m_yapbSeeEnemyTime = time;
				break;
			}
		}
	}

	if (visEnemy == __NULL__ && time > m_yapbSeeEnemyTime + 3.0) {
		m_yapbSenseStates &= ~STATE_SEEING_ENEMY;
	}

	/* combat mode */
	if (visEnemy != __NULL__) {
		m_yapbAimFlags = AIM_ENEMY;
		YaPB_CombatEnhance();
		YaPB_AimEnhance(visEnemy);
		return; /* don't do objective stuff while fighting */
	}

	/* if we heard someone, investigate */
	if (m_yapbSenseStates & STATE_HEARING_ENEMY) {
		if (time < m_yapbHeardTime + 8.0) {
			RouteToPosition(m_yapbHeardPos);
		} else {
			m_yapbSenseStates &= ~STATE_HEARING_ENEMY;
		}
	}

	/* should we camp? */
	if (m_yapbCampEnd > 0.0 && time < m_yapbCampEnd) {
		input_movevalues = [0, 0, 0];
		return;
	}

	if (YaPB_ShouldCamp()) {
		m_yapbCampEnd = time + 8.0 + random() * 15.0;
		return;
	}

	/* fall through to FreeCS's existing objective system */
	Bot_CreateObjective();

	/* stuck detection */
	YaPB_StuckDetect();

	m_yapbAimFlags = AIM_NAVPOINT;
}

/*
 * YaPB_CombatEnhance — Enhanced combat behavior.
 * Adds strafing, crouching, retreat decisions.
 */
void
csPlayer::YaPB_CombatEnhance(void)
{
	entity enemy = m_eTarget;
	if (enemy == __NULL__ || enemy.health <= 0)
		return;

	float dist = vlen(enemy.origin - origin);

	/* difficulty-based strafing */
	if (m_yapbDifficulty >= DIFFICULTY_NORMAL && dist < 800.0) {
		float strafeDir = (random() < 0.5) ? -1.0 : 1.0;
		input_movevalues[1] = strafeDir * GetSideSpeed() * 0.8;
	}

	/* rush or retreat based on aggression vs fear */
	if (m_yapbAggression > m_yapbFear && dist > 200.0) {
		input_movevalues[0] = GetForwardSpeed();
	} else if (m_yapbFear > m_yapbAggression && dist < 300.0) {
		input_movevalues[0] = -GetBackSpeed();
	}

	/* crouch at range for accuracy (hard+ difficulty) */
	if (dist > 400.0 && dist < 900.0 && m_yapbDifficulty >= DIFFICULTY_HARD) {
		input_buttons |= INPUT_CROUCH;
	}

	/* fire control */
	if (time >= m_yapbShootTime) {
		makevectors(v_angle);
		vector dir = normalize(enemy.origin - origin);
		float dot = dir * v_forward;
		float threshold = 0.85 + (m_yapbDifficulty * 0.03);

		if (dot >= threshold) {
			input_buttons |= INPUT_PRIMARY;
			m_yapbShootTime = time + 0.08 + random() * 0.04;
		}
	}

	/* retreat decision */
	if (YaPB_ShouldRetreat()) {
		input_movevalues[0] = -GetBackSpeed();
		if (random() < 0.3)
			input_movevalues[1] = (random() < 0.5 ? 1 : -1) * GetSideSpeed();
	}
}

/*
 * YaPB_AimEnhance — Difficulty-based aiming with error and smoothing.
 */
void
csPlayer::YaPB_AimEnhance(entity target)
{
	if (target == __NULL__)
		return;

	int diff = m_yapbDifficulty;
	vector aimTarget;

	/* headshot chance based on difficulty */
	float headshotPct = g_yapbDiff_headshotPct[diff];
	if (random() < headshotPct)
		aimTarget = target.origin + target.view_ofs; /* head */
	else
		aimTarget = target.origin + target.view_ofs * 0.4; /* chest */

	/* add aim error */
	float errMin = g_yapbDiff_aimErrMin[diff];
	float errMax = g_yapbDiff_aimErrMax[diff];
	float errScale = errMin + random() * (errMax - errMin);
	aimTarget[0] += crandom() * errScale * 0.01;
	aimTarget[1] += crandom() * errScale * 0.01;

	/* aim speed: expert = fast, noob = slow */
	float aimSpeed = 0.15 + (diff * 0.2);
	aimSpeed = bound(0.1, aimSpeed, 1.0);

	/* smooth lerp */
	Bot_AimLerp(aimTarget, aimSpeed);
}

/*
 * YaPB_StuckDetect — Detect and recover from stuck situations.
 */
void
csPlayer::YaPB_StuckDetect(void)
{
	if (time < m_yapbStuckTime)
		return;
	m_yapbStuckTime = time + 0.5;

	float speed = vlen(origin - m_yapbPrevOrigin);
	m_yapbPrevOrigin = origin;

	if (speed < 10.0 && vlen(input_movevalues) > 50.0) {
		m_yapbStuckCount++;

		if (m_yapbStuckCount > 4)
			input_buttons |= INPUT_JUMP;
		if (m_yapbStuckCount > 8)
			input_buttons |= INPUT_CROUCH;
		if (m_yapbStuckCount > 12) {
			float dir = (random() < 0.5) ? 1.0 : -1.0;
			input_movevalues[1] = dir * GetSideSpeed();
		}
		if (m_yapbStuckCount > 18) {
			RouteClear();
			m_yapbStuckCount = 0;
		}
	} else {
		m_yapbStuckCount = 0;
	}
}

/*
 * YaPB_SoundAwareness — Listen for enemy gunfire/footsteps.
 */
void
csPlayer::YaPB_SoundAwareness(void)
{
	float hearingPct = g_yapbDiff_hearingPct[m_yapbDifficulty];
	if (random() > hearingPct)
		return;

	for (entity e = world; (e = find(e, ::classname, "player"));) {
		if (e == this || e.team == this.team || e.health <= 0)
			continue;

		float dist = vlen(e.origin - origin);
		if (dist > 1200.0)
			continue;

		/* shooting players make noise */
		if (e.button0 && dist < 900.0) {
			m_yapbHeardPos = e.origin;
			m_yapbHeardTime = time;
			m_yapbSenseStates |= STATE_HEARING_ENEMY;
			return;
		}

		/* running players make footstep noise */
		if (vlen(e.velocity) > 150.0 && dist < 500.0) {
			m_yapbHeardPos = e.origin;
			m_yapbHeardTime = time;
			m_yapbSenseStates |= STATE_HEARING_ENEMY;
			return;
		}
	}

	if (time > m_yapbHeardTime + 6.0)
		m_yapbSenseStates &= ~STATE_HEARING_ENEMY;
}

/*
 * YaPB_IsInFOV — Check if entity is within field of view.
 */
bool
csPlayer::YaPB_IsInFOV(entity ent, float fov)
{
	makevectors(v_angle);
	vector dir = normalize(ent.origin - origin);
	float dot = dir * v_forward;
	float threshold = cos((fov / 2.0) * (M_PI / 180.0));
	return (dot >= threshold);
}

/*
 * YaPB_ShouldCamp — Personality-based camping decision.
 */
bool
csPlayer::YaPB_ShouldCamp(void)
{
	if (m_yapbPersonality == PERSONALITY_RUSHER)
		return false;

	float chance = 0.03;
	if (m_yapbPersonality == PERSONALITY_CAREFUL)
		chance = 0.12;
	if (health < 40)
		chance += 0.08;

	return (random() < chance);
}

/*
 * YaPB_ShouldRetreat — Low health / outgunned retreat decision.
 */
bool
csPlayer::YaPB_ShouldRetreat(void)
{
	if (m_yapbPersonality == PERSONALITY_RUSHER && health > 20)
		return false;
	if (health < 25)
		return true;
	if (health < 40 && m_yapbPersonality == PERSONALITY_CAREFUL)
		return true;
	return false;
}

#endif /* SERVER */
