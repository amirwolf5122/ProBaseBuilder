/**
 * ------------------------------------------------------------------
 * 					Base Builder: Zombie Mod
 * ------------------------------------------------------------------
 *
 *	@developer		AmirWolf
 *
 *	@description	A comprehensive zombie plugin for the Base Builder
 *					game mode, adding new gameplay mechanics and features.
 *
 *	@contact		Telegram: T.me/Mr_Admins
 *
 * ------------------------------------------------------------------
 */

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <csx>
#include <msgstocks>
#include <cromchat>
#include <xs>

#if AMXX_VERSION_NUM < 183
	#include <dhudmessage>
#endif

#define VERSION "4.1"
#define MODNAME "^3[^4BB^3]^1"

// --- General Constants ---
#define MAXPLAYERS 32
#define MAXENTS 1024
#define MODELCHANGE_DELAY 0.5
#define AUTO_TEAM_JOIN_DELAY 0.1
#define TEAM_SELECT_VGUI_MENU_ID 2
#define OBJECT_PUSHPULLRATE 4.0
#define BARRIER_RENDERAMT 120.0
#define BLOCK_RENDERAMT 150.0
#define BUILD_DELAY 0.75
#define LOCKED_COLOR 125.0, 0.0, 0.0
#define LOCKED_RENDERAMT 140.0

const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE);

// --- Admin Flags ---
#define FLAGS_BUILD 	ADMIN_KICK
#define FLAGS_BUILDBAN  ADMIN_KICK
#define FLAGS_SWAP		ADMIN_KICK
#define FLAGS_REVIVE	ADMIN_KICK
#define FLAGS_RELEASE	ADMIN_BAN
#define FLAGS_OVERRIDE	ADMIN_KICK
#define FLAGS_GUNS		ADMIN_LEVEL_A
#define FLAGS_FULLADMIN	ADMIN_LEVEL_G
#define FLAGS_VIP		ADMIN_RESERVATION
#define FLAGS_INFOR		ADMIN_KICK
#define FLAGS_LOCKAFTER ADMIN_KICK
#define FLAGS_LOCK		ADMIN_ALL

// --- Function-like Macros ---
#define LockBlock(%1,%2)	(entity_set_int(%1, EV_INT_iuser1, %2))
#define UnlockBlock(%1)		(entity_set_int(%1, EV_INT_iuser1, 0))
#define BlockLocker(%1)		(entity_get_int(%1, EV_INT_iuser1))

#define MovingEnt(%1)		(entity_set_int(%1, EV_INT_iuser2, 1))
#define UnmovingEnt(%1)		(entity_set_int(%1, EV_INT_iuser2, 0))
#define IsMovingEnt(%1)		(entity_get_int(%1, EV_INT_iuser2) == 1)

#define SetEntMover(%1,%2)	(entity_set_int( %1, EV_INT_iuser3, %2))
#define UnsetEntMover(%1)	(entity_set_int( %1, EV_INT_iuser3, 0))
#define GetEntMover(%1)		(entity_get_int(%1, EV_INT_iuser3))

#define SetLastMover(%1,%2)	(entity_set_int(%1, EV_INT_iuser4, %2))
#define UnsetLastMover(%1)	(entity_set_int(%1, EV_INT_iuser4, 0))
#define GetLastMover(%1)	(entity_get_int(%1, EV_INT_iuser4))

// --- Memory Offsets ---
#define AMMO_SLOT 376
#define OFFSET_WPN_WIN 41
#define OFFSET_WPN_LINUX  4
#define OFFSET_ACTIVE_ITEM 373
#define OFFSET_LINUX 5

#if cellbits == 32
	#define OFFSET_BUYZONE 235
#else
	#define OFFSET_BUYZONE 268
#endif

enum (+= 5000)
{
	TASK_BUILD = 10000,
	TASK_PREPTIME,
	TASK_MODELSET,
	TASK_RESPAWN,
	TASK_HEALTH,
	TASK_IDLESOUND
};

// --- Core Globals & Player State ---
new g_msgStatusText, g_HudSync,
	g_isConnected[MAXPLAYERS+1], g_isAlive[MAXPLAYERS+1], g_isZombie[MAXPLAYERS+1],
	g_isBuildBan[MAXPLAYERS+1], g_isCustomModel[MAXPLAYERS+1];

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

// --- Forwards ---
new g_fwRoundStart, g_fwPrepStarted, g_fwBuildStarted, g_fwClassPicked, g_fwClassSet,
	g_fwPushPull, g_fwGrabEnt_Pre, g_fwGrabEnt_Post, g_fwDropEnt_Pre,
	g_fwDropEnt_Post, g_fwNewColor, g_fwLockEnt_Pre, g_fwLockEnt_Post, g_fwDummyResult;

// --- CVars ---
new g_pcvar_enabled, g_iBuildTime, g_iPrepTime, g_iGrenadeHE, g_iGrenadeFLASH,
	g_iGrenadeSMOKE, Float:g_fEntSetDist, Float:g_fEntMaxDist, g_iShowMovers,
	g_iLockBlocks, g_iLockMax, g_iColorMode, g_iZombieTime, g_iInfectTime,
	g_iSupercut, g_iGunsMenu, g_pcvar_givenades[32], g_pcvar_allowedweps[32],
	knife_model_human[75];

// --- Gameplay & Building System ---
new Float:g_fModelsTargetTime, Float:g_fRoundStartTime, Float:g_fOffset[MAXPLAYERS+1][3], Float:g_fEntDist[MAXPLAYERS+1],
	Float:g_fBuildDelay[MAXPLAYERS+1], Float:g_fRotateDelay[MAXPLAYERS+1],
	g_szPlayerModel[MAXPLAYERS+1][32], g_szModName[32],
	g_iCountDown, g_iEntBarrier, g_iOwnedEnt[MAXPLAYERS+1], g_iOwnedEntities[MAXPLAYERS+1],
	g_iWeaponPicked[2][MAXPLAYERS+1], g_iPrimaryWeapon[MAXPLAYERS+1],
	bool:g_boolCanBuild, bool:g_boolPrepTime, bool:g_boolRoundEnded, bool:g_boolRepick[MAXPLAYERS+1],
	CsTeams:g_iTeam[MAXPLAYERS+1];

// Zombie Class System
new g_iZClasses, g_iZombieClass[MAXPLAYERS+1], g_iNextClass[MAXPLAYERS+1],
	g_szPlayerClass[MAXPLAYERS+1][32], Float:g_fPlayerSpeed[MAXPLAYERS+1],
	bool:g_boolFirstSpawn[MAXPLAYERS+1], bool:g_boolArraysCreated;

new Array:g_zclass_name, Array:g_zclass_info, Array:g_zclass_modelsstart, Array:g_zclass_modelsend,
	Array:g_zclass_playermodel, Array:g_zclass_modelindex, Array:g_zclass_clawmodel, Array:g_zclass_hp,
	Array:g_zclass_spd, Array:g_zclass_grav, Array:g_zclass_admin, Array:g_zclass_credits, Array:g_zclass_new;

new Array:g_zclass2_realname, Array:g_zclass2_name, Array:g_zclass2_info, Array:g_zclass2_modelsstart,
	Array:g_zclass2_modelsend, Array:g_zclass2_playermodel, Array:g_zclass2_clawmodel, Array:g_zclass2_hp,
	Array:g_zclass2_spd, Array:g_zclass2_grav, Array:g_zclass2_admin, Array:g_zclass2_credits;

// --- Weapon Definitions ---
static const g_szWpnEntNames[][] =
{
	"", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
	"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
	"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
	"weapon_ak47", "weapon_knife", "weapon_p90"
};

// Weapon Names (For Guns Menu)
static const szWeaponNames[24][23] =
{
	"Schmidt Scout", "XM1014 M4", "Ingram MAC-10", "Steyr AUG A1", "UMP 45", "SG-550 Auto-Sniper",
	"IMI Galil", "Famas", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun", "M3 Super 90", "M4A1 Carbine",
	"Schmidt TMP", "G3SG1 Auto-Sniper", "SG-552 Commando", "AK-47 Kalashnikov", "ES P90", "P228 Compact",
	"Dual Elite Berettas", "Fiveseven", "USP .45 ACP Tactical", "Glock 18C", "Desert Eagle .50 AE"
};

// Weapon CSW
static const g_weaponCSW[24] = 
{
    CSW_SCOUT,
	CSW_XM1014,
	CSW_MAC10,
	CSW_AUG,
	CSW_UMP45,
	CSW_SG550,
	CSW_GALIL,
	CSW_FAMAS,
	CSW_AWP,
	CSW_MP5NAVY,
	CSW_M249,
	CSW_M3,
	CSW_M4A1,
	CSW_TMP,
	CSW_G3SG1,
	CSW_SG552,
	CSW_AK47,
	CSW_P90,
	CSW_P228,
	CSW_ELITE,
	CSW_FIVESEVEN,
	CSW_USP,
	CSW_GLOCK18,
	CSW_DEAGLE
};

// --- Color System Definitions ---
enum _:ColorData
{
	Name[24],
	Float:Red,
	Float:Green,
	Float:Blue,
	Float:RenderAmount,
	AdminFlag
}

#define MAX_COLORS 25
new const g_aColors[MAX_COLORS][ColorData] =
{
	// Name,			Red, Green, Blue, RenderAmount, AdminFlag
	{"Red",				200.0, 000.0, 000.0, 100.0,		ADMIN_ALL},
	{"Red Orange",		255.0, 083.0, 073.0, 135.0,		ADMIN_ALL},
	{"Orange",			255.0, 117.0, 056.0, 140.0,		ADMIN_ALL},
	{"Yellow Orange",	255.0, 174.0, 066.0, 120.0,		ADMIN_ALL},
	{"Peach",			255.0, 207.0, 171.0, 140.0,		ADMIN_ALL},
	{"Yellow",			252.0, 232.0, 131.0, 125.0,		ADMIN_ALL},
	{"Lemon Yellow",	254.0, 254.0, 034.0, 100.0,		ADMIN_ALL},
	{"Jungle Green",	059.0, 176.0, 143.0, 125.0,		ADMIN_ALL},
	{"Yellow Green",	197.0, 227.0, 132.0, 135.0,		ADMIN_ALL},
	{"Green",			000.0, 150.0, 000.0, 100.0,		ADMIN_ALL},
	{"Aquamarine",		120.0, 219.0, 226.0, 125.0,		ADMIN_ALL},
	{"Baby Blue",		135.0, 206.0, 235.0, 150.0,		ADMIN_ALL},
	{"Sky Blue",		128.0, 218.0, 235.0, 090.0,		ADMIN_ALL},
	{"Blue",			000.0, 000.0, 255.0, 075.0,		ADMIN_ALL},
	{"Violet",			146.0, 110.0, 174.0, 175.0,		ADMIN_ALL},
	{"Hot Pink",		255.0, 105.0, 180.0, 150.0,		ADMIN_ALL},
	{"Magenta",			246.0, 100.0, 175.0, 175.0,		ADMIN_ALL},
	{"Mahogany",		205.0, 074.0, 076.0, 140.0,		ADMIN_ALL},
	{"Tan",				250.0, 167.0, 108.0, 140.0,		ADMIN_ALL},
	{"Light Brown",		234.0, 126.0, 093.0, 140.0,		ADMIN_ALL},
	{"Brown", 			180.0, 103.0, 077.0, 165.0,		ADMIN_ALL},
	{"Gray",			149.0, 145.0, 140.0, 175.0,		ADMIN_ALL},
	{"Black",			000.0, 000.0, 000.0, 125.0,		ADMIN_ALL},
	{"White",			255.0, 255.0, 255.0, 125.0,		ADMIN_ALL},
	{"Random",			000.0, 000.0, 000.0, 150.0,		FLAGS_VIP}
};

enum // Color Indices (Matches g_aColors array)
{
	COLOR_RED = 0, 		//200, 000, 000
	COLOR_REDORANGE, 	//255, 083, 073
	COLOR_ORANGE, 		//255, 117, 056
	COLOR_YELLOWORANGE,	//255, 174, 066
	COLOR_PEACH, 		//255, 207, 171
	COLOR_YELLOW, 		//252, 232, 131
	COLOR_LEMONYELLOW, 	//254, 254, 034
	COLOR_JUNGLEGREEN, 	//059, 176, 143
	COLOR_YELLOWGREEN, 	//197, 227, 132
	COLOR_GREEN, 		//000, 200, 000
	COLOR_AQUAMARINE, 	//120, 219, 226
	COLOR_BABYBLUE,		//135, 206, 235
	COLOR_SKYBLUE, 		//128, 218, 235
	COLOR_BLUE, 		//000, 000, 200
	COLOR_VIOLET, 		//146, 110, 174
	COLOR_PINK, 		//255, 105, 180
	COLOR_MAGENTA, 		//246, 100, 175
	COLOR_MAHOGANY,		//205, 074, 076
	COLOR_TAN,			//250, 167, 108
	COLOR_LIGHTBROWN, 	//234, 126, 093
	COLOR_BROWN, 		//180, 103, 077
	COLOR_GRAY, 		//149, 145, 140
	COLOR_BLACK, 		//000, 000, 000
	COLOR_WHITE ,		//255, 255, 255
	COLOR_RANDOM, 		//000, 000, 000
};

new g_iColor[MAXPLAYERS+1], g_iColorOwner[MAX_COLORS];

new const g_szRoundStart[][] = 
{
	"basebuilder/round_start.wav",
	"basebuilder/round_start2.wav"
};

new const WIN_HUMANS[][] =
{
    "basebuilder/human/win/win1.wav",
	"basebuilder/human/win/win2.wav",
	"basebuilder/human/win/win3.wav",
	"basebuilder/human/win/win4.wav",
	"basebuilder/human/win/win5.wav"
};

new const g_szHumanPain[][] =
{
	"basebuilder/human/pain/pain1.wav",
	"basebuilder/human/pain/Pain2.wav",
	"basebuilder/human/pain/Pain3.wav",
	"basebuilder/human/pain/Pain4.wav",
	"basebuilder/human/pain/Pain5.wav",
	"basebuilder/human/pain/Pain6.wav"
};

new const g_szHumanDead[][] =
{
	"basebuilder/human/death/death1.wav",
	"basebuilder/human/death/death2.wav",
	"basebuilder/human/death/death3.wav",
	"basebuilder/human/death/death4.wav",
	"basebuilder/human/death/death5.wav"
};

new const WIN_ZOMBIES[][] =
{
	"basebuilder/zombie/win/win1.wav",
	"basebuilder/zombie/win/win2.wav",
	"basebuilder/zombie/win/win3.wav",
	"basebuilder/zombie/win/win4.wav",
	"basebuilder/zombie/win/win5.wav"
	
};

new const g_szZombiePain[][] =
{
	"basebuilder/zombie/pain/pain1.wav",
	"basebuilder/zombie/pain/pain2.wav",
	"basebuilder/zombie/pain/pain3.wav"
};

new const g_szZombieDie[][] =
{
	"basebuilder/zombie/death/death1.wav",
	"basebuilder/zombie/death/death2.wav",
	"basebuilder/zombie/death/death3.wav"
};

