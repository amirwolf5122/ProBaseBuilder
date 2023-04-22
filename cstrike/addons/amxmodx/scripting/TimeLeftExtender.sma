/*
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at
 *  your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software Foundation,
 *  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 *  All date formats are in european format (dd.mm.yyyy)
 *
 *                                  _
 *                                 | | _
 *              _ __  _ ______  ___| |(_) __ ___  __
 *             | '_ \| '_/  _ \/  _  || |/ _' | \/ /
 *             | |_) | | \ (_) \ (_| || | (_| |\  /
 *             | .__/|_|  \____/\____||_|\__. |/ /
 *             |_|                       |___//_/
 *      
 *  File:    TimeLeftExtender.sma
 *
 *  Title:   TimeLeft Extender
 *
 *  Version: 1.2
 *
 *  Feel free to redistribute and modify this file,
 *  But please give me some credits.
 *
 *  Author:  prodigy
 *           pro.digy@gmx.net
 *
 *  Last Changes:     17.07.2007 (dd.mm.yyyy)
 *
 *  Credits: - Johnny got his gun @ http://forums.alliedmods.net/showthread.php?p=67909
 *             For his code about detecting a round end.. and inspiring me to write this
 *           - The AMXX Team for some code from the timeleft.sma
 *           - MaximusBrood @ http://forums.alliedmods.net/showthread.php?p=236886
 *             For the color-code
 *           - neuromancer: Fixing the bug where the plugin "randomly" changed the map for some unknown reason
 *
 *  Purpose: This plugin removes the timelimit CATCH_MAPCHANGE_AT seconds before mapchange
 *           and makes the round end after the current round delaying the change for
 *           amx_tle_chattime seconds.
 *           When mapchange is blocked typing timeleft displays that the current round is the last.
 *
 *
 *  CVars:
 *           amx_tle_enabled [1]/0   - Controls wether the plugin is enabled or not. (default 1)
 *           amx_tle_usehud [1]/0    - Controls wether to use HUD message announcement or not. (default 1)
 *           amx_tle_chattime [7]    - Controls the time people have to chat before actual change occurs. (default 7)
 *           amx_tle_catchat [5]     - Controls at which second of timeleft the plugin should
 *                                       catch the mapchange and block it. (default 5)
 *           amx_tle_textcolor 0-[2] // Sets the color of the "This is the last round" message.
 *                                   //  0 = Normal chat color
 *                                   //  1 = Team color (CT: blue, T: red)
 *                                   //  2 = Green
 *
 *  Commands:
 *           amx_changenow          - Changes map immediatley to current amx_nextmap
 *           say changenow          - Changes map immediatley to current amx_nextmap
 *           say timeleft           - If the plugin blocked the mapchange, saying timeleft will
 *                                      display "This is the last round." in the users language.
 *
 *  Copyright (c) 2007 by Sebastian G. alias prodigy
 *
 *  Change-Log:
 *    1.2 (17.07.2007):
 *       Bug Fix:
 *         o Fixed the bug where the plugin "randomly" changed the map for some unknown reason
 *    1.1a (08.05.2007):
 *       o changed cvars to pcvars
 *
 *    1.1 (30.04.2007): 
 *       Features:
 *         o Added amx_tle_textcolor and functionality
 *    
 *    1.0 (29.04.2007):
 *       o initial release
 *
 *    0.1 Alpha (29.04.2007):
 *       o Added functionality for everything in 1.0,
 *         basically I just renamed the Version number.
 */

#include <amxmodx>
#include <amxmisc>

#define TLE_ENABLED "1"
#define DEFAULT_CHATTIME "7"
#define DEFAULT_USEHUD "0"
#define CATCH_MAPCHANGE_AT "5" // seconds left when mapchange should be catched and blocked
#define DEFAULT_TEXTCOLOR "2"
#define CHANGE_ACCESS ADMIN_MAP

new bool:g_mrset
new g_timelimit
new cvar_tle_enabled, cvar_tle_chattime, cvar_tle_catchat, cvar_tle_usehud, cvar_tle_textcol

