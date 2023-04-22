/*
	Проект: CS-MAKER.RU
	Группа проекта: https://vk.com/cs_maker_ru
*/

#include amxmodx
#include fakemeta_util
#include hamsandwich
#include basebuilder
#include cstrike

#define IsCustomItem(%0)  (pev(%0, pev_impulse) == WEAPON_SPECIAL_CODE)
#define IsValidEntity(%0) (pev_valid(%0) == 2)
#define KillEntity(%0)    (set_pev(%0, pev_flags, pev(%0, pev_flags) | FL_KILLME))

new const WEAPON_WEAPONLIST[] = "weapon_y22s2sfpistol";
new const WEAPON_REFERENCE[] = "weapon_p228";
new const WEAPON_NATIVE[] = "zp_give_user_sfpistol";
new const WEAPON_SPECIAL_CODE = 9999934;

new const WEAPON_MODEL_VIEW[] = "models/G/v_y22s2sfpistol.mdl";
new const WEAPON_MODEL_PLAYER[] = "models/G/p_y22s2sfpistol.mdl";
new const WEAPON_MODEL_WORLD[] = "models/G/w_y22s2sfpistol.mdl";
new const WEAPON_LASERBEAM[] = "sprites/G/ef_y22s2sfpistol_laser.spr";
new const WEAPON_SOUNDS[][] =
{
	"weapons/y22s2sfpistol_idle.wav",
	"weapons/y22s2sfpistol_shoot_end.wav",
	"weapons/y22s2sfpistol-1.wav",
	"weapons/y22s2sfpistol_shoot-2.wav",
	"weapons/y22s2sfpistol_shoot2_fx.wav"
};

new const Float: WEAPON_DAMAGE = 1.1;
new const WEAPON_MAX_CLIP = 50;
new const WEAPON_DEFAULT_AMMO = 100;
new const SHOOTS_NEEDED = 50;

new const ENTITY_CLASSNAME[] = "sfpistol_bh";
new const ENTITY_MODEL[] = "models/G/ef_y22s2sfpistol.mdl";
new const Float: ENTITY_DAMAGE_RADIUS = 200.0;
new const Float: ENTITY_DAMAGE = 5.0;

enum
{
	WEAPON_ANIM_IDLE = 0,
	WEAPON_ANIM_SHOOT1,
	WEAPON_ANIM_SHOOT_END,
	WEAPON_ANIM_RELOAD,
	WEAPON_ANIM_DRAW,
	WEAPON_ANIM_SHOOT2
};

#define ANIM_TIME_IDLE				101.0/30
#define ANIM_TIME_SHOOT1			13.0/30
#define ANIM_TIME_SHOOTEND			16.0/30
#define ANIM_TIME_RELOAD			67.0/30
#define ANIM_TIME_DRAW				40.0/30
#define ANIM_TIME_SHOOT2			21.0/30
#define ANIM_TIME_BLACKHOLE			61.0/30

// Linux extra offsets
#define linux_diff_weapon 4
#define linux_diff_player 5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox 34

// CBasePlayerItem
#define m_pPlayer 41
#define m_pNext 42
#define m_iId 43

// CBasePlayerWeapon
#define m_flNextPrimaryAttack 46
#define m_flNextSecondaryAttack 47
#define m_flTimeWeaponIdle 48
#define m_iPrimaryAmmoType 49
#define m_iClip 51
#define m_fInReload 54
#define m_flAccuracy 62
#define m_iShotsFired 64
#define m_iWeaponState 74
#define m_fInSuperBullets 30
#define m_iGlock18ShotsFired 70

// CBaseMonster
#define m_flNextAttack 83
#define m_LastHitGroup 75

// CBasePlayer
#define m_rpgPlayerItems 367
#define m_pActiveItem 373
#define m_rgAmmo 376

new const iWeaponList[] = {9, 52, -1, -1, 1, 3, 1, 0};
new gl_iszAllocString_Weapon,
	gl_iszAllocString_ModelView,
	gl_iszAllocString_ModelPlayer,
	gl_iszAllocString_Blackhole,
	
	gl_iszBeamModelIndex,
	gl_iszSmokeModelIndex,
	
	gl_iMsgID_Weaponlist,
	
	HamHook: gl_HamHook_TraceAttack[4],
	
	g_iItemID;

