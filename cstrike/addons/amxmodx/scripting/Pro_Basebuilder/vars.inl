/*
Mod editor
AmirWolf

Version 7.0
*/

#if !defined MAX_NAME_LENGTH
const MAX_NAME_LENGTH = 32
#endif

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

enum _: Settings
{
    DHUD_BUILD_TIME_COLOR[3],
	Float:DHUD_BUILD_TIME_POSITION[2],
	DHUD_PREP_TIME_COLOR[3],
	Float:DHUD_PREP_TIME_POSITION[2],
	HUDINFO_HUMAN_COLOR[3],
	HUDINFO_ZOMBIE_COLOR[3],
	Float:HUDINFO_POSITION[2],
	Float:BARRIER_COLOR[3]
};

new g_eSettings[ Settings ];

#define clr(%1) %1 == -1 ? random(256) : %1

#define isPlayer(%1) ((1 <= %1 && %1 < MAXPLAYERS))
#define BAN_BUILD	"basebuilder/IR_zombie/ban.wav"
#define UNBAN_BUILD	"basebuilder/IR_zombie/unban.wav"
#define TEAM_SWP	"sound/basebuilder/IR_zombie/swap.mp3"
#define RE_VEV	"basebuilder/IR_zombie/CareHeal.wav"

new const limitBlocks = 25;
new const LASERSPRITE[]	= "sprites/basebuildervt/laserbeam.spr";
new const sprite_player[] = "sprites/basebuilder/barhp.spr";
new const sprite_vip[] = "sprites/basebuilder/barhpivp.spr";
new const sprite_admin[] = "sprites/basebuilder/newHp.spr";
new const TEAMSPRITE[] = "sprites/basebuildervt/teams3.spr";	
new const BLUEZSPRITE[] = "sprites/basebuildervt/bluez.spr";
new const Float:hudPosHit[9][1] = { 0.4, 0.44, 0.48, 0.52, 0.56, 0.60, 0.64, 0.68, 0.72 };
new lightCharacter[] = "abcdefghijklmnopqrstuvwxyz";

new Float:reconnectTableTime[33], Float:fOffset[33][3], Float:userAfkValue[33], Float:userPlayerSpeed[33] = 260.0, Float:userTeamLine[33],
	bool:serverLetClone, bool:clockStop, bool:userReconnected[33], bool:userLockBlock[33], bool:AutoLockBlock[33], bool:userViewCamera[33],
	bool:userMusic[33], bool:ReviveUsedViP[33], bool:Color_Random_Block[33], bool:isMusicPlaying = false,
	userName[33][33], userVarList[33][33], reconnectTable[33][33],
	lightType[2], userClone[33], userBarHp[33], stuck[33], userClaimed[33], userNoClip[33], userGodMod[33], userButtonAfk[33], userVarMenu[33],
	userHudDeal[33], userHudGet[33], userMoveAs[33], userMoverBlockColor[33], userAllowBuild[33], userTeam[33], userTeamMenu[33], userTeamSend[33],
	userTeamBlock[33], userSaveOption[33],
	sprite_bluez, team_spr, userMenuId, spriteBeam;



	/*-*\
--| STUCK			 |
	\*-*/

new const Float:size[][3] = {
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
};

