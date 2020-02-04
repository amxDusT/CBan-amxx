# CBan-amxx

A more efficient way to ban people.
# This version is meant to substitute the normal ban system. 
Add this on the top on plugins.ini. 

If you're using AMXBans, consider checking the "master" branch. 
If you want something that works separated from your default ban system, check the "default" branch.

Features:
 - a better ban system ( doesn't only ban by steamid and/or IP ).
 - works (only) with database.
 - amx_offban (ban recent players that were ingame).
 - amx_addban (ban a player by steamid or IP. if this player joins in the server, the ban details will be updated to his).
 - tracks last banned players' IPs.
 - can update player's steamid/nick/IP to last one in the database.
 - can decide to ban steamers by steamid and nonsteamers by IP.
 - addban's time can start from when the banned player joins the server.
 - offban's time can start from when the banned player joins the server.
 - has a screenshot system included that will take X numbered screenshots of the player before he gets kicked.
 - amx_rban to perform IP range bans.
API:
 - forward to check whenever a player gets banned (before and after he gets banned): you can block a ban too or change ban's length.
 - forwards to check whenever a player gets banned through offban and addban.
 - native for banning players through other plugins.
 - native for unbanning players.
 - native for banning through offban 
 - native for banning through addban  
   
TO DO:
 - cvar for screenshots.
 - add some huds to screenshots.
 - change ban times in the amx_banmenu to show hour(s), day(s), week(s)
