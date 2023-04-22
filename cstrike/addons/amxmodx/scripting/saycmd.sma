#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <cromchat>

#define PLUGIN	"slash commands"
#define VERSION	"5.1"
#define AUTHOR	"Enzo & MarshaL"
#define ACCESS ADMIN_CVAR

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /r1","restart",ACCESS)
	register_clcmd("say /map","amx_mapmenu",ACCESS)
	register_clcmd("say /sl","amx_slapmenu",ACCESS)
	register_clcmd("say /k","amx_kickmenu",ACCESS)
	register_clcmd("say /vm","amx_votemapmenu",ACCESS)
	register_clcmd("say /mod","amx_clcmdmenu",ACCESS)
	register_clcmd("say /war","warnmenu",ACCESS)
	register_clcmd("say /a1","amxmodmenu",ACCESS)
	register_clcmd("say /am","adminsmanager",ACCESS)
	register_clcmd("say /sxe","amx_sxe_menu",ACCESS)
	register_clcmd("say /ucp","ucp_menu",ACCESS)
	register_clcmd("say /bm","amx_banmenu",ACCESS)
	register_clcmd("say /ubm","amx_unbanmenu",ACCESS)
	register_clcmd("say /p","puase",ACCESS)
	register_clcmd("say /g","gag",ACCESS)
	register_clcmd("say /t1","ontalk",ACCESS)
	register_clcmd("say /t0","offtalk",ACCESS)
	register_clcmd("say /join1","join1",ACCESS)
	register_clcmd("say /join0","join0",ACCESS)
	register_clcmd("say /say1","say1",ACCESS)
	register_clcmd("say /say0","say0",ACCESS)
	register_clcmd("say /name1","name1",ACCESS)
	register_clcmd("say /name0","name0",ACCESS)
}

public name1(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_noname 0");
		CC_SendMessage(0, "^4%s: /name1", Name);
	}
	return PLUGIN_HANDLED
}
public name0(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_noname 1");
		CC_SendMessage(0, "^4%s: /name0", Name);
	}
	return PLUGIN_HANDLED
}
public say1(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_nosay 0");
		CC_SendMessage(0, "^4%s: /say1", Name);
	}
	return PLUGIN_HANDLED
}
public say0(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_nosay 1");
		CC_SendMessage(0, "^4%s: say0", Name);
	}
	return PLUGIN_HANDLED
}
public join1(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_chooseteam 1");
		CC_SendMessage(0, "^4%s: /join1", Name);
	}
	return PLUGIN_HANDLED
}
public join0(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_chooseteam 0");
		CC_SendMessage(0, "^4%s: /join0", Name)
	}
	return PLUGIN_HANDLED
}
public warnmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		client_cmd(id,"warnmenu");
	}
	return PLUGIN_HANDLED
}
public amx_clcmdmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_clcmdmenu");
		CC_SendMessage(0, "^4%s: /mod", Name)
	}
	return PLUGIN_HANDLED
}
public amx_votemapmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_votemapmenu");
		CC_SendMessage(0, "^4%s: /vm", Name)
	}
	return PLUGIN_HANDLED
}
public amx_kickmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_kickmenu");
		CC_SendMessage(0, "^4%s: /k", Name)
	}
	return PLUGIN_HANDLED
}
public amx_slapmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_slapmenu");
		CC_SendMessage(0, "^4%s: /sl", Name)
	}
	return PLUGIN_HANDLED
}
public restart(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_restart 1");
		CC_SendMessage(0, "^4%s: /r", Name)
	}
	return PLUGIN_HANDLED
}
public amx_mapmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_mapmenu");
		CC_SendMessage(0, "^4%s: /map", Name)
	}
	return PLUGIN_HANDLED
}
public amxmodmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amxmodmenu");
		CC_SendMessage(0, "^4%s: /a1", Name)
	}
	return PLUGIN_HANDLED
}
public adminsmanager(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		client_cmd(id,"say_team /adminsmanager");
	}
	return PLUGIN_HANDLED
}
public amx_sxe_menu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_sxe_menu");
		CC_SendMessage(0, "^4%s: /sxe", Name)
	}
	return PLUGIN_HANDLED
}
public ucp_menu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new name[32]
		get_user_info(id, "name", name, 31)
		client_cmd(id,"ucp_menu");
		ColorChat(0, GREEN,"%s: /ucp",name)
	}
	return PLUGIN_HANDLED
}
public amx_banmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_banmenu");
		CC_SendMessage(0, "^4%s: /bm", Name)
	}
	return PLUGIN_HANDLED
}
public amx_unbanmenu(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		client_cmd(id,"amx_unbanmenu");
		CC_SendMessage(0, "^4%s: /ubm", Name)
	}
	return PLUGIN_HANDLED
}
public puase(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("amx_pause");
		CC_SendMessage(0, "^4%s: /p", Name)
	}
	return PLUGIN_HANDLED
}
public gag(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("amx_gagmenu");
		CC_SendMessage(0, "^4%s: /g", Name)
	}
	return PLUGIN_HANDLED
}
public ontalk(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_alltalk 1");
		CC_SendMessage(0, "^4%s: /t1", Name)
	}
	return PLUGIN_HANDLED
}
public offtalk(id, level, cid)
{
	if(cmd_access(id,level, cid, 1))
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("sv_alltalk 0");
		CC_SendMessage(0, "^4%s: /t0", Name)
	}
	return PLUGIN_HANDLED
}