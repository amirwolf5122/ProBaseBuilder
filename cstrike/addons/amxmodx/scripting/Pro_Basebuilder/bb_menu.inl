/*
Base Builder Zombie Mod
AmirWolf

Version 7.0
*/

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>

public globalMenu(id){
	
	new gText[512], szCache1[32], iLen = 0;
	
	ArrayGetString(g_zclass_name, g_iZombieClass[id], szCache1, charsmax(szCache1))
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\d|\r•\d| \w[BB] ProBuilder \rNew Mode \d|\r•\d|^n");
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r1\d| \r[ \wBuy Weapons\r ]");
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r2\d| %s", (g_boolCanBuild) ? "\r[ \dExtra Iteams\r ] \d[\rOnly in Prep Time\d]" : "\r[ \wExtra Iteams\r ]");
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r3\d| \r[ \wZombie Class\r ] \d[\r%s\d]", szCache1);
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r4\d| \r[ \wPlayer Menu\r ]");
	
	if(!ReviveUsedViP[id] && access(id, FLAGS_VIP) && g_boolPrepTime && cs_get_user_team(id) == CS_TEAM_CT)
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r5\d| \r[ \wRespawn \r ] [ \yOnly in Prep Time \w[\r1\w] \r] [ \yVIP\r ]");
	}
	else
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r5\d| \r[ \w%s\r ]", (cs_get_user_team(id) == CS_TEAM_SPECTATOR) ? "Spec Join" : "Respawn");
	}
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r6\d| \r[ %sUnstuck\r ]", (g_boolCanBuild || g_boolPrepTime) ? "\w" : "\d");
	
	if (userTeam[id])
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r7\d| \r[ \wTeam z:\y %s\r ]", userName[userTeam[id]]);
	}
	else
	{
		iLen += formatex(gText[iLen],  charsmax(gText) - iLen, "^n\d|\r7\d| \r[ \wInvite to the Team\r ]");
	}
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r9\d| \r[ %sAdmin Menu\r ]", (get_user_flags(id) & FLAGS_BUILDBAN) ? "\w" : "\d");
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r0\d| \wExit");
	
	show_menu(id, KEYS_GENERIC, gText, -1, "globalMenu")
	return PLUGIN_HANDLED
}

public globalMenu_2(id, item){
	
	switch(item){
		
		case 0:client_cmd(id, "say /guns");
		case 1:client_cmd(id, "say /shop");
		case 2:show_zclass_menu(id, 0);
		case 3:PlayerMenu(id);
		case 4:
		{
			if(cs_get_user_team(id) == CS_TEAM_SPECTATOR)
			{
				switch( random_num( 1, 2 ) )
				{
					case 1: cs_set_user_team( id, CS_TEAM_T );
					case 2: cs_set_user_team( id, CS_TEAM_CT );
				}
			}
			else if(!ReviveUsedViP[id] && access(id, FLAGS_VIP) && g_boolPrepTime && cs_get_user_team(id) == CS_TEAM_CT)
			{
				ExecuteHamB(Ham_CS_RoundRespawn, id)
				ReviveUsedViP[ id ] = true
			}else client_cmd(id, "say /respawn");
		}
		case 5:cmdUnstuck(id), globalMenu(id)
		case 6:teamOption(id);
		case 8: { // Admin Menu
			// Check if player has the required access
			if(access(id, FLAGS_BUILDBAN))
			{
				adminMenu(id);
			}
			else print_color(id, "%s ^x03only Admin can open this menu.", MODNAME)
		}
	}
	return PLUGIN_CONTINUE;
}

public PlayerMenu(id){
	
	new gText[512], iLen = 0;
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\d|\r•\d| \w[BB] ProBuilder \rPlayer Menu \d|\r•\d|^n")
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r1\d| \r[ \wCurrent Color\r ]\w: \d[ \r%s\d ]", g_szColorName[g_iColor[id]][ColorName]);
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r2\d| \r[ \wBlock Mod\r ]\w: %s", userMoverBlockColor[id] == BLOCK_COLOR ? "\wNormall" : userMoverBlockColor[id] == BLOCK_RENDER ? "\yTransparent" : "\dWithout color");
	
	if(access(id, FLAGS_VIP)) // VIP LOCK
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r3\d| \r[ \wLock Mod\r ]\w: %s", userLockBlock[id] ? "\yON" : "\dOFF")
	}
	else
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r3\d| \r[ \dLock Mod\r ]\w: \dOFF \r[ \yVIP\r ]")
	}
	
	if(access(id, FLAGS_GUNS)) // ADMIN LOCK
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r4\d| \r[ \wAuto Lock\r ]\w: %s", AutoLockBlock[id] ? "\yON" : "\dOFF")
	}
	else
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r4\d| \r[ \dAuto Lock\r ]\w: \dOFF \r[ \yAdmin\r ]")
	}
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r5\d| \r[ \wRandom Colors\r ]");
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r6\d| \r[ \wPlay Music\r ]\w: %s", userMusic[id] ? "\yON" : "\dOFF");
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r7\d| \r[ \wThird person view\r ]\w: %s", userViewCamera[id] ? "\yON" : "\dOFF");
	
	if(access(id, FLAGS_VIP) && g_boolCanBuild && cs_get_user_team(id) == CS_TEAM_CT)
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r8\d| \r[ \wPlayer Speed\r ]\w: \y%d", floatround(Float:userPlayerSpeed[id]));
	}
	else
	{
		iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\d|\r8\d| \r[ \dPlayer Speed\r ]\w: \dOFF %s", (get_user_flags(id) & FLAGS_VIP) ? "" : "\r[ \yVIP\r ]")
	}
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n^n\d|\r0\d| \wExit");
	
	show_menu(id, KEYS_GENERIC, gText, -1, "PlayerMenu")
	return PLUGIN_HANDLED
}

