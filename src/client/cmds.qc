/*
 * Copyright (c) 2016-2023 Marco Cawthorne <marco@icculus.org>
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

void CSVGUI_ChooseTeam(void);
void CSVGUI_BuyMenu(void);
void CSVGUI_ShowMOTD(void);

void
CMD_ChooseTeam(void)
{
	if (serverkeyfloat("sv_playerslots") <= 1)
		return;

	/* handle both VGUI and text menus */
	if (ClientGame_IsUsingVGUI())
		CSVGUI_ChooseTeam();
	else
		Textmenu_Toggle("TEAM_SELECT");
}

void
CMD_BuyMenu(void)
{
	CSPlayer pl = (CSPlayer)pSeat->m_ePlayer;

	/* only in buy zones... */
	if (!(pl.gflags & GF_BUYZONE)) {
		return;
	}

	/* handle both VGUI and text menus */
	if (ClientGame_IsUsingVGUI())
		CSVGUI_BuyMenu();
	else
		Textmenu_Toggle("BUY");
}

int
ClientGame_ConsoleCommand(void)
{
	switch(argv(0)) {
	case "showTeamSelectionMenu":
	case "chooseteam":
		CMD_ChooseTeam();
		break;
	case "buy":
		CMD_BuyMenu();
		break;
	case "showMOTD":
		CSVGUI_ShowMOTD();
		break;
	case "radio1":
		Textmenu_Toggle("RADIOA");
		break;
	case "radio2":
		Textmenu_Toggle("RADIOB");
		break;
	case "radio3":
		Textmenu_Toggle("RADIOC");
		break;
	case "nightvision":
		Nightvision_Toggle();
		break;
	case "drop":
		sendevent("DropWeapon", "");
		break;

	default:
		return (0);
	}
	return (1);
}
