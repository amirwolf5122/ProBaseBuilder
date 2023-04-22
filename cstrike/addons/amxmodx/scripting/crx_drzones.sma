#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_VERSION "1.1"
#define ADMIN_ACCESS ADMIN_RCON
#define TASK_SHOWZONES 377737

#define ZONE_SPRITE "sprites/laserbeam.spr"
#define ZONE_STARTFRAME 1
#define ZONE_FRAMERATE 1
#define ZONE_LIFE 12
#define ZONE_WIDTH 5
#define ZONE_NOISE 0
#define ZONE_COLOR_RED 255
#define ZONE_COLOR_GREEN 0
#define ZONE_COLOR_BLUE 0
#define ZONE_COLOR_SELECTED_RED 0
#define ZONE_COLOR_SELECTED_GREEN random(256)
#define ZONE_COLOR_SELECTED_BLUE 255
#define ZONE_BRIGHTNESS 255
#define ZONE_SPEED 0
#define ZONE_VIEWDISTANCE 800.0
#define ZONE_BLOCKEDTEAM 1

// Comment this line to disable the beam when setting points.
#define BEAM_ENABLED

// Comment a line to disable the sound.
#define SOUND_SETPOINT "agrunt/ag_fire2.wav"
#define SOUND_SELECT "bullchicken/bc_spithit3.wav"
#define SOUND_DELETE "buttons/button10.wav"
#define SOUND_DELETEALL "buttons/button11.wav"
//#define SOUND_TELEPORT "debris/beamstart7.wav"

#if defined BEAM_ENABLED
	#define BEAM_SPRITE "sprites/lgtning.spr"
	#define BEAM_STARTFRAME 0
	#define BEAM_FRAMERATE 10
	#define BEAM_LIFE 2
	#define BEAM_WIDTH 15
	#define BEAM_NOISE 2
	#define BEAM_COLOR_RED 255
	#define BEAM_COLOR_GREEN 0
	#define BEAM_COLOR_BLUE 0
	#define BEAM_COLOR_SELECT_RED 0
	#define BEAM_COLOR_SELECT_GREEN random(256)
	#define BEAM_COLOR_SELECT_BLUE 255
	#define BEAM_BRIGHTNESS 255
	#define BEAM_SPEED 30
	
	new g_iBeamSprite
#endif

new const g_szPrefix[] = "^4[DRZones]^1"
new const g_szEntString[] = "info_target"
new const g_szClassname[] = "DRZone"

new g_szDirectory[512], g_szFilename[512], g_szMap[32]

new Array:g_aZones
new Trie:g_tZones
new bool:g_blBuilding[33]
new Float:g_flBuildOrigin[33][2][3]
new g_iBuildStage[33]
new g_iCurrentZone[33][2]

new bool:g_blHighlight[33]
new g_iZoneSprite

new Float:g_flSpawnPoint[2][3]
new g_iTotalZones
new g_iSayText
new g_pGlobal

