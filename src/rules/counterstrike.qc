/*
 * Copyright (c) 2016-2025 Marco Cawthorne <marco@icculus.org>
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

#define TEAM_NONE 0i
#define TEAM_T 1i
#define TEAM_CT 2i


typedef enum
{
	STATE_INACTIVE = 0i,
	STATE_COMMENCING = 1i,
	STATE_FREEZE = 2i,
	STATE_ACTIVE = 3i,
	STATE_END = 4i,
	STATE_OVER = 5i
} csGameState_t;

string g_csGameStateName[] =
{
	"STATE_INACTIVE",
	"STATE_COMMENCING",
	"STATE_FREEZE",
	"STATE_ACTIVE",
	"STATE_END",
	"STATE_OVER"
};

var csGameState_t g_csGameState;
var float g_cs_gametime;
var float g_cs_gameOverTime;
var bool g_cs_mapChangeRequested;
var int g_csSwapTeamRoundCounter;
var int g_iEscapedTerrorists;

/** @return If the usage of the flashlight is allowed. */
bool
AllowFlashlight(void)
{
	return cvars.GetBool("mp_flashlight");
}

/** @return Number of hostages in the map. */
int
HostageCount(void)
{
	return serverinfo.GetInteger("cs_hostages");
}

/** @return Number of different bomb zones/areas. Not bomb-sites. */
int
BombZones(void)
{
	return serverinfo.GetInteger("cs_bombzones");
}

/** @return Number of different escape zones/areas. */
int
EscapeZones(void)
{
	return serverinfo.GetInteger("cs_escapezones");
}

/** @return Number of different vip zones/areas. */
int
VIPZones(void)
{
	return serverinfo.GetInteger("cs_vipzones");
}

/** @return If hostage rescue rules apply. */
bool
IsHostageRescue(void)
{
	return (HostageCount() > 0i) ? (true) : (false);
}

/** @return If bomb defusal rules apply. */
bool
IsBombDefusal(void)
{
	return (BombZones() > 0i) ? (true) : (false);
}

/** @return If escape mode rules apply. */
bool
IsEscape(void)
{
	return (EscapeZones() > 0i) ? (true) : (false);
}

/** @return If assassination rules apply. */
bool
IsAssassination(void)
{
	return (VIPZones() > 0i) ? (true) : (false);
}

/** Called to set the internal CS ruleset game state. */
void
GameState_Set(csGameState_t newState)
{
	g_csGameState = newState;

	/* we need to be able to query it on the client. */
	serverinfo.SetInteger("cs_gamestate", newState);
}

/** @return Current rule state. See csGameState_t for valid states. */
csGameState_t
GameState(void)
{
	return (g_csGameState);
}

string
GameStateName(void)
{
	return (g_csGameStateName[g_csGameState]);
}

float
GameTime(void)
{
	return (g_cs_gametime);
}

/** @return Whether the bomb had been planted yet. */
bool
BombHasBeenPlanted(void)
{
	return serverinfo.GetBool("cs_bombplanted");
}

/** @return Whether the bomb is being defused. */
bool
BombIsBeingDefused(void)
{
	return serverinfo.GetBool("cs_bombbeingdefused");
}

/** @return How many rounds have been played on this map. */
int
RoundsPlayed(void)
{
	return serverinfo.GetInteger("cs_roundsplayed");
}

/** @return How many hostages have been rescued this round. */
int
HostagesRescued(void)
{
	return serverinfo.GetInteger("cs_hostagesrescued");
}

/** @return The desired CS round time, in seconds. */
float
RoundTime(void)
{
	return cvars.GetFloat("mp_roundtime") * 60;
}

/** @return The desired map time limit, in seconds. */
float
TimeLimit(void)
{
	return cvars.GetFloat("mp_timelimit") * 60;
}

/** @return The desired map win limit, in rounds won. */
int
WinLimit(void)
{
	return cvars.GetInteger("mp_winlimit");
}

/** @return The amount of frozen time at the start of each round. */
float
FreezeTime(void)
{
	return cvars.GetFloat("mp_freezetime");
}

/** @parm playerCheck Player to check the status from.
@return Whether the given player is a VIP in the Assassination mode. */
bool
IsVIP(entity playerCheck)
{
	return userinfo.GetBool(playerCheck, "*csvip");
}

