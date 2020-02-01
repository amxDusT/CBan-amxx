#if defined _cban_main_included
  #endinput
#endif
#define _cban_main_included

#define VERSION		"1.0"

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

// length stuff
#define MAX_CSIZE           35
#define MAX_URL_LENGTH      128
#define MAX_DB_LENGTH       64
#define MAX_SERVER_IP       25
#define MAX_STEAMID_LENGTH  30
#define MAX_REASON_LENGTH   100

#define MIN_STEAMID_LENGTH  11
#define MIN_TARGET_LENGTH   5     // if nick/ip is lower than this, don't do anything ( unban, etc ).

/**
*
*
*
*/



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