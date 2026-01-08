new szFile[128], g_isMapConfigured;

public adminLockBlock(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wBlock Control Menu", "adminLockBlock_2");
	menu_additem(menu, "Lock/Unlock the Block");
	menu_additem(menu, "Delete Block");
	menu_additem(menu, "Save Blocks");
	menu_additem(menu, "Load Blocks");
	menu_additem(menu, "Reset Blocks");
	
	menu_setprop(menu, MPROP_NUMBER_COLOR, "\r");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public removeColor(ent)
{	
	set_pev(ent,pev_rendermode,kRenderNormal);
	set_pev(ent,pev_renderamt, 255.0);
}

public adminLockBlock_2(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new ent, body;
	get_user_aiming(id, ent, body);
	
	if (item <= 1)
	{
		if (!is_valid_build_ent(ent))
		{
			CC_SendMessage(id, "%s^x01 Error: Not a valid block.", MODNAME);
			adminLockBlock(id);
			return PLUGIN_HANDLED;
		}
	}
	
	switch(item)
	{
		case 0:
		{
			switch(GetEntMover(ent))
			{
				case 0:
				{
					set_pev(ent,pev_rendermode,kRenderTransColor);
					set_pev(ent,pev_rendercolor, Float:{163.0, 1.0, 37.0});
					set_pev(ent,pev_renderamt, 240.0);	
					SetEntMover(ent, 1);
					CC_SendMessage(id, "%s^x01 Blocked [%d]", MODNAME, ent);
					set_task(0.5, "removeColor", ent);
				}
				case 1:
				{					
					set_pev(ent,pev_rendermode,kRenderTransColor);
					set_pev(ent,pev_rendercolor, Float:{37.0, 167.0, 1.0});
					set_pev(ent,pev_renderamt, 240.0);
					UnsetEntMover(ent);
					CC_SendMessage(id, "%s^x01 Unlocked [%d]", MODNAME, ent);
					set_task(0.5, "removeColor", ent);
				}
			}		
		}
		case 1:
		{
			new ent, body;
			get_user_aiming(id, ent, body);
			
			if(ent == 0) return PLUGIN_HANDLED;
				
			if(!pev_valid(ent))
			{
				CC_SendMessage(id, "%s^x01 Error: No block selected.", MODNAME);	
				adminLockBlock(id);
				return PLUGIN_HANDLED;
			}
			remove_entity(ent);
		}
		case 2:
		{
			saveCloneBlock();
			CC_SendMessage(id, "%s^x01 blocks Saved.", MODNAME);
		}
		case 3:
		{
			loadCloneBlock();
			CC_SendMessage(id, "%s^x01 blocks Loaded.", MODNAME);	
		}
		case 4:
		{
			if (file_exists(szFile))
			{
				delete_file(szFile);
				CC_SendMessage(id, "%s^x01 Blocks Restart.", MODNAME);
			} else CC_SendMessage(id, "%s^x01 No file exists to reset.", MODNAME);
		}	
	}
	adminLockBlock(id);
	return PLUGIN_HANDLED;
}

public cloneBlockFolder()
{
	new szDir[128], szFolder[64];
	get_configsdir(szDir, sizeof(szDir));
	
	format(szFolder, sizeof(szFolder) - 1, "%s/CloneBlock", szDir);
	
	if (!dir_exists(szFolder))
	{
		Log("[CloneBlock] Folder 'CloneBlock' successfully created.");
		mkdir(szFolder);
	}
}

public loadCloneBlock()
{
	if (!file_exists(szFile)) return;
	
	new file = fopen(szFile, "rt");
	if (!file) return;
	
	new szData[256];
	while (!feof(file))
	{
		fgets(file, szData, sizeof(szData));
		
		new szType[2], szEnt[5], szOrigin[3][17];
		parse(szData,
			szType, sizeof(szType),
			szEnt, sizeof(szEnt),
			szOrigin[0], sizeof(szOrigin[]),
			szOrigin[1], sizeof(szOrigin[]),
			szOrigin[2], sizeof(szOrigin[])
		);
		
		new ent = str_to_num(szEnt);
		
		if (!is_valid_build_ent(ent))
		{
			continue;
		}
		
		new Float:fOrigin[3];
		for (new i = 0; i < 3; i++)
		{
			fOrigin[i] = str_to_float(szOrigin[i]);
		}
		
		switch (str_to_num(szType))
		{
			case 0:
			{
				remove_entity(ent);
				continue;
			}
			case 1:
			{
				SetEntMover(ent, 2);
				set_pev(ent, pev_vuser3, fOrigin);
				entity_set_origin(ent, fOrigin);
			}
		}
	}
	fclose(file);
}

public saveCloneBlock()
{
	new file = fopen(szFile, "wt");
	if (!file) return;
	
	new Float:fOrigin[3];
	
	for (new ent = MAXENTS - 1; ent > MAXPLAYERS; ent--)
	{
		if (!is_valid_build_ent(ent))
		{
			continue;
		}
		
		pev(ent, pev_origin, fOrigin);
		
		fprintf(file, "%d %d %f %f %f^n",
		GetEntMover(ent), ent,
		fOrigin[0], fOrigin[1], fOrigin[2]);
	}
	fclose(file);
}

public clonePrepare()
{
	new szFolder[32], szMap[32];
	
	get_mapname(szMap, sizeof(szMap));
	get_configsdir(szFolder, sizeof(szFolder));
	
	format(szFile, sizeof(szFile), "%s/CloneBlock/%s.bb", szFolder, szMap);
	
	g_isMapConfigured = file_exists(szFile);
	if (g_isMapConfigured)
	{
		loadCloneBlock();
		server_cmd("sv_restart 1");
	}
}

public warn_map_config(id)
{
	if (!is_user_connected(id))
		return;
	
	set_dhudmessage(0, 255, 0, -1.0, 0.10, 0, 10.0, 10.0);
	show_dhudmessage(id, "^xc2^xbb Say /Clonemenu ^xc2^xab");

	CC_SendMessage(id, "%s^x01 Setting blocks rejected: Map is not configured.^x04 say /Clonemenu", MODNAME);

	Log("[CloneBlock] Setting blocks rejected: Map is not configured.");
}