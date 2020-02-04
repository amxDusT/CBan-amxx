#include < amxmodx >
#include < amxmisc >
#include < cban_main >
#include < sqlx >
#include < regex >

#define TASK_KICK   1246
new Handle:tuple;

new g_RangeTable[ 64 ];
new g_ComplainUrl[ MAX_URL_LENGTH ];

public plugin_init()
{
    register_plugin( "[CBAN] Range Ban", VERSION, "DusT" );

    register_concmd( "amx_rban", "CmdRangeBan", ADMIN_FLAG_RANGE, "< ip_start > < ip_end > < reason > - IP range ban." );
    
    register_dictionary( "cbans.txt" );
}

public plugin_cfg()
{
    ReadINI();
    set_task( 0.1, "SQL_Init" );
}

ReadINI()
{
    new szDir[ 128 ];
    get_configsdir( szDir, charsmax( szDir ) );

    add( szDir, charsmax( szDir ), "/CBans.ini" );

    if( !file_exists( szDir ) )
        return;

    new fp = fopen( szDir, "rt" );
    new szData[ 256 ], szToken[ 32 ], szValue[ 224 ];
    new host[ MAX_DB_LENGTH ], user[ MAX_DB_LENGTH ], password[ MAX_DB_LENGTH ], db[ MAX_DB_LENGTH ];
    while( fgets( fp, szData, charsmax( szData ) ) )
    {
        if( szData[ 0 ] == '/' && szData[ 1 ] == '/' )
            continue;
        if( szData[ 0 ] == ';' )
            continue;
        trim( szData );
        if( !szData[ 0 ] )
            continue;

        strtok2( szData, szToken, charsmax( szToken ), szValue, charsmax( szValue ), '=' );
        trim( szValue );
        trim( szToken );

        if( equal( szToken, "DB_HOST" ) )
            copy( host, charsmax( host ), szValue );
        else if( equal( szToken, "DB_USER" ) )
            copy( user, charsmax( user ), szValue );
        else if( equal( szToken, "DB_PASS" ) )
            copy( password, charsmax( password ), szValue );
        else if( equal( szToken, "DB_DB" ) )
            copy( db, charsmax( db ), szValue );
        else if( equal( szToken, "DB_RANGETABLE" ) )
            copy( g_RangeTable, charsmax( g_RangeTable ), szValue );
        else if( equal( szToken, "COMPLAIN_URL" ) )
            copy( g_ComplainUrl, charsmax( g_ComplainUrl ), szValue );  
    }
    fclose( fp );

    tuple = SQL_MakeDbTuple( host, user, password, db );
}

public SQL_Init()
{
    new query[ 256 ];
    formatex( query, charsmax( query ), "CREATE TABLE IF NOT EXISTS `%s` (\
                                            id INT NOT NULL AUTO_INCREMENT,\
                                            ip_start VARCHAR(16) NOT NULL,\
                                            ip_end VARCHAR(16) NOT NULL,\
                                            reason VARCHAR(%d) NOT NULL,\
                                            PRIMARY KEY (id)\ 
                                        );", g_RangeTable, MAX_REASON_LENGTH );
    
    SQL_ThreadQuery( tuple, "IgnoreHandle", query );
}
public IgnoreHandle( failState, Handle:query, error[], errNum )
{
    if( errNum )
        log_amx( error );
}
public CmdRangeBan( id, level, cid )
{
    if( !cmd_access( id, level, cid, 4 ) )
        return PLUGIN_HANDLED;

    new ipStart[ MAX_IP_LENGTH ], ipEnd[ MAX_IP_LENGTH ];
    read_argv( 1, ipStart, charsmax( ipStart ) );
    read_argv( 2, ipEnd, charsmax( ipEnd ) );

    // check if they're IP like format. negative numbers will return error too.
    static Regex:pPattern;
    if( !pPattern )
        pPattern = regex_compile( "^^(\d{1,3}\.){3}\d{1,3}$" );

    if( !regex_match_c( ipStart, pPattern ) || !regex_match_c( ipEnd, pPattern ) )
    {
        console_print( id, "Wrong IP formats.");
        return PLUGIN_HANDLED;
    }

    new ip_start[ 4 ][ 4 ], ip_end[ 4 ][ 4 ];
    explode_string( ipStart, ".", ip_start, 4, 3 );
    explode_string( ipEnd, ".", ip_end, 4, 3 );

    // if any value is bigger than 255, it's a problem
    for( new i; i < 4; i++ )
    {
        if( str_to_num( ip_start[ i ] ) > 255 )
        {
            console_print( id, "Invalid IP start." );
            return PLUGIN_HANDLED; 
        }

        if( str_to_num( ip_end[ i ] ) > 255 )
        {
            console_print( id, "Invalid IP end." );
            return PLUGIN_HANDLED; 
        }
    }

    // first 2 parts of the range ban let's keep it similar.
    if( str_to_num( ip_start[ 0 ] ) != str_to_num( ip_end[ 0 ] ) || str_to_num( ip_start[ 1 ] ) != str_to_num( ip_end[ 1 ] ) )
    {
        console_print( id, "IP start and end must have the first 2 parts equal." );
        return PLUGIN_HANDLED;
    }

    if( str_to_num( ip_start[ 2 ] ) > str_to_num( ip_end[ 2 ] ) )
    {
        console_print( id, "IP end must be higher." );
        return PLUGIN_HANDLED; 
    }
    if( str_to_num( ip_start[ 2 ] ) == str_to_num( ip_end[ 2 ] ) && str_to_num( ip_start[ 3 ] ) > str_to_num( ip_end[ 3 ] ) )
    {
        console_print( id, "IP end must be higher." );
        return PLUGIN_HANDLED; 
    }

    new args[ 132 ];
    read_args( args, charsmax( args ) );
    remove_quotes( args );
    new reason[ MAX_REASON_LENGTH ];
    new iReasonPos = strlen( ipStart ) + strlen( ipEnd ) + 2;
    copy( reason, charsmax( reason ), args[ iReasonPos ] );

    SQL_ThreadQuery( tuple, "IgnoreHandle", fmt( "INSERT INTO db_range VALUES(NULL, '%s', '%s', '%s');", ipStart, ipEnd, reason ) );

    console_print( id, "IP range added successfully" );
    return PLUGIN_HANDLED;  
}

