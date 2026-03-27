#!/bin/bash
set -euo pipefail

FTEQW_DIR="${1:?Usage: patch-fteqw.sh <fteqw-source-dir>}"

patch -p1 -d "$FTEQW_DIR" <<'PATCH'
--- a/engine/server/sv_main.c
+++ b/engine/server/sv_main.c
@@ -1406,6 +1406,7 @@ static void SVC_GetInfo (const char *challenge, int fullstatus)
 	*resp++ = '\n';

 	SV_GeneratePublicServerinfo(resp, response+sizeof(response));
+	resp += strlen(resp);

 	if (fullstatus)
 	{
--- a/engine/client/net_master.c
+++ b/engine/client/net_master.c
@@ -153,8 +153,8 @@ static net_masterlist_t net_masterlist[] = {
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
--- a/engine/client/m_download.c
+++ b/engine/client/m_download.c
@@ -37 +37 @@
-cvar_t	pkg_autoupdate = CVARFD("pkg_autoupdate", "-1", CVAR_NOTFROMSERVER|CVAR_NOSAVE|CVAR_NOSET|CVAR_NORESET, "Controls autoupdates, can only be changed via the downloads menu.\n0: off.\n1: enabled (stable only).\n2: enabled (unstable).\nNote that autoupdate will still prompt the user to actually apply the changes."); //read from the package list only.
+cvar_t	pkg_autoupdate = CVARFD("pkg_autoupdate", "0", CVAR_NOTFROMSERVER|CVAR_NOSAVE|CVAR_NOSET|CVAR_NORESET, "Controls autoupdates, can only be changed via the downloads menu.\n0: off.\n1: enabled (stable only).\n2: enabled (unstable).\nNote that autoupdate will still prompt the user to actually apply the changes."); //read from the package list only.
--- a/engine/common/fs.c
+++ b/engine/common/fs.c
@@ -211 +211 @@
-	{"-halflife",	"halflife",	"Rad-Therapy",	{"valve/liblist.gam"},	HLCFG,	{"valve"},	"Rad-Therapy",	"https://www.frag-net.com/pkgs/halflife.txt", "valve-patch-radtherapy;fteplug_ffmpeg"},
+	{"-halflife",	"halflife",	"Rad-Therapy",	{"valve/liblist.gam"},	HLCFG,	{"valve"},	"Rad-Therapy",	NULL, "valve-patch-radtherapy;fteplug_ffmpeg"},
PATCH

echo "FTEQW patched successfully"
