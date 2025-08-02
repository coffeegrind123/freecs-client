/*
 * Copyright (c) 2024 Marco Cawthorne <marco@icculus.org>
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
CSProjectile::CSProjectile(void)
{

}

#ifdef SERVER
void
CSProjectile::HasExploded(void)
{
	float flashTime = GetSpawnFloat("flashTime");
	float smokeTime = GetSpawnFloat("smokeTime");

	if (flashTime > 0.0f) {
		FX_Flashbang(GetOrigin());
	}

	if (smokeTime > 0.0f) {
		FX_Smokenade(GetOrigin());
	}
}

void
CSProjectile::SetRangeModifier(float rangeModifier)
{
	m_flRangeModifier = rangeModifier;
}

void
CSProjectile::SetPenetrationMaxThickness(float maxThickness)
{
	m_flMaxThickness = maxThickness;
}

void
CSProjectile::SetPenetrationPower(int powerLevel)
{
	m_iTotalPenetrations = powerLevel;
}

void
CSProjectile::_LaunchHitscan(vector startPos, vector launchDir, float dmgMultiplier)
{
	vector vecDir;
	vector ownerAngle;
	vector ownerDir;

	m_eMultiTarget = __NULL__;
	m_iMultiValue = 0;

	ownerAngle = anglesToForward(launchDir);
	ownerDir = aim(owner, 100000);

	while (m_iShots > 0) {
		/* use cached value */
		v_forward = ownerAngle;

		if (owner.flags & FL_CLIENT) {
			vecDir = ownerDir;
		} else {
			vecDir = v_forward;
		}

		/* FOR NOW Monsters will not be able to do spread like players if patterns are enabled */
		if (!(owner.flags & FL_CLIENT)) {
			vecDir += random(-1,1) * m_vecSpread[0] * anglesToRight(launchDir);
			vecDir += random(-1,1) * m_vecSpread[1] * anglesToUp(launchDir);
		} else {
			CSPlayer pl = (CSPlayer)owner;

			/* weapons have already applied their multiplier... so attempt this */
			int multiplier = pl.cs_shotmultiplier - m_iShots;
			float frand = (multiplier / 6);

			/* shoddy attempt at spray patterns */
			if (frand < 1)
				frand = frand;
			else if (frand <= 2)
				frand = 2 - (frand * 1.5);

			vecDir += frand * m_vecSpread[0] * anglesToRight(launchDir);
			vecDir += (m_vecSpread[1] * anglesToUp(launchDir)) * 2;
		}

		_FireSingle(startPos, vecDir, m_flDamage, m_flRange);
		m_iShots--;
	}

	if (m_eMultiTarget) {
		_ApplyDamage();
	}
}

