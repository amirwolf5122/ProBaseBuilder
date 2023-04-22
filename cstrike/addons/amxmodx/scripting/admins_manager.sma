#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Admins Manager"
#define VERSION "1.3"
#define AUTHOR "Alka"

#define STR_LEN 64

#define MENU_ACCESS_FLAG ADMIN_RCON

new gConfigsDir[STR_LEN];
new gAdminsFile[STR_LEN];

new const gAdminFlags[][] = {
	
	"a", "b", "c", "d", 
	"e", "f", "g", "h", 
	"i", "j", "k", "l",
	"m", "n", "o", "p",
	"q", "r", "s", "t",
	"u"
};
new const gAdminAccessFlags[][] = {
	
	"a", "b", "c", "d", "e"
};	
new const gAdminFlagsDetails[][] = {
	
	"Immunity",
	"Reservation",
	"Kick",
	"Ban / Unban",
	"Slay / Slap",
	"Change Map",
	"Cvar change",
	"Cfg exec",
	"Chat messages",
	"Vote",
	"Server Password",
	"Rcon",
	"Custom A",
	"Custom B",
	"Custom C",
	"Custom D",
	"Custom E",
	"Custom F",
	"Custom G",
	"Custom H",
	"Amxx Menu"
};
new const gAdminAccessFlagsDetails[][] = {
	
	"Disconnect on invalid password",
	"Clan tag",
	"For SteamId / WonId",
	"For Ip",
	"Password is not checked"
};
new gAdminTargetId[33];
new gAdminTargetFlags[33][32];
new gAdminTargetPassword[33][STR_LEN];
new gAdminTargetAccessFlags[33][32];
new gAdminTargetAccount[33][32];
new gAdminTargetDetails[33][4][STR_LEN];
new gAdminSaveMode[33];
new bool:gAccessFromEditMenu[33];

public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_saycmd("adminsmanager", "cmdAdminsManage", -1, "");
	
	register_concmd("amx_adminpassword", "cmdAdminPassword", MENU_ACCESS_FLAG, "<password> - Save / change this password for specified admin.");
	register_concmd("amx_adminaccount", "cmdAdminAccount", MENU_ACCESS_FLAG, "<name / ip / steam id> - Save / change this account info for specified admin.");
	
	get_configsdir(gConfigsDir, sizeof gConfigsDir - 1);
	formatex(gAdminsFile, sizeof gAdminsFile - 1, "%s/users.ini", gConfigsDir);
	
	if(!file_exists(gAdminsFile))
		set_fail_state("Non-existent file.");
}

public cmdAdminsManage(id)
{
	static iMenu, iCallBack;
	iMenu = menu_create("\yAdmins manager (\wMain Menu\y):", "MainMenuHandler");
	iCallBack = menu_makecallback("MainMenuCallBack");
	
	menu_additem(iMenu, "\wAdd Admin", "1", 0, iCallBack);
	menu_additem(iMenu, "\wRemove Admin", "2", 0, iCallBack);
	menu_additem(iMenu, "\wEdit Admin", "3", 0, iCallBack);
	
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public MainMenuCallBack(id, menu, item)
	return access(id, MENU_ACCESS_FLAG) ? ITEM_ENABLED : ITEM_DISABLED;

public MainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
		return 1;
	
	static iAccess, iCallback;
	static sData[6];
	menu_item_getinfo(menu, item, iAccess, sData, sizeof sData - 1, _, _, iCallback);
	
	static iKey;
	iKey = str_to_num(sData);
	
	switch(iKey)
	{
		case 1: { cmdAdminAdd(id); }
		case 2: { cmdAdminRemove(id); }
		case 3: { cmdAdminEdit(id); }
	}
	return 1;
}

