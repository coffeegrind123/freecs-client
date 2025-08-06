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

/** @brief Get entity by class name and index **/
ncEntity
GetEntityByNameAndIndex(string name, int index)
{
	int curIndex = 0;
	for (entity a = world; (a = find(a, ::classname, name));) {
		if (curIndex == index) {
			return (ncEntity)a;
		}
		++curIndex;
	}
	print("WARNING: cstrike/server/bot.qc GetEntityByNameAndIndex: no entity '",
		  name, "' with index ", itos(index), "!\n");
	return __NULL__;
}

/** @brief Get bombsite entity by bombsite index
 *
 *  @note
 *  When there are for example 2 bombsites (g_cs_bombzones == 2) then valid
 *  indexes would be 0 and 1.
 * */
ncEntity
GetBombsiteByIndex(int index)
{
	return GetEntityByNameAndIndex("func_bomb_target", index);
}

/** @brief Get Escape Zone entity by index **/
ncEntity
GetEscapeZoneByIndex(int index)
{
	return GetEntityByNameAndIndex("func_escapezone", index);
}

/** @brief Get VIP Safety Zone entity by index **/
ncEntity
GetVIPSafetyZoneByIndex(int index)
{
	return GetEntityByNameAndIndex("func_vip_safetyzone", index);
}




void
csPlayer::csPlayer(void)
{
	ingame = false;
	cs_shotmultiplier = 0;
	cs_shottime = 0;
	cs_prev_hor_rec = 0;
	cs_hor_rec_sign = 0;
	cs_rec_reverse_chance = 0;

#ifdef CLIENT
	 playertype = 0;
	 cs_cross_mindist = 0;
	 cs_cross_deltadist = 0;
	 cs_crosshairdistance = 0;
#else
	 charmodel = 0;
	 money = 0;
	 progress = 0;
	 m_buyMessage = 0;
	 m_hostMessageT = 0;
	 m_seenFriend = 0;
	 m_seenEnemy = 0;
	 m_seenHostage = 0;
	 m_seenBombSite = 0;
	 m_bHasNightvision = 0;
	/* bot related maps */
	m_actionIsPlanting = FALSE;
	m_actionIsDefusing = FALSE;
	m_gflagsBackup = 0;
#endif
}

void
csPlayer::Physics_InputPreMove(void)
{
	super::Physics_InputPreMove();
	

	gflags &= ~GF_BUYZONE;
	gflags &= ~GF_RESCUEZONE;
	gflags &= ~GF_BOMBZONE;
}

float
punchangle_recovery(float punchangle)
{
	return input_timelength * (-0.2 * pow(1.2, fabs(punchangle)) + 4);
}

void
csPlayer::Physics_InputPostMove(void)
{
	//start of this function is taken from super::Physics_InputPostMove
	float punch;
	/* timers, these are predicted and shared across client and server */
	m_timeUntilNextAttack = max(0, m_timeUntilNextAttack - input_timelength);
	m_timeUntilReloaded = max(0, m_timeUntilReloaded - input_timelength);
	m_timeUntilNextIdle = max(0, m_timeUntilNextIdle - input_timelength);
	m_weaponAnimTime += input_timelength;
	punch = max(0, 1.0f - (input_timelength * 4));

	float flDamp;
	float flForce;
	if ( vlen( m_punchVelocity ) > 0.001 ) {
		m_punchAngle += m_punchVelocity * input_timelength;

		flForce = bound( 0, input_timelength * 65, 2 );
		flDamp = 1 - ( input_timelength * 9 );

		if ( flDamp < 0 ) {
			flDamp = 0;
		}
		m_punchVelocity *= flDamp;
		m_punchVelocity -= m_punchAngle * flForce;

		m_punchAngle[0] = bound( -89, m_punchAngle[0], 89 );
		m_punchAngle[1] = bound( -179, m_punchAngle[1], 179 );
		m_punchAngle[2] = bound( -89, m_punchAngle[2], 89 );
	} else if (vlen( m_punchAngle ) > 0.001) {
		if (m_punchAngle[0] < 0) {
			m_punchAngle[0] += punchangle_recovery(m_punchAngle[0]);
		}

		m_punchAngle[1] *= punch;
		m_punchAngle[2] *= punch;
	}



	RemoveVFlags(VFL_FROZEN);
	RemoveVFlags(VFL_NOATTACK);

	if (serverkeyfloat("cs_gamestate") == GAME_FREEZE) {
		AddVFlags(VFL_FROZEN);
		AddVFlags(VFL_NOATTACK);

		if (input_buttons & INPUT_BUTTON0) {
			m_timeUntilNextAttack = (m_timeUntilNextAttack > 0.1) ? m_timeUntilNextAttack : 0.1f;
		}
	}

	/* player animation code */
	UpdatePlayerAnimation(input_timelength);
	ProcessInput();
}
#ifdef CLIENT


