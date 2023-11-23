/*
Base Builder Zombie Mod
AmirWolf
Contact: T.me/Mr_Admins

Version 7.2 Pub
*/

#include <amxmodx>
#include <amxmisc>
#include <credits>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <csx>
#include <msgstocks>

#if AMXX_VERSION_NUM < 183
    #include <dhudmessage>
#endif 

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame

//Enable this only if you have bought the credits plugin
//#define BB_CREDITS

#define FLAGS_BUILD 	ADMIN_KICK
#define FLAGS_BUILDBAN  ADMIN_KICK
#define FLAGS_SWAP		ADMIN_KICK
#define FLAGS_REVIVE	ADMIN_KICK
#define FLAGS_RELEASE	ADMIN_BAN
#define FLAGS_OVERRIDE	ADMIN_KICK
#define FLAGS_GUNS		ADMIN_LEVEL_A
#define FLAGS_FULLADMIN	ADMIN_LEVEL_G
#define FLAGS_VIP		ADMIN_RESERVATION
#define FLAGS_LOCK		ADMIN_ALL
#define FLAGS_INFOR		ADMIN_ALL
#define FLAGS_LOCKAFTER	ADMIN_ALL 

#define VERSION "1.5"
#define MODNAME "^x03[^x04 Pro BaseBuilder^x03 ]^x01"

#define LockBlock(%1,%2)  	( entity_set_int( %1, EV_INT_iuser1,     %2 ) )
#define UnlockBlock(%1)   	( entity_set_int( %1, EV_INT_iuser1,     0  ) )
#define BlockLocker(%1)   	( entity_get_int( %1, EV_INT_iuser1         ) )

#define MovingEnt(%1)     	( entity_set_int( %1, EV_INT_iuser2,     1 ) )
#define UnmovingEnt(%1)   	( entity_set_int( %1, EV_INT_iuser2,     0 ) )
#define IsMovingEnt(%1)   	( entity_get_int( %1, EV_INT_iuser2 ) == 1 )

#define SetEntMover(%1,%2)  	( entity_set_int( %1, EV_INT_iuser3, %2 ) )
#define UnsetEntMover(%1)   	( entity_set_int( %1, EV_INT_iuser3, 0  ) )
#define GetEntMover(%1)   	( entity_get_int( %1, EV_INT_iuser3     ) )

#define SetLastMover(%1,%2)  	( entity_set_int( %1, EV_INT_iuser4, %2 ) )
#define UnsetLastMover(%1)   	( entity_set_int( %1, EV_INT_iuser4, 0  ) )
#define GetLastMover(%1)  	( entity_get_int( %1, EV_INT_iuser4     ) )

#define MAXPLAYERS 32
#define MAXENTS 1024
#define AMMO_SLOT 376
#define MODELCHANGE_DELAY 0.5
#define AUTO_TEAM_JOIN_DELAY 0.1
#define TEAM_SELECT_VGUI_MENU_ID 2
#define OBJECT_PUSHPULLRATE 4.0
#define HUD_FRIEND_HEIGHT 0.30

#define BARRIER_RENDERAMT 120.0

#define BLOCK_RENDERAMT 150.0

#define LOCKED_COLOR 125.0, 0.0, 0.0
#define LOCKED_RENDERAMT 225.0

const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)
#define OFFSET_WPN_WIN 	  41
#define OFFSET_WPN_LINUX  4

#define OFFSET_ACTIVE_ITEM 373
#define OFFSET_LINUX 5

#if cellbits == 32
	#define OFFSET_BUYZONE 235
#else
	#define OFFSET_BUYZONE 268
#endif

new g_iMaxPlayers
new g_msgSayText, g_msgStatusText
new g_HudSync

new g_isConnected[MAXPLAYERS+1]
new g_isAlive[MAXPLAYERS+1]
new g_isZombie[MAXPLAYERS+1]
new g_isBuildBan[MAXPLAYERS+1]
new g_isCustomModel[MAXPLAYERS+1]

enum (+= 5000)
{
	TASK_BUILD = 10000,
	TASK_PREPTIME,
	TASK_MODELSET,
	TASK_RESPAWN,
	TASK_HEALTH,
	TASK_IDLESOUND
}

//Custom Sounds
new g_szRoundStart[][] = 
{
	"basebuilder/IR_zombie/start/round_start1.wav",
	"basebuilder/IR_zombie/start/round_start2.wav",
	"basebuilder/IR_zombie/start/round_start3.wav",
	"basebuilder/IR_zombie/start/round_start4.wav",
	"basebuilder/IR_zombie/start/round_start5.wav",
	"basebuilder/IR_zombie/start/round_start6.wav",
	"basebuilder/IR_zombie/start/round_start7.wav"
}

new WIN_ZOMBIES[][] = 
{
	"basebuilder/IR_zombie/win/zombies_win2.wav",
	"basebuilder/IR_zombie/win/zombies_win3.wav",
	"basebuilder/IR_zombie/win/zombies_win4.wav",
	"basebuilder/IR_zombie/win/zombies_win5.wav",
	"basebuilder/IR_zombie/win/zombies_win6.wav",
	"basebuilder/IR_zombie/win/zombies_win7.wav"
	
}

new WIN_BUILDERS[][] = 
{
    "basebuilder/IR_zombie/win/win_humans1.wav",
	"basebuilder/IR_zombie/win/win_humans2.wav",
	"basebuilder/IR_zombie/win/win_humans3.wav",
	"basebuilder/IR_zombie/win/win_humans4.wav",
	"basebuilder/IR_zombie/win/win_humans6.wav",
	"basebuilder/IR_zombie/win/win_humans8.wav",
	"basebuilder/IR_zombie/win/win_humans9.wav"
}

#define LOCK_OBJECT 	"buttons/lightswitch2.wav"
#define LOCK_FAIL	"buttons/button10.wav"

#define GRAB_START	"basebuilder/block_grab.wav"
#define GRAB_STOP	"basebuilder/block_drop.wav"

#define INFECTION	"basebuilder/zombie_kill1.wav"

new const g_szZombiePain[][] =
{
	"basebuilder/zombie/pain/pain1.wav",
	"basebuilder/zombie/pain/pain2.wav",
	"basebuilder/zombie/pain/pain3.wav"
}

new const g_szZombieDie[][] =
{
	"basebuilder/zombie/death/death1.wav",
	"basebuilder/zombie/death/death2.wav",
	"basebuilder/zombie/death/death3.wav"
}

new const Pain[][] = { "RealisticSD/HumanPain1.wav", "RealisticSD/HumanPain2.wav", "RealisticSD/HumanPain3.wav", "RealisticSD/HumanPain4.wav", "RealisticSD/HumanPain5.wav", "RealisticSD/HumanPain6.wav" }
new const Dead[][] = { "RealisticSD/HumanDead1.wav", "RealisticSD/HumanDead2.wav", "RealisticSD/HumanDead3.wav", "RealisticSD/HumanDead4.wav", "RealisticSD/HumanDead5.wav" } 

new const g_szZombieIdle[][] =
{
	"basebuilder/zombie/idle/idle1.wav",
	"basebuilder/zombie/idle/idle2.wav",
	"basebuilder/zombie/idle/idle3.wav"
}

new const g_szZombieHit[][] =
{
	"basebuilder/zombie/hit/hit1.wav",
	"basebuilder/zombie/hit/hit1.wav",
	"basebuilder/zombie/hit/hit1.wav"
}

new const g_szZombieMiss[][] =
{
	"basebuilder/zombie/miss/miss1.wav",
	"basebuilder/zombie/miss/miss2.wav",
	"basebuilder/zombie/miss/miss3.wav"
}

//Custom Player Models
new Float:g_fModelsTargetTime, Float:g_fRoundStartTime
new g_szPlayerModel[MAXPLAYERS+1][32]

//Game Name
new g_szModName[32]

new Float:SlowMove[33]
new Float:OriginSave[33][3]

new g_iCountDown, g_iEntBarrier
new bool:g_boolCanBuild, bool:g_boolPrepTime, bool:g_boolRoundEnded
//new g_iFriend[MAXPLAYERS+1]
new CsTeams:g_iTeam[MAXPLAYERS+1], CsTeams:g_iCurTeam[MAXPLAYERS+1]
new bool:g_boolFirstTeam[MAXPLAYERS+1]

//Building Stores
new Float:g_fOffset1[MAXPLAYERS+1], Float:g_fOffset2[MAXPLAYERS+1], Float:g_fOffset3[MAXPLAYERS+1]
new g_iOwnedEnt[MAXPLAYERS+1], g_iOwnedEntities[MAXPLAYERS+1]
new Float:g_fEntDist[MAXPLAYERS+1]