public plugin_init() {
  register_plugin("TimeLeft Extender", "0.1a", "prodigy")
  register_dictionary("TimeLeftExtender.txt")
  cvar_tle_enabled  = register_cvar("amx_tle_enabled", TLE_ENABLED)
  cvar_tle_chattime = register_cvar("amx_tle_chattime", DEFAULT_CHATTIME)
  cvar_tle_catchat  = register_cvar("amx_tle_catchat", CATCH_MAPCHANGE_AT) // changes are only registered after a map change
  cvar_tle_usehud   = register_cvar("amx_tle_usehud", DEFAULT_USEHUD) // use hud message?
  cvar_tle_textcol  = register_cvar("amx_tle_textcolor", DEFAULT_TEXTCOLOR) // text color to use
  register_event("SendAudio","event_roundEnd","a","2=%!MRAD_terwin","2=%!MRAD_ctwin","2=%!MRAD_rounddraw")
  register_clcmd("amx_changenow", "changeNow", CHANGE_ACCESS, "- changes map immediately to current amx_nextmap")
  register_clcmd("say changenow", "changeNow", CHANGE_ACCESS, "- changes map immediately to current amx_nextmap")
  register_clcmd("say timeleft", "timeleftInfo", 0, "- when timelimit is 0 displays last round")

  g_mrset = false
  set_task(get_pcvar_float(cvar_tle_catchat), "initMapchangeEvent", 901337, "", 0, "d", 1) // Catch mapchange amx_tle_catchat seconds before change
}

public timeleftInfo(id)
{
  if(g_mrset == true)
  {
    client_print(0, print_chat, "%L.", LANG_PLAYER, "LAST_ROUND")
    return PLUGIN_HANDLED
  }
  return PLUGIN_CONTINUE
}

public changeNow(id)
{
  if(get_pcvar_num(cvar_tle_enabled))
  {
    if(access(id, ADMIN_MAP))
    {
      new name[64], nextmap[32]
      get_user_name(id, name, 63)
      get_cvar_string("amx_nextmap", nextmap, 31)
      switch(get_cvar_num("amx_show_activity"))
      {
        case 2: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_CHANGENOW_2", name, nextmap)
        case 1: client_print(0, print_chat, "%L", LANG_PLAYER, "ADMIN_CHANGENOW_1", nextmap)
      }
      initMapChange()
      return PLUGIN_HANDLED
    }
    return PLUGIN_CONTINUE
  }
  return PLUGIN_CONTINUE
}

public event_roundEnd() // roundend hook
{
  if(g_mrset == true)
  {
    g_mrset = false
    resetTimeLimit()
    initMapChange()
  }
  return PLUGIN_CONTINUE
}

public initMapchangeEvent() // initiate the main event, setting timelimit to 0 etc..
{
  if(get_pcvar_num(cvar_tle_enabled))
  {
    new m_timeleft = get_timeleft()
    new colorstring[5]
    if(m_timeleft <= get_pcvar_num(cvar_tle_catchat) && g_mrset == false)
    {
      switch(get_pcvar_num(cvar_tle_textcol))
      {
        case 2: copy(colorstring, 4, "^x04")
        case 1: copy(colorstring, 4, "^x03")
        case 0: copy(colorstring, 4, "^x01")
      }
      new message[64]
      format(message, 61, "%s%L.", colorstring, LANG_PLAYER, "LAST_ROUND")
      remove_task(901337)

      new plist[32], playernum, player;
      get_players(plist, playernum, "c");
      for(new i = 0; i < playernum; i++)
      {
        player = plist[i];
        message_begin(MSG_ONE, get_user_msgid("SayText"), {0,0,0}, player);
        write_byte(player);
        write_string(message);
        message_end();
      }

      if(get_pcvar_num(cvar_tle_usehud))
      {
        set_hudmessage(0, 255, 0, -1.0, 0.1)
        show_hudmessage(0, "> %L <", LANG_PLAYER, "LAST_ROUND")
      }
      g_mrset = true
      g_timelimit = get_cvar_num("mp_timelimit")
      set_cvar_num("mp_timelimit", 0)
    }
  }
}

public resetTimeLimit() // reset timelimit to value used before setting it to 0
{
  set_cvar_num("mp_timelimit", g_timelimit)
}

public initMapChange() // initiate the change
{
  message_begin(MSG_ALL, SVC_INTERMISSION) /* Taken from timeleft.sma */ // initiates a mapchange viewing the scores screen
  message_end()                                /*                         */
  set_task(get_pcvar_float(cvar_tle_chattime), "doMapChange", 901338, "", 0, "")
}

public doMapChange() // do the actual change
{
  if(task_exists(901338, 0))
  {
    remove_task(901338);
  }
  new nextmap[32]
  get_cvar_string("amx_nextmap", nextmap, 31)
  server_cmd("changelevel %s", nextmap)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1031\\ f0\\ fs16 \n\\ par }
*/
