#include <new_rpg>

public OnPluginStart()
{
	HookEvent("player_healed", Event_localplayer_healed);
}

public Event_localplayer_healed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "healer"));
	new amount = GetEventInt(event, "amount");
	
	if(PlayerCheck(client) && GetAbility(client, "healing_bolt"))
	{
		if(amount >= 110)
		{
			SetClientExp(client, 1, 0);
			PrintToChat(client, "\x03[Exp Up] 110 이상 힐 들어가서 경험치 1 증가");
			
			if(GetClientExp(client) >= GetExp(client))
			{
				SetClientLevel(client, GetClientLevel(client) + 1);
				GetWeapon(client);
			}
		}
	}
}