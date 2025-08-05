

var float g_csMoneyDelta;
var float g_csMoneyAlpha;
var vector g_csMoneyColor;
var float g_csMoneyOldValue;

var float g_csTimeAlpha;
var float g_csTimeUnitsOld;

var bool g_csDrawTime = false;

var string g_csDollarSprite;
var string g_csPlusSprite;
var string g_csMinusSprite;
var string g_csTimerSprite;

float
GetGameTime(void)
{
	return max(0.0f, serverkeyfloat("cs_gametime") - time);
}

float
GetMoneyAmount(void)
{
	return player.GetFloat("*money");
}

void
HLHUD_AmmoNotify_Draw(__inout vector pos)
{
	pos[0] = g_hudMins[0] + g_hudRes[0] - 40;

	for (int i = 0; i < AMMO_COUNT; i++) {
		vector srcpos;
		float a;

		/* make sure we skip any faded entries, and also null them */
		if (g_ammonotify[i].alpha <= 0.0f) {
			g_ammonotify[i].count = 0;
			continue;
		}

		/* let's get the src img pos for our type */
		srcpos = g_ammotype[i];
		a = bound(0, g_ammonotify[i].alpha, 1.0);

		/* we'll use the alpha to control the offset so it gently glides down when fading out */
		pos -= [0, 32 * a]; /* go up a notch */
		draw.SubPic(pos,
			[24,24],
			g_hud7_spr,
			srcpos,
			[24/256, 24/128],
			g_fg_color,
			a,
			DRAWFLAG_ADDITIVE
		);

		drawfont = 0;
		string txt = sprintf("%i", g_ammonotify[i].count);
		float offs = stringwidth(txt, FALSE, [20,20]);
		draw.Text_RGBA(pos + [-offs - 8,4], sprintf("%i", g_ammonotify[i].count), g_fg_color, a, FONT_20);

		g_ammonotify[i].alpha -= (clframetime * 0.5);
	}
}

void
HLHUD_AmmoNotify_Insert(int type, int count)
{
	if (count <= 0)
		return;

	if (type == 7 && count < 8) // hornet hack!
		return;

	g_ammonotify[type].count += count;
	g_ammonotify[type].alpha = 2.5f;

}

void
HLHUD_DamageNotifyDraw(vector hudmins, vector res)
{
	vector pos;
	
	pos = hudmins + [16, res[1] - 128];

	for (int i = 0; i < DMG_COUNT; i++) {
		vector srcpos;
		float a;

		/* make sure we skip any faded entries, and also null them */
		if (g_dmgnotify[i].alpha <= 0.0f) {
			continue;
		}

		/* let's get the src img pos for our type */
		srcpos = g_dmgtype[i];

		a = (sin(cltime * 2.5) * 0.5) + 0.5;
		a *= bound(0.0f, g_dmgnotify[i].alpha, 1.0);

		if (i < 4)
		draw.SubPic(pos,
			[64,64],
			g_dmg1_spr,
			srcpos,
			[64/256, 64/64],
			g_fg_color,
			a,
			DRAWFLAG_ADDITIVE
		);
		else
		draw.SubPic(pos,
			[64,64],
			g_dmg2_spr,
			srcpos,
			[64/256, 64/64],
			g_fg_color,
			a,
			DRAWFLAG_ADDITIVE
		);

		g_dmgnotify[i].alpha -= (clframetime * 2.0);
		pos -= [0, 64]; /* go up a notch */
	}
}


void
HLHUD_ItemNotify_Draw(__inout vector pos)
{
	pos[0] = g_hudMins[0] + g_hudRes[0] - 44;

	for (int i = 0; i < ITEM_COUNT; i++) {
		vector srcpos;
		float a;

		/* make sure we skip any faded entries, and also null them */
		if (g_itemnotify[i].alpha <= 0.0f) {
			g_itemnotify[i].count = 0;
			continue;
		}

		/* let's get the src img pos for our type */
		srcpos = g_itemtype[i];
		a = bound(0, g_itemnotify[i].alpha, 1.0);

		/* we'll use the alpha to control the offset so it gently glides down when fading out */
		pos -= [0, 52 * a]; /* go up a notch */
		draw.SubPic(pos + [-20,0],
			[44,44],
			g_hud2_spr,
			srcpos,
			[44/256, 44/256],
			g_fg_color,
			a,
			DRAWFLAG_ADDITIVE
		);

		if (g_itemnotify[i].count > 1) {
		drawfont = 0;
		string txt = sprintf("%i", g_itemnotify[i].count);
		float offs = stringwidth(txt, FALSE, [20,20]) + 16;

		draw.Text_RGBA(pos + [-offs - 8,12], sprintf("%i", g_itemnotify[i].count), g_fg_color, a, FONT_20);
		}

		g_itemnotify[i].alpha -= (clframetime * 0.5);
	}
}

void
HLHUD_ItemNotify_Insert(int type, int count)
{
	if (count <= 0) {
		return;
	}

	g_itemnotify[type].count += count;
	g_itemnotify[type].alpha = 2.5f;

}