static const g_szWpnEntNames[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
//Weapon Names (For Guns Menu)
static const szWeaponNames[24][23] = { "Schmidt Scout", "XM1014 M4", "Ingram MAC-10", "Steyr AUG A1", "UMP 45", "SG-550 Auto-Sniper",
			"IMI Galil", "Famas", "AWP Magnum Sniper", "MP5 Navy", "M249 Para Machinegun", "M3 Super 90", "M4A1 Carbine",
			"Schmidt TMP", "G3SG1 Auto-Sniper", "SG-552 Commando", "AK-47 Kalashnikov", "ES P90", "P228 Compact",
			"Dual Elite Berettas", "Fiveseven", "USP .45 ACP Tactical", "Glock 18C", "Desert Eagle .50 AE" }
			
#define MAX_COLORS 25
new const Float:g_fColor[MAX_COLORS][3] = 
{
	{200.0, 000.0, 000.0},
	{255.0, 083.0, 073.0},
	{255.0, 117.0, 056.0},
	{255.0, 174.0, 066.0},
	{255.0, 207.0, 171.0},
	{252.0, 232.0, 131.0},
	{254.0, 254.0, 034.0},
	{059.0, 176.0, 143.0},
	{197.0, 227.0, 132.0},
	{000.0, 150.0, 000.0},
	{120.0, 219.0, 226.0},
	{135.0, 206.0, 235.0},
	{128.0, 218.0, 235.0},
	{000.0, 000.0, 255.0},
	{146.0, 110.0, 174.0},
	{255.0, 105.0, 180.0},
	{246.0, 100.0, 175.0},
	{205.0, 074.0, 076.0},
	{250.0, 167.0, 108.0},
	{234.0, 126.0, 093.0},
	{180.0, 103.0, 077.0},
	{149.0, 145.0, 140.0},
	{000.0, 000.0, 000.0},
	{255.0, 255.0, 255.0},
	{000.0, 000.0, 000.0}
}

new const Float:g_fRenderAmt[MAX_COLORS] = 
{
	100.0, //Red
	135.0, //Red Orange
	140.0, //Orange
	120.0, //Yellow Orange
	140.0, //Peach
	125.0, //Yellow
	100.0, //Lemon Yellow
	125.0, //Jungle Green
	135.0, //Yellow Green
	100.0, //Green
	125.0, //Aquamarine
	150.0, //Baby Blue
	090.0, //Sky Blue
	075.0, //Blue
	175.0, //Violet
	150.0, //Hot Pink
	175.0, //Magenta
	140.0, //Mahogany
	140.0, //Tan
	140.0, //Light Brown
	165.0, //Brown
	175.0, //Gray
	125.0, //Black
	125.0, //White
	150.0  //Random
}

enum _:ColorsBB
{
    ColorName[24],
    ColorInfo[3],
    ColorFlagAdmin
}

new const g_szColorName[MAX_COLORS][ColorsBB] = 
{
	{"Red", "0", ADMIN_ALL},
	{"Red Orange", "1", ADMIN_ALL},
	{"Orange", "2", ADMIN_ALL},
	{"Yellow Orange", "3", ADMIN_ALL},
	{"Peach", "4", ADMIN_ALL},
	{"Yellow", "5", ADMIN_ALL},
	{"Lemon Yellow", "6", ADMIN_ALL},
	{"Jungle Green", "7", ADMIN_ALL},
	{"Yellow Green", "8", ADMIN_ALL},
	{"Green", "9", ADMIN_ALL},
	{"Aquamarine", "10", ADMIN_ALL},
	{"Baby Blue", "11", ADMIN_ALL},
	{"Sky Blue", "12", ADMIN_ALL},
	{"Blue", "13", ADMIN_ALL},
	{"Violet", "14", ADMIN_ALL},
	{"Hot Pink", "15", ADMIN_ALL},
	{"Magenta", "16", ADMIN_ALL},
	{"Mahogany", "17", ADMIN_ALL},
	{"Tan", "18", ADMIN_ALL},
	{"Light Brown", "19", ADMIN_ALL},
	{"Brown", "20", ADMIN_ALL},
	{"Gray", "21", ADMIN_ALL},
	{"Black", "22", ADMIN_ALL},
	{"White", "23", ADMIN_ALL},
	{"Random \r[\yVIP\r]", "*", ADMIN_LEVEL_A}
}

enum
{
	COLOR_RED = 0, 		//200, 000, 000
	COLOR_REDORANGE, 	//255, 083, 073
	COLOR_ORANGE, 		//255, 117, 056
	COLOR_YELLOWORANGE, 	//255, 174, 066
	COLOR_PEACH, 		//255, 207, 171
	COLOR_YELLOW, 		//252, 232, 131
	COLOR_LEMONYELLOW, 	//254, 254, 034
	COLOR_JUNGLEGREEN, 	//059, 176, 143
	COLOR_YELLOWGREEN, 	//197, 227, 132
	COLOR_GREEN, 		//000, 200, 000
	COLOR_AQUAMARINE, 	//120, 219, 226
	COLOR_BABYBLUE, 		//135, 206, 235
	COLOR_SKYBLUE, 		//128, 218, 235
	COLOR_BLUE, 		//000, 000, 200
	COLOR_VIOLET, 		//146, 110, 174
	COLOR_PINK, 		//255, 105, 180
	COLOR_MAGENTA, 		//246, 100, 175
	COLOR_MAHOGANY,		//205, 074, 076
	COLOR_TAN, 		//250, 167, 108
	COLOR_LIGHTBROWN, 	//234, 126, 093
	COLOR_BROWN, 		//180, 103, 077
	COLOR_GRAY, 		//149, 145, 140
	COLOR_BLACK, 		//000, 000, 000
	COLOR_WHITE ,		//255, 255, 255
	COLOR_RANDOM, 		//000, 000, 000
}

new g_iColor[MAXPLAYERS+1]
new g_iColorOwner[MAX_COLORS]

//Color Menu
new g_iMenuOffset[MAXPLAYERS+1], g_iMenuOptions[MAXPLAYERS+1][8], g_iWeaponPicked[2][MAXPLAYERS+1],
	g_iPrimaryWeapon[MAXPLAYERS+1]
	
new bool:g_boolFirstTime[MAXPLAYERS+1], bool:g_boolRepick[MAXPLAYERS+1]

new Float:g_fBuildDelay[MAXPLAYERS+1]
#define BUILD_DELAY 0.75

#define KEYS_GENERIC (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

enum
{
	ATT_HEALTH = 0,
	ATT_SPEED,
	ATT_GRAVITY
}

//Zombie Classes
new g_iZClasses
new g_iZombieClass[MAXPLAYERS+1]
new bool:g_boolFirstSpawn[MAXPLAYERS+1]
new g_szPlayerClass[MAXPLAYERS+1][32]
new g_iNextClass[MAXPLAYERS+1]
new Float:g_fPlayerSpeed[MAXPLAYERS+1]
new bool:g_boolArraysCreated
new Array:g_zclass_name
new Array:g_zclass_info
new Array:g_zclass_modelsstart // start position in models array
new Array:g_zclass_modelsend // end position in models array
new Array:g_zclass_playermodel // player models array
new Array:g_zclass_modelindex // model indices array
new Array:g_zclass_clawmodel
new Array:g_zclass_hp
new Array:g_zclass_spd
new Array:g_zclass_grav
new Array:g_zclass_admin
new Array:g_zclass_credits
//new Float:g_fClassMultiplier[MAXPLAYERS+1][3]

new Array:g_zclass2_realname, Array:g_zclass2_name, Array:g_zclass2_info,
Array:g_zclass2_modelsstart, Array:g_zclass2_modelsend, Array:g_zclass2_playermodel,
Array:g_zclass2_clawmodel, Array:g_zclass2_hp, Array:g_zclass2_spd,
Array:g_zclass2_grav, Array:g_zclass2_admin, Array:g_zclass2_credits, Array:g_zclass_new

//Forwards
new g_fwRoundStart, g_fwPrepStarted, g_fwBuildStarted, g_fwClassPicked, g_fwClassSet,
g_fwPushPull, g_fwGrabEnt_Pre, g_fwGrabEnt_Post, g_fwDropEnt_Pre,
 g_fwDropEnt_Post, g_fwNewColor, g_fwLockEnt_Pre, g_fwLockEnt_Post, g_fwDummyResult
 
 //Cvars
new g_pcvar_enabled, g_iBuildTime, g_iPrepTime,
	g_iGrenadeHE, g_iGrenadeFLASH, g_iGrenadeSMOKE,
	Float: g_fEntMinDist, Float: g_fEntSetDist, Float: g_fEntMaxDist,
	g_iShowMovers, g_iLockBlocks, g_iLockMax, g_iColorMode,
	g_iZombieTime, g_iInfectTime, g_iSupercut, g_iGunsMenu,
	g_pcvar_givenades[32], g_pcvar_allowedweps[32], human_knifemdl[75],
	PHASE_PREP[75], PHASE_BUILD[75], PHASE_RUN[75], LASTHUMAN[75]

#include "Pro_Basebuilder/vars.inl"
#include "Pro_Basebuilder/stocks.inl"
#include "Pro_Basebuilder/Clone.inl"
#include "Pro_Basebuilder/cloneAllBlock.inl"
#include "Pro_Basebuilder/bb_menu.inl"
#include "Pro_Basebuilder/writeOnSprite.inl"
#include "Pro_Basebuilder/AFK.inl"
#include "Pro_Basebuilder/team.inl"

public plugin_precache()
{
	server_cmd("bb_credits_active 0")
	register_plugin("Base Builder", VERSION, "Tirant")
	register_cvar("base_builder", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("base_builder", VERSION)
	
	ReadFile()
	
	if (!g_pcvar_enabled)
		return;

	new i;

	for (i=0; i<strlen(g_pcvar_givenades);i++)
	{
		switch(g_pcvar_givenades[i])
		{
			case 'h': g_iGrenadeHE++
			case 'f': g_iGrenadeFLASH++
			case 's': g_iGrenadeSMOKE++
		}
	}
	
	for (i=0; i<sizeof g_szRoundStart; i++) 	precache_sound(g_szRoundStart[i])
	for (i=0; i<sizeof g_szZombiePain;i++) 	precache_sound(g_szZombiePain[i])
	for (i=0; i<sizeof g_szZombieDie;i++) 	precache_sound(g_szZombieDie[i])
	for (i=0; i<sizeof g_szZombieIdle;i++) 	precache_sound(g_szZombieIdle[i])
	for (i=0; i<sizeof g_szZombieHit;i++) 	precache_sound(g_szZombieHit[i])
	for (i=0; i<sizeof g_szZombieMiss;i++) 	precache_sound(g_szZombieMiss[i])
	for (i=0; i<sizeof WIN_ZOMBIES;i++) 	precache_sound(WIN_ZOMBIES[i])
	for (i=0; i<sizeof WIN_BUILDERS;i++) 	precache_sound(WIN_BUILDERS[i])
	
	for (new i = 0; i < sizeof Pain; i++)
		engfunc(EngFunc_PrecacheSound, Pain[i])
	
	for (new i = 0; i < sizeof Dead; i++)
		engfunc(EngFunc_PrecacheSound, Dead[i])
		
	spriteBeam = precache_model(LASERSPRITE);
	team_spr = 	precache_model(TEAMSPRITE);
	sprite_bluez = 	precache_model(BLUEZSPRITE);
	
	precache_generic(PHASE_BUILD)
	precache_generic(PHASE_PREP)
	precache_generic(PHASE_RUN)
	precache_generic(LASTHUMAN)
	precache_generic(TEAM_SWP)
	
	precache_sound(LOCK_OBJECT)
	precache_sound(LOCK_FAIL)
	precache_sound(GRAB_START)
	precache_sound(GRAB_STOP)
	precache_sound(BAN_BUILD)
	precache_sound(UNBAN_BUILD)
	precache_sound(RE_VEV)
	
	precache_model(szSpriteAlfa)
	precache_model(human_knifemdl)

	if (g_iInfectTime)
		precache_sound(INFECTION)
	
	i = create_entity("info_bomb_target");
	entity_set_origin(i, Float:{8192.0,8192.0,8192.0})
	
	i = create_entity("info_map_parameters");
	DispatchKeyValue(i, "buying", "3");
	DispatchKeyValue(i, "bombradius", "1");
	DispatchSpawn(i);
	
	g_zclass_name = ArrayCreate(32, 1)
	g_zclass_info = ArrayCreate(32, 1)
	g_zclass_modelsstart = ArrayCreate(1, 1)
	g_zclass_modelsend = ArrayCreate(1, 1)
	g_zclass_playermodel = ArrayCreate(32, 1)
	g_zclass_modelindex = ArrayCreate(1, 1)
	g_zclass_clawmodel = ArrayCreate(32, 1)
	g_zclass_hp = ArrayCreate(1, 1)
	g_zclass_spd = ArrayCreate(1, 1)
	g_zclass_grav = ArrayCreate(1, 1)
	g_zclass_admin = ArrayCreate(1, 1)
	g_zclass_credits = ArrayCreate(1, 1)
	
	g_zclass2_realname = ArrayCreate(32, 1)
	g_zclass2_name = ArrayCreate(32, 1)
	g_zclass2_info = ArrayCreate(32, 1)
	g_zclass2_modelsstart = ArrayCreate(1, 1)
	g_zclass2_modelsend = ArrayCreate(1, 1)
	g_zclass2_playermodel = ArrayCreate(32, 1)
	g_zclass2_clawmodel = ArrayCreate(32, 1)
	g_zclass2_hp = ArrayCreate(1, 1)
	g_zclass2_spd = ArrayCreate(1, 1)
	g_zclass2_grav = ArrayCreate(1, 1)
	g_zclass2_admin = ArrayCreate(1, 1)
	g_zclass2_credits = ArrayCreate(1, 1)
	g_zclass_new = ArrayCreate(1, 1)
	
	g_boolArraysCreated = true
	
	precache_model(sprite_admin);
	precache_model(sprite_vip);
	precache_model(sprite_player);
	precache_model("models/rpgrocket.mdl")
	
	return;
}

ReadFile()
{	
	new szFilename[256]
	get_configsdir(szFilename, charsmax(szFilename))
	add(szFilename, charsmax(szFilename), "/Pro_basebuilder.ini")

	new iFilePointer = fopen(szFilename, "rt")

	if(iFilePointer)
	{
		new szData[256 + MAX_NAME_LENGTH], szValue[256], szKey[MAX_NAME_LENGTH]
		new szTemp[4][5], i

		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)

			switch(szData[0])
			{
				case EOS, '#', ';': continue
				default:
				{
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
					
					if(equal(szKey, "BB_ACTIVADO"))
					{
						g_pcvar_enabled = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "BB_BUILDTIME"))
					{
						g_iBuildTime = clamp(str_to_num(szValue), 5, 300)
					}
					else if(equal(szKey, "BB_PREPTIME"))
					{
						g_iPrepTime = clamp(str_to_num(szValue), 5, 100)
					}
					else if(equal(szKey, "BB_ZOMBIE_RESPAWN"))
					{
						g_iZombieTime = clamp(str_to_num(szValue), 1, 30)
					}
					else if(equal(szKey, "BB_SURVIVOR_RESPAWN_INFECTION"))
					{
						g_iInfectTime = clamp(str_to_num(szValue), 0, 30)
					}
					else if(equal(szKey, "BB_SHOW_MOVERS"))
					{
						g_iShowMovers = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "BB_LOCK_BLOCKS"))
					{
						g_iLockBlocks = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "BB_LOCKMAX"))
					{
						g_iLockMax = clamp(str_to_num(szValue), 0, 50)
					}
					else if(equal(szKey, "BB_COLOR_MODE"))
					{
						g_iColorMode = clamp(str_to_num(szValue), 0, 2)
					}
					else if(equal(szKey, "BB_MAX_MOVE_DIST"))
					{
						g_fEntMaxDist = str_to_float(szValue)
					}
					else if(equal(szKey, "BB_MIN_MOVE_DIST"))
					{
						g_fEntMinDist = str_to_float(szValue)
					}
					else if(equal(szKey, "BB_MIN_MOVE_SET"))
					{
						g_fEntSetDist = str_to_float(szValue)
					}
					else if(equal(szKey, "BB_ZOMBIE_SUPERCUT"))
					{
						g_iSupercut = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "BB_GUNSMENU"))
					{
						g_iGunsMenu = clamp(str_to_num(szValue), 0, 1)
					}
					else if(equal(szKey, "BB_ROUNDNADES"))
					{
						copy(g_pcvar_givenades, charsmax(g_pcvar_givenades), szValue)
					}
					else if(equal(szKey, "BB_WEAPONS"))
					{
						copy(g_pcvar_allowedweps, charsmax(g_pcvar_allowedweps), szValue)
					}
					else if(equal(szKey, "BB_HUMANKNIFE"))
					{
						copy(human_knifemdl, charsmax(human_knifemdl), szValue)
					}
					else if(equal(szKey, "PHASE_BUILD"))
					{
						copy(PHASE_BUILD, charsmax(PHASE_BUILD), szValue)
					}
					else if(equal(szKey, "PHASE_PREP"))
					{
						copy(PHASE_PREP, charsmax(PHASE_PREP), szValue)
					}
					else if(equal(szKey, "PHASE_RUN"))
					{
						copy(PHASE_RUN, charsmax(PHASE_RUN), szValue)
					}
					else if(equal(szKey, "LASTHUMAN"))
					{
						copy(LASTHUMAN, charsmax(LASTHUMAN), szValue)
					}
					else if(equal(szKey, "DHUD_BUILD_TIME_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
						{
							g_eSettings[DHUD_BUILD_TIME_COLOR][i] = clamp(str_to_num(szTemp[i]), -1, 255)
						}
					}
					else if(equal(szKey, "DHUD_BUILD_TIME_POSITION"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 2; i++)
						{
							g_eSettings[DHUD_BUILD_TIME_POSITION][i] = _:floatclamp(str_to_float(szTemp[i]), -1.0, 0.0)
						}
					}
					else if(equal(szKey, "DHUD_PREP_TIME_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
						{
							g_eSettings[DHUD_PREP_TIME_COLOR][i] = clamp(str_to_num(szTemp[i]), -1, 255)
						}
					}
					else if(equal(szKey, "DHUD_PREP_TIME_POSITION"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 2; i++)
						{
							g_eSettings[DHUD_PREP_TIME_POSITION][i] = _:floatclamp(str_to_float(szTemp[i]), -1.0, 1.0)
						}
					}
					else if(equal(szKey, "HUDINFO_HUMAN_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
						{
							g_eSettings[HUDINFO_HUMAN_COLOR][i] = clamp(str_to_num(szTemp[i]), -1, 255)
						}
					}
					else if(equal(szKey, "HUDINFO_ZOMBIE_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
						{
							g_eSettings[HUDINFO_ZOMBIE_COLOR][i] = clamp(str_to_num(szTemp[i]), -1, 255)
						}
					}
					else if(equal(szKey, "HUDINFO_POSITION"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 2; i++)
						{
							g_eSettings[HUDINFO_POSITION][i] = _:floatclamp(str_to_float(szTemp[i]), -1.0, 1.0)
						}
					}
					else if(equal(szKey, "BARRIER_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
						{
							g_eSettings[BARRIER_COLOR][i] = _:floatclamp(str_to_float(szTemp[i]), -1.0, 255.0)
						}
					}
				}
			}
		}
		fclose(iFilePointer)
	}
}

public plugin_cfg()
{
	g_boolArraysCreated = false
	cloneBlockFolder();
}

public plugin_init()
{
	if (!g_pcvar_enabled)
		return;
		
	formatex(g_szModName, charsmax(g_szModName), "Base Builder %s", VERSION)
	
	register_clcmd("say", 	   	"cmdSay");
	register_clcmd("say_team",	"cmdSay");
	
	//Added for old users
	register_clcmd("+grab",		"cmdGrabEnt");
	register_clcmd("-grab",		"cmdStopEnt");
	
	register_impulse(201, "Slower_blocks")
	
	register_impulse(100, 			"impulseClone");
	register_clcmd("bb_write", "writeText")
	
	new const blockCommandAll[][] = { "buy", "go", "buyammo1", "buyammo2", "radio", "radio1", "votekick", "votemap", "vote" , "kick"};
	for(new i = 0; i < sizeof(blockCommandAll); i++) register_clcmd(blockCommandAll[i],  "blockCommand")
	
	register_clcmd("say /clone",		"cloneOffset",	0);
	register_clcmd("lastinv",		"rotateBlock");
	//register_clcmd("x", "adminLockBlockCmd")
	clonePrepare();
	register_clcmd( "+jetpack",		"userJetPackOn" );
	register_clcmd( "-jetpack",		"userJetPackOff" );
	
	register_clcmd("bb_lock",	"cmdLockBlock",0, " - Aim at a block to lock it");
	register_clcmd("bb_claim",	"cmdLockBlock",0, " - Aim at a block to lock it");
	
	register_concmd("bb_buildban",	"cmdBuildBan",0, " <player>");
	register_concmd("bb_unbuildban",	"cmdBuildBan",0, " <player>");
	register_concmd("bb_bban",	"cmdBuildBan",0, " <player>");
	
	register_concmd("bb_swap",	"cmdSwap",0, " <player>");
	register_concmd("bb_revive",	"cmdRevive",0, " <player>");
	if (g_iGunsMenu) register_concmd("bb_guns",	"cmdGuns",0, " <player>");
	register_clcmd("bb_startround",	"cmdStartRound",0, " - Starts the round");
	
	register_logevent("logevent_round_start",2, 	"1=Round_Start")
	register_logevent("logevent_round_end", 2, 	"1=Round_End")
	
	register_message(get_user_msgid("TextMsg"), 	"msgRoundEnd")
	register_message(get_user_msgid("TextMsg"),	"msgSendAudio")
	register_message(get_user_msgid("StatusIcon"), 	"msgStatusIcon");
	register_message(get_user_msgid("Health"), 	"msgHealth");
	register_message(get_user_msgid("StatusValue"), 	"msgStatusValue")
	register_message(get_user_msgid("TeamInfo"), 	"msgTeamInfo");
	
	register_menucmd(register_menuid("ZClassSelect"),KEYS_GENERIC,"zclass_pushed")
	if (g_iGunsMenu)
	{
		register_menucmd(register_menuid("WeaponMethodMenu"),(1<<0)|(1<<1)|(1<<2),"weapon_method_pushed")
		register_menucmd(register_menuid("PrimaryWeaponSelect"),KEYS_GENERIC,"prim_weapons_pushed")
		register_menucmd(register_menuid("SecWeaponSelect"),KEYS_GENERIC,"sec_weapons_pushed")
	}
	
	register_event("HLTV", 		"ev_RoundStart", "a", "1=0", "2=0")
	register_event("AmmoX", 		"ev_AmmoX", 	 "be", "1=1", "1=2", "1=3", "1=4", "1=5", "1=6", "1=7", "1=8", "1=9", "1=10")
	register_event("Health",   	"ev_Health", 	 "be", "1>0");
	
	RegisterHam(Ham_Player_ResetMaxSpeed,"player","playerResetMaxSpeed",1)
	RegisterHam(Ham_Touch, 		"weapon_shield","ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Touch, 		"weaponbox",  	"ham_WeaponCleaner_Post", 1)
	RegisterHam(Ham_Spawn, 		"player", 	"ham_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed,          "player",         "ham_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, 	"player", 	"ham_TakeDamage")
	for (new i = 1; i < sizeof g_szWpnEntNames; i++)
		if (g_szWpnEntNames[i][0]) RegisterHam(Ham_Item_Deploy, g_szWpnEntNames[i], "ham_ItemDeploy_Post", 1)
	
	register_forward(FM_GetGameDescription, 		"fw_GetGameDescription")
	register_forward(FM_SetClientKeyValue, 		"fw_SetClientKeyValue")
	register_forward(FM_ClientUserInfoChanged, 	"fw_ClientUserInfoChanged")
	register_forward(FM_CmdStart, 			"fw_CmdStart");
	register_forward(FM_PlayerPreThink, 		"fw_PlayerPreThink")
	register_forward(FM_EmitSound,			"fw_EmitSound")
	register_forward(FM_ClientKill,			"fw_Suicide")
	if (g_iShowMovers)
		register_forward(FM_TraceLine, 		"fw_Traceline", true)
	
	register_clcmd("drop", "clcmd_drop")
	register_clcmd("radio3", "clcmd1_buy")
	register_clcmd("radio2", "clcmd2_buy")
	
	//Team Handlers
	register_clcmd("chooseteam",	"clcmd_changeteam")
	register_clcmd("jointeam", 	"clcmd_changeteam")
	register_message(get_user_msgid("ShowMenu"), "message_show_menu")
	register_message(get_user_msgid("VGUIMenu"), "message_vgui_menu")
	
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	
	g_iMaxPlayers = get_maxplayers()
	g_HudSync = CreateHudSyncObj();
	g_msgSayText = get_user_msgid("SayText")
	g_msgStatusText = get_user_msgid("StatusText");
	
	g_iEntBarrier = find_ent_by_tname( -1, "barrier" );
	
	//Custom Forwards
	g_fwRoundStart = CreateMultiForward("bb_round_started", ET_IGNORE)
	g_fwPrepStarted = CreateMultiForward("bb_prepphase_started", ET_IGNORE)
	g_fwBuildStarted = CreateMultiForward("bb_buildphase_started", ET_IGNORE)
	g_fwClassPicked = CreateMultiForward("bb_zombie_class_picked", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwClassSet = CreateMultiForward("bb_zombie_class_set", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwPushPull = CreateMultiForward("bb_block_pushpull", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwGrabEnt_Pre = CreateMultiForward("bb_grab_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwGrabEnt_Post = CreateMultiForward("bb_grab_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwDropEnt_Pre = CreateMultiForward("bb_drop_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwDropEnt_Post = CreateMultiForward("bb_drop_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwNewColor = CreateMultiForward("bb_new_color", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwLockEnt_Pre = CreateMultiForward("bb_lock_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwLockEnt_Post = CreateMultiForward("bb_lock_post", ET_IGNORE, FP_CELL, FP_CELL)
	
	register_dictionary("basebuilder.txt");
	
	register_menu("globalMenu", KEYS_GENERIC, "globalMenu_2")
	register_menu("PlayerMenu", KEYS_GENERIC, "PlayerMenu_2")
	//server_cmd("sv_restart 1")
	server_cmd("mp_freezetime 0")
	server_cmd("sv_maxspeed 999")
}

public playerResetMaxSpeed(id)
{
	if(is_user_alive(id) && g_isZombie[id] && entity_get_float(id, EV_FL_maxspeed) != 1.0)
	{
		entity_set_float(id, EV_FL_maxspeed, g_fPlayerSpeed[id])
	}
}

public plugin_natives()
{
	register_native("bb_register_zombie_class","native_register_zombie_class", 1)
	
	register_native("bb_get_class_cost","native_get_class_cost", 1)
	register_native("bb_get_user_zombie_class","native_get_user_zombie_class", 1)
	register_native("bb_get_user_next_class","native_get_user_next_class", 1)
	register_native("bb_set_user_zombie_class","native_set_user_zombie_class", 1)
	
	
	register_native("bb_is_user_zombie","native_is_user_zombie", 1)
	register_native("bb_is_user_banned","native_is_user_banned", 1)
	
	register_native("bb_is_build_phase","native_bool_buildphase", 1)
	register_native("bb_is_prep_phase","native_bool_prepphase", 1)
	
	register_native("bb_get_build_time","native_get_build_time", 1)
	register_native("bb_set_build_time","native_set_build_time", 1)
	
	register_native("bb_get_user_color","native_get_user_color", 1)
	register_native("bb_set_user_color","native_set_user_color", 1)
	
	register_native("bb_drop_user_block","native_drop_user_block", 1)
	register_native("bb_get_user_block","native_get_user_block", 1)
	register_native("bb_set_user_block","native_set_user_block", 1)
	
	register_native("bb_is_locked_block","native_is_locked_block", 1)
	register_native("bb_lock_block","native_lock_block", 1)
	register_native("bb_unlock_block","native_unlock_block", 1)
	register_native("bb_get_flags_lockafter","native_get_flags_lockafter", 1) 
	
	register_native("bb_release_zombies","native_release_zombies", 1)
	
	register_native("bb_set_user_primary","native_set_user_primary", 1)
	register_native("bb_get_user_primary","native_get_user_primary", 1)
	
	register_native("bb_get_flags_build","native_get_flags_build", 1)
	register_native("bb_get_flags_lock","native_get_flags_lock", 1)
	register_native("bb_get_flags_buildban","native_get_flags_buildban", 1)
	register_native("bb_get_flags_swap","native_get_flags_swap", 1)
	register_native("bb_get_flags_revive","native_get_flags_revive", 1)
	register_native("bb_get_flags_guns","native_get_flags_guns", 1)
	register_native("bb_get_flags_release","native_get_flags_release", 1)
	register_native("bb_get_flags_override","native_get_flags_override", 1)
	
	//register_native("bb_set_user_mult","native_set_user_mult", 1)
	
	//ZP Natives Converted
	register_native("zp_register_zombie_class","native_register_zombie_class", 1)
	register_native("zp_get_user_zombie_class","native_get_user_zombie_class", 1)
	register_native("zp_get_user_next_class","native_get_user_next_class", 1)
	register_native("zp_set_user_zombie_class","native_set_user_zombie_class", 1)
	register_native("zp_get_user_zombie","native_is_user_zombie", 1)
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, g_szModName)
	return FMRES_SUPERCEDE;
}

public client_connect(id){

	get_user_name(id, userName[id], charsmax(userName[]));
	addToReconnect(id, 0)
	userBarHp[id] = 0;
	userNoClip[id] = 0;
	userGodMod[id] = 0;
	userClaimed[id] = 0;
	userAfkValue[id] = 0.00;
	userMoveAs[id] = 0;
	userMoverBlockColor[id] = 0;
	userAllowBuild[id] = 0;
	userJetpackSpeed[id] = 400;
	userReconnected[id] = false;
}

public client_putinserver(id)
{
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
		
	g_isConnected[id] = true
	g_isAlive[id] = false
	g_isZombie[id] = false
	g_isBuildBan[id] = false
	g_isCustomModel[id] = false
	g_boolFirstSpawn[id] = true
	g_boolFirstTeam[id] = false
	g_boolFirstTime[id] = true
	g_boolRepick[id] = true
	
	SlowMove[id] = 0.0
	
	userLockBlock[id] = false
	AutoLockBlock[id] = false
	Color_Random_Block[id] = false
	userMusic[id] = true
	
	g_iZombieClass[id] = 0
	g_iNextClass[id] = g_iZombieClass[id]
	//for (new i = 0; i < 3; i++) g_fClassMultiplier[id][i] = 1.0
	set_task(5.0,"Respawn_Player",id+TASK_RESPAWN);
	
	return PLUGIN_CONTINUE;
}

public client_disconnect(id)
{
	removeBarHp(id);
	addToReconnect(id, 1);
	if (g_iOwnedEnt[id])
		cmdStopEnt(id)

	g_isConnected[id] = false
	g_isAlive[id] = false
	g_isZombie[id] = false
	g_isBuildBan[id] = false
	g_isCustomModel[id] = false
	g_boolFirstSpawn[id] = false
	g_boolFirstTeam[id] = false
	g_boolFirstTime[id] = false
	g_boolRepick[id] = false
	
	g_iZombieClass[id] = 0
	g_iNextClass[id] = 0
	
	userMoverBlockColor[id] = 0;
	userLockBlock[id] = false
	AutoLockBlock[id] = false
	Color_Random_Block[id] = false
	userMusic[id] = false
	
	//for (new i = 0; i < 3; i++) g_fClassMultiplier[id][i] = 1.0
	
	g_iOwnedEntities[id] = 0
	
	remove_task(id+TASK_RESPAWN)
	remove_task(id+TASK_HEALTH)
	remove_task(id+TASK_IDLESOUND)
	remove_task(id+TASK_AFK)
	
	for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
	{
		if (is_valid_ent(iEnt) && g_iLockBlocks && BlockLocker(iEnt) == id)
		{
			UnlockBlock(iEnt)
			set_pev(iEnt,pev_rendermode,kRenderNormal)
				
			UnsetLastMover(iEnt);
			UnsetEntMover(iEnt);
		}
	}
} 

public isInReconnect(id){
	new auth[33];
	get_user_authid(id, auth, charsmax(auth));
	for( new i=0;i<charsmax(reconnectTable); i ++ ){
		if( equal(reconnectTable[i], auth) ){
			if( get_gametime()-reconnectTableTime[i] < 10.0 )
				return i;
		}
	}
	return -1;
}
public addToReconnect(id, type){
	
	if( type == 0){
		new i =isInReconnect(id);
		if( i!=-1 && type == 0){
			userReconnected[id] =true;
			return 0;
		}
	}else{
		new auth[33];
		get_user_authid(id, auth, charsmax(auth) );
		for( new i = 0; i< charsmax( reconnectTable ); i ++ ){
			if( get_gametime()-reconnectTableTime[i] > 10.0 ){			
				copy( reconnectTable[ i ], charsmax( reconnectTable[ ] ), auth );
				reconnectTableTime[i]=get_gametime();
				break;
			}
		}
		
	}
	return 1;
}

public userJetPackOn(id){
	if(g_boolCanBuild || (access(id, FLAGS_FULLADMIN))){
		userJetPack[id] = true;
		entity_set_int(id,EV_INT_sequence, 8);
	}
	return PLUGIN_HANDLED;
}

public userJetPackOff(id){
	userJetPack[id] = false;
	return PLUGIN_HANDLED;
}

public ev_RoundStart()
{
	new players[32], num;
	get_players(players, num, "a");
	for(new i=0;i<num;i++) {
		g_iOwnedEnt[players[i]] = 0;
	}
	arrayset(ReviveUsedViP , false, sizeof(ReviveUsedViP));
	
	remove_task(TASK_BUILD)
	remove_task(TASK_PREPTIME)
	
	arrayset(g_iOwnedEntities, 0, MAXPLAYERS+1)
	arrayset(g_iColor, 0, MAXPLAYERS+1)
	arrayset(g_iColorOwner, 0, MAX_COLORS)
	arrayset(g_boolRepick, true, MAXPLAYERS+1)
	
	g_boolRoundEnded = false
	g_boolCanBuild = true
	g_fRoundStartTime = get_gametime()
	
	new szClass[10], szTarget[7];
	new Float:fOrigin[3]		
	for (new iEnt = MAXPLAYERS+1; iEnt < MAXENTS; iEnt++)
	{
		if( !is_valid_ent(iEnt) )
			continue;
		
		if( iEnt == g_iEntBarrier ) 
			continue;
			
		entity_get_string(iEnt, EV_SZ_classname, szClass, charsmax(szClass));
		entity_get_string(iEnt, EV_SZ_targetname, szTarget, charsmax(szTarget));
		
		if( !equal(szClass, "func_wall") || containi(szTarget, "ignore") !=-1 || equal(szTarget, "barrier") || containi(szClass, "Lab") !=-1)
			continue;
		
		if( GetEntMover(iEnt) != 2 ){
			Remove(iEnt)
		}else if(GetEntMover(iEnt) ==  2){
			entity_get_vector(iEnt, EV_VEC_vuser3, fOrigin )
			entity_set_vector(iEnt, EV_VEC_vuser4, fOrigin )
			engfunc( EngFunc_SetOrigin, iEnt, fOrigin );
		}else{	
			engfunc( EngFunc_SetOrigin, iEnt, Float:{0.0,0.0,0.0} );			
			set_pev(iEnt,pev_rendermode,kRenderNormal)
			set_pev(iEnt,pev_rendercolor, Float:{ 0.0, 0.0, 0.0 })
			set_pev(iEnt,pev_renderamt, 255.0 )
		}
		
	}
}

public ev_AmmoX(id)
	set_pdata_int(id, AMMO_SLOT + read_data(1), 200, 5)

public ev_Health(taskid)
{
	if (taskid>g_iMaxPlayers)
		taskid-=TASK_HEALTH
	
	if( !is_user_connected(taskid) || is_user_bot(taskid) || is_user_hltv(taskid)){
		remove_task( taskid+TASK_HEALTH );
		return PLUGIN_CONTINUE;
	}
	
	if (is_user_alive(taskid))
	{
		new szGoal[32]
		//if (is_credits_active())
		#if defined BB_CREDITS
			format(szGoal, charsmax(szGoal), "^n%L: %d", LANG_SERVER, "HUD_GOAL", credits_get_user_goal(taskid))
		#endif
		
		if (!g_isZombie[taskid]) set_hudmessage(clr(g_eSettings[HUDINFO_HUMAN_COLOR][0]), clr(g_eSettings[HUDINFO_HUMAN_COLOR][1]), clr(g_eSettings[HUDINFO_HUMAN_COLOR][2]), g_eSettings[HUDINFO_POSITION][0], g_eSettings[HUDINFO_POSITION][1], 0, 12.0, 12.0, 0.1, 0.2);
			else set_hudmessage(clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][0]), clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][1]), clr(g_eSettings[HUDINFO_ZOMBIE_COLOR][2]), g_eSettings[HUDINFO_POSITION][0], g_eSettings[HUDINFO_POSITION][1], 0, 12.0, 12.0, 0.1, 0.2);
			
		if (g_isZombie[taskid])
		{
			static szCache1[32], Float:userSpd[33], usergrav
			
			userSpd[taskid] = Float:ArrayGetCell(g_zclass_spd, g_iZombieClass[taskid]);
			usergrav = floatround(Float:ArrayGetCell(g_zclass_grav, g_iZombieClass[taskid]) * 1000.0);
			
			ArrayGetString(g_zclass_name, g_iZombieClass[taskid], szCache1, charsmax(szCache1))
		
			ShowSyncHudMsg(taskid, g_HudSync, "[ %L: %d ]^n[ %L: %s%s ]^n^n[ Gravity: %d | Speed: %d ]", LANG_SERVER, "HUD_HEALTH", pev(taskid, pev_health), LANG_SERVER, "HUD_CLASS", szCache1, szGoal, usergrav, userSpd[taskid]);
		}
		else
		{
			ShowSyncHudMsg(taskid, g_HudSync, "[ %L: %d ]^n[ Class: Human%s ]^n^n[ Your Color: %s ]", LANG_SERVER, "HUD_HEALTH", pev(taskid, pev_health), szGoal, g_szColorName[g_iColor[taskid]][ColorName]);
		}
		set_task(11.9, "ev_Health", taskid+TASK_HEALTH);
	}
	return PLUGIN_CONTINUE;
}

public msgStatusIcon(const iMsgId, const iMsgDest, const iPlayer)
{
	if(g_isAlive[iPlayer] && g_isConnected[iPlayer]) 
	{
		static szMsg[8]
		get_msg_arg_string(2, szMsg, 7)
    
		if(equal(szMsg, "buyzone"))
		{
			set_pdata_int(iPlayer, OFFSET_BUYZONE, get_pdata_int(iPlayer, OFFSET_BUYZONE) & ~(1<<0))
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
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
	static Message[192]
	get_msg_arg_string(2, Message, 191)
	
	if (equal(Message, "#Terrorists_Win"))
	{
		g_boolRoundEnded = true
		set_dhudmessage(255, 0, 0, -1.0, 0.06, 0, 6.0, 6.0)
		show_dhudmessage(0, "»» Round End ««^n• %L •", LANG_SERVER, "WIN_ZOMBIE")
		set_msg_arg_string(2, "")
		client_cmd(0, "spk %s", WIN_ZOMBIES[random(sizeof WIN_ZOMBIES)])
		client_cmd(0, "mp3 stop")
		return PLUGIN_HANDLED
	}
	else if (equal(Message, "#Target_Saved") || equal(Message, "#CTs_Win"))
	{
		g_boolRoundEnded = true
		set_dhudmessage(0, 255, 255, -1.0, 0.06, 0, 6.0, 6.0)
		show_dhudmessage(0, "»» Round End ««^n• %L •", LANG_SERVER, "WIN_BUILDER")
		set_msg_arg_string(2, "")
		client_cmd(0, "spk %s", WIN_BUILDERS[random(sizeof WIN_BUILDERS)])
		client_cmd(0, "mp3 stop")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public msgSendAudio(const MsgId, const MsgDest, const MsgEntity)
{
	static szSound[17]
	get_msg_arg_string(2,szSound,16)
	if(equal(szSound[7], "terwin") || equal(szSound[7], "ctwin") || equal(szSound[7], "rounddraw")) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public ham_WeaponCleaner_Post(iEnt)
{
	call_think(iEnt)
}

public ham_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!is_valid_ent(victim) || !is_user_alive(victim) || !is_user_connected(attacker) || g_isZombie[attacker] == g_isZombie[victim])
		return HAM_IGNORED
	
	if(g_boolCanBuild || g_boolRoundEnded || g_boolPrepTime || victim == attacker)
		return HAM_SUPERCEDE;
		
	if (g_iSupercut)
	{
		damage*=99.0
	}
	
	SetHamParamFloat(4, damage)
	
	/*----------------------*\
	| AFK			 |
	\*----------------------*/	
	
	if(userAfkValue[attacker] > 0.00 ) userAfkValue[attacker] -= 0.50;
		
	/* */
	if(cs_get_user_team(victim) != cs_get_user_team(attacker)){
		new gText[128];
		hudDealDmg(attacker, damage, gText);
		hudGetDmg(victim, damage, gText);
	}
	return HAM_HANDLED
}

public hudDealDmg(id, Float:dmg, szText[]){

	userHudDeal[id] = (userHudDeal[id]+1)% sizeof(hudPosHit);
	
	if( strlen(szText) > 0) set_dhudmessage(128,213,255, 0.75, hudPosHit[userHudDeal[id]][0], 0, 6.0, 0.3, 0.1, 0.1);
	else set_dhudmessage(0, 170, 255, 0.75, hudPosHit[userHudDeal[id]][0], 0, 6.0, 0.3, 0.1, 0.1);

	show_dhudmessage(id, "%d %s", floatround(dmg), szText);	
	
}

public hudGetDmg(id, Float:dmg, szText[]){
	userHudGet[id] = (userHudGet[id]+1)% sizeof(hudPosHit);
	
	if( strlen(szText) > 0)
		set_dhudmessage(240, 119, 143, 0.9, hudPosHit[userHudGet[id]][0], 0, 6.0, 0.3, 0.1, 0.1);
	else set_dhudmessage(255, 42, 85, 0.9, hudPosHit[userHudGet[id]][0], 0, 6.0, 0.3, 0.1, 0.1);
	show_dhudmessage(id, "%d %s", floatround(dmg), szText);
	
}

public ham_ItemDeploy_Post(weapon_ent)
{
	static owner
	owner = get_pdata_cbase(weapon_ent, 41, 4);

	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)
	
	if(g_isZombie[owner]) {
		if(weaponid == CSW_KNIFE) {
			static szClawModel[100]
			ArrayGetString(g_zclass_clawmodel, g_iZombieClass[owner], szClawModel, charsmax(szClawModel))
			format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel)
			entity_set_string( owner , EV_SZ_viewmodel , szClawModel )  
			entity_set_string( owner , EV_SZ_weaponmodel , "" ) 
		}
		if(!((1<<weaponid) & ZOMBIE_ALLOWED_WEAPONS_BITSUM)) 
			engclient_cmd(owner, "weapon_knife")
		
	}
	else {
		if(weaponid == CSW_KNIFE) {
			entity_set_string(owner, EV_SZ_viewmodel, human_knifemdl )  
			entity_set_string(owner, EV_SZ_weaponmodel, "" ) 
			return HAM_IGNORED;
		}
		else if (g_boolCanBuild) {
			engclient_cmd(owner, "weapon_knife")
			return HAM_IGNORED;
		}	
	}
	if (g_boolCanBuild)
		engclient_cmd(owner, "weapon_knife")
	
	return HAM_IGNORED;
}

public logevent_round_start()
{
	set_pev(g_iEntBarrier,pev_solid,SOLID_BSP)
	set_pev(g_iEntBarrier,pev_rendermode,kRenderTransColor)
	set_pev(g_iEntBarrier,pev_renderamt, Float:{ BARRIER_RENDERAMT })
	
	print_color(0, "^x04 ---[ Base Builder %s ]---", VERSION);
	print_color(0, "^x03 %L", LANG_SERVER, "ROUND_MESSAGE");
	print_color(0, "^x03 To use Jetpack ---> Bind z +jetpack");
	
	client_cmd(0,"mp3 stop");
	set_lights("#OFF");
	isMusicPlaying = false
	
	remove_task(TASK_BUILD)
	remove_task(TASK_PREPTIME)
	set_task(5.0, "COLOR_DOOR", TASK_BUILD,_, _, "b");
	set_task(1.0, "task_CountDown", TASK_BUILD,_, _, "b", g_iBuildTime);
	set_task(10.0, "Play_Music", TASK_BUILD)
	
	g_iCountDown = (g_iBuildTime-1);
	
	for( new i = 1; i < MAXPLAYERS; i++ ){
		if( !is_user_alive(i) || !is_user_connected(i) || is_user_hltv(i))
			continue
		userClaimed[i] = 0;
		userMoveAs[i] = i;
		userNoClip[i] = 0;
		userGodMod[i] = 0;
		SlowMove[i] = 0.0
		userAllowBuild[i] = 0;
	}
	
	ExecuteForward(g_fwBuildStarted, g_fwDummyResult);
}

public Play_Music()
{
    new Players[32], Num, id
    get_players(Players, Num, "ch")
    for(new i; i < Num; i++)
    {
        id = Players[i]
        if(userMusic[id])
		{
			client_cmd(id,"stopsound")
			client_cmd(id, "mp3 play %s", g_boolCanBuild ? PHASE_BUILD : (g_boolPrepTime ? PHASE_PREP : PHASE_RUN))
		}
    }
}

public COLOR_DOOR() 
{ 
	set_pev(g_iEntBarrier,pev_rendercolor, g_fColor[random(MAX_COLORS)])
}

public task_CountDown()
{
	if (clockStop)
	{
		set_dhudmessage(clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]), g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		show_dhudmessage(0, "[ Time Stop ]");
		return PLUGIN_HANDLED;
	}
	
	g_iCountDown--
	new mins = g_iCountDown/60, secs = g_iCountDown%60
	if (g_iCountDown>=0 )
	{
		switch(g_iCountDown)                   
		{
			case 0..10:
			{
				set_dhudmessage(255, 0, 0, g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
			}
			case 11..30:
			{
				set_dhudmessage(255, 255, 0, g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
			}
			default:
			{
				set_dhudmessage(clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]), g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
			}
		}
		show_dhudmessage(0, "[ %L - %d:%02d ]", LANG_SERVER, "BUILD_TIMER", mins, secs);
	}
	else
	{
		if (g_iPrepTime)
		{
			g_boolCanBuild = false
			g_boolPrepTime = true
			g_iCountDown = g_iPrepTime+1
			removeNotUsedBlock()
			set_task(1.0, "task_PrepTime", TASK_PREPTIME,_, _, "b", g_iCountDown);
			
			set_hudmessage(random_num(50, 255), random_num(50, 255), random_num(50, 255), -1.0, 0.45, 0, 1.0, 10.0, 0.3, 0.6, 1)
			show_hudmessage(0, "%L", LANG_SERVER, "PREP_ANNOUNCE");
			
			new players[32], num
			get_players(players, num)
			for (new i = 0; i < num; i++)
			{
				if (cs_get_user_team(players[i]) != CS_TEAM_SPECTATOR && g_isAlive[players[i]] && !g_isZombie[players[i]])
				{
					ExecuteHamB(Ham_CS_RoundRespawn, players[i])
					
					if (g_iOwnedEnt[players[i]])
						cmdStopEnt(players[i])
				}
			}
			print_color(0, "%s^x04 %L", MODNAME, LANG_SERVER, "PREP_ANNOUNCE")
			
			set_task(1.0, "Play_Music", TASK_PREPTIME)
			
			ExecuteForward(g_fwPrepStarted, g_fwDummyResult);
		}
		else
			Release_Zombies()

		remove_task(TASK_BUILD);
		return PLUGIN_HANDLED;
	}
	
	new szTimer[32]
	if (g_iCountDown>10)
	{
		if (mins && !secs) num_to_word(mins, szTimer, charsmax(szTimer))
		else if (!mins && secs == 30) num_to_word(secs, szTimer, charsmax(szTimer))
		else return PLUGIN_HANDLED;
		
		client_cmd(0, "spk ^"vox/%s %s remaining^"", szTimer, (mins ? "minutes" : "seconds"))
	}
	else
	{
		num_to_word(g_iCountDown, szTimer, charsmax(szTimer))
		client_cmd(0, "spk ^"vox/%s^"", szTimer)
	}
	return PLUGIN_CONTINUE;
}

public task_PrepTime()
{
	if (clockStop)
	{
		set_dhudmessage(clr(g_eSettings[DHUD_BUILD_TIME_COLOR][0]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][1]), clr(g_eSettings[DHUD_BUILD_TIME_COLOR][2]), g_eSettings[DHUD_BUILD_TIME_POSITION][0], g_eSettings[DHUD_BUILD_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
		show_dhudmessage(0, "[ Time Stop ]");
		return PLUGIN_HANDLED;
	}
	
	
	g_iCountDown--
	
	if (g_iCountDown>=0)
	{
		switch(g_iCountDown)                   
		{
			case 0..10:
			{
				set_dhudmessage(255, 0, 0, g_eSettings[DHUD_PREP_TIME_POSITION][0], g_eSettings[DHUD_PREP_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
			}
			default:
			{
				set_dhudmessage(clr(g_eSettings[DHUD_PREP_TIME_COLOR][0]), clr(g_eSettings[DHUD_PREP_TIME_COLOR][1]), clr(g_eSettings[DHUD_PREP_TIME_COLOR][2]), g_eSettings[DHUD_PREP_TIME_POSITION][0], g_eSettings[DHUD_PREP_TIME_POSITION][1], 0, 1.0, 0.8, 0.4, 0.1);
			}
		}
		show_dhudmessage(0, "[ %L - 0:%02d ]", LANG_SERVER, "PREP_TIMER", g_iCountDown);
    }
	if (0<g_iCountDown<11)
	{
		new szTimer[32]
		num_to_word(g_iCountDown, szTimer, charsmax(szTimer))
		client_cmd(0, "spk ^"vox/%s^"", szTimer)
	}
	else if (g_iCountDown == 0)
	{
		Release_Zombies()
		remove_task(TASK_PREPTIME);
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE;
}

public removeNotUsedBlock(){
	new szClass[10], szTarget[10];
	for(new ent=MAXPLAYERS+1; ent<MAXENTS;ent ++){
		if( !is_valid_ent(ent) )
			continue;
		
		if( ent == g_iEntBarrier ) 
			continue;
		
		
		entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
		entity_get_string(ent, EV_SZ_targetname, szTarget, charsmax(szTarget));
		
		if( !equal(szClass, "func_wall") || containi(szTarget, "ignore")!=-1|| containi(szTarget, "JUMP")!=-1 || containi(szTarget, "Lab")!=-1)
			continue;			
		
		if( GetEntMover(ent) == 3 || GetEntMover(ent) == 1  || GetEntMover(ent) == 0 )
			continue
			
		engfunc( EngFunc_SetOrigin, ent, Float:{ -8192.0, -8192.0, -8192.0 } );
	}
}

public logevent_round_end()
{
	if (g_boolRoundEnded)
	{
		new players[32], num, player
		get_players(players, num)
		for (new i = 0; i < num; i++)
		{
			player = players[i]
			
			removeBarHp(player)
			
			if (g_iCurTeam[player] == g_iTeam[player] )
				cs_set_user_team(player, (g_iTeam[player] = (g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T)))
			else
				g_iTeam[player] = g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T
		}
		print_color(0, "%s^x04 %L", MODNAME, LANG_SERVER, "SWAP_ANNOUNCE")
	}
	client_cmd(0, "mp3 stop")
	remove_task(TASK_BUILD)	
	return PLUGIN_HANDLED
}

public client_death(g_attacker, g_victim, wpnindex, hitplace, TK)
{
	if (is_user_alive(g_victim) || !is_user_connected(g_victim) || !is_user_connected(g_attacker) || g_victim == g_attacker )
		return PLUGIN_HANDLED;
	
	remove_task(g_victim+TASK_IDLESOUND)
	
	g_isAlive[g_victim] = false;
	
	if (TK == 0 && g_attacker != g_victim && g_isZombie[g_attacker])
	{
		client_cmd(0, "spk %s", INFECTION)
		new szPlayerName[32]
		get_user_name(g_victim, szPlayerName, charsmax(szPlayerName))
		set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 5.0, 0.1, 0.2, 1)
		show_hudmessage(0, "%L", LANG_SERVER, "INFECT_ANNOUNCE", szPlayerName);
	}
	
	set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2, 1)
	if (g_isZombie[g_victim])
	{
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_ZOMBIE", g_iZombieTime);
		set_task(float(g_iZombieTime), "Respawn_Player", g_victim+TASK_RESPAWN)
	}
	else if (g_iInfectTime)
	{
		show_hudmessage(g_victim, "%L", LANG_SERVER, "DEATH_HUMAN", g_iInfectTime);
		cs_set_user_team(g_victim, CS_TEAM_T)
		g_isZombie[g_victim] = true
		set_task(float(g_iInfectTime), "Respawn_Player", g_victim+TASK_RESPAWN)
		if(gethumans() == 1)
		{
			for(new i = 1; i <= g_iMaxPlayers; i++)
			{
				if (is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT && !isMusicPlaying)
				{
					client_cmd(0, "mp3 play ^"%s^"", LASTHUMAN)
					isMusicPlaying = true;
					set_lights("c")
					give_item(i, "weapon_hegrenade")
					give_item(i, "weapon_smokegrenade")
					set_task(5.0, "Random_Color", i+TASK_RESPAWN, _, _, "b");
				}
			}
		}
	}
	for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
	{
		if (is_valid_ent(iEnt) && g_iLockBlocks && BlockLocker(iEnt) == g_victim)
		{
			UnlockBlock(iEnt)
			set_pev(iEnt,pev_rendermode,kRenderNormal)
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Random_Color(iPlayer)
{
	iPlayer-=TASK_RESPAWN
	new vpos[3]
	get_user_origin(iPlayer, vpos, 0)
	if( is_user_alive(iPlayer) )
	{
		set_user_rendering(iPlayer, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, 16);
		te_create_beam_ring(vpos, spriteBeam, .r = random(256), .g = random(256), .b = random(256))
	}
}
gethumans()
{
    static iAlive, id 
    iAlive = 0 
    
    for (id = 1; id <= g_iMaxPlayers; id++) 
    { 
        if (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) 
            iAlive++ 
    } 
    return iAlive; 
}

public Respawn_Player(id)
{
    id-=TASK_RESPAWN
    
    if (!g_isConnected[id] || g_isAlive[id])
        return PLUGIN_HANDLED
    
    if (((g_boolCanBuild || g_boolPrepTime) && cs_get_user_team(id) == CS_TEAM_CT) || cs_get_user_team(id) == CS_TEAM_T)
    {
        ExecuteHamB(Ham_CS_RoundRespawn, id)
        
        //Loop the task until they have successfully spawned
        if (!g_isAlive[id])
            set_task(3.0,"Respawn_Human",id+TASK_RESPAWN)
    }
    return PLUGIN_HANDLED
}

public Respawn_Human(id)
{
    if (!is_user_connected(id))
        return PLUGIN_HANDLED
    
    if (((g_boolCanBuild || g_boolPrepTime) && cs_get_user_team(id) == CS_TEAM_CT) || cs_get_user_team(id) == CS_TEAM_T)
    {
        ExecuteHamB(Ham_CS_RoundRespawn, id)
    }
    return PLUGIN_HANDLED
} 

public ham_PlayerSpawn_Post(id)
{
	if (is_user_alive(id))
	{
		g_isAlive[id] = true;
		
		if( !task_exists(id+TASK_AFK) )
			set_task(0.1, "checkCamping", id + TASK_AFK);
			
		g_isZombie[id] = (cs_get_user_team(id) == CS_TEAM_T ? true : false)
		
		remove_task(id + TASK_RESPAWN)
		remove_task(id + TASK_MODELSET)
		remove_task(id + TASK_IDLESOUND)
		
		//Handles the knife and claw model
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
		
		if (g_isZombie[id])
		{
			if (g_boolFirstSpawn[id])
			{
				print_color(id, "This server is running Base Builder v%s by Tirant", VERSION);
				show_zclass_menu(id, 0)
				g_boolFirstSpawn[id] = false
			}
			
			if (g_iNextClass[id] != g_iZombieClass[id])
				g_iZombieClass[id] = g_iNextClass[id]

			set_pev(id, pev_health, float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id]))/**g_fClassMultiplier[id][ATT_HEALTH]*/)
			set_pev(id, pev_gravity, Float:ArrayGetCell(g_zclass_grav, g_iZombieClass[id])/**g_fClassMultiplier[id][ATT_GRAVITY]*/)
			g_fPlayerSpeed[id] = float(ArrayGetCell(g_zclass_spd, g_iZombieClass[id]))/**g_fClassMultiplier[id][ATT_SPEED]*/
							
			static szClawModel[100]
			ArrayGetString(g_zclass_clawmodel, g_iZombieClass[id], szClawModel, charsmax(szClawModel))
			format(szClawModel, charsmax(szClawModel), "models/%s.mdl", szClawModel)
			entity_set_string( id , EV_SZ_viewmodel , szClawModel )  
			entity_set_string( id , EV_SZ_weaponmodel , "" ) 
						
			ArrayGetString(g_zclass_name, g_iZombieClass[id], g_szPlayerClass[id], charsmax(g_szPlayerClass[]))
			
			set_task(random_float(60.0, 360.0), "task_ZombieIdle", id+TASK_IDLESOUND, _, _, "b")

			ArrayGetString(g_zclass_playermodel, g_iZombieClass[id], g_szPlayerModel[id], charsmax(g_szPlayerModel[]))
			new szCurrentModel[32]
			fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel))
			if (!equal(szCurrentModel, g_szPlayerModel[id]))
			{
				if (get_gametime() - g_fRoundStartTime < 5.0)
					set_task(5.0 * MODELCHANGE_DELAY, "fm_user_model_update", id + TASK_MODELSET)
				else
					fm_user_model_update(id + TASK_MODELSET)
			}
			
			ExecuteForward(g_fwClassSet, g_fwDummyResult, id, g_iZombieClass[id]);
			
			if( cs_get_user_team(id) == CS_TEAM_T ){
				createBarHp(id)
			}
		}
		else if (g_isCustomModel[id])
		{
			fm_reset_user_model(id)
		}
		
		if (!g_isZombie[id])
		{
			entity_set_string(id, EV_SZ_viewmodel, human_knifemdl )  
			entity_set_string(id, EV_SZ_weaponmodel, "" ) 
			
			if (((/*g_boolPrepTime && */g_iPrepTime && !g_boolCanBuild) || (g_boolCanBuild && !g_iPrepTime)) && g_iGunsMenu)
			{
				//if (is_credits_active())
				#if defined BB_CREDITS
					credits_show_gunsmenu(id)
				#else
					show_method_menu(id)
				#endif
			}
			
			if (!g_iColor[id])
			{
				new i = random(MAX_COLORS-1)
				if (g_iColorMode)
				{
					while (g_iColorOwner[i])
					{
						i = random(MAX_COLORS-1)
					}
				}
				print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_PICKED", g_szColorName[i][ColorName]);
				g_iColor[id] = i
				g_iColorOwner[i] = id

				if (g_iOwnedEnt[id])
				{
					set_pev(g_iOwnedEnt[id],pev_rendercolor, g_fColor[g_iColor[id]] )
					set_pev(g_iOwnedEnt[id],pev_renderamt, g_fRenderAmt[g_iColor[id]] )
				}
			}
		}
		
		ev_Health(id);
		removeGlow(id);
		
		userNoClip[id] = false;
		userGodMod[id] = false;
		userAllowBuild[id] = false;
		SlowMove[id] = 0.0;
		if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT){
			userPlayerSpeed[id] = 260.0;
		}
	}
}

public createBarHp(id){	
	if( userBarHp[id] != 0 ) return 0;
	
	new ent = create_entity("info_target");
		

	if( !pev_valid(ent) ) return 0;
	
	set_pev(ent, pev_classname, "spriteBarHp");
	set_pev(ent, pev_frame, 0.0);
	set_pev(ent, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(ent, pev_solid, SOLID_NOT);
	set_pev(ent, pev_iuser1, id);
	
	if(access(id, FLAGS_BUILDBAN)){
		entity_set_model(ent, sprite_admin)	
		set_pev(ent, pev_scale, 0.1)
		set_pev(ent, pev_fuser1, 20.0)
	}else if(access(id, FLAGS_VIP)){
		entity_set_model(ent, sprite_vip)
		set_pev(ent, pev_scale, 0.2)
		set_pev(ent, pev_fuser1, 16.0)	
	}else{
		entity_set_model(ent, sprite_player)	
		set_pev(ent, pev_scale, 0.2)
		set_pev(ent, pev_fuser1, 22.0)
	}
	
	entity_set_int(ent, EV_INT_rendermode, 5);
	entity_set_float(ent, EV_FL_renderamt, 255.0);
	userBarHp[id] = ent;
	return ent;
}

public removeBarHp(id){
	new ent = userBarHp[id];
	
	if( ent == 0 ) return 0;
	if( !pev_valid(ent) ) return 0;
		
	remove_entity(ent);
	userBarHp[id]= 0;
	
	return 1;
}

public moveBarHp(id){
	
	new ent = userBarHp[id];
	new Float:maxhealth = float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id]))
	if( !pev_valid(ent) ) return 0;
		
	new Float:fOrigin[3];
	new Float:fSize[3];
	pev(id, pev_origin, fOrigin);
	pev(id, pev_maxs, fSize);
	fOrigin[2]+=floatabs(fSize[2])+5.0;
	set_pev(ent, pev_origin, fOrigin);
	
	new Float:percent=floatmin(float(get_user_health(id)), maxhealth)/maxhealth;
	new Float:frame= pev(ent, pev_fuser1)-(pev(ent, pev_fuser1)*percent);
	set_pev(ent, pev_frame, frame);
	
	return 1;
}

public ham_PlayerKilled_Post(victim) set_task(6.0, "respawn_join", victim)
public task_ZombieIdle(taskid)
{
	taskid-=TASK_IDLESOUND
	if (g_isAlive[taskid] && g_isConnected[taskid] && !g_isZombie[taskid])
		emit_sound(taskid, CHAN_VOICE, g_szZombieIdle[random(sizeof g_szZombieIdle - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public respawn_join(id) {
	if(is_user_connected(id) && !is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T)) 
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public fw_SetClientKeyValue(id, const infobuffer[], const szKey[])
{   
	if (g_isCustomModel[id] && equal(szKey, "model"))
		return FMRES_SUPERCEDE
	return FMRES_IGNORED
}

public fw_ClientUserInfoChanged(id)
{
	if (!g_isCustomModel[id])
		return FMRES_IGNORED
	static szCurrentModel[32]
	fm_get_user_model(id, szCurrentModel, charsmax(szCurrentModel))
	if (!equal(szCurrentModel, g_szPlayerModel[id]) && !task_exists(id + TASK_MODELSET))
		fm_set_user_model(id + TASK_MODELSET)
	return FMRES_IGNORED
}

public fm_user_model_update(taskid)
{
	static Float:fCurTime
	fCurTime = get_gametime()
	
	if (fCurTime - g_fModelsTargetTime >= MODELCHANGE_DELAY)
	{
		fm_set_user_model(taskid)
		g_fModelsTargetTime = fCurTime
	}
	else
	{
		set_task((g_fModelsTargetTime + MODELCHANGE_DELAY) - fCurTime, "fm_set_user_model", taskid)
		g_fModelsTargetTime += MODELCHANGE_DELAY
	}
}

public fm_set_user_model(player)
{
	player -= TASK_MODELSET
	engfunc(EngFunc_SetClientKeyValue, player, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", g_szPlayerModel[player])
	g_isCustomModel[player] = true
}

stock fm_get_user_model(player, model[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, player), "model", model, len)
}

stock fm_reset_user_model(player)
{
	g_isCustomModel[player] = false
	dllfunc(DLLFunc_ClientUserInfoChanged, player, engfunc(EngFunc_GetInfoKeyBuffer, player))
}

public message_show_menu(msgid, dest, id) 
{
	if (!(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))
		return PLUGIN_CONTINUE

	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE

	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public message_vgui_menu(msgid, dest, id) 
{
	if (get_msg_arg_int(1) != TEAM_SELECT_VGUI_MENU_ID || !(!get_user_team(id) && !is_user_bot(id) && !access(id, ADMIN_IMMUNITY)))// 
		return PLUGIN_CONTINUE
		
	static param_menu_msgid[2]
	param_menu_msgid[0] = msgid
	set_task(AUTO_TEAM_JOIN_DELAY, "task_force_team_join", id, param_menu_msgid, sizeof param_menu_msgid)

	return PLUGIN_HANDLED
}

public task_force_team_join(menu_msgid[], id) 
{
	if (get_user_team(id))
		return

	static msg_block
	msg_block = get_msg_block(menu_msgid[0])
	set_msg_block(menu_msgid[0], BLOCK_SET)
	engclient_cmd(id, "jointeam", "5")
	engclient_cmd(id, "joinclass", "5")
	set_msg_block(menu_msgid[0], msg_block)
	if( userReconnected[id] ){				
		cs_set_user_team(id, CS_TEAM_T);
	}
}

public msgTeamInfo(msgid, dest)
{
	if (dest != MSG_ALL && dest != MSG_BROADCAST)
		return;
	
	static id, team[2]
	id = get_msg_arg_int(1)

	get_msg_arg_string(2, team, charsmax(team))
	switch (team[0])
	{
		case 'T' : // TERRORIST
		{
			g_iCurTeam[id] = CS_TEAM_T;
		}
		case 'C' : // CT
		{
			g_iCurTeam[id] = CS_TEAM_CT;
		}
		case 'S' : // SPECTATOR
		{
			g_iCurTeam[id] = CS_TEAM_SPECTATOR;
		}
		default : g_iCurTeam[id] = CS_TEAM_UNASSIGNED;
	}
	if (!g_boolFirstTeam[id])
	{
		g_boolFirstTeam[id] = true
		g_iTeam[id] = g_iCurTeam[id]
	}
}

public clcmd_changeteam(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	
	if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
		return PLUGIN_CONTINUE;

	globalMenu(id)
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
	return PLUGIN_HANDLED
}
public clcmd2_buy(id)
{
	PlayerMenu(id);
	return PLUGIN_HANDLED
}

public blockCommand(id){
	return PLUGIN_HANDLED;
}

public msgStatusValue()
	set_msg_block(g_msgStatusText, BLOCK_SET);

public cmdSay(id)
{
	if (!g_isConnected[id])
		return PLUGIN_HANDLED;

	new szMessage[32]
	read_args(szMessage, charsmax(szMessage));
	remove_quotes(szMessage);
		
	if(szMessage[0] == '/')
	{
		if (equali(szMessage, "/commands") == 1 || equali(szMessage, "/cmd")  == 1 )
		{
			print_color(id, "%s /class, /respawn, /random, /mycolor, /guns%s%s%s", MODNAME, (g_iColorMode ? ", /whois <color>": ""), (g_iColorMode != 2 ? ", /colors":""), (access(id, FLAGS_LOCK) ? ", /lock":"")  );
		}
		else if (equali(szMessage, "/class") == 1)
		{
			show_zclass_menu(id, 0)
		}
		else if (equali(szMessage, "/respawn") == 1 || equali(szMessage, "/revive")  == 1 || equali(szMessage, "/fixspawn")  == 1)
		{
			if (g_boolCanBuild && !g_isZombie[id])
				ExecuteHamB(Ham_CS_RoundRespawn, id)
			else if (g_isZombie[id])
			{
				if (pev(id, pev_health) == float(ArrayGetCell(g_zclass_hp, g_iZombieClass[id])) || !is_user_alive(id))
					ExecuteHamB(Ham_CS_RoundRespawn, id)
				else
					client_print(id, print_center, "%L", LANG_SERVER, "FAIL_SPAWN");
			}
		}
		else if (equali(szMessage, "/lock") == 1 || equali(szMessage, "/claim") == 1 && g_isAlive[id])
		{
			if (access(id, FLAGS_LOCK))
				cmdLockBlock(id)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "FAIL_ACCESS");
			return PLUGIN_HANDLED;
		}
		else if (equal(szMessage, "/whois",6) && g_iColorMode)
		{
			for ( new i=0; i<MAX_COLORS; i++)
			{
				if (equali(szMessage[7], g_szColorName[i][ColorName]) == 1)
				{
					if (g_iColorOwner[i])
					{
						new szPlayerName[32]
						get_user_name(g_iColorOwner[i], szPlayerName, charsmax(szPlayerName))
						print_color(id, "%s^x04 %s^x01's color is^x04 %s", MODNAME, szPlayerName, g_szColorName[i][ColorName]);
					}
					else
						print_color(id, "%s %L^x04 %s", MODNAME, LANG_SERVER, "COLOR_NONE", g_szColorName[i][ColorName]);
						
					break;
				}
			}
		}
		else if (equali(szMessage, "/colors") == 1 && !g_isZombie[id] && g_boolCanBuild && g_iColorMode != 2)
		{
			show_colors_menu(id, 0)
		}
		else if( equal(szMessage, "/team", 8) || 0 <= contain(szMessage, "/dru") || 0 <= contain(szMessage, "/zap") || equal(szMessage, "/t")){
			teamOption(id);
			return PLUGIN_HANDLED;
		}
		else if (equali(szMessage, "/mycolor") == 1 && !g_isZombie[id])
		{
			print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_YOURS", g_szColorName[g_iColor[id]][ColorName]);
			return PLUGIN_HANDLED
		}
		else if (equali(szMessage, "/random") == 1 && !g_isZombie[id] && g_boolCanBuild)
		{
			new i = random(MAX_COLORS-1)
			if (g_iColorMode)
			{
				while (g_iColorOwner[i])
				{
					i = random(MAX_COLORS-1)
				}
			}
			print_color(id, "%s^x04 %L:^x01 %s", MODNAME, LANG_SERVER, "COLOR_RANDOM", g_szColorName[i][ColorName]);
			g_iColorOwner[g_iColor[id]] = 0
			g_iColor[id] = i
			g_iColorOwner[i] = id
			native_set_user_color(userTeam[id], i)
			
			for (new iEnt = g_iMaxPlayers+1; iEnt < MAXENTS; iEnt++)
			{
				if (is_valid_ent(iEnt) && g_iLockBlocks && BlockLocker(iEnt) == id)
					set_pev(iEnt,pev_rendercolor,g_fColor[g_iColor[id]])
			}
			
			ExecuteForward(g_fwNewColor, g_fwDummyResult, id, g_iColor[id]);
		}
		if(equal(szMessage, "/unstuck") || equal(szMessage, "/o") || equal(szMessage, "/uk")){
			cmdUnstuck(id);
			return PLUGIN_HANDLED;
		}
		else if (equali(szMessage, "/menu") == 1 || equali(szMessage, "/bb_menu") == 1)
		{
			globalMenu(id)
		}
		else if (equali(szMessage, "/guns", 5) && g_iGunsMenu)
		{
			if(!g_isAlive[id] || g_isZombie[id])
				return PLUGIN_HANDLED
				
			if (access(id, FLAGS_GUNS))
			{
				new player = cmd_target(id, szMessage[6], 0)
			
				if (!player)
				{
					//if (is_credits_active())
					#if defined BB_CREDITS
						credits_show_gunsmenu(id)
					#else
						show_method_menu(id)
					#endif
					return PLUGIN_CONTINUE
				}
				
				cmdGuns(id, player)
				return PLUGIN_HANDLED;
			}
			else
			{
				if(g_boolCanBuild || !g_boolRepick[id])
					return PLUGIN_HANDLED	
		
				//if (is_credits_active())
				#if defined BB_CREDITS
					credits_show_gunsmenu(id)
				#else
					show_method_menu(id)
				#endif
				return PLUGIN_HANDLED
			}
		}
		else if (equal(szMessage, "/swap",5) || equal(szMessage, "/sp",3) && access(id, FLAGS_SWAP))
		{
			new szName[33], szCommand[10];
			parse( szMessage,
				szCommand, 	sizeof(szCommand),
				szName, 		sizeof(szName)
			);
			new target = cmd_target(id, szName, 0);
			if (!target)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				userVarMenu[id] = 1;
				menuSpecifyUser(id, szName);
				return PLUGIN_CONTINUE
			}
			
			cmdSwap(id, target)
		}
		else if (equal(szMessage, "/revive", 7) || equal(szMessage, "/rv", 3) && access(id, FLAGS_REVIVE))
		{
			new szName[33], szCommand[10];
			parse( szMessage,
				szCommand, 	sizeof(szCommand),
				szName, 		sizeof(szName)
			);
			new target = cmd_target(id, szName, 0);
			if (!target)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				userVarMenu[id] = 0;
				menuSpecifyUser(id, szName);
				return PLUGIN_CONTINUE
			}
			
			cmdRevive(id, target)
		}
		else if (equal(szMessage, "/ban",4) && access(id, FLAGS_BUILDBAN))
		{
			new szName[33], szCommand[10];
			parse( szMessage,
				szCommand, 	sizeof(szCommand),
				szName, 		sizeof(szName)
			);
			new target = cmd_target(id, szName, 0);
			if (!target)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				userVarMenu[id] = 2;
				menuSpecifyUser(id, szName);
				return PLUGIN_CONTINUE
			}
			
			cmdBuildBan(id, target)
		}
		else if (equal(szMessage, "/releasezombies",5) || equal(szMessage, "/opendor",8) && access(id, FLAGS_RELEASE))
		{
			cmdStartRound(id)
		}
		else if (equali(szMessage, "/adminmenu") == 1 || equali(szMessage, "/a") == 1)
		{
			if (access(id, FLAGS_BUILDBAN))
				adminMenu(id)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "FAIL_ACCESS");
			return PLUGIN_HANDLED;
		}
		else if ( 0 <= contain(szMessage, "/tp") && access(id, FLAGS_BUILDBAN))
		{
			new szName[33], szCommand[10];
			parse( szMessage,
				szCommand, 	sizeof(szCommand),
				szName, 		sizeof(szName)
			);
			new target = cmd_target(id, szName, 0);
			if (!target)
			{
				print_color(id, "%s ^x01No such player was found", MODNAME)
				userVarMenu[id] = 3;
				menuSpecifyUser(id, szName);
				return PLUGIN_HANDLED;
			}
			userNoClip[id] = true;
			set_user_noclip(id, userNoClip[id]);
			adminMenu(id);
			new Float:fOrigin[3] = 0.0;
			pev(target, pev_origin, fOrigin);
			set_pev(id, pev_origin, fOrigin);
			
			Log("Admin [ %s ] teleports to the player [ %s ]", userName[id], userName[target])
			
			return PLUGIN_HANDLED;
		}
		else if (equali(szMessage, "/light") == 1 || equali(szMessage, "/nor") == 1)
		{
			if (access(id, FLAGS_FULLADMIN))
				light(id)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "FAIL_ACCESS");
			return PLUGIN_HANDLED;
		}
		else if ( equal(szMessage, "/hp", 3) && access(id, FLAGS_SWAP))
		{
			new szName[33], szCommand[10], szValue[11];
			parse( szMessage,
				szCommand, 	sizeof(szCommand),
				szName, 		sizeof(szName),
				szValue, sizeof(szValue)
			);
			new target = cmd_target(id, szName, 0);
			if (!target)
			{
				print_color(id, "%s Player^x04 %s^x01 could not be found or targetted", MODNAME, szMessage[6])
				return PLUGIN_CONTINUE
			}
			new gValue = str_to_num(szValue)
			if (!gValue)
			{
				print_color(id, "%s Enter how many you want to add", MODNAME)
				return PLUGIN_CONTINUE
			}
			set_user_health(target, get_user_health(target)+gValue)
			
			print_color(id, "%s You added^x04 %d HP^x01 Player^x04 %s", MODNAME, gValue, userName[target])
			print_color(target, "%s Admin^x04 %s^x01 Added you^x04 %d HP", MODNAME, userName[id], gValue)
			
			return PLUGIN_HANDLED;
		}
		else if (equali(szMessage, "/Old Friends") == 1 || equali(szMessage, "/Old player") == 1 || equali(szMessage, "/Oldplayer") == 1 || equali(szMessage, "/Oldplayer") == 1)
		{
			show_motd( id, "Old player.html" );
			return PLUGIN_HANDLED;
		}
		else if (equali(szMessage, "/c") == 1 || equali(szMessage, "/Create") == 1)
		{
			print_color(id, "^x03 Server By :^x04 AmirWolf");
			print_color(id, "^x03 Contact:^x04 T.me/Mr_Admins");
			return PLUGIN_HANDLED;
		}
		return PLUGIN_HANDLED_MAIN
	}
	return PLUGIN_CONTINUE
}

public cmdSwap(id, target)
{
	if (access(id, FLAGS_SWAP))
	{
		new player
		
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, charsmax(arg))
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}

		if (!player || !is_user_connected(player))
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			
		cs_set_user_team(player,( g_iTeam[player] = g_iTeam[player] == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T))
			
		if (is_user_alive(player))
			ExecuteHamB(Ham_CS_RoundRespawn, player)
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id, szAdminName, charsmax(szAdminName))
		get_user_authid (id, szAdminAuthid, charsmax(szAdminAuthid))
		get_user_name(player, szPlayerName, charsmax(szPlayerName))
		get_user_authid (player, szPlayerID, charsmax(szPlayerID))
		
		client_print(id, print_console, "[Base Builder] Player %s was swapped from the %s team to the %s team by %s", szPlayerName, g_iTeam[player] == CS_TEAM_CT ? "zombie":"builder", g_iTeam[player] == CS_TEAM_CT ? "builder":"zombie", szAdminName)
		Log("[SWAP] Admin: %s || SteamID: %s swapped Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_dhudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2)
		show_dhudmessage(player, "%L", LANG_SERVER, "ADMIN_SWAP");
		client_cmd(player, "mp3 play %s", TEAM_SWP)
		print_color(0, "%s Player^x04 %s^x01 has been^x04 swapped^x01 to the^x04 %s^x01 team by ^x04%s", MODNAME, szPlayerName, g_iTeam[player] == CS_TEAM_CT ? "builder":"zombie", szAdminName)
	}
	return PLUGIN_HANDLED	
}

