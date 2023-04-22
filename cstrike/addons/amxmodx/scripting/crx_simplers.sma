#include <amxmodx>
#include <cromchat>
#include <cstrike>
#include <fun>

#define PLUGIN_VERSION "2.1"
#define ARG_NAME "<name>"

new g_pMessage
new const g_szCommands[][] = { "/rs", "/resetscore" }

public plugin_init()
{
	register_plugin("Simple Resetscore", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXSimpleRS", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	g_pMessage = register_cvar("simplers_message", "&x04[&x03Simple Resetscore&x04] &x03<name> &x01has just reset his score!")
	
	for(new i; i < sizeof(g_szCommands); i++)
		register_chat_command(g_szCommands[i], "Cmd_ResetScore")
}

public Cmd_ResetScore(id)
{
	new szMessage[256], iType
	get_pcvar_string(g_pMessage, szMessage, charsmax(szMessage))
	
	if(contain(szMessage, ARG_NAME) != -1)
	{
		new szName[32]
		get_user_name(id, szName, charsmax(szName))
		replace(szMessage, charsmax(szMessage), ARG_NAME, szName)
		iType = 1
	}
		
	set_user_frags(id, 0)
	cs_set_user_deaths(id, 0)
	CC_SendMatched(iType ? id : 0, id, szMessage)
	return PLUGIN_HANDLED
}

register_chat_command(const szCommand[], const szFunction[])
{
	static szTemp[32]
	formatex(szTemp, charsmax(szTemp), "say %s", szCommand)
	register_clcmd(szTemp, szFunction)
	formatex(szTemp, charsmax(szTemp), "say_team %s", szCommand)
	register_clcmd(szTemp, szFunction)
}