void
HUD_PickedUpItem(string itemClass)
{
	switch (itemClass) {
	case "item_battery":
		HLHUD_ItemNotify_Insert(0i, 1i);
		break;
	case "item_healthkit":
		HLHUD_ItemNotify_Insert(1i, 1i);
		break;
	case "item_longjump":
		HLHUD_ItemNotify_Insert(2i, 1i);
		break;
	}
}


void
HLHUD_UpdateTimers(float health, float armor, float clip, float ammo1, float ammo2)
{
	if (health != g_oldHealth) {
		g_healthAlpha = 1.0;
	}
	if (armor != g_oldArmor) {
		g_armorAlpha = 1.0;
	}
	if (clip != g_oldClip) {
		g_clipAlpha = 1.0;
	}
	if (ammo1 != g_oldAmmo1) {
		g_ammo1Alpha = 1.0;
	}
	if (ammo2 != g_oldAmmo2) {
		g_ammo2Alpha = 1.0;
	}

	g_oldHealth = health;
	g_oldArmor = armor;
	g_oldClip = clip;
	g_oldAmmo1 = ammo1;
	g_oldAmmo2 = ammo2;
}

void
HLHUD_ClampTimers()
{
	g_healthAlpha = bound(g_fg_alpha, g_healthAlpha - (clframetime * 0.5), 1.0);
	g_armorAlpha = bound(g_fg_alpha, g_armorAlpha - (clframetime * 0.5), 1.0);
	g_clipAlpha = bound(g_fg_alpha, g_clipAlpha - (clframetime * 0.5), 1.0);
	g_ammo1Alpha = bound(g_fg_alpha, g_ammo1Alpha - (clframetime * 0.5), 1.0);
	g_ammo2Alpha = bound(g_fg_alpha, g_ammo2Alpha - (clframetime * 0.5), 1.0);
	g_ammoDisplayAlpha = bound(0.0, g_ammoDisplayAlpha - (clframetime * 5), 1.0);
	g_damageAlpha = bound(0.0, g_damageAlpha - (clframetime * 1), 1.0);
}

void
HLHUD_BigNums(vector pos, string numString, float alpha)
{
	if (alpha > g_fg_alpha) {
		float backAlpha = bound(0.0f, alpha - g_fg_alpha, 1.0f);
		draw.Text_RGBA(pos + [random(-2,2), 0], numString, g_fg_color, backAlpha, FONT_20);
		draw.Text_RGBA(pos, numString, g_fg_color, alpha, FONT_20);
	} else
		draw.Text_RGBA(pos, numString, g_fg_color, alpha, FONT_20);
}

void
HUD_Init(void)
{
	for (int i = 0; i < HLHUD_SPRITES; i++) {
		g_spriteSheets[i] = atlasPic.Load(g_hlSpriteNames[i]);
	}

	weaponSelectionHUD = spawn(HLWeaponSelect);
	
	

	if (serverinfo.GetString("mode") == "counterstrike") {
		g_csDrawTime = true;
	}
}

void
HUD_ReloadVideoResources(void)
{
	font.Load("fonts/font20.font", FONT_20);
	font.Load("fonts/chat.font", FONT_CHAT);

#if 0
	font.Load("fonts/chat.font", FONT_20);
	font.Load("fonts/weaponicon.font", FONT_WEAPONICON);
	font.Load("fonts/weaponicon_sel.font", FONT_WEAPONICON_SEL);
	font.Load("fonts/weapontext.font", FONT_WEAPONTEXT);
	font.Load("fonts/weaponnumbers.font", FONT_WEAPONNUM);
	font.Load("fonts/weaponnumbers_blurry.font", FONT_WEAPONNUMB);
#endif

	g_hud1_spr = precache.SpriteFrame("sprites/640hud1.spr", 0, 0.0f);
	g_hud2_spr = precache.SpriteFrame("sprites/640hud2.spr", 0, 0.0f);
	g_hud3_spr = precache.SpriteFrame("sprites/640hud3.spr", 0, 0.0f);
	g_hud4_spr = precache.SpriteFrame("sprites/640hud4.spr", 0, 0.0f);
	g_hud5_spr = precache.SpriteFrame("sprites/640hud5.spr", 0, 0.0f);
	g_hud6_spr = precache.SpriteFrame("sprites/640hud6.spr", 0, 0.0f);
	g_hud7_spr = precache.SpriteFrame("sprites/640hud7.spr", 0, 0.0f);

	g_damage_spr_t = precache.SpriteFrame("sprites/640_pain.spr", 0, 0.0f);
	g_damage_spr_r = precache.SpriteFrame("sprites/640_pain.spr", 1, 0.0f);
	g_damage_spr_b = precache.SpriteFrame("sprites/640_pain.spr", 2, 0.0f);
	g_damage_spr_l = precache.SpriteFrame("sprites/640_pain.spr", 3, 0.0f);

	g_dmg1_spr = precache.SpriteFrame("sprites/640hud8.spr", 0, 0.0f);
	g_dmg2_spr = precache.SpriteFrame("sprites/640hud9.spr", 0, 0.0f);
	
	g_csDollarSprite = atlasPic.Load("dollar");
	g_csPlusSprite = atlasPic.Load("plus");
	g_csMinusSprite = atlasPic.Load("minus");
	g_csTimerSprite = atlasPic.Load("stopwatch");
}