public cmdAdminAdd(id)
{
	static iMenu;
	iMenu = menu_create("\yAdmins manager (\wAdd Admin\y):", "AddMenuHandler");
	
	static sPlayers[32], iNum;
	get_players(sPlayers, iNum, "ch");
	
	for(new i = 0 ; i < iNum ; i++)
	{
		static sName[32];
		get_user_name(sPlayers[i], sName, sizeof sName - 1);
		
		menu_additem(iMenu, sName, "", 0, -1);
	}
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public AddMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminsManage(id);
		return 1;
	}
	
	static iAccess, iCallback;
	static sBuffer[32];
	menu_item_getinfo(menu, item, iAccess, "", 0, sBuffer, sizeof sBuffer - 1, iCallback);
	
	static iTarget;
	iTarget = get_user_index(sBuffer);
	
	gAdminTargetId[id] = iTarget;
	
	cmdAdminAddSubMenu(id);
	return 1;
}

public cmdAdminAddSubMenu(id)
{	
	static sTemp[STR_LEN], sName[32];
	get_user_name(gAdminTargetId[id], sName, sizeof sName - 1);
	
	formatex(sTemp, sizeof sTemp - 1, "\yAdmins manager (\wAdd Admin \r%s\y):", sName);
	
	static iMenu;
	iMenu = menu_create(sTemp, "AddSubMenuHandler");
	
	menu_additem(iMenu, "\wAdd / Remove flags", "1", 0, -1);
	menu_additem(iMenu, "\wReset flags", "2", 0, -1);
	menu_addblank(iMenu, 0);
	
	static sBuffer[STR_LEN];
	switch(gAdminSaveMode[id])
	{
		case 0: { formatex(sBuffer, sizeof sBuffer - 1, "\wSave admin mode: \rIp"); }
		case 1: { formatex(sBuffer, sizeof sBuffer - 1, "\wSave admin mode: \rSteam Id"); }
		case 2: { formatex(sBuffer, sizeof sBuffer - 1, "\wSave admin mode: \rName + Password"); }
	}
	
	menu_additem(iMenu, sBuffer, "3", 0, -1);
	menu_additem(iMenu, "\wSave admin", "4", 0, -1);
	menu_addblank(iMenu, 0);
	
	menu_display(id, iMenu, 0);
}

public AddSubMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminAdd(id);
		return 1;
	}
	
	static iAccess, iCallback;
	static sData[6];
	menu_item_getinfo(menu, item, iAccess, sData, sizeof sData - 1, _, _, iCallback);
	
	static iKey;
	iKey = str_to_num(sData);
	
	switch(iKey)
	{
		case 1: { cmdAdminAddFlags(id); }
		case 2: { cmdAdminAddResetFlags(id); }
		case 3: { cmdAdminSaveMode(id); }
		case 4: { cmdAdminAddSave(id); }
	}
	return 1;
}

public cmdAdminAddFlags(id)
{
	static iMenu;
	iMenu = menu_create("\yAdmins manager (\wAdd Admin flags):", "AddFlagsMenuHandler");
	
	static sTemp[128];
	
	for(new i = 0 ; i < sizeof gAdminFlags ; i++)
	{
		formatex(sTemp, sizeof sTemp - 1, "%s - \y%s", gAdminFlags[i], gAdminFlagsDetails[i]);
		menu_additem(iMenu, sTemp, "", 0, -1);
	}
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public AddFlagsMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		if(gAccessFromEditMenu[id])
		{
			cmdAdminEditSubMenu(id);
			gAccessFromEditMenu[id] = false;
			
			return 1;
		}
		else
		{
			cmdAdminAddSubMenu(id);
			return 1;
		}
	}
	
	static iAccess, iCallback;
	static sTemp[32], sBuffer[10];
	menu_item_getinfo(menu, item, iAccess, "", 0, sTemp, sizeof sTemp - 1, iCallback);
	
	strtok(sTemp, sBuffer, sizeof sBuffer - 1, sTemp, sizeof sTemp - 1, '-', 1);
	
	if(containi(gAdminTargetFlags[id], sBuffer) != -1)
		replace(gAdminTargetFlags[id], sizeof gAdminTargetFlags[] - 1, sBuffer, "");
	else
		format(gAdminTargetFlags[id], sizeof gAdminTargetFlags[] - 1, "%s%s", gAdminTargetFlags[id], sBuffer);
	
	set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
	show_hudmessage(id, "Add Admin flags : ^"%s^"", gAdminTargetFlags[id]);
	
	menu_display(id, menu, 0);
	return 1;
}

