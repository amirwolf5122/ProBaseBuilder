stock barMenu(gText[], iLen, type, amount, const symbolOne[], const symbolTwo[])
{
	new line = 0;
	for(new i = 0; i < type; i++)
	{
		line += formatex(gText[line], iLen - line, "\y%s\d", symbolOne);
	}
	for(new i = 0; i < amount - type; i++)
	{
		line += formatex(gText[line], iLen - line, "%s", symbolTwo);
	}
}

stock stringBuffer(flags, buffer[])
{
	for (new i = strlen(lightCharacter) - 1; i >= 0; i--)
	{
		if (flags & (1 << i))
		{
			buffer[0] = lightCharacter[i];
			buffer[1] = EOS;
			return;
		}
	}
	buffer[0] = EOS;
}

stock UpdatePlayerGlow(id)
{
	if (!is_user_connected(id) || !is_user_alive(id))
	{
		set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
		return;
	}
	if (g_isBuildBan[id])
	{
		set_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25);
	}
	else if (userNoClip[id] || userGodMod[id] || userAllowBuild[id])
	{
		set_rendering(id, kRenderFxGlowShell, 120, 250, 50, kRenderNormal, 5);
	}
	else
	{
		set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
	}
}

bool:perform_unstuck(id)
{
	static Float:origin[3];
	pev(id, pev_origin, origin);
	
	new hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
	
	if (is_hull_vacant(origin, hull, id))
	{
		return false;
	}
	
	static Float:mins[3];
	pev(id, pev_mins, mins);
	static Float:vec[3];
	
	const MAX_UNSTUCK_RADIUS = 5;
	new Float:f_dist;
	
	for (new dist = 1; dist <= MAX_UNSTUCK_RADIUS; ++dist)
	{
		f_dist = float(dist);
		for (new x = -1; x <= 1; ++x)
		{
			for (new y = -1; y <= 1; ++y)
			{
				for (new z = -1; z <= 1; ++z)
				{
					if (x == 0 && y == 0 && z == 0)
						continue;
						
					vec[0] = origin[0] - mins[0] * float(x) * f_dist;
					vec[1] = origin[1] - mins[1] * float(y) * f_dist;
					vec[2] = origin[2] - mins[2] * float(z) * f_dist;
					
					if (is_hull_vacant(vec, hull, id))
					{
						engfunc(EngFunc_SetOrigin, id, vec);
						set_pev(id, pev_velocity, {0.0, 0.0, 0.0});
						client_cmd(id, "spk %s", g_szSoundPaths[SOUND_UNSTUCK]);
						return true;
					}
				}
			}
		}
	}
	return false;
}

stock bool:is_hull_vacant(const Float:origin[3], hull, id)
{
	new tr = 0;
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr);
	
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true;
	return false;
}

Util_SetOrigin(id, Float:flOrigin[3], Float:flAngles[3])
{
	new const Float:VEC_DUCK_HULL_MIN[3] = {-16.0, -16.0, -18.0 };
	new const Float:VEC_DUCK_HULL_MAX[3] = { 16.0,  16.0,  32.0 };
	new const Float:VEC_DUCK_VIEW[3]     = {  0.0,   0.0,  12.0 };
	new const Float:VEC_NULL[3]          = {  0.0,   0.0,   0.0 };
	
	cmdStopEnt(id);
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	engfunc(EngFunc_SetSize, id, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX);
	engfunc(EngFunc_SetOrigin, id, flOrigin);
	set_pev(id, pev_view_ofs, VEC_DUCK_VIEW);
	
	set_pev(id, pev_v_angle, VEC_NULL);
	set_pev(id, pev_velocity, VEC_NULL);
	set_pev(id, pev_angles, flAngles);
	set_pev(id, pev_punchangle, VEC_NULL);
	set_pev(id, pev_fixangle, 1);
	
	set_pev(id, pev_gravity, flAngles[2]);
	
	set_pev(id, pev_fuser2, 0.0);
	
	fade_user_screen(id, 0.6, 1.0, ScreenFade_Modulate, 0, 150, 255, 150);
	client_cmd(id, "spk %s", g_szSoundPaths[SOUND_TELEPORT]);
	set_task(0.5, "task_unstuck_player", id)
}

stock SetBlockRenderColor(ent, id, bool:bApplyRenderAmt = true)
{
	new iColorIndex = g_bBlockRandomColor[id] ? random_num(0, MAX_COLORS - 1) : g_iColor[id];
	
	new Float:flColorVec[3];
	flColorVec[0] = g_aColors[iColorIndex][Red];
	flColorVec[1] = g_aColors[iColorIndex][Green];
	flColorVec[2] = g_aColors[iColorIndex][Blue];
	
	set_pev(ent, pev_rendercolor, flColorVec);
	
	if (bApplyRenderAmt)
	{
		set_pev(ent, pev_renderamt, g_aColors[iColorIndex][RenderAmount]);
	}
}