/** Turns a player into a bomber. Tasked to plant the bomb at a given site.
@parm targetPlayer Player to turn into a bomber. */
void
MakeBomber(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	ents.Input(targetPlayer, "GiveItem", "weapon_c4", targetPlayer);
	/* env_message_single(pl, "Hint_you_have_the_bomb"); */
}

/** Turns a player into a VIP. He has to escape from the terrorist threat.
@parm targetPlayer Player to turn into a bomber. */
void
MakeVIP(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	userinfo.SetBool(targetPlayer, "*csvip", true);
	targetPlayer.modelindex = getmodelindex(entityDef.GetString("player_vip", "model"));
}

/** Sets the target player's T model class. Visual fluff. */
void
SetTClass(entity targetPlayer, integer modelIndex)
{
	userinfo.SetInteger(targetPlayer, "t_class", modelIndex);
}

/** Sets the target player's CT model class. Visual fluff. */
void
SetCTClass(entity targetPlayer, integer modelIndex)
{
	userinfo.SetInteger(targetPlayer, "ct_class", modelIndex);
}

/** Returns the modelindex the target player desires to use for the CT team. */
float
GetCTModelIndex(entity targetPlayer)
{
	int classID = userinfo.GetInteger(targetPlayer, "ct_class");
	string keyName = sprintf("model_class%i", classID);
	return getmodelindex(entityDef.GetString("player_counterterrorist", keyName));
}

/** Returns the modelindex the target player desires to use for the T team. */
float
GetTModelIndex(entity targetPlayer)
{
	int classID = userinfo.GetInteger(targetPlayer, "t_class");
	string keyName = sprintf("model_class%i", classID);
	return getmodelindex(entityDef.GetString("player_terrorist", keyName));
}

/** Instantiates a player into the world. Playable by the end. */
void
SoftRespawn(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	/* override any currently set model with the desired class model. */
	if (userinfo.GetInteger(targetPlayer, "*team") == TEAM_T) {
		targetPlayer.modelindex = GetTModelIndex(targetPlayer);

		/* fallback if no "class" key is specified. */
		if (targetPlayer.modelindex == 0) {
			targetPlayer.modelindex = getmodelindex(entityDef.GetString("player_terrorist", "model_class1"));
		}
	} else {
		targetPlayer.modelindex = GetCTModelIndex(targetPlayer);

		/* fallback 2nd */
		if (targetPlayer.modelindex == 0) {
			targetPlayer.modelindex = getmodelindex(entityDef.GetString("player_counterterrorist", "model_class1"));
		}
	}

	userinfo.SetBool(targetPlayer, "*csvip", false);
	targetPlayer.health = 100;
	game.TeleportToSpawn(targetPlayer);
}

/** Instantiates a player into the world. Playable by the end. */
void
HardRespawn(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	/* decl transformation */
	if (userinfo.GetInteger(targetPlayer, "*team") == TEAM_CT) {
		ents.ChangeToClass(targetPlayer, "player_counterterrorist");
	} else {
		ents.ChangeToClass(targetPlayer, "player_terrorist");
	}

	userinfo.SetString(targetPlayer, "*icon1", "");
	SoftRespawn(targetPlayer);
}

/** Will swap teams (and their scores) in the current map. */
void
SwapTeams(void)
{
	int ctScore = 0i;
	int tScore = 0i;

	for (entity teamPlayer = world;(teamPlayer = next.Player(teamPlayer));) {
		if (teamPlayer.team == TEAM_CT) {
			ents.Input(teamPlayer, "SetTeam", "1", world);
			/*teamPlayer.charmodel -= 4;*/
		} else if (teamPlayer.team == TEAM_T) {
			ents.Input(teamPlayer, "SetTeam", "2", world);
			/*teamPlayer.charmodel += 4;*/
		}
	}

	ctScore = teams.Score(TEAM_CT);
	tScore = teams.Score(TEAM_T);

	teams.SetScore(TEAM_CT, tScore);
	teams.SetScore(TEAM_T, ctScore);
}

#include "radio.h"
#include "money.h"

/* ROUND: related to the round timer only */
void Round_Finished(int winningTeam, int moneyReward, bool silentRadio);
void Round_Restart(bool wipeProgress);