public plugin_init()
{
	register_plugin("DeathRun Anti-T Zones", PLUGIN_VERSION, "OciXCrom")
	register_cvar("DRZones", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("DRZones.txt")
	
	register_touch(g_szClassname, "player", "OnTouchZone")
	register_clcmd("say /drzone", "menuZone")
	register_clcmd("say_team /drzone", "menuZone")
	register_clcmd("drop", "selectPoint")
	g_pGlobal = register_cvar("drzone_global", "1")
	
	new iEnt = find_ent_by_class(iEnt, "info_player_deathmatch")
	pev(iEnt, pev_origin, g_flSpawnPoint[0])
	
	iEnt = FM_NULLENT
	
	iEnt = find_ent_by_class(iEnt, "info_player_start")
	pev(iEnt, pev_origin, g_flSpawnPoint[1])
	
	get_mapname(g_szMap, charsmax(g_szMap))
	strtolower(g_szMap)
	
	get_datadir(g_szDirectory, charsmax(g_szDirectory))
	add(g_szDirectory, charsmax(g_szDirectory), "/DRZones")	
	formatex(g_szFilename, charsmax(g_szFilename), "%s/%s.txt", g_szDirectory, g_szMap)
	
	if(!dir_exists(g_szDirectory))
		mkdir(g_szDirectory)
	
	g_aZones = ArrayCreate(5, 1)
	g_tZones = TrieCreate()
	g_iSayText = get_user_msgid("SayText")
	fileRead(0)
}

public plugin_end()
{
	fileRead(1)
	ArrayDestroy(g_aZones)
	TrieDestroy(g_tZones)
}

fileRead(iWrite)
{
	new iFilePointer
	
	switch(iWrite)
	{
		case 0:
		{
			iFilePointer = fopen(g_szFilename, "rt")
	
			if(iFilePointer)
			{
				new szData[200], szPoint[6][32]
				new Float:flPoint[2][3]
				
				while(!feof(iFilePointer))
				{
					fgets(iFilePointer, szData, charsmax(szData))
					trim(szData)
					
					if(szData[0] == EOS || szData[0] == ';')
						continue
						
					parse(szData, szPoint[0], charsmax(szPoint[]), szPoint[1], charsmax(szPoint[]), szPoint[2], charsmax(szPoint[]),
					szPoint[3], charsmax(szPoint[]), szPoint[4], charsmax(szPoint[]), szPoint[5], charsmax(szPoint[]))
					
					for(new i; i < 3; i++)
						flPoint[0][i] = str_to_float(szPoint[i])
						
					for(new i; i < 3; i++)
						flPoint[1][i] = str_to_float(szPoint[i + 3])
					
					CreateZone(flPoint[0], flPoint[1])
				}
			}
		}
		case 1:
		{
			delete_file(g_szFilename)
			
			if(!g_iTotalZones)
				return
				
			iFilePointer = fopen(g_szFilename, "wt")
			
			new szCoords[200], szZone[5], iZone
			
			for(new i; i < g_iTotalZones; i++)
			{
				iZone = ArrayGetCell(g_aZones, i)
				num_to_str(iZone, szZone, charsmax(szZone))
				TrieGetString(g_tZones, szZone, szCoords, charsmax(szCoords))
				fprintf(iFilePointer, "%s^n", szCoords)
			}
		}
	}
	
	fclose(iFilePointer)
}

public OnTouchZone(iZone, id)
{
	if(get_user_team(id) != ZONE_BLOCKEDTEAM && !get_pcvar_num(g_pGlobal))
		return
		
	set_pev(id, pev_origin, g_flSpawnPoint[clamp(get_user_team(id) - 1, 0, 2)])
/*	ColorChat(id, "%L", LANG_PLAYER, "DRZONE_NOTLEAVE")
	
	#if defined SOUND_TELEPORT
		player_emitsound(id, SOUND_TELEPORT)
	#endif*/
}

public selectPoint(id)
{
	if(!g_blBuilding[id])
		return PLUGIN_CONTINUE
		
	new Float:flPointOrigin[3], flUserOrigin[3]
	get_user_origin(id, flUserOrigin, 3)
	IVecFVec(flUserOrigin, flPointOrigin)
	g_flBuildOrigin[id][g_iBuildStage[id]] = flPointOrigin
	
	#if defined SOUND_SETPOINT
		player_spksound(id, SOUND_SETPOINT)
	#endif
	
	#if defined BEAM_ENABLED
		draw_beam(id)
	#endif
	
	switch(g_iBuildStage[id])
	{
		case 0:
		{
			g_iBuildStage[id]++
			ColorChat(id, "%L", LANG_PLAYER, "DRZONE_SET_SECOND")
		}
		case 1:
		{
			g_iBuildStage[id]--
			g_blBuilding[id] = false
			CreateZone(g_flBuildOrigin[id][0], g_flBuildOrigin[id][1])
			ColorChat(id, "%L", LANG_PLAYER, "DRZONE_CREATED")
		}
	}
	
	menu_reopen(id)
	return PLUGIN_HANDLED
}

public menuZone(id)
{
	if(!(get_user_flags(id) & ADMIN_ACCESS))
	{
		ColorChat(id, "%L", LANG_PLAYER, "DRZONE_NOACCESS")
		return PLUGIN_HANDLED
	}
	
	new szTitle[128], szItem[64]
	formatex(szTitle, charsmax(szTitle), "\r%L \d| \y%s \d| \r%i %L", LANG_PLAYER, "DRZONE_DRZONES", g_szMap, g_iTotalZones, LANG_PLAYER, "DRZONE_ZONES")
	
	new iMenu = menu_create(szTitle, "handlerZone")
	
	formatex(szItem, charsmax(szItem), "%L", LANG_PLAYER, g_blBuilding[id] ? "DRZONE_CANCEL" : "DRZONE_ADD")
	menu_additem(iMenu, szItem, "")
	
	formatex(szItem, charsmax(szItem), "%L", LANG_PLAYER, g_blHighlight[id] ? "DRZONE_HIDE" : "DRZONE_HIGHLIGHT")
	menu_additem(iMenu, szItem, "")
	
	formatex(szItem, charsmax(szItem), "%s%L", g_iTotalZones ? "" : "\d", LANG_PLAYER, "DRZONE_SELECT")
	menu_additem(iMenu, szItem, "")
	
	formatex(szItem, charsmax(szItem), "%s%L", g_iTotalZones && is_zone(g_iCurrentZone[id][0]) ? "" : "\d", LANG_PLAYER, "DRZONE_DELETE")
	menu_additem(iMenu, szItem, "")
	
	formatex(szItem, charsmax(szItem), "%s%L", g_iTotalZones ? "" : "\d", LANG_PLAYER, "DRZONE_DELETEALL")
	menu_additem(iMenu, szItem, "")
	
	formatex(szItem, charsmax(szItem), "%s%L", g_iTotalZones && is_zone(g_iCurrentZone[id][0]) ? "" : "\d", LANG_PLAYER, "DRZONE_TELEPORT")
	menu_additem(iMenu, szItem, "")
	
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public handlerZone(id, iMenu, iItem)
{
	if(iItem == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	
	switch(iItem)
	{
		case 0:
		{
			if(g_blBuilding[id])
			{
				g_iBuildStage[id] = 0
				g_blBuilding[id] = false
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_CANCELED")
			}
			else
			{
				g_blBuilding[id] = true
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_SET_FIRST")
			}
		}
		case 1:
		{
			if(g_blHighlight[id])
			{
				g_blHighlight[id] = false
				remove_task(id + TASK_SHOWZONES)
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_HIGHLIGHT_DISABLED")
			}
			else
			{
				g_blHighlight[id] = true
				set_task(1.0, "showZones", id + TASK_SHOWZONES, "", 0, "b", 0)
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_HIGHLIGHT_ENABLED")
			}
		}
		case 2:
		{
			if(g_iTotalZones)
			{
				menu_destroy(iMenu)
				menuSelect(id)
				return PLUGIN_HANDLED
			}
			else noZones(id)
		}
		case 3:
		{
			if(is_zone(g_iCurrentZone[id][0]))
			{
				ColorChat(id, "%L", LANG_SERVER, "DRZONE_REMOVED", g_iCurrentZone[id][0])
				player_remove_zone(id)
				
				#if defined SOUND_DELETE
					player_spksound(id, SOUND_DELETE)
				#endif
			}
			else invalidZone(id)
		}
		case 4:
		{
			if(g_iTotalZones)
			{
				new iPlayers[32], iPnum, iEnt
				get_players(iPlayers, iPnum)
				
				while((iEnt = find_ent_by_class(iEnt, g_szClassname)))
					if(pev_valid(iEnt))
						remove_entity(iEnt)
				
				for(new i, iPlayer; i < iPnum; i++)
				{
					iPlayer = iPlayers[i]
					g_iCurrentZone[iPlayer][0] = 0
					g_iCurrentZone[iPlayer][1] = 0
				}
				
				g_iTotalZones = 0
				ArrayClear(g_aZones)
				TrieClear(g_tZones)
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_REMOVEDALL")
				
				#if defined SOUND_DELETEALL
					player_spksound(id, SOUND_DELETEALL)
				#endif
			}
			else noZones(id)
		}
		case 5:
		{
			if(is_zone(g_iCurrentZone[id][0]))
			{
				new Float:flOrigin[3]
				pev(g_iCurrentZone[id][0], pev_origin, flOrigin)
				set_pev(id, pev_origin, flOrigin)
				ColorChat(id, "%L", LANG_PLAYER, "DRZONE_TELEPORTED", g_iCurrentZone[id][0])
				
/*				#if defined SOUND_TELEPORT
					player_emitsound(id, SOUND_TELEPORT)
				#endif*/
			}
			else invalidZone(id)
		}
	}
	
	menu_destroy(iMenu)
	menuZone(id)
	return PLUGIN_HANDLED
}

public menuSelect(id)
{
	new szTitle[128], szItem[64], szTemp[32], szZone[5], iZone
	formatex(szTitle, charsmax(szTitle), "\r%L \d| \y%s \d| \r%i %L", LANG_PLAYER, "DRZONE_DRZONES", g_szMap, g_iTotalZones, LANG_PLAYER, "DRZONE_ZONES")
	
	new iMenu = menu_create(szTitle, "handlerSelect")
	
	formatex(szItem, charsmax(szItem), "\r%L", LANG_PLAYER, "DRZONE_BACK")
	menu_additem(iMenu, szItem, "0")
	
	formatex(szItem, charsmax(szItem), "\r%L", LANG_PLAYER, "DRZONE_DESELECT")
	menu_additem(iMenu, szItem, "1")
	
	for(new i; i < g_iTotalZones; i++)
	{
		iZone = ArrayGetCell(g_aZones, i)
		num_to_str(iZone, szZone, charsmax(szZone))
		formatex(szItem, charsmax(szItem), "%L #%i", LANG_PLAYER, "DRZONE_ZONE", iZone)
		
		if(g_iCurrentZone[id][0] == iZone)
		{
			formatex(szTemp, charsmax(szTemp), " \y[%L]", LANG_PLAYER, "DRZONE_CURRENT")
			add(szItem, charsmax(szItem), szTemp)
		}
		
		menu_additem(iMenu, szItem, szZone)
	}
	
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public handlerSelect(id, iMenu, iItem)
{
	switch(iItem)
	{
		case MENU_EXIT:
		{
			menu_destroy(iMenu)
			return PLUGIN_HANDLED
		}
		case 0:
		{
			menu_destroy(iMenu)
			menuZone(id)
			return PLUGIN_HANDLED
		}
		case 1:
		{
			g_iCurrentZone[id][0] = 0
			ColorChat(id, "%L", LANG_PLAYER, "DRZONE_DESELECTED")
			menu_destroy(iMenu)
			menuSelect(id)
			return PLUGIN_HANDLED
		}
	}
	
	new szData[6], iName[64], iAccess, iCallback
	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), iName, charsmax(iName), iCallback)
	new iKey = str_to_num(szData)
	
	g_iCurrentZone[id][0] = iKey
	g_iCurrentZone[id][1] = iItem - 2
	ColorChat(id, "%L", LANG_PLAYER, "DRZONE_SELECTED", iKey)
	
	#if defined SOUND_SELECT
		player_spksound(id, SOUND_SELECT)
	#endif
	
	#if defined BEAM_ENABLED
		draw_beam(id, iKey)
	#endif
	
	menu_destroy(iMenu)
	menuSelect(id)
	return PLUGIN_HANDLED
}

CreateZone(Float:flFirstPoint[3], Float:flSecondPoint[3])
{
	new Float:flCenter[3], Float:flSize[3]
	new Float:flMins[3], Float:flMaxs[3]
	
	for(new i; i < 3; i++)
	{
		flCenter[i] = (flFirstPoint[i] + flSecondPoint[i]) / 2.0
		flSize[i] = get_float_difference(flFirstPoint[i], flSecondPoint[i])
		flMins[i] = flSize[i] / -2.0
		flMaxs[i] = flSize[i] / 2.0
	}
	
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, g_szEntString))
	
	if(pev_valid(iEnt))
	{
		engfunc(EngFunc_SetOrigin, iEnt, flCenter)
		set_pev(iEnt, pev_classname, g_szClassname)
		dllfunc(DLLFunc_Spawn, iEnt)
		set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
		set_pev(iEnt, pev_solid, SOLID_TRIGGER)
		engfunc(EngFunc_SetSize, iEnt, flMins, flMaxs)
	}
	
	new szCoords[200], szZone[5]
	formatex(szCoords, charsmax(szCoords), "%f %f %f %f %f %f", flFirstPoint[0], flFirstPoint[1], flFirstPoint[2], flSecondPoint[0], flSecondPoint[1], flSecondPoint[2])
	num_to_str(iEnt, szZone, charsmax(szZone))
	TrieSetString(g_tZones, szZone, szCoords)
	ArrayPushCell(g_aZones, iEnt)
	g_iTotalZones++
}

