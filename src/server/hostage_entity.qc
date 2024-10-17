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

/*!QUAKED CSHostage (0 1 0) (-16 -16 0) (16 16 72)
# OVERVIEW
Hostage NPC.
Used in the Hostage Rescue mode (cs_* maps).

# KEYS
"targetname"    Name
"target"        Target when triggered.
"killtarget"    Target to kill when triggered.

# TRIVIA
This entity was introduced in Counter-Strike (1999)

-------- MODEL FOR RADIANT ONLY - DO NOT SET THIS AS A KEY --------
model="models/hostage.mdl"
skin="0"
*/

enum
{
	HOSA_WALK,
	HOSA_WALKSCARED,
	HOSA_RUN,
	HOSA_RUNSCARED,
	HOSA_RUNLOOK,
	HOSA_180LEFT,
	HOSA_180RIGHT,
	HOSA_FLINCH,
	HOSA_PAIN,
	HOSA_PAINLEFT,
	HOSA_PAINRIGHT,
	HOSA_PAINLEGLEFT,
	HOSA_PAINLEGRIGHT,
	HOSA_IDLE1,
	HOSA_IDLE2,
	HOSA_IDLE3,
	HOSA_IDLE4,
	HOSA_IDLE5,
	HOSA_IDLE6,
	HOSA_SCARED_END,
	HOSA_SCARED1,
	HOSA_SCARED2,
	HOSA_SCARED3,
	HOSA_SCARED4,
	HOSA_PANIC,
	HOSA_FEAR1,
	HOSA_FEAR2,
	HOSA_CRY,
	HOSA_SCI1,
	HOSA_SCI2,
	HOSA_SCI3,
	HOSA_DIE_SIMPLE,
	HOSA_DIE_FORWARD1,
	HOSA_DIE_FORWARD2,
	HOSA_DIE_BACKWARD,
	HOSA_DIE_HEADSHOT,
	HOSA_DIE_GUTSHOT,
	HOSA_LYING1,
	HOSA_LYING2,
	HOSA_DEADSIT,
	HOSA_DEADTABLE1,
	HOSA_DEADTABLE2,
	HOSA_DEADTABLE3
};

class CSHostage:NSTalkMonster
{
	bool m_bUsedOnce;

	void CSHostage(void);

	virtual void OnPlayerUse(void);
	virtual void Pain(entity, entity, int, vector, int);
	virtual void Death(entity, entity, int, vector, int);

};

void
CSHostage::CSHostage(void)
{
	Sound_Precache("hostage_entity.follow");
	m_bUsedOnce = false;
}


void
CSHostage::OnPlayerUse(void)
{
	if (eActivator.team == TEAM_T) {
		CSPlayer pl = (CSPlayer)eActivator;

		if (serverinfo.GetBool("cs_hints") == true)
		if (pl.m_hostMessageT == false) {
			env_message_single(pl, "Only_CT_Can_Move_Hostages");
			pl.m_hostMessageT = true;
		}
		return;
	}

	if (m_eFollowing == world) {
		Sound_Speak(this, "hostage_entity.follow");
	}

	/* CT reward, first time only */
	if (m_bUsedOnce == false) {
		g_grMode.Input(eActivator, "HostageContacted", "");
		m_bUsedOnce = true;
	}

	NSTalkMonster::OnPlayerUse();
}

void
CSHostage::Pain(entity inflictor, entity attacker, int damageDealt, vector dir, int location)
{
	super::Pain(inflictor, attacker, damageDealt, dir, location);

	if (IsAlive() == false) {
		return;
	}

	switch (location) {
	case BODY_HEAD:
	case BODY_DEFAULT:
	case BODY_CHEST:
	case BODY_STOMACH:
		AnimPlay(HOSA_PAIN);
		break;
	case BODY_ARMLEFT:
		AnimPlay(HOSA_PAINLEFT);
		break;
	case BODY_ARMRIGHT:
		AnimPlay(HOSA_PAINRIGHT);
		break;
	case BODY_LEGLEFT:
		AnimPlay(HOSA_PAINLEGLEFT);
		break;
	case BODY_LEGRIGHT:
		AnimPlay(HOSA_PAINLEGRIGHT);
		break;
	}

	/* penalties */
	if (isPlayer(attacker) == false) {
		return;
	}

	g_grMode.Input(attacker, "HostageInjured",  itos(damageDealt));
}

void
CSHostage::Death(entity inflictor, entity attacker, int damageDealt, vector dir, int location)
{
	WarnAllies();

	if (IsAlive() == true) {
		switch (location) {
		case BODY_HEAD:
			SetFrame(HOSA_DIE_HEADSHOT);
			break;
		case BODY_STOMACH:
			SetFrame(HOSA_DIE_GUTSHOT);
			break;
		default:
			SetFrame(HOSA_DIE_SIMPLE + floor(random(0,4)));
			break;
		}

		if (isPlayer(attacker) == true) {
			g_grMode.Input(attacker, "HostageKilled", itos(damageDealt));
		}
	}

	/* HACK: don't let them gib */
	SetHealth(0);

	/* now mark our state as 'dead' */
	super::Death(inflictor, attacker, damageDealt, dir, location);
	SetSolid(SOLID_NOT);
}
