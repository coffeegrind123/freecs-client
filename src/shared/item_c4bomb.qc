/*
 * Copyright (c) 2016-2021 Marco Cawthorne <marco@icculus.org>
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

class CSBombEntity:NSRenderableEntity
{
public:
	void CSBombEntity(void);

#ifdef SERVER
	virtual void Spawned(void);
	virtual float SendEntity(entity, float);
	virtual void ClearProgress(void);
	virtual void OnPlayerUse(void);
	virtual void Logic(void);
	virtual void OnRemoveEntity(void);
#endif

#ifdef CLIENT
	virtual void DrawLED(void);
	virtual float predraw(void);
#endif

#ifdef SERVER
private:
	entity m_eUser;
	float m_flBeepTime;
	float m_flExplodeTime;
	float m_flDefusalState;
#endif
};

void
CSBombEntity::CSBombEntity(void)
{
#ifdef SERVER
	m_eUser = __NULL__;
	m_flBeepTime = 0.0f;
	m_flExplodeTime = 0.0f;
	m_flDefusalState = 0.0f;
#endif
}

#ifdef SERVER
float
CSBombEntity::SendEntity(entity pvsent, float flags)
{
	WriteByte(MSG_ENTITY, ENT_C4BOMB);
	WriteCoord(MSG_ENTITY, origin[0]);
	WriteCoord(MSG_ENTITY, origin[1]);
	WriteCoord(MSG_ENTITY, origin[2]);
	WriteCoord(MSG_ENTITY, angles[0]);
	WriteCoord(MSG_ENTITY, angles[1]);
	WriteCoord(MSG_ENTITY, angles[2]);
	WriteShort(MSG_ENTITY, modelindex);
	return (1);
}

void
CSBombEntity::ClearProgress(void)
{
	if (m_eUser != world) {
		CSPlayer pl = (CSPlayer)m_eUser;
		pl.progress = 0.0f;
		pl.RemoveVFlags(VFL_FROZEN);
	}
}

void
CSBombEntity::OnPlayerUse(void)
{
	CSPlayer pl = (CSPlayer)eActivator;

	/* obvious check */
	if (pl.team != TEAM_CT) {
		return;
	}

	/* don't allow anyone else to hijack. */
	if (m_eUser == world) {
		m_eUser = eActivator;
		StartSoundDef("weapon_c4bomb.disarm", CHAN_ITEM, true);
	}
}

void
CSBombEntity::Logic(void)
{
	/* check if we're being used */
	if (m_eUser != world) {
		CSPlayer pl = (CSPlayer)m_eUser;

		/* we need to check if the user has changed every frame. */
		if (!m_eUser.button5) {
			ClearProgress();

			/* clear user */
			m_eUser = world;
			m_flDefusalState = 0.0f;
			serverinfo.SetBool("cs_bombbeingdefused", false);
		} else {

			/* defusal kit always cuts the time in half */
			if (pl.HasItem("item_defuse"))
				m_flDefusalState += (frametime * 2);
			else
				m_flDefusalState += frametime;

			/* tracked stat */
			pl.progress = m_flDefusalState;
			pl.AddVFlags(VFL_FROZEN);
			serverinfo.SetBool("cs_bombbeingdefused", true);
		}
	}

	if (m_flDefusalState > 10.0f) {
		StartSoundDef("weapon_c4bomb.disarmed", CHAN_VOICE, true);
		g_grMode.Input(m_eUser, "BombDisarmed", "");
		Destroy();
		return;
	}

	/* if our time has passed, explode */
	if (m_flExplodeTime < time) {
		float bestDist = 9999.0f;
		NSEntity bestTarget = __NULL__;
		g_grMode.Input(m_eUser, "BombExploded", "");

		combat.RadiusDamage(origin, -g_cstrike_bombradius, 0i, 500i, real_owner, "");
		//Damage_Radius(origin, this.real_owner, 500, g_cstrike_bombradius, false, WEAPON_C4BOMB);


		StartSoundDef("weapon_c4bomb.explode", CHAN_VOICE, true);

		for (entity e = world; (e = find(e, ::classname, "func_bomb_target"));) {
			float dist = vlen(origin - e.origin);

			if (dist < bestDist) {
				bestDist = dist;
				bestTarget = (NSEntity)e;
			}
		}

		/* Found it. */
		if (bestTarget) {
			bestTarget.UseTargets(this, TRIG_TOGGLE, 0.0f);
		}

		Destroy();
		return;
	}

	if (m_flBeepTime > time) {
		return;
	}
	m_flBeepTime = time + 1.5;

	if (m_flExplodeTime - time < 5) {
		StartSoundDef("weapon_c4bomb.beep5", CHAN_VOICE, true);
	} else if (m_flExplodeTime - time < 10) {
		StartSoundDef("weapon_c4bomb.beep4", CHAN_VOICE, true);
	} else if (m_flExplodeTime - time < 20) {
		StartSoundDef("weapon_c4bomb.beep3", CHAN_VOICE, true);
	} else if (m_flExplodeTime - time < 30) {
		StartSoundDef("weapon_c4bomb.beep2", CHAN_VOICE, true);
	} else {
		StartSoundDef("weapon_c4bomb.beep1", CHAN_VOICE, true);
	}
}