public showZones(id)
{
	id -= TASK_SHOWZONES
	
	if(!is_user_connected(id))
	{
		remove_task(id + TASK_SHOWZONES)
		return
	}
	
	new iMins[3], iMaxs[3], iEnt
	new Float:flUserOrigin[3], Float:flOrigin[3], Float:flMins[3], Float:flMaxs[3]
	new bool:blCurrentZone
	pev(id, pev_origin, flUserOrigin)
	
	while((iEnt = find_ent_by_class(iEnt, g_szClassname)))
	{
		blCurrentZone = (iEnt == g_iCurrentZone[id][0]) ? true : false
		
		pev(iEnt, pev_origin, flOrigin)
		
		if(get_distance_f(flUserOrigin, flOrigin) > ZONE_VIEWDISTANCE)
			continue
		
		pev(iEnt, pev_mins, flMins)
		pev(iEnt, pev_maxs, flMaxs)
	
		flMins[0] += flOrigin[0]
		flMins[1] += flOrigin[1]
		flMins[2] += flOrigin[2]
		flMaxs[0] += flOrigin[0]
		flMaxs[1] += flOrigin[1]
		flMaxs[2] += flOrigin[2]
		
		FVecIVec(flMins, iMins)
		FVecIVec(flMaxs, iMaxs)

		draw_line(id, blCurrentZone, iMaxs[0], iMaxs[1], iMaxs[2], iMins[0], iMaxs[1], iMaxs[2])
		draw_line(id, blCurrentZone, iMaxs[0], iMaxs[1], iMaxs[2], iMaxs[0], iMins[1], iMaxs[2])
		draw_line(id, blCurrentZone, iMaxs[0], iMaxs[1], iMaxs[2], iMaxs[0], iMaxs[1], iMins[2])
		draw_line(id, blCurrentZone, iMins[0], iMins[1], iMins[2], iMaxs[0], iMins[1], iMins[2])
		draw_line(id, blCurrentZone, iMins[0], iMins[1], iMins[2], iMins[0], iMaxs[1], iMins[2])
		draw_line(id, blCurrentZone, iMins[0], iMins[1], iMins[2], iMins[0], iMins[1], iMaxs[2])
		draw_line(id, blCurrentZone, iMins[0], iMaxs[1], iMaxs[2], iMins[0], iMaxs[1], iMins[2])
		draw_line(id, blCurrentZone, iMins[0], iMaxs[1], iMins[2], iMaxs[0], iMaxs[1], iMins[2])
		draw_line(id, blCurrentZone, iMaxs[0], iMaxs[1], iMins[2], iMaxs[0], iMins[1], iMins[2])
		draw_line(id, blCurrentZone, iMaxs[0], iMins[1], iMins[2], iMaxs[0], iMins[1], iMaxs[2])
		draw_line(id, blCurrentZone, iMaxs[0], iMins[1], iMaxs[2], iMins[0], iMins[1], iMaxs[2])
		draw_line(id, blCurrentZone, iMins[0], iMins[1], iMaxs[2], iMins[0], iMaxs[1], iMaxs[2])
	}
}

