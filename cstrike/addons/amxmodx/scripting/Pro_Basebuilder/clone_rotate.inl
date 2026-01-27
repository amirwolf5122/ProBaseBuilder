new g_userClone[MAXPLAYERS+1], g_numUserClones[MAXPLAYERS+1], g_maxUserClones;

public CloneBlock(id)
{
	if (isPlayer(g_iOwnedEnt[id]) || !g_isMapConfigured) return PLUGIN_CONTINUE;
	
	if (g_numUserClones[id] >= g_maxUserClones)
	{
		client_print(id, print_center, "You have already cloned the maximum of [%d / %d] objects.", g_numUserClones[id], g_maxUserClones);
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		return PLUGIN_HANDLED;
	}
	
	g_userClone[id] = !g_userClone[id];
	
	return PLUGIN_HANDLED;
}

public RotateBlock(id)
{
	if (g_fRotateDelay[id] + BUILD_DELAY > get_gametime())
	{
		g_fRotateDelay[id] = get_gametime();
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_SPAM");
		return 0;
	}
	else g_fRotateDelay[id] = get_gametime();
	
	new ent;
	if (!g_isMapConfigured || !(ent = g_iOwnedEnt[id]) || isPlayer(ent)) return 0;
	
	new Float:currentAngles[3];
	pev(ent, pev_angles, currentAngles);
	
	currentAngles[1] += 90.0;
	
	if (currentAngles[1] >= 180.0) currentAngles[1] -= 180.0;
	
	SetEntityAngles(id, currentAngles, ent);
	
	client_cmd(id, "spk %s", g_szSoundPaths[SOUND_GRAB_START]);
	
	return 1;
}

SetEntityAngles(id, const Float:angles[3], ent)
{
	if (!is_valid_ent(ent))
		return;
	
	new Float:origin[3];
	origin = GetEntityOrigin(ent);
	
	set_pev(ent, pev_angles, angles);
	set_pev(ent, pev_origin, Float:{0.0, 0.0, 0.0});
	
	new Float:newOrigin[3];
	newOrigin = GetEntityOrigin(ent);
	
	xs_vec_sub(origin, newOrigin, origin);
	
	engfunc(EngFunc_SetOrigin, ent, origin);
	
	if (BlockLocker(ent))
	{
		new cloneEnt = g_iClonedEnts[ent];
		if (is_valid_ent(cloneEnt))
		{
			set_pev(cloneEnt, pev_angles, angles);
			engfunc(EngFunc_SetOrigin, cloneEnt, origin);
		}
	}
	
	new iOrigin[3], Float:fOrigin[3], Float:vMoveTo[3], Float:velocity_vec[3];
	
	get_user_origin(id, iOrigin, 1);
	IVecFVec(iOrigin, fOrigin);
	
	velocity_by_aim(id, floatround(g_fEntDist[id]), velocity_vec);
	
	xs_vec_add(fOrigin, velocity_vec, vMoveTo);
	xs_vec_sub(origin, vMoveTo, g_fOffset[id]);
}

Float:GetEntityOrigin(ent)
{
	new Float:origin[3];
	pev(ent, pev_origin, origin);
	
	new Float:center[3];
	{
		new Float:mins[3], Float:maxs[3];
		pev(ent, pev_mins, mins);
		pev(ent, pev_maxs, maxs);
		
		xs_vec_add(mins, maxs, center);
		xs_vec_mul_scalar(center, 0.5, center);
	}
	
	new Float:rotatedCenter[3];
	{
		new Float:angles[3];
		pev(ent, pev_angles, angles);
		
		new Float:fwd[3], Float:left[3], Float:up[3], Float:right[3];
		xs_anglevectors(angles, fwd, right, up);
		xs_vec_neg(right, left);
		
		rotatedCenter[0] = fwd[0]*center[0] + left[0]*center[1] + up[0]*center[2];
		rotatedCenter[1] = fwd[1]*center[0] + left[1]*center[1] + up[1]*center[2];
		rotatedCenter[2] = fwd[2]*center[0] + left[2]*center[1] + up[2]*center[2];
	}
	
	xs_vec_add(origin, rotatedCenter, origin);
	
	return origin;
}

public createClone(entView)
{
	new ent = create_entity("func_wall");
	if(!pev_valid(ent)) return -1;
	
	new szClassName[16];
	pev(entView, pev_classname, szClassName, sizeof(szClassName));
	set_pev(ent, pev_classname, szClassName);
	
	pev(entView, pev_model, szClassName, sizeof(szClassName));
	set_pev(ent, pev_model, szClassName);
	
	set_pev(ent, pev_solid, pev(entView, pev_solid));
	set_pev(ent, pev_movetype, pev(entView, pev_movetype));
	set_pev(ent, pev_modelindex, pev(entView, pev_modelindex));
	set_pev(ent, pev_body, pev(entView, pev_body));
	set_pev(ent, pev_skin, pev(entView, pev_skin));
	set_pev(ent, pev_flags, pev(entView, pev_flags));
	
	new Float:fFloat[3];
	pev(entView, pev_angles, fFloat);
	set_pev(ent, pev_angles, fFloat);
	
	pev(entView, pev_mins, fFloat);
	set_pev(ent, pev_mins, fFloat);
	
	pev(entView, pev_maxs, fFloat);
	set_pev(ent, pev_maxs, fFloat);
	
	pev(entView, pev_origin, fFloat);
	
	entity_set_origin(ent, fFloat);
	
	return ent;
}