public plugin_init()
{
	register_plugin("Weapon: Star Taylor", "1.0", "gajerek / xUnicorn & Batcoh: code base");
	
	register_forward(FM_UpdateClientData,		"FM_Hook_UpdateClientData_Post", true);
	register_forward(FM_SetModel, 				"FM_Hook_SetModel_Pre", false);
	
	RegisterHam(Ham_Item_AddToPlayer,				WEAPON_REFERENCE,	"CWeapon__AddToPlayer_Post", true);
	RegisterHam(Ham_Item_Deploy,					WEAPON_REFERENCE,	"CWeapon__Deploy_Post", true);
	RegisterHam(Ham_Item_PostFrame,					WEAPON_REFERENCE,	"CWeapon__PostFrame_Pre", false);
	RegisterHam(Ham_Weapon_Reload,					WEAPON_REFERENCE,	"CWeapon__Reload_Pre", false);
	RegisterHam(Ham_Weapon_WeaponIdle,				WEAPON_REFERENCE,	"CWeapon__WeaponIdle_Pre", false);
	RegisterHam(Ham_Weapon_PrimaryAttack,			WEAPON_REFERENCE,	"CWeapon__PrimaryAttack_Pre", false);
	RegisterHam(Ham_Weapon_SecondaryAttack,			WEAPON_REFERENCE,	"CWeapon__SecondaryAttack_Pre", false);
	
	RegisterHam(Ham_Think, 							"info_target",		"CEntity__Think_Pre", false);
	RegisterHam(Ham_Touch, 							"info_target",		"CEntity__Touch_Pre", false);
	
	gl_HamHook_TraceAttack[0] = RegisterHam(Ham_TraceAttack,	"func_breakable",	"CPlayer__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[1] = RegisterHam(Ham_TraceAttack,	"info_target",		"CPlayer__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[2] = RegisterHam(Ham_TraceAttack,	"player",			"CPlayer__TraceAttack_Pre", false);
	gl_HamHook_TraceAttack[3] = RegisterHam(Ham_TraceAttack,	"hostage_entity",	"CPlayer__TraceAttack_Pre", false);
	
	fm_ham_hook(false);
	
	gl_iMsgID_Weaponlist = get_user_msgid("WeaponList");
	
	gl_iszAllocString_Weapon = engfunc(EngFunc_AllocString, WEAPON_REFERENCE);
	gl_iszAllocString_ModelView = engfunc(EngFunc_AllocString, WEAPON_MODEL_VIEW);
	gl_iszAllocString_ModelPlayer = engfunc(EngFunc_AllocString, WEAPON_MODEL_PLAYER);
	gl_iszAllocString_Blackhole = engfunc(EngFunc_AllocString, ENTITY_CLASSNAME);
	
	register_clcmd(WEAPON_WEAPONLIST, "Command_HookWeapon");
	
	//g_iItemID = zp_register_extra_item("Star Taylor", 0, ZP_TEAM_HUMAN);
}

public plugin_precache()
{	
	new i;
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_VIEW);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_PLAYER);
	engfunc(EngFunc_PrecacheModel, WEAPON_MODEL_WORLD);
	engfunc(EngFunc_PrecacheModel, ENTITY_MODEL);
	
	UTIL_PrecacheSoundsFromModel(WEAPON_MODEL_VIEW);
	for(i = 0; i < sizeof WEAPON_SOUNDS; i++)
		engfunc(EngFunc_PrecacheSound, WEAPON_SOUNDS[i]);
		
	gl_iszBeamModelIndex = engfunc(EngFunc_PrecacheModel, WEAPON_LASERBEAM);
	gl_iszSmokeModelIndex = engfunc(EngFunc_PrecacheModel, "sprites/G/ef_smoke_poison.spr");
	
	new szWeaponList[128]; formatex(szWeaponList, charsmax(szWeaponList), "sprites/G/%s.txt", WEAPON_WEAPONLIST);
	engfunc(EngFunc_PrecacheGeneric, szWeaponList);
	engfunc(EngFunc_PrecacheGeneric, "sprites/G/640hud219.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/G/640hud61.spr");
	engfunc(EngFunc_PrecacheGeneric, "sprites/G/640hud123.spr");
}

