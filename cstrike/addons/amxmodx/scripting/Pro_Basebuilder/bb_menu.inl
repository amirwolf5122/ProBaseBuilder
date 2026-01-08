public globalMenu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wProBuilder Menu", "globalMenu_2");
	
	new gText[128], szTargetPlayerName[32], szCache1[32];
	ArrayGetString(g_zclass_name, g_iZombieClass[id], szCache1, charsmax(szCache1));
	get_user_name(userTeam[id], szTargetPlayerName, charsmax(szTargetPlayerName));
	
	menu_additem(menu, "\r[ \wBuy Weapons\r ]");
	
	formatex(gText, charsmax(gText), "%s", g_boolCanBuild ? "\r[ \dExtra Items\r ] \d[\rPrep Time\d]" : "\r[ \wExtra Items\r ]");
	menu_additem(menu, gText);
	
	formatex(gText, charsmax(gText), "\r[ \wZombie Class\r ] \d[\r%s\d]", szCache1);
	menu_additem(menu, gText);
	
	menu_additem(menu, "\r[ \wPlayer Menu\r ]^n");
	
	if (!g_bUsedVipSpawn[id] && access(id, FLAGS_VIP) && g_boolPrepTime && cs_get_user_team(id) == CS_TEAM_CT)
	{
		menu_additem(menu, "\r[ \wRespawn \r ] [ \yPrep Time \w[\r1\w] \r] [ \yVIP\r ]");
	}
	else
	{
		formatex(gText, charsmax(gText), "\r[ \w%s\r ]", cs_get_user_team(id) == CS_TEAM_SPECTATOR ? "Spec Join" : "Respawn");
		menu_additem(menu, gText);
	}
	
	formatex(gText, charsmax(gText), "\r[ %sUnstuck\r ]", (g_boolCanBuild || g_boolPrepTime) ? "\w" : "\d");
	menu_additem(menu, gText);
	
	if (ArePlayersInSameParty(id, userTeam[id]))
	{
		formatex(gText, charsmax(gText), "\r[ \wTeammate:\y %s \r]", szTargetPlayerName);
		menu_additem(menu, gText);
	}
	else
	{
		menu_additem(menu, "\r[ \wSend Team Invite\r ]");
	}
	
	if (get_user_flags(id) & FLAGS_BUILDBAN)
	{
		menu_additem(menu, "\r[ \wAdmin Menu\r ]");
	}
	else
	{
		menu_additem(menu, "\r[ \dAdmin Menu\r ]");
	}
	
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
			show_zclass_menu(id);
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			PlayerMenu(id);
		}
		case 4:
		{
			if (cs_get_user_team(id) == CS_TEAM_SPECTATOR)
			{
				new randomTeam = random_num(1, 2);
				if (randomTeam == 1)
					cs_set_user_team(id, CS_TEAM_T);
				else
					cs_set_user_team(id, CS_TEAM_CT);
			}
			else if (!g_bUsedVipSpawn[id] && access(id, FLAGS_VIP) && g_boolPrepTime && cs_get_user_team(id) == CS_TEAM_CT)
			{
				ExecuteHamB(Ham_CS_RoundRespawn, id);
				g_bUsedVipSpawn[id] = true;
			}
			else
			{
				client_cmd(id, "say /respawn");
			}
		}
		case 5:
		{
			cmdUnstuck(id);
		}
		case 6:
		{
			teamOption(id);
		}
		case 7:
		{
			if (RequireAccess(id, FLAGS_BUILDBAN))
			{
				adminMenu(id);
			}
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}


