/*
	BaseBuilderShop
	Version 1.2 
	Copyright © 2020, Supremache



	Description:
	This plugin is designed for basebuilder mod to buy items.

	Commands:
		amx_shop — open the BaseBuilder shop.
		say /shop — open the BaseBuilder shop.
		say /bb_shop — open the BaseBuilder shop.

	
	Cvars:
		// Main Cvars
		bb_shop_enable	"1"		                 // 1/0 - Enable / Disable BB Shop         (Default: 1)
		bb_shop_msg	"1"		                 // 1/0 - Enable / Disable BB Shop Message (Default: 1)
		bb_message_time "30"                             //     - BB Shop message time             (Default: 30 sec)
		bb_shop_prefix	"&x01[&x04BBSHOP&x01]"         //     - BB Shop Messages Prefix          (Default: [BBSHOP])

		// Builders's  Menu
		bb_shop_builders_enable      "1"                 // 1/0 - Enable / Disable Builders's  Menu (Default: 1)
		bb_cost_health1_human        "10000"		 //     - +255 Health Cost   (Default: 10000)
		bb_cost_health2_human	     "5000" 		 //     - +150 Health Cost   (Default: 5000)
		bb_cost_armor        	     "4000" 		 //     - +200 Armor Cost    (Default: 4000)
		bb_he                        "1500"		 //     - He Grenade Cost    (Default: 1500)
		bb_flash               	     "1000" 		 //     - Flash Grenade Cost (Default: 1000)
		bb_smoke                     "1000"   	         //     - Smoke Grenade Cost (Default: 1000)
		bb_cost_superknife_human     "16000" 	         //     - SuperKnife Cost    (Default: 16000)
		bb_cost_bhop_human           "12000" 	         //     - BunnyHop Cost      (Default: 12000)
		bb_cost_multijump_human      "8000" 	         //     - MultiJump Cost     (Default: 8000)
		bb_cost_ultimateclip         "10000"             //     - Ultimateclip Cost  (Default: 10000)
		bb_cost_gravity_human        "12000" 	         //     - Gravity Cost       (Default: 12000)
		bb_cost_invisible_human      "5000" 	         //     - Invisible Cost     (Default: 5000)
		bb_cost_godmod_human         "5000"              //     - Godmod Cost        (Default: 5000)
		bb_cost_m249                 "7000" 	         //     - M249 Cost          (Default: 7000)
		bb_cost_g3sg1                "8000" 	         //     - G3SG1 Cost         (Default: 8000)
		bb_cost_sg550                "8000" 	         //     - SG550 Cost         (Default: 8000)

		// Zombie's health Menu
		bb_shop_zombies_enable       "1"		 // 1/0 - Enable / Disable Zombier's  Menu (Default: 1)
		bb_cost_health1_zombie       "10000"	         //     - +5000  Health Cost (Default: 10000)
		bb_cost_health2_zombie       "5000"	         //     - +2500  Health Cost (Default: 5000)
		bb_cost_superknife_zombie    "16000"	         //     - SuperKnife Cost    (Default: 16000)
		bb_cost_gravity_zombie       "12000"	         //     - Gravity Cost       (Default: 12000)
		bb_cost_speed                "6000"	         //     - Speed Cost         (Default: 6000)
		bb_cost_bhop_zombie          "12000"             //     - BunnyHop Cost      (Default: 12000)
		bb_cost_multijump_zombie     "8000"              //     - MultiJump Cost     (Default: 8000)
		bb_cost_invisible_zombie     "5000"              //     - Invisible Cost     (Default: 5000)
		bb_cost_godmod_zombie        "5000"              //     - Godmod Cost     (Default: 5000)

		// Quantity & Time Section!
		bb_multijump                 "1"		 // 1/0 - Enable / Disable Multijump Item (Default: 1)

		bb_quantity_health1_human    "255"	         //     - Health (1) Quantity    (Default: 255)
		bb_quantity_health2_human    "150"	         //     - Health (2) Quantity    (Default: 150)
		bb_quantity_armor            "200"	         //     - Armor Quantity         (Default: 200)
		bb_quantity_gravity_human    "0.5"	         //     - Gravity Quantity       (Default: 0.5)

		bb_quantity_health1_zombie   "5000"	         //     - Health (1) Quantity    (Default: 5000)
		bb_quantity_health2_zombie   "2500"	         //     - Health (2) Quantity    (Default: 2500)
		bb_quantity_gravity_zombie   "0.5"	         //     - Gravity Quantity       (Default: 0.5)

		bb_quantity_speed            "390.0"	         //     - Speed Quantity         (Default: 390.0)
		bb_knife_dmg                 "5.0"	         //     - SupreKnife Damage      (Default: 5.0)
		bb_invisible_time            "5.0"	         //     - Invisible Time         (Default: 5.0 Second)
		bb_godmod_time               "60.0"	         //     - Godmod Time            (Default: 60.0 Second)
	


	
	Changelog:
		— Version: 1.0 beta (June 16, 2020 )
			Initial beta release.
		— Version: 1.1 beta (June 17, 2020 )
			Added Enable/ Disable System..
			Added Lang File.
			Added Confing File.
			Added Shop Message 

*/


