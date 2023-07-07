#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>

public menuTeamOption(id){
	
	if(!is_user_connected(id)) return;

	new gText[256], iLen = 0;
	if(userTeam[id] == 0){
		print_color(id, "%s You no longer have a team with this player!", MODNAME);
		return;	
	}
	iLen += format(gText[iLen], sizeof(gText)-iLen-1, "\r[BaseBuilder]\y Teams menu^n^n");
	
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "\y%s^t^t\dYou currently have a team z:\r %s^n", symbolsCustom[SYMBOL_DR_ARROW], userName[userTeam[id]]);
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "\y%s^t^t\dEach round a different value is drawn!^n", symbolsCustom[SYMBOL_DR_ARROW]);
	
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "^n\y%s^t^t\dTo teleport\r ( Crouch and click 1 )", symbolsCustom[SYMBOL_DR_ARROW]);
	
	new menu = menu_create(gText, "menuTeamOption_2");
	
	menu_additem(menu, "Teleport\d [\y Crouch\d ]");
	
	if( g_boolCanBuild || g_boolPrepTime || (get_user_team(id) != get_user_team(userTeam[id])))
		menu_additem(menu, "Disconnect");
	else menu_additem(menu, "\dDisconnect");
	
	menu_display(id, menu, 0);
}
public menuTeamOption_2(id, menu, item){
	if( item == MENU_EXIT){
		menu_destroy(menu);
		return;
	}
	switch(item){
		case 0:{
			if (g_boolCanBuild || g_boolPrepTime){
				if (userTeam[id] && cs_get_user_team(id) == CS_TEAM_CT){
					if (is_user_alive(userTeam[id]) && is_user_connected(userTeam[id]) && get_user_team(userTeam[id]) == get_user_team(id)){
						if (pev(id, pev_button) & IN_DUCK){
							new Float:fOrigin[3] = 0.0;
							pev(userTeam[id], pev_origin, fOrigin);
							set_pev(id, pev_origin, fOrigin);
							menuTeamOption(id);
							return;
						}
						menuTeamOption(id);
						print_color(id, "%s Crouch to use the teleporter", MODNAME);
					}
				}
			} else {
				print_color(id, "%s Teleport is disabled during the round!", MODNAME);
				menuTeamOption(id);
			}
		}
		case 1:{
			if( g_boolCanBuild || g_boolPrepTime ||(get_user_team(id) != get_user_team(userTeam[id]))){
				new target = userTeam[id];
				
				if( target == 0 ) return;
				
				userTeam[target] = 0;
				userTeam[id] 	 = 0;
				
				print_color(id, "%s Your squad has been disconnected", MODNAME);
				print_color(target, "%s Your squad has been disconnected", MODNAME);
			}
		}
	}
}
public teamOption(id){
	if( userTeam[id] == 0 ){
		if( menuTeam(id) == 0 ){				
			print_color(id, "%s Players are missing", MODNAME);
			return;
		}	
	} else menuTeamOption(id);
}
public menuTeam(id){

	if(!is_user_connected(id)) return 0;

	new gText[128];
	new menu = menu_create("\r[BaseBuilder]\y Who do you want to invite?", "menuTeam_2");
	
	format(gText, sizeof(gText), "\yBlock the team: %s^n", hasOption(userSaveOption[id], save_TEAM) ? "\rYes" : "\dNo");
	menu_additem(menu, gText);
	
	new x = 1;
	for( new i = 1; i < MAXPLAYERS; i++ ){
		if( !is_user_connected(i) || !is_user_alive(i) || i == id || userTeamBlock[i] || hasOption(userSaveOption[i], save_TEAM)|| userTeam[i] != 0 || get_user_team(id) != get_user_team(i))  continue;
		
		format(gText, sizeof(gText), "%s", userName[i] );
		menu_additem(menu, gText);
		userVarList[id][x++] = i;
	}
	menu_display(id, menu, 0);
	return x;
}
public menuTeam_2(id,menu,item){
	if( item == MENU_EXIT ){
		menu_destroy(menu);
		return;
	}
	switch(item){
		case 0:{
			if( hasOption(userSaveOption[id], save_TEAM) ){
				removeOption(userSaveOption[id], save_TEAM);
				print_color(id, "%s Team unlocked", MODNAME);
			}else{
				addOption(userSaveOption[id], save_TEAM);
				print_color(id, "%s Team blocked", MODNAME);
			}
			menuTeam(id);
		}
		default:{
			userMenuId++;
			new target = userVarList[id][item];
			
			if( !is_user_connected(target) || userTeamBlock[target] || userTeam[target] != 0 || get_user_team(target) != get_user_team(id)) {
				print_color(id, "%s You cannot form a team with this player!", MODNAME);
				menuTeam(id);
			}
			userTeamMenu[id] 	= userMenuId;
			userTeamMenu[target] 	= userMenuId;
			userTeamSend[target] 	= id;
			
			print_color(id, "%s You sent a team invite to a player:^3 %s", MODNAME, userName[target]);
			print_color(target, "%s You have received a party invite from a player:^3 %s", MODNAME, userName[id]);
			menuConfirmationTeam(target);
		}
	}
}
public menuConfirmationTeam(id){

	if(!is_user_connected(id)) return;

	new gText[256], iLen = 0;
	new target = userTeamSend[id];
	
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "\r[BaseBuilder]\y You've been invited to the party!^n^n");
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "\y%s^t^t\dTeam invitation sent by\r %s!^n", symbolsCustom[SYMBOL_DR_ARROW], userName[target] );
	iLen += format(gText[iLen], sizeof(gText)-1-iLen, "\y%s^t^t\dDo you want to create a team?^n", symbolsCustom[SYMBOL_DR_ARROW]);

	new menu = menu_create(gText, "menuConfirmationTeam_2");
	
	menu_additem(menu, "Yes, sure ");
	menu_additem(menu, "No, I prefer alone");
	menu_display(id, menu, 0);
}
public menuConfirmationTeam_2(id,menu,item){
	
	new target = userTeamSend[id];
	
	if( item == MENU_EXIT ){
		menu_destroy(menu);
		return;
	}
	switch(item){
		case 0:{
			if( userTeamMenu[id] != userTeamMenu[target] ){
				print_color(id, "%s Too late to accept", MODNAME);
				return;
			}
			
			if(get_user_team(id) != get_user_team(target)){
				print_color(id, "%s The person is on a different team", MODNAME);
				return;
			}
			if(userTeam[id] == 0 && userTeam[target] == 0){
			
				userTeam[id]		= target;
				userTeam[target] 	= id;
				
				print_color(id, "%s Team z^4 %s^1 active", MODNAME, userName[target]);
				print_color(target, "%s Team z^4 %s^1 active", MODNAME, userName[id]);
				
				menuTeamOption(id);
				menuTeamOption(target);
				
			}
		}
		case 1:{
			print_color(id, "%s Team od^4 %s^1 she was rejected", MODNAME, userName[target]);
			print_color(target, "%s Team z^4 %s^1 rejected", MODNAME, userName[id]);
			userTeam[id]		= 0;
			userTeam[target] 	= 0;
		}
	}
}
public teamLineOrSprite(id){
	if (userTeam[id] && !hasOption(userSaveOption[id], save_INVIS) ){
		if (teamWorks(id) && cs_get_user_team(id) == CS_TEAM_CT){
			new Float:fOriginId[3] = 0.0;
			new Float:fOriginTeam[3] = 0.0;
			pev(id, pev_origin, fOriginId);
			pev(userTeam[id], pev_origin, fOriginTeam);
			if (get_distance_f(fOriginId, fOriginTeam) > 350) Create_TE_PLAYERATTACHMENT(id, userTeam[id], 40, team_spr, 10);
			if (floatsub(get_gametime(), userTeamLine[id]) > 3.55){
				userTeamLine[id] = get_gametime();
				if (get_distance_f(fOriginId, fOriginTeam) > 350) drawLine(id, fOriginId, fOriginTeam, 25,65,170, 3, 10, 0);
			}
		}
	}
}
public bool:teamWorks(id){
	return userTeam[id] && get_user_team(userTeam[id]) == get_user_team(id);
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
