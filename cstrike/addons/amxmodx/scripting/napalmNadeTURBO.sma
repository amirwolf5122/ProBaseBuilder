#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <cstrike>
#include <fun>
#include <basebuilder>

//#define USE_NAPALM_CUSTOM_MODELS
#if defined USE_NAPALM_CUSTOM_MODELS

new const g_model_napalm_view[] = "models/v_hegrenade"
new const g_model_napalm_player[] = "models/p_hegrenade.mdl"
new const g_model_napalm_world[] = "models/w_hegrenade.mdl"
#endif

new const sprite_grenade_fire2[] = "sprites/zerogxplode.spr";

new const grenade_fire[][] = { "weapons/hegrenade-1.wav" }
new const grenade_fire_player[][] = { "scientist/sci_fear8.wav", "scientist/sci_pain1.wav", "scientist/scream02.wav" }
new const sprite_grenade_fire[] = "sprites/basebuilder/flames.spr"
new const  sprite_grenade_smoke[] = "sprites/black_smoke3.spr"
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"


const NAPALM_R = 200
const NAPALM_G = 0
const NAPALM_B = 0

const TASK_BURN = 1000

#define ID_BURN (taskid - TASK_BURN)
#define BURN_DURATION args[0]
#define BURN_ATTACKER args[1]

// CS Player PData Offsets (win32)
const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_MAPZONE = 235
new const AFFECTED_BPAMMO_OFFSETS[] = { 388, 387, 389 }
const OFFSET_LINUX = 5 


const OFFSET_ACTIVE_ITEM = 373
const OFFSET_WEAPONID = 43
const OFFSET_LINUX_WEAPONS = 4 
const OFFSET_WEAPONOWNER = 41
const PLAYER_IN_BUYZONE = (1<<0)
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_NAPALM = 681856
const PEV_NAPALM_AMMO = pev_flSwimTime


new const AFFECTED_NAMES[][] = { "HE", "FB", "SG" }
new const AFFECTED_CLASSNAMES[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" }
new const AFFECTED_AMMOID[] = { 12, 11, 13 }
#if defined USE_NAPALM_CUSTOM_MODELS
new const AFFECTED_WEAPONS[] = { CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE }
#endif

new const sound_buyammo[] = "items/9mmclip1.wav"
new g_hamczbots
new g_flameSpr, g_smokeSpr, g_trailSpr, g_exploSpr, fire2
new g_msgDamage, g_msgMoney, g_msgBlinkAcct, g_msgAmmoPickup
new cvar_radius, cvar_price, cvar_hitself, cvar_duration, cvar_slowdown, cvar_override,
cvar_on, cvar_buyzone, cvar_ff, cvar_cankill, cvar_spread, cvar_botquota,
cvar_teamrestrict, cvar_screamrate, cvar_keepexplosion, cvar_affect, cvar_carrylimit
new g_maxplayers, g_on, g_affect, g_override, g_allowedteam, g_keepexplosion, g_spread,
g_ff, g_duration, g_buyzone, g_price, g_carrylimit, g_hitself, g_screamrate,
Float:g_slowdown, g_cankill, Float:g_radius
//new bool:isInFire[33]
new lastAttacker[33]

enum{class_CLASSIC, class_SPEED, class_FAT, class_TANK, class_DRACULA, class_SNOWMAN,  class_DEVIL, class_HEALTH, class_POISON, class_DEATH, class_TERMINATOR, class_DEMON, class_TOTAL}



public plugin_precache()
{
	new i
	for (i = 0; i < sizeof grenade_fire; i++)
		engfunc(EngFunc_PrecacheSound, grenade_fire[i])
	for (i = 0; i < sizeof grenade_fire_player; i++)
		engfunc(EngFunc_PrecacheSound, grenade_fire_player[i])
	
	g_flameSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_fire)
	g_smokeSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_smoke)
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)
	g_exploSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_ring)
	fire2 = engfunc(EngFunc_PrecacheModel, sprite_grenade_fire2)
	
	engfunc(EngFunc_PrecacheSound, sound_buyammo)
	
#if defined USE_NAPALM_CUSTOM_MODELS
	engfunc(EngFunc_PrecacheModel, g_model_napalm_view)
	engfunc(EngFunc_PrecacheModel, g_model_napalm_player)
	engfunc(EngFunc_PrecacheModel, g_model_napalm_world)