public cmdRevive(id, target)
{
	if (access(id, FLAGS_REVIVE))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, charsmax(arg))
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}

		if (!player || !is_user_connected(player))
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			
		ExecuteHamB(Ham_CS_RoundRespawn, player)
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id, szAdminName, charsmax(szAdminName))
		get_user_authid (id, szAdminAuthid, charsmax(szAdminAuthid))
		get_user_name(player, szPlayerName, charsmax(szPlayerName))
		get_user_authid (player, szPlayerID, charsmax(szPlayerID))
		
		client_print(id, print_console, "[Base Builder] Player %s has been^x04 revived by %s", szPlayerName, szAdminName)
		Log("[REVIVE] Admin: %s || SteamID: %s revived Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_dhudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2)
		show_dhudmessage(player, "%L", LANG_SERVER, "ADMIN_REVIVE");
		client_cmd(player, "spk %s", RE_VEV)
		print_color(0, "%s Player^x04 %s^x01 has been^x04 revived^x01 by an admin by ^x04%s", MODNAME, szPlayerName, szAdminName)
	}
	return PLUGIN_HANDLED	
}

public cmdGuns(id, target)
{
	if (access(id, FLAGS_GUNS))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, charsmax(arg))
			player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
		}
		
		if (!player || !is_user_connected(player))
		{
			client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
			return PLUGIN_HANDLED;
		}
		
		if (g_isZombie[player])
		{
			return PLUGIN_HANDLED;
		}
		
		if (!g_isAlive[player])
		{
			client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_DEAD");
			return PLUGIN_HANDLED;
		}

		//if (is_credits_active())
		#if defined BB_CREDITS
			credits_show_gunsmenu(player)
		#else
			show_method_menu(player)
		#endif
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id, szAdminName, charsmax(szAdminName))
		get_user_authid (id, szAdminAuthid, charsmax(szAdminAuthid))
		get_user_name(player, szPlayerName, charsmax(szPlayerName))
		get_user_authid (player, szPlayerID, charsmax(szPlayerID))
		
		client_print(id, print_console, "[Base Builder] Player %s has had his weapons menu re-opened by %s", szPlayerName, szAdminName);
		Log("[GUNS] Admin: %s || SteamID: %s opened the guns menu for Player: %s || SteamID: %s", szAdminName, szAdminAuthid, szPlayerName, szPlayerID);
		
		set_dhudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2)
		show_dhudmessage(player, "%L", LANG_SERVER, "ADMIN_GUNS");
		
		print_color(0, "%s Player^x04 %s^x01 has had their^x04 guns^x01 menu^x04 re-opened by ^x04%s", MODNAME, szPlayerName, szAdminName)
	}
	return PLUGIN_HANDLED	
}

