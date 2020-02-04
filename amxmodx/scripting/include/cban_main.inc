#if defined _cban_main_included
  #endinput
#endif
#define _cban_main_included

#define VERSION		"1.0.7"

enum _:UnbanType
{
  UT_NICK     = 0,
  UT_IP       = 1,
  UT_STEAMID  = 2
}

// admin stuff
#define ADMIN_FLAG_BAN          ADMIN_BAN
#define ADMIN_FLAG_ADDBAN       ADMIN_BAN
#define ADMIN_FLAG_OFFBAN       ADMIN_BAN
#define ADMIN_FLAG_SCREENSHOTS	ADMIN_BAN
#define ADMIN_FLAG_UNBAN        ADMIN_IMMUNITY
#define ADMIN_FLAG_IMMUNITY     ADMIN_IMMUNITY
#define ADMIN_FLAG_RANGE        ADMIN_IMMUNITY

// length stuff
#define MAX_CSIZE           35
#define MAX_URL_LENGTH      128
#define MAX_DB_LENGTH       64
#define MAX_SERVER_IP       25
#define MAX_STEAMID_LENGTH  30
#define MAX_REASON_LENGTH   100

#define MIN_STEAMID_LENGTH  11
#define MIN_TARGET_LENGTH   5     // if nick/ip is lower than this, don't do anything ( unban, etc ).

// for the menu stuff
#define MAX_REASONS     20
#define MAX_BANTIMES    15
#define DEFAULT_TIME    60

/**
* Ban a player.
* @note if admin's ID is not connected or <0, it will consider server.
*
* @param  admin       Admin's ID banning the player.
* @param  player      Player's ID.
* @param  banLength   Ban length.
* @param  banReason   Ban reason.
*/
native CBan_BanPlayer( admin = 0, player, banLength, banReason[] );

/**
* Unban a player.
* @note if admin's ID is not connected or <0, it will consider server.
* @note targetType serves to know whether the target is nick,ip or steamid.
*
* @param  admin       Admin's ID unbanning the player.
* @param  target      player's nick, ip or steamid.
* @param  targetType  UT_NICK, UT_IP or UT_STEAMID
*/
native CBan_UnbanPlayer( admin = 0, target[], targetType = UT_NICK );

/**
* Bans a player if he was ingame recently.
* @note if admin's ID is not connected or <0, it will consider server.
* @note if target is ingame, it will normally ban him.
*
* @param  admin       Admin's ID banning the player.
* @param  target      Player's nick.
* @param  banLength   Ban length.
* @param  banReason   Ban reason.
*
* @return   0 if target is not found as immunity. 1 otherwise.
*/
native CBan_OffBanPlayer( admin = 0, target[], banLength, banReason[] );

/**
* Bans a player by IP or steamid if he's not ingame.
* @note if admin's ID is not connected or <0, it will consider server.
* @note if target is ingame, it will normally ban him.
*
* @param  admin       Admin's ID banning the player.
* @param  target      Player's steamid or IP.
* @param  banLength   Ban length.
* @param  banReason   Ban reason.
*
* @return   0 if target is ingame and has immunity. 1 otherwise.
*/
native CBan_AddBanPlayer( admin = 0, target[], banLength, banReason[] );

/**
*   Called before the player is banned. 
*   @note: Can be stopped by returning PLUGIN_HANDLED.
*   @note: banLength is byref. if changed, it will affect user's ban.
*
*   @param  player      Player's ID.
*   @param  admin       Admin's ID.
*   @param  banLength   Ban Length in minutes.
*   @param  banReason   Ban reason.
*/
forward CBan_OnPlayerBannedPre( player, admin, &banLength, const banReason[ MAX_REASON_LENGTH ] );


/**
*   Called after the player is banned. 
*   @note: Cannot be stopped.
*
*   @param  player      Player's ID.
*   @param  admin       Admin's ID.
*   @param  banLength   Ban Length in minutes.
*   @param  banReason   Ban reason.
*/
forward CBan_OnPlayerBannedPost( player, admin, banLength, const banReason[ MAX_REASON_LENGTH ] );


/**
* Called when an admin uses amx_addban.
* @note   banLength is byref. if changed, it will affect user's ban.
* @note   returning PLUGIN_HANDLED blocks the ban.
*
* @param target     Either IP or SteamID.
* @param admin      Admin's ID.
* @param banLength  Ban length in minutes.
* @param banReason  Ban reason.
*/
forward CBan_OnAddBan( target[], admin, &banLength, banReason[ MAX_REASON_LENGTH ] );


/**
* Called when an admin uses amx_addban.
* @note   banLength is byref. if changed, it will affect user's ban.
* @note   returning PLUGIN_HANDLED blocks the ban.
*
* @param targetSteamID  player's SteamID.
* @param admin          Admin's ID.
* @param banLength      Ban length in minutes.
* @param banReason      Ban reason.
*/
forward CBan_OnOffBan( targetSteamID[], admin, &banLength, banReason[ MAX_REASON_LENGTH ] );
