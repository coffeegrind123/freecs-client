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

#define PMOVE_STEPHEIGHT 18
#define PMOVE_AIRSTEPHEIGHT 0
#define PMOVE_FRICTION 4
#define PMOVE_EDGEFRICTION 1
#define PMOVE_STOPSPEED 75
#define PMOVE_GRAVITY 800
#define PMOVE_AIRACCELERATE 10
#define PMOVE_WATERACCELERATE 8
#define PMOVE_ACCELERATE 4
#define PMOVE_MAXSPEED 250
#define PMOVE_STEP_WALKSPEED 270
#define PMOVE_STEP_CROUCHSPEED 90
#define PMOVE_BOXCENTER true
#define PMOVE_NORMAL_HEIGHT 72
#define PMOVE_NORMAL_VIEWHEIGHT 54
#define PMOVE_CROUCH_HEIGHT 36
#define PMOVE_CROUCH_VIEWHEIGHT 30

/* disable prone, run and lean */
#define PMOVE_STEP_RUNSPEED 0
#define PMOVE_PRONE_HEIGHT 0

.float waterlevel;
.float watertype;

void
CSPlayer::Physics_Fall(float impactspeed)
{
	impactspeed *= 1.25f;
	if (impactspeed > 580) {
#ifdef SERVER
		float fFallDamage = (impactspeed - 580) * (100 / (1024 - 580)) * 0.75f;
		//Damage_Apply(this, world, fFallDamage, 0, DMG_FALL | DMG_SKIP_ARMOR);

		if (random() < 0.5)
			sound(this, CHAN_AUTO, "player/pl_pain2.wav", 1.0, ATTN_NORM);
		else
			sound(this, CHAN_AUTO, "player/pl_pain4.wav", 1.0, ATTN_NORM);
#endif
	}
}

void
CSPlayer::Physics_Jump(void)
{
	if (waterlevel >= 2) {
		if (watertype == CONTENT_WATER) {
			velocity[2] = 100;
		} else if (watertype == CONTENT_SLIME) {
			velocity[2] = 80;
		} else {
			velocity[2] = 50;
		}
	} else {
		/* slow the player down a bit to prevent bhopping like crazy */
		velocity *= 0.80f;
		velocity[2] += 260;
	}
}
