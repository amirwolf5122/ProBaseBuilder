enum
{
	save_TEAM,
	save_TEAM_COLOR
};

new userMenuId, userTeam[MAXPLAYERS+1], userTeamMenu[MAXPLAYERS+1], userTeamSend[MAXPLAYERS+1], userTeamBlock[MAXPLAYERS+1], userSaveOption[MAXPLAYERS+1], Float:userTeamLine[MAXPLAYERS+1];

public menuTeamOption(id)
{
	if(!is_user_connected(id)) return;
	
	new teammate = userTeam[id];
	
	if(teammate == 0)
	{
		CC_SendMessage(id, "%s ^x04[Team] ^x01You are no longer in a team", MODNAME);
		return;	
	}
	
	if (!is_user_connected(teammate))
    {
		userTeam[id] = 0;
		removeOption(userSaveOption[id], save_TEAM_COLOR);
		CC_SendMessage(id, "%s ^x04[Team] ^x01Your teammate ^x04is unavailable,^x01 the team was disbanded", MODNAME);
		return;
	}
	
	new gText[256], szTargetPlayerName[32], iLen = 0;
	get_user_name(teammate, szTargetPlayerName, charsmax(szTargetPlayerName));
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\d[\r ProBuilder \d] \y- \wTeams menu^n^n");
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\y^xc2^xbb^t^t\dYour current teammate is:\r %s^n", szTargetPlayerName);
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\y^xc2^xbb^t^t\dTeam bonuses may change each round^n");
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "^n\y^xc2^xbb^t^t\dTeleport to your teammate:\r ( CTRL + 2 )");
	
	new menu = menu_create(gText, "menuTeamOption_2");
	
	if (hasOption(userSaveOption[id], save_TEAM_COLOR))
	{
		if (!hasOption(userSaveOption[teammate], save_TEAM_COLOR))
		{
			formatex(gText, charsmax(gText) , "Team Color Sync: \y[Enabled] \d[Teammate: \rDisabled\d]^n");
		}
		else
		{
			formatex(gText, charsmax(gText), "Team Color Sync: \r[Enabled]^n");
		}
	}
	else
	{
		if (hasOption(userSaveOption[teammate], save_TEAM_COLOR))
		{
			formatex(gText, charsmax(gText), "Team Color Sync: \y[Disabled] \d[Teammate: \rEnabled\d]^n");
		}
		else
		{
			formatex(gText, charsmax(gText), "\yTeam Color Sync: \d[Disabled]^n");
		}
	}
	menu_additem(menu, gText);
	
	new bool:canTeleport = g_boolCanBuild && !g_isZombie[id];
	
	menu_additem(menu, canTeleport ? "Teleport\d [\y CTRL + 2\d ]" : "\dTeleport [ CTRL + 2 ]");
	menu_additem(menu, g_boolCanBuild ? "Leave Team" : "\dLeave Team");
	
	menu_display(id, menu, 0);
}