#include <amxmodx>
#include <cstrike>
#include <amxmisc>
#include <engine>
#include <fun>
#include <cromchat>
#include <hamsandwich>
#include <fakemeta_util>
#include <basebuilder>

native zp_give_user_sfpistol(id)

#define FLAGS_VIP		ADMIN_RESERVATION

#define VERSION "1.2"

#define MAX_PLAYERS 32
#define Ham_Player_ResetMaxSpeed Ham_Item_PreFrame
// weapons offsets
#define OFFSET_CLIPAMMO        51
#define OFFSET_LINUX_WEAPONS    4
#define fm_cs_set_weapon_ammo(%1,%2)    set_pdata_int(%1, OFFSET_CLIPAMMO, %2, OFFSET_LINUX_WEAPONS)

// players offsets
#define m_pActiveItem 373

const NOCLIP_WPN_BS    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
new const g_MaxClipAmmo[] = 
{
    0,
    13, //CSW_P228
    0,
    10, //CSW_SCOUT
    0,  //CSW_HEGRENADE
    7,  //CSW_XM1014
    0,  //CSW_C4
    30, //CSW_MAC10
    30, //CSW_AUG
    0,  //CSW_SMOKEGRENADE
    15, //CSW_ELITE
    20, //CSW_FIVESEVEN
    25, //CSW_UMP45
    30, //CSW_SG550
    35, //CSW_GALIL
    25, //CSW_FAMAS
    12, //CSW_USP
    20, //CSW_GLOCK18
    10, //CSW_AWP
    30, //CSW_MP5NAVY
    100,//CSW_M249
    8,  //CSW_M3
    30, //CSW_M4A1
    30, //CSW_TMP
    20, //CSW_G3SG1
    0,  //CSW_FLASHBANG
    7,  //CSW_DEAGLE
    30, //CSW_SG552
    30, //CSW_AK47
    0,  //CSW_KNIFE
    50  //CSW_P90
}

new bool:g_HasHealthAZombie[MAX_PLAYERS+1]
new bool:g_HasHealthBZombie[MAX_PLAYERS+1]
new bool:g_HasBhopZombie[MAX_PLAYERS+1]

new bool:g_HasHealthAHuman[MAX_PLAYERS+1]
new bool:g_HasHealthBHuman[MAX_PLAYERS+1]
new bool:g_HasBhopHuman[MAX_PLAYERS+1]
new bool:g_HasHeGrenade[MAX_PLAYERS+1]
new bool:g_HasFlashGrenade[MAX_PLAYERS+1]
new bool:g_HasSmokeGrenade[MAX_PLAYERS+1]
new bool:g_HasSpeed[MAX_PLAYERS+1]
new bool:g_HasInvisible[MAX_PLAYERS+1]
new bool:g_HasGodmod[MAX_PLAYERS+1]
new bool:g_HasUltimateClip[MAX_PLAYERS+1]


