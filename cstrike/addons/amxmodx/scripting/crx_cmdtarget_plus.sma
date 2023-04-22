#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN_VERSION "1.3"
#define CMD_MULTI -69
#define MULTI_ARG "<arg>"
#define SYM_NOGROUP "n"

new Trie:g_tArgs
new Trie:g_tNoGroups

new const g_szNoGroups[][] = { "@spec", "@ct", "@t", "@all" }

public plugin_init()
{
	register_plugin("Command Targeting Plus", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXCMDTarget", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	g_tArgs = TrieCreate()
	g_tNoGroups = TrieCreate()
	ReadFile()
}

public plugin_end()
{
	TrieDestroy(g_tArgs)
	TrieDestroy(g_tNoGroups)
}

ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/CMDTargetPlus.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[64], szCommand[60], szArg[3]
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData)); trim(szData)
			
			switch(szData[0])
			{
				case EOS, '#', ';': continue
				default:
				{
					parse(szData, szCommand, charsmax(szCommand), szArg, charsmax(szArg))
					
					if(contain(szArg, SYM_NOGROUP) != -1)
					{
						TrieSetCell(g_tNoGroups, szCommand, 1)
						replace(szArg, charsmax(szArg), SYM_NOGROUP, "")
					}
					
					TrieSetCell(g_tArgs, szCommand, szArg[0] == EOS ? 1 : str_to_num(szArg))
					register_concmd(szCommand, "OnCommand")
					szArg[0] = EOS
				}
			}
		}
		
		fclose(iFilePointer)
	}
}

