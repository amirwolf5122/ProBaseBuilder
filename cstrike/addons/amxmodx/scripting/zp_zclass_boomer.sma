#include < amxmodx >
#include < cstrike >
#include < engine >
#include < basebuilder >
#include < cromchat >

new const zclass_name[ ] = "Boomer Zombie"
new const zclass_info[ ] = "[ADMIN 'G']"
new const zclass_model[ ] = "zombie_boomer"
new const zclass_clawmodel[ ] = "v_knife_boomer"
const zclass_health = 4000
const zclass_speed = 260
const Float:zclass_gravity = 0.74
const zclass_adminflags = ADMIN_LEVEL_E

new const vomit_sprite[ ] = "sprites/poison.spr"
new const vomit_sounds[ 3 ][ ] = 
{ "zombie_plague/male_boomer_vomit_01.wav",
"zombie_plague/male_boomer_vomit_03.wav",
"zombie_plague/male_boomer_vomit_04.wav" }

new const explode_sounds[ 3 ][ ] = 
{ "zombie_plague/explo_medium_09.wav",
"zombie_plague/explo_medium_10.wav",
"zombie_plague/explo_medium_14.wav" }

new g_zclass_boomer, g_msgid_ScreenFade, g_iMaxPlayers, vomit, cvar_vomitdist, cvar_explodedist, cvar_wakeuptime, cvar_vomitcooldown, cvar_victimrender, cvar_inuse, cvar_boomer_reward

// Cooldown hook
new Float:g_iLastVomit[ 33 ]

// Stupid spam when using IN_USE button
new bool:g_iHateSpam[ 33 ]

public plugin_init( )
{
	register_plugin( "[ZP] Zombie Class: Boomer", "1.2 BETA", "Excalibur.007" )
	
	register_clcmd( "boomer_vomit", "clcmd_vomit" )
	
	register_event( "DeathMsg", "event_DeathMsg", "a" )
	
	cvar_vomitdist = register_cvar( "zp_boomer_vomit_dist", "300" )
	cvar_explodedist = register_cvar( "zp_boomer_explode_dist", "300" )
	cvar_wakeuptime = register_cvar( "zp_boomer_blind_time", "5" )
	cvar_vomitcooldown = register_cvar( "zp_boomer_vomit_cooldown", "25.0" )
	cvar_victimrender = register_cvar( "zp_boomer_victim_render", "1" )
	cvar_inuse = register_cvar( "zp_boomer_in_use_bind", "1" )
	cvar_boomer_reward = register_cvar( "zp_boomer_ap_reward", "300" )
	
	register_clcmd("drop", "cmd_cdsa")
	
	g_msgid_ScreenFade = get_user_msgid( "ScreenFade" )
	
	/* - We hook it at here to optimize the plugin a bit
	since sv_maxplayers cvar CANNOT BE CHANGED during in-game - */
	g_iMaxPlayers = get_maxplayers( )
}

public plugin_precache( )
{
	g_zclass_boomer = zp_register_zombie_class( zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, 0.0, zclass_adminflags )
	
	vomit = precache_model( vomit_sprite )
	
	for( new i = 0; i < sizeof vomit_sounds; i ++ )
		precache_sound( vomit_sounds[ i ] )
		
	for( new i = 0; i < sizeof explode_sounds; i ++ )
		precache_sound( explode_sounds[ i ] )
}

public zp_user_infected_post( id, infector )
{
	if( zp_get_user_zombie_class( id ) == g_zclass_boomer )
	{
		if( get_pcvar_num( cvar_inuse ) )
		{
			CC_SendMessage(id,"^1[BB] ^4Press your defuse/plant button(Default: E) to vomit!. Made by Excalibur.007" )
		}
		else
		{
			CC_SendMessage(id,"^1[BB] ^4To vomit, ^"bind [key] boomer_vomit^". Made by Excalibur.007" )
		}
	}
}

public cmd_cdsa( id )
{
	if( !is_user_alive( id ) || !is_user_connected( id ) || bb_is_build_phase() || bb_is_prep_phase() || !zp_get_user_zombie( id ) || zp_get_user_zombie_class( id ) != g_zclass_boomer || !get_pcvar_num( cvar_inuse ) || g_iHateSpam[ id ] )
		return PLUGIN_CONTINUE
		
		g_iHateSpam[ id ] = true
		clcmd_vomit( id )
		set_task( 1.0, "StopSpam_XD", id )

	return PLUGIN_CONTINUE
}