enum _:ItemsHuman {
	Item_HealthA = 1,
	Item_HealthB,
	Item_HE,
	Item_Flash,
	Item_Smoke,
	Item_Bhop,
	Item_UltimateClip,
	Item_Invisible,
	Item_Godmod,
	Item_M249,
	Item_G3SG1,
	Item_AK47_GOLD,
	Item_STAR
}

enum _:ItemsZombie {
	Item_HealthA_Z = 1,
	Item_HealthB_Z,
	Item_Speed,
	Item_Bhop_Z,
	Item_Bomb_Conc_Z,
	Item_Invisible_Z,
	Item_Godmod_Z
}

new g_pCvarEnable;
new g_pCvarPrefix;
new g_pCvarMessage, g_pCvarMessageTime;
new g_pMenuEnableCvars[2];
new g_pCvarHumanCost[ItemsHuman];
new g_pCvarZombieCost[ItemsZombie];
new g_pCvarQuantityHealthHumanA, g_pCvarQuantityHealthHumanB;
new g_pCvarQuantityHealthZombieA, g_pCvarQuantityHealthZombieB;
new g_pCvarQuantitySpeed;
new g_pInvisibleTime, g_pGodmodTime;

// Others
new const g_szShopFile[] = "shop.cfg";	// Shop file

public plugin_init() 
{
	register_plugin("BaseBuilderShop", VERSION, "MrAbdoO")
	
	// Multi-Lingual
	register_dictionary("shop.txt")
	
	
	// Register Commands
	register_concmd("amx_shop", "cmdBaseBuilderShop")
	register_clcmd("/shop", "cmdBaseBuilderShop");
	register_clcmd("/bb_shop", "cmdBaseBuilderShop");
	register_clcmd("say /shop", "cmdBaseBuilderShop");
	register_clcmd("say /bb_shop", "cmdBaseBuilderShop");

	
	// Shop Enable/disable
	g_pCvarEnable = register_cvar("bb_shop_enable", "1")
	g_pCvarPrefix = register_cvar("bb_shop_prefix", "&x01[&x04BBSHOP&x01]")
	g_pCvarMessage = register_cvar("bb_shop_msg", "1")
	g_pCvarMessageTime =register_cvar("bb_message_time", "30")
	set_task(get_pcvar_float(g_pCvarMessageTime), "Message" , _ , _ , _ , "b") 
	
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0")
	
	// Builders
	g_pMenuEnableCvars[0] = register_cvar("bb_shop_builders_enable", "1")
	
	g_pCvarHumanCost[Item_HealthA] = register_cvar("bb_cost_health1_human", "10000")
	g_pCvarHumanCost[Item_HealthB] = register_cvar("bb_cost_health2_human", "5000")
	g_pCvarHumanCost[Item_HE] = register_cvar("bb_he", "1500")
	g_pCvarHumanCost[Item_Flash] = register_cvar("bb_flash", "1000");
	g_pCvarHumanCost[Item_Smoke] = register_cvar("bb_smoke", "1000")
	g_pCvarHumanCost[Item_Bhop] = register_cvar("bb_cost_bhop_human", "12000")
	g_pCvarHumanCost[Item_UltimateClip] = register_cvar("bb_cost_ultimateclip", "10000")
	g_pCvarHumanCost[Item_Invisible] = register_cvar("bb_cost_invisible_human", "5000")
	g_pCvarHumanCost[Item_Godmod] = register_cvar("bb_cost_godmod_human", "5000")
	g_pCvarHumanCost[Item_M249] = register_cvar("bb_cost_m249", "7000")
	g_pCvarHumanCost[Item_G3SG1] = register_cvar("bb_cost_g3sg1", "8000")
	g_pCvarHumanCost[Item_AK47_GOLD] = register_cvar("bb_cost_AK47", "16000")
	g_pCvarHumanCost[Item_STAR] = register_cvar("bb_cost_STAR", "16000")
	
	g_pCvarQuantityHealthHumanA = register_cvar("bb_quantity_health1_human", "255");
	g_pCvarQuantityHealthHumanB = register_cvar("bb_quantity_health2_human", "150");
	
	// Zombies
	g_pMenuEnableCvars[1] = register_cvar("bb_shop_zombies_enable", "1")
	
	g_pCvarZombieCost[Item_HealthA_Z] = register_cvar("bb_cost_health1_zombie", "10000")
	g_pCvarZombieCost[Item_HealthB_Z] = register_cvar("bb_cost_health2_zombie", "5000")
	g_pCvarZombieCost[Item_Speed] = register_cvar("bb_cost_speed", "6000")
	g_pCvarZombieCost[Item_Bhop_Z] = register_cvar("bb_cost_bhop_zombie", "12000")
	g_pCvarZombieCost[Item_Bomb_Conc_Z] = register_cvar("bb_cost_Bomb_Conc_zombie", "8000")
	g_pCvarZombieCost[Item_Invisible_Z] = register_cvar("bb_cost_invisible_zombie", "5000")
	g_pCvarZombieCost[Item_Godmod_Z] = register_cvar("bb_cost_godmod_zombie", "5000")
	
	g_pCvarQuantityHealthZombieA = register_cvar("bb_quantity_health1_zombie", "5000");
	g_pCvarQuantityHealthZombieB = register_cvar("bb_quantity_health2_zombie", "2500");

	g_pCvarQuantitySpeed = register_cvar("bb_quantity_speed", "390.0")
	g_pInvisibleTime = register_cvar("bb_invisible_time", "5.0") // second
	g_pGodmodTime = register_cvar("bb_godmod_time", "60.0") // second
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "Death", "a")
	RegisterHam(Ham_Spawn, "player", "Player_Spawn_Post", 1)
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "Player_ResetMaxSpeed", 1)
	
	set_cvar_num("sv_maxspeed", 999)
	
}