/** Called when forcing a state change, with a specific count-down timer. */
void
Round_TimerStart(float secondsLeft, int desiredState)
{
	g_cs_gametime = secondsLeft;
	serverinfo.SetFloat("cs_gametime", time + secondsLeft);

	if (desiredState == STATE_FREEZE) {
		GameState_Set(STATE_FREEZE);
	} else if (desiredState == STATE_ACTIVE) {
		GameState_Set(STATE_ACTIVE);

		if (teams.NumPlayers(TEAM_T) <= 1i || teams.NumPlayers(TEAM_CT) <= 1i)
			return;

		/* if no players are present in the chosen team, force restart round */
		if (teams.NumAlivePlayers(TEAM_T) == 0i) {
			Round_Finished(TEAM_CT, 3600i, false);
			return;
		} else if (teams.NumAlivePlayers(TEAM_CT)  == 0i) {
			Round_Finished(TEAM_T, 3600i, false);
			return;
		}

	} else if (desiredState == STATE_END) {
		GameState_Set(STATE_END);
	} else if (desiredState == STATE_COMMENCING) {
		GameState_Set(STATE_COMMENCING);
	} else if (desiredState == STATE_OVER) {
		GameState_Set(STATE_OVER);
	}
}

/** This gets called whenever an objective is completed or time is up. */
void
Round_Finished(int winningTeam, int moneyReward, bool silentRadio)
{
	if (GameState() != STATE_ACTIVE && GameState() != STATE_FREEZE) {
		return;
	}

	if (winningTeam == TEAM_T) {
		if (silentRadio == false) {
			Radio_BroadcastMessage(RADIO_TERWIN);
		}

		g_csSwapTeamRoundCounter++;
		teams.AddScore(TEAM_T, 1i);
	} else if (winningTeam == TEAM_CT) {
		if (silentRadio == false) {
			Radio_BroadcastMessage(RADIO_CTWIN);
		}

		g_csSwapTeamRoundCounter++;
		teams.AddScore(TEAM_CT, 1i);

		/* In Bomb Defusal, if Terrorists were able to plant the bomb
		 * but lose the round, all Terrorists receive an $800 bonus. */
		if (BombHasBeenPlanted()) {
			Money_QueTeamReward(TEAM_T, 800i);
		}
	} else {
		if (silentRadio == false) {
			Radio_BroadcastMessage(RADIO_ROUNDDRAW);
		}
	}

	Money_HandleRoundReward(winningTeam);
	Money_QueTeamReward(winningTeam, moneyReward);
	Round_TimerStart(5.0f, STATE_END); /* Round is over, 5 seconds til a new round starts. */

	serverinfo.SetInteger("cs_hostagesrescued", 0i);
	serverinfo.SetBool("cs_bombbeingdefused", false);
	serverinfo.SetBool("cs_bombplanted", false);
	serverinfo.SetInteger("cs_roundsplayed", serverinfo.GetInteger("cs_roundsplayed") + 1i);
}

/** Called when the state timer ends, which was started with Round_TimerStart(). */
void
Round_TimerEnd(void)
{
	if (IsEscape() == true) {
		Round_Finished(TEAM_T, 3250i, false);
	} else if (IsBombDefusal() == true) {
		/* In Bomb Defusal, all Counter-Terrorists receive $3250
		 *  if they won running down the time. */
		Round_Finished(TEAM_CT, 3250i, false);
	} else if (IsHostageRescue() == true) {
		// TODO: Broadcast_Print: Hostages have not been rescued!
		Round_Finished(TEAM_T, 3250i, false);
	} else {
		Round_Finished(TEAM_NONE, 0i, false);
	}
}