new const g_szZombieIdle[][] =
{
	"basebuilder/zombie/idle/idle1.wav",
	"basebuilder/zombie/idle/idle2.wav",
	"basebuilder/zombie/idle/idle3.wav"
};

new const g_szZombieHit[][] =
{
	"basebuilder/zombie/hit/hit1.wav",
	"basebuilder/zombie/hit/hit2.wav",
	"basebuilder/zombie/hit/hit3.wav"
};

new const g_szZombieMiss[][] =
{
	"basebuilder/zombie/miss/miss1.wav",
	"basebuilder/zombie/miss/miss2.wav",
	"basebuilder/zombie/miss/miss3.wav"
};

// --- Includes ---
#include "Pro_Basebuilder/vars.inl"
#include "Pro_Basebuilder/team.inl"
#include "Pro_Basebuilder/cloneAllBlock.inl"
#include "Pro_Basebuilder/stocks.inl"
#include "Pro_Basebuilder/clone_rotate.inl"
#include "Pro_Basebuilder/bb_menu.inl"

public plugin_init()
{
	if (!g_pcvar_enabled)
		return;

	formatex(g_szModName, charsmax(g_szModName), "Base Builder %s", VERSION);

	register_clcmd("say", "cmdSay");
	register_clcmd("say_team", "cmdSay");
	register_clcmd("+grab",	"cmdGrabEnt");
	register_clcmd("-grab",	"cmdStopEnt");
	register_clcmd("+bb_copy",	"CloneBlock");
	register_clcmd("bb_rotate",	"RotateBlock");
	register_clcmd("bb_lock",	"cmdLockBlock", 0, " - Aim at a block to lock it");
	register_clcmd("bb_claim",	"cmdLockBlock", 0, " - Aim at a block to lock it");
	register_clcmd("bb_startround",	"cmdStartRound", 0, " - Starts the round");
	register_clcmd("drop", "clcmd_drop");
	register_clcmd("radio3", "clcmd1_buy");
	register_clcmd("radio2", "clcmd2_buy");
	register_clcmd("chooseteam", "clcmd_changeteam");
	register_clcmd("jointeam", "clcmd_changeteam");

	new const blockCommandAll[][] = { "buy", "go", "buyammo1", "buyammo2", "radio", "radio1", "votekick", "votemap", "vote" , "kick"};
	for(new i = 0; i < sizeof(blockCommandAll); i++)
	{
		register_clcmd(blockCommandAll[i], "blockCommand");
	}
	
	register_concmd("bb_buildban",	"cmdBuildBan", 0, " <player>");
	register_concmd("bb_unbuildban", "cmdBuildBan", 0, " <player>");
	register_concmd("bb_bban", "cmdBuildBan", 0, " <player>");
	register_concmd("bb_swap", "cmdSwap", 0, " <player>");
	register_concmd("bb_revive", "cmdRevive", 0, " <player>");
	register_concmd("bb_teleport", "cmdTeleport", 0, " <player>");
	
	if (g_iGunsMenu)
	{
		register_concmd("bb_guns",	"cmdGuns", 0, " <player>");
	}
	
	register_logevent("logevent_round_start", 2, "1=Round_Start");
	register_logevent("logevent_round_end", 2, "1=Round_End");

	register_event("HLTV", "ev_RoundStart", "a", "1=0", "2=0");
	register_event("AmmoX", "ev_AmmoX", "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10");

	register_message(get_user_msgid("TextMsg"), "msgRoundEnd");
	register_message(get_user_msgid("SayText"), "messageSayText");
	register_message(get_user_msgid("SendAudio"), "msgSendAudio");
	register_message(get_user_msgid("StatusIcon"), "msgStatusIcon");
	register_message(get_user_msgid("Health"), "msgHealth");
	register_message(get_user_msgid("StatusValue"), "msgStatusValue");
	register_message(get_user_msgid("ShowMenu"), "message_show_menu");
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu");
	
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET);

	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "playerResetMaxSpeed", 1);
	RegisterHam(Ham_Touch, "weapon_shield", "ham_WeaponCleaner_Post", 1);
	RegisterHam(Ham_Touch, "weaponbox", "ham_WeaponCleaner_Post", 1);
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled_Post", 1);
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage");
	
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)
	{
		if (g_szWpnEntNames[i][0])
			RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "ham_ItemDeploy_Post", 1);
	}

	register_forward(FM_GetGameDescription, "fw_GetGameDescription");
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue");
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged");
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_EmitSound, "fw_EmitSound");
	register_forward(FM_ClientKill, "fw_Suicide");
	
	if (g_iShowMovers)
	{
		register_forward(FM_TraceLine, "fw_Traceline", true);
	}

	g_fwRoundStart = CreateMultiForward("bb_round_started", ET_IGNORE);
	g_fwPrepStarted = CreateMultiForward("bb_prepphase_started", ET_IGNORE);
	g_fwBuildStarted = CreateMultiForward("bb_buildphase_started", ET_IGNORE);
	g_fwClassPicked = CreateMultiForward("bb_zombie_class_picked", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwClassSet = CreateMultiForward("bb_zombie_class_set", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwPushPull = CreateMultiForward("bb_block_pushpull", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_fwGrabEnt_Pre = CreateMultiForward("bb_grab_pre", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwGrabEnt_Post = CreateMultiForward("bb_grab_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwDropEnt_Pre = CreateMultiForward("bb_drop_pre", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwDropEnt_Post = CreateMultiForward("bb_drop_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwNewColor = CreateMultiForward("bb_new_color", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwLockEnt_Pre = CreateMultiForward("bb_lock_pre", ET_IGNORE, FP_CELL, FP_CELL);
	g_fwLockEnt_Post = CreateMultiForward("bb_lock_post", ET_IGNORE, FP_CELL, FP_CELL);

	clonePrepare();
	register_dictionary("basebuilder.txt");
	
	g_HudSync = CreateHudSyncObj();
	g_msgStatusText = get_user_msgid("StatusText");
	g_iEntBarrier = find_ent_by_tname(-1, "barrier");
	
	server_cmd("mp_freezetime 0");
	server_cmd("sv_maxspeed 999");
	server_cmd("mp_autoteambalance 1");	
}

public plugin_precache()
{
	register_plugin("Base Builder", VERSION, "Tirant");
	register_cvar("base_builder", VERSION, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("base_builder", VERSION);
	
	server_cmd("bb_credits_active 0");
	ReadFile();
	
	if (!g_pcvar_enabled)
		return;
	
	new i;
	for (i = 0; i < strlen(g_pcvar_givenades); i++)
	{
		switch(g_pcvar_givenades[i])
		{
			case 'h': g_iGrenadeHE++;
			case 'f': g_iGrenadeFLASH++;
			case 's': g_iGrenadeSMOKE++;
		}
	}
	
	for (i = 0; i < sizeof g_szRoundStart; i++) 	precache_sound(g_szRoundStart[i]);
	for (i = 0; i < sizeof WIN_HUMANS; i++) 	 	precache_sound(WIN_HUMANS[i]);
	for (i = 0; i < sizeof g_szHumanPain; i++) 		precache_sound(g_szHumanPain[i]);
	for (i = 0; i < sizeof g_szHumanDead; i++) 		precache_sound(g_szHumanDead[i]);
	
	for (i = 0; i < sizeof WIN_ZOMBIES; i++) 	 	precache_sound(WIN_ZOMBIES[i]);
	for (i = 0; i < sizeof g_szZombiePain; i++) 	precache_sound(g_szZombiePain[i]);
	for (i = 0; i < sizeof g_szZombieDie; i++)		precache_sound(g_szZombieDie[i]);
	for (i = 0; i < sizeof g_szZombieIdle; i++) 	precache_sound(g_szZombieIdle[i]);
	for (i = 0; i < sizeof g_szZombieHit; i++)		precache_sound(g_szZombieHit[i]);
	for (i = 0; i < sizeof g_szZombieMiss; i++) 	precache_sound(g_szZombieMiss[i]);
	
	for (i = 0; i < E_Sounds; i++)					precache_sound(g_szSoundPaths[i]);
	for (i = 0; i < E_Sprites; i++)					g_iSpriteIDs[i] = precache_model(g_szSpritePaths[i]);
	
	precache_model("models/rpgrocket.mdl");
	precache_model(knife_model_human);
	
	i = create_entity("info_bomb_target");
	entity_set_origin(i, Float:{8192.0, 8192.0, 8192.0});
	
	i = create_entity("info_map_parameters");
	DispatchKeyValue(i, "buying", "3");
	DispatchKeyValue(i, "bombradius", "1");
	DispatchSpawn(i);
	
	g_zclass_name = ArrayCreate(32, 1);
	g_zclass_info = ArrayCreate(32, 1);
	g_zclass_modelsstart = ArrayCreate(1, 1);
	g_zclass_modelsend = ArrayCreate(1, 1);
	g_zclass_playermodel = ArrayCreate(32, 1);
	g_zclass_modelindex = ArrayCreate(1, 1);
	g_zclass_clawmodel = ArrayCreate(32, 1);
	g_zclass_hp = ArrayCreate(1, 1);
	g_zclass_spd = ArrayCreate(1, 1);
	g_zclass_grav = ArrayCreate(1, 1);
	g_zclass_admin = ArrayCreate(1, 1);
	g_zclass_credits = ArrayCreate(1, 1);
	g_zclass_new = ArrayCreate(1, 1);
	
	g_zclass2_realname = ArrayCreate(32, 1);
	g_zclass2_name = ArrayCreate(32, 1);
	g_zclass2_info = ArrayCreate(32, 1);
	g_zclass2_modelsstart = ArrayCreate(1, 1);
	g_zclass2_modelsend = ArrayCreate(1, 1);
	g_zclass2_playermodel = ArrayCreate(32, 1);
	g_zclass2_clawmodel = ArrayCreate(32, 1);
	g_zclass2_hp = ArrayCreate(1, 1);
	g_zclass2_spd = ArrayCreate(1, 1);
	g_zclass2_grav = ArrayCreate(1, 1);
	g_zclass2_admin = ArrayCreate(1, 1);
	g_zclass2_credits = ArrayCreate(1, 1);
	
	g_boolArraysCreated = true;
	
	return;
}

ReadFile()
{
	new szFilename[256];
	get_configsdir(szFilename, charsmax(szFilename));
	add(szFilename, charsmax(szFilename), "/Pro_basebuilder.ini");
	
	new iFilePointer = fopen(szFilename, "rt");
	if (!iFilePointer)
	{
		return;
	}
	
	new szData[256 + MAX_NAME_LENGTH], szValue[256], szKey[MAX_NAME_LENGTH];
	
	while (!feof(iFilePointer))
	{
		fgets(iFilePointer, szData, charsmax(szData));
		trim(szData);
		
		if (szData[0] == EOS || szData[0] == '#' || szData[0] == ';')
		{
			continue;
		}
		
		strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
		trim(szKey);
		trim(szValue);
		
		if (equal(szKey, "MOD_ENABLED")) g_pcvar_enabled = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_BUILDTIME")) g_iBuildTime = clamp(str_to_num(szValue), 5, 300);
		else if (equal(szKey, "BB_PREPTIME")) g_iPrepTime = clamp(str_to_num(szValue), 5, 100);
		else if (equal(szKey, "BB_ZOMBIE_RESPAWN")) g_iZombieTime = clamp(str_to_num(szValue), 1, 30);
		else if (equal(szKey, "BB_SURVIVOR_RESPAWN_INFECTION")) g_iInfectTime = clamp(str_to_num(szValue), 0, 30);
		else if (equal(szKey, "BB_SHOW_MOVERS")) g_iShowMovers = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_LOCK_BLOCKS")) g_iLockBlocks = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_LOCKMAX")) g_iLockMax = clamp(str_to_num(szValue), 5, 40);
		else if (equal(szKey, "BB_MAX_USER_CLONES")) g_maxUserClones = clamp(str_to_num(szValue), 5, 40);
		else if (equal(szKey, "BB_COLOR_MODE")) g_iColorMode = clamp(str_to_num(szValue), 0, 2);
		else if (equal(szKey, "BB_MAX_MOVE_DIST")) g_fEntMaxDist = floatclamp(str_to_float(szValue), 10.0, 900.0);
		else if (equal(szKey, "BB_MIN_MOVE_SET")) g_fEntSetDist = floatclamp(str_to_float(szValue), 10.0, 100.0);
		else if (equal(szKey, "BB_ZOMBIE_SUPERCUT")) g_iSupercut = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_MOVE_LOCKED_BLOCKS")) g_bMoveLockBlocks = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_GUNSMENU")) g_iGunsMenu = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_ROUNDNADES")) copy(g_pcvar_givenades, charsmax(g_pcvar_givenades), szValue);
		else if (equal(szKey, "BB_WEAPONS")) copy(g_pcvar_allowedweps, charsmax(g_pcvar_allowedweps), szValue);
		else if (equal(szKey, "BB_KNIFE_HUMAN")) copy(knife_model_human, charsmax(knife_model_human), szValue);
		else if (equal(szKey, "DOOR_RANDOM_COLOR_ENABLED")) g_bColorDoorActive = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_BLOCK_COLLISION")) g_bCheckForBlocker = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "BB_GRAB_PLAYERS")) g_bCanGrabPlayers = clamp(str_to_num(szValue), 0, 1);
		else if (equal(szKey, "DOOR_COLOR_CHANGE_INTERVAL")) g_fColorDoorTime = floatclamp(str_to_float(szValue), 1.0, 300.0);
		
		else if (equal(szKey, "DHUD_BUILD_TIME_COLOR")) ReadColorSetting(szValue, g_eSettings[DHUD_BUILD_TIME_COLOR]);
		else if (equal(szKey, "DHUD_PREP_TIME_COLOR")) ReadColorSetting(szValue, g_eSettings[DHUD_PREP_TIME_COLOR]);
		else if (equal(szKey, "HUDINFO_HUMAN_COLOR")) ReadColorSetting(szValue, g_eSettings[HUDINFO_HUMAN_COLOR]);
		else if (equal(szKey, "HUDINFO_ZOMBIE_COLOR")) ReadColorSetting(szValue, g_eSettings[HUDINFO_ZOMBIE_COLOR]);
		else if (equal(szKey, "BARRIER_PRIMARY_COLOR")) ReadFloatColorSetting(szValue, g_eSettings[BARRIER_PRIMARY_COLOR]);
		else if (equal(szKey, "BARRIER_SECONDARY_COLOR")) ReadFloatColorSetting(szValue, g_eSettings[BARRIER_SECONDARY_COLOR]);
		else if (equal(szKey, "DHUD_BUILD_TIME_POSITION")) ReadPositionSetting(szValue, g_eSettings[DHUD_BUILD_TIME_POSITION]);
		else if (equal(szKey, "DHUD_PREP_TIME_POSITION")) ReadPositionSetting(szValue, g_eSettings[DHUD_PREP_TIME_POSITION]);
		else if (equal(szKey, "HUDINFO_POSITION")) ReadPositionSetting(szValue, g_eSettings[HUDINFO_POSITION]);
	}
	fclose(iFilePointer);
}

public plugin_cfg()
{
	g_boolArraysCreated = false;
	cloneBlockFolder();
}

public plugin_natives()
{
	register_native("bb_register_zombie_class","native_register_zombie_class", 1);
	register_native("bb_get_class_cost","native_get_class_cost", 1);
	register_native("bb_get_user_zombie_class","native_get_user_zombie_class", 1);
	register_native("bb_get_user_next_class","native_get_user_next_class", 1);
	register_native("bb_set_user_zombie_class","native_set_user_zombie_class", 1);
	
	register_native("bb_is_user_zombie","native_is_user_zombie", 1);
	register_native("bb_is_user_banned","native_is_user_banned", 1);
	
	register_native("bb_is_build_phase","native_bool_buildphase", 1);
	register_native("bb_is_prep_phase","native_bool_prepphase", 1);
	
	register_native("bb_get_build_time","native_get_build_time", 1);
	register_native("bb_set_build_time","native_set_build_time", 1);
	
	register_native("bb_get_user_color","native_get_user_color", 1);
	register_native("bb_set_user_color","native_set_user_color", 1);
	
	register_native("bb_drop_user_block","native_drop_user_block", 1);
	register_native("bb_get_user_block","native_get_user_block", 1);
	register_native("bb_set_user_block","native_set_user_block", 1);
	
	register_native("bb_is_locked_block","native_is_locked_block", 1);
	register_native("bb_lock_block","native_lock_block", 1);
	register_native("bb_unlock_block","native_unlock_block", 1);
	register_native("bb_get_flags_lockafter","native_get_flags_lockafter", 1);
	register_native("notify_block_in_zone", "native_block_in_zone");
	
	register_native("bb_release_zombies","native_release_zombies", 1);
	
	register_native("bb_set_user_primary","native_set_user_primary", 1);
	register_native("bb_get_user_primary","native_get_user_primary", 1);
	
	register_native("bb_get_flags_build","native_get_flags_build", 1);
	register_native("bb_get_flags_lock","native_get_flags_lock", 1);
	register_native("bb_get_flags_buildban","native_get_flags_buildban", 1);
	register_native("bb_get_flags_swap","native_get_flags_swap", 1);
	register_native("bb_get_flags_revive","native_get_flags_revive", 1);
	register_native("bb_get_flags_guns","native_get_flags_guns", 1);
	register_native("bb_get_flags_release","native_get_flags_release", 1);
	register_native("bb_get_flags_override","native_get_flags_override", 1);
	
	register_native("zp_register_zombie_class","native_register_zombie_class", 1);
	register_native("zp_get_user_zombie_class","native_get_user_zombie_class", 1);
	register_native("zp_get_user_next_class","native_get_user_next_class", 1);
	register_native("zp_set_user_zombie_class","native_set_user_zombie_class", 1);
	register_native("zp_get_user_zombie","native_is_user_zombie", 1);
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_szModName);
	return FMRES_SUPERCEDE;
}

public client_connect(id)
{
	addToReconnect(id, 0);
	g_bUserReconnected[id] = false;
}

public client_putinserver(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	g_isConnected[id] = true;
	g_isAlive[id] = false;
	g_isZombie[id] = false;
	g_isBuildBan[id] = false;
	g_isCustomModel[id] = false;
	g_boolFirstSpawn[id] = true;
	g_boolRepick[id] = true;
	
	g_iZombieClass[id] = 0;
	g_iNextClass[id] = g_iZombieClass[id];
	
	ResetPlayerData(id)
	
	set_task(5.0, "Respawn_Player", id + TASK_RESPAWN);
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	addToReconnect(id, 1);
	
	if (g_iOwnedEnt[id])
		cmdStopEnt(id);
	
	remove_task(id + TASK_RESPAWN);
	remove_task(id + TASK_HEALTH);
	remove_task(id + TASK_IDLESOUND);
	
	g_isConnected[id] = false;
	g_isAlive[id] = false;
	g_isZombie[id] = false;
	g_isBuildBan[id] = false;
	g_isCustomModel[id] = false;
	g_boolFirstSpawn[id] = false;
	g_boolRepick[id] = false;
	
	g_iZombieClass[id] = 0;
	g_iNextClass[id] = 0;
	g_iOwnedEntities[id] = 0;
	
	ResetPlayerData(id)
	leaveParty(id)
	
	for (new iEnt = MAXPLAYERS + 1; iEnt < MAXENTS; iEnt++)
	{
		if (is_valid_ent(iEnt) && BlockLocker(iEnt) == id)
		{
			new cloneEnt = g_iClonedEnts[iEnt];
			if (is_valid_ent(cloneEnt))
			{
				remove_entity(cloneEnt);
				g_iClonedEnts[iEnt] = 0;
			}
			
			UnlockBlock(iEnt);
			set_pev(iEnt, pev_rendermode, kRenderNormal);
			
			UnsetLastMover(iEnt);
			UnsetEntMover(iEnt);
		}
	}
}

public isInReconnect(id)
{
	new auth[33];
	get_user_authid(id, auth, charsmax(auth));
	
	for(new i=0;i<charsmax(reconnectTable); i ++)
	{
		if(equal(reconnectTable[i], auth))
		{
			if(get_gametime() - reconnectTableTime[i] < 10.0)
				return i;
		}
	}
	return -1;
}

public addToReconnect(id, type)
{
	if(type == 0)
	{
		new i = isInReconnect(id);
		if(i != -1 && type == 0)
		{
			g_bUserReconnected[id] = true;
			return 0;
		}
	}
	else
	{
		new auth[33];
		get_user_authid(id, auth, charsmax(auth));
		
		for(new i = 0; i< charsmax(reconnectTable); i ++)
		{
			if(get_gametime()-reconnectTableTime[i] > 10.0)
			{			
				copy(reconnectTable[i], charsmax(reconnectTable[]), auth);
				reconnectTableTime[i] = get_gametime();
				break;
			}
		}
	}
	return 1;
}

public ev_RoundStart()
{
	remove_task(TASK_BUILD);
	remove_task(TASK_PREPTIME);
	
	arrayset(g_iOwnedEntities, 0, MAXPLAYERS+1);
	arrayset(g_iColor, 0, MAXPLAYERS+1);
	arrayset(g_iColorOwner, 0, MAX_COLORS);
	arrayset(g_boolRepick, true, MAXPLAYERS+1);
	
	arrayset(g_bUsedVipSpawn , false, sizeof(g_bUsedVipSpawn));
	arrayset(g_iOwnedEnt, 0, MAXPLAYERS+1);
	arrayset(g_numUserClones, 0, MAXPLAYERS+1);
	arrayset(g_SelectedUser, 0, MAXPLAYERS+1);
	arrayset(userNoClip, false, MAXPLAYERS+1);
	arrayset(userGodMod, false, MAXPLAYERS+1);
	arrayset(userAllowBuild, false, MAXPLAYERS+1);

	g_boolRoundEnded = false;
	g_boolCanBuild = true;
	g_fRoundStartTime = get_gametime();
	
	for (new iEnt = MAXPLAYERS + 1; iEnt < MAXENTS; iEnt++)
	{
		if (!is_valid_build_ent(iEnt))
		{
			continue;
		}
		
		new Float:fOrigin[3];
		entity_get_vector(iEnt, EV_VEC_vuser3, fOrigin);
		
		if (BlockLocker(iEnt))
		{
			new cloneEnt = g_iClonedEnts[iEnt];
			if (is_valid_ent(cloneEnt))
			{
				remove_entity(cloneEnt);
				g_iClonedEnts[iEnt] = 0;
			}
			
			UnlockBlock(iEnt);
		}
		
		UnsetLastMover(iEnt);
		
		if (GetEntMover(iEnt) != 2)
		{
			UnsetEntMover(iEnt);
		}
		
		if (g_isMapConfigured && GetEntMover(iEnt) != 2)
		{
			remove_entity(iEnt);
		}
		else
		{
			engfunc(EngFunc_SetOrigin, iEnt, fOrigin);
			set_pev(iEnt, pev_rendermode, kRenderNormal);
			set_pev(iEnt, pev_rendercolor, Float:{0.0, 0.0, 0.0});
			set_pev(iEnt, pev_renderamt, Float:{255.0});
		}
	}
}

public ev_AmmoX(id)
	set_pdata_int(id, AMMO_SLOT + read_data(1), 200, 5);

public ev_Health(id)
{
	id-=TASK_HEALTH;
	
	if (!is_user_connected(id) || !is_user_alive(id) || is_user_bot(id) || is_user_hltv(id))
	{
		remove_task(id + TASK_HEALTH);
		return PLUGIN_CONTINUE;
	}
	
	if (userNoClip[id] || userGodMod[id] || userAllowBuild[id])
	{
		new szDhudText[128], iLen = 0;
		if (userNoClip[id])		iLen += formatex(szDhudText[iLen], charsmax(szDhudText) - iLen, "[NoClip]^n");
		if (userGodMod[id])		iLen += formatex(szDhudText[iLen], charsmax(szDhudText) - iLen, "[GodMode]^n");
		if (userAllowBuild[id])	iLen += formatex(szDhudText[iLen], charsmax(szDhudText) - iLen, "[Build Mode]");

		fade_user_screen(id, 1.0, 1.0, ScreenFade_FadeIn, 78, 255, 0, 20);
		set_dhudmessage(78, 255, 0, -1.0, 0.76, 0, 0.1, 1.0, 0.1, 0.1);
		show_dhudmessage(id, "%s", szDhudText);
	}
	
	new szGoal[32], r, g, b;
	
	#if defined BB_CREDITS
		formatex(szGoal, charsmax(szGoal), "^n%L: %d", LANG_SERVER, "HUD_GOAL", credits_get_user_goal(id));
	#endif
	
	if (g_isZombie[id])
	{
		r = clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][0]);
		g = clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][1]);
		b = clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][2]);
	}
	else
	{
		r = clr(g_eSettings[HUDINFO_HUMAN_COLOR][0]);
		g = clr(g_eSettings[HUDINFO_HUMAN_COLOR][1]);
		b = clr(g_eSettings[HUDINFO_HUMAN_COLOR][2]);
	}
	
	set_hudmessage(r, g, b, g_eSettings[HUDINFO_POSITION][0], g_eSettings[HUDINFO_POSITION][1], 0, 0.1, 1.0, 0.1, 0.1);
	
	if (g_isZombie[id])
	{
		new szClassName[32];
		ArrayGetString(g_zclass_name, g_iZombieClass[id], szClassName, charsmax(szClassName));
		
		ShowSyncHudMsg(id, g_HudSync, "[ %L: %d ]^n[ %L: %s%s ]",
			LANG_SERVER, "HUD_HEALTH", pev(id, pev_health),
			LANG_SERVER, "HUD_CLASS", szClassName, szGoal);
	}
	else
	{
		ShowSyncHudMsg(id, g_HudSync, "[ %L: %d ]^n[ Class: Human%s ]^n^n[ Your Color: %s ]",
			LANG_SERVER, "HUD_HEALTH", pev(id, pev_health),
			szGoal, g_aColors[g_iColor[id]][Name]);
	}
	
	if (!g_isZombie[id] && ArePlayersInSameParty(id, userTeam[id]) && (g_boolCanBuild || g_boolPrepTime))
	{
		teamLineOrSprite(id);
	}
	
	set_task(1.0, "ev_Health", id + TASK_HEALTH);
	return PLUGIN_CONTINUE;
}