public PlayerMenu_2(id, item){
	
	switch(item){
		
		case 0:{
			show_colors_menu(id, 0);
			return PLUGIN_HANDLED
		}
		case 1:{
			userMoverBlockColor[id] = (userMoverBlockColor[id]+1) % 3;
		}
		case 2:{if(access(id, FLAGS_BUILDBAN)){
			userLockBlock[id] = !userLockBlock[id];
			}else print_color(id, "%s ^x03You do not have access.", MODNAME)
		}
		case 3:{if(access(id, FLAGS_GUNS)){
			AutoLockBlock[id] = !AutoLockBlock[id];
			}else print_color(id, "%s ^x03You do not have access.", MODNAME)
		}		
		case 4:{
			client_cmd(id, "say /random");
		}
		case 5:{
			userMusic[id] =! userMusic[id];
			if(!userMusic[id]){
				client_cmd(id,"mp3 stop")
			}
		}
		case 6:{
			userViewCamera[id] =! userViewCamera[id];
			if(userViewCamera[id])
				set_view(id,CAMERA_3RDPERSON);
			else set_view(id, CAMERA_NONE);
		}
		case 7:{
			if(is_user_alive(id) && access(id, FLAGS_VIP) && g_boolCanBuild && cs_get_user_team(id) == CS_TEAM_CT){
			if ((userPlayerSpeed[id] += 100.0) > 560.0) 
				userPlayerSpeed[id] = 260.0;
			set_user_maxspeed(id, Float:userPlayerSpeed[id])
			}else print_color(id, "%s ^x03You do not have access.", MODNAME)
		}
		case 9: // exit
		{
			return PLUGIN_HANDLED
		}
	}
	PlayerMenu(id);
	return PLUGIN_CONTINUE;
}

public adminMenu(id){ // Admin Menu
	
	new gText[512]
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wAdmin Menu\d:", "adminMenu_2")
	
	formatex(gText, charsmax(gText), " \yNoClip\d:\w  [ %s \w]", userNoClip[id] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \yGodMod\d:\w  [ %s \w]", userGodMod[id] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \yCounting Down: \w  [ %s \w]^n", !clockStop ? "\rNormal" : "\dStopped")
	menu_additem(menu, gText)
	menu_additem(menu, " \wCommands Menu  \d[\rBaseBuilde\d]")
	menu_additem(menu, " \wPermissions  \d[\rStart Helping\d]")
	menu_additem(menu, " \wAmx Mod X")
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED
}

public adminMenu_2(id, menu, item)
{
	switch(item){
		
		case 0:{
			userNoClip[id] =! userNoClip[id];
			set_user_noclip(id, userNoClip[id]);
			adminMenu(id);
		}
		case 1:{
			userGodMod[id] =! userGodMod[id];
			set_user_godmode(id, userGodMod[id]);
			adminMenu(id);
		}
		case 2:{
			clockStop =! clockStop;
			print_color(0, "%s Admin %s %s Counting Down", MODNAME, userName[id], clockStop ? "Stopped" : "Resumed");
			adminMenu(id);
		}
		case 3:client_cmd(id, "amx_clcmdmenu")
		case 4:{
			selectAimingMoveAs(id);
			if (id != userMoveAs[id] && userMoveAs[id]){
				helpingMenu(id);
			}else{
				adminMenu(id);
				print_color(id, "%s ^x03Target the player", MODNAME)
			}
		}
		case 5:client_cmd(id, "amxmodmenu")
	}
	if(userNoClip[id] || userGodMod[id]){
		set_rendering(id, kRenderFxGlowShell, 120, 250, 50, kRenderNormal, 5);		
	} else set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	
	menu_destroy(menu)
	return PLUGIN_CONTINUE;
}