/** Run every single frame. */
void
Round_TimerUpdate(void)
{
	/* if we've got hostages in the map... */
	if (IsHostageRescue()) {
		/* and they're all rescued.... */
		if (HostagesRescued() >= HostageCount()) {
			/* CTs win! */
			Round_Finished(TEAM_CT, 0i, false);
			return;
		}
	}

	/* This map has been played enough we think */
	if (g_cs_mapChangeRequested == false && GameState() != STATE_OVER) {
		if (TimeLimit() > 0i) {
			if (time >= TimeLimit()) {
				g_cs_mapChangeRequested = true;
			}
		}
	}

	/* Okay, this means that timelimit is not the only deciding factor */
	if (WinLimit() > 0i && g_cs_mapChangeRequested == false && GameState() != STATE_OVER) {
		/* if either win, go end this map.*/
		if (teams.Score(TEAM_CT) >= WinLimit() ||
			teams.Score(TEAM_T) >= WinLimit()) {
			g_cs_mapChangeRequested = true;
		}
	}

	/* Game over: advance to next map after delay */
	if (GameState() == STATE_OVER && g_cs_gameOverTime > 0.0f) {
		if (time >= g_cs_gameOverTime) {
			g_cs_gameOverTime = 0.0f;
			localcmd("nextmap\n");
		}
	}

	/* If map change requested but no round is active (no players on teams),
	   change map immediately — otherwise we'd be stuck forever */
	if (g_cs_mapChangeRequested == true) {
		if (GameState() == STATE_INACTIVE || GameState() == STATE_COMMENCING) {
			GameState_Set(STATE_OVER);
			g_cs_gameOverTime = time + 5.0f;
			g_cs_mapChangeRequested = false;
			return;
		}
	}

	/* INACTIVE means no one is registered as a player */
	if (GameState() == STATE_INACTIVE) {
		return;
	}

	/* our continously running down timer */
	g_cs_gametime = bound(0.0f, g_cs_gametime - frametime, g_cs_gametime);

	//printf("%f %S\n", GameTime(), GameStateName());

	/* if the round is over or the game is done with... */
	if (GameState() == STATE_COMMENCING || GameState() == STATE_END) {
		if (GameTime() <= 0.0f) {
			/* map change was requested — do it now that the round ended */
			if (g_cs_mapChangeRequested == true) {
				GameState_Set(STATE_OVER);
				g_cs_gameOverTime = time + 5.0f;
				g_cs_mapChangeRequested = false;
				return;
			}

			if (teams.Score(TEAM_T) == 0i && teams.Score(TEAM_CT) == 0i) {
				Money_ResetTeamReward();
				Money_ResetRoundReward();
				Round_Restart(true);
			} else {
				if (cvars.GetBool("mp_halftime") == true && ((WinLimit() / 2i) == RoundsPlayed())) {
					Money_ResetTeamReward();
					SwapTeams();
					Round_Restart(true);
				} else {
					Round_Restart(false);
				}
			}
		}
		return;
	}

	if ((GameState() == STATE_ACTIVE) || (GameState() == STATE_FREEZE)) {
		if (GameTime() <= 0.0f) {
			if (GameState() == STATE_ACTIVE) {
				/* 1.5 will make the T's lose if time runs out no matter what */
				if (cvars.GetBool("fcs_fix_bombtimer") == true) {
					if (IsBombDefusal() == true && BombHasBeenPlanted() == true) {
						return;
					}
				}

				Round_TimerEnd();
				Round_TimerStart(5.0f, STATE_END); /* Round is over, 5 seconds til a new round starts */
			} else {
				Round_TimerStart(RoundTime(), STATE_ACTIVE); // Unfreeze
				Radio_StartMessage();
				/* CSBot_RoundStart(); */
			}
		}
	}
}

/** Called to forcefully respawn everything in the map, and players. */
void
Round_Restart(bool wipeProgress)
{
	/* shall we swap teams? */
	if (cvars.GetInteger("fcs_swaponround") > 0i) {
		if (g_csSwapTeamRoundCounter >= cvars.GetInteger("fcs_swaponround")) {
			g_csSwapTeamRoundCounter = 0i;
			SwapTeams();
		}
	}


	for (entity teamPlayer = world;(teamPlayer = next.Player(teamPlayer));) {
		if (teamPlayer.team != TEAM_CT && teamPlayer.team != TEAM_T) {
			continue;
		}

		ents.Input(teamPlayer, "NotifyRoundRestarted", "", world);

		if (is.Alive(teamPlayer) == true && wipeProgress == false) {
			SoftRespawn(teamPlayer);
		} else {
			HardRespawn(teamPlayer);
		}

		if (wipeProgress == false) {
			Money_GiveTeamReward(teamPlayer);
		} else {
			Money_WipeProgress(teamPlayer);
		}

		ents.Input(teamPlayer, "NotifyBuyStart", "", world);
	}

	/* sometimes, even when the bomb was planted, the round may end early.
	   so get rid of any bombs that may be on the level. */
	for (entity bombFinder = world; (bombFinder = find(bombFinder, ::classname, "item_c4"));) {
		ents.Input(bombFinder, "Kill", "", world);
	}

	/* Select a random Terrorist player for the bomb duty, if needed */
	if (IsBombDefusal() == true) {
		MakeBomber(teams.RandomPlayer(TEAM_T));
	} 

	/* if there is meant to be a VIP, select a random CT to be it */
	if (IsAssassination() == true) {
		MakeVIP(teams.RandomPlayer(TEAM_CT));
	}

	/* Respawn all the entities */
	game.CleanUpMap();
	Round_TimerStart(FreezeTime(), STATE_FREEZE);
	Money_ResetTeamReward();
}

