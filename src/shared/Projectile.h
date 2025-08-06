/*
 * Copyright (c) 2024 Vera Visions LLC.
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

class
csProjectile:ncProjectile
{
public:
	void csProjectile(void);

#ifdef SERVER
	virtual void HasExploded(void);
	nonvirtual void SetRangeModifier(float);
	nonvirtual void SetPenetrationMaxThickness(float);
	nonvirtual void SetPenetrationPower(int);

	virtual void _FireSingle(vector,vector,float,float);
	virtual void _LaunchHitscan(vector, vector, float);

private:
	float m_flRangeModifier;
	int m_iTotalPenetrations;
	float m_flMaxThickness;
#endif
};