public msgStatusIcon(const iMsgId, const iMsgDest, const iPlayer)
{
	if(g_isAlive[iPlayer] && g_isConnected[iPlayer]) 
	{
		static szMsg[8];
		get_msg_arg_string(2, szMsg, charsmax(szMsg));
    
		new const blockIcon[][] =
		{
			"c4",
			"escape",
			"rescue",
			"defuser",
			"buyzone",
			"vipsafety"
		};
		
		for(new i = 0; i < sizeof(blockIcon); i ++)
		{
			if(equal(szMsg, blockIcon[i]))
			{
				set_pdata_int(iPlayer, OFFSET_BUYZONE, get_pdata_int(iPlayer, OFFSET_BUYZONE) & ~(1<<0));
				return PLUGIN_HANDLED;
			}
		}
	}
	return PLUGIN_CONTINUE;
} 

public msgHealth(msgid, dest, id)
{
	if(!g_isAlive[id])
		return PLUGIN_CONTINUE;
	
	static hp;
	hp = get_msg_arg_int(1);
	
	if(hp > 255 && (hp % 256) == 0)
		set_msg_arg_int(1, ARG_BYTE, ++hp);
	
	return PLUGIN_CONTINUE;
}

public msgRoundEnd(const MsgId, const MsgDest, const MsgEntity)
{
	static szMessage[192];
	get_msg_arg_string(2, szMessage, charsmax(szMessage));
	
	if (equal(szMessage, "#Terrorists_Win"))
	{
		g_boolRoundEnded = true;
		
		set_dhudmessage(255, 0, 0, -1.0, 0.06, 0, 6.0, 6.0);
		show_dhudmessage(0, "• %L •", LANG_SERVER, "WIN_ZOMBIE");
		
		set_msg_arg_string(2, "");
		
		client_cmd(0, "spk %s", WIN_ZOMBIES[random(sizeof WIN_ZOMBIES)]);
		
		return PLUGIN_HANDLED;
	}
	else if (equal(szMessage, "#Target_Saved") || equal(szMessage, "#CTs_Win"))
	{
		g_boolRoundEnded = true;
		
		set_dhudmessage(0, 255, 255, -1.0, 0.06, 0, 6.0, 6.0);
		show_dhudmessage(0, "• %L •", LANG_SERVER, "WIN_BUILDER");
		
		set_msg_arg_string(2, "");
		
		client_cmd(0, "spk %s", WIN_HUMANS[random(sizeof WIN_HUMANS)]);
		
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

public messageSayText()
{
	new arg[32];
	get_msg_arg_string(2, arg, charsmax(arg));
	
	if(containi(arg,"name")!= -1)
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public msgSendAudio(const MsgId, const MsgDest, const MsgEntity)
{
	static szSoundPath[17];
	get_msg_arg_string(2, szSoundPath, charsmax(szSoundPath));
	
	if(equal(szSoundPath[7], "terwin") || equal(szSoundPath[7], "ctwin") || equal(szSoundPath[7], "rounddraw")) return PLUGIN_HANDLED;
	return PLUGIN_CONTINUE;
}

public ham_WeaponCleaner_Post(iEnt)
{
	call_think(iEnt);
}

public ham_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_valid_ent(victim) || !is_user_alive(victim) || !is_user_connected(attacker) || g_isZombie[attacker] == g_isZombie[victim])
		return HAM_IGNORED;
	
	if(g_boolCanBuild || g_boolRoundEnded || g_boolPrepTime || victim == attacker)
		return HAM_SUPERCEDE;
	
	if (g_iSupercut) damage*=99.0;
	
	SetHamParamFloat(4, damage);
	
	static szEmptyText[1] = "";
	ShowDamageIndicator(attacker, damage, szEmptyText);
	ShowDamageIndicator(victim, damage, szEmptyText);
	
	return HAM_HANDLED;
}

public ham_ItemDeploy_Post(weapon_ent)
{
	static owner, weaponid;
	owner = get_pdata_cbase(weapon_ent, OFFSET_WPN_WIN, OFFSET_WPN_LINUX);
	weaponid = cs_get_weapon_id(weapon_ent);
	
	if (g_boolCanBuild && weaponid != CSW_KNIFE)
	{
		engclient_cmd(owner, "weapon_knife");
		return HAM_IGNORED;
	}

	if (g_isZombie[owner])
	{
		if (weaponid == CSW_KNIFE)
		{
			static szClawModel[100];
			ArrayGetString(g_zclass_clawmodel, g_iZombieClass[owner], szClawModel, charsmax(szClawModel));
			format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel);
			
			entity_set_string(owner, EV_SZ_viewmodel, szClawModel);
			entity_set_string(owner, EV_SZ_weaponmodel, "");
		}
		else if (!((1 << weaponid) & ZOMBIE_ALLOWED_WEAPONS_BITSUM))
		{
			engclient_cmd(owner, "weapon_knife");
		}
	}
	else
	{
		if (weaponid == CSW_KNIFE)
		{
			entity_set_string(owner, EV_SZ_viewmodel, knife_model_human);
			entity_set_string(owner, EV_SZ_weaponmodel, "");
		}
	}
	
	return HAM_IGNORED;
}

