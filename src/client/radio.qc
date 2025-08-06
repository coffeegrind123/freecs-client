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

string g_cstrikeRadioWAVs[43] = {
	"blow.wav",
	"bombdef.wav",
	"bombpl.wav",
	"circleback.wav",
	"clear.wav",
	"com_followcom.wav",
	"com_getinpos.wav",
	"com_go.wav",
	"com_reportin.wav",
	"ct_affirm.wav",
	"ct_backup.wav",
	"ct_coverme.wav",
	"ct_enemys.wav",
	"ct_fireinhole.wav",
	"ct_imhit.wav",
	"ct_inpos.wav",
	"ct_point.wav",
	"ct_reportingin.wav",
	"ctwin.wav",
	"enemydown.wav",
	"fallback.wav",
	"fireassis.wav",
	"followme.wav",
	"getout.wav",
	"go.wav",
	"hitassist.wav",
	"hosdown.wav",
	"letsgo.wav",
	"locknload.wav",
	"matedown.wav",
	"meetme.wav",
	"moveout.wav",
	"negative.wav",
	"position.wav",
	"regroup.wav",
	"rescued.wav",
	"roger.wav",
	"rounddraw.wav",
	"sticktog.wav",
	"stormfront.wav",
	"takepoint.wav",
	"terwin.wav",
	"vip.wav"
};

string g_cstrikeRadioChat[43] = {
	"BLOW",
	"BOMBDEF",
	"BOMBPL",
	"CIRCLEBACK",
	"CLEAR",
	"COM_FOLLOWCOM",
	"COM_GETINPOS",
	"COM_GO",
	"COM_REPORTIN",
	"CT_AFFIRM",
	"CT_BACKUP",
	"CT_COVERME",
	"CT_ENEMYS",
	"CT_FIREINHOLE",
	"CT_IMHIT",
	"CT_INPOS",
	"CT_POINT",
	"CT_REPORTINGIN",
	"CTWIN",
	"ENEMYDOWN",
	"FALLBACK",
	"FIREASSIS",
	"FOLLOWME",
	"GETOUT",
	"GO",
	"HITASSIST",
	"HOSDOWN",
	"LETSGO",
	"LOCKNLOAD",
	"MATEDOWN",
	"MEETME",
	"MOVEOUT",
	"NEGATIVE",
	"POSITION",
	"REGROUP",
	"RESCUED",
	"ROGER",
	"ROUNDDRAW",
	"STICKTOG",
	"STORMFRONT",
	"TAKEPOINT",
	"TERWIN",
	"VIP",
};

void
Radio_Init(void)
{
	for (int i = 0; i < g_cstrikeRadioWAVs.length; i++)
		precache_sound(strcat("radio/", g_cstrikeRadioWAVs[i]));
}

/*
=================
Radio_PlayMessage

Play a radio message that doesn't come from a player
=================
*/
void
Radio_PlayMessage(float fMessage)
{
	string localizedRadioMessage = localize(strcat("#RADIO_", g_cstrikeRadioChat[fMessage]));
	string messageSound = strcat("radio/", g_cstrikeRadioWAVs[fMessage]);

	sound(world, CHAN_VOICE, messageSound, 1, ATTN_NONE, 0, SOUNDFLAG_NOSPACIALISE);

	if (fMessage == RADIO_CTWIN || fMessage == RADIO_TERWIN || fMessage == RADIO_ROUNDDRAW) {
		CSQC_Parse_CenterPrint(sprintf("%s", localizedRadioMessage));
	} else {
		CSQC_Parse_Print(sprintf("^2[RADIO]^xF80: %s", localizedRadioMessage), PRINT_CHAT);
	}
}

/*
=================
Radio_PlayPlayerMessage

This radio message does come from a player
=================
*/
void
Radio_PlayPlayerMessage(float fPlayerNum, float fMessage)
{
	string localizedRadioMessage = localize(strcat("#RADIO_", g_cstrikeRadioChat[fMessage]));
	string messageSound = strcat("radio/", g_cstrikeRadioWAVs[fMessage]);

	sound(world, CHAN_VOICE, messageSound, 1, ATTN_NONE, 0, SOUNDFLAG_NOSPACIALISE);
	CSQC_Parse_Print(sprintf("^2[RADIO] %s%s^xF80: %s", HUD_GetChatColorHEX(stof(getplayerkeyvalue(fPlayerNum, "*team"))), getplayerkeyvalue(fPlayerNum, "name"), localizedRadioMessage), PRINT_CHAT);
}