void
HLHUD_DrawNumber(int iNumber, vector vecPos, float fAlpha, vector vColor)
{
	atlasPic.Draw_RGBA(
		g_spriteSheets[S_NUMBER_0 + iNumber],
		vecPos,
		vColor * fAlpha,
		g_fg_alphaScale, 
		true
	);
}

void
HLHUD_DrawNums(float fNumber, vector vecPos, float fAlpha, vector vColor)
{
	int iNumber = fNumber;
	if (iNumber > 0) {
		while (iNumber > 0) {
			HLHUD_DrawNumber((float)iNumber % 10, vecPos, fAlpha, vColor);
			iNumber = iNumber / 10;
			vecPos[0] -= 20;
		} 
	} else {
		HLHUD_DrawNumber(0, vecPos, fAlpha, vColor);
	}
}

void
HLHUD_DrawHealth(vector pos, float healthValue)
{
	if (healthValue > 25) {
		atlasPic.Draw_RGBA(
			g_spriteSheets[S_CROSS],
			pos + [-72,-1],
			g_fg_color * g_healthAlpha,
			g_fg_alphaScale, 
			true
		);
		HLHUD_DrawNums(healthValue, pos, g_healthAlpha, g_fg_color);
	} else {
		atlasPic.Draw_RGBA(
			g_spriteSheets[S_CROSS],
			pos + [-72,-1],
			[1,0,0],
			g_fg_alphaScale, 
			true
		);
		HLHUD_DrawNums(healthValue, pos, g_healthAlpha, [1,0,0]);
	}
}

void
HLHUD_DrawArmor(vector pos, float armorValue)
{
	atlasPic.Draw_RGBA(
		g_spriteSheets[S_SUIT_EMPTY],
		pos + [-80,-1],
		g_fg_color * g_armorAlpha,
		g_fg_alphaScale, 
		true
	);

	if (armorValue > 0) {
		float perc = bound(0, (armorValue / 100), 1.0);

		atlasPic.DrawBottom_RGBA(
			g_spriteSheets[S_SUIT_FULL],
			pos + [-80,-1],
			perc,
			g_fg_color * g_armorAlpha,
			g_fg_alphaScale, 
			true
		);
	}

	HLHUD_DrawNums(armorValue, pos, g_armorAlpha, g_fg_color);
}

void
HLHUD_DrawFlashlight(vector pos, float sprintValue)
{
	atlasPic.Draw_RGBA(
		g_spriteSheets[S_FLASH_EMPTY],
		pos,
		g_fg_color * g_armorAlpha,
		g_fg_alphaScale, 
		true
	);

	if (sprintValue > 0) {
		atlasPic.DrawLeft_RGBA(
			g_spriteSheets[S_FLASH_FULL],
			pos,
			sprintValue,
			g_fg_color * g_armorAlpha,
			g_fg_alphaScale, 
			true
		);
	}

	if (player.IsSprinting()) {
		atlasPic.DrawLeft_RGBA(
			g_spriteSheets[S_FLASH_FULL],
			pos,
			sprintValue,
			g_fg_color * g_armorAlpha,
			g_fg_alphaScale, 
			true
		);

		atlasPic.Draw_RGBA(
			g_spriteSheets[S_FLASH_BEAM],
			pos + [32, 0],
			g_fg_color * g_armorAlpha,
			g_fg_alphaScale, 
			true
		);
	}
}

void
HLHUD_DrawObituaries(vector drawAtPos, bool rightAlign)
{
	if (g_killMsgTime < time && g_killMsgCount > 0i) {
		for (int i = 0i; i < (KILLMESSAGE_LIMIT-1i); i++) {
			g_killMsgRecord[i].m_target = g_killMsgRecord[i+1].m_target;
			g_killMsgRecord[i].m_attacker = g_killMsgRecord[i+1].m_attacker;
			g_killMsgRecord[i].m_icon = g_killMsgRecord[i+1].m_icon;
		}

		g_killMsgRecord[KILLMESSAGE_LIMIT-1].m_target = "";
		g_killMsgRecord[KILLMESSAGE_LIMIT-1].m_attacker = "";
		g_killMsgRecord[KILLMESSAGE_LIMIT-1].m_icon = -1;

		g_killMsgTime = time + KILLMESSAGE_TIME;
		g_killMsgCount--;
	}

	if (g_killMsgCount <= 0i) {
		return;
	}

	for (int i = 0i; i < g_killMsgCount; i++) {
		float m_ofs1 = font.StringWidth(g_killMsgRecord[i].m_target, true, FONT_CHAT);
		float m_ofs2 = atlasPic.GetWidth(g_killMsgRecord[i].m_icon);
		float m_padding = 8.0f;

		if (rightAlign == true) {
			draw.RText(drawAtPos, g_killMsgRecord[i].m_target, FONT_CHAT);
			atlasPic.Draw_RGBA(
				g_killMsgRecord[i].m_icon,
				[drawAtPos[0] - (m_ofs1 + m_padding + m_ofs2), drawAtPos[1]],
				g_fg_color * HUD_ALPHA,
				g_fg_alphaScale, 
				true
			);
			draw.RText([drawAtPos[0] - (m_ofs1 + m_padding + m_ofs2 + m_padding), drawAtPos[1]], g_killMsgRecord[i].m_attacker, FONT_CHAT);
		} else {
			draw.Text(drawAtPos, g_killMsgRecord[i].m_target, FONT_CHAT);
			atlasPic.Draw_RGBA(
				g_killMsgRecord[i].m_icon,
				drawAtPos,
				g_fg_color * HUD_ALPHA,
				g_fg_alphaScale, 
				true
			);
			draw.Text(drawAtPos, g_killMsgRecord[i].m_attacker, FONT_CHAT);
		}
		drawAtPos[1] += font.GetHeight(FONT_CHAT) + m_padding;
	}
}