#endif
}

public plugin_init()
{
	register_plugin("Napalm Nades2", "1.3a", "MeRcyLeZZ edit: KoRrNiK - amxx.pl/user/69614-korrnik/")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Touch, "player", "fw_TouchPlayer")
#if defined USE_NAPALM_CUSTOM_MODELS
	for (new i = 0; i < sizeof AFFECTED_CLASSNAMES; i++)
		RegisterHam(Ham_Item_Deploy, AFFECTED_CLASSNAMES[i], "fw_Item_Deploy_Post", 1)
#endif
	RegisterHam(Ham_Spawn, 		"player", 		"ham_Spawn",			1)
	
	// Client commands
	//register_clcmd("say napalm", "buy_napalm")
	//register_clcmd("say /napalm", "buy_napalm")
	
	// CVARS
	cvar_on = register_cvar("napalm_on", "1")
	cvar_affect = register_cvar("napalm_affect", "1")
	cvar_teamrestrict = register_cvar("napalm_team", "2")
	cvar_override = register_cvar("napalm_override", "1")
	cvar_price = register_cvar("napalm_price", "1000")
	cvar_buyzone = register_cvar("napalm_buyzone", "0")
	cvar_carrylimit = register_cvar("napalm_carrylimit", "1")
	
	cvar_radius = register_cvar("napalm_radius", "240")
	cvar_hitself = register_cvar("napalm_hitself", "0")
	cvar_ff = register_cvar("napalm_ff", "0")
	cvar_spread = register_cvar("napalm_spread", "1")
	cvar_keepexplosion = register_cvar("napalm_keepexplosion", "0")
	
	cvar_duration = register_cvar("napalm_duration", "5")
	cvar_cankill = register_cvar("napalm_cankill", "1")
	cvar_slowdown = register_cvar("napalm_slowdown", "0.5")
	cvar_screamrate = register_cvar("napalm_screamrate", "20")
	
	cvar_botquota = get_cvar_pointer("bot_quota")
	g_maxplayers = get_maxplayers()
	
	// Message ids
	g_msgDamage = get_user_msgid("Damage")
	g_msgMoney = get_user_msgid("Money")
	g_msgBlinkAcct = get_user_msgid("BlinkAcct")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}

public plugin_cfg()
{
	// Cache CVARs after configs are loaded
	set_task(0.5, "event_round_start")
}

public plugin_natives(){
	register_native("bb_set_in_fire", "native_set_in_fire",1)
}
public native_set_in_fire(id, id2, duration){
	if( !task_exists(id2+TASK_BURN) ){
		static params[2]
		params[0] = duration // duration
		params[1] = id // attacker		

		set_task(0.1, "burning_flame", id2+TASK_BURN, params, sizeof params)
	}
}



// Round Start Event
public event_round_start()
{
	// Cache CVARs
	g_on = get_pcvar_num(cvar_on)
	g_affect = get_pcvar_num(cvar_affect)
	g_override = get_pcvar_num(cvar_override)
	g_allowedteam = get_pcvar_num(cvar_teamrestrict)
	g_keepexplosion = get_pcvar_num(cvar_keepexplosion)
	g_spread = get_pcvar_num(cvar_spread)
	g_ff = get_pcvar_num(cvar_ff)
	g_duration = get_pcvar_num(cvar_duration)
	g_buyzone = get_pcvar_num(cvar_buyzone)
	g_price = get_pcvar_num(cvar_price)
	g_carrylimit = get_pcvar_num(cvar_carrylimit)
	g_hitself = get_pcvar_num(cvar_hitself)
	g_screamrate = get_pcvar_num(cvar_screamrate)
	g_slowdown = get_pcvar_float(cvar_slowdown)
	g_cankill = get_pcvar_num(cvar_cankill)
	g_radius = get_pcvar_float(cvar_radius)
	
	// Stop any burning tasks on players
	for (new id = 1; id <= g_maxplayers; id++)
		remove_task(id+TASK_BURN);
}

public ham_Spawn(id){
	remove_task(id+TASK_BURN);	
}

// Client joins the game
public client_putinserver(id)
{
	if (!g_hamczbots && cvar_botquota && is_user_bot(id))
	{
		set_task(0.1, "register_ham_czbots", id)
	}
}