stock SetLockedBlock(ent, id, bool:LockMode = false, bool:updateClone = true)
{
	if (updateClone)
	{
		new oldClone = g_iClonedEnts[ent];
		if (is_valid_ent(oldClone))
		{
			remove_entity(oldClone);
		}
		
		new cloneEnt = createClone(ent);
		if (!is_valid_ent(cloneEnt))
			return;
		g_iClonedEnts[ent] = cloneEnt;
	}
	else
	{
		new cloneEnt = g_iClonedEnts[ent];
		if (is_valid_ent(cloneEnt))
		{
			set_pev(cloneEnt, pev_renderfx, kRenderFxNone);
			set_pev(cloneEnt, pev_rendermode, kRenderNormal);
		}
	}
	
	set_pev(ent, pev_rendermode, kRenderTransColor);
	set_pev(ent, pev_renderamt, Float:{LOCKED_RENDERAMT});
	
	if (g_iLockBlocks == 0)
	{
		set_pev(ent, pev_rendercolor, Float:{LOCKED_COLOR});
	}
	else
	{
		SetBlockRenderColor(ent, id, false);
	}

	if (LockMode)
	{
		set_pev(ent, pev_renderfx, kRenderFxPulseSlowWide);
	}
	else
	{
		set_pev(ent, pev_renderfx, kRenderFxNone);
	}
}

stock SetEntityRenderColor(ent, Float:r, Float:g, Float:b)
{
    r = (r == -1.0) ? random_float(0.0, 255.0) : r;
    g = (g == -1.0) ? random_float(0.0, 255.0) : g;
    b = (b == -1.0) ? random_float(0.0, 255.0) : b;
    
    set_pev(ent, pev_rendercolor, r, g, b);
}

ReadColorSetting(const szValue[], destin[])
{
    new szTemp[3][5];
    parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]));
    for (new i = 0; i < 3; i++)
    {
        destin[i] = clamp(str_to_num(szTemp[i]), -1, 255);
    }
}

ReadPositionSetting(const szValue[], Float:destin[])
{
    new szTemp[3][5];
    parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]));
    for (new i = 0; i < 2; i++)
    {
        destin[i] = floatclamp(str_to_float(szTemp[i]), -1.0, 1.0);
    }
}

ReadFloatColorSetting(const szValue[], Float:destin[])
{
    new szTemp[3][5];
    parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]));
    for (new i = 0; i < 3; i++)
    {
        destin[i] = floatclamp(str_to_float(szTemp[i]), -1.0, 255.0);
    }
}

stock ManagementAction(const id, const player, const actionVerb[], const logType[], const hudLangKey[], const chatParam[] = "", const hudParam[] = "", bool:alt_message = false)
{
	new szAdminAuthid[32], szAdminName[32], szPlayerName[32], szPlayerID[32];
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	get_user_name(player, szPlayerName, charsmax(szPlayerName));
	get_user_authid(player, szPlayerID, charsmax(szPlayerID));

	Log("[%s] Admin: %s || SteamID: %s %s Player: %s || SteamID: %s", logType, szAdminName, szAdminAuthid, actionVerb, szPlayerName, szPlayerID);
	
	if (alt_message)
	{
		client_print(id, print_console, "[Pro BaseBuilder] You %s %s", actionVerb, szPlayerName);
		CC_SendMessage(0, "%s Admin^x04 %s^x01 has^x04 %s^x01 to^x04 %s", MODNAME, szAdminName, actionVerb, szPlayerName);
	}
	else
	{
		client_print(id, print_console, "[Pro BaseBuilder] Player %s was %s by %s", szPlayerName, actionVerb, szAdminName);
		if (chatParam[0] != 0)
			CC_SendMessage(0, "%s Player^x04 %s^x01 has been^x04 %s^x01 to the^x04 %s^x01 team by ^x04%s", MODNAME, szPlayerName, actionVerb, chatParam, szAdminName);
		else
			CC_SendMessage(0, "%s Player^x04 %s^x01 has been^x04 %s^x01 by ^x04%s", MODNAME, szPlayerName, actionVerb, szAdminName);
	}
	
	if (hudLangKey[0] != EOS)
	{
		set_dhudmessage(255, 0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2);
		
		if (hudParam[0] != EOS)
			show_dhudmessage(player, "%L", LANG_SERVER, hudLangKey, hudParam);
		else
			show_dhudmessage(player, "%L", LANG_SERVER, hudLangKey);
	}
}

stock FindPlayer(id, target, bool:allow_self = false)
{
	new player;
	if (target) 
		player = target;
	else
	{
		new arg[32];
		read_argv(1, arg, charsmax(arg));
		new flags = CMDTARGET_OBEY_IMMUNITY;
		if (allow_self) flags |= CMDTARGET_ALLOW_SELF;
		player = cmd_target(id, arg, flags);
	}
	
	if (!player || !is_user_connected(player))
	{
		client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
		return 0;
	}
	return player;
}

