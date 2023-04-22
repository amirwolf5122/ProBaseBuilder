#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#if !defined Ham_CS_Player_ResetMaxSpeed
const Ham:Ham_CS_Player_ResetMaxSpeed = Ham_Item_PreFrame
#endif


const Float:PLAYER_SPEED = 260.0
const Float:PLAYER_GRAVITY = 600.0
const DEFAULT_GRAVITY = 800

public plugin_init()
{
    register_plugin("Speed + Gravity", "1.0", "OciXCrom")
    RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "OnChangeSpeed", 1)
    RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
}

public OnChangeSpeed(id)
{
    if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
    {
        set_user_maxspeed(id, PLAYER_SPEED)
    }
}

public OnPlayerSpawn(id)
{
    if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT)
    {
        set_user_gravity(id, PLAYER_GRAVITY / DEFAULT_GRAVITY)
    }
}