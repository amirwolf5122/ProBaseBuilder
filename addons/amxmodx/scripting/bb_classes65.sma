#include <amxmodx>
#include <basebuilder>
#include <hamsandwich>
#include <fun>
#include <cstrike>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

// Mummy Zombie Attributes
new const zclass1_name[] = { "Mummy Zombie" }
new const zclass1_info[] = { "=Balanced=" }
new const zclass1_model[] = { "bb_mummy" }
new const zclass1_clawmodel[] = { "v_mummy" }
const zclass1_health = 3500
const zclass1_speed = 270
const Float:zclass1_gravity = 0.8
const zclass1_adminflags = ADMIN_ALL

// Alien Zombie Attributes
new const zclass2_name[] = { "Speed Zombie" }
new const zclass2_info[] = { "HP-- Speed++" }
new const zclass2_model[] = { "bb_fast" }
new const zclass2_clawmodel[] = { "v_bloodyhands" }
const zclass2_health = 3000
const zclass2_speed = 320
const Float:zclass2_gravity = 0.8
const zclass2_adminflags = ADMIN_ALL

// Stamper Zombie Attributes
new const zclass3_name[] = { "Jumper Zombie" }
new const zclass3_info[] = { "HP- Jump+" }
new const zclass3_model[] = { "bb_stamper" }
new const zclass3_clawmodel[] = { "v_stamper" }
const zclass3_health = 3000
const zclass3_speed = 270
const Float:zclass3_gravity = 0.4
const zclass3_adminflags = ADMIN_ALL

// Venom Zombie Attributes
new const zclass4_name[] = { "Tanker Zombie" }
new const zclass4_info[] = { "HP++ Speed-" }
new const zclass4_model[] = { "bb_zombie_big" }
new const zclass4_clawmodel[] = { "v_big" }
const zclass4_health = 4500
const zclass4_speed = 260
const Float:zclass4_gravity = 0.8
const zclass4_adminflags = ADMIN_ALL

/*============================================================================*/


// Zombie Classes MUST be registered on plugin_precache
public plugin_precache()
{
	register_plugin("[BB] Default Zombie Classes", "8.2", "Tirant")
	
	// Register all classes
	bb_register_zombie_class(zclass1_name, zclass1_info, zclass1_model, zclass1_clawmodel, zclass1_health, zclass1_speed, zclass1_gravity, 0.0, zclass1_adminflags)
	bb_register_zombie_class(zclass2_name, zclass2_info, zclass2_model, zclass2_clawmodel, zclass2_health, zclass2_speed, zclass2_gravity, 0.0, zclass2_adminflags)
	bb_register_zombie_class(zclass3_name, zclass3_info, zclass3_model, zclass3_clawmodel, zclass3_health, zclass3_speed, zclass3_gravity, 0.0, zclass3_adminflags)
	bb_register_zombie_class(zclass4_name, zclass4_info, zclass4_model, zclass4_clawmodel, zclass4_health, zclass4_speed, zclass4_gravity, 0.0, zclass4_adminflags)
}

#if defined NEMESIS_ARMOR
public plugin_init()
{
	RegisterHam(Ham_Spawn, "player", "ham_PlayerSpawn_Post", 1)
}

public ham_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id))
		return ;
		
	if (bb_is_user_zombie(id) && bb_get_user_zombie_class(id) == g_zclass_Nemesis)
	{
		give_item(id, "item_assaultsuit");
		cs_set_user_armor(id, NEMESIS_ARMOR, CS_ARMOR_VESTHELM);
	}
}
#endif
