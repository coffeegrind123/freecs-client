/*
 * Copyright (c) 2016-2020 Marco Cawthorne <marco@icculus.org>
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
Game_InitRules(void)
{
	if (cvar("sv_playerslots") == 1 || cvar("coop") == 1) {
			g_grMode = NSGameRules::InitFromProgs("progs/singleplayer.dat");
	} else {
		if (cvar("fcs_deathmatch") == 1) {
			g_grMode = NSGameRules::InitFromProgs("progs/deathmatch.dat");
		} else {
			g_grMode = NSGameRules::InitFromProgs("progs/counterstrike.dat");
		}
	}
}

void
Game_Worldspawn(void)
{
	precache_sound("weapons/ric_metal-2.wav");
	precache_sound("player/pl_pain2.wav");
	precache_sound("player/pl_pain4.wav");
	Sound_Precache("buy.kevlar");
	Sound_Precache("buy.weapon");
	Sound_Precache("buy.ammo");
	Sound_Precache("player.headshot");
	Sound_Precache("player.hitarmor");
	Sound_Precache("player.headshotarmor");
	Sound_Precache("Player.FlashLightOff");
	Sound_Precache("Player.FlashLightOn");

	FX_Corpse_Init();
}