public Command_HookWeapon(iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERENCE);
	return PLUGIN_HANDLED;
}

public zp_extra_item_selected(player, itemid)
{
	if(itemid == g_iItemID)
		Command_GiveWeapon(player)
}

public plugin_natives() register_native(WEAPON_NATIVE, "Command_GiveWeapon", 1);
public Command_GiveWeapon(iPlayer)
{
	static iWeapon; iWeapon = engfunc(EngFunc_CreateNamedEntity, gl_iszAllocString_Weapon);
	if(!IsValidEntity(iWeapon)) return FM_NULLENT;

	set_pev(iWeapon, pev_impulse, WEAPON_SPECIAL_CODE);
	ExecuteHam(Ham_Spawn, iWeapon);
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, linux_diff_weapon);
	UTIL_DropWeapon(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));

	if(!ExecuteHamB(Ham_AddPlayerItem, iPlayer, iWeapon))
	{
		KillEntity(iWeapon);
		return FM_NULLENT;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer, iWeapon, iPlayer);
	
	set_pdata_int(iWeapon, m_iGlock18ShotsFired, 0, linux_diff_weapon);
	set_pdata_int(iWeapon, m_fInSuperBullets, 0, linux_diff_weapon);
	
	new iAmmoType = m_rgAmmo + get_pdata_int(iWeapon, m_iPrimaryAmmoType, linux_diff_weapon);
	if(get_pdata_int(iPlayer, m_rgAmmo, linux_diff_player) < WEAPON_DEFAULT_AMMO)
		set_pdata_int(iPlayer, iAmmoType, WEAPON_DEFAULT_AMMO, linux_diff_player);

	emit_sound(iPlayer, CHAN_ITEM, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	return iWeapon;
}

public fm_ham_hook(bool: bEnabled)
{
	if(bEnabled)
	{
		EnableHamForward(gl_HamHook_TraceAttack[0]);
		EnableHamForward(gl_HamHook_TraceAttack[1]);
		EnableHamForward(gl_HamHook_TraceAttack[2]);
		EnableHamForward(gl_HamHook_TraceAttack[3]);
	}
	else 
	{
		DisableHamForward(gl_HamHook_TraceAttack[0]);
		DisableHamForward(gl_HamHook_TraceAttack[1]);
		DisableHamForward(gl_HamHook_TraceAttack[2]);
		DisableHamForward(gl_HamHook_TraceAttack[3]);
	}
}

public FM_Hook_UpdateClientData_Post(iPlayer, iSendWeapons, CD_Handle)
{
	if(!is_user_alive(iPlayer)) return;
	static iItem; iItem = get_pdata_cbase(iPlayer, m_pActiveItem, linux_diff_player);
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
}

public FM_Hook_SetModel_Pre(iEntity)
{
	static i, szClassName[32], iItem;
	pev(iEntity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	for(i = 0; i < 6; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, linux_diff_weapon);
		if(IsValidEntity(iItem) && IsCustomItem(iItem))
		{
			engfunc(EngFunc_SetModel, iEntity, WEAPON_MODEL_WORLD);
			set_pev(iEntity, pev_body, 0);
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public CWeapon__AddToPlayer_Post(iItem, iPlayer) 
{
	if(IsCustomItem(iItem)) UTIL_WeaponList(iPlayer, true, 1);
	else if(pev(iItem, pev_impulse) == 0) UTIL_WeaponList(iPlayer, false, -1);
}

public CWeapon__Deploy_Post(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if (cs_get_user_team(iPlayer) == CS_TEAM_CT){
		set_pev_string(iPlayer, pev_viewmodel2, gl_iszAllocString_ModelView);
		set_pev_string(iPlayer, pev_weaponmodel2, gl_iszAllocString_ModelPlayer);
	}
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_DRAW);
	SetExtraAmmo(iPlayer, get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon));
	
	set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_TIME_DRAW, linux_diff_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_DRAW, linux_diff_weapon);
}