public cmdAdminAddResetFlags(id)
{
	formatex(gAdminTargetFlags[id], sizeof gAdminTargetFlags[] - 1, "");
	
	set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
	show_hudmessage(id, "Add Admin flags : Flags reseted");
	
	cmdAdminAddSubMenu(id);
	return 1;
}

public cmdAdminSaveMode(id)
{
	static iNum;
	iNum++;
	
	if(iNum > 2)
		iNum = 0;
	
	gAdminSaveMode[id] = iNum;
	
	if(iNum == 2)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
		show_hudmessage(id, "Add Admin Password: Type on console the new admin password^ncommand: amx_adminpassword");
	}
	cmdAdminAddSubMenu(id);
	return 1;
}

public cmdAdminAddSave(id)
{
	static iFile;
	iFile = fopen(gAdminsFile, "at+");
	
	if(!gAdminTargetFlags[id][0])
	{
		set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
		show_hudmessage(id, "You must select some flags before save^nthe admin.");
		
		cmdAdminAddSubMenu(id);
		return 1;
	}
	static UserInfo[32];
	
	switch(gAdminSaveMode[id])
	{
		case 0: { get_user_ip(gAdminTargetId[id], UserInfo, sizeof UserInfo - 1, 1); }
		case 1: { get_user_authid(gAdminTargetId[id], UserInfo, sizeof UserInfo - 1); }
		case 2:
		{
			if(!gAdminTargetPassword[id][0])
			{
				set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
				show_hudmessage(id, "Type on console the new admin password^ncommand: amx_adminpassword <password>");
				
				cmdAdminAddSubMenu(id);
				return 1;
			}
			get_user_name(gAdminTargetId[id], UserInfo, sizeof UserInfo - 1);	
		}
	}
	
	static sTemp[128];
	new iLine;
	
	while(!feof(iFile))
	{
		fgets(iFile, sTemp, sizeof sTemp - 1);
		
		iLine++;
		
		if((containi(sTemp, UserInfo) != -1) && sTemp[0] != ';')
		{
			client_print(id, print_chat, "Sorry but an admin account with this account info already exists!");
			return 1;
		}
	}
	
	static sBuffer[128];
	switch(gAdminSaveMode[id])
	{
		case 0: { formatex(sBuffer, sizeof sBuffer - 1, "^n^"%s^" ^"^" ^"%s^" ^"de^"", UserInfo, gAdminTargetFlags[id]); }
		case 1: { formatex(sBuffer, sizeof sBuffer - 1, "^n^"%s^" ^"^" ^"%s^" ^"ce^"", UserInfo, gAdminTargetFlags[id]); }
		case 2: { formatex(sBuffer, sizeof sBuffer - 1, "^n^"%s^" ^"%s^" ^"%s^" ^"a^"", UserInfo, gAdminTargetPassword[id], gAdminTargetFlags[id]); }
	}
	
	fprintf(iFile, sBuffer);
	
	fclose(iFile);
	client_print(id, print_chat, "Successfuly added ^"%s^" to admins list on line %d!", UserInfo, iLine + 1);
	server_cmd("amx_reloadadmins");
	
	formatex(gAdminTargetFlags[id], sizeof gAdminTargetFlags[] - 1, "");
	formatex(gAdminTargetPassword[id], sizeof gAdminTargetPassword[] - 1, "");
	gAdminTargetId[id] = 0;
	
	return 1;
}

public cmdAdminPassword(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return 1;
	
	static sArg[64];
	read_argv(1, sArg, sizeof sArg - 1);
	
	if(!sArg[0])
		return 1;
	
	formatex(gAdminTargetPassword[id], sizeof gAdminTargetPassword[] - 1, sArg);
	
	console_print(id, "Successfuly saved password : ^"%s^" for specified admin!", gAdminTargetPassword[id]);
	return 1;
}