public menuTeamOption_2(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new teammate = userTeam[id];
	
	switch (item)
	{
		case 0:
		{
			if (hasOption(userSaveOption[id], save_TEAM_COLOR))
			{
				removeOption(userSaveOption[id], save_TEAM_COLOR);
				CC_SendMessage(id, "%s ^x04[Team]^x01 Color Sync with teammate:^x04 Disabled", MODNAME);
			}
			else
			{
				addOption(userSaveOption[id], save_TEAM_COLOR);
				CC_SendMessage(id, "%s ^x04[Team]^x01 Color Sync with teammate:^x04 Enabled", MODNAME);
			}
			
			menuTeamOption(id);
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			if (g_isZombie[id])
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 Zombies cannot use^x03 Teleport", MODNAME);
				menuTeamOption(id);
				return PLUGIN_HANDLED;
			}
			
			if (!g_boolCanBuild)
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 Teleporters are only active during^x04 Build Time", MODNAME);
				menuTeamOption(id);
				return PLUGIN_HANDLED;
			}
			
			if (!AreAliveTeammates(id, teammate))
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 Your teammate is not available for teleport", MODNAME);
				menuTeamOption(id);
				return PLUGIN_HANDLED;
			}
			
			if (pev(id, pev_button) & IN_DUCK)
			{
				new Float:fOrigin[3], Float:fAngles[3];
				pev(teammate, pev_origin, fOrigin);
				pev(teammate, pev_angles, fAngles);
				Util_SetOrigin(id, fOrigin, fAngles);
				
				new szPlayerName[32], szTargetPlayerName[32];
				get_user_name(id, szPlayerName, charsmax(szPlayerName));
				get_user_name(teammate, szTargetPlayerName, charsmax(szTargetPlayerName));
				
				CC_SendMessage(id, "%s ^x04[Team]^x01 You have teleported to^x04 %s", MODNAME, szTargetPlayerName);
				CC_SendMessage(teammate, "%s ^x04[Team]^x04 %s^x01 has teleported to you!", MODNAME, szPlayerName);
				
				menu_destroy(menu);
			}
			else
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 Press ^x04[Ctrl]^x01 to teleport to your teammate", MODNAME);
				menuTeamOption(id);
			}
		}
		case 2:
		{
			if (!g_boolCanBuild)
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 You can only leave your team during^x04 Build Time", MODNAME);
				menuTeamOption(id);
				return PLUGIN_HANDLED;
			}
			
			if (is_user_connected(teammate))
			{
				userTeam[teammate] = 0;
				removeOption(userSaveOption[teammate], save_TEAM_COLOR);
				CC_SendMessage(teammate, "%s ^x04[Team]^x01 Your teammate has^x04 left the team", MODNAME);
			}
			
			userTeam[id] = 0;
			removeOption(userSaveOption[id], save_TEAM_COLOR);
			CC_SendMessage(id, "%s ^x04[Team]^x01 You have^x04 left the team", MODNAME);
			menu_destroy(menu);
		}
	}
	return PLUGIN_HANDLED;
}

public teamOption(id)
{
	if (userTeam[id] == 0)
	{
		if (menuTeam(id) == 0)
		{
			CC_SendMessage(id, "%s ^x04[Team]^x01 No other available players to team up with", MODNAME);
		}
		return;
	}
	
	new teammate = userTeam[id];
	
	if (!IsValidBuilderTeam(id, teammate))
	{
		if (is_user_connected(teammate))
		{
			userTeam[teammate] = 0;
			CC_SendMessage(teammate, "%s ^x04[Team]^x01 Your team was disbanded", MODNAME);
		}
		
		userTeam[id] = 0;
		CC_SendMessage(id, "%s ^x04[Team]^x01 Your team has been disbanded", MODNAME);
		
		if (menuTeam(id) == 0)
		{
			CC_SendMessage(id, "%s ^x04[Team]^x01 No other available players to team up with", MODNAME);
		}
		return;
	}
	menuTeamOption(id);
}

public menuTeam(id)
{
	if (!is_user_connected(id)) return 0;

	new gText[128];
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wSend Team Invite", "menuTeam_2");
	
	formatex(gText, charsmax(gText), "\yBlock Team Invitations: %s^n", hasOption(userSaveOption[id], save_TEAM) ? "\r[Enabled]" : "\d[Disabled]");
	menu_additem(menu, gText);
	
	new x = 1;
	for (new i = 1; i < MAXPLAYERS; i++)
	{
		if (!AreAliveTeammates(id, i))
		{
			continue;
		}

		if (i == id || userTeamBlock[i] || hasOption(userSaveOption[i], save_TEAM) || userTeam[i] != 0)
		{
			continue;
		}
		
		get_user_name(i, gText, charsmax(gText));
		menu_additem(menu, gText);
		userVarList[id][x++] = i;
	}
	
	menu_display(id, menu, 0);
	return x;
}