public CWeapon__PostFrame_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	static iWeaponState; iWeaponState = get_pdata_int(iItem, m_iWeaponState, linux_diff_weapon);
	static iButton; iButton = pev(iPlayer, pev_button);
	if(get_pdata_int(iItem, m_fInReload, linux_diff_weapon) == 1)
	{
		static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
		static iAmmo; iAmmo = get_pdata_int(iPlayer, iAmmoType, linux_diff_player);
		static j; j = min(WEAPON_MAX_CLIP - iClip, iAmmo);
		set_pdata_int(iItem, m_iClip, iClip + j, linux_diff_weapon);
		set_pdata_int(iPlayer, iAmmoType, iAmmo - j, linux_diff_player);
		set_pdata_int(iItem, m_fInReload, 0, linux_diff_weapon);
	}
	switch(iWeaponState)
	{
		case 1:
		{
			if(pev(iPlayer, pev_oldbuttons) & IN_ATTACK || pev(iPlayer, pev_oldbuttons) & IN_ATTACK2)
				return HAM_IGNORED;
			
			UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT_END);
			emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			set_pdata_int(iItem, m_iWeaponState, 0, linux_diff_weapon);
			set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_SHOOTEND, linux_diff_weapon);
			set_pdata_float(iPlayer, m_flNextAttack, ANIM_TIME_SHOOTEND, linux_diff_player);
		}
	}
	if(iButton & IN_ATTACK2 && get_pdata_float(iItem, m_flNextSecondaryAttack, linux_diff_weapon) < 0.0 && get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) > 0)
	{
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iItem);
		
		set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, linux_diff_weapon);
		set_pev(iPlayer, pev_button, pev(iPlayer, pev_oldbuttons) & ~IN_ATTACK2);
	}
	return HAM_IGNORED;
}

public CWeapon__Reload_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iAmmoType; iAmmoType = m_rgAmmo + get_pdata_int(iItem, m_iPrimaryAmmoType, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	
	if(iClip >= WEAPON_MAX_CLIP) return HAM_SUPERCEDE;
	if(get_pdata_int(iPlayer, iAmmoType, linux_diff_player) <= 0) return HAM_SUPERCEDE;

	set_pdata_int(iItem, m_iClip, 0, linux_diff_weapon);
	ExecuteHam(Ham_Weapon_Reload, iItem);
	set_pdata_int(iItem, m_iClip, iClip, linux_diff_weapon);
	set_pdata_int(iItem, m_fInReload, 1, linux_diff_weapon);
	
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_RELOAD);
	set_pdata_float(iItem, m_flNextPrimaryAttack, ANIM_TIME_RELOAD, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_RELOAD, linux_diff_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, ANIM_TIME_RELOAD, linux_diff_player);

	return HAM_SUPERCEDE;
}

public CWeapon__WeaponIdle_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem) || get_pdata_float(iItem, m_flTimeWeaponIdle, linux_diff_weapon) > 0.0) return HAM_IGNORED;
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);

	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_IDLE);
	emit_sound(iItem, CHAN_WEAPON, WEAPON_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_IDLE, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__PrimaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextPrimaryAttack, 0.2, linux_diff_weapon);
		return HAM_SUPERCEDE;
	}
	
	fm_ham_hook(true);
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	fm_ham_hook(false);
	
	set_pev(iPlayer, pev_punchangle, Float:{0.01, 0.01, 0.01});
	set_pdata_float(iItem, m_flAccuracy, 1.0, linux_diff_weapon);
	
	if(get_pdata_int(iItem, m_iGlock18ShotsFired, linux_diff_weapon) >= SHOOTS_NEEDED)
	{
		set_pdata_int(iItem, m_iGlock18ShotsFired, 0, linux_diff_weapon);
		set_pdata_int(iItem, m_fInSuperBullets, get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) + 1, linux_diff_weapon);
		SetExtraAmmo(iPlayer, get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon));
	}
	else set_pdata_int(iItem, m_iGlock18ShotsFired, get_pdata_int(iItem, m_iGlock18ShotsFired, linux_diff_weapon) + 1, linux_diff_weapon);
	
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT1);
	
	static Float:vecAimOrigin[3]; fm_get_aim_origin(iPlayer, vecAimOrigin);
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iPlayer | 0x1000);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[2]);
	write_short(gl_iszBeamModelIndex);
	write_byte(0); // framestart
	write_byte(1); // framerate
	write_byte(2); // life
	write_byte(11); // width
	write_byte(0); // noise
	write_byte(0); // red
	write_byte(100); // green
	write_byte(255); // blue
	write_byte(100); // brightness
	write_byte(10); // speed
	message_end();
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecAimOrigin, 0)//, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecAimOrigin[2] - 7.0);
	write_short(gl_iszSmokeModelIndex); // Id Sprite
	write_byte(random_num(2, 4)); // Sprite size
	write_byte(random_num(60, 76)); // Sprite framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES);
	message_end();
	
	set_pdata_int(iItem, m_iShotsFired, 0, linux_diff_weapon);
	set_pdata_int(iItem, m_iWeaponState, 1, linux_diff_weapon);
	set_pdata_int(iItem, m_iClip, iClip - 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, 1.0, linux_diff_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, 0.1, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_SHOOT1, linux_diff_weapon);

	return HAM_SUPERCEDE;
}

