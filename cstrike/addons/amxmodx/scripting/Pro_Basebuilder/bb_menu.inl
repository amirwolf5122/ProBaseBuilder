public globalMenu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wProBuilder Menu", "globalMenu_2");
	
	new szTargetPlayerName[32], szClassName[32];
	ArrayGetString(g_zclass_name, g_iZombieClass[id], szClassName, charsmax(szClassName));
	get_user_name(userTeam[id], szTargetPlayerName, charsmax(szTargetPlayerName));
	
	add_format_item(menu, !g_boolCanBuild && g_boolRepick[id] || access(id, FLAGS_GUNS) ? "\r[ \wBuy Weapons\r ]" : "\r[ \dBuy Weapons\r ]");
	add_format_item(menu, g_boolCanBuild ? "\r[ \dExtra Items\r ] \d[\rPrep Time\d]" : "\r[ \wExtra Items\r ]");
	add_format_item(menu, "\r[ \wZombie Class\r ] \d[\r%s\d]", szClassName);
	menu_additem(menu, "\r[ \wPlayer Menu\r ]^n");
	
	if (!g_bUsedVipSpawn[id] && access(id, FLAGS_VIP) && g_boolPrepTime && !g_isZombie[id])
		add_format_item(menu, "\r[ \wRespawn \r ] [ \yPrep Time \w[\r1\w] \r] [ \yVIP\r ]");
	else
		add_format_item(menu, g_boolCanBuild ? "\r[ \wRespawn\r ]" : "\r[ \dRespawn\r ]");
	
	menu_additem(menu, g_boolCanBuild ? "\r[ \wUnstuck\r ]" : "\r[ \dUnstuck\r ]");
	
	if (ArePlayersInSameParty(id, userTeam[id]))
		add_format_item(menu, "\r[ \wTeammate:\y %s \r]", szTargetPlayerName);
	else
		menu_additem(menu, "\r[ \wSend Team Invite\r ]");
	
	menu_additem(menu, get_user_flags(id) & FLAGS_BUILDBAN ? "\r[ \wAdmin Menu\r ]" : "\r[ \dAdmin Menu\r ]");
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public globalMenu_2(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /guns");
		}
		case 1:
		{
			client_cmd(id, "say /shop");
		}
		case 2:
		{
			client_cmd(id, "say /class");
		}
		case 3:
		{
			PlayerMenu(id);
		}
		case 4:
		{
			client_cmd(id, "say /respawn");
		}
		case 5:
		{
			client_cmd(id, "say /unstuck");
		}
		case 6:
		{
			client_cmd(id, "say /team");
		}
		case 7:
		{
			client_cmd(id, "say /adminmenu");
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}


public PlayerMenu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wPlayer Menu", "PlayerMenu_2");
	
	add_format_item(menu, "\r[ %sCurrent Color\r ]\d: \d[ \r%s\d ]", g_iColorMode != 2 ? "\w" : "\d", g_aColors[g_iColor[id]][Name]);
	add_format_item(menu, "\r[ \wBlock Mod\r ]\d: %s^n", !g_playerBlockRenderMode[id] ? "\wNormal" : "\dWithout color");
	
	if (access(id, FLAGS_VIP))
		add_format_item(menu, "\r[ \wLock Mod\r ]\w: %s^n", g_bUserLockMode[id] ? "\yEnabled" : "\dDisabled");
	else
		menu_additem(menu, "\r[ \dLock Mod\r ]\d: \dDisabled \r[ \yVIP\r ]^n");
	
	menu_additem(menu, !g_isZombie[id] && g_boolCanBuild ? "\r[ \wRandom Colors\r ]^n" : "\r[ \dRandom Colors\r ]^n");
	
	if (access(id, FLAGS_VIP) && g_boolCanBuild && !g_isZombie[id])
		add_format_item(menu, "\r[ \wPlayer Speed\r ]\d: \y%d^n", floatround(g_fUserPlayerSpeed[id]));
	else
		add_format_item(menu, "\r[ \dPlayer Speed\r ]\d: \dDisabled %s^n", access(id, FLAGS_VIP) ? "" : "\r[ \yVIP\r ]");
	
	add_format_item(menu, "\r[ \wThird person view\r ]\w: %s", g_bUserViewCamera[id] ? "\yEnabled" : "\dDisabled");
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}
	
