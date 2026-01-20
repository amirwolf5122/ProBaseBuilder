#if !defined MAX_NAME_LENGTH
	const MAX_NAME_LENGTH = 32;
#endif

#define clr(%1) %1 == -1 ? random(256) : %1
#define isPlayer(%1) ((1 <= %1 && %1 < MAXPLAYERS))

enum
{
	RENDER_MODE_NORMAL,
	RENDER_MODE_NO_COLOR
};

enum BlockCheckType
{
	CHECK_FOR_BLOCKING,
	CHECK_FOR_COLOR
};

enum _:Settings
{
	DHUD_BUILD_TIME_COLOR[3],
	Float:DHUD_BUILD_TIME_POSITION[2],
	DHUD_PREP_TIME_COLOR[3],
	Float:DHUD_PREP_TIME_POSITION[2],
	HUDINFO_HUMAN_COLOR[3],
	HUDINFO_ZOMBIE_COLOR[3],
	Float:HUDINFO_POSITION[2],
	Float:BARRIER_PRIMARY_COLOR[3],
	Float:BARRIER_SECONDARY_COLOR[3]
};

new g_eSettings[Settings];

enum _:E_Sounds
{
	SOUND_BAN_BUILD,
	SOUND_UNBAN_BUILD,
	SOUND_SWAP,
	SOUND_REVIVE,
	SOUND_TELEPORT,
	SOUND_GRAB_START,
	SOUND_GRAB_STOP,
	SOUND_GRAB_PLAYER,
	SOUND_GRAB_ADMIN,
	SOUND_BRICK,
	SOUND_INFECTION,
	SOUND_LOCK_OBJECT,
	SOUND_LOCK_FAIL,
	SOUND_WARNING,
	SOUND_HEALTH_POINTS,
	SOUND_UNSTUCK
};

new const g_szSoundPaths[E_Sounds][] =
{
	"basebuilder/block_ban.wav",
	"basebuilder/block_unban.wav",
	"basebuilder/swap.wav",
	"basebuilder/revive.wav",
	"basebuilder/teleport.wav",
	"basebuilder/block_grab.wav",
	"basebuilder/block_drop.wav",
	"basebuilder/grab_player.wav",
	"basebuilder/grab_admin.wav",
	"basebuilder/brick.wav",
	"basebuilder/zombie_kill1.wav",
	"buttons/lightswitch2.wav",
	"buttons/button10.wav",
	"warcraft3/immolate_burning.wav",
	"items/smallmedkit1.wav",
	"fvox/blip.wav"
};

enum _:E_Sprites
{
	SPRITE_TEAM,
	SPRITE_BLUE,
	SPRITE_GRAB,
	SPRITE_SKULL
};

new const g_szSpritePaths[E_Sprites][] =
{
	"sprites/basebuilder/team.spr",
	"sprites/basebuilder/blue.spr",
	"sprites/basebuilder/grab.spr",
	"sprites/basebuilder/skull.spr"
};

new g_iSpriteIDs[E_Sprites];

new g_iClonedEnts[MAXENTS];

new const Float:hudPosHit[9][1] = { 0.4, 0.44, 0.48, 0.52, 0.56, 0.60, 0.64, 0.68, 0.72 };
new lightCharacter[] = "abcdefghijklmnopqrstuvwxyz";

new Float:reconnectTableTime[MAXPLAYERS+1], Float:g_fColorDoorTime, Float:g_fUserPlayerSpeed[MAXPLAYERS+1], Float:g_fAdminReturnOrigin[MAXPLAYERS+1][3], Float:g_fAdminReturnAngles[33][3];

new bool:g_bTimerPaused, bool:g_bUserReconnected[MAXPLAYERS+1], bool:g_bUserLockMode[MAXPLAYERS+1], bool:g_bUserViewCamera[MAXPLAYERS+1], bool:g_bHasReturnOrigin[MAXPLAYERS+1],
	bool:g_bUsedVipSpawn[MAXPLAYERS+1], bool:g_bBlockRandomColor[MAXPLAYERS+1], g_bMoveLockBlocks, g_bColorDoorActive, g_bCheckForBlocker, g_bCanGrabPlayers;

new userVarList[MAXPLAYERS+1][32], reconnectTable[MAXPLAYERS+1][32], userNoClip[MAXPLAYERS+1], userGodMod[MAXPLAYERS+1], userAllowBuild[MAXPLAYERS+1],
	userVarMenu[MAXPLAYERS+1], userHudDeal[MAXPLAYERS+1], g_SelectedUser[MAXPLAYERS+1],
	g_playerBlockRenderMode[MAXPLAYERS+1], lightType[2];