void
HUD_DrawSeperator(vector vecPos)
{
	atlasPic.Draw_RGBA(
		g_spriteSheets[S_DIVIDER],
		vecPos - [0, 7],
		g_fg_color * HUD_ALPHA,
		g_fg_alphaScale, 
		true
	);
}

void
HLHUD_DrawAmmo1(vector pos, float ammoValue)
{
	HLHUD_DrawNums(ammoValue, pos, g_clipAlpha, g_fg_color);
	HUD_DrawSeperator(pos + [30,0]);
}

void
HLHUD_DrawAmmo2(vector pos, float ammoValue)
{
	HLHUD_DrawNums(ammoValue, pos, g_ammo1Alpha, g_fg_color);
}

void
HLHUD_DrawAmmo3(vector pos, float ammoValue)
{
	HLHUD_DrawNums(ammoValue, pos, g_ammo2Alpha, g_fg_color);
}

void
CSHUD_DrawMoney(vector money_pos, float moneyValue)
{
	float endalpha;

	/* if the money differs from last frame, paint it appropriately */
	if (moneyValue > g_csMoneyOldValue) {
		/* effect already in progress from something else, go add on top of it! */
		if (g_csMoneyAlpha > 0) {
			g_csMoneyDelta += (g_csMoneyOldValue - moneyValue);
		} else {
			g_csMoneyDelta = g_csMoneyOldValue - moneyValue;
		}
		/* make it green for a short time */
		g_csMoneyColor = [0,1,0];
		g_csMoneyAlpha = 1.0;
	} else if (moneyValue < g_csMoneyOldValue) {
		/* same one as above */
		if (g_csMoneyAlpha > 0) {
			g_csMoneyDelta += (g_csMoneyOldValue - moneyValue);
		} else {
			g_csMoneyDelta = g_csMoneyOldValue - moneyValue;
		}
		/* make it red */
		g_csMoneyColor = [1,0,0];
		g_csMoneyAlpha = 1.0;
		g_csMoneyDelta = g_csMoneyOldValue - moneyValue;
	}

	/* maximum alpha is variable. */
	endalpha = g_csMoneyAlpha * HUD_ALPHA;

	atlasPic.Draw_RGBA(
		g_csDollarSprite,
		money_pos,
		g_fg_color,
		HUD_ALPHA - endalpha,
		true
	);

	/* if the alpha/color effect is active, draw the money twice in their
	 * varying alphas/colors  */
	if (g_csMoneyAlpha > 0) {
		/* red/green dollar sign */
		atlasPic.Draw_RGBA(
			g_csDollarSprite,
			money_pos,
			g_csMoneyColor,
			endalpha,
			true
		);

		/* draw the +/- symbols depending on whether
		 * or not we made or lost money */
		if (g_csMoneyDelta < 0) {
			atlasPic.Draw_RGBA(
				g_csMinusSprite,
				money_pos + [0,-32],
				g_csMoneyColor,
				endalpha,
				true
			);
		} else {
			atlasPic.Draw_RGBA(
				g_csPlusSprite,
				money_pos + [0,-32],
				g_csMoneyColor,
				endalpha,
				true
			);
		}

		/* shift the numbers for reverse drawing */
		money_pos[0] += (24 * 5);

		/* draw the red/green overlay numbers on top of ours */
		HLHUD_DrawNums(moneyValue, money_pos, endalpha, g_csMoneyColor);

		/* draw above how much money we've lost/gotten from all this */
		HLHUD_DrawNums(fabs(g_csMoneyDelta), money_pos + [0,-32], endalpha, g_csMoneyColor);
	} else {
		money_pos[0] += (24 * 5);
	}

	/* regular number */
	HLHUD_DrawNums(
		moneyValue,
		money_pos,
		HUD_ALPHA - endalpha,
		g_fg_color
	);

	g_csMoneyOldValue = moneyValue;
	g_csMoneyAlpha = max(0, g_csMoneyAlpha - (clframetime * 0.5));
}