public OnCommand(id)
{
	static szArg[64], szCmd[32], iArgNum
	read_argv(0, szCmd, charsmax(szCmd))
	TrieGetCell(g_tArgs, szCmd, iArgNum)
	read_argv(iArgNum, szArg, charsmax(szArg))
	
	static szFullCmd[128]
	read_args(szFullCmd, charsmax(szFullCmd))
	
	if(contain(szArg, ";") != -1)
	{
		static szValue[128]
		replace(szFullCmd, charsmax(szFullCmd), szArg, MULTI_ARG)
		
		while(szArg[0] != 0 && strtok(szArg, szValue, charsmax(szValue), szArg, charsmax(szArg), ';'))
		{
			trim(szArg); trim(szValue)
			replace(szFullCmd, charsmax(szFullCmd), MULTI_ARG, szValue)
			client_cmd(id, "%s %s", szCmd, szFullCmd)
			replace(szFullCmd, charsmax(szFullCmd), szValue, MULTI_ARG)
		}
		
		return PLUGIN_HANDLED
	}
	
	if(szArg[0] == '@')
	{
		if(TrieKeyExists(g_tNoGroups, szCmd))
		{
			static i
			
			for(i = 0; i < sizeof(g_szNoGroups); i++)
			{
				if(equali(g_szNoGroups[i], szArg))
					return PLUGIN_CONTINUE
			}
		}
		
		format(szFullCmd, charsmax(szFullCmd), "%s %s", szCmd, szFullCmd)
		
		if(is_this_command(id, szArg, "aim", false, false))
		{
			static iPlayer, iBody
			get_user_aiming(id, iPlayer, iBody)
			
			if(iPlayer)
				do_cmd_by_index(id, iPlayer, szFullCmd, szArg)
		}
		/*else if(is_this_command(id, szArg, "r", false, false))
		{
			static Float:fOrigin[3], Float:fRadius, szClassname[32], iEnt
			entity_get_vector(id, EV_VEC_origin, fOrigin)
			fRadius = str_to_float(szArg[2])
		   
			while((iEnt = find_ent_in_sphere(iEnt, fOrigin, fRadius)) != 0)
			{
				if(id == iEnt)
					continue
					
				entity_get_string(iEnt, EV_SZ_classname, szClassname, charsmax(szClassname))
				
				if(equal(szClassname, "player"))
					do_cmd_by_index(id, iEnt, szFullCmd, szArg)
			}
		}*/
		else if(is_this_command(id, szArg, "spectating", false, false))
		{
			static iPlayer
			iPlayer = pev(id, pev_iuser2)
			
			if(iPlayer)
				do_cmd_by_index(id, iPlayer, szFullCmd, szArg)
		}
		else if(is_this_command(id, szArg, "view", false, false) || is_this_command(id, szArg, "viewct", false, false) || is_this_command(id, szArg, "viewt", false, false))
		{
			static Float:fOrigin[3], iPlayers[32], iPlayer, iPnum, i
			
			switch(szArg[5])
			{
				case 'C', 'c': get_players(iPlayers, iPnum, "ae", "CT")
				case 'T', 't': get_players(iPlayers, iPnum, "ae", "TERRORIST")
				default: get_players(iPlayers, iPnum, "a")
			}
			
			for(i = 0; i < iPnum; i++)
			{
				iPlayer = iPlayers[i]
				
				if(id == iPlayer)
					continue
				
				entity_get_vector(iPlayer, EV_VEC_origin, fOrigin)
				
				if(is_in_viewcone(id, fOrigin, 1))
					do_cmd_by_index(id, iPlayer, szFullCmd, szArg)
			}
		}
		else if(is_this_command(id, szArg, "alive", true, true))					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "a"); }
		else if(is_this_command(id, szArg, "alivect", true, true))					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "ae", "CT"); }
		else if(is_this_command(id, szArg, "alivet", true, true))					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "ae", "TERRORIST"); }
		else if(is_this_command(id, szArg, "all", true, true))						{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg); }
		else if(is_this_command(id, szArg, "bots", false, true))					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "d"); }
		else if(is_this_command(id, szArg, "ct", true, true)) 						{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "e", "CT"); }
		else if(is_this_command(id, szArg, "dead", true, true)) 					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "b"); }
		else if(is_this_command(id, szArg, "deadct", true, true)) 					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "be", "CT"); }
		else if(is_this_command(id, szArg, "deadt", true, true)) 					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "be", "T"); }
		else if(is_this_command(id, szArg, "humans", true, true))					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "ch"); }
		else if(is_this_command(id, szArg, "me", false, false)) 					{ do_cmd_by_index(id, id, szFullCmd, szArg); }
		else if(is_this_command(id, szArg, "spec", true, true)) 					{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "e", "SPECTATOR"); }
		else if(is_this_command(id, szArg, "t", true, true)) 						{ do_cmd_by_index(id, CMD_MULTI, szFullCmd, szArg, "e", "TERRORIST"); }
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

do_cmd_by_index(id, iPlayer, szCmd[], szArg[], szFlags[] = "", szTeam[] = "")
{	
	if(iPlayer == CMD_MULTI)
	{
		static iPlayers[32], iPlayer, iPnum, i, bool:bNoSelf
		bNoSelf = szArg[1] == '!'
		
		get_players(iPlayers, iPnum, szFlags, szTeam)
		
		for(i = 0; i < iPnum; i++)
		{
			iPlayer = iPlayers[i]
			
			if(id == iPlayer && bNoSelf)
				continue
				
			create_and_execute(id, iPlayer, szCmd, szArg)
		}
	}
	else create_and_execute(id, iPlayer, szCmd, szArg)
}

create_and_execute(id, iPlayer, szCmd[], szArg[])
{
	static szFullCmd[128], szId[16]
	copy(szFullCmd, charsmax(szFullCmd), szCmd)
	formatex(szId, charsmax(szId), "#%i", get_user_userid(iPlayer))
	replace(szFullCmd, charsmax(szFullCmd), szArg, szId)
	client_cmd(id, szFullCmd)
}

bool:is_this_command(id, szArg[], szCommand[], bool:bAllowSelf, bool:bAllowServer)
{
	if(!bAllowServer && !is_user_connected(id))
		return false
	
	return (equali(szArg[1], szCommand) || (bAllowSelf && szArg[1] == '!' && equali(szArg[2], szCommand)))
}