public cmdStartRound(id)
{
	if (access(id, FLAGS_RELEASE))
	{
		native_release_zombies()
	}
}

public Release_Zombies()
{
	g_boolCanBuild = false
	remove_task(TASK_BUILD);
	
	g_boolPrepTime = false
	remove_task(TASK_PREPTIME);
	
	new players[32], num, player, szWeapon[32]
	get_players(players, num, "a")
	for(new i = 0; i < num; i++)
	{
		player = players[i]

		if (!g_isZombie[player])
		{
			if (g_iOwnedEnt[player])
				cmdStopEnt(player)

			if(g_iGrenadeHE		) give_item(player,"weapon_hegrenade"	), cs_set_user_bpammo(player,CSW_HEGRENADE,	g_iGrenadeHE)
			if(g_iGrenadeFLASH	) give_item(player,"weapon_flashbang"	), cs_set_user_bpammo(player,CSW_FLASHBANG,	g_iGrenadeFLASH)
			if(g_iGrenadeSMOKE	) give_item(player,"weapon_smokegrenade"	), cs_set_user_bpammo(player,CSW_SMOKEGRENADE,	g_iGrenadeSMOKE)

			if (g_iPrimaryWeapon[player])
			{
				get_weaponname(g_iPrimaryWeapon[player],szWeapon,sizeof szWeapon - 1)
				engclient_cmd(player, szWeapon);
			}
			fade_user_screen(player, 0.5, 2.0, ScreenFade_Modulate, .r = random(256), .g = random(256), .b = random(256), .a = 90)
		}
	}
	
	set_dhudmessage(random_num(50, 255), random_num(50, 255), random_num(50, 255), -1.0, 0.24, 0, 1.0, 10.0, 0.1, 0.2)
	show_dhudmessage(0, "%L", LANG_SERVER, "RELEASE_ANNOUNCE");
	client_cmd(0, "spk %s", g_szRoundStart[ random( sizeof g_szRoundStart ) ] )
	
	set_task(12.0, "Play_Music", TASK_BUILD)
	
	ExecuteForward(g_fwRoundStart, g_fwDummyResult);
	
	makeBarrierNoSolid()
}

