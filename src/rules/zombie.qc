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

void
WaveTimer_Tick(void)
{
	int monsterCount = actor.TotalActors();

	/* spawn a new monster */
	if (monsterCount < 5) {
		entity zombie = ents.Create("npc_zombie", [0,0,0]);
		game.TeleportToSpawn(zombie);
		ents.Input(zombie, "HordeOn", "", world);
	}

	self.nextthink = time + 2.0f;
}

bool
AllowFlashlight(void)
{
	return cvars.GetBool("mp_flashlight");
}

void
CodeCallback_StartGameType(void)
{
	precache.Entity("npc_zombie");
	precache.Entity("player_csdm");
	motd.LoadDefault();
	game.SetSpawnPoint("info_player_deathmatch");
	teams.SetUp(1, "Players", [255, 255, 255], false);
	teams.SetUp(2, "Zombies", [255, 0, 0], false);
	teams.SetSpawnPoint(1, "info_player_deathmatch");
	teams.SetSpawnPoint(2, "info_player_deathmatch");

	entity tick = spawn();
	tick.think = WaveTimer_Tick;
	tick.nextthink = time + 1.0f;
}

void
CodeCallback_PlayerSpawn(entity playerEntity)
{
	ents.ChangeToClass(playerEntity, "player_csdm");
	ents.Input(playerEntity, "SetTeam", "1", world);
	playerEntity.modelindex = getmodelindex("models/player.mdl"); /* keep OG size */
	game.TeleportToSpawn(playerEntity);
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

void
CodeCallback_PlayerKilled(entity playerEntity, entity inflictor, entity attacker, string weapon)
{
	combat.Obituary(playerEntity.netname, attacker.netname, weapon, "");

	/* death-counter */
	playerEntity.deaths++;

	/* update score-counter */
	if (is.Player(attacker)) {
		if (playerEntity == attacker) {
			attacker.frags--;
		} else {
			attacker.frags++;
		}
	} else if (is.Sentient(attacker)) {
		teams.AddScore(attacker.team, 1);
	}
}

void
CodeCallback_NPCKilled(entity npcEntity, entity inflictor, entity attacker, string weapon)
{
	combat.Obituary(npcEntity.netname, attacker.netname, weapon, "");

	/* update score-counter */
	if (is.Player(attacker)) {
		if (npcEntity == attacker) {
			attacker.frags--;
		} else {
			attacker.frags++;
		}
	}
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