/* timer */
void
CSHUD_DrawTimer(vector time_pos, float gameTime)
{
	if (g_csDrawTime == false) {
		return;
	}

	int iMinutes, iSeconds, iTens, iUnits;

	if (gameTime < -1) {
		return;
	}

	iMinutes = gameTime / 60;
	iSeconds = gameTime - 60 * iMinutes;
	iTens = iSeconds / 10;
	iUnits = iSeconds - 10 * iTens;

	/* Flashing red numbers */
	if ((iMinutes == 0) &&  (iTens <= 1)) {
		float fAlpha;
		
		/* 0:00 is fully red */
		if ((iTens == 0) && (iUnits == 0)) {
			fAlpha = 1;
		} else {
			fAlpha = fabs(sin(time * 20));
		}
		
		HLHUD_DrawNumber(iMinutes, time_pos + [48,0], fAlpha, [1,0,0]);
		HLHUD_DrawNumber(iTens, time_pos + [75,0], fAlpha, [1,0,0]);
		HLHUD_DrawNumber(iUnits, time_pos + [99,0],fAlpha, [1,0,0]);
		HLHUD_DrawNumber(iMinutes, time_pos + [48,0], 1 - fAlpha, g_fg_color);
		HLHUD_DrawNumber(iTens, time_pos + [75,0], 1 - fAlpha, g_fg_color);
		HLHUD_DrawNumber(iUnits, time_pos + [99,0],1 - fAlpha, g_fg_color);
		
		/* : symbol */
		draw.Rect(time_pos + [70,6], [3,3], [1,0,0], fAlpha, DRAWFLAG_ADDITIVE);
		draw.Rect(time_pos + [70,16], [3,3], [1,0,0], fAlpha, DRAWFLAG_ADDITIVE);
		draw.Rect(time_pos + [70,6], [3,3], g_fg_color, 1 - fAlpha, DRAWFLAG_ADDITIVE);
		draw.Rect(time_pos + [70,16], [3,3], g_fg_color, 1 - fAlpha, DRAWFLAG_ADDITIVE);
		
		/* clock */
		atlasPic.Draw_RGBA(g_csTimerSprite, time_pos, [1,0,0], fAlpha, true);
		atlasPic.Draw_RGBA(g_csTimerSprite, time_pos, g_fg_color, 1 - fAlpha, true);
	} else {
		if (iUnits != g_csTimeUnitsOld) {
			g_csTimeAlpha = 1.0;
		}
	
		if (g_csTimeAlpha >= HUD_ALPHA) {
			g_csTimeAlpha -= clframetime * 0.5;
		} else {
			g_csTimeAlpha = HUD_ALPHA;
		}
		HLHUD_DrawNumber(iMinutes, time_pos + [48,0], g_csTimeAlpha, g_fg_color);
		HLHUD_DrawNumber(iTens, time_pos + [75,0], g_csTimeAlpha, g_fg_color);
		HLHUD_DrawNumber(iUnits, time_pos + [95,0], g_csTimeAlpha, g_fg_color);
		
		draw.Rect(time_pos + [70,6], [3,3], g_fg_color, g_csTimeAlpha, DRAWFLAG_ADDITIVE);
		draw.Rect(time_pos + [70,16], [3,3], g_fg_color, g_csTimeAlpha, DRAWFLAG_ADDITIVE);

		atlasPic.Draw_RGBA(g_csTimerSprite, time_pos, g_fg_color, g_csTimeAlpha, true);
		g_csTimeUnitsOld = iUnits;
	}
}