void
Round_CheckUponDeath(entity playerCheck)
{
	/* don't count kills at this stage */
	if (GameState() == STATE_END) {
		return;
	}

	/* hack so that we can kill rounds. */
	if ((teams.NumAlivePlayers(TEAM_T) == 0i) && (teams.NumAlivePlayers(TEAM_CT) == 0i)) {
		GameState_Set(STATE_ACTIVE);
	}

	switch (GameState()) {
	case STATE_INACTIVE:
	case STATE_COMMENCING:
	case STATE_END:
	case STATE_OVER:
		return;
		break;
	}

	if ((teams.NumAlivePlayers(TEAM_T) == 0i) && (teams.NumAlivePlayers(TEAM_CT) == 0i)) {
		if (BombHasBeenPlanted() == true) {
			Round_Finished(TEAM_T, 3600i, false);
		} else {
			Round_Finished(TEAM_NONE, 0i, false);
		}
	} else {
		int winningTeam;

		if ((playerCheck.team == TEAM_T) && (teams.NumAlivePlayers(TEAM_T) == 0i)) {
			winningTeam = TEAM_CT;
		} else if ((playerCheck.team == TEAM_CT) && (teams.NumAlivePlayers(TEAM_CT) == 0i)) {
			winningTeam = TEAM_T;
		} else {
			return;
		}

		if (IsBombDefusal() == true) {
			/* In Bomb Defusal, the winning team receives $3250
			 * if they won by eliminating the enemy team. */
			if (BombHasBeenPlanted() == false || teams.NumAlivePlayers(TEAM_CT) == 0i) {
				Round_Finished(winningTeam, 3250i, false);
			}
		} else {
			/* In Hostage Rescue, the winning team receives $3600
			 * if they won by eliminating the enemy team. */
			Round_Finished(winningTeam, 3600i, false);
		}
	}
}

void
CS_CountHostages(void)
{
	int counter = 0i;

	for (entity e = world; (e = find(e, ::classname, "hostage_entity"));) {
		counter++;
	}

	serverinfo.SetInteger("cs_hostages", counter);
}

void
CS_CountBombZones(void)
{
	int counter = 0i;

	for (entity e = world; (e = find(e, ::classname, "func_bomb_target"));) {
		counter++;
	}

	serverinfo.SetInteger("cs_bombzones", counter);
}

void
CS_CountEscapeZones(void)
{
	int counter = 0i;

	for (entity e = world; (e = find(e, ::classname, "func_escape_zone"));) {
		counter++;
	}

	serverinfo.SetInteger("cs_escapezones", counter);
}

void
CS_CountVIPZones(void)
{
	int counter = 0i;

	for (entity e = world; (e = find(e, ::classname, "func_vip_safetyzone"));) {
		counter++;
	}

	serverinfo.SetInteger("cs_vipzones", counter);
}

void
CS_GoSpectator(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	ents.ChangeToClass(targetPlayer, "spectator");
	game.TeleportToSpawn(targetPlayer);
}