public fw_SetModel(entity, const model[])
{
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)

	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	if (!equal(model, "models/w_hegrenade.mdl"))
		return FMRES_IGNORED;
	
	static owner, napalm_weaponent
	owner = pev(entity, pev_owner)
	napalm_weaponent = fm_get_user_current_weapon_ent(owner)
	
	if (!g_override && pev(napalm_weaponent, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return FMRES_IGNORED;
	
	static owner_team
	owner_team = fm_get_user_team(owner)
	
	if (g_allowedteam > 0 && g_allowedteam != owner_team)
		return FMRES_IGNORED;
	
	fm_set_rendering(entity, kRenderFxGlowShell, NAPALM_R, NAPALM_G, NAPALM_B, kRenderNormal, 16)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(NAPALM_R) // r
	write_byte(NAPALM_G) // g
	write_byte(NAPALM_B) // b
	write_byte(200) // brightness
	message_end()
	
	static napalm_ammo
	napalm_ammo = pev(napalm_weaponent, PEV_NAPALM_AMMO)
	set_pev(napalm_weaponent, PEV_NAPALM_AMMO, --napalm_ammo)
	
	if (napalm_ammo < 1)
	{
		set_pev(napalm_weaponent, PEV_NADE_TYPE, 0)
	}

	set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
	set_pev(entity, pev_team, owner_team)
	
#if defined USE_NAPALM_CUSTOM_MODELS
	engfunc(EngFunc_SetModel, entity, g_model_napalm_world)
	return FMRES_SUPERCEDE;
#else
	return FMRES_IGNORED;
#endif
}

// Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	// Not a napalm grenade
	if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return HAM_IGNORED;
	
	// Explode event
	napalm_explode(entity)
	
	// Keep the original explosion?
	if (g_keepexplosion)
	{
		set_pev(entity, PEV_NADE_TYPE, 0)
		return HAM_IGNORED;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, entity)
	return HAM_SUPERCEDE;
}

// Player Touch Forward
public fw_TouchPlayer(self, other)
{
	// Spread cvar disabled or not touching a player
	if (!g_spread || !is_user_alive(other))
		return;
	
	// Toucher not on fire or touched player already on fire
	if (!task_exists(self+TASK_BURN) || task_exists(other+TASK_BURN))
		return;
	
	// Check if friendly fire is allowed
	if (!g_ff && fm_get_user_team(self) == fm_get_user_team(other))
		return;
	if( fm_get_user_team(other) == 2 )
		return
	// Heat icon
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, other)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_BURN) // damage type
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
	
	// Our task params
	static params[2]
	params[0] = g_duration * 2 // duration (reduced a bit)
	params[1] = lastAttacker[self] // attacker
	
	// Set burning task on victim
	set_task(0.1, "burning_flame", other+TASK_BURN, params, sizeof params)
}

