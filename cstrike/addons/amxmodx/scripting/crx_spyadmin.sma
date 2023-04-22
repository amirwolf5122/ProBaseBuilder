#include <amxmodx>
#include <cromchat>

native agroups_update_user_group(id)
native cm_update_player_data(id)

new const PLUGIN_VERSION[] = "2.2"
const Float:REFRESH_DELAY = 0.1

new bool:g_bSpy[33], bool:g_bAdmin[33]
new g_iOriginalFlags[33], g_iDefaultFlag
new g_pAdminFlag, g_pAutoHide
new g_iAutoHide, g_iAdminFlag

new bool:g_bChatManager, bool:g_bAdminGroups

new const g_szCommands[][] = { "say /spy", "say_team /spy", "say /spyadmin", "say_team /spyadmin", "amx_spy", "amx_spyadmin" }

public plugin_init()
{
    register_plugin("Spy Admin", PLUGIN_VERSION, "OciXCrom")
    register_cvar("CRXSpyAdmin", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
    register_dictionary("SpyAdmin.txt")

    if(LibraryExists("agroups.inc", LibType_Library))
    {
        g_bAdminGroups = true
    }

    if(LibraryExists("chatmanager", LibType_Library))
    {
        g_bChatManager = true
    }

    g_pAdminFlag = register_cvar("spyadmin_adminflag", "e")
    g_pAutoHide = register_cvar("spyadmin_autohide", "0")

    for(new i; i < sizeof(g_szCommands); i++)
    {
        register_clcmd(g_szCommands[i], "CmdSpy")
    }

    CC_SetPrefix("&x04[SPY]")
}

public plugin_natives()
{
    set_module_filter("module_filter")
    set_native_filter("native_filter")
}

public module_filter(const szLibrary[])
{
    return (equal(szLibrary, "chatmanager") || equal(szLibrary, "agroups")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public native_filter(const szNative[], id, iTrap)
{
    return (!iTrap && (equal(szNative, "agroups_update_user_group") || equal(szNative, "cm_update_player_data"))) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public plugin_cfg()
{
    new szFlags[32]
    get_pcvar_string(g_pAdminFlag, szFlags, charsmax(szFlags))
    g_iAdminFlag = read_flags(szFlags)
    get_cvar_string("amx_default_access", szFlags, charsmax(szFlags))
    g_iDefaultFlag = read_flags(szFlags)
    g_iAutoHide = get_pcvar_num(g_pAutoHide)
}

public client_putinserver(id)
{
    spyadmin_checkadmin(id)
}

public spyadmin_checkadmin(id)
{
    g_bSpy[id] = false
    g_iOriginalFlags[id] = get_user_flags(id)
    g_bAdmin[id] = bool:(get_user_flags(id) & g_iAdminFlag)

    if(g_iAutoHide && g_bAdmin[id])
    {
        spyadmin_removeflags(id)
    }
}

public client_infochanged(id)
{
    static szNewName[32], szOldName[32]
    get_user_info(id, "name", szNewName, charsmax(szNewName))
    get_user_name(id, szOldName, charsmax(szOldName))

    if(!equal(szNewName, szOldName))
    {
        set_task(REFRESH_DELAY, "spyadmin_checkadmin", id)
    }
}

public CmdSpy(id)
{
    if(!g_bAdmin[id])
    {
        CC_SendMessage(id, "%L", id, "SPYADMIN_NOACCESS")
    }
    else
    {
        g_bSpy[id] ? spyadmin_setflags(id) : spyadmin_removeflags(id)
    }

    client_print(id, print_chat, "asd you")

    if(g_bAdminGroups)
    {
        client_print(id, print_chat, "updating you")
        agroups_update_user_group(id)
    }

    if(g_bChatManager)
    {
        cm_update_player_data(id)
    }

    return PLUGIN_HANDLED
}

public spyadmin_removeflags(id)
{
    remove_user_flags(id, g_iOriginalFlags[id], 0)
    set_user_flags(id, g_iDefaultFlag, 0)
    CC_SendMessage(id, "%L", id, "SPYADMIN_ACTIVATED")
    g_bSpy[id] = true
}

public spyadmin_setflags(id)
{
    remove_user_flags(id, g_iDefaultFlag, 0)
    set_user_flags(id, g_iOriginalFlags[id], 0)
    CC_SendMessage(id, "%L", id, "SPYADMIN_DEACTIVATED")
    g_bSpy[id] = false
}
