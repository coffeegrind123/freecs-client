#!/bin/bash
set -euo pipefail

FTEQW_DIR="${1:?Usage: patch-fteqw.sh <fteqw-source-dir>}"

patch -p1 -d "$FTEQW_DIR" <<'PATCH'
diff --git a/engine/client/m_download.c b/engine/client/m_download.c
index 2d618c1..fb3ba43 100644
--- a/engine/client/m_download.c
+++ b/engine/client/m_download.c
@@ -34,7 +34,7 @@ static char enginerevision[256] = STRINGIFY(SVNREVISION);
 #ifdef ENABLEPLUGINSBYDEFAULT
 cvar_t	pkg_autoupdate = CVARFD("pkg_autoupdate", "1", CVAR_NOTFROMSERVER|CVAR_NOSAVE|CVAR_NOSET|CVAR_NORESET, "Controls autoupdates, can only be changed via the downloads menu.\n0: off.\n1: enabled (stable only).\n2: enabled (unstable).\nNote that autoupdate will still prompt the user to actually apply the changes."); //read from the package list only.
 #else
-cvar_t	pkg_autoupdate = CVARFD("pkg_autoupdate", "-1", CVAR_NOTFROMSERVER|CVAR_NOSAVE|CVAR_NOSET|CVAR_NORESET, "Controls autoupdates, can only be changed via the downloads menu.\n0: off.\n1: enabled (stable only).\n2: enabled (unstable).\nNote that autoupdate will still prompt the user to actually apply the changes."); //read from the package list only.
+cvar_t	pkg_autoupdate = CVARFD("pkg_autoupdate", "0", CVAR_NOTFROMSERVER|CVAR_NOSAVE|CVAR_NOSET|CVAR_NORESET, "Controls autoupdates, can only be changed via the downloads menu.\n0: off.\n1: enabled (stable only).\n2: enabled (unstable).\nNote that autoupdate will still prompt the user to actually apply the changes."); //read from the package list only.
 #endif

 #define INSTALLEDFILES	"installed.lst"	//the file that resides in the quakedir (saying what's installed).
