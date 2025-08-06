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

/*!QUAKED func_escapezone (0 .5 .8) ?
"targetname"    Name
"target"        Target when triggered.
"killtarget"    Target to kill when triggered.

COUNTER-STRIKE (1999) ENTITY

Terrorist escape zone.

Used in the Escape mode (es_* maps).
*/

class
func_escapezone:ncBrushTrigger
{
	void func_escapezone(void);

	virtual void Respawn(void);
	virtual void Touch(entity);
};

void
func_escapezone::func_escapezone(void)
{
}

void
func_escapezone::Respawn(void)
{
	InitBrushTrigger();
}


void
func_escapezone::Touch(entity eToucher)
{
	csPlayer pl = (csPlayer)eToucher;

	/* disallow the wrong players */
	if (pl.classname != "player")
		return;
	if (pl.team != TEAM_T)
		return;

	g_grMode.Input(eToucher, "Escaped", "");

}