public menuTeam_2(id, menu, item)
{
 	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch (item)
	{
		case 0:
		{
			if (hasOption(userSaveOption[id], save_TEAM))
			{
				removeOption(userSaveOption[id], save_TEAM);
				CC_SendMessage(id, "%s ^x04[Team]^x01 Team Preference: ^x04Unlocked", MODNAME);
			}
			else
			{
				addOption(userSaveOption[id], save_TEAM);
				CC_SendMessage(id, "%s ^x04[Team]^x01 Team Preference: ^x04Locked", MODNAME);
			}
			menuTeam(id);
			return PLUGIN_HANDLED;
		}
		default:
		{
			new target = userVarList[id][item];
			
			if (!AreAliveTeammates(id, target))
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 You can only team up with players on your team", MODNAME);
				menuTeam(id);
				return PLUGIN_HANDLED;
			}
			
			if (userTeamBlock[target] || hasOption(userSaveOption[target], save_TEAM) || userTeam[target] != 0)
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 This player cannot receive invites right now", MODNAME);
				menuTeam(id);
				return PLUGIN_HANDLED;
			}
			
			new szTargetPlayerName[32], szPlayerName[32];
			get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
			get_user_name(id, szPlayerName, charsmax(szPlayerName));
			
			userMenuId++;
			
			userTeamMenu[id] = userMenuId;
			userTeamMenu[target] = userMenuId;
			userTeamSend[target] = id;
			
			CC_SendMessage(id, "%s ^x04[Team]^x01 Team invite sent to ^x03%s", MODNAME, szTargetPlayerName);
			CC_SendMessage(target, "%s ^x04[Team]^x01 You received a team invite from ^x04%s", MODNAME, szPlayerName);
			
			menuConfirmationTeam(target);
		}
	}
	
	return PLUGIN_HANDLED;
}

public menuConfirmationTeam(id)
{
	if (!is_user_connected(id)) return;
	
	new target = userTeamSend[id];
	if (!is_user_connected(target))
	{
		CC_SendMessage(id, "%s ^x04[Team]^x01 The inviter^x04 is unavailable", MODNAME);
		return;
	}

	new gText[256], szTargetPlayerName[32], iLen = 0;
	get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
	
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\d[\r ProBuilder \d] \y- \wYou've been invited to the party!^n^n");
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\y^xc2^xbb^t^t\dTeam invitation sent by\r %s!^n", szTargetPlayerName);
	iLen += formatex(gText[iLen], charsmax(gText) - iLen, "\y^xc2^xbb^t^t\dDo you want to create a team?^n");

	new menu = menu_create(gText, "menuConfirmationTeam_2");
	
	menu_additem(menu, "Accept");
	menu_additem(menu, "Decline");
	menu_display(id, menu, 0);
}

public menuConfirmationTeam_2(id, menu, item)
{
	new target = userTeamSend[id];
	if (item == MENU_EXIT || !is_user_connected(id) || !is_user_connected(target))
	{
		menu_destroy(menu);
		return;
	}
	
	new szTargetPlayerName[32], szPlayerName[32];
	get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	
	switch(item)
	{
		case 0:
		{
			if (userTeamMenu[id] != userTeamMenu[target])
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 This team invite has expired", MODNAME);
				return;
			}
			
			if (!ArePlayersOnSameTeam(id, target))
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 That player is on the opposing team", MODNAME);
				return;
			}
			
			if (ArePlayersTeammates(id, target) || ArePlayersTeammates(target, id))
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 Either you or ^x04%s^x01 have already joined another team", MODNAME, szTargetPlayerName);
				return;
			}
			
			userTeam[id]		= target;
			userTeam[target] 	= id;
				
			CC_SendMessage(id, "%s ^x04[Team]^x01 Your teammate is ^x03 %s", MODNAME, szTargetPlayerName);
			CC_SendMessage(target, "%s ^x04[Team]^x01 Your teammate is ^x03 %s", MODNAME, szPlayerName);
				
			menuTeamOption(id);
			menuTeamOption(target);
		}
		case 1:
		{
			CC_SendMessage(id, "%s ^x04[Team]^x03 %s ^x01 has ^x04 rejected ^x01 your team invite", MODNAME, szTargetPlayerName);
			CC_SendMessage(target, "%s ^x04[Team]^x01 You have ^x04 rejected the team invite from ^x03%s", MODNAME, szPlayerName);
		}
	}
	menu_destroy(menu);
}

