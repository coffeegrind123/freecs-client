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
Radio_BroadcastMessage

A global radio message for all players
=================
*/
void
Radio_BroadcastMessage(float fMessage)
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EV_RADIOMSG);
	WriteByte(MSG_MULTICAST, fMessage);
	msg_entity = self;
	multicast([0,0,0], MULTICAST_ALL);
}

/*
=================
Radio_TeamMessage

A radio message targetted at members of a specific team
=================
*/
void
Radio_TeamMessage(float fMessage, float fTeam)
{
	static void Radio_TeamMessage_Send(float fMessage, entity eEnt) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RADIOMSG);
		WriteByte(MSG_MULTICAST, fMessage);
		msg_entity = eEnt;
		multicast([0,0,0], MULTICAST_ONE);
	}
	
	for (entity eFind = world; (eFind = find(eFind, classname, "player"));) {
		if (eFind.team == fTeam) {
			Radio_TeamMessage_Send(fMessage, eFind);
		}
	}
}

/*
=================
Radio_DefaultStart

Pick a generic, random radio string for global start messages
=================
*/
float
Radio_DefaultStart(void)
{
	float fRand = floor(random(1, 4));
	
	if (fRand == 1) {
		return RADIO_MOVEOUT;
	} else if (fRand == 2) {
		return RADIO_LOCKNLOAD;
	} else {
		return RADIO_LETSGO;
	}
}

/*
=================
Radio_StartMessage

Decide which startmessage to play at the beginning of each round
=================
*/
void
Radio_StartMessage(void)
{
	if (g_cs_vipzones > 0) {
		Radio_TeamMessage(RADIO_VIP, TEAM_CT);
		Radio_TeamMessage(Radio_DefaultStart(), TEAM_T);
	} else if (g_cs_escapezones > 0) {
		Radio_TeamMessage(RADIO_GETOUT, TEAM_T);
		Radio_TeamMessage(Radio_DefaultStart(), TEAM_CT);
	} else {
		Radio_BroadcastMessage(Radio_DefaultStart());
	}
}

/*
=================
CSEv_Radio_f

Triggered by clients, plays a message to members of the same team
=================
*/
void
CSEv_Radio_f(float fMessage)
{
	static void CSEv_Radio_Send(float fMessage, entity eEnt, entity eTarg) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EV_RADIOMSG2);
		WriteByte(MSG_MULTICAST, num_for_edict(eEnt) - 1);
		WriteByte(MSG_MULTICAST, fMessage);
		msg_entity = eTarg;
		multicast([0,0,0], MULTICAST_ONE);
	}
	
	// Don't allow spamming
	/*if (self.fRadioFinished > time) {
		return;
	}*/
	
	// When dead, don't talk
	if (self.health <= 0) {
		return;
	}
	
	// Make sure that VIPs and CTs get eachother
	float fTargetTeam = self.team;

	
	for (entity eFind = world; (eFind = find(eFind, classname, "player"));) {
		if (eFind.team == fTargetTeam) {
			CSEv_Radio_Send(fMessage, self, eFind);
		}
	}
	
	/*self.fRadioFinished = time + 3.0f;*/
} 