public ev_RoundStart()
{
	new players[32], num;
	get_players(players, num, "a");
	for(new i=0;i<num;i++) {
		g_HasBhopHuman[players[i]] = false;
		g_HasBhopZombie[players[i]] = false;
	}
}
/*================================================================================
 [Confings]
=================================================================================*/

public plugin_cfg()
{
	new ConfigsDir[64]
	get_localinfo("amxx_configsdir", ConfigsDir, charsmax(ConfigsDir))
	format(ConfigsDir, charsmax(ConfigsDir), "%s/%s", ConfigsDir, g_szShopFile)
	get_pcvar_string(g_pCvarPrefix, CC_PREFIX, charsmax(CC_PREFIX))
	
	if (!file_exists(ConfigsDir))
	{
		server_print("BaseBuilder Shop file [%s] doesn't exists!", ConfigsDir)
		return;
	}
	server_cmd("exec ^"%s^"", ConfigsDir)
}

/*================================================================================
 [Menus]
=================================================================================*/

public cmdBaseBuilderShop(id)
{
	if ( !is_user_alive(id) )
	{
		CC_SendMessage(id, "%L", LANG_SERVER, "FAIL_DEAD");
		return PLUGIN_HANDLED;
	}
	if (!get_pcvar_num(g_pCvarEnable))
	{
		CC_SendMessage(id, "%L", LANG_SERVER, "FAIL_DISABLED")
		return PLUGIN_HANDLED;
	}
	
	if (bb_is_build_phase())
	{
		CC_SendMessage(id, "The store is available after Build Time!")
		return PLUGIN_HANDLED;
	}
	
	switch(cs_get_user_team(id))
		{
			case CS_TEAM_CT:
				CustomShopHuman(id);
				
			case CS_TEAM_T:
				CustomShopZombie(id);
				
		}
		
	return PLUGIN_HANDLED;		
}