public logevent_round_start()
{
	set_pev(g_iEntBarrier,pev_solid,SOLID_BSP);
	set_pev(g_iEntBarrier,pev_rendermode,kRenderTransColor);
	set_pev(g_iEntBarrier,pev_renderamt, Float:{ BARRIER_RENDERAMT });
	
	CC_SendMessage(0, "%s^x01 %L", MODNAME, LANG_SERVER, "ROUND_MESSAGE");
	CC_SendMessage(0, "%s^x01 To copy a block, type in console:^x04 bind f +bb_copy", MODNAME);
	
	remove_task(TASK_BUILD);
	remove_task(TASK_PREPTIME);
	
	if(g_bColorDoorActive)
	{
		set_task(g_fColorDoorTime, "COLOR_DOOR", TASK_PREPTIME, _, _, "b");
	}
	else
	{
		SetEntityRenderColor(g_iEntBarrier, g_eSettings[BARRIER_PRIMARY_COLOR][0], g_eSettings[BARRIER_PRIMARY_COLOR][1], g_eSettings[BARRIER_PRIMARY_COLOR][2]);
	}
	
	set_task(1.0, "task_CountDown", TASK_BUILD,_, _, "b", g_iBuildTime);
	
	g_iCountDown = (g_iBuildTime-1);
	
	ExecuteForward(g_fwBuildStarted, g_fwDummyResult);
}

public COLOR_DOOR() 
{ 
	SetEntityRenderColor(g_iEntBarrier, g_eSettings[BARRIER_PRIMARY_COLOR][0],g_eSettings[BARRIER_PRIMARY_COLOR][1],g_eSettings[BARRIER_PRIMARY_COLOR][2]);
}

public task_CountDown()
{
	if (g_bTimerPaused)
	{
		set_dhudmessage(clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]), g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		show_dhudmessage(0, "[ Timer: PAUSED ]");
		return PLUGIN_HANDLED;
	}
	
	g_iCountDown--;
	
	if (g_iCountDown >= 0)
	{
		new r, g, b;

		if (g_iCountDown <= 10)
		{
			r = 255; g = 0; b = 0;
		}
		else if (g_iCountDown <= 30)
		{
			r = 255; g = 255; b = 0;
		}
		else
		{
			r = clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]);
			g = clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]);
			b = clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]);
		}
		
		set_dhudmessage(r, g, b, g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		new mins = g_iCountDown / 60, secs = g_iCountDown % 60;
		show_dhudmessage(0, "[ %L - %d:%02d ]", LANG_SERVER, "BUILD_TIMER", mins, secs);
	}
	else
	{
		if (g_iPrepTime)
		{
			g_boolCanBuild = false;
			g_boolPrepTime = true;
			g_iCountDown = g_iPrepTime + 1;
			
			removeNotUsedBlock();
			set_task(1.0, "task_PrepTime", TASK_PREPTIME,_, _, "b", g_iCountDown);
			
			set_hudmessage(random_num(50, 255), random_num(50, 255), random_num(50, 255), -1.0, 0.45, 0, 1.0, 10.0, 0.3, 0.6, 1)
			show_hudmessage(0, "%L", LANG_SERVER, "PREP_ANNOUNCE");
			
			new players[32], num, player;
			get_players(players, num);
			for (new i = 0; i < num; i++)
			{
				player = players[i];
				
				if (cs_get_user_team(player) != CS_TEAM_SPECTATOR && g_isAlive[player] && !g_isZombie[player])
				{
					ExecuteHamB(Ham_CS_RoundRespawn, player);
					
					set_task(0.5, "task_unstuck_player", player)
					
					if (g_iOwnedEnt[player])
						cmdStopEnt(player);
				}
			}
			CC_SendMessage(0, "%s^x01 %L", MODNAME, LANG_SERVER, "PREP_ANNOUNCE");
			ExecuteForward(g_fwPrepStarted, g_fwDummyResult);
		}
		else Release_Zombies();
		
		remove_task(TASK_BUILD);
		return PLUGIN_HANDLED;
	}
	
	if (g_iCountDown > 0)
	{
		static szTimer[32];
		
		if (g_iCountDown <= 10)
		{
			num_to_word(g_iCountDown, szTimer, charsmax(szTimer));
			client_cmd(0, "spk ^"vox/%s^"", szTimer);
		}
		else
		{
			new mins = g_iCountDown / 60, secs = g_iCountDown % 60;
			if (mins && !secs)
			{
				num_to_word(mins, szTimer, charsmax(szTimer));
				client_cmd(0, "spk ^"vox/%s minutes remaining^"", szTimer);
			}
			else if (!mins && secs == 30)
			{
				num_to_word(secs, szTimer, charsmax(szTimer));
				client_cmd(0, "spk ^"vox/%s seconds remaining^"", szTimer);
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public task_PrepTime()
{
	if (g_bTimerPaused)
	{
		set_dhudmessage(clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]), g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		show_dhudmessage(0, "[ Time Stop ]");
		return PLUGIN_HANDLED;
	}
	
	g_iCountDown--;
	
	if (g_iCountDown >= 0)
	{
		new r, g, b;
		
		if (g_iCountDown <= 10)
		{
			r = 255; g = 0; b = 0;
			
			static szTimer[32];
			num_to_word(g_iCountDown, szTimer, charsmax(szTimer));
			client_cmd(0, "spk ^"vox/%s^"", szTimer);
		}
		else
		{
			r = clr(g_eSettings[DHUD_PREP_TIME_COLOR][0]);
			g = clr(g_eSettings[DHUD_PREP_TIME_COLOR][1]);
			b = clr(g_eSettings[DHUD_PREP_TIME_COLOR][2]);
		}
		set_dhudmessage(r, g, b, g_eSettings[DHUD_PREP_TIME_POSITION][0], g_eSettings[DHUD_PREP_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		show_dhudmessage(0, "[ %L - 0:%02d ]", LANG_SERVER, "PREP_TIMER", g_iCountDown);
	}
	else
	{
		Release_Zombies();
		remove_task(TASK_PREPTIME);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public removeNotUsedBlock()
{
	for (new ent = MAXPLAYERS + 1; ent < MAXENTS; ent++) 
	{
		if (!is_valid_build_ent(ent) || GetEntMover(ent) != 2)
		{
			continue;
		}
		engfunc(EngFunc_SetOrigin, ent, Float:{ -8192.0, -8192.0, -8192.0 });
	}
}

public logevent_round_end()
{
	if (g_boolRoundEnded)
	{
		CC_SendMessage(0, "%s^x01 %L", MODNAME, LANG_SERVER, "SWAP_ANNOUNCE");

		new players[32], num, player;
		get_players(players, num);

		for (new i = 0; i < num; i++)
		{
			player = players[i];
			
			new CsTeams:new_team = (g_iTeam[player] == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
			
			cs_set_user_team(player, new_team);
			
			g_iTeam[player] = new_team;
		}
	}
	remove_task(TASK_BUILD);
	return PLUGIN_HANDLED;
}

public client_death(g_attacker, g_victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(g_victim) || !is_user_connected(g_victim) || !is_user_connected(g_attacker) || g_victim == g_attacker)
		return PLUGIN_HANDLED;
	
	remove_task(g_victim + TASK_IDLESOUND);
	g_isAlive[g_victim] = false;
	
	if (TK == 0 && g_attacker != g_victim && g_isZombie[g_attacker])
	{
		client_cmd(0, "spk %s", g_szSoundPaths[SOUND_INFECTION]);
		
		new szPlayerName[32];
		get_user_name(g_victim, szPlayerName, charsmax(szPlayerName));
		
		set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 5.0, 0.1, 0.2, 1);
		show_hudmessage(0, "%L", LANG_SERVER, "INFECT_ANNOUNCE", szPlayerName);
	}
	
	set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1);
	if (g_isZombie[g_victim])
	{
		new origin[3]
		get_user_origin(g_victim, origin);
		origin[2] += 25;
		
		te_display_additive_sprite(origin, g_iSpriteIDs[SPRITE_SKULL]);
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_ZOMBIE", g_iZombieTime);
		set_task(float(g_iZombieTime), "Respawn_Player", g_victim + TASK_RESPAWN);
	}
	else if (g_iInfectTime)
	{
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_HUMAN", g_iInfectTime);
		
		cs_set_user_team(g_victim, CS_TEAM_T);
		g_isZombie[g_victim] = true;
		set_task(float(g_iInfectTime), "Respawn_Player", g_victim + TASK_RESPAWN);
	}
	
	for (new iEnt = MAXPLAYERS + 1; iEnt < MAXENTS; iEnt++)
	{
		if (is_valid_ent(iEnt) && BlockLocker(iEnt) == g_victim)
		{
			new cloneEnt = g_iClonedEnts[iEnt];
			if (is_valid_ent(cloneEnt))
			{
				remove_entity(cloneEnt);
				g_iClonedEnts[iEnt] = 0;
			}
			
			UnlockBlock(iEnt);
			set_pev(iEnt, pev_rendermode, kRenderNormal);
		}
	}
	return PLUGIN_CONTINUE;
}

public Respawn_Player(id)
{
	id-=TASK_RESPAWN
	
	if (!g_isConnected[id] || g_isAlive[id])
		return PLUGIN_HANDLED;
	
	if (((g_boolCanBuild || g_boolPrepTime) && cs_get_user_team(id) == CS_TEAM_CT) || cs_get_user_team(id) == CS_TEAM_T)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
		
		if (!g_isAlive[id])
			set_task(3.0, "Respawn_Human", id + TASK_RESPAWN);
	}
	return PLUGIN_HANDLED;
}

public Respawn_Human(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	if (((g_boolCanBuild || g_boolPrepTime) && cs_get_user_team(id) == CS_TEAM_CT) || cs_get_user_team(id) == CS_TEAM_T)
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
	return PLUGIN_HANDLED;
} 

public playerResetMaxSpeed(id)
{
	if (!is_user_alive(id) || !g_isZombie[id])
	{
		return;
	}

	if (entity_get_float(id, EV_FL_maxspeed) != g_fPlayerSpeed[id])
	{
		entity_set_float(id, EV_FL_maxspeed, g_fPlayerSpeed[id]);
	}
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return;
	
	g_isAlive[id] = true;
	
	g_isZombie[id] = (cs_get_user_team(id) == CS_TEAM_T ? true : false);
	
	g_iTeam[id] = cs_get_user_team(id);
	
	remove_task(id + TASK_RESPAWN);
	remove_task(id + TASK_MODELSET);
	remove_task(id + TASK_IDLESOUND);
	remove_task(id + TASK_HEALTH);
	
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
	
	if (g_isZombie[id])
	{
		new zclass = g_iNextClass[id];
		if (zclass != g_iZombieClass[id])
			g_iZombieClass[id] = zclass;
		else
			zclass = g_iZombieClass[id];
			
		if (g_boolFirstSpawn[id])
		{
			CC_SendMessage(id, "This server is running Base Builder v%s by Tirant", VERSION);
			show_zclass_menu(id);
			g_boolFirstSpawn[id] = false;
		}
		
		set_pev(id, pev_health, float(ArrayGetCell(g_zclass_hp, zclass)));
		set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, zclass));
		g_fPlayerSpeed[id] = float(ArrayGetCell(g_zclass_spd, zclass));
		
		static szClawModel[100];
		ArrayGetString(g_zclass_clawmodel, zclass, szClawModel, charsmax(szClawModel));
		
		format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel);
		entity_set_string(id, EV_SZ_viewmodel, szClawModel);
		entity_set_string(id, EV_SZ_weaponmodel, "");
		
		ArrayGetString(g_zclass_name, zclass, g_szPlayerClass[id], charsmax(g_szPlayerClass[]));
		
		set_task(random_float(60.0, 360.0), "task_ZombieIdle", id + TASK_IDLESOUND, _, _, "b");
		
		ArrayGetString(g_zclass_playermodel, zclass, g_szPlayerModel[id], charsmax(g_szPlayerModel[]));
		
		new szCurrentModel[32];
		fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel));
		if (!equal(szCurrentModel, g_szPlayerModel[id]))
		{
			if (get_gametime() - g_fRoundStartTime < 5.0)
				set_task(5.0 * MODELCHANGE_DELAY, "fm_user_model_update", id + TASK_MODELSET);
			else
				fm_user_model_update(id + TASK_MODELSET);
		}
		
		ExecuteForward(g_fwClassSet, g_fwDummyResult, id, zclass);
		
		ExecuteHamB(Ham_Player_ResetMaxSpeed, id);
	}
	else
	{
		if (g_isCustomModel[id])
		{
			fm_reset_user_model(id);
		}
		
		entity_set_string(id, EV_SZ_viewmodel, knife_model_human); 
		entity_set_string(id, EV_SZ_weaponmodel, "");
		
		if ((g_iPrepTime && !g_boolCanBuild) || (g_boolCanBuild && !g_iPrepTime))
		{
			if (g_iGunsMenu)
			{
				#if defined BB_CREDITS
					credits_show_gunsmenu(id);
				#else
					show_method_menu(id);
				#endif
			}
		}
		
		if (!g_iColor[id])
		{
			SetRandomPlayerColor(id);
		}
		
		g_fUserPlayerSpeed[id] = 260.0;
	}
	
	if (!g_isMapConfigured && (access(id, FLAGS_FULLADMIN)))
	{
		set_task(10.0, "warn_map_config", id + TASK_HEALTH);
	}
	
	set_task(0.1, "ev_Health", id + TASK_HEALTH);
	
	if (g_bHasReturnOrigin[id])
	{
		g_bHasReturnOrigin[id] = false;
	}
	
	if (userNoClip[id] || userGodMod[id] || userAllowBuild[id])
	{
		userNoClip[id] = false;
		userGodMod[id] = false;
		userAllowBuild[id] = false;
	}
	
	if (ArePlayersInSameParty(id, userTeam[id]))
	{
		CheckTeamOnSpawn(id);
	}
	
	UpdatePlayerGlow(id);
}

