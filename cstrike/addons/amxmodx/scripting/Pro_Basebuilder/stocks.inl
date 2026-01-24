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

stock add_format_item(menu, const fmt[], any:...)
{
	new text[256];
	vformat(text, charsmax(text), fmt, 3);
	menu_additem(menu, text);
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

stock bool:perform_unstuck(id)
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
	static Float:VEC_DUCK_HULL_MIN[3] = {-16.0, -16.0, -18.0 };
	static Float:VEC_DUCK_HULL_MAX[3] = { 16.0,  16.0,  32.0 };
	static Float:VEC_DUCK_VIEW[3]     = {  0.0,   0.0,  12.0 };
	static Float:VEC_NULL[3]          = {  0.0,   0.0,   0.0 };
	
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

stock SetBlockRenderColor(ent, id)
{
	new iColorIndex = g_bBlockRandomColor[id] ? random_num(0, MAX_COLORS - 1) : g_iColor[id];
	
	new Float:flColorVec[3];
	flColorVec[0] = g_aColors[iColorIndex][Red];
	flColorVec[1] = g_aColors[iColorIndex][Green];
	flColorVec[2] = g_aColors[iColorIndex][Blue];
	
	set_pev(ent, pev_rendercolor, flColorVec);
	set_pev(ent, pev_renderamt, g_aColors[iColorIndex][RenderAmount]);
}


stock SetLockedBlock(ent, id, bool:LockMode = false, bool:SetColorBlock = true)
{	
	set_pev(ent, pev_rendermode, kRenderTransColor);
	
	if (g_iLockBlocks == 0)
	{
		set_pev(ent, pev_rendercolor, Float:{LOCKED_COLOR});
	}
	else if (SetColorBlock)
	{
		SetBlockRenderColor(ent, id);
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

stock RecordAdminAction(const id, const player, const szLogType[], const szAction[], const szChatExtra[] = "", const szHudLangKey[] = "", const szHudExtra[] = "")
{
	new szAdminName[32], szPlayerName[32];
	new szAdminAuthid[32], szPlayerAuthid[32];
	
	get_user_name(id, szAdminName, charsmax(szAdminName));
	get_user_authid(id, szAdminAuthid, charsmax(szAdminAuthid));
	get_user_name(player, szPlayerName, charsmax(szPlayerName));
	get_user_authid(player, szPlayerAuthid, charsmax(szPlayerAuthid));

	Log("[%s] Admin: %s (%s) %s Player: %s (%s)", szLogType, szAdminName, szAdminAuthid, szAction, szPlayerName, szPlayerAuthid);
	
	if (szChatExtra[0])
	{
		CC_SendMessage(0, "%s Admin ^x04%s^x01 %s ^x04%s^x01 %s", MODNAME, szAdminName, szAction, szPlayerName, szChatExtra);
	}
	else
	{
		CC_SendMessage(0, "%s Admin ^x04%s^x01 %s ^x04%s^x01", MODNAME, szAdminName, szAction, szPlayerName);
	}
	
	client_print(id, print_console, "[Pro BaseBuilder] You %s %s", szAction, szPlayerName);
	
	if (szHudLangKey[0])
	{
		set_dhudmessage(255, 0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2);
		
		if (szHudExtra[0])
			show_dhudmessage(player, "%L", LANG_SERVER, szHudLangKey, szHudExtra);
		else
			show_dhudmessage(player, "%L", LANG_SERVER, szHudLangKey);
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
		client_print(id, print_console, "[Pro BaseBuilder] %L", LANG_SERVER, "FAIL_NAME");
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
	userHudDeal[id] = (userHudDeal[id] + 1)% sizeof(hudPosHit);

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

stock bool:BlockCheck(id, iEntity2, Float:ent2_mins[3], Float:ent2_maxs[3], BlockCheckType:checkType)
{
	new Float:center[3], Float:radius;
	xs_vec_add(ent2_mins, ent2_maxs, center);
	xs_vec_div_scalar(center, 2.0, center);
	radius = get_distance_f(center, ent2_maxs);

	new iEntity1 = -1;
	while ((iEntity1 = engfunc(EngFunc_FindEntityInSphere, iEntity1, center, radius)) != 0)
	{
		if (!is_valid_build_ent(iEntity1) || iEntity1 == iEntity2)
		{
			continue;
		}
		
		if (checkType == CHECK_FOR_COLOR && !BlockLocker(iEntity1))
		{
			continue;
		}
		
		new Float:ent1_mins[3], Float:ent1_maxs[3];
		get_block_origin(iEntity1, ent1_mins, ent1_maxs);
		
		if (DoBoxesIntersect(ent2_mins, ent2_maxs, ent1_mins, ent1_maxs))
		{
			switch (checkType)
			{
				case CHECK_FOR_BLOCKING:
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
				case CHECK_FOR_COLOR:
				{
					new Float:LockColor[3];
					pev(iEntity1, pev_rendercolor, LockColor);

					if (floatabs(g_aColors[g_iColor[id]][Red] - LockColor[0]) < 5.0 &&
						floatabs(g_aColors[g_iColor[id]][Green] - LockColor[1]) < 5.0 &&
						floatabs(g_aColors[g_iColor[id]][Blue] - LockColor[2]) < 5.0)
					{
						new iEnt1Mins[3], iEnt1Maxs[3];
						FVecIVec(ent1_mins, iEnt1Mins);
						FVecIVec(ent1_maxs, iEnt1Maxs);
						te_create_box(iEnt1Mins, iEnt1Maxs, 5, 0, 0, 255, id);
						return true;
					}
				}
			}
		}
	}
	return false;
}

stock get_block_origin(ent, Float:out_mins[3], Float:out_maxs[3])
{
	static Float:origin[3], Float:angles[3];
	static Float:mins[3], Float:maxs[3];
	static Float:local_corners[8][3], Float:world_corners[8][3];
	static Float:fwd[3], Float:right[3], Float:up[3], Float:left[3];

	pev(ent, pev_origin, origin);
	pev(ent, pev_angles, angles);
	pev(ent, pev_mins, mins);
	pev(ent, pev_maxs, maxs);
	
	for (new i = 0; i < 8; i++)
	{
		local_corners[i][0] = (i & 1) ? maxs[0] : mins[0];
		local_corners[i][1] = (i & 2) ? maxs[1] : mins[1];
		local_corners[i][2] = (i & 4) ? maxs[2] : mins[2];
	}

	xs_anglevectors(angles, fwd, right, up);
	xs_vec_neg(right, left);
	
	for (new i = 0; i < 8; i++)
	{
		new Float:rotated_offset[3];
		xs_vec_mul_scalar(fwd, local_corners[i][0], rotated_offset);
		xs_vec_mul_add(left, local_corners[i][1], rotated_offset, rotated_offset);
		xs_vec_mul_add(up, local_corners[i][2], rotated_offset, rotated_offset);
		xs_vec_add(origin, rotated_offset, world_corners[i]);
	}

	xs_vec_copy(world_corners[0], out_mins);
	xs_vec_copy(world_corners[0], out_maxs);
	
	for (new i = 1; i < 8; i++)
	{
		if (world_corners[i][0] < out_mins[0]) out_mins[0] = world_corners[i][0];
		if (world_corners[i][1] < out_mins[1]) out_mins[1] = world_corners[i][1];
		if (world_corners[i][2] < out_mins[2]) out_mins[2] = world_corners[i][2];
		
		if (world_corners[i][0] > out_maxs[0]) out_maxs[0] = world_corners[i][0];
		if (world_corners[i][1] > out_maxs[1]) out_maxs[1] = world_corners[i][1];
		if (world_corners[i][2] > out_maxs[2]) out_maxs[2] = world_corners[i][2];
	}
}

stock xs_vec_mul_add(const Float:v1[3], const Float:s, const Float:v2[3], Float:out[3])
{
	out[0] = v1[0] * s + v2[0];
	out[1] = v1[1] * s + v2[1];
	out[2] = v1[2] * s + v2[2];
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
    
	new Float:ent_mins[3], Float:ent_maxs[3];
	get_block_origin(ent, ent_mins, ent_maxs);
    
	if (callfunc_begin("CheckBlockInZone", "bbzones.amxx") == 1)
	{
		callfunc_push_int(id);
		callfunc_push_int(ent);
		callfunc_push_float(ent_mins[0]);
		callfunc_push_float(ent_mins[1]);
		callfunc_push_float(ent_mins[2]);
		callfunc_push_float(ent_maxs[0]);
		callfunc_push_float(ent_maxs[1]);
		callfunc_push_float(ent_maxs[2]);
		callfunc_end();
	}
	
	if (is_valid_ent(ent) && g_isMapConfigured && g_bCheckForBlocker && !access(id, FLAGS_OVERRIDE) && BlockCheck(id, ent, ent_mins, ent_maxs, CHECK_FOR_BLOCKING))
	{
		if (BlockLocker(ent))
		{
			new cloneEnt = g_iClonedEnts[ent];
			if (is_valid_ent(cloneEnt))
			{
				remove_entity(cloneEnt);
				g_iClonedEnts[ent] = 0;
			}
		}
		remove_entity(ent);
		
		fade_user_screen(id, 1.0, 0.8, ScreenFade_FadeIn, 255, 0, 0, 150);
		shake_user_screen(id, 8.0, 0.8, 180.0);
		
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_WARNING]);
		return;
	}
}