#if defined USE_NAPALM_CUSTOM_MODELS
// Ham Weapon Deploy Forward
public fw_Item_Deploy_Post(entity)
{
	// Napalm grenades disabled
	if (!g_on) return;
	
	// Not a napalm grenade (because the weapon entity of its owner doesn't have the flag set)
	if (!g_override && pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return;
	
	// Get weapon's id
	static weaponid
	weaponid = fm_get_weapon_ent_id(entity)
	
	// Not an affected grenade
	if (weaponid != AFFECTED_WEAPONS[g_affect-1])
		return;
	
	// Get weapon's owner
	static owner
	owner = fm_get_weapon_ent_owner(entity)
	
	// Player is on a restricted team
	if (g_allowedteam > 0 && g_allowedteam != fm_get_user_team(owner))
		return;
	
	// Replace models
	set_pev(owner, pev_viewmodel2, g_model_napalm_view)
	set_pev(owner, pev_weaponmodel2, g_model_napalm_player)
}
#endif

// Napalm purchase command
public buy_napalm(id)
{
	// Napalm grenades disabled
	if (!g_on) return PLUGIN_CONTINUE;
	
	// Check if override setting is enabled instead
	if (g_override)
	{
		client_print(id, print_center, "Just buy a %s grenade and get a napalm automatically!", AFFECTED_NAMES[g_affect-1])
		return PLUGIN_HANDLED;
	}
	
	// Check if player is alive
	if ( !is_user_connected(id) || !is_user_alive ( id ) || zp_get_user_zombie ( id ) )
	{
		client_print(id, print_center, "You can't buy when you're dead!")
		return PLUGIN_HANDLED;
	}
	
	// Check if the player is on a restricted team
	if (g_allowedteam > 0 && g_allowedteam != fm_get_user_team(id))
	{
		client_print(id, print_center, "Your team cannot buy napalm nades!")
		return PLUGIN_HANDLED;
	}
	
	// Check if player needs to be in a buyzone
	if (g_buyzone && !fm_get_user_buyzone(id))
	{
		client_print(id, print_center, "You are not in a buyzone!")
		return PLUGIN_HANDLED;
	}
	
	// Check that player has the money
	if (fm_get_user_money(id) < g_price)
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money")
		
		// Blink money
		message_begin(MSG_ONE_UNRELIABLE, g_msgBlinkAcct, _, id)
		write_byte(2) // times
		message_end()
		
		return PLUGIN_HANDLED;
	}
	
	// Get napalm weapon entity
	static napalm_weaponent
	napalm_weaponent = fm_get_napalm_entity(id, g_affect)
	
	// Does the player have a napalm already?
	if (napalm_weaponent != 0)
	{
		// Retrieve napalm ammo
		static napalm_ammo
		napalm_ammo = pev(napalm_weaponent, PEV_NAPALM_AMMO)
		
		// Check if allowed to have this many napalms
		if (napalm_ammo < g_carrylimit)
		{
			// Increase napalm ammo
			set_pev(napalm_weaponent, PEV_NAPALM_AMMO, ++napalm_ammo)
			
			// Increase player's backpack ammo
			set_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1], get_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1]) + 1, OFFSET_LINUX)
			
			// Flash ammo in hud
			message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
			write_byte(AFFECTED_AMMOID[g_affect-1]) // ammo id
			write_byte(1) // ammo amount
			message_end()
			
			// Play clip purchase sound
			engfunc(EngFunc_EmitSound, id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Set napalm flag on the weapon entity (bugfix)
			set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
		}
		else
		{
			client_print(id, print_center, "You cannot carry any more napalms!")
			return PLUGIN_HANDLED;
		}
	}
	else
	{
		// Give napalm
		fm_give_item(id, AFFECTED_CLASSNAMES[g_affect-1])
		
		// Get napalm weapon entity now it exists
		napalm_weaponent = fm_get_napalm_entity(id, g_affect)
		
		// Set napalm flag on the weapon entity
		set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
		
		// Set napalm ammo
		set_pev(napalm_weaponent, PEV_NAPALM_AMMO, 1)
	}
	
	// Calculate new money amount
	static newmoney
	newmoney = fm_get_user_money(id) - g_price
	
	// Update money offset
	fm_set_user_money(id, newmoney)
	
	// Update money on HUD
	message_begin(MSG_ONE, g_msgMoney, _, id)
	write_long(newmoney) // amount
	write_byte(1) // flash
	message_end()
	
	return PLUGIN_HANDLED;
}

// Napalm Grenade Explosion
napalm_explode(ent)
{
	// Get attacker and its team
	static attacker, attacker_team
	attacker = pev(ent, pev_owner)
	attacker_team = pev(ent, pev_team)
	
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Custom explosion effect
	create_blast2(originF)
	
	
	
	// Collisions
	static victim
	victim = -1
	new podpalonych = 0;
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_radius)) != 0)
	{
		// Only effect alive players
		if (!is_user_alive(victim))
			continue;
		
		// Check if myself is allowed
		if (!g_hitself && victim == attacker)
			continue;
		
		/*
			if( bb_get_class(victim) == class_WITCH )
				continue
		*/
				
		if( get_user_godmode(victim) )
			continue
		// Check if friendly fire is allowed
		if (!g_ff && victim != attacker && attacker_team == fm_get_user_team(victim))
			continue;
			
		// Heat icon
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
		
		// Our task params
		static params[2]
		params[0] = g_duration * 5 // duration
		params[1] = attacker // attacker
		
		podpalonych++
		// Set burning task on victim
		set_task(0.1, "burning_flame", victim+TASK_BURN, params, sizeof params)
	}
	//bb_add_mission(attacker, mission_FireMan, podpalonych)
	static origin[3]
	IVecFVec(origin, originF)
	// Napalm explosion sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, grenade_fire[random_num(0, sizeof grenade_fire - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin, 0)
	
	write_byte(TE_DLIGHT)			
	write_coord(origin[0]);	
	write_coord(origin[1]);
	write_coord(origin[2]);			
	write_byte(25)			

	write_byte(200); 
	write_byte(100); 
	write_byte(0); 
	
	write_byte(10)			
	write_byte(50)			
	message_end()
}

