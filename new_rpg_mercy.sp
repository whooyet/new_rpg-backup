#include <tf2_stocks>
#include <new_rpg>

public OnPluginStart()
{
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}


public iv(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetAbility(client, "mercy"))
	{
		TF2_AddCondition(client, TFCond:107, -1.0);
		TF2_AddCondition(client, TFCond_RadiusHealOnDamage, -1.0);
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond:107)) TF2_RemoveCondition(client, TFCond:107);
		if(TF2_IsPlayerInCondition(client, TFCond_RadiusHealOnDamage)) TF2_RemoveCondition(client, TFCond_RadiusHealOnDamage);
	}
}
