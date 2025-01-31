/*
 * Copyright (c) 2024 Marco Cawthorne <marco@icculus.org>
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

#pragma PROGS_DAT  "../../progs/deathmatch.dat"

#include "../../../src/server/api.h"

bool
IsTeamplay(void)
{
	return cvars.GetBool("mp_teamplay");
}

bool
AllowFlashlight(void)
{
	return cvars.GetBool("mp_flashlight");
}

void
CodeCallback_StartGameType(void)
{
	motd.LoadDefault();

	if (IsTeamplay() == true) {
		teams.SetUp(1, "Terrorist", [153, 204, 255], true);
		teams.SetSpawnPoint(1, "info_player_deathmatch");
		teams.SetUp(2, "Counter-Terrorist", [255, 63, 63], true);
		teams.SetSpawnPoint(2, "info_player_deathmatch");
	} else {
		game.SetSpawnPoint("info_player_deathmatch");
	}
}

void
HLDM_PlayerSpawn(entity playerEntity)
{
	string playerModel;

	ents.ChangeToClass(playerEntity, "player_csdm");

	if (IsTeamplay() == true) {
		float teamCount = 2;
		float playerTeam = playerEntity.team;
		string teamModel;

		/* not part of a team? pick one of the ones we have */
		/* TODO: this should sort us into the lowest team */
		if (playerTeam == 0) {
			playerTeam = 1 + floor(random(0, teamCount)); /* teams start at 1 after all */
			ents.Input(playerEntity, "SetTeam", ftos(playerTeam), playerEntity);
		}

		teamModel = argv(playerTeam - 1);
		playerModel = sprintf("models/player/%s/%s.mdl", teamModel, teamModel);
	} else {
		/* interpret the 'model' InfoKey */
		playerModel = userinfo.GetString(playerEntity, "model");

		if (playerModel != "") {
			playerModel = sprintf("models/player/%s/%s.mdl", playerModel, playerModel);
		}
	}

	/* fallback is always models/player.mdl for Half-Life */
	if (playerModel == "" || exists.InVFS(playerModel) == false) {
		playerModel = "models/player.mdl";
	}

	playerEntity.modelindex = getmodelindex(playerModel); /* keep OG size */
	game.TeleportToSpawn(playerEntity);
}

void
CodeCallback_PlayerSpawn(entity playerEntity)
{
	if (IsTeamplay() == false) {
		HLDM_PlayerSpawn(playerEntity);
	} else {
		ents.ChangeToClass(playerEntity, "spectator");
		game.TeleportToSpawn(playerEntity);
	}
}


void
CodeCallback_PlayerDisconnect(entity playerEntity)
{

}

bool
CodeCallback_PlayerRequestRespawn(entity playerEntity)
{
	CodeCallback_PlayerSpawn(playerEntity);
	return (true);
}

void
CodeCallback_PlayerDamage(entity playerEntity, entity inflictor, entity attacker)
{

}

bool
CodeCallback_CallRequestTeam(entity playerEntity, int teamNum)
{
	ents.Input(playerEntity, "SetTeam", itos(teamNum), playerEntity);
	ents.Input(playerEntity, "Damage", "1000", playerEntity);
	return (true);
}

void
CodeCallback_PlayerKilled(entity playerEntity, entity inflictor, entity attacker, string weapon)
{
	combat.Obituary(playerEntity.netname, attacker.netname, weapon, "");

	/* death-counter */
	playerEntity.deaths++;

	/* update score-counter */
	if (ents.isPlayer(attacker)) {
		if (playerEntity == attacker) {
			attacker.frags--;
		} else {
			attacker.frags++;
		}
	}
}

bool
CodeCallback_ClientCommand(entity playerEntity, string command)
{
	float commandArgs = tokenize(command);

	switch (argv(0)) {
	default:
		return (false);
	}

	return (true);
}

bool
CodeCallback_ImpulseCommand(entity playerEntity, float impulseNum)
{
	switch (impulseNum) {
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