public CheckTeamOnSpawn(id)
{
	new teammate = userTeam[id];
	
	if (!IsValidBuilderTeam(id, teammate))
	{
		userTeam[id] = 0;
		removeOption(userSaveOption[id], save_TEAM_COLOR);
		CC_SendMessage(id, "%s ^x04[Team]^x01 Your team was disbanded because you are on different teams now", MODNAME);
		
		if (is_user_connected(teammate))
		{
			userTeam[teammate] = 0;
			removeOption(userSaveOption[teammate], save_TEAM_COLOR);
			
			new szPlayerName[32];
			get_user_name(id, szPlayerName, charsmax(szPlayerName));
			
			CC_SendMessage(teammate, "%s ^x04[Team]^x01 Your team with ^x03%s^x01 was disbanded", MODNAME, szPlayerName);
		}
	}
}

public teamLineOrSprite(id)
{
	new team_mate = userTeam[id];
	if (!ArePlayersTeammates(id, team_mate) || !is_user_alive(team_mate) || g_isZombie[team_mate])
	{
		return;
	}
	
	new fOriginId[3], fOriginTeam[3];
	GetUserFootOrigin(id, fOriginId);
	GetUserFootOrigin(team_mate, fOriginTeam);

	if (get_distance(fOriginId, fOriginTeam) > 232)
	{
		te_attach_model_to_player(team_mate, g_iSpriteIDs[SPRITE_TEAM], 40, 11, id);
		
		new Float:game_time = get_gametime();
		if (floatsub(game_time, userTeamLine[id]) > 3.0)
		{
			userTeamLine[id] = game_time;
			te_create_beam_between_points(fOriginId, fOriginTeam, g_iSpriteIDs[SPRITE_BLUE], 0, 25, 11, 10, 0, 25, 65, 170, 255, 255, id);
		}
	}
}

stock bool:ArePlayersOnSameTeam(player1, player2)
{
	if (!is_user_connected(player1) || !is_user_connected(player2))
	{
		return false;
	}
	return (get_user_team(player1) == get_user_team(player2));
}

stock bool:AreAliveTeammates(player1, player2)
{
	if (!is_user_connected(player1) || !is_user_alive(player1) || !is_user_connected(player2) || !is_user_alive(player2))
	{
		return false;
	}
	return (get_user_team(player1) == get_user_team(player2));
}

stock bool:ArePlayersTeammates(player1, player2)
{
	if (!is_user_connected(player1) || !is_user_connected(player2))
		return false;
	
	if (userTeam[player1] == 0 || userTeam[player2] == 0)
		return false;
	
	return (userTeam[player1] == player2 && userTeam[player2] == player1);
}

stock bool:IsValidBuilderTeam(player1, player2)
{
	if (!ArePlayersTeammates(player1, player2))
	{
		return false;
	}
	if (g_boolCanBuild)
	{
		if (!ArePlayersOnSameTeam(player1, player2))
		{
			return false;
		}
	}
	return true;
}

stock bool:hasOption(var, option)
{
	return !!(var&(1<<option));
}

stock addOption(&var, option)
{
	var |= (1<<option);
}

stock removeOption(&var, option)
{
	var &= ~(1<<option);
}

stock GetUserFootOrigin(id, origin[3]) 
{
	new Float:temp, Float:ground[3];
	
	pev(id, pev_absmin, ground);
	temp = ground[2];
	pev(id, pev_origin, ground);
	ground[2] = temp + 2.0;
	
	origin[0] = floatround(ground[0]);
	origin[1] = floatround(ground[1]);
	origin[2] = floatround(ground[2]);
}