void
HUD_Draw(void)
{
	vector pos;
	vector hud_mins, hud_size;
	float armorValue  = player.GetArmor();
	float healthValue = player.GetHealth();
	int teamID = player.GetTeam();
	float clipValue = weapon.GetClip();
	float ammoValue = weapon.GetAmmo1();
	float ammoValue2 = weapon.GetAmmo2();
	float staminaValue = 1.0 - player.GetStamina();

	g_hudMins = hud_mins = screen.HUDMins();
	g_hudRes = hud_size = screen.HUDSize();

	HLHUD_UpdateTimers(healthValue, armorValue, clipValue, ammoValue, ammoValue2);
	HLHUD_DamageNotifyDraw(hud_mins, hud_size);

	if (1) {
		pos = g_hudMins + [g_hudRes[0] - 192, g_hudRes[1] - 128];
		pos[1] += 48;
		HLHUD_ItemNotify_Draw(pos);
		HLHUD_AmmoNotify_Draw(pos);
	}

	HLHUD_DrawObituaries([g_hudRes[0] - 16, 48], true);

	if (g_damageAlpha > 0.0f) {
		vector center;
		vector rel_pos;
		float fw, fw_alpha;
		float rt, rt_alpha;

		center = hud_mins + (hud_size / 2);

		/* the pos relative to the player + view_dir determines which
		 * and how bright each indicator is drawn. so first get the relative
		 * position between us and the attacker, then calculate the strength
		 * of each direction based on a dotproduct tested against our
		 * camera direction.
		 */
		vector playerPosition = player.GetCameraPosition();
		vector playerAngle = player.GetCameraAngles();
		playerPosition[2] = g_damageLocation[2];
		rel_pos = vectorNormalize(g_damageLocation - playerPosition);
		fw = vectorDot(rel_pos, anglesToForward(playerAngle));
		rt = vectorDot(rel_pos, anglesToRight(playerAngle));

		fw_alpha = fabs(fw) * g_damageAlpha;
		if (fw > 0.25f) {
			draw.Pic(center + [-64,-102], g_damage_spr_t, 
				[128,48], [1,1,1], fw_alpha, DRAWFLAG_ADDITIVE);
		} else if (fw < -0.25f) {
			draw.Pic(center + [-64,70], g_damage_spr_b,
				[128,48], [1,1,1], fw_alpha, DRAWFLAG_ADDITIVE);
		}

		rt_alpha = fabs(rt) * g_damageAlpha;
		if (rt > 0.25f) {
			draw.Pic(center + [70,-64], g_damage_spr_r,
				[48,128], [1,1,1], rt_alpha, DRAWFLAG_ADDITIVE);
		} else if (rt < -0.25f) {
			draw.Pic(center + [-102,-64], g_damage_spr_l,
				[48,128], [1,1,1], rt_alpha, DRAWFLAG_ADDITIVE);
		}

		if (autocvar_cg_damageFill > 0.0) {
			vector screenSize = screen.Size();
			vector finalColor = [1,1,1];
			finalColor[1] = finalColor[2] = 1.0 - (g_damageAlpha * autocvar_cg_damageFill);
			draw.Pic(hud_mins, "fade_modulate", screenSize, finalColor, 1.0, DRAWFLAG_NORMAL);
		}

		g_damageAlpha -= clframetime;
	}

	pos = hud_mins + [88, hud_size[1] - 42];
	HLHUD_DrawHealth(pos, healthValue); 
	pos = hud_mins + [198, hud_size[1] - 42];
	HLHUD_DrawArmor(pos, armorValue);
	
	pos = hud_mins + [hud_size[0] - 160, hud_size[1] - 72];
	CSHUD_DrawMoney(pos, GetMoneyAmount());

	if (0) {
		pos = hud_mins + [(hud_size[0] / 2) - 62, 16];
	} else {
		pos = hud_mins + [(hud_size[0] / 2) - 62, hud_size[1] - 42];
	}

	CSHUD_DrawTimer(pos, GetGameTime());

	weaponSelectionHUD.Draw();

	if (g_spriteCrosshair != -1i) {
		//atlasPic.DrawCrosshair(g_spriteCrosshair);
	}

	pos = hud_mins + [hud_size[0] - 52, 16];
	HLHUD_DrawFlashlight(pos, staminaValue);

	if (weapon.AmmoRequired() == false) {
		HLHUD_ClampTimers();
		return;
	}

	/* ammo displays */

	/* ammo 2 */
	if (weapon.UsesSecondaryAmmo() == true) {
		pos = hud_mins + [hud_size[0] - 72, hud_size[1] - 74];
		HLHUD_DrawAmmo3(pos, ammoValue2);
	}

	pos = hud_mins + [hud_size[0] - 48, hud_size[1] - 42];

	atlasPic.Draw_RGBA(
		g_spriteAmmoIcon,
		pos,
		g_fg_color,
		g_fg_alphaScale,
		true
	);

	if (weapon.GetClipSize() > 0) {
		pos = hud_mins + [hud_size[0] - 152, hud_size[1] - 42];
		HLHUD_DrawAmmo1(pos, clipValue);
	}

	pos = hud_mins + [hud_size[0] - 72, hud_size[1] - 42];
	HLHUD_DrawAmmo2(pos, ammoValue);

	HLHUD_ClampTimers();
}

void
HUD_WeaponSwitched(string weaponName)
{
	g_spriteAmmoIcon = atlasPic.Load(strcat(weaponName, ".ammo"));
	g_spriteCrosshair = atlasPic.Load(strcat(weaponName, ".crosshair"));
	g_ammoDisplayAlpha = 1.0f;
}

float
HUD_InputFrame(float inputButtons)
{
	if (weaponSelectionHUD.Active()) {
		if (inputButtons & INPUT_PRIMARY) {
			weaponSelectionHUD.Trigger();
		} else if (inputButtons & INPUT_SECONDARY) {
			weaponSelectionHUD.Deactivate();
		}

		return (0.2f);
	}

	return (0.0f);
}

