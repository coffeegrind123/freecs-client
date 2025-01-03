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

static vguiWindow winChooseTeam;

string
VGUI_ChooseTeam_MapInfo(void)
{
	static string mapinfo = __NULL__;

	if (mapinfo != __NULL__)
		return mapinfo;
	
	filestream fileMap = fopen(strcat("maps/", mapname, ".txt"), FILE_READ);
	string temp;

	if (fileMap != -1) {
		while ((temp = fgets(fileMap))) {
			mapinfo = strcat(mapinfo, temp, "\n");
		}
	} else {
		mapinfo = "No map info available.";
	}

	return mapinfo;
}

/* returns true if you should join CT, else T */
bool
VGUI_ChooseTeam_AutoQuery(void)
{
	int teamT = 0;
	int teamCT = 0;

	for (int i = -1; i > -32; i--) {
		if (getplayerkeyfloat(i, "*team") == 1) {
			teamT++;
		} else if (getplayerkeyfloat(i, "*team") == 2) {
			teamCT++;
		}
	}

	if (teamT > teamCT)
		return true;

	return false;
}

void
VGUI_ChooseTeam(void)
{
	static int initialized;
	static vguiButton btnJoinT;
	static vguiButton btnJoinCT;
	static vguiButton btnAutoAssign;
	static vguiButton btnGoSpectator;
	static vguiFrame frmMapInfo;
	static vguiLabel lblSelectTeam;
	static vguiLabel lblMapName;
	static vguiLabel lblMapInfo;

	static void VGUI_ChooseTeam_CT(void) {
		localcmd("cmd joinTeam 2\n");
		VGUI_ChooseClassCT();
		winChooseTeam.Hide();
	}

	static void VGUI_ChooseTeam_T(void) {
		localcmd("cmd joinTeam 1\n");
		VGUI_ChooseClassT();
		winChooseTeam.Hide();
	}

	static void VGUI_ChooseTeam_Auto(void) {
		localcmd("cmd joinTeam 9\n");
	}

	static void VGUI_ChooseTeam_Spec(void) {
		localcmd("cmd joinTeam 1002\n");
		winChooseTeam.Hide();
	}

	if (!initialized) {
		vector btnpos = [40,80];

		initialized = TRUE;
		winChooseTeam = spawn(vguiWindow);
		winChooseTeam.SetSize('640 480');
		winChooseTeam.SetStyleMask(vguiWindowBorderless | vguiWindowFullscreen);

		lblSelectTeam = spawn(vguiLabel);
		lblSelectTeam.SetTitle("Select Your Team");
		lblSelectTeam.SetTextSize(19);
		lblSelectTeam.SetPos([40, 38]);
		lblSelectTeam.SetSize('400 24');

		frmMapInfo = spawn(vguiFrame);
		frmMapInfo.SetPos('176 80');
		frmMapInfo.SetSize('424 312');

		lblMapName = spawn(vguiLabel);
		lblMapName.SetTitle(mapname);
		lblMapName.SetTextSize(19);
		lblMapName.SetPos('194 105');
		lblMapName.SetSize('250 312');

		lblMapInfo = spawn(vguiLabel);
		lblMapInfo.SetTitle(VGUI_ChooseTeam_MapInfo());
		lblMapInfo.SetPos('194 129');
		lblMapInfo.SetSize('375 250');

		btnJoinT = spawn(vguiButton);
		btnJoinT.SetTitle("Terrorist Forces");
		btnJoinT.SetPos('40 80');
		btnJoinT.SetSize('124 24');
		btnJoinT.SetKeyEquivalent("1");
		btnJoinT.SetFunc(VGUI_ChooseTeam_T);

		btnJoinCT = spawn(vguiButton);
		btnJoinCT.SetTitle("CT Forces");
		btnJoinCT.SetPos('40 112');
		btnJoinCT.SetSize('124 24');
		btnJoinCT.SetKeyEquivalent("2");
		btnJoinCT.SetFunc(VGUI_ChooseTeam_CT);

		btnAutoAssign = spawn(vguiButton);
		btnAutoAssign.SetTitle("Auto Assign");
		btnAutoAssign.SetPos('40 208');
		btnAutoAssign.SetSize('124 24');
		btnAutoAssign.SetKeyEquivalent("5");
		btnAutoAssign.SetFunc(VGUI_ChooseTeam_Auto);

		btnGoSpectator = spawn(vguiButton);
		btnGoSpectator.SetTitle("Spectate");
		btnGoSpectator.SetPos('40 272');
		btnGoSpectator.SetSize('124 24');
		btnGoSpectator.SetKeyEquivalent("6");
		btnGoSpectator.SetFunc(VGUI_ChooseTeam_Spec);

		g_uiDesktop.Add(winChooseTeam);
		winChooseTeam.Add(frmMapInfo);
		winChooseTeam.Add(lblSelectTeam);
		winChooseTeam.Add(lblMapName);
		winChooseTeam.Add(lblMapInfo);
		winChooseTeam.Add(btnJoinT);
		winChooseTeam.Add(btnJoinCT);
		winChooseTeam.Add(btnAutoAssign);
		winChooseTeam.Add(btnGoSpectator);
	}

	winChooseTeam.Show();
	winChooseTeam.SetPos((g_vidsize / 2) - (winChooseTeam.GetSize() / 2));
}