public plugin_precache()
{
	g_iZoneSprite = precache_model(ZONE_SPRITE)
	
	#if defined SOUND_SETPOINT
		precache_sound(SOUND_SETPOINT)
	#endif
	
	#if defined SOUND_SELECT
		precache_sound(SOUND_SELECT)
	#endif
	
	#if defined SOUND_DELETE
		precache_sound(SOUND_DELETE)
	#endif
	
	#if defined SOUND_DELETEALL
		precache_sound(SOUND_DELETEALL)
	#endif
	
/*	#if defined SOUND_TELEPORT
		precache_sound(SOUND_TELEPORT)
	#endif*/
	
	#if defined BEAM_ENABLED
		g_iBeamSprite = precache_model(BEAM_SPRITE)
	#endif
}

menu_reopen(id)
{
	new iNewMenu, iMenu = player_menu_info(id, iMenu, iNewMenu)
	
	if(iMenu)
	{
		show_menu(id, 0, "^n", 1)
		menuZone(id)
	}
}

#if defined BEAM_ENABLED
	draw_beam(id, iZone = 0)
	{
		new iUserOrigin[3], iPointOrigin[3]
		get_user_origin(id, iUserOrigin)
		
		if(iZone && pev_valid(iZone))
		{
			new Float:flOrigin[3]
			pev(iZone, pev_origin, flOrigin)
			FVecIVec(flOrigin, iPointOrigin)
		}
		else get_user_origin(id, iPointOrigin, 3)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMPOINTS)
		write_coord(iUserOrigin[0])
		write_coord(iUserOrigin[1])
		write_coord(iUserOrigin[2])
		write_coord(iPointOrigin[0])
		write_coord(iPointOrigin[1])
		write_coord(iPointOrigin[2])
		write_short(g_iBeamSprite)
		write_byte(BEAM_STARTFRAME)
		write_byte(BEAM_FRAMERATE)
		write_byte(BEAM_LIFE)
		write_byte(BEAM_WIDTH)
		write_byte(BEAM_NOISE)
		write_byte(iZone ? BEAM_COLOR_SELECT_RED : BEAM_COLOR_RED)
		write_byte(iZone ? BEAM_COLOR_SELECT_GREEN : BEAM_COLOR_GREEN)
		write_byte(iZone ? BEAM_COLOR_SELECT_BLUE : BEAM_COLOR_BLUE)
		write_byte(BEAM_BRIGHTNESS)
		write_byte(BEAM_SPEED)
		message_end()
	}
