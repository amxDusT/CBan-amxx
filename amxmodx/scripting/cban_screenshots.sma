#include < amxmodx >
#include < amxmisc >
#include < cban_main >

#define DEFAULT_SCREENSHOTS		3

enum _:eScreenData
{
    ADMIN_NAME[ MAX_NAME_LENGTH * 2 ],
    PLAYER_NAME[ MAX_NAME_LENGTH ],
    PLAYER_IP[ MAX_IP_LENGTH ],
    PLAYER_STEAMID[ MAX_STEAMID_LENGTH ],
    SS_NUMBER,
    SS_TAKEN
}

new const TASK_SS = 4213
new dataSize = MAX_NAME_LENGTH * 3 + MAX_IP_LENGTH + MAX_STEAMID_LENGTH + SS_NUMBER + SS_TAKEN + 6;

public plugin_init()
{
    register_plugin( "[CBAN] Screenshots", VERSION, "DusT" );

    register_concmd( "amx_ss", "CmdScreenshot", ADMIN_FLAG_SCREENSHOTS, "< nick | steamid | #id > [ screens ] - take screenshots on player." );
}

public plugin_natives()
{
    register_native( "CBan_TakeScreenshot", "_CBan_TakeScreenshot" );
}

public CmdScreenshot( id, level, cid )
{
    if( !cmd_access( id, level, cid, 2 ) )
        return PLUGIN_HANDLED;
    
    new target[ 32 ];    
    read_argv( 1, target, charsmax( target ) );

    new pid = cmd_target( id, target, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );

    if( !pid )
        return PLUGIN_HANDLED;
    
    new screens;
    if( read_argc() > 2 )
        screens = read_argv_int( 2 );
    
    Screenshot( id, pid, screens );

    return PLUGIN_HANDLED;
}

Screenshot( admin, player, screens = 0 )
{
    if( !player || !is_user_connected( player ) )
    {
        console_print( admin, "Player is not connected!" );
        return;
    }
    
    if( screens <= 0 )
        screens = DEFAULT_SCREENSHOTS;

    new eData[ eScreenData ];
    get_user_name( admin, eData[ ADMIN_NAME ], charsmax( eData[ ADMIN_NAME ] ) );
    
    get_user_name( player, eData[ PLAYER_NAME ], charsmax( eData[ PLAYER_NAME ] ) );
    get_user_ip( player, eData[ PLAYER_IP ], charsmax( eData[ PLAYER_IP ] ) );
    get_user_authid( player, eData[ PLAYER_STEAMID ], charsmax( eData[ PLAYER_STEAMID ] ) );
    
    eData[ SS_NUMBER ] = screens;

    client_cmd( player, "net_graph 3; wait;" );
    client_cmd( player, "stop; wait;" );

    set_task( 0.3, "PrepareScreen", player, eData, dataSize );
}

public PrepareScreen( eData[], id )
{
    if( !is_user_connected( id ) )
        return;
    
    static szServerName[ MAX_NAME_LENGTH * 2 ];
    if( !szServerName[ 0 ] )
        get_user_name( 0, szServerName, charsmax( szServerName ) );

    eData[ SS_TAKEN ]++;

    new szDate[ 64 ];
    format_time( szDate, charsmax( szDate ), "%d/%m/%Y - %H:%M:%S" );
    
    client_print_color( id, print_team_red, "^4[CBAN]^1 Admin ^3%s^1 took a screenshot of you!", eData[ ADMIN_NAME ] );
    client_print_color( id, print_team_red, "^4[CBAN]^1 SS Number: ^3%d^1/%d. Date: ^3%s^1", eData[ SS_TAKEN ], eData[ SS_NUMBER ], szDate );
    client_print_color( id, print_team_red, "^4[CBAN]^1 Name: ^3%n^1 IP: ^3%s^1 SteamID: ^3%s^1", id, eData[ PLAYER_IP ], eData[ PLAYER_STEAMID ] );
    client_print_color( id, print_team_red, "^4[CBAN]^1 This is a ^4Screenshot^1 taken on ^4%s^1 ^n", szServerName );

    set_task( 0.1, "TakeScreenshots", id + TASK_SS );

    if( eData[ SS_TAKEN ] < eData[ SS_NUMBER ] )
        set_task( 0.4, "PrepareScreen", id, eData, dataSize );
    
}

public TakeScreenshots( id )
{
    client_cmd( id - TASK_SS, "snapshot;wait;" );
}

public _CBan_TakeScreenshot( plugin, argc )
{
    Screenshot( get_param( 1 ), get_param( 2 ), get_param( 3 ) );
}

public CBan_OnPlayerBannedPre( player, admin )
{
    Screenshot( admin, player );
}