public fw_CmdStart( id, uc_handle, randseed )
{
	if (!g_isConnected[id] || !g_isAlive[id])
		return FMRES_IGNORED
		
	new button = get_uc( uc_handle , UC_Buttons );
	new oldbutton = pev(id, pev_oldbuttons)

	if( button & IN_USE && !(oldbutton & IN_USE) && !g_iOwnedEnt[id])
		cmdGrabEnt(id)
	else if( oldbutton & IN_USE && !(button & IN_USE) && g_iOwnedEnt[id])
		cmdStopEnt(id)
		
	if( userBarHp[id] != 0 && is_user_alive(id) ){
		if( cs_get_user_team(id) == CS_TEAM_T )
			moveBarHp(id);
		else removeBarHp(id);
	}
	
	if( userJetPack[ id ] ){
		if(g_boolCanBuild || (access(id, FLAGS_FULLADMIN))){	
			static Float:fVelo[ 3 ];
			VelocityByAim(id, userJetpackSpeed[id], fVelo );
			entity_set_vector(id , EV_VEC_velocity, fVelo );
			entity_set_int(id,EV_INT_sequence, 8 );	
		}
	}
	
	teamLineOrSprite(id);
	return FMRES_IGNORED;
}

public cmdGrabEnt(id)
{
	if (g_fBuildDelay[id] + BUILD_DELAY > get_gametime())
	{
		g_fBuildDelay[id] = get_gametime()
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_SPAM")
		return PLUGIN_HANDLED
	}
	else
		g_fBuildDelay[id] = get_gametime()

	if (g_isBuildBan[id])
	{
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_BANNED")
		client_cmd(id, "spk %s", LOCK_FAIL);
		return PLUGIN_HANDLED;
	}
	
	if (g_isZombie[id] && !access(id, FLAGS_OVERRIDE))
		return PLUGIN_HANDLED
		
	if (!g_boolCanBuild && !access(id, FLAGS_BUILD) && !access(id, FLAGS_OVERRIDE) && !userAllowBuild[id])
	{
		client_print (id, print_center, "%L", LANG_SERVER, "BUILD_NOTIME")
		return PLUGIN_HANDLED
	}
	
	if (g_iOwnedEnt[id] && is_valid_ent(g_iOwnedEnt[id])) 
		cmdStopEnt(id)
	
	new ent, bodypart
	get_user_aiming (id,ent,bodypart)
	
	if (!is_valid_ent(ent) || ent == g_iEntBarrier || is_user_alive(ent) || IsMovingEnt(ent))
		return PLUGIN_HANDLED;
	
	if ((BlockLocker(ent) && BlockLocker(ent) != id && BlockLocker(ent) != userTeam[id]) || (BlockLocker(ent) && !access(id, FLAGS_OVERRIDE)))
		return PLUGIN_HANDLED;
	
	new szClass[10], szTarget[7];
	entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
	entity_get_string(ent, EV_SZ_targetname, szTarget, charsmax(szTarget));
	/*if (access(id, FLAGS_BUILDBAN)){
		if(!isPlayer(ent) && (!equal(szClass, "func_wall") || equal(szTarget, "ignore")))
		return ent;
	}else*/if(!equal(szClass, "func_wall") || equal(szTarget, "ignore"))
			return ent;
		
	ExecuteForward(g_fwGrabEnt_Pre, g_fwDummyResult, id, ent);

	new Float:fOrigin[3], iAiming[3], Float:fAiming[3]
	
	get_user_origin(id, iAiming, 3);
	IVecFVec(iAiming, fAiming);
	entity_get_vector(ent, EV_VEC_origin, fOrigin);

	g_fOffset1[id] = fOrigin[0] - fAiming[0];
	g_fOffset2[id] = fOrigin[1] - fAiming[1];
	g_fOffset3[id] = fOrigin[2] - fAiming[2];
	
	g_fEntDist[id] = get_user_aiming(id, ent, bodypart);
	
	if(!isPlayer(ent) && ( userClone[id] || GetEntMover(ent) == 2 )){
		new cloneEnt = createClone(ent);
		if( is_valid_ent(ent) ){	
			ent = cloneEnt;
			if( userClaimed[id]>=limitBlocks ){
				return PLUGIN_CONTINUE
			}		
		}
		userClone[id]=false;
		userClaimed[id]++
	}
	if (g_fEntMinDist)
	{
		if (g_fEntDist[id] < g_fEntMinDist)
			g_fEntDist[id] = g_fEntSetDist;
	}
	else if (g_fEntMaxDist)
	{
		if (g_fEntDist[id] > g_fEntMaxDist)
			return PLUGIN_HANDLED
	}

	if(!isPlayer(ent) && (userMoverBlockColor[id] == BLOCK_COLOR)){
		set_pev(ent,pev_rendermode,kRenderTransColor)
		set_pev(ent,pev_rendercolor, Color_Random_Block[id] ? g_fColor[random(MAX_COLORS)] : g_fColor[g_iColor[id]])
		set_pev(ent,pev_renderamt, g_fRenderAmt[g_iColor[id]])
		
	}else if(userMoverBlockColor[id] == BLOCK_RENDER){
		set_pev(ent,pev_renderfx, kRenderFxNone);
		set_pev(ent,pev_rendermode,kRenderTransTexture);
		set_pev(ent,pev_renderamt, 200.0 );
		
	}else if(userMoverBlockColor[id] == BLOCK_NORENDER){
		set_pev(ent,pev_renderfx, kRenderFxNone);
		set_pev(ent,pev_rendermode,kRenderNormal);	
	}
		
	MovingEnt(ent);
	SetEntMover(ent, id);
	g_iOwnedEnt[id] = ent

	//Checked after object is successfully grabbed
	if (!g_boolCanBuild && (access(id, FLAGS_BUILD) || access(id, FLAGS_OVERRIDE)))
	{
		new adminauthid[32],adminname[32]
		get_user_authid (id,adminauthid,charsmax(adminauthid))
		get_user_name(id,adminname,charsmax(adminauthid))
		Log("[MOVE] Admin: %s || SteamID: %s moved an entity", adminname, adminauthid)
	}
	
	client_cmd(id, "spk %s", GRAB_START);
	
	ExecuteForward(g_fwGrabEnt_Post, g_fwDummyResult, id, ent);
	
	if(SlowMove[id] > 0)
		entity_get_vector(ent, EV_VEC_origin, OriginSave[id])
	
	if(AutoLockBlock[id]){
		LockBlock(ent, id)
		g_iOwnedEntities[id]++
		if(!userLockBlock[id]){
			set_pev(ent,pev_rendermode,kRenderTransColor)
		}else if(userLockBlock[id]){
			set_pev(ent,pev_renderfx,kRenderFxPulseSlowWide);
			set_pev(ent,pev_rendermode,kRenderTransColor)
		}
	}
		
	return PLUGIN_HANDLED
}