stock bool:RequireAccess(player_id, flags)
{
	if (access(player_id, flags))
	{
		return true;
	}

	client_print(player_id, print_center, "%L", LANG_SERVER, "FAIL_ACCESS");
	CC_SendMessage(player_id, "%s ^x01You do not have permission to use this command.", MODNAME);

	return false;
}

stock PlayerNotFound(player_id, const target_name[], menu_type)
{
	CC_SendMessage(player_id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, target_name);
	userVarMenu[player_id] = menu_type;
	
	new szTargetNameCopy[32];
	copy(szTargetNameCopy, charsmax(szTargetNameCopy), target_name);
	
	menuSpecifyUser(player_id, szTargetNameCopy);
}

stock ShowDamageIndicator(const id, const Float:damage, const szText[])
{
	userHudDeal[id] = (userHudDeal[id]+1)% sizeof(hudPosHit);

	new r, g, b;
	if (g_isZombie[id])
	{
		r = 255; g = 42; b = 85;
	}
	else
	{
		r = 0; g = 170; b = 255;
	}
	
	set_dhudmessage(r, g, b, 0.75, hudPosHit[userHudDeal[id]][0], 0, 6.0, 0.3, 0.1, 0.1);
	show_dhudmessage(id, "%d %s", floatround(damage), szText); 
}

stock bool:CheckForBlocker(id, iEntity2)
{
	if (access(id, FLAGS_OVERRIDE) || isPlayer(iEntity2))
	{
		return false;
	}
	
	new Float:iEntity2_absmin[3], Float:iEntity2_absmax[3];
	pev(iEntity2, pev_absmin, iEntity2_absmin);
	pev(iEntity2, pev_absmax, iEntity2_absmax);

	new Float:iEntity2_center[3];
	xs_vec_add(iEntity2_absmin, iEntity2_absmax, iEntity2_center);
	xs_vec_div_scalar(iEntity2_center, 2.0, iEntity2_center);
	new Float:iEntity2_radius = get_distance_f(iEntity2_center, iEntity2_absmax);
	
	new iEntity1 = -1;
	while ((iEntity1 = engfunc(EngFunc_FindEntityInSphere, iEntity1, iEntity2_center, iEntity2_radius)) != 0)
	{
		if (!is_valid_build_ent(iEntity1) || iEntity1 == iEntity2)
		{
			continue;
		}
		
		new Float:iEntity1_absmin[3], Float:iEntity1_absmax[3];
		pev(iEntity1, pev_absmin, iEntity1_absmin);
		pev(iEntity1, pev_absmax, iEntity1_absmax);

		if (DoBoxesIntersect(iEntity2_absmin, iEntity2_absmax, iEntity1_absmin, iEntity1_absmax))
		{
			if (GetEntMover(iEntity1) == 2)
			{
				CC_SendMessage(id, "%s^x04 Cannot build inside map structures", MODNAME);
				return true;
			}
			
			new OwnerBlock = BlockLocker(iEntity1);
			if (!OwnerBlock)
			{
				OwnerBlock = GetLastMover(iEntity1);
			}
			
			if (OwnerBlock != 0 && OwnerBlock != id && !ArePlayersInSameParty(id, OwnerBlock))
			{
				CC_SendMessage(id, "%s^x01 You cannot place a block inside another player's block", MODNAME);
				CC_SendMessage(id, "%s^x04 Only allowed for teammates", MODNAME);
				return true; 
			}
		}
	}
	return false;
}

stock bool:DoBoxesIntersect(const Float:mins1[3], const Float:maxs1[3], const Float:mins2[3], const Float:maxs2[3])
{
	if (maxs1[0] < mins2[0] || mins1[0] > maxs2[0]) return false;
	if (maxs1[1] < mins2[1] || mins1[1] > maxs2[1]) return false;
	if (maxs1[2] < mins2[2] || mins1[2] > maxs2[2]) return false;
	return true;
}

stock bool:is_valid_build_ent(ent)
{
	if (!ent || !is_valid_ent(ent) || is_user_alive(ent) || ent == g_iEntBarrier)
	{
		return false;
	}
	
	new szClass[16], szTarget[16];
	entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
	entity_get_string(ent, EV_SZ_targetname, szTarget, charsmax(szTarget));
	
	if (!equal(szClass, "func_wall") || equal(szTarget, "ignore") || equal(szTarget, "barrier"))
	{
		return false;
	}
	
	return true;
}

stock CheckForZoneblock(id, ent)
{
	if (isPlayer(ent))
	{
		return;
	}
	
	if(callfunc_begin("CheckBlockInZone", "bbzones.amxx") == 1)
	{
		callfunc_push_int(id);
		callfunc_push_int(ent);
		callfunc_end();
	}
}