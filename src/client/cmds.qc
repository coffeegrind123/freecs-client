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

void VGUI_ChooseTeam(void);
void VGUI_BuyMenu(void);
void HUD_DrawWeaponSelect_Back(void);
void HUD_DrawWeaponSelect_Forward(void);
void HUD_DrawWeaponSelect_Last(void);
void HUD_SlotSelect(int);

void
CMD_ChooseTeam(void)
{
	if (serverkeyfloat("sv_playerslots") <= 1)
		return;

	/* handle both VGUI and text menus */
	if (ClientGame_IsUsingVGUI())
		VGUI_ChooseTeam();
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
		VGUI_BuyMenu();
	else
		Textmenu_Toggle("BUY");
}

int
ClientGame_ConsoleCommand(void)
{
	switch(argv(0)) {
	case "invnext":
		HUD_DrawWeaponSelect_Back();
		break;
	case "invprev":
		HUD_DrawWeaponSelect_Forward();
		break;
	case "lastinv":
		HUD_DrawWeaponSelect_Last();
		break;
	case "slot1":
		HUD_SlotSelect(0);
		break;
	case "slot2":
		HUD_SlotSelect(1);
		break;
	case "slot3":
		HUD_SlotSelect(2);
		break;
	case "slot4":
		HUD_SlotSelect(3);
		break;
	case "slot5":
		HUD_SlotSelect(4);
		break;
	case "slot6":
		HUD_SlotSelect(5);
		break;
	case "slot7":
		HUD_SlotSelect(6);
		break;
	case "slot8":
		HUD_SlotSelect(7);
		break;
	case "slot9":
		HUD_SlotSelect(8);
		break;
	case "slot10":
		HUD_SlotSelect(9);
		break;
	case "chooseteam":
		CMD_ChooseTeam();
		break;
	case "buy":
		CMD_BuyMenu();
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
	case "glock":
		sendevent("CSBuy", "f", BUY_GLOCK18);
		break;
	case "usp":
		sendevent("CSBuy", "f", BUY_USP45);
		break;
	case "p228":
		sendevent("CSBuy", "f", BUY_P228);
		break;
	case "deagle":
		sendevent("CSBuy", "f", BUY_DEAGLE);
		break;
	case "fn57":
		sendevent("CSBuy", "f", BUY_FIVESEVEN);
		break;
	case "elites":
		sendevent("CSBuy", "f", BUY_ELITES);
		break;
	case "m3":
		sendevent("CSBuy", "f", BUY_M3);
		break;
	case "xm1014":
		sendevent("CSBuy", "f", BUY_XM1014);
		break;
	case "tmp":
		sendevent("CSBuy", "f", BUY_TMP);
		break;
	case "mac10":
		sendevent("CSBuy", "f", BUY_MAC10);
		break;
	case "mp5":
		sendevent("CSBuy", "f", BUY_MP5);
		break;
	case "ump45":
		sendevent("CSBuy", "f", BUY_UMP45);
		break;
	case "p90":
		sendevent("CSBuy", "f", BUY_P90);
		break;
	case "ak47":
		sendevent("CSBuy", "f", BUY_AK47);
		break;
	case "m4a1":
		sendevent("CSBuy", "f", BUY_M4A1);
		break;
	case "sg552":
		sendevent("CSBuy", "f", BUY_SG552);
		break;
	case "aug":
		sendevent("CSBuy", "f", BUY_AUG);
		break;
	case "scout":
		sendevent("CSBuy", "f", BUY_SCOUT);
		break;
	case "sg550":
		sendevent("CSBuy", "f", BUY_SG550);
		break;
	case "awp":
		sendevent("CSBuy", "f", BUY_AWP);
		break;
	case "g3sg1":
		sendevent("CSBuy", "f", BUY_G3SG1);
		break;
	case "m249":
		sendevent("CSBuy", "f", BUY_PARA);
		break;
	case "buyammo1":
	case "primammo":
		sendevent("CSBuy", "f", BUY_PRIMARYAMMO);
		break;
	case "buyammo2":
	case "secammo":
		sendevent("CSBuy", "f", BUY_SECONDARYAMMO);
		break;
	case "vest":
		sendevent("CSBuy", "f", BUY_VEST);
		break;
	case "vesthelm":
		sendevent("CSBuy", "f", BUY_VESTHELMET);
		break;
	case "flash":
		sendevent("CSBuy", "f", BUY_FLASHBANG);
		break;
	case "hegren":
		sendevent("CSBuy", "f", BUY_HEGRENADE);
		break;
	case "vsgren":
		sendevent("CSBuy", "f", BUY_SMOKEGRENADE);
		break;
	case "defuser":
		sendevent("CSBuy", "f", BUY_DEFUSALKIT);
		break;
	case "nvg":
		sendevent("CSBuy", "f", BUY_NIGHTVISION);
		break;
	case "coverme":
		sendevent("Radio", "f", RADIO_CT_COVERME);
		break;
	case "takepoint":
		sendevent("Radio", "f", RADIO_CT_POINT);
		break;
	case "takepoint":
		sendevent("Radio", "f", RADIO_POSITION);
		break;
	case "regroup":
		sendevent("Radio", "f", RADIO_REGROUP);
		break;
	case "followme":
		sendevent("Radio", "f", RADIO_FOLLOWME);
		break;
	case "takingfire":
		sendevent("Radio", "f", RADIO_FIREASSIS);
		break;
	case "go":
		sendevent("Radio", "f", RADIO_GO);
		break;
	case "fallback":
		sendevent("Radio", "f", RADIO_FALLBACK);
		break;
	case "sticktog":
		sendevent("Radio", "f", RADIO_STICKTOG);
		break;
	case "getinpos":
		sendevent("Radio", "f", RADIO_COM_GETINPOS);
		break;
	case "stormfront":
		sendevent("Radio", "f", RADIO_STORMFRONT);
		break;
	case "report":
		sendevent("Radio", "f", RADIO_COM_REPORTIN);
		break;
	case "roger":
		sendevent("Radio", "f", RADIO_ROGER);
		break;
	case "enemyspot":
		sendevent("Radio", "f", RADIO_CT_ENEMYS);
		break;
	case "needbackup":
		sendevent("Radio", "f", RADIO_CT_BACKUP);
		break;
	case "sectorclear":
		sendevent("Radio", "f", RADIO_CLEAR);
		break;
	case "inposition":
		sendevent("Radio", "f", RADIO_CT_INPOS);
		break;
	case "reportingin":
		sendevent("Radio", "f", RADIO_CT_REPORTINGIN);
		break;
	case "getout":
		sendevent("Radio", "f", RADIO_GETOUT);
		break;
	case "negative":
		sendevent("Radio", "f", RADIO_NEGATIVE);
		break;
	case "enemydown":
		sendevent("Radio", "f", RADIO_ENEMYDOWN);
		break;
	default:
		return (0);
	}
	return (1);
}