diff --git a/engine/client/net_master.c b/engine/client/net_master.c
index 30f6c85..53a6810 100644
--- a/engine/client/net_master.c
+++ b/engine/client/net_master.c
@@ -150,8 +150,8 @@ static net_masterlist_t net_masterlist[] = {
 	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra1", ""/*"qwmaster.ocrana.de:27000" not responding*/,	CVAR_NOSAVE, Net_Masterlist_Callback),	"Ocrana(2nd)"},	//german. admin unknown
 	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra2", ""/*"masterserver.exhale.de:27000" dns dead*/,		CVAR_NOSAVE, Net_Masterlist_Callback)},	//german. admin unknown
 //	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra3", "asgaard.morphos-team.net:27000",					CVAR_NOSAVE, Net_Masterlist_Callback),	"Germany, admin: bigfoot"},
-	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra4", "master.quakeservers.net:27000",					CVAR_NOSAVE, Net_Masterlist_Callback),	"Germany, admin: raz0?"},
-	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra5", "qwmaster.fodquake.net:27000",						CVAR_NOSAVE, Net_Masterlist_Callback),	"admin: bigfoot"},
+	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra4", "",					CVAR_NOSAVE, Net_Masterlist_Callback),	"Germany, admin: raz0?"},
+	{MP_QUAKEWORLD, CVARFC("net_qwmasterextra5", "",						CVAR_NOSAVE, Net_Masterlist_Callback),	"admin: bigfoot"},
 //	{MP_QUAKEWORLD, CVARFC("net_qwmasterextraHistoric",	"satan.idsoftware.com:27000",				CVAR_NOSAVE, Net_Masterlist_Callback),	"Official id Master"},
 //	{MP_QUAKEWORLD, CVARFC("net_qwmasterextraHistoric",	"satan.idsoftware.com:27002",				CVAR_NOSAVE, Net_Masterlist_Callback),	"Official id Master For CTF Servers"},
 //	{MP_QUAKEWORLD, CVARFC("net_qwmasterextraHistoric",	"satan.idsoftware.com:27003",				CVAR_NOSAVE, Net_Masterlist_Callback),	"Official id Master For TeamFortress Servers"},
@@ -2367,20 +2367,20 @@ void Master_CheckPollSockets(void)
 #ifdef HAVE_IPV6
 			if (!strncmp(s, "getserversResponse6", 19) && (s[19] == '\\' || s[19] == '/'))	//parse a bit more...
 			{
-				net_message.currentbit = (c+19-1)<<3;
+				net_message.currentbit = c+((19-1)<<3);
 				CL_MasterListParse(NA_IPV6, SS_GETINFO, true);
 				continue;
 			}
 #endif
 			if (!strncmp(s, "getserversExtResponse", 21) && (s[21] == '\\' || s[21] == '/'))	//parse a bit more...
 			{
-				net_message.currentbit = (c+21-1)<<3;
+				net_message.currentbit = c+((21-1)<<3);
 				CL_MasterListParse(NA_IP, SS_GETINFO, true);
 				continue;
 			}
 			if (!strncmp(s, "getserversResponse", 18) && (s[18] == '\\' || s[18] == '/'))	//parse a bit more...
 			{
-				net_message.currentbit = (c+18-1)<<3;
+				net_message.currentbit = c+((18-1)<<3);
 				CL_MasterListParse(NA_IP, SS_GETINFO, true);
 				continue;
 			}
diff --git a/engine/common/fs.c b/engine/common/fs.c
index 92a816d..b3845b1 100644
--- a/engine/common/fs.c
+++ b/engine/common/fs.c
@@ -208,7 +208,7 @@ static const gamemode_info_t gamemode_info[] = {
 //	{"-diablo2",	NULL,		"FTE-Diablo2",			{"d2music.mpq"},				NULL,	{"*",							"*fted2"},	"Diablo 2"},
 #endif
 	/* maintained by frag-net.com ~eukara */
-	{"-halflife",	"halflife",	"Rad-Therapy",	{"valve/liblist.gam"},	HLCFG,	{"valve"},	"Rad-Therapy",	"https://www.frag-net.com/pkgs/halflife.txt", "valve-patch-radtherapy;fteplug_ffmpeg"},
+	{"-halflife",	"halflife",	"Rad-Therapy",	{"valve/liblist.gam"},	HLCFG,	{"valve"},	"Rad-Therapy",	NULL, "valve-patch-radtherapy;fteplug_ffmpeg"},
 	{"-gunman",	"gunman",	"Rad-Therapy",		{"rewolf/liblist.gam"},	HLCFG,	{"rewolf"},	"Gunman Chronicles",	"https://www.gunmanchronicles.com/packages.txt", "rewolf-patch-gunman;fteplug_ffmpeg"},
 	{"-halflife2",	"halflife2",	"Rad-Therapy-II",	{"hl2/gameinfo.txt"},	HL2CFG,	{"hl2", "hl2mp"},	"Rad-Therapy II",						"https://www.frag-net.com/pkgs/halflife2.txt", "hl2-patch-radtherapy2;fteplug_ffmpeg;fteplug_ode;fteplug_hl2"},
 	{"-gmod9",	"halflife2",	"Rad-Therapy-II",	{"gmod9/gameinfo.txt"},	HL2CFG,	{"css", "hl2", "hl2mp", "gmod9"},	"Free Will",		"https://www.frag-net.com/pkgs/halflife2.txt", "hl2mp-mod-gmod9;fteplug_ffmpeg;fteplug_ode;fteplug_hl2"},
diff --git a/engine/server/sv_main.c b/engine/server/sv_main.c
index 8bc36e9..1a40734 100644
--- a/engine/server/sv_main.c
+++ b/engine/server/sv_main.c
@@ -1406,6 +1406,7 @@ static void SVC_GetInfo (const char *challenge, int fullstatus)
 	*resp++ = '\n';

 	SV_GeneratePublicServerinfo(resp, response+sizeof(response));
+	resp += strlen(resp);

 	if (fullstatus)
 	{
PATCH

echo "FTEQW patched successfully"
