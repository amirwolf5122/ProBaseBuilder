/*
Mod editor
AmirWolf

Version 7.0
*/

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

new Float:reconnectTableTime[33];
new Float:fOffset[33][3];
new Float:userAfkValue[33];
new Float:userPlayerSpeed[33] = 260.0;
new Float:userTeamLine[33];

new bool:serverLetClone;
new bool:clockStop;
new bool:userReconnected[33];
new bool:userLockBlock[33];
new bool:AutoLockBlock[33];
new bool:userViewCamera[33];
new bool:userMusic[33];
new bool:ReviveUsedViP[33];
new bool:Color_Random_Block[33];

new lightCharacter[] = "abcdefghijklmnopqrstuvwxyz";

new sprite_bluez;
new team_spr;
new userMenuId;
new spriteBeam;

new userName[33][33];
new userVarList[33][33];
new reconnectTable[33][33];
new lightType[2];
new userClone[33];
new userBarHp[33]
new stuck[33];
new userClaimed[33];
new userNoClip[33];
new userGodMod[33];
new userButtonAfk[33];
new userVarMenu[33];
new userHudDeal[33];
new userHudGet[33];
new userMoveAs[33];
new userMoverBlockColor[33];
new userAllowBuild[33];
new userTeam[33];
new userTeamMenu[33];
new userTeamSend[33];
new userTeamBlock[33];
new userSaveOption[33];

new const Float:hudPosHit[9][1] = { 0.4, 0.44, 0.48, 0.52, 0.56, 0.60, 0.64, 0.68, 0.72 };

//#define HUD_HIDE_MONEY 			(1<<5)
//#define	HUD_HIDE_FLASH 			(1<<1)
//#define HUD_HIDE_RHA 			(1<<3)

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