/*
=================
csPlayer::ReceiveEntity
=================
*/
void
csPlayer::ReceiveEntity(float flIsNew, float flChanged)
{
	ncPlayer::ReceiveEntity(flIsNew, flChanged);

	/* animation */
	READENTITY_BYTE(anim_top, PLAYER_TOPFRAME)
	READENTITY_FLOAT(anim_top_time, PLAYER_TOPFRAME)
	READENTITY_FLOAT(anim_top_delay, PLAYER_TOPFRAME)
	READENTITY_BYTE(anim_bottom, PLAYER_BOTTOMFRAME)
	READENTITY_FLOAT(anim_bottom_time, PLAYER_BOTTOMFRAME)

	READENTITY_BYTE(cs_shotmultiplier, PLAYER_CSTIMERS)
	READENTITY_FLOAT(cs_shottime, PLAYER_CSTIMERS)
	READENTITY_FLOAT(cs_prev_hor_rec, PLAYER_CSTIMERS)
	READENTITY_BYTE(cs_hor_rec_sign, PLAYER_CSTIMERS)
	READENTITY_FLOAT(cs_rec_reverse_chance, PLAYER_CSTIMERS)

#if 0
	if (flChanged & PLAYER_AMMOTYPE) {
		HUD_AmmoNotify_Check(this);
	}
#endif

	setorigin(this, origin);
}

/*
=================
csPlayer::PredictPostFrame

Save the last valid server values away in the _net variants of each field
so we can roll them back later.
=================
*/
void
csPlayer::PredictPreFrame(void)
{
	super::PredictPreFrame();

	SAVE_STATE(cs_shotmultiplier)
	SAVE_STATE(cs_shottime)
	SAVE_STATE(cs_prev_hor_rec)
	SAVE_STATE(cs_hor_rec_sign)
	SAVE_STATE(cs_rec_reverse_chance)
}

/*
=================
csPlayer::PredictPostFrame

Where we roll back our values to the ones last sent/verified by the server.
=================
*/
void
csPlayer::PredictPostFrame(void)
{
	super::PredictPostFrame();

	ROLL_BACK(cs_shotmultiplier)
	ROLL_BACK(cs_shottime)
	ROLL_BACK(cs_prev_hor_rec)
	ROLL_BACK(cs_hor_rec_sign)
	ROLL_BACK(cs_rec_reverse_chance)
}

#else
/** @brief Aim towards a given (vector)aimpos with a given (float)lerp speed.
 *
 * @note
 * Copied code from nuclide botlib (inside bot::RunAI), maybe make this a
 * method there, could be usefull for other stuff?
 **/
void csPlayer::Bot_AimLerp(vector aimpos, float flLerp) {
	vector aimdir, vecNewAngles;

	vector oldAngle = v_angle;

	/* that's the old angle */
	vecNewAngles = anglesToForward(v_angle);

	/* aimdir = new final angle */
	aimdir = vectorToAngles(aimpos - origin);

	/* slowly lerp towards the final angle */
	vecNewAngles = vectorLerp(vecNewAngles, anglesToForward(aimdir), flLerp);

	/* make sure we're aiming tight */
	v_angle = vectorToAngles(vecNewAngles);
	input_angles = angles = v_angle = fixAngle(v_angle);
}

