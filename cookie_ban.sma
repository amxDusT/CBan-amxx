#include < amxmodx >
#include < amxmisc >
#include < time >
#include < sqlx >

#define MOTD_CHECK          "http://localhost:8080/cs/CookieCheck/index.php"
#define MAX_COOKIE_SIZE     35
#define ADMIN_FLAG          ADMIN_BAN

new const host[] = "127.0.0.1";
new const user[] = "root";
new const pass[] = "";
new const db[]   = "mysql_dust";

new const bannedCookies[] = "db_ban_cookies";
new const checkedCookies[] = "db_check_cookies";

#if AMXX_VERSION_NUM < 183
    set_fail_state( "Plugin requires 1.8.3 or higher." );
#endif

new Handle:hTuple;

enum _:PlayerData
{   
    TIME = 0,
    ID,
    NAME[ 32 ],
    COOKIE[ MAX_COOKIE_SIZE ],
    REASON[ 64 ]
}

new pComplainUrl[ 128 ];
new pExpired;
new pServer;

public plugin_init()
{
    register_plugin( "Cookie Bans", "2.2.2", "DusT" );

    register_cvar( "AmX_DusT", "Cookie_Ban_Default", FCVAR_SPONLY | FCVAR_SERVER );

    // admin commands
    //register_concmd( "amx_ban", "CmdBan" );
    register_concmd( "cookie_remove", "CookieRemove", ADMIN_FLAG, "< nick > - removes nick from cookie bans." );
    register_concmd( "cookie_ban", "CmdCookieBan", ADMIN_FLAG, "< time > < nick | steamid | #id > < reason > - Bans with cookies." );

    register_message( get_user_msgid( "MOTD" ), "MessageMotd" );
    
    bind_pcvar_num( create_cvar( "cban_delete_expired", "0" ), pExpired );
    bind_pcvar_num( create_cvar( "cban_server", "1" ), pServer );
    bind_pcvar_string( create_cvar( "cban_complain_url", "dust-pro.com" ), pComplainUrl, charsmax( pComplainUrl ) );

    hTuple = SQL_MakeDbTuple( host, user, pass, db );

    register_dictionary( "time.txt" );
}

public MessageMotd( msgId, msgDest, msgEnt)
{
    set_msg_arg_int( 1, ARG_BYTE, 1 );
    set_msg_arg_string( 2, fmt( "%s?uid=%d&srv=%d", MOTD_CHECK, get_user_userid( msgEnt ), pServer ) );
    
    return PLUGIN_CONTINUE;
}

public plugin_cfg()
{
    set_task( 0.1, "SQL_Init" );
}