bool
HUD_ConsoleCommand(string commandString)
{
	tokenize_console(commandString);

	switch (argv(0)) {
	case "invnext":
		weaponSelectionHUD.SelectNext(false);
		break;
	case "invprev":
		weaponSelectionHUD.SelectPrevious(false);
		break;
	default:
		return (false);
	}

	return (true);
}

	
void
HUD_DamageReceived(vector damageLocation, int damagePoints, int damageFlags)
{
	if (damagePoints <= 0i) {
		return;
	}

	g_damageAlpha = 1.0;
	g_damageLocation = damageLocation;
	g_damageFlags = damageFlags;

	if (g_damageFlags & DMG_CHEMICAL) {
		g_damageFlags &= ~DMG_CHEMICAL;
		DMG_NOTIFY_SET(DMGNOT_CHEMICAL);
	}
	if (g_damageFlags & DMG_BURN) {
		g_damageFlags &= ~DMG_BURN;
		DMG_NOTIFY_SET(DMGNOT_BURN);
	}
	if (g_damageFlags & DMG_SLOWBURN) {
		g_damageFlags &= ~DMG_SLOWBURN;
		DMG_NOTIFY_SET(DMGNOT_BURN);
	}
	if (g_damageFlags & DMG_ELECTRO) {
		g_damageFlags &= ~DMG_ELECTRO;
		DMG_NOTIFY_SET(DMGNOT_SHOCK);
	}
	if (g_damageFlags & DMG_DROWN) {
		g_damageFlags &= ~DMG_DROWN;
		DMG_NOTIFY_SET(DMGNOT_DROWN);
	}
	if (g_damageFlags & DMG_NERVEGAS) {
		g_damageFlags &= ~DMG_NERVEGAS;
		DMG_NOTIFY_SET(DMGNOT_NERVEGAS);
	}
	if (g_damageFlags & DMG_POISON) {
		g_damageFlags &= ~DMG_POISON;
		DMG_NOTIFY_SET(DMGNOT_POISON);
	}
	if (g_damageFlags & DMG_RADIATION) {
		g_damageFlags &= ~DMG_RADIATION;
		DMG_NOTIFY_SET(DMGNOT_RADIATION);
	}
	if (g_damageFlags & DMG_FREEZE) {
		g_damageFlags &= ~DMG_FREEZE;
		DMG_NOTIFY_SET(DMGNOT_FREEZE);
	}
	if (g_damageFlags & DMG_SLOWFREEZE) {
		g_damageFlags &= ~DMG_SLOWFREEZE;
		DMG_NOTIFY_SET(DMGNOT_FREEZE);
	}
}


vector g_ammotype[AMMO_COUNT] = {
	[0/256, 72/128], // pistol
	[24/256, 72/128], // revolver
	[48/256, 72/128], // grenade
	[72/256, 72/128], // shell
	[96/256, 72/128], //  arrow
	[120/256, 72/128], // rocket
	[0/256, 96/128], // uranium
	[24/256, 96/128], // hornet
	[48/256, 96/128], // grenade
	[72/256, 96/128], // satchel
	[96/256, 96/128], //  snark
	[120/256, 96/128], // tripmine
	[24/256, 72/128], // 556 (same as 357)
	[24/256, 72/128], // 762 (same as 357)
	[200/256, 48/128], // spore
	[224/256, 48/128], //  shock
	[144/256, 72/128], // penguin
};

void
HUD_AmmoChanged(int ammoType, int absoluteValue, int deltaValue)
{
	string ammoTypeName = ammo.NameForNum(ammoType);

	/* if you wonder why this isn't cleaner, this was ported from
	   the old HUD code. this can be changed to be decl specific at some point! */
	switch (ammoTypeName) {
	case "ammo_9mm":
		HLHUD_AmmoNotify_Insert(0, deltaValue);
		break;
	case "ammo_357":
		HLHUD_AmmoNotify_Insert(1, deltaValue);
		break;
	case "ammo_m203_grenade":
		HLHUD_AmmoNotify_Insert(2, deltaValue);
		break;
	case "ammo_buckshot":
		HLHUD_AmmoNotify_Insert(3, deltaValue);
		break;
	case "ammo_bolt":
		HLHUD_AmmoNotify_Insert(4, deltaValue);
		break;
	case "ammo_rocket":
		HLHUD_AmmoNotify_Insert(5, deltaValue);
		break;
	case "ammo_uranium":
		HLHUD_AmmoNotify_Insert(6, deltaValue);
		break;
	case "ammo_hornet":
		HLHUD_AmmoNotify_Insert(7, deltaValue);
		break;
	case "ammo_handgrenade":
		HLHUD_AmmoNotify_Insert(8, deltaValue);
		break;
	case "ammo_satchel":
		HLHUD_AmmoNotify_Insert(9, deltaValue);
		break;
	case "ammo_snark":
		HLHUD_AmmoNotify_Insert(10, deltaValue);
		break;
	case "ammo_tripmine":
		HLHUD_AmmoNotify_Insert(11, deltaValue);
		break;
	case "ammo_556":
		HLHUD_AmmoNotify_Insert(12, deltaValue);
		break;
	case "ammo_762":
		HLHUD_AmmoNotify_Insert(13, deltaValue);
		break;
	case "ammo_spore":
		HLHUD_AmmoNotify_Insert(14, deltaValue);
		break;
	case "ammo_shock":
		HLHUD_AmmoNotify_Insert(15, deltaValue);
		break;
	case "ammo_penguin":
		HLHUD_AmmoNotify_Insert(16, deltaValue);
		break;
	}
}