/* This player requests a spawn, usually when having chosen a team + model. */
void
CS_RequestSpawn(entity targetPlayer)
{
	if (!targetPlayer) {
		return;
	}

	switch (GameState()) {
	/* spawn the players immediately when its in the freeze state */
	case STATE_FREEZE:
		HardRespawn(targetPlayer);

		/* we're the first people to join in this state. make them bomber, vip */
		if (targetPlayer.team == TEAM_T && teams.NumAlivePlayers(TEAM_T) == 1i) {
			if (IsBombDefusal() == true) {
				MakeBomber(targetPlayer);
			}
		} else if (targetPlayer.team == TEAM_CT && teams.NumAlivePlayers(TEAM_CT) == 1i) {
			if (IsAssassination() == true) {
				MakeVIP(targetPlayer);
			}
		}

		break;
	}

	/* if no players are present in the chosen team, force restart round */
	if (targetPlayer.team == TEAM_T && teams.NumAlivePlayers(TEAM_T) == 0i) {
		Round_Finished(TEAM_NONE, 0i, false);
	} else if (targetPlayer.team == TEAM_CT && teams.NumAlivePlayers(TEAM_CT) == 0i) {
		Round_Finished(TEAM_NONE, 0i, false);
	}
}

void
CS_PlayerRemovedFromGame(entity targetPlayer)
{
	/* In Assassination, all Terrorists receive a $2500
	 *  reward if they won by killing the VIP. */
	if (IsVIP(targetPlayer) == true) {
		Round_Finished(TEAM_T, 2500i, false);
		return;
	}

	Round_CheckUponDeath(targetPlayer);
}

void
CodeCallback_Precache(void)
{
	precache.Entity("player_vip");
	precache.Entity("player_terrorist");
	precache.Entity("player_counterterrorist");
}

/* Callbacks, functions that are called from Nuclide */
void
CodeCallback_StartGameType(void)
{
	string spawnCT;
	string spawnT;

	spawnCT = entityDef.GetString("player_counterterrorist", "spawnpoint");
	spawnT = entityDef.GetString("player_terrorist", "spawnpoint");

	/* let Nuclide decide which motd to read */
	motd.LoadDefault();

	/* the only teams CS will ever need... ? */
	teams.SetUp(TEAM_T, "Terrorist", [255, 63, 63], true);
	teams.SetSpawnPoint(TEAM_T, spawnT);
	teams.SetUp(TEAM_CT, "Counter-Terrorist", [153, 204, 255], true);
	teams.SetSpawnPoint(TEAM_CT, spawnCT);

	cvars.SetInteger("g_infiniteAmmo", 0i);

	/* evaluate our world */
	CS_CountHostages();
	CS_CountBombZones();
	CS_CountEscapeZones();
	CS_CountVIPZones();

	/* create gameplay elements on top */
	if (IsHostageRescue() == true) {
		if (exists.InMap("func_hostage_rescue") == false) {
			for (entity testEnt = world; (testEnt = find(testEnt, ::classname, spawnCT));) {
				ents.Create("info_hostage_rescue", testEnt.origin);
			}
		}
	}

	/* we don't need to create any additional CT zones. */
	if (exists.InMap("func_buyzone") == false) {
		/* since no buyzones are available, let's create one around every spawn */
		for (entity testEnt = world; (testEnt = find(testEnt, ::classname, spawnCT));) {
			entity buyZone = ents.Create("info_buyzone", testEnt.origin);
			buyZone.angles = testEnt.angles;
			buyZone.team = TEAM_CT;
		}

		for (entity testEnt = world; (testEnt = find(testEnt, ::classname, spawnT));) {
			entity buyZone = ents.Create("info_buyzone", testEnt.origin);
			buyZone.angles = testEnt.angles;
			buyZone.team = TEAM_T;
		}
	}

	for (entity spawnPoint = world;(spawnPoint = nextent(spawnPoint));) {
		switch (spawnPoint.classname) {
		case "info_player_start":
		case "trigger_camera":
		case "info_player_deathmatch":
			entity specSpawn = ents.Create("info_spectator_start", spawnPoint.origin);
			specSpawn.angles = spawnPoint.angles;
			break;
		default:
			break;
		}
	}
}

void
CodeCallback_FrameStart(void)
{
	int totalPlayers = teams.NumPlayers(TEAM_T) + teams.NumPlayers(TEAM_CT);

	/* if we suddenly have players, commence a new round. */
	if (totalPlayers > 0i && GameState() == STATE_INACTIVE) {
		Round_TimerStart(2.0f, STATE_COMMENCING);
		return;
	}

	/* if there are 0 players whatsoever, forget most state,
	   so we can commence (see above) a game later. */
	if (totalPlayers == 0i) {
		GameState_Set(STATE_INACTIVE);
		g_cs_gametime = 0.0f;
		teams.SetScore(TEAM_T, 0i);
		teams.SetScore(TEAM_CT, 0i);
		serverinfo.SetInteger("cs_roundsplayed", 0i);
		return;
	}
	

	/* should only ever run when players are actually present. */
	Round_TimerUpdate();
}