void
csPlayer::Bot_RunToConfront(void)
{
	entity t;

	if (team == TEAM_T) {
		t = Route_SelectRandom(teams.SpawnPoint(TEAM_CT));
	} else {
		t = Route_SelectRandom(teams.SpawnPoint(TEAM_T));
	}

	ChatSayTeam("Going to run to the Enemy Spawn!");

	if (t)
		RouteToPosition(t.origin);
}
/* go to the planted bomb */
void
csPlayer::Bot_RunToBomb(void)
{
	ncEntity e = __NULL__;
	e = (ncEntity)find(e, ::model, "models/w_c4.mdl");

	if (e) {
		RouteToPosition(e.WorldSpaceCenter());
		ChatSayTeam("Going to run to the Bomb!");
	}
}

/* go to given bombsite */
void
csPlayer::Bot_RunToBombsite(int bombsiteIndex)
{
	ncEntity e = GetBombsiteByIndex(bombsiteIndex);
	RouteToPosition(e.WorldSpaceCenter());
	ChatSayTeam(strcat("Going to run to Bomb Site ", itos(bombsiteIndex), "!"));
}

/* go to random bombsite */
void
csPlayer::Bot_RunToRandomBombsite(void)
{
	Bot_RunToBombsite(random(0, serverinfo.GetInteger("cs_bombzones")));
}

/* go to given escape zone */
void
csPlayer::Bot_RunToEscapeZone(int index)
{
	ncEntity e = GetEscapeZoneByIndex(index);
	RouteToPosition(e.WorldSpaceCenter());
	ChatSayTeam(strcat("Going to run to Escape Zone ", itos(index), "!"));
}

/* go to a random escape zone */
void
csPlayer::Bot_RunToRandomEscapeZone(void)
{
	Bot_RunToEscapeZone(random(0, serverinfo.GetInteger("cs_escapezones")));
}

/* go to given VIP Safety Zone */
void
csPlayer::Bot_RunToVIPSafetyZone(int index)
{
	ncEntity e = GetVIPSafetyZoneByIndex(index);
	RouteToPosition(e.WorldSpaceCenter());
	ChatSayTeam(strcat("Going to run to VIP Safety Zone ", itos(index), "!"));
}

/* go to a random VIP Safety Zone */
void
csPlayer::Bot_RunToRandomVIPSafetyZone(void)
{
	Bot_RunToVIPSafetyZone(random(0, serverinfo.GetInteger("cs_vipzones")));
}

void
csPlayer::Bot_RunToHostages(void)
{
	ncEntity e = __NULL__;

	e = (ncEntity)find(e, ::classname, "hostage_entity");

	RouteToPosition(e.origin);
	ChatSayTeam("Going to run to the hostages!");
}

/** @brief Let the bot roam within a maximum distance from a given origin. */
void csPlayer::Bot_Roam(vector roamOrigin, int maxDistance) {
	/* Get random point whitin a radius from the given origin */
	int angle = random(0, 360); /* random angle. */
	int distance = random(0, maxDistance); /* random distance */
	float radian = angle * 3.145238095238 / 180;
	vector randLoc = roamOrigin;
	randLoc.x += sin(radian) * distance;
	randLoc.y += cos(radian) * distance;

	/* Go to the random waypoint. */
	RouteToPosition(ncNavInfo::PositionOfClosestNode(randLoc));
}

