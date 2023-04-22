#include <amxmodx>
#include <hamsandwich>

#if AMXX_VERSION_NUM < 183 || !defined set_dhudmessage
	#tryinclude <dhudmessage>

	#if !defined _dhudmessage_included
		#error "dhudmessage.inc" is missing in your "scripting/include" folder. Download it from: "https://amxx-bg.info/forum/inc/"
	#endif
#endif

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

#if !defined MAX_NAME_LENGTH
const MAX_NAME_LENGTH = 32
#endif

//#define STATS_COLOR 255, 255, 0
#define STATS_POSITION -1.0, 0.20
#define STATS_DURATION 5.0
#define STATS_EFFECT 0

enum _:PlayerStats
{
	Kills,
	Damage
}

new const SORTING_FUNCTIONS[][] = { "sort_players_by_kills", "sort_players_by_damage" }

new g_iPlayerStats[MAX_PLAYERS + 1][PlayerStats]

public plugin_init()
{
	register_plugin("Best Player DHUD", "1.0", "OciXCrom")
	register_logevent("OnRoundEnd", 2, "1=Round_End")
	register_event("DeathMsg", "OnPlayerKilled", "a")
	RegisterHam(Ham_TakeDamage, "player", "OnTakeDamage", 1)
}

public client_putinserver(id)
{
	g_iPlayerStats[id][Kills] = 0
	g_iPlayerStats[id][Damage] = 0
}

public OnPlayerKilled()
{
	new iAttacker = read_data(1), iVictim = read_data(2)

	if(is_user_connected(iAttacker) && iAttacker != iVictim)
	{
		g_iPlayerStats[iAttacker][Kills]++
	}
}

public OnTakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	g_iPlayerStats[iAttacker][Damage] += floatround(fDamage)
}

public OnRoundEnd()
{
	new iPlayers[MAX_PLAYERS], szName[sizeof(SORTING_FUNCTIONS)][MAX_NAME_LENGTH], iBest[sizeof(SORTING_FUNCTIONS)], iPnum
	get_players(iPlayers, iPnum)

	if(!iPnum)
	{
		return
	}

	for(new i; i < sizeof(SORTING_FUNCTIONS); i++)
	{
		SortCustom1D(iPlayers, iPnum, SORTING_FUNCTIONS[i])
		iBest[i] = iPlayers[0]
		get_user_name(iBest[i], szName[i], charsmax(szName[]))
	}

	set_dhudmessage(random(256), random(256), random(256), STATS_POSITION, .effects = STATS_EFFECT, .holdtime = STATS_DURATION)
	show_dhudmessage(0, "Best Players:^n%s: %i Killed^n%s: %i Damage",\
	szName[Kills], g_iPlayerStats[iBest[Kills]][Kills], szName[Damage], g_iPlayerStats[iBest[Damage]][Damage])

	arrayset(g_iPlayerStats[Kills], 0, sizeof(g_iPlayerStats[]))
	arrayset(g_iPlayerStats[Damage], 0, sizeof(g_iPlayerStats[]))
}

public sort_players_by_kills(id1, id2)
{
	return g_iPlayerStats[id2][Kills] - g_iPlayerStats[id1][Kills]
}

public sort_players_by_damage(id1, id2)
{
	return g_iPlayerStats[id2][Damage] - g_iPlayerStats[id1][Damage]
}