public cmdStopEnt(id)
{
	if (!g_iOwnedEnt[id])
		return PLUGIN_HANDLED;
		
	new ent = g_iOwnedEnt[id]
	
	ExecuteForward(g_fwDropEnt_Pre, g_fwDummyResult, id, ent);
	
	if (BlockLocker(ent))
	{
		switch(g_iLockBlocks)
		{
			case 0:
			{
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor, Float:{ LOCKED_COLOR })
				set_pev(ent,pev_renderamt,Float:{ LOCKED_RENDERAMT })
			}
			case 1:
			{
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor, Color_Random_Block[id] ? g_fColor[random(MAX_COLORS)] : g_fColor[g_iColor[id]])
				set_pev(ent,pev_renderamt,Float:{ LOCKED_RENDERAMT })
			}
		}
	}
	else
		set_pev(ent,pev_rendermode,kRenderNormal)	
	
	UnsetEntMover(ent);
	SetLastMover(ent,id);
	g_iOwnedEnt[id] = 0;
	UnmovingEnt(ent);
	
	client_cmd(id, "spk %s", GRAB_STOP);
	
	ExecuteForward(g_fwDropEnt_Post, g_fwDummyResult, id, ent);
	
	if(callfunc_begin("origin_check", "bbzones.amxx") == 1){
		callfunc_push_int(id)
		callfunc_push_int(ent)
		callfunc_end()
	}
	
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
		
	new ent, bodypart
	get_user_aiming (id,ent,bodypart)
	
	if (GetEntMover(ent) == 2)
	{
		return PLUGIN_HANDLED;
	}
	
	new szTarget[7], szClass[10];
	entity_get_string(ent, EV_SZ_targetname, szTarget, charsmax(szTarget));
	entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
	if (!ent || !is_valid_ent(ent) || is_user_alive(ent) || ent == g_iEntBarrier || !equal(szClass, "func_wall") || equal(szTarget, "ignore"))
		return PLUGIN_HANDLED;
	
	ExecuteForward(g_fwLockEnt_Pre, g_fwDummyResult, id, ent);
	
	switch (g_iLockBlocks)
	{
		case 0:
		{
			if (!BlockLocker(ent) && !IsMovingEnt(ent))
			{
				LockBlock(ent, id);
				set_pev(ent,pev_rendermode,kRenderTransColor)
				set_pev(ent,pev_rendercolor,Float:{LOCKED_COLOR})
				set_pev(ent,pev_renderamt,Float:{LOCKED_RENDERAMT})
				client_cmd(id, "spk %s", LOCK_OBJECT);
			}
			else if (BlockLocker(ent))
			{
				UnlockBlock(ent)
				set_pev(ent,pev_rendermode,kRenderNormal)
				client_cmd(id, "spk %s", LOCK_OBJECT);
			}
		}
		case 1:
		{
			if (!BlockLocker(ent) && !IsMovingEnt(ent))
			{
				if (g_iOwnedEntities[id]<g_iLockMax || !g_iLockMax)
				{
					LockBlock(ent, id)
					g_iOwnedEntities[id]++
					
					if(!userLockBlock[id]){
						set_pev(ent,pev_rendermode,kRenderTransColor)
						set_pev(ent,pev_rendercolor,Color_Random_Block[id] ? g_fColor[random(MAX_COLORS)] : g_fColor[g_iColor[id]])
						set_pev(ent,pev_renderamt,Float:{LOCKED_RENDERAMT})
					}else if(userLockBlock[id]){
						set_pev(ent,pev_renderfx,kRenderFxPulseSlowWide);
						set_pev(ent,pev_rendermode,kRenderTransColor)
						set_pev(ent,pev_rendercolor,Color_Random_Block[id] ? g_fColor[random(MAX_COLORS)] : g_fColor[g_iColor[id]])
						set_pev(ent,pev_renderamt,Float:{LOCKED_RENDERAMT})
					}
					
					client_print(id, print_center, "%L [ %d / %d ]", LANG_SERVER, "BUILD_CLAIM_NEW", g_iOwnedEntities[id], g_iLockMax)
					client_cmd(id, "spk %s", LOCK_OBJECT);
				}
				else if (g_iOwnedEntities[id]>=g_iLockMax)
				{
					client_print(id, print_center, "%L", LANG_SERVER, "BUILD_CLAIM_MAX", g_iLockMax)
					client_cmd(id, "spk %s", LOCK_FAIL);
				}
			}
			else if (BlockLocker(ent))
			{
				if (BlockLocker(ent) == id || access(id, FLAGS_OVERRIDE))
				{
					g_iOwnedEntities[BlockLocker(ent)]--
					set_pev(ent,pev_renderfx, kRenderFxNone)
					set_pev(ent,pev_rendermode,kRenderNormal)
					
					client_print(BlockLocker(ent), print_center, "%L [ %d / %d ]", LANG_SERVER, "BUILD_CLAIM_LOST", g_iOwnedEntities[BlockLocker(ent)], g_iLockMax)
					
					UnlockBlock(ent)
					client_cmd(id, "spk %s", LOCK_OBJECT);
				}
				else
				{
					client_print(id, print_center, "%L", LANG_SERVER, "BUILD_CLAIM_FAIL")
					client_cmd(id, "spk %s", LOCK_FAIL);
				}
			}	
		}
	}
	
	ExecuteForward(g_fwLockEnt_Post, g_fwDummyResult, id, ent);
	
	return PLUGIN_HANDLED
}

