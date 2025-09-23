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
//#if defined(CZERO) || defined(CSSOURCE)
#if 1
	return true;
#else
	if (getplayerkeyvalue(player_localnum, "vgui_menus") == "0")
		return true;
	if (getplayerkeyvalue(player_localnum, "_vgui_menus") == "0")
		return true;

	return false;
#endif
}

void
ClientGame_InitDone(void)
{
}

void
ClientGame_RendererRestart(string rstr)
{
	FX_Smokenade_Init();
	Radar_Init();
	font.Load("fonts/scoreboard.font", FONT_SCOREBOARD);
	font.Load("fonts/scores_norm.font", FONT_SCORES_NORMAL);
	font.Load("fonts/scores_bold.font", FONT_SCORES_BOLD);
}
