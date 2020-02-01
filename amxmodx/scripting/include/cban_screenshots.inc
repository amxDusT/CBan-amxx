#if defined _cban_screenshots_included
  #endinput
#endif
#define _cban_screenshots_included

/**
*	Take screenshots on player.
*	
*	@param admin	Admin taking the screenshot. Use 0 for server.
*	@param player	Player's ID.
*	@param screens	How many screenshots. Use 0 for default.
*/
native CBan_TakeScreenshot( admin, player, screens = 0 );