void
CodeCallback_Input(entity activator, string inputName, string dataString)
{
	switch (inputName) {
	case "BombDefused":
		/* In Bomb Defusal, all Counter-Terrorists receive $3600
		   if they won by defusing the bomb. */
		Round_Finished(TEAM_CT, 3600i, true);
		Radio_BroadcastMessage(RADIO_BOMBDEF);
		break;
	case "BombExploded":
		/* In Bomb Defusal, all Terrorists receive $3500
		   if they won by detonating the bomb. */
		Round_Finished(TEAM_T, 3500i, false);
		break;
	case "HostageContacted":
		Money_AddMoney(activator, 150i);
		break;
	case "HostageKilled":
		int damageDealt = stoi(dataString);

		if (damageDealt >= 100i) {
			Money_AddMoney(activator, -2500i);
		} else {
			Money_AddMoney(activator, -500i);
		}

		Radio_BroadcastMessage(RADIO_HOSDOWN);
		break;
	case "HostageRescued":
		Radio_BroadcastMessage(RADIO_RESCUED);
		serverinfo.SetInteger("cs_hostagesrescued", serverinfo.GetInteger("cs_hostagesrescued") + 1i);

		Money_AddMoney(activator, 1000i);
		//CSBot_HostageRescueNotify();

		/* In Hostage Rescue, all Counter-Terrorists receive an $850
		* bonus for every hostage that was rescued, even if they lose the round. */
		Money_QueTeamReward(TEAM_CT, 850i);
		break;
	case "HostageInjured":
		Money_AddMoney(activator, -(stoi(dataString) * 25i));
		break;
	case "Escaped":
		int to_escape = teams.NumPlayers(TEAM_T);

		/* don't matter when rules are not active */
		if (GameState() != STATE_ACTIVE) {
			return;
		}

		g_iEscapedTerrorists++;

		if (to_escape > 3i) {
			to_escape = 3i;
		}

		/* balancing tweak: for every escaped T, each and every CT will lose funds */
		if (cvars.GetInteger("fcs_escapepenalty") != 0i) {
			for (entity teamPlayer = world;(teamPlayer = next.Player(teamPlayer));) {
				if (teamPlayer.team == TEAM_CT) {
					Money_AddMoney(teamPlayer, cvars.GetInteger("fcs_escapepenalty"));
				}
			}
		}

		/* mark player as spectator for the end of this 'round' */
		ents.Input(activator, "Spectate", "", world);

		/* threshold has been met to trigger the end of the round */
		if (g_iEscapedTerrorists >= to_escape) {
			/* reset */
			g_iEscapedTerrorists = 0i;

			/* Ts win the round */
			Round_Finished(TEAM_T, 3600i, false);
		}
		break;
	}
}

int
CodeCallback_MaxItemPerSlot(int weaponSlot)
{
	/* grenades can have more */
	if (weaponSlot == 3) {
		return (3);
	}

	return (1);
}

void
CodeCallback_PlayerSpawn(entity playerEntity)
{
	/* first course of action is to kick players into spectator cam */
	CS_GoSpectator(playerEntity);
}

void
CodeCallback_PlayerDisconnect(entity playerEntity)
{
	/* if they leave, timeout, get kicked (or banned), we gotta know! */
	CS_PlayerRemovedFromGame(playerEntity);
}

void
CodeCallback_PlayerDamage(entity inflictor, entity attacker)
{

}