public PlayerMenu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wPlayer Menu", "PlayerMenu_2");
	
	new gText[128];
	
	formatex(gText, charsmax(gText), "\r[ \wCurrent Color\r ]\d: \d[ \r%s\d ]", g_aColors[g_iColor[id]][Name]);
	menu_additem(menu, gText);
	
	formatex(gText, charsmax(gText), "\r[ \wBlock Mod\r ]\d: %s^n", g_playerBlockRenderMode[id] == RENDER_MODE_NORMAL ? "\wNormall" : g_playerBlockRenderMode[id] == RENDER_MODE_TRANSPARENT ? "\yTransparent" : "\dWithout color");
	menu_additem(menu, gText);
	
	if (access(id, FLAGS_VIP))
	{
		formatex(gText, charsmax(gText), "\r[ \wLock Mod\r ]\w: %s^n", g_bUserLockMode[id] ? "\yEnabled" : "\dDisabled");
	}
	else
	{
		formatex(gText, charsmax(gText), "\r[ \dLock Mod\r ]\d: \dDisabled \r[ \yVIP\r ]^n");
	}
	menu_additem(menu, gText);
	
	menu_additem(menu, "\r[ \wRandom Colors\r ]^n");
	
	if (access(id, FLAGS_VIP) && g_boolCanBuild && cs_get_user_team(id) == CS_TEAM_CT)
	{
		formatex(gText, charsmax(gText), "\r[ \wPlayer Speed\r ]\d: \y%d^n", floatround(Float:g_fUserPlayerSpeed[id]));
	}
	else
	{
		formatex(gText, charsmax(gText), "\r[ \dPlayer Speed\r ]\d: \dDisabled %s^n", (get_user_flags(id) & FLAGS_VIP) ? "" : "\r[ \yVIP\r ]");
	}
	menu_additem(menu, gText);
	
	formatex(gText, charsmax(gText), "\r[ \wThird person view\r ]\w: %s", g_bUserViewCamera[id] ? "\yEnabled" : "\dDisabled");
	menu_additem(menu, gText);
	
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
			show_colors_menu(id);
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			g_playerBlockRenderMode[id] = (g_playerBlockRenderMode[id]+1) % 3;
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
			SetRandomPlayerColor(id);
		}
		case 4:
		{
			if (RequireAccess(id, FLAGS_VIP) && g_isAlive[id] && g_boolCanBuild && cs_get_user_team(id) == CS_TEAM_CT)
			{
				if ((g_fUserPlayerSpeed[id] += 100.0) > 560.0) 
					g_fUserPlayerSpeed[id] = 260.0;
				set_user_maxspeed(id, Float:g_fUserPlayerSpeed[id]);
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
	new gText[512];
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wAdmin Menu\d:", "adminMenu_2");
	
	formatex(gText, charsmax(gText), "NoClip\d:\w [ %s \w]", userNoClip[id] ? "\r•" : "\d•");
	menu_additem(menu, gText);
	formatex(gText, charsmax(gText), "GodMod\d:\w [ %s \w]", userGodMod[id] ? "\r•" : "\d•");
	menu_additem(menu, gText);
	formatex(gText, charsmax(gText), "Manage Countdown\d:\w [ %s \w]^n", !g_bTimerPaused ? "\yACTIVE" : "\dPAUSED");
	menu_additem(menu, gText);
	
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
			adminMenu(id);
		}
		case 1:
		{
			userGodMod[id] =! userGodMod[id];
			set_user_godmode(id, userGodMod[id]);
			UpdatePlayerGlow(id);
			adminMenu(id);
		}
		case 2:
		{
			g_bTimerPaused =! g_bTimerPaused;
			
			new szPlayerName[32];
			get_user_name(id, szPlayerName, charsmax(szPlayerName));
			
			CC_SendMessage(0, "%s Admin ^x04%s ^x01has toggled the Round timer. It is now ^x04%s.", MODNAME, szPlayerName, g_bTimerPaused ? "PAUSED" : "ACTIVE");
			adminMenu(id);
		}
		case 3:
		{
			if (g_bHasReturnOrigin[id])
			{
				Util_SetOrigin(id, g_fAdminReturnOrigin[id], g_fAdminReturnAngles[id]);
				g_bHasReturnOrigin[id] = false;
			
				adminMenu(id);
			}
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
			}
			else
			{
				adminMenu(id);
				CC_SendMessage(id, "%s ^x01Invalid Target. Aim at another player and retry.", MODNAME);
			}
		}
		case 6:
		{
			client_cmd(id, "amxmodmenu");
		}
	}
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
		CC_SendMessage(id, "%s^x01 You cannot use the helping menut^x04 on yourself!", MODNAME);
		adminMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new gText[512], szTargetPlayerName[32], szPlayerName[32];
	get_user_name(target, szTargetPlayerName, charsmax(szTargetPlayerName));
	get_user_name(id, szPlayerName, charsmax(szPlayerName));
	
	formatex(gText, charsmax(gText), "\d[\r ProBuilder \d] \y- \wYou help the player\d: \r[ \y%s \r]", szTargetPlayerName);
	new menu = menu_create(gText, "helpingMenu_2");

	new const targetOptions[][] = { "NoClip", "GodMod", "Building" };
	new targetBools[3];
	targetBools[0] = userNoClip[target];
	targetBools[1] = userGodMod[target];
	targetBools[2] = userAllowBuild[target];

	for (new i = 0; i < sizeof targetOptions; i++)
	{
		formatex(gText, charsmax(gText), "\y%s\d: \r[ \y%s \r]\w [ %s \w]%s", 
			targetOptions[i], 
			szTargetPlayerName, 
			targetBools[i] ? "\r•" : "\d•",
			i == (sizeof targetOptions - 1) ? "^n" : ""
		);
		menu_additem(menu, gText);
	}

	new const selfOptions[][] = { "NoClip", "GodMod" };
	new selfBools[2];
	selfBools[0] = userNoClip[id];
	selfBools[1] = userGodMod[id];
	
	for (new i = 0; i < sizeof selfOptions; i++)
	{
		formatex(gText, charsmax(gText), "\w%s\d: \r[ \y%s \r]\w [ %s \w]%s", 
			selfOptions[i], 
			szPlayerName, 
			selfBools[i] ? "\r•" : "\d•",
			i == (sizeof selfOptions - 1) ? "^n" : ""
		);
		menu_additem(menu, gText);
	}

	if (ArePlayersInSameParty(id, target))
	{
		formatex(gText, charsmax(gText), "\rRemove Team \r[ \y%s \r]", szTargetPlayerName);
		menu_additem(menu, gText);
	}
	else if (ArePlayersOnSameTeam(id, target))
	{
		formatex(gText, charsmax(gText), "\yAdd Team \r[ \y%s \r]", szTargetPlayerName);
		menu_additem(menu, gText);
	}
	
	formatex(gText, charsmax(gText), "Respawn \r[ \y%s \r]", szTargetPlayerName);
	menu_additem(menu, gText);
	
	if (g_isZombie[target])
	{
		formatex(gText, charsmax(gText), "Swap to \yBuilder Team \r[ \y%s \r]", szTargetPlayerName);
	}
	else
	{
		formatex(gText, charsmax(gText), "Swap to \rZombie Team \r[ \y%s \r]", szTargetPlayerName);
	}
	menu_additem(menu, gText);

	if (g_isBuildBan[target])
	{
		formatex(gText, charsmax(gText), "\rUnBan Build \d(Currently Banned) \r[ \y%s \r]", szTargetPlayerName);
	}
	else
	{
		formatex(gText, charsmax(gText), "\wBan Build \r[ \y%s \r]", szTargetPlayerName);
	}
	menu_additem(menu, gText);
	
	new const adminCommands[][] =
	{
		"Gag (1 min)",
		"Slay",
		"Kick",
		"Ban (5 min)"
	};
	for (new i = 0; i < sizeof adminCommands; i++)
	{
		formatex(gText, charsmax(gText), "%s \r[ \y%s \r]", adminCommands[i], szTargetPlayerName);
		menu_additem(menu, gText);
	}
	
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
			ManagementAction(id, target, "Opened the Help Menu for", "NoClip", "");
			UpdatePlayerGlow(target);
		}
		case 1:
		{
			userGodMod[target] =! userGodMod[target];
			set_user_godmode(target, userGodMod[target]);
			ManagementAction(id, target, "Opened the Help Menu for", "GodMod", "");
			UpdatePlayerGlow(target);
		}
		case 2:
		{
			if (g_isBuildBan[target])
			{
				CC_SendMessage(id, "%s ^x01Cannot change Build Mode: Player is build-banned!", MODNAME);
			}
			else
			{
				userAllowBuild[target] =! userAllowBuild[target];
				ManagementAction(id, target, "Opened the Help Menu for", "Build Mode", "");
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
			else if (ArePlayersOnSameTeam(id, target))
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
		}
		case 12:
		{
			server_cmd("amx_ban #%i ^"1^"", get_user_userid(target));
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
	
	formatex(gText, charsmax(gText), "%s", bar);
	menu_additem(menu, gText);

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
	if (!(g_boolCanBuild || g_boolPrepTime) || userNoClip[id])
	{
		return PLUGIN_CONTINUE;
	}
	
	if (!is_user_connected(id) || !is_user_alive(id))
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
	if (!is_user_connected(id) || !is_user_alive(id))
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
	if (g_isZombie[id] || !g_boolCanBuild)
		return;
		
	new iColorIndex;

	if (g_iColorMode)
	{
		iColorIndex = random_num(0, MAX_COLORS - 1);
		new attempts = 0;
		while (g_iColorOwner[iColorIndex] && attempts < MAX_COLORS)
		{
			iColorIndex = random_num(0, MAX_COLORS - 1);
			attempts++;
		}
		
		if (g_iColorOwner[iColorIndex])
		{
			iColorIndex = random_num(0, MAX_COLORS - 1);
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
		iColorIndex = random_num(0, MAX_COLORS - 1);
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