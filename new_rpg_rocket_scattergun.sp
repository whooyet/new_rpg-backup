#include <sdkhooks>
#include <tf2>
#include <new_rpg>

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientPutInServer(i) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(attacker == client)
	{
		if(GetAbility(client, "rocket_scattergun"))
		{
			TF2_AddCondition(client, TFCond:14, 0.001);			
			fDamage = 45.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}