void
csPlayer::Bot_CreateObjective(void)
{
	/* Bomb defuse map */
	if (serverinfo.GetInteger("cs_bombzones") > 0) {
		/* Bomb is planted */
		if (serverinfo.GetBool("cs_bombplanted")) {
			entity eBomb = find(world, ::model, "models/w_c4.mdl");
			if (eBomb == world) {
				/* No bomb model found, but it is/was planted */

				/* RoundOver: Bomb is defused */
				if (serverkeyfloat("cs_gamestate") == GAME_END) {
					Bot_RunToRandomBombsite();
					return;
				}

				/* Error */
				print("WARNING! g_cs_bombplanted == TRUE, but bomb model "
					  "cannot be found in the world.\n");
				return;
			}

			if (team == TEAM_CT) {
				if (serverinfo.GetBool("cs_bombbeingdefused") && m_actionIsDefusing == FALSE) {
					/* Bomb is being defused but not by this bot */
					/* Go and roam the defuser */
					Bot_Roam(eBomb.origin, 300);
					return;
				}

				if (m_actionIsDefusing) {
					if (serverinfo.GetBool("cs_bombbeingdefused") == false) {
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
						Bot_RunToBomb();
					} else {
						/* Aim at the bomb. */
						input_buttons |= INPUT_BUTTON8; // duck
						if ((HasVFlags(VFL_ONUSABLE))) {
							// Aimed at the bomb, ready to defuse!
							ChatSayTeam("Defusing!");
							input_buttons |= INPUT_BUTTON5;
							input_movevalues = [0,0,0];
							button5 = input_buttons & INPUT_BUTTON5; // don't release button5
							m_actionIsDefusing = TRUE;
						} else {
							// Do the real aiming
							float flLerp = bound(0.0f, frametime * 45, 1.0f);  // aim speed
							Bot_AimLerp(eBomb.origin + [0, 0, -6], flLerp);
						}
					}
				}
			}
			/* team == TEAM_T */
			else {
				/* Let T bots roam around the planted bomb */
				Bot_Roam(eBomb.origin, 500);
			}
			return;
		}
		/* Bomb is NOT planted */
		else {
			if (team == TEAM_T) {
				/* T-bot: plant bomb */
				if (HasItem("weapon_c4")) {
					/* We carry the bomb */
					if (m_gflagsBackup & GF_BOMBZONE) {
						/* We are at a bombsite and ready to plant the bomb */
						if (GetCurrentWeapon() != "weapon_c4") {
						/* TODO: REPLACE THIS WITH NSNAVAI METHOD */
							SwitchToWeapon("weapon_c4");
							//Weapons_Draw((csPlayer)self);
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
						Bot_RunToRandomBombsite();
					}
					return;
				}
				else {
					/* T-bot: check if the bomb has been dropped */
					ncEntity e = (ncEntity)find(world, ::model, "models/w_backpack.mdl");

					if (e != __NULL__) {
						/* The bomb backpack has been dropped */
						/* Go fetch dropped bomb! */
						ChatSayTeam("Arrr! Bomb on the ground, going to fetch it!");
						RouteToPosition(e.WorldSpaceCenter());
						return;
					}
				}
			}
		}
	}

	if (serverinfo.GetInteger("cs_escapezones") > 0i && team == TEAM_T) {
		Bot_RunToRandomEscapeZone();
		return;
	}

	if (random() < 0.5 && serverinfo.GetInteger("cs_escapezones") > 0i && team == TEAM_CT) {
		Bot_RunToRandomEscapeZone();
		return;
	}

	if (serverinfo.GetInteger("cs_vipzones") > 0i && team == TEAM_CT) {
		Bot_RunToRandomVIPSafetyZone();
		return;
	}

	if (random() < 0.5 && serverinfo.GetInteger("cs_vipzones") > 0i && team == TEAM_T) {
		Bot_RunToRandomVIPSafetyZone();
		return;
	}

	if (random() < 0.5) {
		if (serverinfo.GetInteger("cs_hostages") > 0) {
			Bot_RunToHostages();
		}
		if (serverinfo.GetInteger("cs_bombzones") > 0) {
			Bot_RunToRandomBombsite();
		}
	} else {
		Bot_RunToConfront();
	}
}

float ConsoleCmd(string cmd);

void
csPlayer::Bot_Buy(void)
{
	int done = 0;
	int count = 0;
	csPlayer pl = (csPlayer)self;
	int playerMoney = userinfo.GetInteger(pl, "*money");
	string weaponToBuy = "";
	int weaponPrice = 0i;

	if (pl.team == TEAM_T) {
		weaponToBuy = userinfo.GetString(pl, "fav_primary_ct");
	} else if (pl.team == TEAM_CT) {
		weaponToBuy = userinfo.GetString(pl, "fav_primary_t");
	}

	/* Workaround */
	pl.gflags = m_gflagsBackup;

	if (STRING_SET(weaponToBuy)) {
		weaponPrice = entityDef.GetInteger(weaponToBuy, "price");

		if (weaponPrice <= userinfo.GetInteger(pl, "*money")) {
			ConsoleCmd(strcat("buy ", weaponToBuy));
			playerMoney = userinfo.GetInteger(pl, "*money");
		} else {
			weaponToBuy = "";
		}
	}
	

	/* CT: Random buy bomb defuse kit when enough money left */
	if (pl.team == TEAM_CT && serverinfo.GetInteger("cs_bombzones") > 0 &&
		entityDef.GetInteger("item_defuse", "price") <= playerMoney &&
		random() < 0.5)
	{
		ConsoleCmd("item_defuse");
		playerMoney = userinfo.GetInteger(pl, "*money");
	}

	/* need armor */
	if (pl.armor < 100) {
		if (playerMoney >= entityDef.GetInteger("item_kevlar_helmet", "price")) {
			ConsoleCmd("buy item_kevlar_helmet");
		} else if (playerMoney >= entityDef.GetInteger("item_kevlar", "price")) {
			ConsoleCmd("buy item_kevlar");
		}
	} else if (pl.HasItem("item_kevlar_helmet") == false) {
		if (playerMoney >= 350) {
			ConsoleCmd("buy item_kevlar_helmet");
		}
	}

	if (STRING_SET(weaponToBuy)) {
		SwitchToWeapon(weaponToBuy);
	}

	/* force buy right now */
	ConsoleCmd("buyammo 0");
	ConsoleCmd("buyammo 1");
}


void
csPlayer::Input(entity eAct, string strInput, string strData)
{
	switch (strInput) {
	case "RadioMessage":
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RADIOMSG);
		WriteByte(MSG_MULTICAST, stof(strData));
		msg_entity = this;
		multicast([0,0,0], MULTICAST_ONE);
		break;
	case "RadioTeamMessage":
		tokenize(strData);
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RADIOMSG2);
		WriteByte(MSG_MULTICAST, stof(argv(0)));
		WriteByte(MSG_MULTICAST, stof(argv(1)));
		msg_entity = this;
		multicast([0,0,0], MULTICAST_ONE);
		break;
	case "NotifyBuyStart":
		if (IsAlive() == false) {
			return;
		}

		ScheduleThink(Bot_Buy, random(0, cvars.GetFloat("mp_freezetime")));
		break;
	case "NotifyRoundStarted":
		if (clienttype(this) != CLIENTTYPE_REAL) {
			if (IsAlive() == false) {
				return;
			}

			if (GetTeam() == TEAM_T) {
				return;
			}

			Bot_RunToRandomBombsite();
		}
		break;
	case "NotifyRoundRestarted":
		/* bot stuff */
		m_actionIsPlanting = FALSE;
		m_actionIsDefusing = FALSE;
		break;
	case "NotifyBombPlanted":
		if (clienttype(this) != CLIENTTYPE_REAL) {
			if (IsAlive() == false) {
				return;
			}

			if (GetTeam() == TEAM_T) {
				return;
			}

			Bot_RunToRandomBombsite();
		}
		break;
	case "NotifyHostageRescued":
		if (clienttype(this) != CLIENTTYPE_REAL) {
			if (IsAlive() == false) {
				return;
			}

			if (GetTeam() == TEAM_T) {
				return;
			}

			Bot_RunToHostages();
		}
		break;
	default:
		super::Input(eAct, strInput, strData);
	}
}