public cmdBuildBan(id, target)
{
	if (access(id, FLAGS_BUILDBAN))
	{
		new player
		if (target) player = target
		else
		{
			new arg[32]
			read_argv(1, arg, charsmax(arg))
			player = cmd_target(id, arg, CMDTARGET_OBEY_IMMUNITY)
		}
		
		if (!player)
			return client_print(id, print_console, "[Base Builder] %L", LANG_SERVER, "FAIL_NAME");
		
		new szAdminAuthid[32],szAdminName[32],szPlayerName[32],szPlayerID[32]
		get_user_name(id, szAdminName, charsmax(szAdminName))
		get_user_authid (id, szAdminAuthid, charsmax(szAdminAuthid))
		get_user_name(player, szPlayerName, charsmax(szPlayerName))
		get_user_authid (player, szPlayerID, charsmax(szPlayerID))
		
		g_isBuildBan[player] = g_isBuildBan[player] ? false : true
		
		if (g_isBuildBan[player] && g_iOwnedEnt[player])
			cmdStopEnt(player)
		
		client_print(id, print_console, "[Base Builder] Player %s was %s from building by %s", szPlayerName, g_isBuildBan[player] ? "banned":"unbanned", szAdminName)
		Log("[MOVE] Admin: %s || SteamID: %s banned Player: %s || SteamID: %s from building", szAdminName, szAdminAuthid, szPlayerName, szPlayerID)
		
		set_dhudmessage(255,0, 0, -1.0, 0.45, 0, 1.0, 10.0, 0.1, 0.2)
		show_dhudmessage(player, "%L", LANG_SERVER, "ADMIN_BUILDBAN", g_isBuildBan[player] ? "disabled":"re-enabled");
		
		if(g_isBuildBan[player])
		{
			set_user_rendering(player, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
			set_rendering(player, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5)
			fade_user_screen(player, .r = 255, .g = 0, .b = 0)
			shake_user_screen(player)
			client_cmd(player, "spk %s", BAN_BUILD)
		}
		else
		{
			set_user_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 25)
			set_rendering(player, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
			fade_user_screen(player, .r = 255, .g = 255, .b = 255)
			client_cmd(player, "spk %s", UNBAN_BUILD)
		}
		
		print_color(0, "%s Player^x04 %s^x01 has been^x04 %s^x01 from building by ^x04%s", MODNAME, szPlayerName, g_isBuildBan[player] ? "banned":"unbanned", szAdminName)
	}
	
	return PLUGIN_HANDLED;
}

public fw_PlayerPreThink(id)
{
	if (!is_user_connected(id))
	{
		cmdStopEnt(id)
		return PLUGIN_HANDLED
	}
	
	if (!g_iOwnedEnt[id] || !is_valid_ent(g_iOwnedEnt[id]))
		return FMRES_HANDLED
		
	new buttons = pev(id, pev_button)
	if (buttons & IN_ATTACK)
	{
		g_fEntDist[id] += OBJECT_PUSHPULLRATE;
		
		if (g_fEntDist[id] > g_fEntMaxDist)
		{
			g_fEntDist[id] = g_fEntMaxDist
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MAX")
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PUSH")
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 1);
	}
	else if (buttons & IN_ATTACK2)
	{
		g_fEntDist[id] -= OBJECT_PUSHPULLRATE;
			
		if (g_fEntDist[id] < g_fEntSetDist)
		{
			g_fEntDist[id] = g_fEntSetDist
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_MIN")
		}
		else
			client_print(id, print_center, "%L", LANG_SERVER, "OBJECT_PULL")
			
		ExecuteForward(g_fwPushPull, g_fwDummyResult, id, g_iOwnedEnt[id], 2);
	}
	
	new iOrigin[3], iLook[3], Float:fOrigin[3], Float:fLook[3], Float:vMoveTo[3], Float:fLength
	    
	get_user_origin(id, iOrigin, 1);
	IVecFVec(iOrigin, fOrigin);
	get_user_origin(id, iLook, 3);
	IVecFVec(iLook, fLook);
	    
	fLength = get_distance_f(fLook, fOrigin);
	if (fLength == 0.0) fLength = 1.0;

	vMoveTo[0] = (fOrigin[0] + (fLook[0] - fOrigin[0]) * g_fEntDist[id] / fLength) + g_fOffset1[id];
	vMoveTo[1] = (fOrigin[1] + (fLook[1] - fOrigin[1]) * g_fEntDist[id] / fLength) + g_fOffset2[id];
	vMoveTo[2] = (fOrigin[2] + (fLook[2] - fOrigin[2]) * g_fEntDist[id] / fLength) + g_fOffset3[id];
	vMoveTo[2] = float(floatround(vMoveTo[2], floatround_floor));

	if(SlowMove[id] > 0){
		new Float:vMoved[3];
		vMoved[0]	=	OriginSave[id][0]+((vMoveTo[0]-OriginSave[id][0])/SlowMove[id])
		vMoved[1]	=	OriginSave[id][1]+((vMoveTo[1]-OriginSave[id][1])/SlowMove[id])
		vMoved[2]	=	OriginSave[id][2]+((vMoveTo[2]-OriginSave[id][2])/SlowMove[id])
		
		entity_set_origin(g_iOwnedEnt[id], vMoved)
	}else entity_set_origin(g_iOwnedEnt[id], vMoveTo);
	
	return FMRES_HANDLED
}

public fw_Traceline(Float:start[3], Float:end[3], conditions, id, trace)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED
	
	new ent = get_tr2(trace, TR_pHit)
	
	if (is_valid_ent(ent))
	{
		new ent,body
		new gText[256], iLen;
		
		get_user_aiming(id,ent,body)
		
		new szClass[10], szTarget[7];
		entity_get_string(ent, EV_SZ_classname, szClass, charsmax(szClass));
		entity_get_string(ent, EV_SZ_targetname, szTarget, charsmax(szTarget));
		if (equal(szClass, "func_wall") && !equal(szTarget, "ignore") && ent != g_iEntBarrier && g_iShowMovers == 1)
		{
			if (g_boolCanBuild || access(id, FLAGS_INFOR))
			{
				set_hudmessage(0, 255, 255, -1.0, 0.16, 0, 0.1, 0.1, 0.1, 0.1);
				new szCurMover[32], szLastMover[32]
				if( userClone[id] ) iLen += format(gText[iLen], sizeof(gText)-1-iLen, "-- F --^n");
			
				if (GetLastMover(ent) == 0 || !GetEntMover(ent) && !GetLastMover(ent))
					iLen += format(gText[iLen], sizeof(gText)-1-iLen, "-- ! --");
				else if (GetEntMover(ent))
				{
					get_user_name(GetEntMover(ent),szCurMover,charsmax(szCurMover))
					if (!GetLastMover(ent))
						iLen += format(gText[iLen], sizeof(gText)-1-iLen, "[ %s ]", szCurMover);
				}
				if (GetLastMover(ent))
				{
					get_user_name(GetLastMover(ent),szLastMover,charsmax(szLastMover))
					if (!GetEntMover(ent))
						iLen += format(gText[iLen], sizeof(gText)-1-iLen, "[ %s ]", szLastMover);
				}
				if (GetEntMover(ent) && GetLastMover(ent))
				{
					if (getRotateBlock(ent, 0)) iLen += format(gText[iLen], sizeof(gText)-1-iLen,  "-- Q --^n");
					iLen += format(gText[iLen], sizeof(gText)-1-iLen, "[ %s ]^n[ %s ]", szCurMover, szLastMover);
				}
				if(SlowMove[id]) iLen += format(gText[iLen], sizeof(gText)-iLen-1, "^n[ %s ]", SlowMove[id] > 0 ? formatm("%d Times Slower", floatround(SlowMove[id])) : "");
				
				show_hudmessage(id, "%s", gText)
            }
		}
		if(isPlayer(ent)){
		
			if( is_user_connected(ent) && is_user_alive(ent)){

				if (!g_isZombie[ent]) set_hudmessage(25, 125, 255, -1.0, 0.20, 0, 0.1, 0.1, 0.1, 0.1)	;
				else set_hudmessage(255, 125, 25, -1.0, 0.20, 0, 0.1, 0.1, 0.1, 0.1);
				
				if (!g_isZombie[ent]) iLen += format(gText[iLen], sizeof(gText)-iLen-1, "[ Name: %s %s Health: %d ]^n[ Color: %s ]", userName[ent], symbolsCustom[SYMBOL_VERTICAL_LINE], pev(ent, pev_health), g_szColorName[g_iColor[ent]][ColorName]);
				else iLen += format(gText[iLen], sizeof(gText)-iLen-1, "[ Name: %s | Health: %d ]^n[ Class: %s ]", userName[ent], pev(ent, pev_health), g_szPlayerClass[ent]);
				iLen += format(gText[iLen], sizeof(gText)-iLen-1, "^n~ [ AFK: %0.2f%% ] ~", userAfkValue[ ent ]);
				if (teamWorks(id)) iLen += format(gText[iLen], sizeof(gText)-iLen-1, "^n%s [ TEAM ] %s", symbolsCustom[SYMBOL_DR_ARROW], symbolsCustom[SYMBOL_DL_ARROW]);
				
				show_hudmessage(id, "%s", gText);
			}
		}
	}

	return PLUGIN_HANDLED
}