// Burning Task
public burning_flame(args[2], taskid)
{
	// Player died/disconnected
	if (!is_user_alive(ID_BURN))
		return;
	
	// Get player origin and flags
	static Float:originF[3], flags
	pev(ID_BURN, pev_origin, originF)
	flags = pev(ID_BURN, pev_flags)
	
	// In water or burning stopped
	if ((flags & FL_INWATER) || BURN_DURATION < 1)
	{
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		return;
	}
	
	// Randomly play burning sounds
	if (g_screamrate > 0 && random_num(1, g_screamrate) == 1)
		engfunc(EngFunc_EmitSound, ID_BURN, CHAN_VOICE, grenade_fire_player[random_num(0, sizeof grenade_fire_player - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Fire slow down
	if (g_slowdown > 0.0 && (flags & FL_ONGROUND))
	{
		static Float:velocity[3]
		pev(ID_BURN, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, g_slowdown, velocity)
		set_pev(ID_BURN, pev_velocity, velocity)
	}
	
	// Get victim's health
	static health
	health = pev(ID_BURN, pev_health)
	
	new Float:g_damage=random_float(10.0,50.0)
	
	lastAttacker[ID_BURN]=BURN_ATTACKER
	// Take damage from the fire
	if (health - g_damage > 0){
		set_pev(ID_BURN, pev_health, (health - g_damage))
	}else if (g_cankill)
	{
		
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		// bb_kill_respawn(BURN_ATTACKER, ID_BURN)
		return;
	}
	
	// Flame sprite
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0)) // x
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0)) // y
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(10, 16)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease task cycle count
	BURN_DURATION -= 1;
	
	// Keep sending flame messages
	set_task(0.2, "burning_flame", taskid, args, sizeof args)
}

// Napalm Grenade: Fire Blast (originally made by Avalanche in Frostnades)
create_blast2(const Float:originF[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITETRAIL) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]) // z axis
	write_short(fire2) // sprite index
	write_byte(35) // sprite count
	write_byte(5) // life
	write_byte(1) // size
	write_byte(60) // velocity
	write_byte(60) // velocity
	message_end() 
	
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(100) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(50) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(0) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

// Register Ham Forwards for CZ bots
public register_ham_czbots(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (g_hamczbots || !get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	RegisterHamFromEntity(Ham_Touch, id, "fw_TouchPlayer")
	
	// Ham forwards for CZ bots succesfully registered
	g_hamczbots = true;
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF);
	set_pev(ent, pev_origin, originF);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	static save
	save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, id);
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent);
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

// Finds napalm grenade weapon entity of a player
stock fm_get_napalm_entity(id, g_affect)
{
	return fm_find_ent_by_owner(-1, AFFECTED_CLASSNAMES[g_affect-1], id);
}

// Get User Current Weapon Entity
stock fm_get_user_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

// Get Weapon Entity's CSW_ ID
stock fm_get_weapon_ent_id(ent)
{
	return get_pdata_int(ent, OFFSET_WEAPONID, OFFSET_LINUX_WEAPONS);
}

// Get Weapon Entity's Owner
stock fm_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// Get User Money
stock fm_get_user_money(id)
{
	return get_pdata_int(id, OFFSET_CSMONEY, OFFSET_LINUX);
}

// Set User Money
stock fm_set_user_money(id, amount)
{
	set_pdata_int(id, OFFSET_CSMONEY, amount, OFFSET_LINUX);
}

// Get User Team
stock fm_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

// Returns whether user is in a buyzone
stock fm_get_user_buyzone(id)
{
	if (get_pdata_int(id, OFFSET_MAPZONE) & PLAYER_IN_BUYZONE)
		return 1;
	
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
