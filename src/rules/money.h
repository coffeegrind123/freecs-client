/*
 * Copyright (c) 2016-2024 Marco Cawthorne <marco@icculus.org>
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

var int g_cs_moneyreward_t;
var int g_cs_moneyreward_ct;
var int g_cs_roundslost_ct;
var int g_cs_roundslost_t;
var int g_cs_winstreak_ct;
var int g_cs_winstreak_t;
var bool g_cs_bonus_ct;
var bool g_cs_bonus_t;

void
Money_AddMoney(entity targetPlayer, int addCash)
{
	int currentCash = userinfo.GetInteger(targetPlayer, "*money");
	currentCash += addCash;

	/* clamp at the classic 160000. */
	if (currentCash > 16000i) {
		currentCash = 16000i;
	} else if (currentCash < 0i) {
		currentCash = 0i;
	}

	if (addCash > 0i) {
		NSLog("Paying %s ^7$%i. Cash = $%i\n", targetPlayer.netname, addCash, currentCash);
	} else if (addCash < 0i) {
		NSLog("Fining %s ^7$%i. Cash = $%i\n", targetPlayer.netname, addCash, currentCash);
	}

	userinfo.SetInteger(targetPlayer, "*money", currentCash);
}

int
Money_GetCapital(entity targetPlayer)
{
	return userinfo.GetInteger(targetPlayer, "*money");
}

void
Money_QueTeamReward(int targetTeam, int iMoneyValue)
{
	if (targetTeam == TEAM_T) {
		g_cs_moneyreward_t += iMoneyValue;
	} else {
		g_cs_moneyreward_ct += iMoneyValue;
	}
}

void
Money_GiveTeamReward(entity targetPlayer)
{
	if (targetPlayer.team == TEAM_T) {
		Money_AddMoney(targetPlayer, g_cs_moneyreward_t);
	} else {
		Money_AddMoney(targetPlayer, g_cs_moneyreward_ct);
	}
}

void
Money_ResetTeamReward(void)
{
	g_cs_moneyreward_t = 0i;
	g_cs_moneyreward_ct = 0i;
}

int
Money_GetLosses(int queryTeam)
{
	if (queryTeam == TEAM_T) {
		return (g_cs_roundslost_t);
	} else {
		return (g_cs_roundslost_ct);
	}
}

bool
Money_HasBonus(int queryTeam)
{
	if (queryTeam == TEAM_T) {
		return (g_cs_bonus_t);
	} else {
		return (g_cs_bonus_ct);
	}
}

void
Money_HandleRoundReward(int winningTeam)
{
	int losingTeam = -1i; /* womp */

	if (winningTeam == TEAM_CT) {
		g_cs_winstreak_ct++;
		g_cs_winstreak_t = 0i;
		g_cs_roundslost_t++;
		g_cs_roundslost_ct = 0i;
		losingTeam = TEAM_T;

		if (g_cs_winstreak_ct >= 2i) {
			g_cs_bonus_ct = true;
		}
	} else {
		g_cs_winstreak_t++;
		g_cs_winstreak_ct = 0i;
		g_cs_roundslost_ct++;
		g_cs_roundslost_t = 0i;
		losingTeam = TEAM_CT;

		if (g_cs_winstreak_t >= 2i) {
			g_cs_bonus_t = true;
		}
	}

	/*  After the condition of a team winning two consecutive rounds is
	 *  satisfied then the loss bonus money changes to above where their
	 *  first loss means they receive $1500 and not $1400. */
	if (Money_HasBonus(losingTeam)) {
		switch (Money_GetLosses(losingTeam)) {
		case 1i:
			Money_QueTeamReward(losingTeam, 1500i);
			break;
		case 2i:
			Money_QueTeamReward(losingTeam, 2000i);
			break;
		case 3i:
			Money_QueTeamReward(losingTeam, 2500i);
			break;
		default:
			Money_QueTeamReward(losingTeam, 3000i);
			break;
		}
	} else {
		switch (Money_GetLosses(losingTeam)) {
		case 1i:
			Money_QueTeamReward(losingTeam, 1400i);
			break;
		case 2i:
			Money_QueTeamReward(losingTeam, 1900i);
			break;
		case 3i:
			Money_QueTeamReward(losingTeam, 2400i);
			break;
		case 4i:
			Money_QueTeamReward(losingTeam, 2900i);
			break;
		default:
			Money_QueTeamReward(losingTeam, 3400i);
			break;
		}
	}
}

void
Money_ResetRoundReward(void)
{
	g_cs_roundslost_ct =
	g_cs_roundslost_t =
	g_cs_winstreak_ct =
	g_cs_winstreak_t = 0i;
	g_cs_bonus_ct =
	g_cs_bonus_t = false;
}

void
Money_WipeProgress(entity targetPlayer)
{
	userinfo.SetInteger(targetPlayer, "*money", 0i);
	Money_AddMoney(targetPlayer, cvars.GetInteger("mp_startmoney"));
}

void
Money_PurchaseAmmoForSlot(entity customer, int slot)
{
	string inventory = actor.GetInventory(customer);

	/* we get to iterate over the whole inventory */
	for (int i = 0; i < tokenize(inventory); i++) {
		string declName = argv(i);
		int slotNum = entityDef.GetInteger(declName, "hudSlot");
		string ammoType = entityDef.GetString(declName, "ammoType");

		/* validity check */
		if (slotNum != slot || !STRING_SET(ammoType)) {
			continue;
		}

		/* we found a weapon that will get filled up. */
		int itemPrice = entityDef.GetInteger(ammoType, "price");
		int ammoAmount = entityDef.GetInteger(ammoType, strcat("inv_", ammoType));
		int ammoID = ammo.NumForName(ammoType);

		/* invalid weapon. */
		if (itemPrice <= 0i || ammoAmount <= 0i) {
			return;
		}

		/* as long as we're not full... */
		while (actor.MaxAmmo(customer, ammoID) == false) {
			/* and we can afford it... */
			if ((Money_GetCapital(customer) - itemPrice) >= 0) {
				ents.Input(customer, "GiveAmmo", sprintf("%s %i", ammoType, ammoAmount), world);
				Money_AddMoney(customer, -itemPrice);
			} else {
				break;
			}
		}
	}
}

void
Money_Purchase(entity customer, string desiredItem)
{
	int itemPrice = entityDef.GetInteger(desiredItem, "price");

	/* no free things in CS */
	if (itemPrice <= 0i) {
		return;
	}

	if ((Money_GetCapital(customer) - itemPrice) >= 0) {
		ents.Input(customer, "GiveItem", desiredItem, world);
		Money_AddMoney(customer, -itemPrice);
	}
}