enum { BLOCK_COLOR, BLOCK_RENDER, BLOCK_NORENDER };
enum{save_TEAM,save_SPRAY,save_MODELS, save_CAVE, save_INVIS, save_SOUND, save_TOTAL};
enum {     SYMBOL_DOT = 0, SYMBOL_LINE, SYMBOL_PERMILLE, SYMBOL_CROSS, SYMBOL_APOSTROPHE, SYMBOL_R_ARROW,  SYMBOL_L_ARROW, SYMBOL_DL_ARROW, SYMBOL_DR_ARROW, SYMBOL_X, SYMBOL_CIRCLE_C,
	SYMBOL_CIRCLE_R, SYMBOL_SMALL_DOT,SYMBOL_EMPTY_DOT, SYMBOL_LINE_CURVE,SYMBOL_VERTICAL_LINE, SYMBOL_SQUARE_X, SYMBOL_DOLAR, SYMBOL_PILCROW,
	SYMBOL_SMALL_A, SYMBOL_SMALL_C, SYMBOL_SMALL_E, SYMBOL_SMALL_L, SYMBOL_SMALL_N, SYMBOL_SMALL_O, SYMBOL_SMALL_S, SYMBOL_SMALL_X, SYMBOL_SMALL_Z, 
	SYMBOL_LARGE_A, SYMBOL_LARGE_C, SYMBOL_LARGE_E, SYMBOL_LARGE_L, SYMBOL_LARGE_N, SYMBOL_LARGE_O, SYMBOL_LARGE_S, SYMBOL_LARGE_X, SYMBOL_LARGE_Z, SYMBOL_BB, TOTAL_SYMBOL_CUSTOM
};

new const symbolsCustom[TOTAL_SYMBOL_CUSTOM][] = {
	  "^xe2^x80^xa2"		// �		SYMBOL_DOT
	,"^xe2^x80^x93"		// �		SYMBOL_LINE
	,"^xe2^x80^xb0"		// � 		SYMBOL_PERMILLE
	,"^xe2^x80^xa0"		// �		SYMBOL_CROSS	
	,"^xe2^x80^x9c"		// �		SYMBOL_APOSTROPHE
	,"^xe2^x80^xaba"	// �		SYMBOL_R_ARROW   
	,"^xe2^x80^xab9"	// �		SYMBOL_L_ARROW
	,"^xc2^xab"		// �		SYMBOL_DL_ARROW
	,"^xc2^xbb"		// �		SYMBOL_DR_ARROW
	,"^xc3^x97"		// �		SYMBOL_X
	,"^xc2^xa9"		// � 		SYMBOL_CIRCLE_C
	,"^xc2^xae"		// � 		SYMBOL_CIRCLE_R
	,"^xc2^xb7"		// �		SYMBOL_SMALL_DOT
	,"^xc2^xb0"		// �		SYMBOL_EMPTY_DOT
	,"^xc2^xac"		// �		SYMBOL_LINE_CURVE
	,"^xc2^xa6"		// �		SYMBOL_VERTICAL_LINE
	,"^xc2^xa4"		// �		SYMBOL_SQUARE_X
	,"^xc2^xa7"		// �		SYMBOL_DOLAR
	,"^xc2^xb6"		// �		SYMBOL_PILCROW
	
	,"^xc4^x85"		// �		SYMBOL_SMALL_A
	,"^xc4^x87"		// �		SYMBOL_SMALL_C
	,"^xc4^x99"		// �		SYMBOL_SMALL_E
	,"^xc5^x82"		// �		SYMBOL_SMALL_L
	,"^xc5^x84"		// �		SYMBOL_SMALL_N
	,"^xc3^xb3"		// �		SYMBOL_SMALL_O
	,"^xc5^x9b"		// �		SYMBOL_SMALL_S
	,"^xc5^xba"		// �		SYMBOL_SMALL_X
	,"^xc5^xbc"		// �		SYMBOL_SMALL_Z
	
	,"^xc4^x84"		// �		SYMBOL_LARGE_A
	,"^xc4^x86"		// �		SYMBOL_LARGE_C
	,"^xc4^x98"		// �		SYMBOL_LARGE_E
	,"^xc5^x81"		// �		SYMBOL_LARGE_L
	,"^xc5^x83"		// �		SYMBOL_LARGE_N
	,"^xc3^x93"		// �		SYMBOL_LARGE_O
	,"^xc5^x9a"		// �		SYMBOL_LARGE_S
	,"^xc5^xb9"		// �		SYMBOL_LARGE_X
	,"^xc5^xbb"		// �		SYMBOL_LARGE_Z
	,"^x5c^x79^xe2^x80^x94^x5c^x64^x20^x62^x79^x5c^x72^x20 \
		^x4b^x6f^x52^x72^x4e^x69^x4b^x5c^x79^x20^xe2^x80^x94"
};