public helpingMenu(id){ // Admin Menu
	
	if(!is_user_connected(id) && !g_isAlive[id]) return PLUGIN_CONTINUE;
	
	new gText[512], target = userMoveAs[id];
	
	formatex(gText, charsmax(gText), "\d[\r ProBuilder \d] \y- \wYou help the player\d: \r[ \y%s \r]", userName[target])
	new menu = menu_create(gText, "helpingMenu_2")
	
	formatex(gText, charsmax(gText), " \yNoClip\d: \r[ \y%s \r]\w  [ %s \w]", userName[target], userNoClip[target] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \yGodMod\d: \r[ \y%s \r]\w  [ %s \w]", userName[target], userGodMod[target] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \yBuilding\d: \r[ \y%s \r]\w  [ %s \w]^n", userName[target], userAllowBuild[target] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	
	formatex(gText, charsmax(gText), " \wNoClip\d: \r[ \y%s \r]\w  [ %s \w]", userName[id], userNoClip[id] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wGodMod\d: \r[ \y%s \r]\w  [ %s \w]^n", userName[id], userGodMod[id] ? "\r•" : "\d•")
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wAdd Team\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	
	formatex(gText, charsmax(gText), " \wRespawn\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wSwap\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wBan Build - UnBan Build\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wGag\d: \r[ \y%s \r] \r[ \w1 min \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wSlay\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wKick\d: \r[ \y%s \r]", userName[target])
	menu_additem(menu, gText)
	formatex(gText, charsmax(gText), " \wBan Server\d: \r[ \y%s \r] \r[ \w5 min \r]", userName[target])
	menu_additem(menu, gText)
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED
}

public helpingMenu_2(id, menu, item){ // helpingMenu

	new target = userMoveAs[id];
	
	if(!is_user_connected(target)){
		adminMenu(id);
		print_color(id, "^x04The player you helped left the server!");
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}
	
	if( item == MENU_EXIT ){
		adminMenu(id);
		return PLUGIN_CONTINUE;
	}
	switch (item)
	{
		case 0:{
			userNoClip[target] =! userNoClip[target];
			set_user_noclip(target, userNoClip[target]);
		}
		case 1:{
			userGodMod[target] =! userGodMod[target];
			set_user_godmode(target, userGodMod[target]);
		}
		case 2:{
			userAllowBuild[target] =! userAllowBuild[target];
			set_user_godmode(target, userAllowBuild[target]);
		}
		case 3:{
			userNoClip[id] =! userNoClip[id];
			set_user_noclip(id, userNoClip[id]);
		}
		case 4:{
			userGodMod[id] =! userGodMod[id];
			set_user_godmode(id, userGodMod[id]);
		}
		case 5:{
			if(userTeam[id] == 0 && userTeam[target] == 0){
			
				userTeam[id]		= target;
				userTeam[target] 	= id;
				
				print_color(id, "%s Team z^4 %s^1 active", MODNAME, userName[target]);
				print_color(target, "%s Team z^4 %s^1 active", MODNAME, userName[id]);
				
				menuTeamOption(id);
				menuTeamOption(target);
				
			}
		}
		case 6:{
			cmdRevive(id, target);
		}
		case 7:{
			cmdSwap(id, target);
		}
		case 8:{
			cmdBuildBan(id, target);
		}
		case 9:{
			server_cmd("amx_gag #%i ^"60^"", get_user_userid(target))
		}
		case 10:{
			user_kill(target, 1);
		}
		case 11:{
			server_cmd("amx_kick #%i", get_user_userid(target));
		}
		case 12:{
			server_cmd("amx_ban #%i ^"1^"", get_user_userid(target));
		}
	}
	if(userNoClip[target] || userGodMod[target] || userAllowBuild[target]){
		set_rendering(target, kRenderFxGlowShell, 120, 250, 50, kRenderNormal, 5);		
	} else set_rendering(target, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	
	if(userNoClip[id] || userGodMod[id]){
		set_rendering(id, kRenderFxGlowShell, 120, 250, 50, kRenderNormal, 5);		
	} else set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0);
	helpingMenu(id)
	menu_destroy(menu);
	return PLUGIN_CONTINUE
}


public menuSpecifyUser(id, szName[]){
	
	if(!is_user_connected(id)) return;
	
	new gText[128], szNameEdit[48];
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wWho do you mean\r?", "menuSpecifyUser_2");
	strToLower(szName);
	for( new i = 1, x = 0;  i < MAXPLAYERS; i ++ ){
		
		if( !is_user_connected(i) || is_user_hltv(i)) continue;	
		if( containi(userName[i], szName) == -1) continue;
		
		format(szNameEdit, sizeof(szNameEdit), "%s\w", szName);	
		strToLower(szName);
		format(gText, sizeof(gText), "%s", userName[i]);
		strToLower(gText);
		replace_all(gText, sizeof(gText)-1, szName, szNameEdit);
		strFix(gText, userName[i]);
		menu_additem(menu, gText);
		userVarList[id][x++] = i ;
	}
	menu_display(id, menu, 0);
}

public strFix(szString[], szName[]){
	for( new i = 0, x = 0 ; i < strlen(szString); i ++){
		if(szString[i] == 92){
			i++;
			continue;
		}
		szString[i] = szName[x++];
	}
}

public strToLower( szString[]){
	for( new i = 0 ; i < strlen(szString) ; i ++ ){
		szString[i] = tolower(szString[i]);
	}
}

public menuSpecifyUser_2(id, menu, item){
	if( item == MENU_EXIT ){
		menu_destroy(menu);
		return;
	}
	new target = userVarList[id][item];
	switch(userVarMenu[id]){
		case 0:cmdRevive(id, target);
		case 1:cmdSwap(id, target);
		case 2:cmdBuildBan(id, target);
		case 3:{
			userNoClip[id] = true;
			set_user_noclip(id, userNoClip[id]);
			adminMenu(id);
			new Float:fOrigin[3] = 0.0;
			pev(target, pev_origin, fOrigin);
			set_pev(id, pev_origin, fOrigin);
		}
	}
}

public selectAimingMoveAs(id){
	if (access(id, FLAGS_BUILDBAN)){
		new ent, body;
		
		get_user_aiming(id, ent, body, 9999);
		if (!isPlayer(ent)){
			new szClass[10], szTarget[7];
			entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass));
			entity_get_string(ent, EV_SZ_targetname, szTarget, sizeof(szTarget));
			if (equal(szClass, "func_wall") && !equal(szTarget, "ignore")){
				if (GetEntMover(ent)) ent = GetEntMover(ent);
				else ent = id;
			} else ent = id;
		}
		if (userMoveAs[id] != ent){
			userMoveAs[id] = ent;
		}
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public light(id){
	
	if(!is_user_connected(id)) return;
	
	new gText[256], bar[256];
	if(!lightType[0] ) format(gText, sizeof(gText),"\dLight:\r Normal");
	else format(gText, sizeof(gText),"\dLight:\r %d%%\w [\d %d/%d\w -\d %c\w ]",  ( lightType[0] * 100 / strlen(lightCharacter)), lightType[0], strlen(lightCharacter), lightCharacter[lightType[0]-1]);
	new menu = menu_create(gText, "light_2");
	barMenu(bar, sizeof(bar), lightType[0] , strlen(lightCharacter), "|", "|") ;   

	format(gText, sizeof(gText), "%s", bar);
	menu_additem(menu, bar);

		
	menu_display(id, menu, 0);
}	
public light_2(id, menu, item){
	if(item == MENU_EXIT){
		menu_destroy(menu);
		return;
	}
	switch(item){
		case 0:{
			new bufferBit[32];
			
			if((lightType[0] ++) >= strlen(lightCharacter)){
				for(new i = 0; i < 2; i ++) lightType[i] = 0;
				set_lights("#OFF");
			}	
			lightType[1] ^= ( 1 << lightType[0] - 1 );
			stringBuffer(lightType[1], bufferBit, sizeof(bufferBit));
			set_lights(bufferBit);
			light(id);
		}	
		
	}
}

public cmdUnstuck(id){
	if(!(g_boolCanBuild || g_boolPrepTime)) return PLUGIN_CONTINUE;
	
	static Float:origin[3];
	static Float:mins[3], hull;
	static Float:vec[3];
	static o;
	if (is_user_connected(id) && is_user_alive(id)){
		pev(id, pev_origin, origin);
		hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
		if (!is_hull_vacant(origin, hull,id) && (!get_user_noclip(id) || !userNoClip[id] ) && !(pev(id,pev_solid) & SOLID_NOT)) {
			++stuck[id];
			pev(id, pev_mins, mins);
			vec[2] = origin[2];
			for (o=0; o < sizeof size; ++o) {
				vec[0] = origin[0] - mins[0] * size[o][0];
				vec[1] = origin[1] - mins[1] * size[o][1];
				vec[2] = origin[2] - mins[2] * size[o][2];
				if (is_hull_vacant(vec, hull,id)) {
					engfunc(EngFunc_SetOrigin, id, vec);
					
					fade_user_screen(id, 0.5, 0.5, .r = 255, .g = 32, .b = 32, .a = 90)
					set_dhudmessage(255, 32, 32, -1.0, 0.3, 0, 0.5, 0.9, 0.5, 0.5);
					show_dhudmessage(id, "!! Unlocked !!");
					
					set_pev(id,pev_velocity,{0.0,0.0,0.0});
					o = sizeof(size);
				}	
			}
		}
		else stuck[id] = 0;	
	}
	return PLUGIN_CONTINUE;
}