public cmdAdminRemove(id)
{
	static iMenu;
	iMenu = menu_create("\yAdmins manager (\wRemove Admin\y):", "RemoveMenuHandler");
	
	static sBuffer[128], sTempItem[128];
	static sTemp[4][STR_LEN];
	
	static iFileP;
	iFileP = fopen(gAdminsFile, "rt");
	
	while(!feof(iFileP))
	{
		fgets(iFileP, sBuffer, sizeof sBuffer - 1);
		
		if((strlen(sBuffer) < 3) || sBuffer[0] == ';')
			continue;
		
		parse(sBuffer, sTemp[0], sizeof sTemp[] - 1, sTemp[1], sizeof sTemp[] - 1, sTemp[2], sizeof sTemp[] - 1, sTemp[3], sizeof sTemp[] - 1);
		
		for(new j = 0 ; j < sizeof sTemp ; j++)
		{
			remove_quotes(sTemp[j]);
		}
		
		formatex(sTempItem, sizeof sTempItem - 1, "\w%s\r|\w%s\r|\w%s\r|\w%s\r", sTemp[0], sTemp[1], sTemp[2], sTemp[3]);
		
		menu_additem(iMenu, sTempItem, "", 0, -1);
	}
	fclose(iFileP);
	
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public RemoveMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminsManage(id);
		return 1;
	}
	
	static iAccess, iCallback;
	static sBuffer[128], sTemp[STR_LEN];
	menu_item_getinfo(menu, item, iAccess, "", 0, sBuffer, sizeof sBuffer - 1, iCallback);
	
	strtok(sBuffer, sTemp, sizeof sTemp - 1, sBuffer, sizeof sBuffer - 1, '|');
	
	replace(sTemp, sizeof sTemp - 1, "\w", "");
	replace(sTemp, sizeof sTemp - 1, "\r", "");
	trim(sTemp);
	
	static iFileP;
	iFileP = fopen(gAdminsFile, "rt");
	
	static sTempAccount[STR_LEN];
	new i;
	
	while(!feof(iFileP))
	{
		fgets(iFileP, sBuffer, sizeof sBuffer - 1);
		
		i++;
		
		if((strlen(sBuffer) < 3) || sBuffer[0] == ';')
			continue;
		
		parse(sBuffer, sTempAccount, sizeof sTempAccount - 1);
		
		remove_quotes(sTempAccount);
		
		if(equali(sTempAccount, sTemp))
		{
			format(sBuffer, sizeof sBuffer - 1, ";%s", sBuffer);
			write_file(gAdminsFile, sBuffer, i - 1);
			break;
		}
	}
	fclose(iFileP);
	client_print(id, print_chat, "Successfuly removed ^"%s^" from admins list!", sTemp);
	server_cmd("amx_reloadadmins");
	
	return 1;
}

public cmdAdminEdit(id)
{
	static iMenu;
	iMenu = menu_create("\yAdmins manager (\wEdit Admin\y):", "EditMenuHandler");
	
	static sBuffer[128], sTempItem[128];
	static sTemp[4][STR_LEN];
	
	static iFileP;
	iFileP = fopen(gAdminsFile, "rt");
	
	while(!feof(iFileP))
	{
		fgets(iFileP, sBuffer, sizeof sBuffer - 1);
		
		if((strlen(sBuffer) < 3) || sBuffer[0] == ';')
			continue;
		
		parse(sBuffer, sTemp[0], sizeof sTemp[] - 1, sTemp[1], sizeof sTemp[] - 1, sTemp[2], sizeof sTemp[] - 1, sTemp[3], sizeof sTemp[] - 1);
		
		for(new j = 0 ; j < sizeof sTemp ; j++)
		{
			remove_quotes(sTemp[j]);
		}
		
		formatex(sTempItem, sizeof sTempItem - 1, "\w%s\r|\w%s\r|\w%s\r|\w%s\r", sTemp[0], sTemp[1], sTemp[2], sTemp[3]);
		
		menu_additem(iMenu, sTempItem, "", 0, -1);
	}
	fclose(iFileP);
	
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public EditMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminsManage(id);
		
		for(new j = 0 ; j < sizeof gAdminTargetDetails[] ; j++)
			formatex(gAdminTargetDetails[id][j], sizeof gAdminTargetDetails[][] - 1, "");
		
		return 1;
	}
	
	static iAccess, iCallback;
	static sBuffer[128];
	menu_item_getinfo(menu, item, iAccess, "", 0, sBuffer, sizeof sBuffer - 1, iCallback);
	
	str_piece(id, sBuffer, gAdminTargetDetails, sizeof gAdminTargetDetails[], sizeof gAdminTargetDetails[][] - 1, '|');
	
	for(new j = 0 ; j < sizeof gAdminTargetDetails[] ; j++)
	{
		replace(gAdminTargetDetails[id][j], sizeof gAdminTargetDetails[][] - 1, "\w", "");
		replace(gAdminTargetDetails[id][j], sizeof gAdminTargetDetails[][] - 1, "\r", "");
		trim(gAdminTargetDetails[id][j]);
	}
	cmdAdminEditSubMenu(id);
	return 1;
}

