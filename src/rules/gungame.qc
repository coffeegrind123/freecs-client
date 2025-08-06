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

/* loosely based on GunGame, which was an idea by cagemonkey and originally written by teame06 */

#ifdef NOVO
var string autocvar_gg_weapon_order = "usp,p228,deagle,fiveseven,elite,m3,xm1014,tmp,mac10,mp5navy,ump45,p90,galil,famas,ak47,scout,m4a1,awp,sg552,g3sg1,aug,m249,hegrenade,knife";
#else
var string autocvar_gg_weapon_order = "usp,p228,deagle,fiveseven,elite,m3,xm1014,tmp,mac10,mp5navy,ump45,p90,ak47,scout,m4a1,awp,sg552,g3sg1,aug,m249,hegrenade,knife";
#endif

var int autocvar_gg_killsPerLevel = 3i;

var string g_gunGameWeaponOrder;
var int g_gunGameWeaponCount;

.float gg_score;
.float gg_level;


bool
AllowFlashlight(void)
{
	return cvars.GetBool("mp_flashlight");
}

float
GunGame_RandomModel(void)
{
#ifdef NOVO
	/* FIXME: increment this, once we added more classes */
	string keyName = sprintf("model_class%d", floor(random(1, 5)));
#else
	string keyName = sprintf("model_class%d", floor(random(1, 5)));
#endif

	if (random() < 0.5) {
		return getmodelindex(entityDef.GetString("player_counterterrorist", keyName));
	} else {
		return getmodelindex(entityDef.GetString("player_terrorist", keyName));
	}
}

string
GunGame_WeaponForScore(float gunGameScore)
{
	if (gunGameScore >= g_gunGameWeaponCount) {
		return "";
	}

	int orderCount = tokenizebyseparator(g_gunGameWeaponOrder, ",");
	return strcat("weapon_", argv(gunGameScore));
}

void
CodeCallback_Precache(void)
{
	precache.Entity("player_csdm");
	precache.Entity("csdm_spawnpoint");
}

void
CodeCallback_StartGameType(void)
{
	motd.LoadDefault();

	game.SetSpawnPoint("csdm_spawnpoint");

	g_gunGameWeaponOrder = autocvar_gg_weapon_order;
	g_gunGameWeaponCount = tokenizebyseparator(g_gunGameWeaponOrder, ",");

	cvars.SetInteger("g_infiniteAmmo", 2i);
}

void
HLDM_PlayerSpawn(entity playerEntity)
{
	string playerModel;

	ents.ChangeToClass(playerEntity, "player_gungame");
	playerEntity.modelindex = GunGame_RandomModel();
	game.TeleportToSpawn(playerEntity);

	string weaponToGive = GunGame_WeaponForScore(playerEntity.gg_level);
	
	if (STRING_SET(weaponToGive)) {
		ents.Input(playerEntity, "RemoveActiveWeapon", "", world);
		ents.Input(playerEntity, "GiveItem", weaponToGive, world);
	}
}

void
CodeCallback_PlayerSpawn(entity playerEntity)
{
	HLDM_PlayerSpawn(playerEntity);
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
	if (is.Player(attacker)) {
		if (playerEntity == attacker) {
			attacker.frags--;
			attacker.gg_level--;
			attacker.gg_score = 0;

			if (attacker.gg_level < 0) {
				attacker.gg_level = 0;
			}
		} else {
			attacker.frags++;
			attacker.gg_score++;
			
			if (attacker.gg_score >= autocvar_gg_killsPerLevel) {
				attacker.gg_level++;
				attacker.gg_score = 0;

				/* kill gets rewarded with a new weapon */
				string weaponToGive = GunGame_WeaponForScore(attacker.gg_level);
			
				if (STRING_SET(weaponToGive)) {
					ents.Input(attacker, "RemoveActiveWeapon", "", world);
					ents.Input(attacker, "GiveItem", weaponToGive, world);
					printf("Giving %s a %s\n", attacker.netname, weaponToGive);
				} else {
					game.EndMap();
				}
			}
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