public clcmd_vomit( id )
{
	if( !is_user_alive( id ) || !is_user_connected( id ) || !zp_get_user_zombie( id ) || zp_get_user_zombie_class( id ) != g_zclass_boomer )
		return PLUGIN_HANDLED
	
	if( get_gametime( ) - g_iLastVomit[ id ] < get_pcvar_float( cvar_vomitcooldown ) )
	{
		CC_SendMessage(id,"^3[BB] ^1You need to wait for ^3%.f ^1sec. ^1to vomit again!", get_pcvar_float( cvar_vomitcooldown ) - ( get_gametime( ) - g_iLastVomit[ id ] ) )
		return PLUGIN_HANDLED
	}
	
	g_iLastVomit[ id ] = get_gametime( )
	
	new target, body, dist = get_pcvar_num( cvar_vomitdist )
	get_user_aiming( id, target, body, dist )
		
	new vec[ 3 ], aimvec[ 3 ], velocityvec[ 3 ]
	new length
	
	get_user_origin( id, vec )
	get_user_origin( id, aimvec, 2 )
	
	velocityvec[ 0 ] = aimvec[ 0 ] - vec[ 0 ]
	velocityvec[ 1 ] = aimvec[ 1 ] - vec[ 1 ]
	velocityvec[ 2 ] = aimvec[ 2 ] - vec[ 2 ]
	length = sqrt( velocityvec[ 0 ] * velocityvec[ 0 ] + velocityvec[ 1 ] * velocityvec[ 1 ] + velocityvec[ 2 ] * velocityvec[ 2 ] )
	velocityvec[ 0 ] = velocityvec[ 0 ] * 10 / length
	velocityvec[ 1 ] = velocityvec[ 1 ] * 10 / length
	velocityvec[ 2 ] = velocityvec[ 2 ] * 10 / length
	
	new args[ 8 ]
	args[ 0 ] = vec[ 0 ]
	args[ 1 ] = vec[ 1 ]
	args[ 2 ] = vec[ 2 ]
	args[ 3 ] = velocityvec[ 0 ]
	args[ 4 ] = velocityvec[ 1 ]
	args[ 5 ] = velocityvec[ 2 ]
	
	set_task( 0.1, "create_sprite", 0, args, 8, "a", 3 )
	
	emit_sound( id, CHAN_STREAM, vomit_sounds[ random_num( 0, 2 ) ], 1.0, ATTN_NORM, 0, PITCH_HIGH )
	
	if( is_valid_ent( target ) && is_user_alive( target ) && is_user_connected( target ) && !zp_get_user_zombie( target ) && get_entity_distance( id, target ) <= dist )
	{
		message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, target )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( 0x0004 )
		write_byte( 79 )
		write_byte( 180 )
		write_byte( 61 )
		write_byte( 255 )
		message_end( )
		
		if( get_pcvar_num( cvar_victimrender ) )
		{
			set_rendering( target, kRenderFxGlowShell, 79, 180, 61, kRenderNormal, 25 ) 
		}
		set_task( get_pcvar_float( cvar_wakeuptime ), "victim_wakeup", target )
		
		if( !get_pcvar_num( cvar_boomer_reward ) )
			return PLUGIN_HANDLED
			
		//new setmoney = cs_get_user_money(id) + get_pcvar_num( cvar_boomer_reward )
		cs_set_user_money(id, cs_get_user_money(id) + get_pcvar_num( cvar_boomer_reward ))
		CC_SendMessage(id,"^1[BB] ^4You've earned ^1%i ^1for vomiting on a human!", get_pcvar_num( cvar_boomer_reward ) )
	}
	return PLUGIN_HANDLED
}

public create_sprite( args[ ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 120 )
	write_coord( args[ 0 ] )
	write_coord( args[ 1 ] )
	write_coord( args[ 2 ] )
	write_coord( args[ 3 ] )
	write_coord( args[ 4 ] )
	write_coord( args[ 5 ] )
	write_short( vomit )
	write_byte( 8 )
	write_byte( 70 )
	write_byte( 100 )
	write_byte( 5 )
	message_end( )
	
	return PLUGIN_CONTINUE
}

public victim_wakeup( id )
{
	if( !is_user_connected( id ) )
		return PLUGIN_HANDLED
	
	message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, id )
	write_short( ( 1<<12 ) )
	write_short( 0 )
	write_short( 0x0000 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 255 )
	message_end( )
	
	if( get_pcvar_num( cvar_victimrender ) )
	{
		set_rendering( id )
	}
	return PLUGIN_HANDLED
}

public StopSpam_XD( id )
{
	if( is_user_connected( id ) )
	{	
		g_iHateSpam[ id ] = false
	}
}
public event_DeathMsg( )
{
	new id = read_data( 2 )
	
	if( !is_user_connected( id ) || !zp_get_user_zombie( id ) || zp_get_user_zombie_class( id ) != g_zclass_boomer )
		return PLUGIN_HANDLED
		
	emit_sound( id, CHAN_STREAM, explode_sounds[ random_num( 0, 2 ) ], 1.0, ATTN_NORM, 0, PITCH_HIGH )
	
	for( new i = 1; i <= g_iMaxPlayers; i ++ )
	{
		if( !is_valid_ent( i ) || !is_user_alive( i ) || !is_user_connected( i ) || zp_get_user_zombie( i ) || get_entity_distance( id, i ) > get_pcvar_num( cvar_explodedist ) )
			return PLUGIN_HANDLED
			
		message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, i )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( 0x0004 )
		write_byte( 79 )
		write_byte( 180 )
		write_byte( 61 )
		write_byte( 255 )
		message_end( )
		
		if( get_pcvar_num( cvar_victimrender ) )
		{
			set_rendering( i, kRenderFxGlowShell, 79, 180, 61, kRenderNormal, 25 )
		}
		
		set_task( get_pcvar_float( cvar_wakeuptime ), "victim_wakeup", i )
		
		if( !get_pcvar_num( cvar_boomer_reward ) )
			return PLUGIN_HANDLED
			
		cs_set_user_money(id, cs_get_user_money(id) + ( get_pcvar_num( cvar_boomer_reward ) * i))
		CC_SendMessage(id,"^1[BB] ^4You've earned ^1%i ^1for exploding on ^1%i ^4humans!", ( get_pcvar_num( cvar_boomer_reward ) * i ), i )
	}
	return PLUGIN_HANDLED
}

public sqrt( num )
{
	new div = num
	new result = 1
	while( div > result )
	{
		div = ( div + result ) / 2
		result = num / div
	}
	return div
}