void
CSProjectile::_FireSingle(vector vecPos, vector vecAngles, float flDamage, float flRange)
{
	vector range;
	vector planeNormal;
	vector endPos;

	if (flRange <= 0)
		return;

	if (flDamage < 1)
		return;

	range = (vecAngles * 8196);

	owner.dimension_solid = 255;
	owner.dimension_hit = 255;

	/* make sure we can gib corpses */
	int oldhitcontents = owner.hitcontentsmaski;
	owner.hitcontentsmaski = CONTENTBITS_POINTSOLID | CONTENTBIT_CORPSE | CONTENTBIT_WATER | CONTENTBIT_SLIME | CONTENTBIT_LAVA | CONTENTBIT_PROJECTILE;
	traceline(vecPos, vecPos + range, MOVE_LAGGED | MOVE_HITMODEL, owner);
	owner.hitcontentsmaski = oldhitcontents;
	planeNormal = trace_plane_normal;
	endPos = trace_endpos;

	flRange -= trace_plane_dist;

	owner.dimension_solid = 254;
	owner.dimension_hit = 254;

	m_iMultiBody |= trace_surface_id;

	if (trace_fraction >= 1.0f)
		return;

	/* water impact */
	if (trace_endcontentsi & CONTENTBIT_WATER) {
		SurfData_ImpactOfNamedType("water", endPos, planeNormal);
		_FireSingle(endPos + (v_forward * 2), vecAngles, flDamage / 2, flRange);
	} else if (trace_endcontentsi & CONTENTBIT_SLIME) {
		SurfData_ImpactOfNamedType("slime", endPos, planeNormal);
		_FireSingle(endPos + (v_forward * 2), vecAngles, flDamage / 2, flRange);
	} else if (trace_endcontentsi & CONTENTBIT_LAVA) {
		SurfData_ImpactOfNamedType("lama", endPos, planeNormal);
		_FireSingle(endPos + (v_forward * 2), vecAngles, flDamage / 2, flRange);
	}

	if (trace_ent.takedamage != DAMAGE_NO && trace_ent.iBleeds) {
		SoundDef_Play(trace_ent, CHAN_BODY, "damage_bullet.hit");

		ncPlayer pl = (ncPlayer)trace_ent;
		/* modify the damage based on the location */
		switch (trace_surface_id) {
		case BODY_HEAD:
			/* the helmet is one power house */
			if (pl.HasItem("item_kevlar_helmet") == true) {
				flDamage = 0;
				SoundDef_Play(trace_ent, CHAN_BODY, "player.headshotarmor");
				pl.RemoveItem("item_kevlar_helmet");
				return;
			} else {
				flDamage *= 4;
				SoundDef_Play(trace_ent, CHAN_BODY, "player.headshot");
			}
			break;
		case BODY_STOMACH:
			flDamage *= 0.9;
			if (pl.armor > 0)
				SoundDef_Play(trace_ent, CHAN_BODY, "player.hitarmor");
			break;
		case BODY_LEGLEFT:
		case BODY_LEGRIGHT:
			flDamage *= 0.4;
			break;
		}
	}

	/* impact per bullet */
	if (m_bDetonateOnWorld == true && trace_ent.iBleeds == 0) {
		if (m_strDecalGroup)
			DecalGroups_Place(m_strDecalGroup, endPos + (vecAngles * -2));

		SurfData_Impact(trace_ent, endPos, planeNormal);
	}

	/* combine them into one single Damage_Apply call later */
	if (trace_ent.takedamage != DAMAGE_NO) {
		if (trace_ent != m_eMultiTarget) {
			trace_endpos = endPos;
			_ApplyDamage();
			m_eMultiTarget = (ncSurfacePropEntity)trace_ent;
			m_iMultiValue = flDamage;
		} else {
			m_iMultiValue += flDamage;
		}
	}

	if (m_iTotalPenetrations > 0) {
		float cont;

#if 0
		if (!(trace_surfaceflagsi & SURF_PENETRATE))
			m_iTotalPenetrations -= 1;
#endif

		/* check if this wall is 6 units thick... */
		if (m_iTotalPenetrations > 0) {
			cont = pointcontents(endPos + v_forward * 5);

			if (cont == CONTENT_SOLID)
				m_iTotalPenetrations -= 1; /* deduct 1 penetration power */
		}

		cont = pointcontents(endPos + v_forward * m_flMaxThickness);

		if (cont == CONTENT_EMPTY)
			_FireSingle(endPos + (v_forward * 2), vecAngles, flDamage / 2, flRange);
	}
}

CSProjectile
CSProjectile_SpawnDef(string entityDef, ncEntity theOwner, float rangeMod, int power, vector spread)
{
	entity oldself = self;

	CSProjectile rocket = spawn(CSProjectile);
	rocket.owner = theOwner;
	self = rocket;
	EntityDef_SpawnClassname(entityDef);
	self = oldself;

	rocket.m_vecSpread = spread;
	rocket.SetRangeModifier(rangeMod);
	rocket.SetPenetrationPower(power);
	rocket.SetPenetrationMaxThickness((8 * power) * rangeMod);
	rocket.Launch(theOwner.GetEyePos(), theOwner.GetViewAngle(), 0.0f, 0.0f, 0.0f);
	return rocket;
}
#endif
