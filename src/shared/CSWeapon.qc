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
void Cstrike_DrawCrosshair(CSPlayer);
#endif

class
CSWeapon:HLWeapon
{
public:
	void CSWeapon(void);

#ifdef CLIENT
	virtual void AddedToInventory(void);
	virtual void UpdateGUI(void);
#endif

	virtual void Draw(void);
	virtual void SecondaryAttack(void);
	virtual void Release(void);
	virtual void FiredWeaponAttack(string);
	virtual void SwitchedToWeapon(void);

#ifdef CLIENT
private:
	int m_iHudSlot;
	int m_iHudSlotPos;

	string m_ammoIcon;
	string m_crossHair;
	NSWeapon m_nextWeapon;
#endif
};

void
CSWeapon::CSWeapon(void)
{

}

void
CSWeapon::SwitchedToWeapon(void)
{
	Cstrike_ShotReset((CSPlayer)owner);
}

void
CSWeapon::SecondaryAttack(void)
{
	if (GetDefBool("altSilences") == true) {
		if (CanFire() == false) {
			return;
		}

		float silAnimation = 0;
		float silTime;

		m_iMode = 1 - m_iMode;

		if (m_iMode)
			silAnimation = GetDefAct("actAddSil");
		else
			silAnimation = GetDefAct("actDetachSil");

		SetWeaponFrame(silAnimation);
		silTime = frameduration(m_viewModel, silAnimation);
		SetAttackNext(silTime);
		SetIdleNext(silTime + 1.0f);
		return;
	}

	super::SecondaryAttack();
}

void
CSWeapon::FiredWeaponAttack(string defName)
{
	CSPlayer ourOwner = (CSPlayer)owner;
	int numProjectiles = GetSubDefInt(defName, "numProjectiles");
	string traceInfo = GetSubDefString(defName, "def_onFire");
	float flAccuracyDivisor = GetSubDefFloat(defName,"accuracyDivisor");
	float flAccuracyMovementPenalty = GetSubDefFloat(defName,"accuracyMovementPenalty");
	float flAccuracyMultiplier = GetSubDefFloat(defName,"accuracyMultiplier");
	float flAccuracyAdd= GetSubDefFloat(defName,"accuracyAdd");
	float flRangeModifier = GetSubDefFloat(defName,"rangeModifier");
	float flPenetrationPower = GetSubDefFloat(defName,"penetrationPower");
	float flBulletStrength = GetSubDefFloat(defName,"bulletStrength");
	float flMultiplierShots = GetSubDefFloat(defName,"multiplierShots");
	float flMultiplierStrength = GetSubDefFloat(defName,"multiplierStrength");
	float flMultiplierInaccuracy = GetSubDefFloat(defName,"multiplierInaccuracy");
	float accuracy = Cstrike_CalculateAccuracy(ourOwner, flAccuracyDivisor, flAccuracyMovementPenalty) / flAccuracyMultiplier;
	accuracy += flAccuracyAdd;
	vector bulletSpread = [accuracy, accuracy];

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
		CSProjectile_SpawnDef(traceInfo, ourOwner, flRangeModifier, flPenetrationPower, bulletSpread);
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
CSWeapon::Draw(void)
{
	super::Draw();

#ifdef CLIENT
	CSPlayer ourOwner = (CSPlayer)owner;
	ourOwner.cs_cross_mindist = GetDefInt("crossMinDist");
	ourOwner.cs_cross_deltadist = GetDefInt("crossDeltaDist");
	CStrikeView_UpdateGeomset(ourOwner);
#endif
}

void
CSWeapon::Release(void)
{
	owner.v_angle = input_angles;
	Cstrike_ShotMultiplierUpdate((CSPlayer)owner);
	input_angles = owner.v_angle;
	super::Release();
}

#ifdef CLIENT
void
CSWeapon::AddedToInventory(void)
{
	super::AddedToInventory();

	m_ammoIcon = GetDefString("ammoIcon");

	if (m_ammoIcon == "") {
		m_ammoIcon = sprintf("%s.ammo", strtolower(classname));
	}

	m_crossHair = GetDefString("crosshair");

	if (m_crossHair == "") {
		m_crossHair = sprintf("%s.crosshair", strtolower(classname));
	}

	m_iHudSlot = GetDefInt("hudSlot");
	m_iHudSlotPos = GetDefInt("hudSlotPos");
}

void
CSWeapon::UpdateGUI(void)
{
	CSPlayer ourOwner = (CSPlayer)GetOwner();

	/* draw crosshair */
	Cstrike_DrawCrosshair(ourOwner);

	/* draw ammo icon */
	if (m_ammoIcon) {
		vector ammoPos = g_hudmins + [g_hudres[0] - 48, g_hudres[1] - 42];
		HLSprite_Draw_RGBA(m_ammoIcon, ammoPos, g_hud_color, pSeatLocal->m_flAmmo2Alpha, true);
	}

	if (m_bAmmoRequired == false) {
		return;
	}

	if (m_iClipSize > 0i) {
		ourOwner.a_ammo1 = m_iClip;
		HUD_DrawAmmo1();
	}

	ourOwner.a_ammo2 = ourOwner.GetReserveAmmo(m_primaryAmmoType);
	HUD_DrawAmmo2();

	if (m_secondaryAmmoType && m_primaryAmmoType != m_secondaryAmmoType) {
		ourOwner.a_ammo3 = ourOwner.GetReserveAmmo(m_secondaryAmmoType);
		HUD_DrawAmmo3();
	}
}
#endif