#endif

draw_line(id, bool:blCurrentZone, x1, y1, z1, x2, y2, z2)
{
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, SVC_TEMPENTITY, _, id ? id : 0)
	write_byte(TE_BEAMPOINTS)
	write_coord(x1)
	write_coord(y1)
	write_coord(z1)
	write_coord(x2)
	write_coord(y2)
	write_coord(z2)
	write_short(g_iZoneSprite)
	write_byte(ZONE_STARTFRAME)
	write_byte(ZONE_FRAMERATE)
	write_byte(ZONE_LIFE)
	write_byte(ZONE_WIDTH)
	write_byte(ZONE_NOISE)
	write_byte(blCurrentZone ? ZONE_COLOR_SELECTED_RED : ZONE_COLOR_RED)
	write_byte(blCurrentZone ? ZONE_COLOR_SELECTED_GREEN : ZONE_COLOR_GREEN)
	write_byte(blCurrentZone ? ZONE_COLOR_SELECTED_BLUE : ZONE_COLOR_BLUE)
	write_byte(ZONE_BRIGHTNESS)
	write_byte(ZONE_SPEED)
	message_end()
}

player_emitsound(id, szSound[])
	emit_sound(id, CHAN_ITEM, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)

player_spksound(id, szSound[])
	client_cmd(id, "spk %s", szSound)

