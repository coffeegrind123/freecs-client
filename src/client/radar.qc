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

#define CSRADAR_DISTANCE 1024

var string g_cs_radar;
var NSRadar g_csRadar;

void
Radar_Init(void)
{
	g_cs_radar = spriteframe("sprites/radar640.spr", 0, 0.0f);

	g_csRadar = NSRadar::InitEmpty();
}

void
Radar_Draw(void)
{
	vector radpos = g_view.GetHUDCanvasPos() + [16,16];

	drawpic(radpos, g_cs_radar, [128,128], [1,1,1], 0.25f, DRAWFLAG_ADDITIVE);

	/* these need constant adjustment for when the display changes */
	g_csRadar.SetViewPosition(radpos);
	g_csRadar.SetViewSize([128,128]);
	g_csRadar.UpdateView();


}