void
HUD_Obituary(string targetName, string attackerName, string weaponDef, string meansOfDeath)
{
	static void HUD_Obituary_Add(int id, string targetName, string attackerName, string weaponDef, string meansOfDeath) {
		string killIcon = entityDef.GetString(weaponDef, "killIcon");

		g_killMsgRecord[id].m_target = targetName;

		if (wordInString(meansOfDeath, "self") == false) {
			g_killMsgRecord[id].m_attacker = attackerName;
		} else {
			g_killMsgRecord[id].m_attacker = "";
		}

		if (STRING_SET(killIcon)) {
			g_killMsgRecord[id].m_icon = atlasPic.Load(killIcon);
		} else {
			if (wordInString(meansOfDeath, "vehicle") == true) {
				g_killMsgRecord[id].m_icon = g_spriteSheets[S_D_TRACKTRAIN];
			} else {
				g_killMsgRecord[id].m_icon = g_spriteSheets[S_D_SKULL];
			}
		}
	}

	if (g_killMsgCount < KILLMESSAGE_LIMIT) {
		HUD_Obituary_Add(g_killMsgCount, targetName, attackerName, weaponDef, meansOfDeath);
		g_killMsgCount++;
	} else {
		for (int i = 0i; i < (KILLMESSAGE_LIMIT-1); i++) {
			g_killMsgRecord[i].m_target = g_killMsgRecord[i+1].m_target;
			g_killMsgRecord[i].m_attacker = g_killMsgRecord[i+1].m_attacker;
			g_killMsgRecord[i].m_icon = g_killMsgRecord[i+1].m_icon;
		}

		HUD_Obituary_Add(KILLMESSAGE_LIMIT-1, targetName, attackerName, weaponDef, meansOfDeath);
	}

	g_killMsgTime = time + KILLMESSAGE_TIME;
}



#define SPEC_SEP_COL [0.204,0.196,0.114]
#define SPEC_FG_COL [0.561,0.561,0.212]

void
HUD_DrawSpectator(void)
{
	vector vecPos = g_vec_null;
	float flSep;
	string strText;
	int iMinutes, iSeconds;
	float moneyValue = GetMoneyAmount();

	vector m_vecOrigin = screen.Mins();
	vector m_vecSize = screen.Size();

	vector hudMins = screen.HUDMins();
	vector hudRes = screen.HUDSize();

	/* parts on top and bottom */
	draw.Rect(m_vecOrigin, [m_vecSize[0], 32], [0,0,0], 0.75f);
	draw.Rect(m_vecOrigin + [0, m_vecSize[1]-32], [m_vecSize[0], 32], [0,0,0], 0.75f);

	/* tracking player box */
	draw.RectOutline(hudMins + [(hudRes[0] / 2) - 111, hudRes[1]-26], [222,20], 1.0f, SPEC_SEP_COL, 1.0f);

	strText = strcat(Colors_RGB8_to_HEX(teams.Color(spectating.Team())), spectating.Name());
	vecPos[0] = hudMins[0] + (hudRes[0] / 2) - (font.StringWidth(strText, true, FONT_CHAT) / 2);
	vecPos[1] = hudRes[1]-21;
	draw.Text_RGB(vecPos, strText, [1,1,1], FONT_CHAT);

	/* tracking mode box */
	draw.RectOutline(hudMins + [(hudRes[0] / 2) + 128, hudRes[1]-26], [172,20], 1.0f, SPEC_SEP_COL, 1.0f);
	strText = spectating.LocalizedMode();
	vecPos[0] = (hudMins[0] + (hudRes[0] / 2) + 214) - (font.StringWidth(strText, true, FONT_CHAT) / 2);
	vecPos[1] = hudRes[1]-21;
	draw.Text_RGB(vecPos, strText, SPEC_FG_COL, FONT_CHAT);

	if (spectating.Mode() == SPECMODE_FIRSTPERSON) {
		atlasPic.DrawCrosshair(g_spriteCrosshair);
	}

	/* money */
	strText = sprintf("$ %d", moneyValue);
	flSep = font.StringWidth(strText, true, FONT_CHAT);

	if (flSep < 42)
		flSep = 42;

	flSep = hudMins[0] + (hudRes[0] - flSep) - 10;

	vecPos[0] = flSep + 8;
	vecPos[1] = hudMins[1] + 3;
	draw.Text_RGB(vecPos, strText, SPEC_FG_COL, FONT_CHAT);

	/* score/money separator */
	draw.Rect([flSep,1], [4,30], SPEC_SEP_COL, 1.0f);

	/* team scores */
	strText = sprintf("Terrorist Forces: %i", teams.Score(1));
	vecPos[0] = flSep - font.StringWidth(strText, true, FONT_CHAT) - 2;
	vecPos[1] = hudMins[1] + 3;
	draw.Text_RGB(vecPos, strText, SPEC_FG_COL, FONT_CHAT);

	strText = sprintf("CT Forces: %i", teams.Score(2));
	vecPos[0] = flSep - font.StringWidth(strText, true, FONT_CHAT) - 2;
	vecPos[1] = hudMins[1] + 16;
	draw.Text_RGB(vecPos, strText, SPEC_FG_COL, FONT_CHAT);

	/* time display */
	draw.Pic([flSep + 8, 15], "gfx/vgui/640_timer", [14, 14], [1,1,1], 1.0f, DRAWFLAG_NORMAL);
	iMinutes = GetGameTime() / 60;
	iSeconds = GetGameTime() - 60 * iMinutes;
	strText = sprintf("%i:%02i", iMinutes, iSeconds);
	vecPos[0] = flSep + 8 + 17;
	vecPos[1] = hudMins[1] + 17;
	draw.Text_RGB(vecPos, strText, SPEC_FG_COL, FONT_CHAT);
}