public CWeapon__SecondaryAttack_Pre(iItem)
{
	if(!IsValidEntity(iItem) || !IsCustomItem(iItem)) return HAM_IGNORED;
	
	static iPlayer; iPlayer = get_pdata_cbase(iItem, m_pPlayer, linux_diff_weapon);
	if(!(pev(iPlayer, pev_flags) & FL_ONGROUND))
		return HAM_SUPERCEDE;
	
	static iClip; iClip = get_pdata_int(iItem, m_iClip, linux_diff_weapon);
	if(iClip == 0)
	{
		ExecuteHam(Ham_Weapon_PlayEmptySound, iItem);
		set_pdata_float(iItem, m_flNextSecondaryAttack, 0.2, linux_diff_weapon);
		return HAM_SUPERCEDE;
	}
	
	UTIL_SendWeaponAnim(iPlayer, WEAPON_ANIM_SHOOT2);
	emit_sound(iPlayer, CHAN_WEAPON, WEAPON_SOUNDS[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	CreateBlackHole(iPlayer);
	
	set_pdata_int(iItem, m_fInSuperBullets, get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon) - 1, linux_diff_weapon);
	SetExtraAmmo(iPlayer, get_pdata_int(iItem, m_fInSuperBullets, linux_diff_weapon));
	
	set_pdata_int(iItem, m_iWeaponState, 1, linux_diff_weapon);
	set_pdata_float(iItem, m_flTimeWeaponIdle, ANIM_TIME_SHOOT2, linux_diff_weapon);
	
	return HAM_SUPERCEDE;
}

public CEntity__Think_Pre(iEntity)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Blackhole)
		KillEntity(iEntity);
	
	return HAM_IGNORED;
}

public CEntity__Touch_Pre(iEntity, iTouch)
{
	if(!IsValidEntity(iEntity)) return HAM_IGNORED;
	if(pev(iEntity, pev_classname) == gl_iszAllocString_Blackhole)
	{
		static iAttacker; iAttacker = pev(iEntity, pev_owner);
		static Float: vecOrigin[3]; pev(iEntity, pev_origin, vecOrigin);
		static Float: flDmgTime; pev(iTouch, pev_dmgtime, flDmgTime);
		static Float: flGameTime; flGameTime = get_gametime();
		
		set_pev(iEntity, pev_velocity, Float: { 0.0, 0.0, 0.0 });
		
		iTouch = FM_NULLENT;
		while((iTouch = engfunc(EngFunc_FindEntityInSphere, iTouch, vecOrigin, ENTITY_DAMAGE_RADIUS)) != 0)
		{
			if(!is_user_connected(iTouch) || !is_user_alive(iTouch) || iTouch == iAttacker || !zp_get_user_zombie(iTouch))
				continue;
			
			if(pev(iTouch, pev_takedamage) == DAMAGE_NO)
				continue;
			
			if(flDmgTime <= flGameTime)
			{
				set_pev(iTouch, pev_dmgtime, flGameTime + 0.2);
				set_pdata_int(iTouch, m_LastHitGroup, HIT_GENERIC, linux_diff_player);
				ExecuteHamB(Ham_TakeDamage, iTouch, iAttacker, iAttacker, ENTITY_DAMAGE, DMG_SHOCK);
			}
		}
	}
	return HAM_IGNORED;
}