public CustomShopHuman(id)
{
	new iMenu, Text[128];
	new iMoney = cs_get_user_money(id)
			
	if (!get_pcvar_num(g_pMenuEnableCvars[0]))
	{
		CC_SendMessage(id, "%L", id, "SHOP_HUMAN_OFF")
		return PLUGIN_HANDLED;
	}
		
	formatex(Text, sizeof(Text)-1, "\r-> \yBaseBuilderShop\r: (\yHumans\r)^n\wMoney: \y%i\r$ \y| \wPage:\r ", iMoney)
	iMenu = menu_create(Text, "BuilderShop")
	
	formatex(Text, charsmax(Text), " \w+ %i Health \y[\r%d $\y]", get_pcvar_num(g_pCvarQuantityHealthHumanA), get_pcvar_num(g_pCvarHumanCost[Item_HealthA]))
	menu_additem(iMenu, Text, "1")
	formatex(Text, charsmax(Text), " \w+ %i Health \y[\r%d $\y]", get_pcvar_num(g_pCvarQuantityHealthHumanB), get_pcvar_num(g_pCvarHumanCost[Item_HealthB]))
	menu_additem(iMenu, Text, "2")
	formatex(Text, charsmax(Text), " \wFire grenade \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_HE]))
	menu_additem(iMenu, Text, "3")
	formatex(Text, charsmax(Text), " \wPush Grenade \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_Flash]))
	menu_additem(iMenu, Text, "4")
	formatex(Text, charsmax(Text), " \wIce Grenade \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_Smoke]))
	menu_additem(iMenu, Text, "5")
	formatex(Text, charsmax(Text), " \wBunny Hop \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_Bhop]))
	menu_additem(iMenu, Text, "6")
	formatex(Text, charsmax(Text), " \wUltimateClip \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_UltimateClip]))
	menu_additem(iMenu, Text, "7")
	formatex(Text, charsmax(Text), " \wInvisible \r%d sec \y[\r%d $\y]", get_pcvar_num(g_pInvisibleTime), get_pcvar_num(g_pCvarHumanCost[Item_Invisible]))
	menu_additem(iMenu, Text, "8")
	formatex(Text, charsmax(Text), " \wGodmod \r%d sec \y[\r%d $\y]", get_pcvar_num(g_pGodmodTime), get_pcvar_num(g_pCvarHumanCost[Item_Godmod]))
	menu_additem(iMenu, Text, "9")
	formatex(Text, charsmax(Text), " \wM249 Para Machinegun \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_M249]))
	menu_additem(iMenu, Text, "10")
	formatex(Text, charsmax(Text), " \wG3SG1 Auto-Sniper \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_G3SG1]))
	menu_additem(iMenu, Text, "11")
	formatex(Text, charsmax(Text), " \wAK47 Gold \y[\r%d $\y]", get_pcvar_num(g_pCvarHumanCost[Item_AK47_GOLD]))
	menu_additem(iMenu, Text, "12")
	formatex(Text, charsmax(Text), " \wSTAR Gun \y[\r%d $\y] \r[ \yVIP\r ]", get_pcvar_num(g_pCvarHumanCost[Item_STAR]))
	menu_additem(iMenu, Text, "13")
	
	menu_setprop(iMenu, MPROP_BACKNAME, "Previous page")
	menu_setprop(iMenu, MPROP_NEXTNAME, "Next page")
	menu_setprop(iMenu, MPROP_EXITNAME, "\rClose")
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, iMenu)
	return PLUGIN_HANDLED;
			

}


public CustomShopZombie(id)
{ 
	new iMenu, Text[128];
	new iMoney = cs_get_user_money(id)
		
	if (!get_pcvar_num(g_pMenuEnableCvars[1]))
	{
		CC_SendMessage(id, "%L", id, "SHOP_ZOMBIE_OFF")
		return PLUGIN_HANDLED;
	}
	
	formatex(Text, sizeof(Text)-1, "\r-> \yBaseBuilderShop\r: (\yZombies\r)^n\wMoney: \y%i\r$ \y| \wPage:\r ", iMoney)
	iMenu = menu_create(Text, "ZombieShop")
	
			
	formatex(Text, charsmax(Text), " \w+ %i Health \y[\r%d $\y]", get_pcvar_num(g_pCvarQuantityHealthZombieA), get_pcvar_num(g_pCvarZombieCost[Item_HealthA_Z]))
	menu_additem(iMenu, Text, "1")
	formatex(Text, charsmax(Text), " \w+ %i Health \y[\r%d $\y]", get_pcvar_num(g_pCvarQuantityHealthZombieB), get_pcvar_num(g_pCvarZombieCost[Item_HealthB_Z]))
	menu_additem(iMenu, Text, "2")
	formatex(Text, charsmax(Text), " \wFast Speed \y[\r%d $\y]", get_pcvar_num(g_pCvarZombieCost[Item_Speed]))
	menu_additem(iMenu, Text, "3")
	formatex(Text, charsmax(Text), " \wBunny Hop \y[\r%d $\y]", get_pcvar_num(g_pCvarZombieCost[Item_Bhop_Z]))
	menu_additem(iMenu, Text, "4")
	formatex(Text, charsmax(Text), " \wConcussion Bomb \y[\r%d $\y]", get_pcvar_num(g_pCvarZombieCost[Item_Bomb_Conc_Z]))
	menu_additem(iMenu, Text, "5")
	formatex(Text, charsmax(Text), " \wInvisible \r%d sec \y[\r%d $\y]", get_pcvar_num(g_pInvisibleTime), get_pcvar_num(g_pCvarZombieCost[Item_Invisible_Z]))
	menu_additem(iMenu, Text, "6")
	formatex(Text, charsmax(Text), " \wGodmod \r%d sec \y[\r%d $\y]", get_pcvar_num(g_pGodmodTime), get_pcvar_num(g_pCvarZombieCost[Item_Godmod_Z]))
	menu_additem(iMenu, Text, "7")
	
	menu_setprop(iMenu, MPROP_BACKNAME, "Previous page")
	menu_setprop(iMenu, MPROP_NEXTNAME, "Next page")
	menu_setprop(iMenu, MPROP_EXITNAME, "\rClose")
	
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, iMenu)
	return PLUGIN_HANDLED;

			
}

	
	
public BuilderShop(id, iMenu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}

	if ( !is_user_alive(id) )
	{
		CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_DEAD")
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}	
	
	new info[3]
	new access, callback
	menu_item_getinfo(iMenu, item, access, info, 2, _, _, callback)
	
	new key = str_to_num(info)
	new iNewMoney = cs_get_user_money(id) - get_pcvar_num(g_pCvarHumanCost[key])
	
	if ( cs_get_user_money(id) < get_pcvar_num(g_pCvarHumanCost[key]))
	{
		CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_MONEY")
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	else
	{
		switch(key)
		{
			case Item_HealthA:
			{
				if ( g_HasHealthAHuman[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_health(id, get_user_health(id) + get_pcvar_num(g_pCvarQuantityHealthHumanA))
				g_HasHealthBHuman[id] = true;
				CC_SendMessage(id, "%L" ,  LANG_SERVER, "SHOP_HP_A", get_pcvar_num(g_pCvarQuantityHealthHumanA))
			}
			
			case Item_HealthB:
			{
				if ( g_HasHealthBHuman[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_health(id, get_user_health(id) + get_pcvar_num(g_pCvarQuantityHealthHumanB))
				g_HasHealthBHuman[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_HP_B", get_pcvar_num(g_pCvarQuantityHealthHumanB))
			}
			
			case Item_HE:
			{
				if ( user_has_weapon(id, CSW_HEGRENADE ) )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				give_item(id, "weapon_hegrenade")
				cs_set_user_bpammo( id, CSW_HEGRENADE , 1 );
				g_HasHeGrenade[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_HE");
			}
			
			case Item_Flash:
			{
				if ( user_has_weapon(id, CSW_FLASHBANG ) )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				give_item(id, "weapon_flashbang")
				cs_set_user_bpammo( id, CSW_FLASHBANG , 1 );
				g_HasFlashGrenade[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_HE");
			}
			
			case Item_Smoke:
			{
				if ( user_has_weapon(id, CSW_SMOKEGRENADE ) )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				give_item(id, "weapon_smokegrenade")
				cs_set_user_bpammo( id, CSW_SMOKEGRENADE , 1 );
				g_HasSmokeGrenade[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_SMOKE");
			}
			
			case Item_Bhop:
			{
				if ( g_HasBhopHuman[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				
				cs_set_user_money(id, iNewMoney, 1)
				g_HasBhopHuman[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_BHOP");
			}
			
			case Item_UltimateClip:
			{
				if ( g_HasUltimateClip[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				g_HasUltimateClip[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_ULTIMATE_CLIP");
				//set_time(id, get_pcvar_num(g_pInvisibleTime));
				//set_task(get_pcvar_float(g_pInvisibleTime), "remove_invisible", id)
			}
			
			case Item_Invisible:
			{     
				if ( g_HasInvisible[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				fm_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
				set_time(id, get_pcvar_num(g_pInvisibleTime));
				set_task(get_pcvar_float(g_pInvisibleTime), "remove_invisible", id)
				g_HasInvisible[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_INVISIBLE");
			}
			
			case Item_Godmod:
			{     
				if ( g_HasGodmod[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_godmode(id, 1)
				set_time(id, get_pcvar_num(g_pGodmodTime));
				set_task(get_pcvar_float(g_pGodmodTime), "remove_godmod", id)
				g_HasGodmod[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_GODMOD");
			}
			
			case Item_M249:
			{
				if ( user_has_weapon(id, CSW_M249 ) )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				give_item(id, "weapon_m249")
				cs_set_user_bpammo( id, CSW_M249, 999 );
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_M249");
			}
			
			case Item_G3SG1:
			{
				if ( user_has_weapon(id, CSW_G3SG1 ) )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				give_item(id, "weapon_g3sg1")
				cs_set_user_bpammo( id, CSW_G3SG1, 999 )
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_G3SG1");

			}
			
			case Item_AK47_GOLD:
			{
				cs_set_user_money(id, iNewMoney, 1)
				client_cmd(id, "goldenshop_goldenak")
				cs_set_user_bpammo( id, CSW_AK47, 90 )
			}
			
			case Item_STAR:
			{
				if(get_user_flags(id) & FLAGS_VIP)
				{
					cs_set_user_money(id, iNewMoney, 1)
					zp_give_user_sfpistol(id)
				}else CC_SendMessage(id, "&x07You are not allowed to buy")
			}
		}
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

public ZombieShop(id, iMenu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}

	if ( !is_user_alive(id) )
	{
		CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_DEAD")
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}	
	
	new info[3]
	new access, callback
	menu_item_getinfo(iMenu, item, access, info, 2, _, _, callback)
	
	new key = str_to_num(info)
	new iNewMoney = cs_get_user_money(id) - get_pcvar_num(g_pCvarZombieCost[key])
	
	if ( cs_get_user_money(id) < get_pcvar_num(g_pCvarZombieCost[key]))
	{
		CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_MONEY")
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	else
	{
		switch(key)
		{
			case Item_HealthA_Z:
			{
				if ( g_HasHealthAZombie[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_health(id, get_user_health(id) + get_pcvar_num(g_pCvarQuantityHealthZombieA))
				g_HasHealthAZombie[id] = true;
				CC_SendMessage(id, "%L" ,  LANG_SERVER, "SHOP_HP_A", get_pcvar_num(g_pCvarQuantityHealthZombieA))
			}
			
			case Item_HealthB_Z:
			{
				if ( g_HasHealthBZombie[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_health(id, get_user_health(id) + get_pcvar_num(g_pCvarQuantityHealthZombieB))
				g_HasHealthBZombie[id] = true;
				CC_SendMessage(id, "%L" ,  LANG_SERVER, "SHOP_HP_B", get_pcvar_num(g_pCvarQuantityHealthZombieB))
			}
			
			case Item_Speed:
			{
				if ( g_HasSpeed[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				g_HasSpeed[id] = true;
				set_user_maxspeed(id, get_pcvar_float(g_pCvarQuantitySpeed))
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_SPEED");
			}
			
			case Item_Bhop_Z:
			{
				if ( g_HasBhopZombie[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				
				cs_set_user_money(id, iNewMoney, 1)
				g_HasBhopZombie[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_BHOP");
			}
			
			case Item_Bomb_Conc_Z:
			{
				cs_set_user_money(id, iNewMoney, 1)
				client_cmd(id, "zp_bomb_conc_Amir_wolf")
			}
			
			case Item_Invisible_Z:
			{     
				if ( g_HasInvisible[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				fm_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0)
				set_time(id, get_pcvar_num(g_pInvisibleTime));
				set_task(get_pcvar_float(g_pInvisibleTime), "remove_invisible", id)
				g_HasInvisible[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_INVISIBLE");
			}
			
			case Item_Godmod_Z:
			{     
				if ( g_HasGodmod[id] )
				{
					CC_SendMessage(id, "%L" , LANG_SERVER, "FAIL_ITEM_HAS");
					menu_destroy(iMenu)
					return PLUGIN_HANDLED
				}
				cs_set_user_money(id, iNewMoney, 1)
				set_user_godmode(id, 1)
				set_time(id, get_pcvar_num(g_pGodmodTime))
				set_task(get_pcvar_float(g_pGodmodTime), "remove_godmod", id)
				g_HasGodmod[id] = true;
				CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_GODMOD");
			}
		}
	}
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

/*================================================================================
 [Stocks]
=================================================================================*/

public Player_Spawn_Post(id)
{	
	g_HasSpeed[id] = false;
}

public Player_ResetMaxSpeed( id )
{
	if ( is_user_alive ( id ) )
	{
		if ( get_user_maxspeed(id) != -1.0 )
		{
			if ( g_HasSpeed[id] )
			{
				set_user_maxspeed(id, 250.0)
			}
		}
	}
}


public Event_CurWeapon(id) 
{
	new iWeapon = read_data(2)
	
	if(g_HasSpeed[id] && get_user_maxspeed(id) < get_pcvar_float(g_pCvarQuantitySpeed)) {
		
		set_user_maxspeed(id, get_pcvar_float(g_pCvarQuantitySpeed));
	}

	if (g_HasUltimateClip[id] && !( NOCLIP_WPN_BS & (1<<iWeapon) ))
	{
		fm_cs_set_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , g_MaxClipAmmo[ iWeapon ] )
	}
	
}

public client_connect( id )
{
	client_cmd(id, "cl_forwardspeed 999;cl_sidespeed 999;cl_backspeed 999")
	g_HasSpeed[id] = false;
	g_HasInvisible[id] = false;
	g_HasGodmod[id] = false;
	g_HasUltimateClip[id] = false;
}

public client_disconnect(id) {
	g_HasInvisible[id] = false
	g_HasGodmod[id] = false;
	g_HasUltimateClip[id] = false;
}

public Death()
{
	g_HasInvisible[read_data(2)] = false
	g_HasGodmod[read_data(2)] = false;
	g_HasUltimateClip[read_data(2)] = false;
}

public client_PreThink(id) {
	
	if (is_user_alive(id) && g_HasBhopZombie[id] || is_user_alive(id) && g_HasBhopHuman[id]) {
		
		entity_set_float(id, EV_FL_fuser2, 0.0)		// Won't slow down after a jump
		
		if (entity_get_int(id, EV_INT_button) & 2) {	
			new flags = entity_get_int(id, EV_INT_flags)
			
			if (flags & FL_WATERJUMP)
				return PLUGIN_CONTINUE
			if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
				return PLUGIN_CONTINUE
			if ( !(flags & FL_ONGROUND) )
				return PLUGIN_CONTINUE
			
			new Float:velocity[3]
			entity_get_vector(id, EV_VEC_velocity, velocity)
			velocity[2] += 250.0
			entity_set_vector(id, EV_VEC_velocity, velocity)
			
			entity_set_int(id, EV_INT_gaitsequence, 6)	// Jump graphics
		}
	}
	return PLUGIN_CONTINUE
	
}

public remove_invisible(id)
{
	fm_set_user_rendering(id)
	CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_INVISIBLE_END");

}
public remove_godmod(id)
{
	fm_set_user_godmode(id)
	CC_SendMessage(id, "%L" , LANG_SERVER, "SHOP_GODMOD_END");

}


/*================================================================================
 [Message]
=================================================================================*/
public Message()
{
	if (get_pcvar_num(g_pCvarEnable))
	{
		if (get_pcvar_num(g_pCvarMessage))
		{
			CC_SendMessage(0, "%L", LANG_SERVER, "SHOP_MESSAGE")
		}
	}
}

stock set_time(id, time) {
	message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id);
	write_short(time);
	message_end();
}

/*================================================================================
 [Plugin Ended]
=================================================================================*/