void
csPlayer::ServerInputFrame(void)
{
	super::ServerInputFrame();
}

void
csPlayer::EvaluateEntity(void)
{
	super::EvaluateEntity();

	EVALUATE_FIELD(anim_top, PLAYER_TOPFRAME)
	EVALUATE_FIELD(anim_top_time, PLAYER_TOPFRAME)
	EVALUATE_FIELD(anim_top_delay, PLAYER_TOPFRAME)
	EVALUATE_FIELD(anim_bottom, PLAYER_BOTTOMFRAME)
	EVALUATE_FIELD(anim_bottom_time, PLAYER_BOTTOMFRAME)

	EVALUATE_FIELD(cs_shotmultiplier, PLAYER_CSTIMERS)
	EVALUATE_FIELD(cs_shottime, PLAYER_CSTIMERS)
	EVALUATE_FIELD(cs_prev_hor_rec, PLAYER_CSTIMERS)
	EVALUATE_FIELD(cs_hor_rec_sign, PLAYER_CSTIMERS)
	EVALUATE_FIELD(cs_rec_reverse_chance, PLAYER_CSTIMERS)
}

/*
=================
csPlayer::SendEntity
=================
*/
float
csPlayer::SendEntity(entity ePEnt, float flChanged)
{
	/* don't broadcast invisible players */
	if (IsFakeSpectator() && ePEnt != this)
		return (0);
	if (!GetModelindex() && ePEnt != this)
		return (0);

	flChanged = OptimiseChangedFlags(ePEnt, flChanged);

	ncPlayer::SendEntity(ePEnt, flChanged);

	SENDENTITY_BYTE(anim_top, PLAYER_TOPFRAME)
	SENDENTITY_FLOAT(anim_top_time, PLAYER_TOPFRAME)
	SENDENTITY_FLOAT(anim_top_delay, PLAYER_TOPFRAME)
	SENDENTITY_BYTE(anim_bottom, PLAYER_BOTTOMFRAME)
	SENDENTITY_FLOAT(anim_bottom_time, PLAYER_BOTTOMFRAME)

	SENDENTITY_BYTE(cs_shotmultiplier, PLAYER_CSTIMERS)
	SENDENTITY_FLOAT(cs_shottime, PLAYER_CSTIMERS)
	SENDENTITY_FLOAT(cs_prev_hor_rec, PLAYER_CSTIMERS)
	SENDENTITY_BYTE(cs_hor_rec_sign, PLAYER_CSTIMERS)
	SENDENTITY_FLOAT(cs_rec_reverse_chance, PLAYER_CSTIMERS)
	return (1);
}
#endif