public CPlayer__TraceAttack_Pre(iVictim, iAttacker, Float:flDamage)
{
	if(!is_user_connected(iAttacker)) return;
	static iItem; iItem = get_pdata_cbase(iAttacker, m_pActiveItem, linux_diff_player);
	if(!IsCustomItem(iItem)) return;
	SetHamParamFloat(3, flDamage * WEAPON_DAMAGE);
}

CreateBlackHole(iPlayer)
{
	static iEntity, iszAllocStringCached;
	if(iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, "info_target")))
		iEntity = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	
	if(!IsValidEntity(iEntity)) return FM_NULLENT;
	static Float: vecOrigin[3]; pev(iPlayer, pev_origin, vecOrigin);
	static iFlags; iFlags = pev(iPlayer, pev_flags);
	vecOrigin[2] -= (iFlags & FL_DUCKING) ? 18.0 : 31.1;
	
	dllfunc(DLLFunc_Spawn, iEntity);
	engfunc(EngFunc_SetModel, iEntity, ENTITY_MODEL);
	set_pev_string(iEntity, pev_classname, gl_iszAllocString_Blackhole);
	set_pev(iEntity, pev_animtime, get_gametime());
	set_pev(iEntity, pev_framerate, 1.0);
	set_pev(iEntity, pev_frame, 1.0);
	set_pev(iEntity, pev_rendermode, kRenderTransAdd);
	set_pev(iEntity, pev_renderamt, 240.0);
	set_pev(iEntity, pev_nextthink, get_gametime() + ANIM_TIME_BLACKHOLE);
	set_pev(iEntity, pev_solid, SOLID_TRIGGER);
	set_pev(iEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(iEntity, pev_owner, iPlayer);
	emit_sound(iEntity, CHAN_STATIC, WEAPON_SOUNDS[4], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	engfunc(EngFunc_SetSize, iEntity, Float: {-120.0, -120.0, -120.0}, Float: {120.0, 120.0, 120.0});
	engfunc(EngFunc_SetOrigin, iEntity, vecOrigin);
	
	return iEntity;
}

stock SetExtraAmmo(iPlayer, iClip) // KORD_12.7
{
	message_begin(MSG_ONE, get_user_msgid("AmmoX"), {0.0,0.0,0.0}, iPlayer);
	write_byte(1);
	write_byte(iClip);
	message_end();
}

stock UTIL_WeaponList(iPlayer, bool: bEnabled, iByte)
{
	message_begin(MSG_ONE, gl_iMsgID_Weaponlist, _, iPlayer);
	write_string(bEnabled ? WEAPON_WEAPONLIST : WEAPON_REFERENCE);
	write_byte(iWeaponList[0]);
	write_byte(bEnabled ? WEAPON_DEFAULT_AMMO : iWeaponList[1]);
	write_byte(iByte);
	write_byte(iWeaponList[3]);
	write_byte(iWeaponList[4]);
	write_byte(iWeaponList[5]);
	write_byte(iWeaponList[6]);
	write_byte(iWeaponList[7]);
	message_end();
}

stock UTIL_DropWeapon(iPlayer, iSlot)
{
	static iEntity, iNext, szWeaponName[32];
	iEntity = get_pdata_cbase(iPlayer, m_rpgPlayerItems + iSlot, linux_diff_player);

	if(IsValidEntity(iEntity))
	{
		do
		{
			iNext = get_pdata_cbase(iEntity, m_pNext, linux_diff_weapon);

			if(get_weaponname(get_pdata_int(iEntity, m_iId, linux_diff_weapon), szWeaponName, charsmax(szWeaponName)))
				engclient_cmd(iPlayer, "drop", szWeaponName);
		}
		
		while((iEntity = iNext) > 0);
	}
}

stock UTIL_SendWeaponAnim(iPlayer, iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);
	message_begin(MSG_ONE, SVC_WEAPONANIM, _, iPlayer);
	write_byte(iAnim);
	write_byte(0);
	message_end();
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}