public fw_EmitSound(id,channel,const sample[],Float:volume,Float:attn,flags,pitch)
{
	if (!is_user_connected(id) || g_boolCanBuild || g_boolPrepTime || g_boolRoundEnded)
		return FMRES_IGNORED;
		
	if(g_isZombie[id]){
		if(equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
		{
			emit_sound(id,channel,g_szZombieDie[random(sizeof g_szZombieDie - 1)],volume,attn,flags,pitch)
			return FMRES_SUPERCEDE
		}
	
		if(equal(sample[7], "bhit", 4))
		{
			emit_sound(id,channel,g_szZombiePain[random(sizeof g_szZombiePain - 1)],volume,attn,flags,pitch)
			return FMRES_SUPERCEDE
		}
	
		// Zombie attacks with knife
		if (equal(sample[8], "kni", 3))
		{
			if (equal(sample[14], "sla", 3)) // slash
			{
				emit_sound(id,channel,g_szZombieMiss[random(sizeof g_szZombieMiss - 1)],volume,attn,flags,pitch)
				return FMRES_SUPERCEDE;
			}
			if (equal(sample[14], "hit", 3)) // hit
			{
				if (sample[17] == 'w') // wall
				{
					emit_sound(id,channel,g_szZombieHit[random(sizeof g_szZombieHit - 1)],volume,attn,flags,pitch)
					return FMRES_SUPERCEDE;
				}
				else
				{
					emit_sound(id,channel,g_szZombieHit[random(sizeof g_szZombieHit - 1)],volume,attn,flags,pitch)
					return FMRES_SUPERCEDE;
				}
			}
			if (equal(sample[14], "sta", 3)) // stab
			{
				emit_sound(id,channel,g_szZombieMiss[random(sizeof g_szZombieMiss - 1)],volume,attn,flags,pitch)
				return FMRES_SUPERCEDE;
			}
		}
	}
	else
	{
		if (equal(sample[7], "bhit", 4))
		{
			engfunc(EngFunc_EmitSound, id, channel, Pain[random(sizeof Pain - 1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	
		if (equal(sample[7], "die", 3) || equal(sample[7], "dea", 3))
		{
			engfunc(EngFunc_EmitSound, id, channel, Dead[random(sizeof Dead - 1)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED
}

public Slower_blocks(id){
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT && (g_boolCanBuild || g_boolPrepTime))
	{
		SlowMove[id] += 2.0
		if( SlowMove[id] >= 6.0 ){
			SlowMove[id] = 0.0;
			print_color(id, "%s ^x03'T'^x04 You move the blocks ^x01Normally", MODNAME)
		}else{
			print_color(id, "%s ^x03'T'^x04 Blocks move ^x01%d^x04 times slower", MODNAME, floatround(SlowMove[id]) )
		}
	}
	return PLUGIN_HANDLED
}

public fw_Suicide(id) return FMRES_SUPERCEDE

public show_colors_menu(id, item)
{
	new menu=menu_create("\d|\y*\d| \rSelect Your Color\d: \y", "colors_pushed")
	
	for( new i = 0; i<sizeof(g_szColorName); i ++ )
		menu_additem(menu, g_szColorName[i][ColorName], g_szColorName[i][ColorInfo], g_szColorName[i][ColorFlagAdmin])
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE
}

public colors_pushed(id, menu, item){
	if( item == MENU_EXIT ){
		menu_destroy(menu)
		return PLUGIN_CONTINUE
	}

	// Get the color info for the selected item.
	new iAccess, szInfo[2], hCallback;
	menu_item_getinfo(menu, item, iAccess, szInfo, 1, _, _, hCallback);

	// Set the color random flag for the player and their team.
	Color_Random_Block[id] = szInfo[0] == '*';
	Color_Random_Block[userTeam[id]] = szInfo[0] == '*';

	// Set the player's color.
	g_iColor[id] = item;

	// Set the team color.
	g_iColor[userTeam[id]] = item;

	// Print a message to the player.
	print_color(id, "%s You have picked^x04 %s^x01 as your color", MODNAME, g_szColorName[g_iColor[id]][ColorName]);

	// Execute the new color forward.
	ExecuteForward(g_fwNewColor, g_fwDummyResult, id, g_iColor[id]);

	return PLUGIN_CONTINUE
}

public show_zclass_menu(id,offset)
{
	if(offset<0) offset = 0

	new keys, curnum, menu[512], szCache1[32], szCache2[32], iCache3
	for(new i=offset;i<g_iZClasses;i++)
	{
		ArrayGetString(g_zclass_name, i, szCache1, charsmax(szCache1))
		ArrayGetString(g_zclass_info, i, szCache2, charsmax(szCache2))
		iCache3 = ArrayGetCell(g_zclass_admin, i)
		
		// Add to menu
		if (i == g_iZombieClass[id])
			format(menu, charsmax(menu), "%s^n\d|\r%d\d| \d%s \r[ \y%s \r] \r[ \d%s \r]", menu, curnum+1, szCache1, szCache2, iCache3 == ADMIN_ALL ? "Selected" : "Selected")
		else
			format(menu, charsmax(menu), "%s^n\d|\r%d\d| \w%s \r[ \d%s \r] \r[ %s%s ]", menu, curnum+1, szCache1, szCache2, (get_user_flags(id) & iCache3) ? "Un" : "", iCache3 == ADMIN_ALL ? "UnLocked" : "Locked")
		
		g_iMenuOptions[id][curnum] = i
		keys += (1<<curnum)
	
		curnum++
		
		if(curnum==8)
			break;
	}

	format(menu, charsmax(menu), "\d|\r*\d| \rSelect Your Class\d:^n\w%s^n", menu)
	if(curnum==8 && offset<12)
	{
		keys += (1<<8)
		format(menu, charsmax(menu), "%s^n\d|\r9\d| \wNext",menu)
	}
	keys += (1<<9)
	if(offset)
		format(menu,511,"%s^n\d|\r0\d| \wBack",menu)
	else
		format(menu,511,"%s^n\d|\r0\d| \wExit",menu)
	
	show_menu(id,keys,menu,-1,"ZClassSelect")
}

public zclass_pushed(id,szKey)
{
	if(szKey<8)
	{
		if (g_iMenuOptions[id][szKey] == g_iZombieClass[id])
		{
			client_cmd(id, "spk %s", LOCK_FAIL);
			
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_CURRENT")
			show_zclass_menu(id,g_iMenuOffset[id])
			return ;
		}
		
		new iCache3 = ArrayGetCell(g_zclass_admin, g_iMenuOptions[id][szKey])
		
		if ((iCache3 != ADMIN_ALL || !iCache3) && !access(id, iCache3))
		{
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_NO_ACCESS")
			show_zclass_menu(id,g_iMenuOffset[id])
			return ;
		}
		
		g_iNextClass[id] = g_iMenuOptions[id][szKey]
	
		new szCache1[32]
		ArrayGetString(g_zclass_name, g_iMenuOptions[id][szKey], szCache1, charsmax(szCache1))
		
		if (!g_isZombie[id] || (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime)))
			print_color(id, "%s You have selected^x04 %s^x01 as your next class", MODNAME, szCache1)
		if (!g_isAlive[id])
			print_color(id, "%s %L", MODNAME, LANG_SERVER, "CLASS_RESPAWN")
		g_iMenuOffset[id] = 0
		
		if (g_isZombie[id] && (g_boolCanBuild || g_boolPrepTime))
			ExecuteHamB(Ham_CS_RoundRespawn, id)
			
		ExecuteForward(g_fwClassPicked, g_fwDummyResult, id, g_iZombieClass[id]);
	}
	else
	{
		if(szKey==8)
			g_iMenuOffset[id] += 8
		if(szKey==9) {
            if(!g_iMenuOffset[id])
                return;
            else
                g_iMenuOffset[id] -= 8
        }
	}

	return ;
}

/*------------------------------------------------------------------------------------------------*/
public show_method_menu(id)
{
	if(g_boolFirstTime[id])
	{
		g_boolFirstTime[id] = false
		show_primary_menu(id,0)
	}
	else
	{
		g_iMenuOffset[id] = 0
		show_menu(id,(1<<0)|(1<<1),"\d|\r*\d| \rChoose Your Weapon^n^n\d|\r1\d| \wNew Guns^n\d|\r2\d| \wLast Guns",-1,"WeaponMethodMenu")
	}
}

public weapon_method_pushed(id,szKey)
{
	switch(szKey)
	{
		case 0: show_primary_menu(id,0)
		case 1: give_weapons(id)
	}
	return ;
}

public show_primary_menu(id,offset)
{
	if(offset<0) offset = 0

	new flags = read_flags(g_pcvar_allowedweps)

	new keys, curnum, menu[512]
	for(new i=offset;i<19;i++)
	{
		if(flags & power(2,i))
		{
			g_iMenuOptions[id][curnum] = i
			keys += (1<<curnum)
	
			curnum++
			format(menu, charsmax(menu), "%s^n\d|\r%d\d| \w%s",menu,curnum,szWeaponNames[i])
	
			if(curnum==8)
				break;
		}
	}

	format(menu, charsmax(menu), "\d|\y*\d| \rPrimary Weapon\d:\w^n%s^n",menu)
	if(curnum==8 && offset<12)
	{
		keys += (1<<8)
		format(menu, charsmax(menu), "%s^n\d|\r9\d| \wNext",menu)
	}
	if(offset)
	{
		keys += (1<<9)
		format(menu, charsmax(menu), "%s^n\d|\r0\d| \wBack",menu)
	}

	show_menu(id,keys,menu,-1,"PrimaryWeaponSelect")
}

public prim_weapons_pushed(id,szKey)
{
	if(szKey<8)
	{
		g_iWeaponPicked[0][id] = g_iMenuOptions[id][szKey]
		g_iMenuOffset[id] = 0
		show_secondary_menu(id,0)
	}
	else
	{
		if(szKey==8)
			g_iMenuOffset[id] += 8
		if(szKey==9)
			g_iMenuOffset[id] -= 8
		show_primary_menu(id,g_iMenuOffset[id])
	}
	return ;
}

public show_secondary_menu(id,offset)
{
	if(offset<0) offset = 0

	new flags = read_flags(g_pcvar_allowedweps)

	new keys, curnum, menu[512]
	for(new i=18;i<24;i++)
	{
		if(flags & power(2,i))
		{
			g_iMenuOptions[id][curnum] = i
			keys += (1<<curnum)
	
			curnum++
			format(menu, charsmax(menu), "%s^n\d|\r%d\d| \w%s",menu,curnum,szWeaponNames[i])
		}
	}

	format(menu, charsmax(menu), "\d|\y*\d| \rSecondary Weapon\d:\w^n%s",menu)

	show_menu(id,keys,menu,-1,"SecWeaponSelect")
}

public sec_weapons_pushed(id,szKey)
{
	if(szKey<8)
	{
		g_iWeaponPicked[1][id] = g_iMenuOptions[id][szKey]
	}
	give_weapons(id)
	return ;
}

public give_weapons(id)
{
	strip_user_weapons(id)
	give_item(id,"weapon_knife")
   
	new szWeapon[32], csw
	csw = csw_contant(g_iWeaponPicked[0][id])
	get_weaponname(csw,szWeapon,charsmax(szWeapon))
	give_item(id,szWeapon)
	cs_set_user_bpammo(id,csw,999)
	g_iPrimaryWeapon[id] = csw

	csw = csw_contant(g_iWeaponPicked[1][id])
	get_weaponname(csw,szWeapon,charsmax(szWeapon))
	give_item(id,szWeapon)
	cs_set_user_bpammo(id,csw,999)
	
	g_boolRepick[id] = false
}

stock csw_contant(weapon)
{
	new num = 29
	switch(weapon)
	{
		case 0: num = 3
		case 1: num = 5
		case 2: num = 7
		case 3: num = 8
		case 4: num = 12
		case 5: num = 13
		case 6: num = 14
		case 7: num = 15
		case 8: num = 18
		case 9: num = 19
		case 10: num = 20
		case 11: num = 21
		case 12: num = 22
		case 13: num = 23
		case 14: num = 24
		case 15: num = 27
		case 16: num = 28
		case 17: num = 30
		case 18: num = 1
		case 19: num = 10
		case 20: num = 11
		case 21: num = 16
		case 22: num = 17
		case 23: num = 26
		case 24:
		{
			new flags = read_flags(g_pcvar_allowedweps)
			do
			{
				num = random_num(0,18)
				if(!(num & flags))
				{
					num = -1
				}
			}
			while(num==-1)
			num = csw_contant(num)
		}
		case 25:
		{
			new flags = read_flags(g_pcvar_allowedweps)
			do
			{
				num = random_num(18,23)
				if(!(num & flags))
				{
					num = -1
				}
			}
			while(num==-1)
			num = csw_contant(num)
		}
	}
	return num;
}

Log(const message_fmt[], any:...)
{
	static message[256];
	vformat(message, sizeof(message) - 1, message_fmt, 2);
	
	static filename[96];
	static dir[64];
	if( !dir[0] )
	{
		get_basedir(dir, sizeof(dir) - 1);
		add(dir, sizeof(dir) - 1, "/logs");
	}
	
	format_time(filename, sizeof(filename) - 1, "%m-%d-%Y");
	format(filename, sizeof(filename) - 1, "%s/BaseBuilder_%s.log", dir, filename);
	
	log_to_file(filename, "%s", message);
}

print_color(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	// Send to everyone
	if (!target)
	{
		static player
		for (player = 1; player <= g_iMaxPlayers; player++)
		{
			// Not connected
			if (!g_isConnected[player])
				continue;
			
			// Remember changed arguments
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// Replace LANG_PLAYER with player id
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format message for player
			vformat(buffer, charsmax(buffer), message, 3)
			
			// Send it
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// Replace back player id's with LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// Send to specific target
	else
	{
		// Format message for player
		vformat(buffer, charsmax(buffer), message, 3)
		
		// Send it
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

stock fm_cs_get_current_weapon_ent(id)
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);

public native_register_zombie_class(const name[], const info[], const model[], const clawmodel[], hp, speed, Float:gravity, Float:knockback, adminflags, credits)
{
	if (!g_boolArraysCreated)
		return 0;
		
	// Strings passed byref
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	
	// Add the class
	ArrayPushString(g_zclass_name, name)
	ArrayPushString(g_zclass_info, info)
	
	ArrayPushCell(g_zclass_modelsstart, ArraySize(g_zclass_playermodel))
	ArrayPushString(g_zclass_playermodel, model)
	ArrayPushCell(g_zclass_modelsend, ArraySize(g_zclass_playermodel))
	ArrayPushCell(g_zclass_modelindex, -1)
	
	ArrayPushString(g_zclass_clawmodel, clawmodel)
	ArrayPushCell(g_zclass_hp, hp)
	ArrayPushCell(g_zclass_spd, speed)
	ArrayPushCell(g_zclass_grav, gravity)
	ArrayPushCell(g_zclass_admin, adminflags)
	ArrayPushCell(g_zclass_credits, credits)
	
	// Set temporary new class flag
	ArrayPushCell(g_zclass_new, 1)
	
	// Override zombie classes data with our customizations
	new i, k, buffer[32], Float:buffer2, nummodels_custom, nummodels_default, prec_mdl[100], size = ArraySize(g_zclass2_realname)
	for (i = 0; i < size; i++)
	{
		ArrayGetString(g_zclass2_realname, i, buffer, charsmax(buffer))
		
		// Check if this is the intended class to override
		if (!equal(name, buffer))
			continue;
		
		// Remove new class flag
		ArraySetCell(g_zclass_new, g_iZClasses, 0)
		
		// Replace caption
		ArrayGetString(g_zclass2_name, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_name, g_iZClasses, buffer)
		
		// Replace info
		ArrayGetString(g_zclass2_info, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_info, g_iZClasses, buffer)
		
		nummodels_custom = ArrayGetCell(g_zclass2_modelsend, i) - ArrayGetCell(g_zclass2_modelsstart, i)
		nummodels_default = ArrayGetCell(g_zclass_modelsend, g_iZClasses) - ArrayGetCell(g_zclass_modelsstart, g_iZClasses)
			
		// Replace each player model and model index
		for (k = 0; k < min(nummodels_custom, nummodels_default); k++)
		{
			ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
			ArraySetString(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, buffer)
				
			// Precache player model and replace its modelindex with the real one
			formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
			ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k, engfunc(EngFunc_PrecacheModel, prec_mdl))
		}
			
		// We have more custom models than what we can accommodate,
		// Let's make some space...
		if (nummodels_custom > nummodels_default)
		{
			for (k = nummodels_default; k < nummodels_custom; k++)
			{
				ArrayGetString(g_zclass2_playermodel, ArrayGetCell(g_zclass2_modelsstart, i) + k, buffer, charsmax(buffer))
				ArrayInsertStringAfter(g_zclass_playermodel, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, buffer)
				
				// Precache player model and retrieve its modelindex
				formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", buffer, buffer)
				ArrayInsertCellAfter(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses) + k - 1, engfunc(EngFunc_PrecacheModel, prec_mdl))
			}
				
			// Fix models end index for this class
			ArraySetCell(g_zclass_modelsend, g_iZClasses, ArrayGetCell(g_zclass_modelsend, g_iZClasses) + (nummodels_custom - nummodels_default))
		}
		
		// Replace clawmodel
		ArrayGetString(g_zclass2_clawmodel, i, buffer, charsmax(buffer))
		ArraySetString(g_zclass_clawmodel, g_iZClasses, buffer)
		
		// Precache clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", buffer)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
		
		// Replace health
		buffer[0] = ArrayGetCell(g_zclass2_hp, i)
		ArraySetCell(g_zclass_hp, g_iZClasses, buffer[0])
		
		// Replace speed
		buffer[0] = ArrayGetCell(g_zclass2_spd, i)
		ArraySetCell(g_zclass_spd, g_iZClasses, buffer[0])
		
		// Replace gravity
		buffer2 = Float:ArrayGetCell(g_zclass2_grav, i)
		ArraySetCell(g_zclass_grav, g_iZClasses, buffer2)
		
		// Replace admin flags
		buffer2 = ArrayGetCell(g_zclass2_admin, i)
		ArraySetCell(g_zclass_admin, g_iZClasses, buffer2)
	
		// Replace credits
		buffer2 = ArrayGetCell(g_zclass2_credits, i)
		ArraySetCell(g_zclass_credits, g_iZClasses, buffer2)
	}
	
	// If class was not overriden with customization data
	if (ArrayGetCell(g_zclass_new, g_iZClasses))
	{
		// Precache default class model and replace modelindex with the real one
		formatex(prec_mdl, charsmax(prec_mdl), "models/player/%s/%s.mdl", model, model)
		ArraySetCell(g_zclass_modelindex, ArrayGetCell(g_zclass_modelsstart, g_iZClasses), engfunc(EngFunc_PrecacheModel, prec_mdl))
		
		// Precache default clawmodel
		formatex(prec_mdl, charsmax(prec_mdl), "models/%s.mdl", clawmodel)
		engfunc(EngFunc_PrecacheModel, prec_mdl)
	}

	g_iZClasses++
	
	return g_iZClasses-1
}

public native_get_class_cost(classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return -1;
	
	return ArrayGetCell(g_zclass_credits, classid)
}

public native_get_user_zombie_class(id) return g_iZombieClass[id];
public native_get_user_next_class(id) return g_iNextClass[id];
public native_set_user_zombie_class(id, classid)
{
	if (classid < 0 || classid >= g_iZClasses)
		return 0;
	
	g_iNextClass[id] = classid
	return 1;
}

public native_is_user_zombie(id) return g_isZombie[id]
public native_is_user_banned(id) return g_isBuildBan[id]

public native_bool_buildphase() return g_boolCanBuild
public native_bool_prepphase() return g_boolPrepTime

public native_get_build_time()
{
	if (g_boolCanBuild)
		return g_iCountDown
		
	return 0;
}

public native_set_build_time(time)
{
	if (g_boolCanBuild)
	{
		g_iCountDown = time
		return 1
	}
		
	return 0;
}

public native_get_user_color(id) return g_iColor[id]
public native_set_user_color(id, color)
{
	g_iColor[id] = color
}

public native_drop_user_block(id)
{
	cmdStopEnt(id)
}
public native_get_user_block(id)
{
	if (g_iOwnedEnt[id])
		return g_iOwnedEnt[id]
		
	return 0;
}
public native_set_user_block(id, entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !MovingEnt(entity))
		g_iOwnedEnt[id] = entity
}

public native_is_locked_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity))
		return BlockLocker(entity) ? true : false
		
	return -1;
}
public native_lock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && !BlockLocker(entity))
	{
		LockBlock(entity, 33);
		set_pev(entity,pev_rendermode,kRenderTransColor)
		set_pev(entity,pev_rendercolor,Float:{LOCKED_COLOR})
		set_pev(entity,pev_renderamt,Float:{LOCKED_RENDERAMT})
	}
}
public native_unlock_block(entity)
{
	if (is_valid_ent(entity) && !is_user_alive(entity) && BlockLocker(entity))
	{
		UnlockBlock(entity)
		set_pev(entity,pev_rendermode,kRenderNormal)
	}
}

public native_release_zombies()
{
	if (g_boolCanBuild || g_boolPrepTime)
	{
		Release_Zombies()
		return 1;
	}
	return 0;
}

public native_set_user_primary(id, csw_primary)
{
	if (CSW_P228<=csw_primary<=CSW_P90)
	{
		g_iPrimaryWeapon[id] = csw_primary
		return g_iPrimaryWeapon[id];
	}
		
	return -1;
}

public native_get_user_primary(id) return g_iPrimaryWeapon[id]

public native_get_flags_build() 		return FLAGS_BUILD
public native_get_flags_lock() 		return FLAGS_LOCK
public native_get_flags_buildban() 	return FLAGS_BUILDBAN
public native_get_flags_swap() 		return FLAGS_SWAP
public native_get_flags_revive() 	return FLAGS_REVIVE
public native_get_flags_guns() 		return FLAGS_GUNS
public native_get_flags_release() 	return FLAGS_RELEASE
public native_get_flags_override() 	return FLAGS_OVERRIDE
public native_get_flags_lockafter()     return FLAGS_LOCKAFTER 

/*public native_set_user_mult(id, attribute, Float: amount)
{
	if (attribute < ATT_HEALTH || attribute > ATT_GRAVITY)
		return 0;
		
	if (amount < 1.0)
		amount = 1.0
		
	g_fClassMultiplier[id][attribute] = amount
	
	return 1;
}*/
