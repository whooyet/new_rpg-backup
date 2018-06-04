#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public OnClientPutInServer(i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(AliveCheck(attacker) && AliveCheck(client))
		if(GetAbility(client, "firecow")) TF2_IgnitePlayer(attacker, client);
	return Plugin_Continue;
}
 
public Action:iv(Handle:event, const String:name2[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	FindParticle(client);
	
	if(GetAbility(client, "firecow"))
	{
		TCreateParticle("burningplayer_flyingbits", client, 5);
		TCreateParticle("burningplayer_flyingbits", client, 6);
	}
}


stock FindParticle(client)
{
	new iEnt = -1;
	decl String:szName[30];
	while((iEnt = FindEntityByClassname2(iEnt, "info_particle_system")) != -1)
	{
		GetEntPropString(iEnt, Prop_Data, "m_iName", szName, 16, 0);
		new owner = GetEntPropEnt(iEnt, Prop_Data, "m_pParent");
						
		if(client == owner)
		{
			if(IsValidEdict(iEnt))
			{
				if(StrEqual(szName, "particle_hand_l")) RemoveEdict(iEnt);
				if(StrEqual(szName, "particle_hand_r")) RemoveEdict(iEnt);
			}
		}
	}
}