public cmdAdminEditSubMenu(id)
{
	static iMenu, sTemp[STR_LEN];
	formatex(sTemp, sizeof sTemp - 1, "\yAdmins Manager(\wEdit Admin \r%s\y):", gAdminTargetDetails[id][0]);
	
	iMenu = menu_create(sTemp, "EditSubMenuHandler");
	
	menu_additem(iMenu, "\wEdit account name", "1", 0, -1);
	menu_additem(iMenu, "\wEdit password", "2", 0, -1);
	menu_additem(iMenu, "\wEdit flags", "3", 0 , -1);
	menu_additem(iMenu, "\wEdit access flags", "4", 0, -1);
	menu_addblank(iMenu, 0);
	menu_additem(iMenu, "\wSave modification", "5", 0, -1);
	
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public EditSubMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminEdit(id);
		return 1;
	}
	
	static iAccess, iCallback;
	static sData[6];
	menu_item_getinfo(menu, item, iAccess, sData, sizeof sData - 1, _, _, iCallback);
	
	static iKey;
	iKey = str_to_num(sData);
	
	switch(iKey)
	{
		case 1:
		{
			set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
			show_hudmessage(id, "Type on console command: amx_adminaccount for details.");
		}
		case 2:
		{
			set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
			show_hudmessage(id, "Type on console command: amx_adminpassword for details.");
		}
		case 3:
		{
			gAccessFromEditMenu[id] = true;
			cmdAdminAddFlags(id);
			
			return 1;
		}
		case 4: { cmdAdminAddAccessFlags(id); return 1; }
		case 5: { cmdSaveAdminModification(id); return 1; }
	}
	menu_display(id, menu, 0);
	return 1;
}

public cmdAdminAccount(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return 1;
	
	static sArg[64];
	read_argv(1, sArg, sizeof sArg - 1);
	
	if(!sArg[0])
		return 1;
	
	formatex(gAdminTargetAccount[id], sizeof gAdminTargetAccount[] - 1, sArg);
	
	console_print(id, "Successfuly saved account : ^"%s^" for specified admin.", gAdminTargetAccount[id]);
	return 1;
}

public cmdAdminAddAccessFlags(id)
{
	static iMenu;
	iMenu = menu_create("\yAdmins manager (\wEdit Admin access flags):", "AddAccessFlagsMenuHandler");
	
	static sTemp[128];
	
	for(new i = 0 ; i < sizeof gAdminAccessFlags ; i++)
	{
		formatex(sTemp, sizeof sTemp - 1, "%s - \y%s", gAdminAccessFlags[i], gAdminAccessFlagsDetails[i]);
		menu_additem(iMenu, sTemp, "", 0, -1);
	}
	menu_addblank(iMenu, 0);
	menu_display(id, iMenu, 0);
}

public AddAccessFlagsMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		cmdAdminEditSubMenu(id);
		return 1;
	}
	
	static iAccess, iCallback;
	static sTemp[32], sBuffer[10];
	menu_item_getinfo(menu, item, iAccess, "", 0, sTemp, sizeof sTemp - 1, iCallback);
	
	strtok(sTemp, sBuffer, sizeof sBuffer - 1, sTemp, sizeof sTemp - 1, '-', 1);
	
	if(containi(gAdminTargetAccessFlags[id], sBuffer) != -1)
		replace(gAdminTargetAccessFlags[id], sizeof gAdminTargetAccessFlags[] - 1, sBuffer, "");
	else
		format(gAdminTargetAccessFlags[id], sizeof gAdminTargetAccessFlags[] - 1, "%s%s", gAdminTargetAccessFlags[id], sBuffer);
	
	set_hudmessage(255, 255, 255, -1.0, 0.8, 0, 1.0, 2.0, 0.2, 0.1, 1);
	show_hudmessage(id, "Add Admin access flags : ^"%s^"", gAdminTargetAccessFlags[id]);
	
	menu_display(id, menu, 0);
	return 1;
}

public cmdSaveAdminModification(id)
{
	static iFileP;
	iFileP = fopen(gAdminsFile, "rt");
	
	static sBuffer[128], sTempAccount[4][STR_LEN];
	new i;
	
	while(!feof(iFileP))
	{
		fgets(iFileP, sBuffer, sizeof sBuffer - 1);
		
		i++;
		
		if((strlen(sBuffer) < 3) || sBuffer[0] == ';')
			continue;
		
		parse(sBuffer, sTempAccount[0], sizeof sTempAccount[] - 1, sTempAccount[1], sizeof sTempAccount[] - 1, sTempAccount[2], sizeof sTempAccount[] - 1, sTempAccount[3], sizeof sTempAccount[] - 1);
		
		for(new j = 0 ; j < sizeof sTempAccount ; j++)
		{
			remove_quotes(sTempAccount[j]);
		}
		
		if(equali(sTempAccount[0], gAdminTargetDetails[id][0]))
		{
			formatex(sBuffer, sizeof sBuffer - 1, "^"%s^" ^"%s^" ^"%s%^" ^"%s^"", gAdminTargetAccount[id][0] ? gAdminTargetAccount[id] : sTempAccount[0], gAdminTargetPassword[id][0] ? gAdminTargetPassword[id] : sTempAccount[1], gAdminTargetFlags[id][0] ? gAdminTargetFlags[id] : sTempAccount[2], gAdminTargetAccessFlags[id][0] ? gAdminTargetAccessFlags[id] : sTempAccount[3]);
			write_file(gAdminsFile, sBuffer, i - 1);
			break;
		}
	}
	fclose(iFileP);
	client_print(id, print_chat, "Successfuly edited admin account ^"%s^"!", gAdminTargetDetails[id][0]);
	server_cmd("amx_reloadadmins");
	
	formatex(gAdminTargetFlags[id], sizeof gAdminTargetFlags[] - 1, "");
	formatex(gAdminTargetPassword[id], sizeof gAdminTargetPassword[] - 1, "");
	formatex(gAdminTargetAccessFlags[id], sizeof gAdminTargetAccessFlags[] - 1, "");
	formatex(gAdminTargetAccount[id], sizeof gAdminTargetAccount[] - 1, "");
	
	return 1;
}

stock register_saycmd(saycommand[], function[], flags = -1, info[])
{
	static sTemp[64];
	formatex(sTemp, sizeof sTemp - 1, "say /%s", saycommand);
	register_clcmd(sTemp, function, flags, info);
	formatex(sTemp, sizeof sTemp - 1, "say .%s", saycommand);
	register_clcmd(sTemp, function, flags, info);
	formatex(sTemp, sizeof sTemp - 1, "say_team /%s", saycommand);
	register_clcmd(sTemp, function, flags, info);
	formatex(sTemp, sizeof sTemp - 1, "say_team .%s", saycommand);
	register_clcmd(sTemp, function, flags, info);
}

stock str_piece(index, const input[], output[][][], outputsize, piecelen, token = '|') //Stock by purple_pixie, edited by me. :D
{
	new i = -1, pieces, len = -1;
	
	while(input[++i] != 0)
	{
		if (input[i] != token)
		{
			if (++len < piecelen)
				output[index][pieces][len] = input[i];
		}
		else
		{
			output[index][pieces++][++len] = 0;
			len = -1;
			
			if(pieces == outputsize)
				return pieces;
		}
	}
	return pieces + 1;
}