public ham_PlayerKilled_Post(victim) set_task(6.0, "respawn_join", victim);
public task_ZombieIdle(taskid)
{
	taskid-=TASK_IDLESOUND;
	if (g_isAlive[taskid] && g_isConnected[taskid] && !g_isZombie[taskid])
		emit_sound(taskid, CHAN_VOICE, g_szZombieIdle[random(sizeof g_szZombieIdle - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public respawn_join(id)
{
	if(is_user_connected(id) && !is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T)) 
		ExecuteHamB(Ham_CS_RoundRespawn, id);
}

public fw_SetClientKeyValue(id, const infobuffer[], const szKey[])
{   
	if (g_isCustomModel[id] && equal(szKey, "model"))
		return FMRES_SUPERCEDE;
	return FMRES_IGNORED;
}

public fw_ClientUserInfoChanged(id)
{
	if (!g_isCustomModel[id])
		return FMRES_IGNORED;
	static szCurrentModel[32];
	fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel));
	if (!equal(szCurrentModel, g_szPlayerModel[id]) && !task_exists(id + TASK_MODELSET))
		fm_set_user_model(id + TASK_MODELSET);
	return FMRES_IGNORED;
}

public fm_user_model_update(taskid)
{
	static Float:fCurTime;
	fCurTime = get_gametime();
	
	if (fCurTime - g_fModelsTargetTime >= MODELCHANGE_DELAY)
	{
		fm_set_user_model(taskid);
		g_fModelsTargetTime = fCurTime;
	}
	else
	{
		set_task((g_fModelsTargetTime + MODELCHANGE_DELAY) - fCurTime, "fm_set_user_model", taskid);
		g_fModelsTargetTime += MODELCHANGE_DELAY;
	}
}

public fm_set_user_model(player)
{
	player -= TASK_MODELSET;
	engfunc(EngFunc_SetClientKeyValue, player, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", g_szPlayerModel[player]);
	g_isCustomModel[player] = true;
}

stock fm_get_user_model(player, model[], iLen)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, iLen);
}

stock fm_reset_user_model(player)
{
	g_isCustomModel[player] = false;
	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player));
}

public message_show_menu(msgid, dest, id) 
{
	if (!(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))
		return PLUGIN_CONTINUE;

	static team_select[] = "#Team_Select";
	static menu_text_code[sizeof team_select];
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1);
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE;

	static param_menu_msgid[2];
	param_menu_msgid[0] = msgid;
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid);

	return PLUGIN_HANDLED;
}

public message_vgui_menu(msgid, dest, id) 
{
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID || !(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))// 
		return PLUGIN_CONTINUE;
		
	static param_menu_msgid[2];
	param_menu_msgid[0] = msgid;
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid);

	return PLUGIN_HANDLED;
}

public task_force_team_join(menu_msgid[], id) 
{
	if (get_user_team(id))
		return;

	static msg_block;
	msg_block = get_msg_block(menu_msgid[0]);
	set_msg_block(menu_msgid[0], BLOCK_SET);
	engclient_cmd(id, "jointeam", "5");
	engclient_cmd(id, "joinclass", "5");
	set_msg_block(menu_msgid[0], msg_block);
	
	if(g_bUserReconnected[id])
	{				
		cs_set_user_team(id, CS_TEAM_T);
	}
}

public clcmd_changeteam(id)
{
	static CsTeams:team;
	team = cs_get_user_team(id);
	
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;

	globalMenu(id);
	return PLUGIN_HANDLED;
}

public clcmd_drop(id)
{
	if(g_isZombie[id]) 
		return PLUGIN_CONTINUE;

	return PLUGIN_HANDLED;
}

public clcmd1_buy(id)
{
	if (access(id, FLAGS_BUILDBAN))
		adminMenu(id);
	return PLUGIN_HANDLED;
}
public clcmd2_buy(id)
{
	PlayerMenu(id);
	return PLUGIN_HANDLED;
}

public blockCommand(id)
{
	return PLUGIN_HANDLED;
}

public msgStatusValue()
	set_msg_block(g_msgStatusText, BLOCK_SET);