public SQL_Init()
{
    new szQuery[ 512 ];
    
    formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` (\
                                                `id` INT NOT NULL AUTO_INCREMENT,\
                                                `first_nick` VARCHAR(31) NOT NULL,\
                                                `ban_length` INT NOT NULL,\
                                                `ban_created` INT NOT NULL,\
                                                `reason` VARCHAR( 64 ) NOT NULL,\
                                                `cookie` VARCHAR( %d ) NOT NULL,\
                                                PRIMARY KEY ( id )\
                                            );", bannedCookies, MAX_COOKIE_SIZE );
    SQL_ThreadQuery( hTuple, "IgnoreHandle", szQuery );

    formatex( szQuery, charsmax( szQuery ), "CREATE TABLE IF NOT EXISTS `%s` (\
                                                `id` INT NOT NULL AUTO_INCREMENT,\
                                                `uid` INT NOT NULL,\
                                                `cookie` VARCHAR( %d ) NOT NULL UNIQUE,\
                                                `server` INT NOT NULL,\
                                                PRIMARY KEY ( id )\
                                            );", checkedCookies, MAX_COOKIE_SIZE );
    SQL_ThreadQuery( hTuple, "IgnoreHandle", szQuery );

    if( pExpired )
    {
        formatex( szQuery, charsmax( szQuery ), "DELETE FROM `%s` WHERE `ban_created`+`ban_length`<UNIX_TIMESTAMP() AND `ban_length`<>0;", bannedCookies );
        SQL_ThreadQuery( hTuple, "IgnoreHandle", szQuery );
    }
}

public IgnoreHandle( failState, Handle:query, error[], errNum )
{
    if( errNum )
    {
        set_fail_state( error );
    }
    SQL_FreeHandle( query );
}

public client_putinserver( id )
{
    if( !is_user_bot( id ) )
        set_task( 3.5, "SQL_CheckCookie", id );
}

public client_disconnected( id )
{
    if( task_exists( id ) )
        remove_task( id );
}

public plugin_end()
{
    SQL_ThreadQuery( hTuple, "IgnoreHandle", fmt( "DELETE FROM `%s`", checkedCookies ) );
}

/*
public CmdBan( id )
{
    if( !( get_user_flags( id ) & ADMIN_FLAG ) )
        return PLUGIN_CONTINUE;
    
    if( read_argc() < 4 )
        return PLUGIN_CONTINUE;
    
    new argv[ 32 ], time;
    read_argv( 2, argv, charsmax( argv ) );
    time = read_argv_int( 1 ); 
    new pid = cmd_target( id, argv, CMDTARGET_ALLOW_SELF );
    if( !pid )
        return PLUGIN_CONTINUE;
    new data[ PlayerData ];
    get_user_name( pid, data[ NAME ], charsmax( data[ NAME ] ) );
    data[ ID ] = pid;
    data[ TIME ] = get_systime() + ( ( time == 0 )? 31536000 * 2 : time * 60 ); 
    get_user_ip( pid, data[ IP ], charsmax( data[ IP ] ), 1 );
    // get cookie from checkedCookies table
    SQL_ThreadQuery( hTuple, "SQL_GetCookie", fmt( "SELECT `cookie` FROM `%s` WHERE `uid`=%d AND `server`=%d;", checkedCookies, get_user_userid( pid ), get_pcvar_num( pServer ) ), data, sizeof data );
    
    return PLUGIN_CONTINUE;
}
*/

// retrieve cookie and save in data[ COOKIE ]
public SQL_GetCookie( failState, Handle:query, error[], errNum, data[], dataSize )
{
    if( !SQL_NumResults( query ) )
    {
        if( is_user_connected( data[ ID ] ) )
        {
            log_to_file( "cookie_ban.log", "Cannot check %N", data[ ID ] );
            server_cmd( "kick #%d Cannot verify data.", get_user_userid( data[ ID ] ) );
        }
        return;
    }
    
    SQL_ReadResult( query, 0, data[ COOKIE ], charsmax( data[ COOKIE ] ) );

    BanCookie( data );
}

// save cookie and check if cookie is in the banned db
public SQL_CheckCookie( id )
{
    if( !is_user_connected( id ) )
        return;
    new data[ 2 ];
    data[ 0 ] = id;
    SQL_ThreadQuery( hTuple, "SQL_CheckCookieHandler", fmt( "SELECT * FROM `%s` WHERE `cookie` = ( SELECT `cookie` FROM `%s` WHERE `uid` = %d AND `server`=%d ) AND `ban_created`+`ban_length`*60 > UNIX_TIMESTAMP() OR `ban_length`=0;", bannedCookies, checkedCookies, get_user_userid( id ), pServer ), data, sizeof data );

    SQL_ThreadQuery( hTuple, "SQL_CheckProtector", fmt( "SELECT `cookie` FROM `%s` WHERE `uid`=%d AND `server`=%d;", checkedCookies, get_user_userid( id ), pServer ), data, sizeof data );
}

public SQL_CheckProtector( failState, Handle:query, error[], errNum, data[] )
{
    new id = data[ 0 ];
    if( is_user_connected( id ) && !SQL_NumResults( query ) )
    {
        server_cmd( "kick #%d Cannot verify data.", get_user_userid( id ) );
        log_to_file( "cookie_ban.log", "Cannot check %N", id );
    }
}

public SQL_CheckCookieHandler( failState, Handle:query, error[], errNum, data[], dataSize )
{
    if( errNum )
    {
        set_fail_state( error );
    }
    new id = data[ 0 ];
    if( !is_user_connected( id ) || !SQL_NumResults( query ) )
        return;

    new ban_reason[ 64 ], player_nick[ 64 ]
    new ban_length = SQL_ReadResult( query, SQL_FieldNameToNum( query, "ban_length" ) );
    new ban_created = SQL_ReadResult( query, SQL_FieldNameToNum( query, "ban_created" ) );

    SQL_ReadResult( query, SQL_FieldNameToNum( query, "reason" ), ban_reason, charsmax( ban_reason ) );
    SQL_ReadResult( query, SQL_FieldNameToNum( query, "first_nick" ), player_nick, charsmax( player_nick ) );

    console_print( id, "[CBAN] ===============================================" );
    console_print( id, "[CBAN] You have been banned from this server." );
    console_print( id, "[CBAN] Nick: %s.", player_nick );
    console_print( id, "[CBAN] Reason: %s.", ban_reason );
    if( ban_length == 0 )
        console_print( id, "[CBAN] Ban Length: Permanent." );
    else
    {
        new szTimeLeft[ 128 ];
        get_time_length( id, ban_length, timeunit_minutes, szTimeLeft, charsmax( szTimeLeft ) );
        console_print( id, "[CBAN] Ban Length: %s.", szTimeLeft );
        get_time_length( id, ban_length*60 + ban_created - get_systime(), timeunit_seconds, szTimeLeft, charsmax( szTimeLeft ) );
        console_print( id, "[CBAN] Timeleft: %s.", szTimeLeft );
    }

    console_print( id, "[CBAN] You can complain about your ban @ %s.", pComplainUrl );
    console_print( id, "[CBAN] ===============================================" );

    delayed_kick( id );
    
}


public delayed_kick( id )
{
    if( is_user_connected( id ) )
        server_cmd( "kick #%d You are BANNED. Check your console.", get_user_userid( id ) );
}
public CookieRemove( id, level, cid )
{
    if( !cmd_access( id, level, cid, 2 ) )
        return PLUGIN_HANDLED;
    new argv[ 32 ];
    read_argv( 1, argv, charsmax( argv ) );
    new nick[ 64 ];
    SQL_QuoteString( Empty_Handle, nick, charsmax( nick ), argv );
    SQL_ThreadQuery( hTuple, "IgnoreHandle", fmt( "DELETE FROM `%s` WHERE `first_nick` = '%s'", bannedCookies, nick ) );

    if( id )
        client_print( id, print_console, "Done" );
    else
        server_print( "Done" );
    return PLUGIN_HANDLED;
}
public CmdCookieBan( id, level, cid )
{
    if( !cmd_access( id, level, cid, 4 ) )
        return PLUGIN_HANDLED;

    new data[ PlayerData ];
    data[ TIME ] = read_argv_int( 1 );
    new argv[ 32 ], args[ 128 ];
    read_argv( 2, argv, charsmax( argv ) );
    
    data[ ID ] = cmd_target( id, argv, CMDTARGET_ALLOW_SELF );
    
    if( data[ ID ] )
    {
        get_user_name( data[ ID ], data[ NAME ], charsmax( data[ NAME ] ) );
        read_args( args, charsmax( args ) );
        remove_quotes( args );
        new pos = containi( args, argv ) + strlen( argv ) + 1; 
        formatex( data[ REASON ], charsmax( data[ REASON ] ), args[ pos ] );
        SQL_ThreadQuery( hTuple, "SQL_GetCookie", fmt( "SELECT `cookie` FROM `%s` WHERE `uid`=%d AND `server`=%d;", checkedCookies, get_user_userid( data[ ID ] ), pServer ), data, sizeof data );
    }
    return PLUGIN_HANDLED;
}

BanCookie( data[] )
{

    new nick[ 64 ];
    SQL_QuoteString( Empty_Handle, nick, charsmax( nick ), data[ NAME ] );

    SQL_ThreadQuery( hTuple, "IgnoreHandle", fmt( "INSERT INTO `%s` VALUES( NULL, '%s', %d, %d, '%s', '%s' );", bannedCookies, nick, data[ TIME ], get_systime(), data[ REASON ], data[ COOKIE ] ) );
    new id = find_player( "a", data[ NAME ] );
    if( id )
        set_task( 3.5, "delayed_kick", id );
}