void
CodeCallback_PlayerKilled(entity playerEntity, entity inflictor, entity attacker, string weapon)
{
	combat.Obituary(playerEntity.netname, attacker.netname, weapon, "");

	/* death-counter */
	playerEntity.deaths++;

	/* update player scores */
	if (is.Player(attacker)) {
		if (playerEntity == attacker) {
			attacker.frags--;
		} else if (playerEntity.team == attacker.team) {
			attacker.frags--;
			Money_AddMoney(attacker, cvars.GetInteger("fcs_penalty_teamkill"));
		} else {
			attacker.frags++;
			Money_AddMoney(attacker, cvars.GetInteger("fcs_reward_kill"));
		}
	}

	/* scoreboard death icon */
	if (is.Player(playerEntity)) {
		userinfo.SetString(playerEntity, "*icon1", "d_skull");
		userinfo.SetString(playerEntity, "*icon1_r", "1");
		userinfo.SetString(playerEntity, "*icon1_g", "0");
		userinfo.SetString(playerEntity, "*icon1_b", "0");

		/* turn into a fake spec */
		ents.Input(playerEntity, "Spectate", "", world);
	}

	CS_PlayerRemovedFromGame(playerEntity);
}

bool
CodeCallback_CallRequestTeam(entity playerEntity, int teamNum)
{
	/* can't switch teams while we're a VIP */
	if (IsVIP(playerEntity) == true) {
		return (false);
	}

	/* can't switch teams while alive. */
	if (is.Alive(playerEntity) == true) {
		ents.Input(playerEntity, "Kill", "", playerEntity);
	}

	/* sanity check, invalid team ID? auto team! */
	if (teamNum != TEAM_CT && teamNum != TEAM_T) {
		teamNum = teams.BestAutoJoinTeam();
	}

	switch (teamNum) {
	case TEAM_T:
		ents.Input(playerEntity, "SetTeam", "1", playerEntity);
		break;
	case TEAM_CT:
		ents.Input(playerEntity, "SetTeam", "2", playerEntity);
		break;
	default:
		CS_GoSpectator(playerEntity);
		return (true);
	}

	return (true);
}

bool
CodeCallback_ClientCommand(entity playerEntity, string command)
{
	float commandArgs = tokenize(command);

	switch (argv(0)) {
	case "timeleft":
	{
		float tl = TimeLimit() > 0 ? (TimeLimit() - time) : 0;
		if (tl < 0) tl = 0;
		int mins = (int)floor(tl / 60);
		int secs = (int)floor(tl) % 60;
		if (TimeLimit() <= 0)
			bprint(PRINT_CHAT, "No time limit set.\n");
		else if (g_cs_mapChangeRequested)
			bprint(PRINT_CHAT, sprintf("Map will change after this round. (%d:%02d over limit)\n", mins, secs));
		else
			bprint(PRINT_CHAT, sprintf("Time remaining: %d:%02d\n", mins, secs));
		return (true);
	}
	/* class selection */
	case "terror":
		SetTClass(playerEntity, 1);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_T);
		CS_RequestSpawn(playerEntity);
		break;
	case "leet":
		SetTClass(playerEntity, 2);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_T);
		CS_RequestSpawn(playerEntity);
		break;
	case "arctic":
		SetTClass(playerEntity, 3);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_T);
		CS_RequestSpawn(playerEntity);
		break;
	case "guerilla":
		SetTClass(playerEntity, 4);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_T);
		CS_RequestSpawn(playerEntity);
		break;
	case "urban":
		SetCTClass(playerEntity, 1);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_CT);
		CS_RequestSpawn(playerEntity);
		break;
	case "gsg9":
		SetCTClass(playerEntity, 2);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_CT);
		CS_RequestSpawn(playerEntity);
		break;
	case "sas":
		SetCTClass(playerEntity, 3);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_CT);
		CS_RequestSpawn(playerEntity);
		break;
	case "gign":
		SetCTClass(playerEntity, 4);
		CodeCallback_CallRequestTeam(playerEntity, TEAM_CT);
		CS_RequestSpawn(playerEntity);
		break;
	case "buy":
		Money_Purchase(playerEntity, argv(1));
		break;
	case "buyammo":
		Money_PurchaseAmmoForSlot(playerEntity, stoi(argv(1)));
		break;
	default:
		return (false);
	}

	return (true);
}

bool
CodeCallback_ImpulseCommand(entity playerEntity, float impulseNum)
{
	switch (impulseNum) {
	/* this is how Half-Life triggers the flashlight. `impulse 100`. */
	case 100:
		if (AllowFlashlight() == true) {
			ents.Input(playerEntity, "UseItem", "item_suit", playerEntity);
		}
		break;
	default:
		return (false);
	}

	return (true);
}
