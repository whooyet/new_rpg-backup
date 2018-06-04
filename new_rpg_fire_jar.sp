#include <sdktools>
#include <new_rpg>
#include <tf2_stocks>

new JatateCheck[33];

public OnPluginStart() HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);

public OnClientPutInServer(i) JatateCheck[i] = 0;

public Action:Event_PlayerJarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
	if(GetAbility(client, "fire_jar")) JatateCheck[victim] = client;
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(AliveCheck(client) && GetAbility(client, "fire_jar"))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(AliveCheck(i) && JatateCheck[i] == client)
			{ 
				TF2_IgnitePlayer(i, client);
				if(TF2_IsPlayerInCondition(i, TFCond_OnFire)) JatateCheck[i] = 0;
			}
		}
	}
}