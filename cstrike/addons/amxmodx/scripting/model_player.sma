#include <amxmodx>
#include <hamsandwich>
#include <cstrike>
#include <amxmisc>

//Spicial thanks for OciXCrom

new const Version[ ] = "1.0.1";
new const g_szModelFile[ ] = "CustomModels.ini";

enum _:ModelData
{ 
    Model_Name[ 64 ],
    Model_Team,
    Model_Flag
}

new Array:g_aModels
new eModel[ ModelData ]

public plugin_init( ) 
{
    register_plugin( "Cs Models", Version, "Supremache" );
    RegisterHam( Ham_Spawn, "player", "CBasePlayer_Spawn", 1 )
    
    if( ArraySize( g_aModels ) )
    {
        log_amx( "Loaded %d models", ArraySize( g_aModels ) )
    }
}

public plugin_precache() 
{
    g_aModels = ArrayCreate( ModelData );
    ReadFile( );
}
    
public CBasePlayer_Spawn( id )
{
    if( is_user_alive( id ) )
    {
        for( new iFlags = get_user_flags( id ), iTeam = get_user_team( id ), i; i < ArraySize( g_aModels ); i++ )
        {
            ArrayGetArray( g_aModels, i, eModel )
            
            if( ( !eModel[ Model_Team ] || iTeam == eModel[ Model_Team ] ) && ( iFlags & eModel[ Model_Flag ] == eModel[ Model_Flag ] ) ) //allow multi flags
            {
                cs_set_user_model( id, eModel[ Model_Name ] )
                break;
            }
            else cs_reset_user_model( id );
        }
    }
}

ReadFile( )
{
    new g_szFile[ 128 ], g_szConfigs[ 64 ];
    get_configsdir( g_szConfigs, charsmax( g_szConfigs ) )
    formatex( g_szFile, charsmax( g_szFile ), "%s/%s", g_szConfigs, g_szModelFile )
    
    new iFile = fopen( g_szFile, "rt" );
    
    if( iFile )
    {
        new szData[ 512 ], szModel[ 64 ], szTeam[ 32 ], szFlag[ 32 ];
        
        while( fgets( iFile, szData, charsmax( szData ) ) )
        {    
            trim( szData );
            
            switch( szData[ 0 ] )
            {
                case EOS, ';',  '#', '/':
                {
                    continue;
                }

                default:
                {
                    szFlag[ 0 ] = ADMIN_ALL
                    szTeam[ 0 ] = EOS
                    
                    parse ( szData, szModel, charsmax( szModel ), szTeam, charsmax( szTeam ), szFlag, charsmax( szFlag ) )
                    
                    trim( szModel ); trim( szTeam ); trim( szFlag );
                    
                    if( szModel[ 0 ] )
                    {
                        precache_player_model( szModel )
                        copy( eModel[ Model_Name ], charsmax( eModel[ Model_Name ] ), szModel )
                    
                        eModel[ Model_Team ] = clamp( str_to_num( szTeam ), 0, 3 )
                        eModel[ Model_Flag ] = read_flags( szFlag )
                        
                        ArrayPushArray( g_aModels, eModel )
                    }
                }
            }
        }
        fclose( iFile );
    }
    else
    {
        format( g_szFile, charsmax( g_szFile ), "ERROR: ^"%s^" not found!", g_szFile )
        set_fail_state( g_szFile )
    }
} 

//by OciXCrom
precache_player_model(const szModel[], &id = 0)
{
    new model[128]
    formatex(model, charsmax(model), "models/player/%s/%sT.mdl", szModel, szModel)

    if(file_exists(model))
    {
        id = precache_generic(model)
    }

    static const extension[] = "T.mdl"
    #pragma unused extension

    copy(model[strlen(model) - charsmax(extension)], charsmax(model), ".mdl")
    
    if(!file_exists(model))
    {
        log_amx( "ERROR: model ^"%s^" not found!", model )
        return 1; // dont precache it if file doesn't exists
    }
    
    return precache_generic(model)
}