/************************************************************************
*************************************************************************
[ZPS] Cure Infection
Description: This plugin is meant to be an updated version of the pillscure
    plugin , but with a few more options to allow for tweaks to gameplay. 
    Server owners can enable/disable cure from being applied to medkits
    and/or pills separately from the configuration file. There is also a 
    chance feature that allows server owners to create a random chance
    that these items will cure the infection instead of guaranteeing it.
    
Pills Cure Plugin Author:
    Sammy-ROCK!

Author:
    Mr. Silence
    
*************************************************************************
*************************************************************************
This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************/
// Make sure it reads semicolons as endlines
#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zpsinfection_stocks>

// Defines
#define PLUGIN_VERSION "2.0"
#define TEAM_SURVIVOR 2
#define TEAM_ZOMBIE 3

// Handles and other globals
new Handle:cvar_CIEnabled           = INVALID_HANDLE; // Enables/Disable plugin
new Handle:cvar_CIPillsCure         = INVALID_HANDLE; // Allow/Disallow pills to cure
new Handle:cvar_CIPCureChance       = INVALID_HANDLE; // Chance that pills cure infection
new Handle:cvar_CIHealthKitsCure    = INVALID_HANDLE; // Allow/Disallow healthkits to cure infection
new Handle:cvar_CIHKCureChance      = INVALID_HANDLE; // Chance that healthkits cure infection
new Handle:cvar_CIBackFire          = INVALID_HANDLE; // Enable cure backfire (based on chance of infection per item)
new Handle:cvar_CIFarGone           = INVALID_HANDLE; // Enable cure only if players are not too infected 
new Handle:cvar_CIFGoneTime         = INVALID_HANDLE; // The cut off time limit before a player is considered too far gone
new Handle:cvar_CIGameInfectTime    = INVALID_HANDLE; // ZPS's in-game infection time.

// If the cure backfired, then we shouldn't allow them to be cured
new bool:g_bCIBackFired[MAXPLAYERS+1];
new bool:g_bCIKeyPressed[MAXPLAYERS+1];

// Create our timer stuff for each player (needed for fargone settings).
new Handle:g_hCITurnTimeHandle[MAXPLAYERS+1];
new bool:g_bCITimerCreated[MAXPLAYERS+1];
new Float:g_fCIInfectionTime[MAXPLAYERS+1];

// Plugin info/credits
public Plugin:myinfo = 
{
    name = "[ZPS] Cure Infection",
    author = "Mr.Silence",
    description = "Cure Infection via health items",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/"
}

