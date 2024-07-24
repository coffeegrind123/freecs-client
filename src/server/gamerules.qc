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

void
CSGameRules::PlayerDeath(NSClientPlayer pl)
{
}

void
CSGameRules::PlayerPain(NSClientPlayer pl)
{
}

bool
CSGameRules::ShowHints(void)
{
	return (true);
}

bool
CSGameRules::BuyingPossible(NSClientPlayer pl)
{
	return (false);
}

/* we check what fields have changed over the course of the frame and network
 * only the ones that have actually changed */
void
CSGameRules::PlayerPreFrame(NSClientPlayer pp)
{
	pp.gflags &= ~GF_BUYZONE;
	pp.gflags &= ~GF_RESCUEZONE;
	pp.gflags &= ~GF_BOMBZONE;
}

void
CSGameRules::LevelDecodeParms(NSClientPlayer pp)
{
	CSPlayer pl = (CSPlayer)pp;
	g_landmarkpos[0] = parm1;
	g_landmarkpos[1] = parm2;
	g_landmarkpos[2] = parm3;
	pl.angles[0] = parm4;
	pl.angles[1] = parm5;
	pl.angles[2] = parm6;
	pl.velocity[0] = parm7;
	pl.velocity[1] = parm8;
	pl.velocity[2] = parm9;
	pl.g_items = parm10;
	pl.activeweapon = parm11;
	pl.flags = parm64;
	pl.gflags = parm63;

	if (pl.IsCrouching()) {
		setsize(pl, VEC_CHULL_MIN, VEC_CHULL_MAX);
	} else {
		setsize(pl, VEC_HULL_MIN, VEC_HULL_MAX);
	}
}

void
CSGameRules::LevelChangeParms(NSClientPlayer pp)
{
	CSPlayer pl = (CSPlayer)pp;
	parm1 = g_landmarkpos[0];
	parm2 = g_landmarkpos[1];
	parm3 = g_landmarkpos[2];
	parm4 = pl.angles[0];
	parm5 = pl.angles[1];
	parm6 = pl.angles[2];
	parm7 = pl.velocity[0];
	parm8 = pl.velocity[1];
	parm9 = pl.velocity[2];
	parm63 = pl.gflags;
	parm64 = pl.flags;
	parm10 = pl.g_items;
	parm11 = pl.activeweapon;
}

void
CSGameRules::LevelNewParms(void)
{
	parm1 = parm2 = parm3 = parm4 = parm5 = parm6 = parm7 =
	parm8 = parm9 = parm10 = parm11 = parm12 = parm13 = parm14 =
	parm15 = parm16 = parm17 = parm18 = parm19 = parm20 = parm21 =
	parm22 = parm23 = parm24 = parm25 = parm26 = parm27 = parm28 =
	parm29 = parm30 = parm31 = parm32 = parm33 = parm34 = parm35 =
	parm36 = parm37 = parm38 = parm39 = parm40 = parm41 = parm42 =
	parm43 = parm44 = parm45 = parm46 = parm63= 0;
	parm64 = FL_CLIENT;
}

bool
CSGameRules::ImpulseCommand(NSClient bp, float num)
{
	switch (num) {
	default:
		return super::ImpulseCommand(bp, num);
	}

	return true;
}