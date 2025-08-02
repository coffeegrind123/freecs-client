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

/*
=================
ClientGame_Init

Comparable to worldspawn in SSQC in that it's mostly used for precaches
=================
*/
void
ClientGame_Init(float apilevel, string enginename, float engineversion)
{
	registercommand("chooseteam");
	registercommand("buy");

	/* radio */
	registercommand("radio1");
	registercommand("radio2");
	registercommand("radio3");

	registercommand("motd");
	registercommand("drop");
	registercommand("nightvision");

	/* hud */
	registercommand("lastinv");
	registercommand("invnext");
	registercommand("invprev");

	SoundDef_Precache("nvg.on");
	SoundDef_Precache("nvg.off");
}

bool
ClientGame_IsUsingVGUI(void)
{
#if defined(CZERO) || defined(CSSOURCE)
	return true;
#else
	/* FTE has a bug with _ infokeys, so we'll accept both formats in case
	   that gets fixed in the future :/ */
	if (getplayerkeyfloat(player_localnum, "vgui_menus") == 1)
		return true;
	if (getplayerkeyfloat(player_localnum, "_vgui_menus") == 1)
		return true;

	return false;
#endif
}

void CMD_ChooseTeam(void);
void
ClientGame_InitDone(void)
{
	//CSVGUI_ChooseTeam();
}

void
ClientGame_RendererRestart(string rstr)
{
	g_cs_cross = spriteframe("sprites/crosshairs.spr", 0, 0.0f);
	g_cs_scope0 = spriteframe("sprites/sniper_scope.spr", 0, 0.0f);
	g_cs_scope1 = spriteframe("sprites/top_left.spr", 0, 0.0f);
	g_cs_scope2 = spriteframe("sprites/top.spr", 0, 0.0f);
	g_cs_scope3 = spriteframe("sprites/top_right.spr", 0, 0.0f);
	g_cs_scope4 = spriteframe("sprites/left.spr", 0, 0.0f);
	g_cs_scope5 = spriteframe("sprites/right.spr", 0, 0.0f);
	g_cs_scope6 = spriteframe("sprites/bottom_left.spr", 0, 0.0f);
	g_cs_scope7 = spriteframe("sprites/bottom.spr", 0, 0.0f);
	g_cs_scope8 = spriteframe("sprites/bottom_right.spr", 0, 0.0f);


	FX_Smokenade_Init();
	Radar_Init();
	font.Load("fonts/scoreboard.font", FONT_SCOREBOARD);
}
