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

#ifdef CLIENT
void Cstrike_DrawCrosshair(csPlayer);
#endif

class
csWeapon:hlWeapon
{
public:
	void csWeapon(void);

#ifdef CLIENT
	virtual void ReloadCachedAttributes(void);
	virtual void UpdateGUI(void);
#endif

	virtual bool CanFire(void);
	virtual void Release(void);
	virtual void FiredWeaponAttack(string);
	virtual void SwitchedToWeapon(void);
	virtual void UpdateFireInfoCache(void);
	virtual void WeaponStoppedReloading(void);

	int numProjectiles;
	string traceInfo;
	float accuracy;
	float flAccuracyDivisor;
	float flAccuracyMovementPenalty;
	float flAccuracyMultiplier;
	float flAccuracyAdd;
	float flRangeModifier;
	float flPenetrationPower;
	float flBulletStrength;
	float flMultiplierShots;
	float flMultiplierStrength;
	float flMultiplierInaccuracy;
	vector bulletSpread;

};

void
csWeapon::csWeapon(void)
{

}

bool
csWeapon::CanFire(void)
{
	bool returnValue = super::CanFire();
	
	if (returnValue == true) {
		if (!(owner.gflags & GF_BOMBZONE) && GetSpawnBool("onlyInBombZone")) {
			returnValue = false;
		}
	}

	return (returnValue);
}

void
csWeapon::SwitchedToWeapon(void)
{
	Cstrike_ShotReset((csPlayer)owner);
}

void
csWeapon::WeaponStoppedReloading(void)
{
	Cstrike_ShotReset((csPlayer)owner);
}

void
csWeapon::FiredWeaponAttack(string defName)
{
	csPlayer ourOwner = (csPlayer)owner;

	if (GetSubDefBool(defName, "csWeaponMode") == false) {
		super::FiredWeaponAttack(defName);
		return;
	}



	/* always fire at least 1 */
	if (numProjectiles <= 0i) {
		numProjectiles = 1i;
	}

	if (flBulletStrength) {
		Cstrike_BulletRecoil_ApplyPre(ourOwner, flBulletStrength);
	}

#ifdef SERVER
	float traceDamage = GetSubDefFloat(traceInfo, "damage");

	/* don't bother with shotguns */
	if (numProjectiles > 3i) {
		bulletSpread = [random(-1,1) * 0.1,random(-1,1) * 0.05];
	}

	for (int i = 0i; i < numProjectiles; i++) {
		csProjectile_SpawnDef(traceInfo, ourOwner, flRangeModifier, flPenetrationPower, bulletSpread);
	}
#endif

	if (flBulletStrength) {
		Cstrike_BulletRecoil_ApplyPost(ourOwner, flBulletStrength);
	}

	/* don't bother with shotguns */
	if (numProjectiles <= 3i) {
		Cstrike_ShotMultiplierAdd(ourOwner, flMultiplierShots, flMultiplierStrength, accuracy * flMultiplierInaccuracy);
	}
}

void
csWeapon::Release(void)
{
	owner.v_angle = input_angles;
	Cstrike_ShotMultiplierUpdate((csPlayer)owner);
	input_angles = owner.v_angle;
	super::Release();
}

void
csWeapon::UpdateFireInfoCache(void)
{
	super::UpdateFireInfoCache();

	numProjectiles = GetSubDefInt(m_weaponLastFireInfo, "numProjectiles");
	traceInfo = GetSubDefString(m_weaponLastFireInfo, "def_onFire");
	flAccuracyDivisor = GetSubDefFloat(m_weaponLastFireInfo,"accuracyDivisor");
	flAccuracyMovementPenalty = GetSubDefFloat(m_weaponLastFireInfo,"accuracyMovementPenalty");
	flAccuracyMultiplier = GetSubDefFloat(m_weaponLastFireInfo,"accuracyMultiplier");
	flAccuracyAdd= GetSubDefFloat(m_weaponLastFireInfo,"accuracyAdd");
	flRangeModifier = GetSubDefFloat(m_weaponLastFireInfo,"rangeModifier");
	flPenetrationPower = GetSubDefFloat(m_weaponLastFireInfo,"penetrationPower");
	flBulletStrength = GetSubDefFloat(m_weaponLastFireInfo,"bulletStrength");
	flMultiplierShots = GetSubDefFloat(m_weaponLastFireInfo,"multiplierShots");
	flMultiplierStrength = GetSubDefFloat(m_weaponLastFireInfo,"multiplierStrength");
	flMultiplierInaccuracy = GetSubDefFloat(m_weaponLastFireInfo,"multiplierInaccuracy");
	accuracy = Cstrike_CalculateAccuracy(owner, flAccuracyDivisor, flAccuracyMovementPenalty) / flAccuracyMultiplier;
	accuracy += flAccuracyAdd;
	bulletSpread = [accuracy, accuracy];

#ifdef CLIENT
	csPlayer ourOwner = (csPlayer)owner;
	ourOwner.cs_cross_mindist = GetSubDefInt(m_weaponLastFireInfo, "crossMinDist");
	ourOwner.cs_cross_deltadist = GetSubDefInt(m_weaponLastFireInfo, "crossDeltaDist");

/* no geomset support */
#ifndef NOVO
	CStrikeView_UpdateGeomset(ourOwner);
#endif
#endif
}

#ifdef CLIENT
void
csWeapon::ReloadCachedAttributes(void)
{
	super::ReloadCachedAttributes();

	m_ammoIcon = GetDefString("ammoIcon");

	if (m_ammoIcon == "") {
		m_ammoIcon = sprintf("%s.ammo", strtolower(declclass));
	}

	m_crossHair = GetDefString("crosshair");

	if (m_crossHair == "") {
		m_crossHair = sprintf("%s.crosshair", strtolower(declclass));
	} else if (m_crossHair == "none") {
		m_crossHair = __NULL__;
	}

	m_weaponHUDSlot = GetDefInt("hudSlot");
	m_weaponHUDSlotPos = GetDefInt("hudSlotPos");
}

void
csWeapon::UpdateGUI(void)
{
	csPlayer ourOwner = (csPlayer)GetOwner();

	/* draw crosshair */

	if (STRING_SET(m_crossHair)) {
		Cstrike_DrawCrosshair(ourOwner);
	}
}
#endif