public cmdSay(id)
{
	if (!g_isConnected[id])
		return PLUGIN_HANDLED;
	
	new szFullMessage[192];
	read_args(szFullMessage, charsmax(szFullMessage));
	remove_quotes(szFullMessage);

	if (szFullMessage[0] != '/')
		return PLUGIN_CONTINUE;
	
	new szCommand[32], szArgs[160], szValue[12];
	new szMessageWithoutSlash[191];
	copy(szMessageWithoutSlash, charsmax(szMessageWithoutSlash), szFullMessage[1]);
	parse(szMessageWithoutSlash, szCommand, charsmax(szCommand), szArgs, charsmax(szArgs), szValue, charsmax(szValue));
	
	if (equali(szCommand, "commands") || equali(szCommand, "cmd"))
	{
		new szCommandList[128];
		formatex(szCommandList, charsmax(szCommandList), "%s /class, /respawn, /random, /mycolor, /guns, /team, /unstuck", MODNAME);

		if (g_iColorMode)
		{
			add(szCommandList, charsmax(szCommandList), ", /whois <color>");
		}
		if (g_iColorMode != 2)
		{
			add(szCommandList, charsmax(szCommandList), ", /colors");
		}
		if (access(id, FLAGS_LOCK))
		{
			add(szCommandList, charsmax(szCommandList), ", /lock");
		}
		if (g_isMapConfigured)
		{
			add(szCommandList, charsmax(szCommandList), ", +bb_copy, bb_rotate");
		}
		
		CC_SendMessage(id, "%s", szCommandList);
		
		if (access(id, FLAGS_BUILDBAN))
		{
			CC_SendMessage(id, "%s^x04 [Admin]^x01 /adminmenu, /adminhelp, /swap, /ban, /revive, /tp, /hp, /light", MODNAME);
		}
		
	}
	else if (equali(szCommand, "class"))
	{
		show_zclass_menu(id);
		return PLUGIN_HANDLED;
	}
	else if ((equali(szCommand, "lock") || equali(szCommand, "claim")) && g_isAlive[id])
	{
		if (!RequireAccess(id, FLAGS_LOCK)) return PLUGIN_HANDLED;
		cmdLockBlock(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "whois"))
	{
		if (!g_iColorMode || szArgs[0] == EOS) return PLUGIN_HANDLED;
		
		new szColorName[64];
		if (szValue[0] != EOS)
			formatex(szColorName, charsmax(szColorName), "%s %s", szArgs, szValue);
		else
			copy(szColorName, charsmax(szColorName), szArgs);
		
		for (new i = 0; i < MAX_COLORS; i++)
		{
			if (equali(szColorName, g_aColors[i][Name]))
			{
				if (g_iColorOwner[i])
				{
					new szPlayerName[32];
					get_user_name(g_iColorOwner[i], szPlayerName, charsmax(szPlayerName));
					CC_SendMessage(id, "%s^x04 %s^x01's color is^x03 %s", MODNAME, szPlayerName, g_aColors[i][Name]);
				}
				else
				{
					CC_SendMessage(id, "%s^x01 %L^x04 %s", MODNAME, LANG_SERVER, "COLOR_NONE", g_aColors[i][Name]);
				}
				break; 
			}
		}
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "colors"))
	{
		if (!g_isZombie[id] && g_boolCanBuild && g_iColorMode != 2)
			show_colors_menu(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "team") || equali(szCommand, "t"))
	{
		teamOption(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "mycolor"))
	{
		if (!g_isZombie[id])
			CC_SendMessage(id, "%s^x01 %L:^x04 %s", MODNAME, LANG_SERVER, "COLOR_YOURS", g_aColors[g_iColor[id]][Name]);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "random"))
	{
		SetRandomPlayerColor(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "unstuck") || equali(szCommand, "o") || equali(szCommand, "uk"))
	{
		cmdUnstuck(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "guns"))
	{
		if (!g_iGunsMenu || !g_isAlive[id] || g_isZombie[id]) return PLUGIN_HANDLED;
		
		if (!g_boolCanBuild && g_boolRepick[id])
		{
			#if defined BB_CREDITS
				credits_show_gunsmenu(id);
			#else
				if (g_iPrimaryWeapon[id] == 0)
				{
					show_primary_menu(id);
				}
				else
				{
					show_method_menu(id);
				}
			#endif
		}
		else if (RequireAccess(id, FLAGS_GUNS))
		{
			if (szArgs[0])
			{
				new target = cmd_target(id, szArgs, 0);
				if (target)
				{
					cmdGuns(id, target);
				}
				else PlayerNotFound(id, szArgs, 5);
			}
			else
			{
				#if defined BB_CREDITS
					credits_show_gunsmenu(id);
				#else
					show_method_menu(id);
				#endif
			}
		}
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "adminmenu") || equali(szCommand, "a"))
	{
		if (!RequireAccess(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;
		adminMenu(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "swap") || equali(szCommand, "sp"))
	{
		if (!RequireAccess(id, FLAGS_SWAP)) return PLUGIN_HANDLED;
		
		new target = cmd_target(id, szArgs, 0);
		if (target) cmdSwap(id, target);
		else PlayerNotFound(id, szArgs, 1);
		return PLUGIN_HANDLED;
	}
	else if ((equali(szCommand, "revive") || equali(szCommand, "rv")) && szArgs[0] != EOS)
	{
		if (!RequireAccess(id, FLAGS_REVIVE)) return PLUGIN_HANDLED;
		
		new target = cmd_target(id, szArgs, 0);
		if (target) cmdRevive(id, target);
		else PlayerNotFound(id, szArgs, 0);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "respawn") || equali(szCommand, "revive") || equali(szCommand, "fixspawn"))
	{
		if (!g_bUsedVipSpawn[id] && access(id, FLAGS_VIP) && g_boolPrepTime && !g_isZombie[id])
		{
			ExecuteHamB(Ham_CS_RoundRespawn, id);
			g_bUsedVipSpawn[id] = true;
		}else if ((g_boolCanBuild && !g_isZombie[id]) || (g_isZombie[id] && (!is_user_alive(id) || pev(id, pev_health) == float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id])))))
			ExecuteHamB(Ham_CS_RoundRespawn, id);
		else if (g_isZombie[id])
			client_print(id, print_center, "%L", LANG_SERVER, "FAIL_SPAWN");
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "ban"))
	{
		if (!RequireAccess(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;
		
		new target = cmd_target(id, szArgs, 0);
		if (target) cmdBuildBan(id, target);
		else PlayerNotFound(id, szArgs, 2);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "releasezombies") || equali(szCommand, "opendor"))
	{
		if (!RequireAccess(id, FLAGS_RELEASE)) return PLUGIN_HANDLED;
		cmdStartRound(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "teleport") || equali(szCommand, "tp") && g_isAlive[id])
	{
		if (!RequireAccess(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;
		
		new target = cmd_target(id, szArgs, 0);
		if (target) cmdTeleport(id, target);
		else PlayerNotFound(id, szArgs, 3);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "light") || equali(szCommand, "nor"))
	{
		if (!RequireAccess(id, FLAGS_FULLADMIN)) return PLUGIN_HANDLED;
		light(id);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "health") || equali(szCommand, "hp"))
	{
		if (!RequireAccess(id, FLAGS_SWAP)) return PLUGIN_HANDLED;
		
		new gValue = str_to_num(szValue);
		new target = cmd_target(id, szArgs, 0);
		if (!gValue)
		{
			CC_SendMessage(id, "%s^x01 Please enter a valid amount of HP to add.", MODNAME);
			return PLUGIN_HANDLED;
		}

		if (target)
		{
			if (!g_isAlive[target]) return PLUGIN_HANDLED;
			
			set_user_health(target, get_user_health(target) + gValue);
			
			new szAction[64], szAmount[16];
			formatex(szAction, charsmax(szAction), "given %d HP", gValue);
			num_to_str(gValue, szAmount, charsmax(szAmount));

			ManagementAction(id, target, szAction, "Health", "", "", szAmount);
			client_cmd(target, "spk %s", g_szSoundPaths[SOUND_HEALTH_POINTS]);
		}
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "adminhelp") || equali(szCommand, "ah"))
	{
		if (!RequireAccess(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;
		
		new target = cmd_target(id, szArgs, 0);
		if (target)
		{
			g_SelectedUser[id] = target;
			helpingMenu(id);
		} else PlayerNotFound(id, szArgs, 4);
		return PLUGIN_HANDLED;
	}
	else if (equali(szCommand, "Clonemenu"))
	{
		if (!RequireAccess(id, FLAGS_FULLADMIN)) return PLUGIN_HANDLED;
		adminLockBlock(id)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

public cmdBuildBan(id, target)
{
	if (!access(id, FLAGS_BUILDBAN)) return PLUGIN_HANDLED;

	new player = FindPlayer(id, target);
	if (!player) return PLUGIN_HANDLED;

	g_isBuildBan[player] = !g_isBuildBan[player];

	if (g_isBuildBan[player] && g_iOwnedEnt[player])
		cmdStopEnt(player);

	new szActionVerb[32], szHudParam[16];
	formatex(szActionVerb, charsmax(szActionVerb), g_isBuildBan[player] ? "banned from building" : "unbanned from building");
	formatex(szHudParam, charsmax(szHudParam), g_isBuildBan[player] ? "disabled" : "re-enabled");
	
	ManagementAction(id, player, szActionVerb, "BUILDBAN", "ADMIN_BUILDBAN", "", szHudParam);
	
	UpdatePlayerGlow(player);
	
	if (g_isBuildBan[player])
	{
		fade_user_screen(player, .r = 255, .g = 0, .b = 0);
		shake_user_screen(player);
		client_cmd(player, "spk %s", g_szSoundPaths[SOUND_BAN_BUILD]);
	}
	else
	{
		fade_user_screen(player, .r = 255, .g = 255, .b = 255);
		client_cmd(player, "spk %s", g_szSoundPaths[SOUND_UNBAN_BUILD]);
	}
	return PLUGIN_HANDLED;
}

public cmdGuns(id, target)
{
	if (!RequireAccess(id, FLAGS_GUNS)) return PLUGIN_HANDLED;

	new player = FindPlayer(id, target, true);
	if (!player || g_isZombie[player] || !g_isAlive[player]) return PLUGIN_HANDLED;

	#if defined BB_CREDITS
		credits_show_gunsmenu(player);
	#else
		show_method_menu(player);
	#endif

	ManagementAction(id, player, "opened guns menu for", "GUNS", "ADMIN_GUNS", "", "");
	return PLUGIN_HANDLED;
}

public cmdRevive(id, target)
{
	if (!RequireAccess(id, FLAGS_REVIVE)) return PLUGIN_HANDLED;

	new player = FindPlayer(id, target, true);
	if (!player) return PLUGIN_HANDLED;

	ExecuteHamB(Ham_CS_RoundRespawn, player);
	client_cmd(player, "spk %s", g_szSoundPaths[SOUND_REVIVE]);
	
	ManagementAction(id, player, "revived", "REVIVE", "ADMIN_REVIVE", "", "");
	
	UpdatePlayerGlow(player);
	return PLUGIN_HANDLED;
}

public cmdSwap(id, target)
{
	if (!RequireAccess(id, FLAGS_SWAP)) return PLUGIN_HANDLED;

	new player = FindPlayer(id, target, true);
	if (!player) return PLUGIN_HANDLED;

	cs_set_user_team(player, (g_iTeam[player] = g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T));

	if (is_user_alive(player))
		ExecuteHamB(Ham_CS_RoundRespawn, player);

	client_cmd(player, "spk %s", g_szSoundPaths[SOUND_SWAP]);

	new szTeamName[16];
	formatex(szTeamName, charsmax(szTeamName), (g_iTeam[player] == CS_TEAM_CT) ? "builder" : "zombie");
	
	ManagementAction(id, player, "swapped", "SWAP", "ADMIN_SWAP", szTeamName, "");
	
	UpdatePlayerGlow(player);
	return PLUGIN_HANDLED;
}

public cmdTeleport(id, target)
{
	if (!RequireAccess(id, FLAGS_REVIVE) || !g_isAlive[id]) return PLUGIN_HANDLED;

	new player = FindPlayer(id, target);
	if (!player || !g_isAlive[player]) return PLUGIN_HANDLED;
	
	if (player == id)
	{
		CC_SendMessage(id, "%s^x01 You cannot teleport^x04 to yourself!", MODNAME);
		return PLUGIN_HANDLED;
	}
	
	pev(id, pev_origin, g_fAdminReturnOrigin[id]);
	pev(id, pev_angles, g_fAdminReturnAngles[id]);
	g_bHasReturnOrigin[id] = true;
	
	new Float:fOrigin[3], Float:fAngles[3];
	pev(player, pev_origin, fOrigin);
	pev(player, pev_angles, fAngles);
	
	Util_SetOrigin(id, fOrigin, fAngles);
	
	ManagementAction(id, player, "teleported", "Teleport", "", "", "", true);
	adminMenu(id);
	
	return PLUGIN_HANDLED;
}

public cmdStartRound(id)
{
	if (RequireAccess(id, FLAGS_RELEASE))
	{
		native_release_zombies();
	}
}

public Release_Zombies()
{
	g_boolCanBuild = false;
	remove_task(TASK_BUILD);
	
	g_boolPrepTime = false;
	remove_task(TASK_PREPTIME);
	
	new players[32], num, player, szWeapon[32];
	get_players(players, num, "a");
	for(new i = 0; i < num; i++)
	{
		player = players[i];

		if (!g_isZombie[player])
		{
			if (g_iOwnedEnt[player])
				cmdStopEnt(player);

			if(g_iGrenadeHE	) give_item(player,"weapon_hegrenade"), cs_set_user_bpammo(player,CSW_HEGRENADE,	g_iGrenadeHE);
			if(g_iGrenadeFLASH) give_item(player,"weapon_flashbang"), cs_set_user_bpammo(player,CSW_FLASHBANG,	g_iGrenadeFLASH);
			if(g_iGrenadeSMOKE) give_item(player,"weapon_smokegrenade"), cs_set_user_bpammo(player,CSW_SMOKEGRENADE,	g_iGrenadeSMOKE);

			if (g_iPrimaryWeapon[player])
			{
				get_weaponname(g_iPrimaryWeapon[player], szWeapon, charsmax(szWeapon));
				engclient_cmd(player, szWeapon);
			}
			fade_user_screen(player, 0.5, 2.0, ScreenFade_Modulate, .r = random(256), .g = random(256), .b = random(256), .a = 90);
		}
	}
	
	set_dhudmessage(random_num(50, 255), random_num(50, 255), random_num(50, 255), -1.0, 0.24, 0, 1.0, 10.0, 0.1, 0.2);
	show_dhudmessage(0, "%L", LANG_SERVER, "RELEASE_ANNOUNCE");
	client_cmd(0, "spk %s", g_szRoundStart[random(sizeof g_szRoundStart)]);
	
	ExecuteForward(g_fwRoundStart, g_fwDummyResult);
	
	if (g_iEntBarrier)
	{
		set_pev(g_iEntBarrier,pev_solid,SOLID_NOT);
		SetEntityRenderColor(g_iEntBarrier, g_eSettings[BARRIER_SECONDARY_COLOR][0],g_eSettings[BARRIER_SECONDARY_COLOR][1],g_eSettings[BARRIER_SECONDARY_COLOR][2]);
		set_pev(g_iEntBarrier,pev_renderamt, Float:{60.0});
	}
}

public fw_CmdStart(id, uc_handle, randseed)
{
	if (!g_isConnected[id] || !g_isAlive[id])
		return FMRES_IGNORED;
		
	new button = get_uc(uc_handle , UC_Buttons);
	new oldbutton = pev(id, pev_oldbuttons)

	if(button & IN_USE && !(oldbutton & IN_USE) && !g_iOwnedEnt[id])
		cmdGrabEnt(id);
	else if(oldbutton & IN_USE && !(button & IN_USE) && g_iOwnedEnt[id])
		cmdStopEnt(id);
		
	if (button & IN_RELOAD && !(oldbutton & IN_RELOAD) && g_iOwnedEnt[id])
		RotateBlock(id);
		
	return FMRES_IGNORED;
}

public cmdGrabEnt(id)
{
	if (g_fBuildDelay[id] + BUILD_DELAY > get_gametime())
	{
		g_fBuildDelay[id] = get_gametime();
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_SPAM");
		return PLUGIN_HANDLED;
	}
	else
		g_fBuildDelay[id] = get_gametime();

	if (g_isBuildBan[id])
	{
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_BANNED");
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		return PLUGIN_HANDLED;
	}
	
	if (g_isZombie[id] && !access(id, FLAGS_OVERRIDE))
		return PLUGIN_HANDLED;
		
	if (!g_boolCanBuild && !access(id, FLAGS_BUILD) && !access(id, FLAGS_OVERRIDE) && !userAllowBuild[id])
	{
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_NOTIME");
		return PLUGIN_HANDLED;
	}
	
	if (g_iOwnedEnt[id] && is_valid_ent(g_iOwnedEnt[id])) 
		cmdStopEnt(id);
	
	new ent, bodypart;
	get_user_aiming (id,ent,bodypart);
	
	if (isPlayer(ent))
	{
		if (!g_bCanGrabPlayers || !g_boolCanBuild || !is_user_alive(ent) || !access(id, FLAGS_OVERRIDE))
			return PLUGIN_HANDLED;
	}
	else 
	{
		if (!is_valid_build_ent(ent) || IsMovingEnt(ent))
			return PLUGIN_HANDLED;
	}
	
	if ((BlockLocker(ent) && BlockLocker(ent) != id && !ArePlayersInSameParty(id, BlockLocker(ent))) || (BlockLocker(ent) && !access(id, (g_bMoveLockBlocks ? ADMIN_ALL : FLAGS_OVERRIDE))))
		return PLUGIN_HANDLED;
		
	ExecuteForward(g_fwGrabEnt_Pre, g_fwDummyResult, id, ent);

	new iOrigin[3], Float:fOrigin[3], Float:gOrigin[3], Float:fLook[3], Float:iLook[3], Float:vMoveTo[3];
	
	entity_get_vector(ent, EV_VEC_origin, gOrigin);
	
	g_fEntDist[id] = get_user_aiming(id, ent, bodypart);

	get_user_origin(id, iOrigin, 1);
	IVecFVec(iOrigin, fOrigin);
	
	pev(id, pev_v_angle, iLook);
	angle_vector(iLook, ANGLEVECTOR_FORWARD, fLook);

	new Float:temp_vec[3];
	xs_vec_mul_scalar(fLook, g_fEntDist[id], temp_vec);
	xs_vec_add(fOrigin, temp_vec, vMoveTo);
	
	xs_vec_sub(gOrigin, vMoveTo, g_fOffset[id]);

	new lastMover = GetLastMover(ent);
	if (lastMover != 0 && lastMover != id && is_user_connected(lastMover) && !g_userClone[id] && !ArePlayersInSameParty(id, lastMover))
	{
		new lastMoverName[32], entMoverName[32];
		get_user_name(lastMover, lastMoverName, charsmax(lastMoverName));
		get_user_name(id, entMoverName, charsmax(entMoverName));

		CC_SendMessage(lastMover, "%s ^x04%s ^x01Your block has been moved by ^x04%s ", MODNAME, lastMoverName, entMoverName);
		CC_SendMessage(id, "%s ^x04[Warning] ^x01You have moved a block that belongs to ^x04%s", MODNAME, lastMoverName);
		CC_SendMessage(0,"%s ^x04%s ^x01moved a block that belongs to ^x04%s", MODNAME, entMoverName, lastMoverName);
		
		fade_user_screen(id, 1.0, 0.8, ScreenFade_FadeIn, 255, 255, 0, 150);
		shake_user_screen(id, 8.0, 0.8, 180.0);
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_WARNING]);
	}
	
	if (isPlayer(ent))
	{
		if (!is_user_alive(ent) || !access(id, FLAGS_OVERRIDE))
			return PLUGIN_HANDLED;
		
		new origin[3], start_pos[3], end_pos[3];
		get_user_origin(ent, origin);
		
		start_pos[0] = end_pos[0] = origin[0];
		start_pos[1] = end_pos[1] = origin[1];
		start_pos[2] = origin[2] + 20;
		end_pos[2] = origin[2] + 80;
		
		te_create_model_trail(start_pos, end_pos, g_iSpriteIDs[SPRITE_GRAB], .count = 20, .life = 20, .scale = 4, .velocity = 20, .randomness = 10, .receiver = 0);
		
		set_rendering(ent, kRenderFxGlowShell, 120, 250, 50, kRenderNormal, 10);
		fade_user_screen(ent, 3.0, 3.0, ScreenFade_FadeIn, 78, 255, 0, 20);
		
		ManagementAction(id, ent, "grabbed", "GRAB", "");
		
		client_cmd(ent, "spk %s", g_szSoundPaths[SOUND_GRAB_PLAYER]);
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_GRAB_ADMIN]);
	}
	else
	{
		if (g_userClone[id] || GetEntMover(ent) == 2)
		{
			if (g_numUserClones[id] >= g_maxUserClones)
			{
				client_print(id, print_center, "You have already cloned the maximum of [%d / %d] objects.", g_numUserClones[id], g_maxUserClones);
				client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
				return PLUGIN_CONTINUE;
			}
		
			new cloneEnt = createClone(ent);
			if (!is_valid_ent(cloneEnt))
			{
				return PLUGIN_HANDLED;
			}
		
			SetLastMover(cloneEnt, id);
		
			ent = cloneEnt;
			g_userClone[id] = false;
			g_numUserClones[id] ++;
			
			client_print(id, print_center, "You have already cloned the maximum of [%d / %d] objects.", g_numUserClones[id], g_maxUserClones);
		}
		else
		{
			if (g_bBlockRandomColor[id])
			{
				set_pev(ent, pev_rendermode, kRenderTransColor);
				SetBlockRenderColor(ent, id);
			}
			else
			{
				if (BlockLocker(ent))
				{
					set_pev(ent, pev_rendermode, kRenderTransColor);
					SetBlockRenderColor(ent, id);
				}
				else
				{
				
					if (g_playerBlockRenderMode[id] == RENDER_MODE_NO_COLOR)
					{
						set_pev(ent, pev_renderfx, kRenderFxNone);
						set_pev(ent, pev_rendermode, kRenderNormal);
					}
					else
					{
						new Float:ent_mins[3], Float:ent_maxs[3];
						get_block_origin(ent, ent_mins, ent_maxs);
				
						if (BlockCheck(id, ent, ent_mins, ent_maxs, CHECK_FOR_COLOR))
						{
							set_pev(ent, pev_renderfx, kRenderFxNone);
							set_pev(ent, pev_rendermode, kRenderNormal);
						}
						else
						{
							set_pev(ent, pev_rendermode, kRenderTransColor);
							SetBlockRenderColor(ent, id);
						}
					}
				}
			}
		}
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_GRAB_START]);
	}
	
	MovingEnt(ent);
	SetEntMover(ent, id);
	g_iOwnedEnt[id] = ent;

	if (!g_boolCanBuild && (access(id, FLAGS_BUILD) || access(id, FLAGS_OVERRIDE)))
	{
		new adminauthid[32],adminname[32];
		get_user_authid (id,adminauthid,charsmax(adminauthid));
		get_user_name(id,adminname,charsmax(adminauthid));
		Log("[MOVE] Admin: %s || SteamID: %s moved an entity", adminname, adminauthid);
	}
	
	ExecuteForward(g_fwGrabEnt_Post, g_fwDummyResult, id, ent);
	return PLUGIN_HANDLED
}

public cmdStopEnt(id)
{
	if (!g_iOwnedEnt[id])
		return PLUGIN_HANDLED;
	
	new ent = g_iOwnedEnt[id];

	if (isPlayer(ent) && is_user_alive(ent))
	{
		entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 0.0});
		UpdatePlayerGlow(ent);
	}
	
	ExecuteForward(g_fwDropEnt_Pre, g_fwDummyResult, id, ent);
	
	new blockLockerId = BlockLocker(ent);
	if (blockLockerId)
	{
		if (access(id, FLAGS_OVERRIDE) && !ArePlayersInSameParty(id, blockLockerId))
		{
        	SetLockedBlock(ent, blockLockerId, g_bUserLockMode[blockLockerId], false);
    	}
		else
		{
			if (ArePlayersInSameParty(id, blockLockerId))
			{
				LockBlock(ent, id);
				SetLockedBlock(ent, id, g_bUserLockMode[id], false);
			}
			else
			{
				SetLockedBlock(ent, blockLockerId, g_bUserLockMode[blockLockerId], false);
			}
		}
	}else set_pev(ent, pev_rendermode, kRenderNormal);
	
	UnsetEntMover(ent);
	SetLastMover(ent,id);
	g_iOwnedEnt[id] = 0;
	UnmovingEnt(ent);
	
	client_cmd(id, "spk %s", g_szSoundPaths[SOUND_GRAB_STOP]);
	
	ExecuteForward(g_fwDropEnt_Post, g_fwDummyResult, id, ent);
	
	CheckForZoneblock(id, ent);
	return PLUGIN_HANDLED;
}

