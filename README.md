# CureInfection
ZPS plugin that uses health items to cure infection.

This plugin is an advanced version of the original pills cure plugin in that it gives more options for gameplay tweeks. The plugin has the following cvars:
    
- sm_cureinfection_enabled = Disables/Enables the plugin.
- sm_cureinfection_pills = Disable/Enables cure infection on the pill bottle health item.
- sm_cureinfection_pchance = Sets the chance that the pill bottles cures infection. Requires sm_cureinfection_pills to be enabled. 1.0 = 100%
- sm_cureinfection_healthkits = Disable/Enables cure infection on the healthkit health item.
- sm_cureinfection_hkchance = Sets the chance that the pill bottles cures infection. Requires sm_cureinfection_healthkits to be enabled. 1.0 = 100%
- sm_cureinfection_backfire = Optional setting that will cause the player to zombify faster upon cure failure.
- sm_cureinfection_fargone = Optional setting that can cause the cure to be ineffective if player has been infected for too long.
- sm_cureinfection_fgonetime = The time until infection, in seconds, in which the cure becomes ineffective. Requires sm_cureinfection_fargone to be enabled. Defauilt is 5 seconds.


1.0 Initial Commit (06-04-2017)
-----------------
- Cure infection plugin created.
- Created cvars for each health item (pills and healthkits) as well as an infection cure chance for each.
- Created backfire cvar. This setting will cause the acceleration of the infection, causing them to become a zombie almost instantly. This assumes that the health item fails to cure the user.
- Created fargone cvar. This setting is used to determine if a player is too infected to cure, based on the time, in seconds, specified.
- Created cvar to disable/enable the plugin.
- Added config file for plugin (plugin will also auto generate a config file).
- Compiled on Sourcemod 1.7.3