public PlayerMenu_2(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
    
	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /colors");
		}
		case 1:
		{
			g_playerBlockRenderMode[id] = !g_playerBlockRenderMode[id];
		}
        case 2:
        {
			if (RequireAccess(id, FLAGS_VIP))
            {
				g_bUserLockMode[id] = !g_bUserLockMode[id];
			}
        }	
		case 3:
		{
			client_cmd(id, "say /random");
		}
		case 4:
		{
			if (RequireAccess(id, FLAGS_VIP) && g_isAlive[id] && g_boolCanBuild && !g_isZombie[id])
			{
				if ((g_fUserPlayerSpeed[id] += 120.0) > 620.0) 
				{
					g_fUserPlayerSpeed[id] = 260.0;
					
					set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
					te_remove_all_beams_from_entity(id);
				}
				else
				{
					set_user_maxspeed(id, Float:g_fUserPlayerSpeed[id]);
					
					fade_user_screen(id, 0.5, 0.3, ScreenFade_FadeIn, 0, 100, 255, 50);
					set_user_rendering(id, kRenderFxGlowShell, 0, 100, 255, kRenderNormal, 16);
					te_create_following_beam(id, g_iSpriteIDs[SPRITE_BLUE], 10, 3, 0, 100, 255, 150);
				}
			}
		}
		case 5:
		{
			g_bUserViewCamera[id] =! g_bUserViewCamera[id];
			if(g_bUserViewCamera[id])
				set_view(id,CAMERA_3RDPERSON);
			else set_view(id, CAMERA_NONE);
		}
	}
	
	PlayerMenu(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public adminMenu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wAdmin Menu\d:", "adminMenu_2");
	
	add_format_item(menu, "NoClip\d:\w [ %s \w]", userNoClip[id] ? "\r•" : "\d•");
	add_format_item(menu, "GodMod\d:\w [ %s \w]", userGodMod[id] ? "\r•" : "\d•");
	add_format_item(menu, "Manage Countdown\d:\w [ %s \w]^n", !g_bTimerPaused ? "\yACTIVE" : "\dPAUSED");
	
	if (g_bHasReturnOrigin[id])
    {
        menu_additem(menu, "\rTeleport\w to \yPrevious Location^n");
    }
	
	menu_additem(menu, "Admin Control Panel");
	menu_additem(menu, "Player Tools");
	menu_additem(menu, "Amx Mod X");
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public adminMenu_2(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		globalMenu(id)
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new adjustedItem = item;

	if (!g_bHasReturnOrigin[id] && item >= 3)
	{
		adjustedItem++;
	}
	
	switch (adjustedItem)
	{
		case 0:
		{
			userNoClip[id] =! userNoClip[id];
			set_user_noclip(id, userNoClip[id]);
			UpdatePlayerGlow(id);
		}
		case 1:
		{
			userGodMod[id] =! userGodMod[id];
			set_user_godmode(id, userGodMod[id]);
			UpdatePlayerGlow(id);
		}
		case 2:
		{
			g_bTimerPaused =! g_bTimerPaused;
			
			new szPlayerName[32];
			get_user_name(id, szPlayerName, charsmax(szPlayerName));
			
			CC_SendMessage(0, "%s Admin ^x04%s ^x01has toggled the Round timer. It is now ^x04%s.", MODNAME, szPlayerName, g_bTimerPaused ? "PAUSED" : "ACTIVE");
		}
		case 3:
		{
			if (g_bHasReturnOrigin[id] && g_isAlive[id])
			{
				Util_SetOrigin(id, g_fAdminReturnOrigin[id], g_fAdminReturnAngles[id]);
				g_bHasReturnOrigin[id] = false;
			}else CC_SendMessage(id, "%s^x01 You must be alive to use ^x04Teleport", MODNAME);
		}
		case 4:
		{
			client_cmd(id, "amx_clcmdmenu");
		}
		case 5:
		{
			selectAimingMoveAs(id);
			if (id != g_SelectedUser[id] && g_SelectedUser[id])
			{
				helpingMenu(id);
				return PLUGIN_HANDLED;
			}
			else
			{
				CC_SendMessage(id, "%s ^x01Invalid Target. Aim at another player and retry.", MODNAME);
			}
		}
		case 6:
		{
			client_cmd(id, "amxmodmenu");
		}
	}
	
	adminMenu(id);
	menu_destroy(menu);
	return PLUGIN_CONTINUE;
}

public helpingMenu(id)
{
	if(!is_user_connected(id) || !g_isAlive[id]) 
		return PLUGIN_HANDLED;
	
	new target = g_SelectedUser[id];
	if (target == id)
	{
		CC_SendMessage(id, "%s^x01 You cannot use the helping menu^x04 on yourself!", MODNAME);
		adminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new gText[512], szTargetPlayerName[32], szPlayerName[32];
	get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	
	formatex(gText, charsmax(gText), "\d[\r ProBuilder \d] \y- \wYou help the player\d: \r[ \y%s \r]", szTargetPlayerName);
	new menu = menu_create(gText, "helpingMenu_2");

	add_format_item(menu, "\yNoClip\d: \r[ \y%s \r]\w [ %s \w]", szTargetPlayerName, userNoClip[target] ? "\r•" : "\d•");
	add_format_item(menu, "\yGodMod\d: \r[ \y%s \r]\w [ %s \w]", szTargetPlayerName, userGodMod[target] ? "\r•" : "\d•");
	add_format_item(menu, "\yBuilding\d: \r[ \y%s \r]\w [ %s \w]^n", szTargetPlayerName, userAllowBuild[target] ? "\r•" : "\d•");
	
	add_format_item(menu, "\wNoClip\d: \r[ \y%s \r]\w [ %s \w]", szPlayerName, userNoClip[id] ? "\r•" : "\d•");
	add_format_item(menu, "\wGodMod\d: \r[ \y%s \r]\w [ %s \w]^n", szPlayerName, userGodMod[id] ? "\r•" : "\d•");
	
	if (ArePlayersInSameParty(id, target))
		add_format_item(menu, "\rDisband Team with \r[ \y%s \r]", szTargetPlayerName);
	else if (ArePlayersOnSameTeam(id, target, false))
		add_format_item(menu, "\yCreate Team with \r[ \y%s \r]", szTargetPlayerName);
		
	add_format_item(menu, "Respawn \r[ \y%s \r]", szTargetPlayerName);
	add_format_item(menu, g_isZombie[target] ? "Swap to \yBuilder Team \r[ \y%s \r]" : "Swap to \rZombie Team \r[ \y%s \r]", szTargetPlayerName);
	add_format_item(menu, g_isBuildBan[target] ? "\rUnBan Build \d(Banned) \r[ \y%s \r]" : "\wBan Build \r[ \y%s \r]", szTargetPlayerName);
	
	add_format_item(menu, "Gag (1 min) \r[ \y%s \r]", szTargetPlayerName);
	add_format_item(menu, "Slay \r[ \y%s \r]", szTargetPlayerName);
	add_format_item(menu, "Kick \r[ \y%s \r]", szTargetPlayerName);
	add_format_item(menu, "Ban (5 min) \r[ \y%s \r]", szTargetPlayerName);
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public helpingMenu_2(id, menu, item)
{
	new target = g_SelectedUser[id];
	
	if(!is_user_connected(target))
	{
		CC_SendMessage(id, "%s ^x01The player you helped^x04 is unavailable!", MODNAME);
		adminMenu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(target == id)
	{
		CC_SendMessage(id, "%s ^x04You cannot perform actions^x04 on yourself!", MODNAME);
		adminMenu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(item == MENU_EXIT)
	{
		adminMenu(id);
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new adjustedItem = item;

	if (!ArePlayersInSameParty(id, target) && !ArePlayersOnSameTeam(id, target, false) && item >= 5)
	{
		adjustedItem++;
	}
	
	switch (adjustedItem)
	{
		case 0:
		{
			userNoClip[target] =! userNoClip[target];
			set_user_noclip(target, userNoClip[target]);
			
			new szAction[48];
			formatex(szAction, charsmax(szAction), userNoClip[target] ? "enabled NoClip for" : "disabled NoClip for");
			RecordAdminAction(id, target, "NOCLIP", szAction);
			
			UpdatePlayerGlow(target);
		}
		case 1:
		{
			userGodMod[target] =! userGodMod[target];
			set_user_godmode(target, userGodMod[target]);
			
			new szAction[48];
			formatex(szAction, charsmax(szAction), userGodMod[target] ? "enabled GodMode for" : "disabled GodMode for");
			RecordAdminAction(id, target, "GODMODE", szAction);
			
			UpdatePlayerGlow(target);
		}
		case 2:
		{
			if (!is_user_alive(target))
			{
				CC_SendMessage(id, "%s^x01 You must be alive to use ^x04Build Mode", MODNAME);
			}else if (g_isBuildBan[target])
			{
				CC_SendMessage(id, "%s ^x01Cannot change Build Mode: Player is build-banned!", MODNAME);
			}
			else
			{
				userAllowBuild[target] =! userAllowBuild[target];
				
				new szAction[48];
				formatex(szAction, charsmax(szAction), userAllowBuild[target] ? "enabled Build Mode for" : "disabled Build Mode for");
				RecordAdminAction(id, target, "BUILDMODE", szAction);
				
				UpdatePlayerGlow(target);
			}
		}
		case 3:
		{
			userNoClip[id] =! userNoClip[id];
			set_user_noclip(id, userNoClip[id]);
			UpdatePlayerGlow(id);
		}
		case 4:
		{
			userGodMod[id] =! userGodMod[id];
			set_user_godmode(id, userGodMod[id]);
			UpdatePlayerGlow(id);
		}
		case 5:
		{
			if (ArePlayersInSameParty(id, target))
			{
				userTeam[target] = 0;
				removeOption(userSaveOption[target], save_TEAM_COLOR);
				CC_SendMessage(target, "%s ^x04[Admin]^x01 Your team was disbanded by an admin", MODNAME);

				userTeam[id] = 0;
				removeOption(userSaveOption[id], save_TEAM_COLOR);
				CC_SendMessage(id, "%s ^x04[Admin]^x01 You have disbanded the team", MODNAME);
			}
			else if (ArePlayersOnSameTeam(id, target, false))
			{
				new adminTeammate = userTeam[id];
				if (adminTeammate != 0 && is_user_connected(adminTeammate))
				{
					userTeam[adminTeammate] = 0;
					removeOption(userSaveOption[adminTeammate], save_TEAM_COLOR);
					CC_SendMessage(adminTeammate, "%s ^x04[Admin]^x01 Your team was disbanded by an admin", MODNAME);
				}
				
				new targetTeammate = userTeam[target];
				if (targetTeammate != 0 && is_user_connected(targetTeammate))
				{
					userTeam[targetTeammate] = 0;
					removeOption(userSaveOption[targetTeammate], save_TEAM_COLOR);
					CC_SendMessage(targetTeammate, "%s ^x04[Admin]^x01 Your team was disbanded by an admin", MODNAME);
				}
				
				userTeam[id] = target;
				userTeam[target] = id;
				
				new szTargetPlayerName[32], szPlayerName[32];
				get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
				get_user_name(id, szPlayerName, charsmax(szPlayerName));
				
				CC_SendMessage(id, "%s ^x04[Admin]^x01 Your teammate is ^x04%s", MODNAME, szTargetPlayerName);
				CC_SendMessage(target, "%s ^x04[Admin]^x01 Your teammate is ^x04%s", MODNAME, szPlayerName);
			}
			else
			{
				CC_SendMessage(id, "%s ^x04[Team]^x01 You cannot team up with players on the opposing team.", MODNAME);
			}
		}
		case 6:
		{
			cmdRevive(id, target);
		}
		case 7:
		{
			cmdSwap(id, target);
		}
		case 8:
		{
			cmdBuildBan(id, target);
		}
		case 9:
		{
			server_cmd("amx_gag #%i ^"60^"", get_user_userid(target));
		}
		case 10:
		{
			user_kill(target, 1);
		}
		case 11:
		{
			server_cmd("amx_kick #%i", get_user_userid(target));
			return PLUGIN_HANDLED;
		}
		case 12:
		{
			server_cmd("amx_ban #%i ^"1^"", get_user_userid(target));
			return PLUGIN_HANDLED;
		}
	}
	
	helpingMenu(id);
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public menuSpecifyUser(id, szName[])
{
	if (!is_user_connected(id))
		return;

	new menu = menu_create("\d[\r ProBuilder \d] \y- \wSelect a Player", "menuSpecifyUser_2");
	new szMenuItem[128], currentPlayerName[32];
	new iNameLen, iSearchLen, iPos;

	iSearchLen = strlen(szName);

	for (new i = 1, x = 0; i < MAXPLAYERS; i++)
	{
		if (!is_user_connected(i) || is_user_hltv(i))
			continue;
		
		get_user_name(i, currentPlayerName, charsmax(currentPlayerName)); 
		
		iPos = containi(currentPlayerName, szName);
		
		if (iPos == -1)
			continue;

		iNameLen = strlen(currentPlayerName);
		
		copy(szMenuItem, iPos, currentPlayerName);
		
		format(szMenuItem, sizeof(szMenuItem), "%s\y", szMenuItem);
		add(szMenuItem, sizeof(szMenuItem), currentPlayerName[iPos], iSearchLen);
		
		format(szMenuItem, sizeof(szMenuItem), "%s\w", szMenuItem);
		add(szMenuItem, sizeof(szMenuItem), currentPlayerName[iPos + iSearchLen], iNameLen - (iPos + iSearchLen));
		
		menu_additem(menu, szMenuItem);
		userVarList[id][x++] = i;
	}
	
	menu_display(id, menu, 0);
}

public menuSpecifyUser_2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	new target = userVarList[id][item];
	
	switch(userVarMenu[id])
	{
		case 0:
		{
			cmdRevive(id, target);
		}
		case 1:
		{
			cmdSwap(id, target);
		}
		case 2:
		{
			cmdBuildBan(id, target);
		}
		case 3:
		{
			cmdTeleport(id, target);
		}
		case 4:
		{
			g_SelectedUser[id] = target;
			helpingMenu(id);
		}
		case 5:
		{
			cmdGuns(id, target);
		}
	}
	
	menu_destroy(menu);
	return;
}

public selectAimingMoveAs(id)
{
	if (!RequireAccess(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;
	
	new ent, body;
	get_user_aiming(id, ent, body);
	
	if (!isPlayer(ent))
	{
		if (is_valid_build_ent(ent))
		{
			new OwnerBlock = GetLastMover(ent);
			
			if (OwnerBlock != 0 && is_user_connected(OwnerBlock))
			{
				ent = OwnerBlock;
			}
			else
			{
				ent = id;
			}
		}
		else
		{
			ent = id;
		}
	}
	
	if (g_SelectedUser[id] != ent)
	{
		g_SelectedUser[id] = ent;
	}
	return PLUGIN_CONTINUE;
}

public light(id)
{
	new gText[256], bar[256];
	new lightCount = strlen(lightCharacter);

	if(!lightType[0])
	{
		formatex(gText, charsmax(gText), "\d[\r ProBuilder \d] \y- \dLight:\r Normal");
	}
	else
	{
		new percent = (lightType[0] * 100) / lightCount;
		formatex(gText, charsmax(gText), "\d[\r ProBuilder \d] \y- \dLight:\r %d%%\w [\d %d/%d\w -\d %c\w ]", percent, lightType[0], lightCount, lightCharacter[lightType[0]-1]);
	}

	new menu = menu_create(gText, "light_2");

	barMenu(bar, charsmax(bar), lightType[0], lightCount, "|", "|");
	
	add_format_item(menu, "%s", bar);

	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public light_2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if (item == 0)
	{
		new bufferBit[32];
		new lightCount = strlen(lightCharacter);

		lightType[0]++;

		if(lightType[0] > lightCount)
		{
			lightType[0] = 0;
			lightType[1] = 0;
			set_lights("#OFF");
		}
		else
		{
			lightType[1] ^= (1 << (lightType[0] - 1));

			stringBuffer(lightType[1], bufferBit);
			set_lights(bufferBit);
		}
		light(id);
	}
	return PLUGIN_HANDLED;
}

public cmdUnstuck(id)
{
	if (!g_boolCanBuild || userNoClip[id] || !g_isAlive[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	if (perform_unstuck(id))
	{
		fade_user_screen(id, 0.5, 0.5, .r = 255, .g = 32, .b = 32, .a = 90);
		set_dhudmessage(255, 32, 32, -1.0, 0.3, 0, 0.5, 0.9, 0.5, 0.5);
		show_dhudmessage(id, "!! Unstuck !!");
	}
	
	return PLUGIN_CONTINUE;
}

public task_unstuck_player(id)
{
	if (!g_isAlive[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	if (perform_unstuck(id))
	{
		fade_user_screen(id, 0.5, 0.5, .r = 255, .g = 32, .b = 32, .a = 90);
		set_dhudmessage(255, 32, 32, -1.0, 0.3, 0, 0.5, 0.9, 0.5, 0.5);
		show_dhudmessage(id, "!! Auto Unstuck !!");
	}
	
	return PLUGIN_CONTINUE;
}

public SetRandomPlayerColor(id)
{
	if (g_isZombie[id] || !g_boolCanBuild  || !g_isAlive[id])
		return;
		
	new iColorIndex;

	if (g_iColorMode)
	{
		iColorIndex = random_num(0, MAX_COLORS - 2);
		new attempts = 0;
		while (g_iColorOwner[iColorIndex] && attempts < MAX_COLORS)
		{
			iColorIndex = random_num(0, MAX_COLORS - 2);
			attempts++;
		}
		
		if (g_iColorOwner[iColorIndex])
		{
			iColorIndex = random_num(0, MAX_COLORS - 2);
			return;
		}

		new iOldColor = g_iColor[id];
		if (iOldColor >= 0 && iOldColor < MAX_COLORS)
		{
			g_iColorOwner[iOldColor] = 0;
		}

		g_iColorOwner[iColorIndex] = id;
	}
	else
	{
		iColorIndex = random_num(0, MAX_COLORS - 2);
	}
	
	g_iColor[id] = iColorIndex;
	g_bBlockRandomColor[id] = false;
	CC_SendMessage(id, "%s^x01 %L:^x04 %s", MODNAME, LANG_SERVER, "COLOR_RANDOM", g_aColors[iColorIndex][Name]);
	client_cmd(id, "spk %s", g_szSoundPaths[SOUND_BRICK]);
	
	if (g_iLockBlocks)
	{
		for (new iEnt = MAXPLAYERS + 1; iEnt < MAXENTS; iEnt++)
		{
			if (is_valid_ent(iEnt) && BlockLocker(iEnt) == id)
			{
				SetBlockRenderColor(iEnt, id);
			}
		}
	}
	ExecuteForward(g_fwNewColor, g_fwDummyResult, id, iColorIndex);
	
	new teammate = userTeam[id];
	if (ArePlayersInSameParty(id, teammate) && hasOption(userSaveOption[id], save_TEAM_COLOR) && hasOption(userSaveOption[teammate], save_TEAM_COLOR))
	{
		if (g_iColorMode)
		{
			new iOldTeammateColor = g_iColor[teammate];
			if (iOldTeammateColor >= 0 && iOldTeammateColor < MAX_COLORS)
			{
				g_iColorOwner[iOldTeammateColor] = 0;
			}
		}
		
		g_iColor[teammate] = iColorIndex;
		g_bBlockRandomColor[teammate] = false;
		CC_SendMessage(teammate, "%s^x01 %L:^x04 %s", MODNAME, LANG_SERVER, "COLOR_RANDOM", g_aColors[iColorIndex][Name]);
		client_cmd(teammate, "spk %s", g_szSoundPaths[SOUND_BRICK]);
		
		if (g_iLockBlocks)
		{
			for (new iEnt = MAXPLAYERS + 1; iEnt < MAXENTS; iEnt++)
			{
				if (is_valid_ent(iEnt) && BlockLocker(iEnt) == teammate)
				{
					SetBlockRenderColor(iEnt, teammate);
				}
			}
		}
		ExecuteForward(g_fwNewColor, g_fwDummyResult, teammate, iColorIndex);
	}
}