public cmdLockBlock(id)
{
	if (!g_boolCanBuild && g_iLockBlocks && !access(id, FLAGS_LOCKAFTER))
	{
		client_print(id, print_center, "%L", LANG_SERVER, "FAIL_LOCK");
		return PLUGIN_HANDLED;
	}
	
	if (!access(id, FLAGS_LOCK) || (g_isZombie[id] && !access(id, FLAGS_OVERRIDE)))
		return PLUGIN_HANDLED;
	
	if (g_iOwnedEnt[id] != 0)
	{
		client_print(id, print_center, "You must drop the block you are holding first");
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		return PLUGIN_HANDLED;
	}
	
	new ent, bodypart;
	get_user_aiming(id, ent, bodypart);

	if (!is_valid_build_ent(ent) || IsMovingEnt(ent))
		return PLUGIN_HANDLED;
	
	if (GetEntMover(ent) == 2 || GetLastMover(ent) == 0)
	{
		client_print(id, print_center, "You cannot lock a block that has not been moved. Move it first");
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		return PLUGIN_HANDLED;
	}
	
	ExecuteForward(g_fwLockEnt_Pre, g_fwDummyResult, id, ent);

	new blockLockerId = BlockLocker(ent);
	if (blockLockerId)
	{
		if (g_iLockBlocks == 0 || blockLockerId == id || access(id, FLAGS_OVERRIDE) || ArePlayersInSameParty(id, blockLockerId))
		{
			if (g_iLockBlocks == 1)
			{
				g_iOwnedEntities[blockLockerId]--;
				client_print(blockLockerId, print_center, "%L [ %d / %d ]", LANG_SERVER, "BUILD_CLAIM_LOST", g_iOwnedEntities[blockLockerId], g_iLockMax);
			}
			
			new cloneEnt = g_iClonedEnts[ent];
			if (is_valid_ent(cloneEnt))
			{
				remove_entity(cloneEnt);
				g_iClonedEnts[ent] = 0;
			}
			
			UnlockBlock(ent);
			SetLastMover(ent, id);
			set_pev(ent, pev_renderfx, kRenderFxNone);
			set_pev(ent, pev_rendermode, kRenderNormal); 
			client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_OBJECT]);
		}
		else
		{
			client_print(id, print_center, "%L", LANG_SERVER, "BUILD_CLAIM_FAIL");
			client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		}
	}
	else if (!IsMovingEnt(ent))
	{
		if (g_iLockBlocks == 0 || (g_iLockBlocks == 1 && (g_iOwnedEntities[id] < g_iLockMax || !g_iLockMax)))
		{
			LockBlock(ent, id);
			if (g_iLockBlocks == 1)
			{
				g_iOwnedEntities[id]++;
				client_print(id, print_center, "%L [ %d / %d ]", LANG_SERVER, "BUILD_CLAIM_NEW", g_iOwnedEntities[id], g_iLockMax);
			}
			
			new cloneEnt = createClone(ent);
			if (is_valid_ent(cloneEnt))
			{
				g_iClonedEnts[ent] = cloneEnt;
			}
			
			SetLockedBlock(ent, id, g_bUserLockMode[id]);
			client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_OBJECT]);
		}
		else
		{
			client_print(id, print_center, "%L", LANG_SERVER, "BUILD_CLAIM_MAX", g_iLockMax);
			client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		}
	}
	ExecuteForward(g_fwLockEnt_Post, g_fwDummyResult, id, ent);
	return PLUGIN_HANDLED;
}

public fw_PlayerPreThink(id)
{
	if (!is_user_connected(id))
	{
		cmdStopEnt(id);
		return PLUGIN_HANDLED;
	}
	
	if (!is_user_alive(id) || !g_iOwnedEnt[id] || !is_valid_ent(g_iOwnedEnt[id]))
		return FMRES_HANDLED;
	
	new buttons = pev(id, pev_button);
	if (buttons & IN_ATTACK)
	{
		g_fEntDist[id] += OBJECT_PUSHPULLRATE;
		
		if (g_fEntDist[id] > g_fEntMaxDist)
		{
			g_fEntDist[id] = g_fEntMaxDist;
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MAX");
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PUSH");
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 1);
	}
	else if (buttons & IN_ATTACK2)
	{
		g_fEntDist[id] -= OBJECT_PUSHPULLRATE;
			
		if (g_fEntDist[id] < g_fEntSetDist)
		{
			g_fEntDist[id] = g_fEntSetDist;
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MIN");
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PULL");
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 2);
	}
	
	new ent = g_iOwnedEnt[id];
	new iOrigin[3], Float:fOrigin[3], Float:fLook[3], Float:iLook[3], Float:vMoveTo[3];
	
	get_user_origin(id, iOrigin, 1);
	IVecFVec(iOrigin, fOrigin);
	
	pev(id, pev_v_angle, iLook);
	iLook[2] = 0.0;
	angle_vector(iLook, ANGLEVECTOR_FORWARD, fLook);
	
	new Float:temp_vec[3];
	xs_vec_mul_scalar(fLook, g_fEntDist[id], temp_vec);
	xs_vec_add(fOrigin, temp_vec, vMoveTo);
	xs_vec_add(vMoveTo, g_fOffset[id], vMoveTo);
	
	if (isPlayer(ent))
	{
		if (!g_bCanGrabPlayers || !g_boolCanBuild || !is_user_alive(ent) || !access(id, FLAGS_OVERRIDE))
		{
			cmdStopEnt(id);
			return PLUGIN_HANDLED;
		}
		
		new Float:fCurrentOrigin[3], Float:fVelocity[3];
		entity_get_vector(ent, EV_VEC_origin, fCurrentOrigin);
		
		xs_vec_sub(vMoveTo, fCurrentOrigin, fVelocity);
		xs_vec_mul_scalar(fVelocity, 5.0, fVelocity);
		
		entity_set_vector(ent, EV_VEC_velocity, fVelocity);
	}
	else
	{
		entity_set_origin(ent, vMoveTo);
		
		if (BlockLocker(ent))
		{
			new cloneEnt = g_iClonedEnts[ent];
			if (is_valid_ent(cloneEnt))
			{
				entity_set_origin(cloneEnt, vMoveTo);
			}
		}
	}
	
	return FMRES_HANDLED;
}

public fw_Traceline(Float:start[3], Float:end[3], conditions, id, trace)
{
	if (!is_user_alive(id))
	{
		return PLUGIN_HANDLED;
	}
	
	static Float:hudUpdateTracker[MAXPLAYERS+1];
	if (get_gametime() - hudUpdateTracker[id] < 1.0)
	{
		return PLUGIN_HANDLED;
	}
	
	new ent = get_tr2(trace, TR_pHit);
	if (!is_valid_ent(ent))
	{
		return PLUGIN_HANDLED;
	}
	
	hudUpdateTracker[id] = get_gametime();
	
	if (is_valid_build_ent(ent) && g_iShowMovers == 1 && (g_boolCanBuild || access(id, FLAGS_INFOR)))
	{
		new szHudText[256], iLen = 0;
		set_hudmessage(0, 255, 255, -1.0, 0.16, 0, 0.1, 0.9, 0.1, 0.1);
		
		if (g_userClone[id])
		{
			iLen = formatex(szHudText, charsmax(szHudText), "-- F --^n");
		}
		
		new lockerId = BlockLocker(ent);
		if (lockerId)
		{
			new teammateId = userTeam[lockerId];
			
			if (ArePlayersInSameParty(lockerId, teammateId))
			{
				new szLockerName[32];
				new szTeammateName[32];
				get_user_name(lockerId, szLockerName, charsmax(szLockerName));
				get_user_name(teammateId, szTeammateName, charsmax(szTeammateName));
				
				iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "Claimed by:^n[ %s ] and [ %s ]", szLockerName, szTeammateName);
			}
			else
			{
				new szLockerName[32];
				get_user_name(lockerId, szLockerName, charsmax(szLockerName));
				iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "Claimed by: [ %s ]", szLockerName);
			}
		}
		else
		{
			new lastMover = GetLastMover(ent);
			new entMover = GetEntMover(ent);
			
			if (entMover == id && lastMover != 0 && lastMover != id)
			{
				new szOwnerName[32], szMoverName[32];
				get_user_name(lastMover, szOwnerName, charsmax(szOwnerName));
				get_user_name(id, szMoverName, charsmax(szMoverName));
				iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "[ %s ]^n[ %s ]", szOwnerName, szMoverName);
			}
			else if (lastMover != 0)
			{
				new szOwnerName[32];
				get_user_name(lastMover, szOwnerName, charsmax(szOwnerName));
				iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "[ %s ]", szOwnerName);
			}
			else
			{
				iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "-- ! --");
			}
		}
		
		if (iLen > 0)
		{
			show_hudmessage(id, "%s", szHudText);
		}
	}
	else if (isPlayer(ent) && is_user_connected(ent) && is_user_alive(ent))
	{
		new szHudText[256], iLen = 0;
		new szPlayerName[32];
		get_user_name(ent, szPlayerName, charsmax(szPlayerName));
		
		if (!g_isZombie[ent])
		{
			set_hudmessage(25, 125, 255, -1.0, 0.20, 0, 0.1, 0.9, 0.1, 0.1);
			iLen = formatex(szHudText, charsmax(szHudText), "[ Name: %s | Health: %d ]^n[ Color: %s ]",
				szPlayerName, pev(ent, pev_health), g_aColors[g_iColor[ent]][Name]);
		}
		else
		{
			set_hudmessage(255, 125, 25, -1.0, 0.20, 0, 0.1, 0.9, 0.1, 0.1);
			iLen = formatex(szHudText, charsmax(szHudText), "[ Name: %s | Health: %d ]^n[ Class: %s ]",
				szPlayerName, pev(ent, pev_health), g_szPlayerClass[ent]);
		}
		
		if (ArePlayersInSameParty(id, ent))
		{
			iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "^n^xc2^xbb [ TEAM ] ^xc2^xab");
		}
		
		if (userGodMod[ent] || userNoClip[ent] || userAllowBuild[ent])
		{
			iLen += formatex(szHudText[iLen], charsmax(szHudText) - iLen, "^n%s%s%s",
				userGodMod[ent]   ? "[GodMode] "   : "",
				userNoClip[ent]   ? "[NoClip] "    : "",
				userAllowBuild[ent] ? "[Build Mode] " : "");
		}
		
		if (iLen > 0)
		{
			show_hudmessage(id, "%s", szHudText);
		}
	}
	return PLUGIN_HANDLED;
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_connected(id) || g_boolCanBuild || g_boolPrepTime || g_boolRoundEnded)
		return FMRES_IGNORED;

	if (equal(sample[7], "bhit", 4))
	{
		if (g_isZombie[id])
			emit_sound(id, channel, g_szZombiePain[random(sizeof(g_szZombiePain))], volume, attn, flags, pitch);
		else
			emit_sound(id, channel, g_szHumanPain[random(sizeof(g_szHumanPain))], volume, attn, flags, pitch);
		
		return FMRES_SUPERCEDE;
	}

	if (equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
	{
		if (g_isZombie[id])
			emit_sound(id, channel, g_szZombieDie[random(sizeof(g_szZombieDie))], volume, attn, flags, pitch);
		else
			emit_sound(id, channel, g_szHumanDead[random(sizeof(g_szHumanDead))], volume, attn, flags, pitch);

		return FMRES_SUPERCEDE;
	}
	
	if (g_isZombie[id])
	{
		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3) || equal(sample[14], "sta", 3))
			{
				emit_sound(id, channel, g_szZombieMiss[random(sizeof(g_szZombieMiss))], volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
			
			if (equal(sample[14], "hit", 3))
			{
				emit_sound(id, channel, g_szZombieHit[random(sizeof(g_szZombieHit))], volume, attn, flags, pitch);
				return FMRES_SUPERCEDE;
			}
		}
	}
	return FMRES_IGNORED;
}

public fw_Suicide(id) return FMRES_SUPERCEDE;

public show_colors_menu(id)
{
	new szItemName[128], szItemInfo[8], iAdminReq;
	formatex(szItemName, charsmax(szItemName), "\d[\r ProBuilder \d] \y- \wSelect Your Color\d:^n\yCurrent: \r%s \w", g_aColors[g_iColor[id]][Name]);
	new menu = menu_create(szItemName, "colors_pushed");
	
	for (new i = 0; i < sizeof(g_aColors); i++)
	{
		if (g_iColorMode == 0 || (g_iColorMode == 1 && !g_iColorOwner[i]))
		{
			iAdminReq = g_aColors[i][AdminFlag];
		
			if (i == g_iColor[id])
			{
				formatex(szItemName, charsmax(szItemName), "\d%s", g_aColors[i][Name]);
			}
			else if (iAdminReq != ADMIN_ALL)
			{
				formatex(szItemName, charsmax(szItemName), "%s%s %s", iAdminReq && access(id, iAdminReq) ? "" : "\d", g_aColors[i][Name], iAdminReq && access(id, iAdminReq) ? "" : "\r[\yVIP\r]");
			}
			else
			{
				formatex(szItemName, charsmax(szItemName), "%s", g_aColors[i][Name]);
			}
			
			num_to_str(i, szItemInfo, charsmax(szItemInfo));
			menu_additem(menu, szItemName, szItemInfo);
		}
	}
	
	menu_display(id, menu, 0);
}

public colors_pushed(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, szInfo[8], hCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), _, _, hCallback);
	
	new iColorIndex = str_to_num(szInfo);
	new iAdminReq = g_aColors[iColorIndex][AdminFlag];
	
	if (iColorIndex == g_iColor[id])
	{
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		CC_SendMessage(id, "%s^1 This is already your current color", MODNAME);
		
		show_colors_menu(id);
		return PLUGIN_HANDLED;
	}
	
	if (g_iColorMode == 1 && g_iColorOwner[iColorIndex] != 0)
	{
		CC_SendMessage(id, "%s^1 Sorry, the selected color is not available. Please choose another", MODNAME);
		show_colors_menu(id);
		return PLUGIN_HANDLED;
	}
	
	if ((iAdminReq != ADMIN_ALL || !iAdminReq) && !access(id, iAdminReq))
	{
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		CC_SendMessage(id, "%s^1 Sorry, you don't have access to use this color", MODNAME);
		
		show_colors_menu(id);
		return PLUGIN_HANDLED;
	}
	
	new teammate = userTeam[id];
	new bool:bCanSyncTeamColor = (ArePlayersInSameParty(id, teammate) && hasOption(userSaveOption[id], save_TEAM_COLOR) && hasOption(userSaveOption[teammate], save_TEAM_COLOR));
	new bool:allowRandom = (iAdminReq && access(id, iAdminReq));
	g_bBlockRandomColor[id] = allowRandom;
	if (bCanSyncTeamColor)
	{
		g_bBlockRandomColor[teammate] = allowRandom;
	}
	
	g_iColorOwner[iColorIndex] = id;
	g_iColorOwner[g_iColor[id]] = 0;
	g_iColor[id] = iColorIndex;
	
	if (bCanSyncTeamColor)
	{
		g_iColor[teammate] = iColorIndex;
		
		CC_SendMessage(teammate, "%s^x01 Your color was synced by your teammate to^x04 %s", MODNAME, g_aColors[iColorIndex][Name]);
		ExecuteForward(g_fwNewColor, g_fwDummyResult, teammate, iColorIndex);
	}
	
	CC_SendMessage(id, "%s^x01 You have picked^x04 %s^x01 as your color", MODNAME, g_aColors[iColorIndex][Name]);
	ExecuteForward(g_fwNewColor, g_fwDummyResult, id, iColorIndex);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public show_zclass_menu(id)
{
	new menu = menu_create("\d[\r ProBuilder \d] \y- \wSelect Your Class:", "zclass_menu_handler");
	
	new szClassName[32], szClassInfo[32], iAdminReq;
	new szMenuItem[128];
	
	for(new i = 0; i < g_iZClasses; i++)
	{
		ArrayGetString(g_zclass_name, i, szClassName, charsmax(szClassName));
		ArrayGetString(g_zclass_info, i, szClassInfo, charsmax(szClassInfo));
		iAdminReq = ArrayGetCell(g_zclass_admin, i);
		
		if (i == g_iZombieClass[id])
		{
			formatex(szMenuItem, charsmax(szMenuItem), "\d%s %s", szClassName, szClassInfo);
		}
		else if (iAdminReq != ADMIN_ALL)
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%s%s \y%s %s", iAdminReq && access(id, iAdminReq) ? "" : "\d", szClassName, szClassInfo, iAdminReq && access(id, iAdminReq) ? "" : "\r[ \yAdmin\r ]");
		}
		else
		{
			formatex(szMenuItem, charsmax(szMenuItem), "%s \y%s", szClassName, szClassInfo);
		}
		menu_additem(menu, szMenuItem);
	}
	
	menu_display(id, menu, 0);
}

