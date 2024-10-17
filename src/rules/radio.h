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

#include "../shared/radio.h"
#include "../shared/events.h"

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
	for (entity teamPlayer = world; (teamPlayer = find(teamPlayer, classname, "player"));) {
		if (teamPlayer.team == fTeam) {
			ents.Input(teamPlayer, "RadioMessage", ftos(fMessage), world);
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
	if (IsAssassination()) {
		Radio_TeamMessage(RADIO_VIP, TEAM_CT);
		Radio_TeamMessage(Radio_DefaultStart(), TEAM_T);
	} else if (IsEscape()) {
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
	// Don't allow spamming
	/*if (self.fRadioFinished > time) {
		return;
	}*/
	
	// When dead, don't talk
	if (self.health <= 0) {
		return;
	}

	for (entity teamPlayer = world; (teamPlayer = find(teamPlayer, classname, "player"));) {
		ents.Input(teamPlayer, "RadioTeamMessage", sprintf("%d %d", num_for_edict(teamPlayer) - 1, fMessage), world);
	}

	/*self.fRadioFinished = time + 3.0f;*/
} 