noZones(id)
	ColorChat(id, "%L", LANG_PLAYER, "DRZONE_NOZONES")
	
invalidZone(id)
	ColorChat(id, "%L", LANG_PLAYER, "DRZONE_INVALID")

player_remove_zone(id)
{
	new szZone[5]
	num_to_str(g_iCurrentZone[id][0], szZone, charsmax(szZone))
	ArrayDeleteItem(g_aZones, g_iCurrentZone[id][1])
	TrieDeleteKey(g_tZones, szZone)
	remove_entity(g_iCurrentZone[id][0])
	g_iCurrentZone[id][0] = 0
	g_iCurrentZone[id][1] = 0
	g_iTotalZones--
}

bool:is_zone(iEnt)
{
	if(!pev_valid(iEnt))
		return false
		
	new szClass[32]
	pev(iEnt, pev_classname, szClass, charsmax(szClass))
	return equal(szClass, g_szClassname) ? true : false
}

Float:get_float_difference(Float:flNumber1, Float:flNumber2)
	return (flNumber1 > flNumber2) ? (flNumber1 - flNumber2) : (flNumber2 - flNumber1)

ColorChat(const id, const szInput[], any:...)
{
	new iPlayers[32], iCount = 1
	static szMessage[191]
	vformat(szMessage, charsmax(szMessage), szInput, 3)
	format(szMessage[0], charsmax(szMessage), "%s %s", g_szPrefix, szMessage)
	
	replace_all(szMessage, charsmax(szMessage), "!g", "^4")
	replace_all(szMessage, charsmax(szMessage), "!n", "^1")
	replace_all(szMessage, charsmax(szMessage), "!t", "^3")
	
	if(id)
		iPlayers[0] = id
	else
		get_players(iPlayers, iCount, "ch")
	
	for(new i; i < iCount; i++)
	{
		if(is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, g_iSayText, _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMessage)
			message_end()
		}
	}
}