void
CSBombEntity::OnRemoveEntity(void)
{
	ClearProgress();
	m_flBeepTime = 0.0f;
	m_flDefusalState = 0;
	serverinfo.SetBool("cs_bombbeingdefused", false);
	serverinfo.SetBool("cs_bombplanted", false);
}

void
CSBombEntity::Spawned(void)
{
	super::Spawned();

	/* throw this in with the other temporary round entities */
	classname = "remove_me";

	SetMovetype(MOVETYPE_NONE);
	SetSolid(SOLID_BBOX);
	SetModel("models/w_c4.mdl");
	SetSize([-6,-6,0], [6,6,6]);

	customphysics = Logic;
	PlayerUse = OnPlayerUse;
	m_flExplodeTime = time + 45.0f;
	StartSoundDef("c4.plant", CHAN_WEAPON, true);
	serverinfo.SetBool("cs_bombplanted", true);
}
#endif

#ifdef CLIENT
void
CSBombEntity::DrawLED(void)
{
	vector cameraPos = g_view.GetCameraOrigin();
	float ledAlpha = 1.0 - (time - floor(time));

	if (ledAlpha > 0.0f) {
		vector ledPos = GetOrigin() + [0,0,8];
		vector ledSize = [16,16];
		
		/* Scale the glow somewhat with the players distance */
		ledSize *= bound(1, vlen(cameraPos - origin) / 256, 4);

		/* Nudge this slightly towards the camera */
		makevectors(vectoangles(ledPos - cameraPos));
		ledPos += (v_forward * -16);

		/* Project it, always facing the player */
		makevectors(g_view.GetCameraAngle());
		R_BeginPolygon(g_c4bombled_spr, 1, 0);
		R_PolygonVertex(ledPos + v_right * ledSize[0] - v_up * ledSize[1],
			[1,1], [1,1,1] * ledAlpha, 1.0f);
		R_PolygonVertex(ledPos - v_right * ledSize[0] - v_up * ledSize[1],
			[0,1], [1,1,1] * ledAlpha, 1.0f);
		R_PolygonVertex(ledPos - v_right * ledSize[0] + v_up * ledSize[1],
			[0,0], [1,1,1] * ledAlpha, 1.0f);
		R_PolygonVertex(ledPos + v_right * ledSize[0] + v_up * ledSize[1],
			[1,0], [1,1,1] * ledAlpha, 1.0f);
		R_EndPolygon();
	}
}

float
CSBombEntity::predraw(void)
{
	DrawLED();
	addentity(this);
	return PREDRAW_NEXT;
}

void
w_c4bomb_parse(void)
{
	CSBombEntity tm = (CSBombEntity)self;
	spawnfunc_CSBombEntity();

	g_c4bombled_spr = spriteframe("sprites/ledglow.spr", 0, 0.0f);

	tm.origin[0] = readcoord();
	tm.origin[1] = readcoord();
	tm.origin[2] = readcoord();
	tm.angles[0] = readcoord();
	tm.angles[1] = readcoord();
	tm.angles[2] = readcoord();
	tm.modelindex = readshort();
	setorigin(tm, tm.origin);
	setsize(tm, [-6,-6,0], [6,6,6]);
	tm.solid = SOLID_BBOX;
	tm.movetype = MOVETYPE_NONE;
	tm.drawmask = MASK_ENGINE;
}
#endif
