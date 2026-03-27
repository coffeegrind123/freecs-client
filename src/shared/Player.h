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

/* all potential SendFlags bits we can possibly send */
enumflags
{
	PLAYER_TOPFRAME = PLAYER_CUSTOMFIELDSTART,
	PLAYER_BOTTOMFRAME = PLAYER_CUSTOMFIELDSTART,
	PLAYER_CSTIMERS = PLAYER_CUSTOMFIELDSTART
};

class
csPlayer:hlPlayer
{
public:
	void csPlayer(void);

	virtual void Physics_Fall(float);
	virtual void Physics_Jump(void);
	virtual void Physics_InputPreMove(void);

	virtual void Physics_InputPostMove(void);

#ifdef CLIENT
	virtual void ReceiveEntity(float, float);
	virtual void PredictPreFrame(void);
	virtual void PredictPostFrame(void);
#endif

#ifdef SERVER
	virtual void Death(entity, entity, int, vector, vector, int);
	virtual void Input(entity, string, string);
	virtual void ServerInputFrame(void);
	virtual void EvaluateEntity(void);
	virtual void CreateObjective(void);
	virtual void Spawned(void);
	virtual float SendEntity(entity, float);

	nonvirtual void Bot_RunToConfront(void);
	nonvirtual void Bot_RunToBomb(void);
	nonvirtual void Bot_RunToBombsite(int);
	nonvirtual void Bot_RunToRandomBombsite(void);
	nonvirtual void Bot_RunToEscapeZone(int);
	nonvirtual void Bot_RunToRandomEscapeZone(void);
	nonvirtual void Bot_RunToVIPSafetyZone(int);
	nonvirtual void Bot_RunToRandomVIPSafetyZone(void);
	nonvirtual void Bot_RunToHostages(void);
	nonvirtual void Bot_Roam(vector, int);
	nonvirtual void Bot_CreateObjective(void);
	nonvirtual void Bot_Buy(void);
	nonvirtual void Bot_AimLerp(vector, float);
#endif

private:
	int ingame;
	PREDICTED_FLOAT(cs_shotmultiplier)
	PREDICTED_FLOAT(cs_shottime)
	PREDICTED_FLOAT(cs_prev_hor_rec)
	PREDICTED_INT(cs_hor_rec_sign)
	PREDICTED_FLOAT(cs_rec_reverse_chance)

#ifdef CLIENT
	int playertype;
	int cs_cross_mindist;
	int cs_cross_deltadist;
	float cs_crosshairdistance;
#endif

#ifdef SERVER
	int charmodel;
	int money;
	float progress;

	bool m_buyMessage;
	bool m_hostMessageT;
	bool m_seenFriend;
	bool m_seenEnemy;
	bool m_seenHostage;
	bool m_seenBombSite;
	bool m_bHasNightvision;

	/* bot related vars */
	int m_actionIsPlanting;
	int m_actionIsDefusing;

	/* Workaround:
	* gflags is not yet set when CSBot_BuyStart_Shop() or Bot_CreateObjective()
	* are called, so we back it up on PostFrame() and use that instead.
	* Known issues it solves:
	* - Check if the bot is in a Bomb Zone (gflags & GF_BOMBZONE)
	* - Check if the bot is in a Buy Zone (gflags & GF_BUYZONE) */
	int m_gflagsBackup;

	/* YaPB enhanced bot AI */
	int m_yapbPersonality;
	int m_yapbDifficulty;
	float m_yapbAggression;
	float m_yapbFear;
	float m_yapbReactionTime;
	float m_yapbLastThink;
	float m_yapbShootTime;
	float m_yapbStuckTime;
	vector m_yapbPrevOrigin;
	int m_yapbStuckCount;
	float m_yapbCampEnd;
	float m_yapbHeardTime;
	vector m_yapbHeardPos;
	int m_yapbSenseStates;
	int m_yapbAimFlags;
	entity m_yapbLastEnemy;
	vector m_yapbLastEnemyPos;
	float m_yapbSeeEnemyTime;

	nonvirtual void YaPB_Init(void);
	nonvirtual void YaPB_EnhancedThink(void);
	nonvirtual void YaPB_CombatEnhance(void);
	nonvirtual void YaPB_AimEnhance(entity);
	nonvirtual void YaPB_StuckDetect(void);
	nonvirtual void YaPB_SoundAwareness(void);
	nonvirtual bool YaPB_IsInFOV(entity, float);
	nonvirtual bool YaPB_ShouldCamp(void);
	nonvirtual bool YaPB_ShouldRetreat(void);
#endif
};