public client_putinserver( id ) 
{
    set_task( 5.0, "CheckIP", id );
}
public client_disconnected( id )
{
    if( task_exists( id ) )
        remove_task( id );
    if( task_exists( id + TASK_KICK ) )
        remove_task( id + TASK_KICK );
}
public CheckIP( id )
{
    if( !is_user_connected( id ) )
        return;
    
    new ip[ MAX_IP_LENGTH ];
    new ip_split[ 4 ][ 4 ];
    get_user_ip( id, ip, charsmax( ip ), 1 );
    explode_string( ip, ".", ip_split, 4, 3 );  // divide IP in 4 parts for each element. 
    
    new data[ 3 ];
    data[ 0 ] = id; 
    data[ 1 ] = str_to_num( ip_split[ 2 ] );
    data[ 2 ] = str_to_num( ip_split[ 3 ] );
    SQL_ThreadQuery( tuple, "CheckIPHandler", fmt( "SELECT * FROM db_range WHERE `ip_start` LIKE '%s.%s%%'", ip_split[ 0 ], ip_split[ 1 ] ), data, sizeof data );
}   

public CheckIPHandler( failState, Handle:query, error[], errNum, data[], dataSize )
{
    new id = data[ 0 ];
    if( !is_user_connected( id ) )
        return;

    new max = SQL_NumResults( query );
    if( !max )
        return;
    
    new start[ MAX_IP_LENGTH ];
    new end[ MAX_IP_LENGTH ];
    new ip_start[ 4 ][ 4 ];
    new ip_end[ 4 ][ 4 ];
    new start_t, start_f, end_t, end_f

    for( new i; i < max; i++ )
    {
        SQL_ReadResult( query, 1, start, charsmax( start ) );
        SQL_ReadResult( query, 2, end, charsmax( end ) );

        explode_string( start, ".", ip_start, 4, 3 );
        explode_string( end, ".", ip_end, 4, 3 );

        start_t = str_to_num( ip_start[ 2 ] );
        start_f = str_to_num( ip_start[ 3 ] );
        end_t = str_to_num( ip_end[ 2 ] );
        end_f = str_to_num( ip_end[ 3 ] );

        if( start_t <= data[ 1 ] <= end_t && start_f <= data[ 2 ] <= end_f )    // player is banned
        {
            console_print( id, "[CBAN] ===============================================" );
            console_print( id, "[CBAN] %L", id, "MSG_RANGE_1" );
            console_print( id, "[CBAN] %L", id, "MSG_RANGE_2" );
            console_print( id, "[CBAN] %L %s.", id, "MSG_COMPLAIN", g_ComplainUrl );
            console_print( id, "[CBAN] ===============================================" );

            set_task( 1.0, "KickPlayer", id + TASK_KICK );
            return;
        }
        SQL_NextRow( query );
    } 
}

public KickPlayer( id )
{
    id -= TASK_KICK;

    if( is_user_connected( id ) )
    {
        emessage_begin( MSG_ONE, SVC_DISCONNECT, _, id );
        ewrite_string( "You are BANNED. Check your console." );
        emessage_end();
    }
}