///////////////////////////////////
//===============================//
//=====[ EVENTS ]================//
//===============================//
///////////////////////////////////
// Setup our config file and cvars
public OnPluginStart()
{
	// Give our handles information.
    cvar_CIEnabled          = CreateConVar("sm_cureinfection_enabled", "1", "Enable/Disable Cure Infection plugin. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_CIPillsCure        = CreateConVar("sm_cureinfection_pills", "1", "Allow/Disallow pills to cure infection. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_CIPCureChance      = CreateConVar("sm_cureinfection_pchance", "1.0", "The chance that pills will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.0 (100%)- Guarantees cure infection.", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.1, true, 1.0);
    cvar_CIHealthKitsCure   = CreateConVar("sm_cureinfection_healthkits", "1", "Allow/Disallow healthkits to cure infection. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_CIHKCureChance     = CreateConVar("sm_cureinfection_hkchance", "1.0", "The chance that healthkits will cure infection. \n 0.1 (10%)- Lowest chance to cure infection,\n 1.00 (100%)- Guarantees cure infection.", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.1, true, 1.0);
    cvar_CIBackFire         = CreateConVar("sm_cureinfection_backfire", "0", "Enable/Disable option to have the cure backfire. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_CIFarGone          = CreateConVar("sm_cureinfection_fargone", "0", "Enable/Disable the option to only cure players who aren't about to turn, but are just infected. \nEnable = 1  \nDisable = 0", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_CIFGoneTime        = CreateConVar("sm_cureinfection_fgonetime", "5.0", "The time of infection, in seconds, when the cure becomes ineffective. \n5.0 = 5 seconds before turning into a zombie", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 5.0, true, 50.0);
    cvar_CIGameInfectTime   = CreateConVar("sm_cureinfection_infecttime", "50.0", "ZPS's overall infection time in seconds. Do not change this unless the game was updated and infection time changed. \n50.0 = 50 seconds before turning into a zombie", FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
    
    // Plugin version
    CreateConVar("sm_cureinfection_version", PLUGIN_VERSION, "[ZPS] Cure Infection Version.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    // Initialize infection info!
    ZPSInfectionInit();
    
    // Hook player spawn in order to clear any flags
    HookEvent("player_spawn", Event_CIPlayerSpawn);
    
	// Create a config file for the plugin
    AutoExecConfig(true, "plugin.cureinfection");
}

public OnPluginEnd() 
{
    UnhookEvent("player_spawn", Event_CIPlayerSpawn);
}

// Set some variables to default values
public OnMapStart()
{
    for(new i = 1; i <= MaxClients; i++)
    {
        g_bCITimerCreated[i] = false;
        g_bCIBackFired[i] = false;
        g_bCIKeyPressed[i] = false;
        g_fCIInfectionTime[i] = 0.0;
        g_hCITurnTimeHandle[i] = INVALID_HANDLE;
    }
}

public OnClientPutInServer(client)
{
    // Hook on take damage (we'll need this for infection timers)
    SDKHook(client, SDKHook_OnTakeDamagePost, Event_CIOnTakeDamage);//SDKHook_OnTakeDamagePost, Event_CIOnTakeDamage);
}

// Set some variables to default values
public OnClientDisconnect(client)
{
    g_bCITimerCreated[client] = false;
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
    g_fCIInfectionTime[client] = 0.0;
    g_hCITurnTimeHandle[client] = INVALID_HANDLE;
}

/////////////////////////////////
//=============================//
//=====[ Actions ]=============//
//=============================//
/////////////////////////////////
// When the player hits use, look at the item they use and see if its a health item, then cure based on our settings.
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    // First off, is our plugin enabled?
    if(GetConVarBool(cvar_CIEnabled))
    {
        // It is! Did our player hit the IN_USE command, are they a survivor, and are they infected?
        // Find out in the next exciting if-statement of Sourcepawn Z!
        if((buttons & IN_USE) == IN_USE && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerInfected(client))//GetEntData(client, InfectedOffset, 4))
        {
            // We have to check if they are holding the button down.
            if (g_bCIKeyPressed[client] == true)
            {
                // If the button was pressed and it is currently detected, stop them from that the use key is being held down
                if (GetClientButtons(client) == IN_USE)
                {
                    return Plugin_Continue;
                }
                // If not, then go through the rest of the plugin unhindered and change flags!
                else
                {
                    g_bCIKeyPressed[client] = false;
                }
            }
            
            // Now lets find our entity based on the client's viewpoint
            new ent = TraceToEntity(client);
          
            // Is it valid at all?
            if(IsValidEntity(ent) && IsValidEdict(ent))
            {
                // Compare the prop's position to the clients
                new Float:vecPosEntity[3] = 0.0;
                new Float:vecPosClient[3] = 0.0;
                GetClientEyePosition(client, vecPosClient);
                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecPosEntity);
                
                // Get the distance and see if its less than 100 hammer, based on the position of the entity/player.
                // NOTE: Seems that 100 units is as far as we can go away from the item before not being able to use it. 
                //       Something tells me this might end up being a problem somehow...
                if(GetVectorDistance(vecPosClient, vecPosEntity, false) <= 100.0)
                {
                    // Yes it is! Lets find out which item it is!
                    new String:edictname[64];
                    GetEdictClassname(ent, edictname, 64);

                    // Lets find out which item we are using. 
                    // Pills
                    if(StrEqual(edictname, "item_healthvial", true) && GetConVarBool(cvar_CIPillsCure))
                    {   
                        CurePInfection(client, GetConVarFloat(cvar_CIPCureChance));
                        g_bCIKeyPressed[client] = true;
                        return Plugin_Continue;
                    }
                
                    // Health kits
                    if(StrEqual(edictname, "item_healthkit", true) && GetConVarBool(cvar_CIHealthKitsCure))
                    {
                        CurePInfection(client, GetConVarFloat(cvar_CIHKCureChance));
                        g_bCIKeyPressed[client] = true;
                        return Plugin_Continue;
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

public Action:Event_CIPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event,"userid"));
    g_bCITimerCreated[client] = false;
    g_bCIBackFired[client] = false;
    g_bCIKeyPressed[client] = false;
    g_fCIInfectionTime[client] = 0.0;
    g_hCITurnTimeHandle[client] = INVALID_HANDLE;
}

public Action:Event_CIOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    // Don't display messages based on suicides and such.
    if (victim == attacker)
    {
        return Plugin_Handled;
    }

    // Check if the client is a survivor. 
    if(GetClientTeam(victim) == TEAM_SURVIVOR)
    {
        // If its a survivor, check for infection and if a timer was created for them.
        if(IsPlayerInfected(victim) && !g_bCITimerCreated[victim])
        {
            g_bCITimerCreated[victim] = true;
            g_fCIInfectionTime[victim] = GetConVarFloat(cvar_CIGameInfectTime); // Set countdown global countdown timer
            g_hCITurnTimeHandle[victim] = CreateTimer(1.0, Timer_CIInfectionTimer, victim, TIMER_REPEAT); // Repeat the timer every 1 second.
            return Plugin_Continue;
        }
    }
    
    return Plugin_Continue;
}

// Timer for infection time (only used if cvar_CIFarGone is enabled).
// NOTE: After a few tests, it was determined that infection would take 50 - 53 seconds to transform the player. 
// The last 2-3 seconds of this were the actual transformation (ie, no turning back). 
public Action:Timer_CIInfectionTimer(Handle:timer, any:client)
{
    // If the time reaches 0 and our flag is still true.
    if(g_fCIInfectionTime[client] <= 0.0 && g_bCITimerCreated[client])
    {   
        // Reset values, revert flags, kill handle, the player is pretty much infected
        g_fCIInfectionTime[client] = 0.0;
        g_bCITimerCreated[client] = false;
        ClearTimer(g_hCITurnTimeHandle[client]);
        g_hCITurnTimeHandle[client] = INVALID_HANDLE;
        return Plugin_Handled;
    }
    
    // If at any point the timers decide to hit negative numbers or the plugin's timer flag is false
    if(g_fCIInfectionTime[client] <= -1.0 || !g_bCITimerCreated[client])
    {   
        // Reset values, revert flags, kill handle, the player is pretty much infected
        g_fCIInfectionTime[client] = 0.0;
        ClearTimer(g_hCITurnTimeHandle[client]);
        g_hCITurnTimeHandle[client] = INVALID_HANDLE;
        return Plugin_Handled;
    }
    
    // Countdown timer
    g_fCIInfectionTime[client]--;
    
    return Plugin_Continue;
}

///////////////////////////////////
//===============================//
//=====[ FUNCTIONS ]=============//
//===============================//
///////////////////////////////////
// Trace the entity to the player client
public TraceToEntity(client)
{
    // Get both eye position and angle vectors of our client
    new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos);
    GetClientEyeAngles(client, vecClientEyeAng);
    
    // Trace me like one of your french girls!
    // NOTE: This method does not use local variables/handles. Instead, it uses the global handles.
    //       Since Sourcemod will never use multi-threading, this is actually safer/more efficient than
    //       using handles.
    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_VISIBLE, RayType_Infinite, TraceRayDontHitSelf, client);
	
    // If its hitting the right entity... 
    // NOTE: fyi, we using the global trace result from the above statement! This is why it seems like magic!
    if(TR_DidHit(INVALID_HANDLE))
    {
        // Return our entity's index!
        return TR_GetEntityIndex(INVALID_HANDLE);
    }
    
    // Return -1 for and invalid entity.
    return -1;
}

// Check our data to check that the entity we "hit" is not itself
// In other words: STOP HITTING YOURSELF! STOP HITTING YOURSELF! STOP HITTING YOURSELF!
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data)
    {
        return false;
    }
    return true;
}

// Gets the time remaining on a player's infection, in seconds, before becoming a zombie.
// TODO: Currently, this function relies on a timer from this plugin to figure out infection. If possible, it would be better
//      to find the actual infection time values (which would be a float) from the game itself and use that. However,
//      it does not seem to be as accessible or is hidden some place, so the only realistic way to get this value
//      is to figure out which pointer/function/member variable holds this value, disassemble/reverse engineer said value 
//      from function code in order to get it, or ask the devs nicely build a "ZombieTurnTime" function or member variable that
//      would be used to return/hold the turn time values.
public Float:GetPlayerInfectionTime(client) 
{
    // If the player is infected, but their timer handle is invalid, it means its already 
    // went beyond 50 seconds, return 0 as they are already too fargone to cure.
    if(g_hCITurnTimeHandle[client] == INVALID_HANDLE)
    {
        return 0.0;
    }

    return g_fCIInfectionTime[client];
}

// Method used to determine how to cure infection for whatever item we want
// ... or to make it backfire depending on chance >:3
CurePInfection(client, Float:chance)
{
    // Get our chance of infection and player health
    new Float:rand = GetRandomFloat(0.0, 1.0);
    new health = GetClientHealth(client);

    // Find out how long until infection sets in (which is only 
    new Float:getInfectTime = GetPlayerInfectionTime(client);

    // If our chance setting is greater than or equal to what was generated, we cure infection
    if(chance >= rand && health < 100)
    {
        // If we enabled the fargone cvar
        if (GetConVarBool(cvar_CIFarGone) && g_bCIBackFired[client] == false)
        {   
            if (getInfectTime > GetConVarFloat(cvar_CIFGoneTime))
            {
                // Kill the timer, set our flags/intervals, and uninfect the player
                PrintToChat(client, "You've been cured from infection!");
                UnInfectPlayer(client);
                g_fCIInfectionTime[client] = 0.0;
                g_bCITimerCreated[client] = false;
                CloseHandle(g_hCITurnTimeHandle[client]);
                g_hCITurnTimeHandle[client] = INVALID_HANDLE;
                return;
            }
            if (getInfectTime <= GetConVarFloat(cvar_CIFGoneTime))
            {
                PrintToChat(client, "The cure did not work, you're too infected to cure...");
                return;
            }
        }
        if (!GetConVarBool(cvar_CIFarGone))
        {   
            PrintToChat(client, "You've been cured from infection!");
            UnInfectPlayer(client);
            return;
        }
    }
    
    // If the cure change is less than what was generated and they have less than 100 health, the user is not cured.
    if(chance < rand && health < 100 && g_bCIBackFired[client] == false)
    {   
        // If backfire was enabled, set the user's turn time to 5 second (almost instant transformation!) 
        // then prevent them from being cured
        if (GetConVarBool(cvar_CIBackFire))
        {
            if (getInfectTime > 5.0)
            {
                PrintToChat(client, "It backfired! The infection spreads faster!");
                InfectPlayer(client, -45.0);
                g_bCIBackFired[client] = true;
                g_fCIInfectionTime[client] = 0.0;
                g_bCITimerCreated[client] = false;
                CloseHandle(g_hCITurnTimeHandle[client]);
                g_hCITurnTimeHandle[client] = INVALID_HANDLE;
            }
            return;
        }
        if (!GetConVarBool(cvar_CIBackFire))
        {
            PrintToChat(client, "The cure did not work, the drugs weren't powerful enough...");
            return;
        }
    }
    return;
}

// Kill/clear our client's timer handles. Wouldn't want them eating up precious memory.
ClearTimer(&Handle:timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer, true);
        timer = INVALID_HANDLE;
    }  
}