public zclass_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iClassIndex = item;
	if (iClassIndex == g_iZombieClass[id])
	{
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		CC_SendMessage(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_CURRENT");
		
		show_zclass_menu(id);
		return PLUGIN_HANDLED;
	}
	
	new iAdminReq = ArrayGetCell(g_zclass_admin, iClassIndex);
	if ((iAdminReq != ADMIN_ALL || !iAdminReq) && !access(id, iAdminReq))
	{
		client_cmd(id, "spk %s", g_szSoundPaths[SOUND_LOCK_FAIL]);
		CC_SendMessage(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_NO_ACCESS");
		
		show_zclass_menu(id);
		return PLUGIN_HANDLED;
	}
	
	g_iNextClass[id] = iClassIndex;
	
	new szClassName[32];
	ArrayGetString(g_zclass_name, iClassIndex, szClassName, charsmax(szClassName));
	
	if (!g_isZombie[id] || (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime)))
	{
		CC_SendMessage(id, "%s You have selected^x04 %s^x01 as your next class", MODNAME, szClassName);
	}
	
	if (!g_isAlive[id])
	{
		CC_SendMessage(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_RESPAWN");
	}
	
	if (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id);
	}
	
	ExecuteForward(g_fwClassPicked, g_fwDummyResult, id, g_iZombieClass[id]);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public show_method_menu(id)
{
	new menu = menu_create("\d[\rProBuilder\d] \y- \wChoose Your Weapon:", "weapon_method_handler");
	
	menu_additem(menu, "New Guns");
	menu_additem(menu, "Last Guns");
	
	menu_display(id, menu, 0);
}

public weapon_method_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	switch (item)
	{
		case 0:
		{
			show_primary_menu(id);
		}
		case 1:
		{
			if (g_iPrimaryWeapon[id] == 0)
			{
				show_primary_menu(id);
			}
			else
			{
				give_weapons(id);
			}
		}
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public show_primary_menu(id)
{
	new menu = menu_create("\d[\rProBuilder\d] \y- \wPrimary Weapon:", "primary_weapon_handler");
	
	new szItemInfo[8], flags = read_flags(g_pcvar_allowedweps);
	
	for (new i = 0; i < 19; i++)
	{
		if (flags & (1 << i))
		{
			num_to_str(i, szItemInfo, charsmax(szItemInfo));
			menu_additem(menu, szWeaponNames[i], szItemInfo);
		}
	}
	
	menu_display(id, menu, 0);
}

public primary_weapon_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, szInfo[8], hCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), _, _, hCallback);
	
	g_iWeaponPicked[0][id] = str_to_num(szInfo);
	
	show_secondary_menu(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public show_secondary_menu(id)
{
	new menu = menu_create("\d[\rProBuilder\d] \y- \wSecondary Weapon:", "secondary_weapon_handler");
	
	new szItemInfo[8], flags = read_flags(g_pcvar_allowedweps);
	
	for (new i = 18; i < 24; i++)
	{
		if (flags & (1 << i))
		{
			num_to_str(i, szItemInfo, charsmax(szItemInfo));
			menu_additem(menu, szWeaponNames[i], szItemInfo);
		}
	}
	
	menu_display(id, menu, 0);
}

public secondary_weapon_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new iAccess, szInfo[8], hCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), _, _, hCallback);
	
	g_iWeaponPicked[1][id] = str_to_num(szInfo);
	
	give_weapons(id);
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public give_weapons(id)
{
	strip_user_weapons(id);
	give_item(id, "weapon_knife");
   
	new szWeapon[32], csw;
	csw = g_weaponCSW[g_iWeaponPicked[0][id]];
	get_weaponname(csw, szWeapon, charsmax(szWeapon));
	give_item(id, szWeapon);
	cs_set_user_bpammo(id, csw, 999);
	g_iPrimaryWeapon[id] = csw;

	csw = g_weaponCSW[g_iWeaponPicked[1][id]];
	get_weaponname(csw, szWeapon, charsmax(szWeapon));
	give_item(id, szWeapon);
	cs_set_user_bpammo(id, csw, 999);
	
	g_boolRepick[id] = false;
}

Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, charsmax(message), message_fmt, 2);
	
	static filename[96];
	static dir[64];
	if(!dir[0])
	{
		get_basedir(dir, charsmax(dir));
		add(dir, charsmax(dir), "/logs");
	}
	
	format_time(filename, charsmax(filename), "%m-%d-%Y");
	format(filename, charsmax(filename), "%s/BaseBuilder_%s.log", dir, filename);
	
	log_to_file(filename, "%s", message);
}

stock fm_cs_get_current_weapon_ent(id)
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);

public native_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback, adminflags, credits)
{
	if (!g_boolArraysCreated)
		return 0;
		
	// Strings passed byref
	param_convert(1);
	param_convert(2);
	param_convert(3);
	param_convert(4);
	
	// Add the class
	ArrayPushString(g_zclass_name, name);
	ArrayPushString(g_zclass_info, info);
	
	ArrayPushCell(g_zclass_modelsstart, ArraySize(g_zclass_playermodel));
	ArrayPushString(g_zclass_playermodel, model);
	ArrayPushCell(g_zclass_modelsend, ArraySize(g_zclass_playermodel));
	ArrayPushCell(g_zclass_modelindex, -1);
	
	ArrayPushString(g_zclass_clawmodel, clawmodel);
	ArrayPushCell(g_zclass_hp, hp);
	ArrayPushCell(g_zclass_spd, speed);
	ArrayPushCell(g_zclass_grav, gravity);
	ArrayPushCell(g_zclass_admin, adminflags);
	ArrayPushCell(g_zclass_credits, credits);
	
	// Set temporary new class flag
	ArrayPushCell(g_zclass_new, 1);
	
	// Override zombie classes data with our customizations
	new i, k, buffer[32], Float:buffer2, nummodels_custom, nummodels_default, prec_mdl[100], size = ArraySize(g_zclass2_realname);
	for (i = 0; i < size; i++)
	{
		ArrayGetString(g_zclass2_realname, i, buffer, charsmax(buffer));
		
		// Check if this is the intended class to override
		if (!equal(name, buffer))
			continue;
		
		// Remove new class flag
		ArraySetCell(g_zclass_new, g_iZClasses, 0);
		
		// Replace caption
		ArrayGetString(g_zclass2_name, i, buffer, charsmax(buffer));
		ArraySetString(g_zclass_name, g_iZClasses, buffer);
		
		// Replace info
		ArrayGetString(g_zclass2_info, i, buffer, charsmax(buffer));
		ArraySetString(g_zclass_info, g_iZClasses, buffer);
		
		nummodels_custom = ArrayGetCell(g_zclass2_modelsend, i) - ArrayGetCell(g_zclass2_modelsstart, i);
		nummodels_default = ArrayGetCell(g_zclass_modelsend, g_iZClasses) - ArrayGetCell(g_zclass_modelsstart, g_iZClasses);
			
		// Replace each player model and model index
		for (k = 0; k < min(nummodels_custom, nummodels_default); k++)
		{
			ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer));
			ArraySetString(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, buffer);
				
			// Precache player model and replace its modelindex with the real one
			formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer);
			ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, engfunc(EngFunc_PrecacheModel, prec_mdl));
		}
			
		// We have more custom models than what we can accommodate,
		// Let's make some space...
		if (nummodels_custom > nummodels_default)
		{
			for (k = nummodels_default; k < nummodels_custom; k++)
			{
				ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer));
				ArrayInsertStringAfter(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, buffer);
				
				// Precache player model and retrieve its modelindex
				formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer);
				ArrayInsertCellAfter(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, engfunc(EngFunc_PrecacheModel, prec_mdl));
			}
				
			// Fix models end index for this class
			ArraySetCell(g_zclass_modelsend, g_iZClasses, ArrayGetCell(g_zclass_modelsend, g_iZClasses) + (nummodels_custom - nummodels_default));
		}
		
		// Replace clawmodel
		ArrayGetString(g_zclass2_clawmodel, i, buffer, charsmax(buffer));
		ArraySetString(g_zclass_clawmodel, g_iZClasses, buffer);
		
		// Precache clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", buffer);
		engfunc(EngFunc_PrecacheModel, prec_mdl);
		
		// Replace health
		buffer[0] = ArrayGetCell(g_zclass2_hp, i);
		ArraySetCell(g_zclass_hp, g_iZClasses, buffer[0]);
		
		// Replace speed
		buffer[0] = ArrayGetCell(g_zclass2_spd, i);
		ArraySetCell(g_zclass_spd, g_iZClasses, buffer[0]);
		
		// Replace gravity
		buffer2 = Float:ArrayGetCell(g_zclass2_grav, i);
		ArraySetCell(g_zclass_grav, g_iZClasses, buffer2);
		
		// Replace admin flags
		buffer2 = ArrayGetCell(g_zclass2_admin, i);
		ArraySetCell(g_zclass_admin, g_iZClasses, buffer2);
	
		// Replace credits
		buffer2 = ArrayGetCell(g_zclass2_credits, i);
		ArraySetCell(g_zclass_credits, g_iZClasses, buffer2);
	}
	
	// If class was not overriden with customization data
	if (ArrayGetCell(g_zclass_new, g_iZClasses))
	{
		// Precache default class model and replace modelindex with the real one
		formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", model, model);
		ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses), engfunc(EngFunc_PrecacheModel, prec_mdl));
		
		// Precache default clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", clawmodel);
		engfunc(EngFunc_PrecacheModel, prec_mdl);
	}

	g_iZClasses++;
	
	return g_iZClasses-1;
}

public native_get_class_cost(classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return -1;
	
	return ArrayGetCell(g_zclass_credits, classid);
}

public native_get_user_zombie_class(id) return g_iZombieClass[id];
public native_get_user_next_class(id) return g_iNextClass[id];
public native_set_user_zombie_class(id, classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return 0;
	
	g_iNextClass[id] = classid;
	return 1;
}

public native_is_user_zombie(id) return g_isZombie[id];
public native_is_user_banned(id) return g_isBuildBan[id];

public native_bool_buildphase() return g_boolCanBuild;
public native_bool_prepphase() return g_boolPrepTime;

public native_get_build_time()
{
	if (g_boolCanBuild)
		return g_iCountDown;
		
	return 0;
}

public native_set_build_time(time)
{
	if (g_boolCanBuild)
	{
		g_iCountDown = time;
		return 1;
	}
		
	return 0;
}

public native_get_user_color(id) return g_iColor[id];
public native_set_user_color(id, color)
{
	g_iColor[id] = color;
}

public native_drop_user_block(id)
{
	cmdStopEnt(id);
}

public native_get_user_block(id)
{
	if (g_iOwnedEnt[id])
		return g_iOwnedEnt[id];
		
	return 0;
}

public native_set_user_block(id, entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !MovingEnt(entity))
		g_iOwnedEnt[id] = entity;
}

public native_is_locked_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity))
		return BlockLocker(entity) ? true : false;
		
	return -1;
}

public native_lock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !BlockLocker(entity))
	{
		LockBlock(entity, 33);
		
		new cloneEnt = createClone(entity);
		if (is_valid_ent(cloneEnt))
		{
			g_iClonedEnts[entity] = cloneEnt;
		}
		
		set_pev(entity, pev_rendermode, kRenderTransColor);
		set_pev(entity, pev_rendercolor, Float:{LOCKED_COLOR});
		set_pev(entity, pev_renderamt, Float:{LOCKED_RENDERAMT});
	}
}

public native_unlock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && BlockLocker(entity))
	{
		new cloneEnt = g_iClonedEnts[entity];
		if (is_valid_ent(cloneEnt))
		{
			remove_entity(cloneEnt);
			g_iClonedEnts[entity] = 0;
		}
		
		UnlockBlock(entity);
		set_pev(entity, pev_rendermode, kRenderNormal);
	}
}

public native_release_zombies()
{
	if (g_boolCanBuild || g_boolPrepTime)
	{
		Release_Zombies();
		return 1;
	}
	return 0;
}

public native_set_user_primary(id, csw_primary)
{
	if (CSW_P228 <= csw_primary <= CSW_P90)
	{
		g_iPrimaryWeapon[id] = csw_primary;
		return g_iPrimaryWeapon[id];
	}
		
	return -1;
}

public native_block_in_zone(plugin_id, num_params)
{
	new ent = get_param(1);
	if (!is_valid_ent(ent) || isPlayer(ent))
	{
		return;
	}
	
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
}

stock ResetPlayerData(id)
{
	userTeamMenu[id] = 0;
	userTeamSend[id] = 0;
	userTeamBlock[id] = 0;
	userSaveOption[id] = 0;
	
	g_userClone[id] = 0;
	g_numUserClones[id] = 0;
	
	g_fUserPlayerSpeed[id] = 0.0;
	
	g_iTeam[id] = CS_TEAM_UNASSIGNED;
	
	g_bUserLockMode[id] = false;
	g_bUserViewCamera[id] = false;
	g_bHasReturnOrigin[id] = false;
	g_bUsedVipSpawn[id] = false;
	g_bBlockRandomColor[id] = false;
	
	userNoClip[id] = 0;
	userGodMod[id] = 0;
	userAllowBuild[id] = 0;
	userVarMenu[id] = 0;
	userHudDeal[id] = 0;
	g_SelectedUser[id] = 0;
	g_playerBlockRenderMode[id] = 0;
}

public native_get_user_primary(id)	return g_iPrimaryWeapon[id];

public native_get_flags_build()		return FLAGS_BUILD;
public native_get_flags_lock()		return FLAGS_LOCK;
public native_get_flags_buildban()	return FLAGS_BUILDBAN;
public native_get_flags_swap()		return FLAGS_SWAP;
public native_get_flags_revive()	return FLAGS_REVIVE;
public native_get_flags_guns()		return FLAGS_GUNS;
public native_get_flags_release()	return FLAGS_RELEASE;
public native_get_flags_override()	return FLAGS_OVERRIDE;
public native_get_flags_lockafter()	return FLAGS_LOCKAFTER;
