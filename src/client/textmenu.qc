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
TEAM_SELECT(int n)
{
	switch (n) {
	case 1:
		Textmenu_Call("TERRORIST_SELECT");
		localcmd("cmd joinTeam 1\n");
		break;
	case 2:
		Textmenu_Call("CT_SELECT");
		localcmd("cmd joinTeam 2\n");
		break;
	case 5:
		localcmd("cmd joinTeam 9\n");
		Textmenu_Call("");
		break;
	}
}
void
TERRORIST_SELECT(int n)
{
	if (n == 5)
		n = floor(random(1, 5));

	switch (n) {
	case 1:
		localcmd("cmd terror\n");
		Textmenu_Call("");
		break;
	case 2:
		localcmd("cmd leet\n");
		Textmenu_Call("");
		break;
	case 3:
		localcmd("cmd arctic\n");
		Textmenu_Call("");
		break;
	case 4:
		localcmd("cmd guerilla\n");
		Textmenu_Call("");
		break;
	}
}
void
CT_SELECT(int classSelection)
{
	if (classSelection == 5)
		classSelection = floor(random(1, 5));

	switch (classSelection) {
	case 1:
		localcmd("cmd urban\n");
		Textmenu_Call("");
		break;
	case 2:
		localcmd("cmd gsg9\n");
		Textmenu_Call("");
		break;
	case 3:
		localcmd("cmd sas\n");
		Textmenu_Call("");
		break;
	case 4:
		localcmd("cmd gign\n");
		Textmenu_Call("");
		break;
	}
}

void
BUY(int n)
{
	csPlayer pl;
	pl = (csPlayer)pSeat->m_ePlayer;
	int inteam = getplayerkeyfloat(pl.entnum-1, "*team");

	switch (n) {
	case 1:
		Textmenu_Call(inteam == TEAM_T ? "T_BUYPISTOL" : "CT_BUYPISTOL");
		break;
	case 2:
		Textmenu_Call("BUYSHOTGUN");
		break;
	case 3:
		Textmenu_Call(inteam == TEAM_T ? "T_BUYSUBMACHINEGUN" : "CT_BUYSUBMACHINEGUN");
		break;
	case 4:
		Textmenu_Call(inteam == TEAM_T ? "T_BUYRIFLE" : "CT_BUYRIFLE");
		break;
	case 5:
		Textmenu_Call(inteam == TEAM_T ? "BUYMACHINEGUN" : "BUYMACHINEGUN");
		break;
	case 6:
		sendevent("CSBuy", "f", BUY_PRIMARYAMMO);
		Textmenu_Call("");
		break;
	case 7:
		sendevent("CSBuy", "f", BUY_SECONDARYAMMO);
		Textmenu_Call("");
		break;
	case 8:
		Textmenu_Call(inteam == TEAM_T ? "DT_BUYITEM" : "DCT_BUYITEM");
		break;
	case 10:
		Textmenu_Call("");
		break;
	}
}

/* Equipment */
void
DT_BUYITEM(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_VEST);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_VESTHELMET);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_FLASHBANG);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_HEGRENADE);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_SMOKEGRENADE);
		break;
	case 7:
		sendevent("CSBuy", "f", BUY_NIGHTVISION);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}
void
DCT_BUYITEM(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_VEST);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_VESTHELMET);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_FLASHBANG);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_HEGRENADE);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_SMOKEGRENADE);
		break;
	case 6:
		sendevent("CSBuy", "f", BUY_DEFUSALKIT);
		break;
	case 7:
		sendevent("CSBuy", "f", BUY_NIGHTVISION);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* Handguns */
void
T_BUYPISTOL(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_USP45);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_GLOCK18);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_DEAGLE);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_P228);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_ELITES);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}
void
CT_BUYPISTOL(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_USP45);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_GLOCK18);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_DEAGLE);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_P228);
		break;
	case 6:
		sendevent("CSBuy", "f", BUY_FIVESEVEN);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* Shotguns */
void
BUYSHOTGUN(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_M3);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_XM1014);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* Rifles, Sniper */
void
T_BUYRIFLE(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_AK47);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_SG552);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_SCOUT);
		break;
	case 6:
		sendevent("CSBuy", "f", BUY_AWP);
		break;
	case 7:
		sendevent("CSBuy", "f", BUY_G3SG1);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}
void
CT_BUYRIFLE(int n)
{
	switch (n) {
	case 3:
		sendevent("CSBuy", "f", BUY_M4A1);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_AUG);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_SCOUT);
		break;
	case 6:
		sendevent("CSBuy", "f", BUY_AWP);
		break;
	case 7:
		sendevent("CSBuy", "f", BUY_G3SG1);
		break;
	case 8:
		sendevent("CSBuy", "f", BUY_SG550);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* SMGs */
void
T_BUYSUBMACHINEGUN(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_MP5);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_P90);
		break;
	case 4:
		sendevent("CSBuy", "f", BUY_MAC10);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_UMP45);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}
void
CT_BUYSUBMACHINEGUN(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_MP5);
		break;
	case 2:
		sendevent("CSBuy", "f", BUY_TMP);
		break;
	case 3:
		sendevent("CSBuy", "f", BUY_P90);
		break;
	case 5:
		sendevent("CSBuy", "f", BUY_UMP45);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* Big and heavy */
void
BUYMACHINEGUN(int n)
{
	switch (n) {
	case 1:
		sendevent("CSBuy", "f", BUY_PARA);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

/* Radio */
void
RADIOA(int n)
{
	switch (n) {
	case 1:
		sendevent("Radio", "f", RADIO_CT_COVERME);
		break;
	case 2:
		sendevent("Radio", "f", RADIO_TAKEPOINT);
		break;
	case 3:
		sendevent("Radio", "f", RADIO_POSITION);
		break;
	case 4:
		sendevent("Radio", "f", RADIO_REGROUP);
		break;
	case 5:
		sendevent("Radio", "f", RADIO_FOLLOWME);
		break;
	case 6:
		sendevent("Radio", "f", RADIO_FIREASSIS);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

void
RADIOB(int n)
{
	switch (n) {
	case 1:
		sendevent("Radio", "f", RADIO_COM_GO);
		break;
	case 2:
		sendevent("Radio", "f", RADIO_FALLBACK);
		break;
	case 3:
		sendevent("Radio", "f", RADIO_STICKTOG);
		break;
	case 4:
		sendevent("Radio", "f", RADIO_COM_GETINPOS);
		break;
	case 5:
		sendevent("Radio", "f", RADIO_STORMFRONT);
		break;
	case 6:
		sendevent("Radio", "f", RADIO_COM_REPORTIN);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}

void
RADIOC(int n)
{
	switch (n) {
	case 1:
		sendevent("Radio", "f", RADIO_CT_AFFIRM);
		break;
	case 2:
		sendevent("Radio", "f", RADIO_CT_ENEMYS);
		break;
	case 3:
		sendevent("Radio", "f", RADIO_CT_BACKUP);
		break;
	case 4:
		sendevent("Radio", "f", RADIO_CLEAR);
		break;
	case 5:
		sendevent("Radio", "f", RADIO_CT_INPOS);
		break;
	case 6:
		sendevent("Radio", "f", RADIO_CT_REPORTINGIN);
		break;
	case 7:
		sendevent("Radio", "f", RADIO_BLOW);
		break;
	case 8:
		sendevent("Radio", "f", RADIO_NEGATIVE);
		break;
	case 9:
		sendevent("Radio", "f", RADIO_ENEMYDOWN);
		break;
	case 10:
		Textmenu_Call("");
		break;
	default:
		return;
	}

	Textmenu_Call("");
}