void
csPlayer::Physics_Fall(float impactspeed)
{
#if 0
	/* apply some predicted punch to the player */
	if (impactspeed >= 580)
		m_punchAngle += [15,0,(input_sequence & 1) ? 15 : -15];
	else if (impactspeed >= 400)
		m_punchAngle += [15,0,0];
#endif

	impactspeed *= 1.25f;

	/* basic server-side falldamage */
#ifdef SERVER
	/* if we've reached a fallheight of PHY_FALLDMG_DISTANCE qu, start applying damage */
	if (impactspeed >= 580) {
		float impactDamage = (impactspeed - 580) * (100 / (1024 - 580)) * 0.75f;

		/* this is kinda ugly, but worth the price */
		ncDict damageDecl = spawn(ncDict);
		damageDecl.AddKey("damage", ftos((int)impactDamage));
		Damage(this, this, damageDecl, 1.0, g_vec_null, origin);
		remove(damageDecl);
		StartSoundDef("Player.FallDamage", CHAN_VOICE, true);
	} else if (impactspeed >= 400) {
		StartSoundDef("Player.LightFall", CHAN_VOICE, true);
	}
#endif
}

void
csPlayer::Physics_Jump(void)
{
	if (waterlevel >= 2) {
		if (watertype == CONTENT_WATER) {
			velocity[2] = 100;
		} else if (watertype == CONTENT_SLIME) {
			velocity[2] = 80;
		} else {
			velocity[2] = 50;
		}
	} else {
		/* slow the player down a bit to prevent bhopping like crazy */
		velocity *= 0.80f;
		velocity[2] += 260;
	}
}

#ifdef SERVER
void
csPlayer::Death(entity inflictor, entity attacker, int damagePoints, vector dir, vector absImpactPos, int hitBody)
{
	/* either gib, or make a corpse */
	if (GetHealth()< -200) {
		float gibStrength = damagePoints * 2.0f;
		BreakModel_Entity(this, dir, gibStrength);
	} else {
		float deathAnimation = CSANIM_DIE_FORWARD;

		switch (hitBody) {
		case BODY_HEAD:
			deathAnimation = CSANIM_DIE_HEAD;
			break;
		case BODY_CHEST:
			deathAnimation = CSANIM_DEATH3;
			break;
		case BODY_STOMACH:
			deathAnimation = CSANIM_DIE_GUT;
			break;
		default:
			bool isFacing = IsFacingPosition(absImpactPos);

			/* we still want a change to play CSANIM_DIESIMPLE */
			if (random() < 0.5)
			if (isFacing == false) {
				deathAnimation = CSANIM_DEATH1;
			} else {
				deathAnimation = random() < 0.5 ? CSANIM_DEATH2 : CSANIM_DIE_BACK;
			}

			break;
		}

		MakeCorpse(deathAnimation);
	}
	
	ncPlayer::Death(inflictor,  attacker,  damagePoints,  dir, absImpactPos, hitBody);
}
#endif