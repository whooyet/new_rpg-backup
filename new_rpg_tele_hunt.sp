#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <new_rpg>

public OnPluginStart()
{
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientPutInServer(i) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);

public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(AliveCheck(attacker) && AliveCheck(client))
	{
		if(attacker != client && GetAbility(client, "tele_hunt"))
		{
			decl Float:pos[3], Float:cpos[3], Float:angle[3];
				
			GetClientAbsOrigin(client, cpos);
			GetClientAbsOrigin(attacker, pos);
			GetClientAbsAngles(attacker, angle);
			
			pos[2] += 150.0;
			effect(client, cpos, 2.0, "spell_cast_wheel_blue");
			effect(attacker, pos, 2.0, "spell_cast_wheel_blue");
			
			TeleportEntity(client, pos, angle, NULL_VECTOR);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock effect(entity, Float:pos[3], Float:time, String:effect[], bool:pp = false)
{
	new ent = CreateEntityByName("info_particle_system");
	if (ent != -1)
	{
		DispatchKeyValueVector(ent, "origin", pos);
		DispatchKeyValue(ent, "effect_name", effect);
		DispatchSpawn(ent);
					
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Start");
		
		if(pp)
		{
			SetVariantString("!activator");
			AcceptEntityInput(ent, "SetParent", entity);
		}
					
		CreateTimer(time, killll, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:killll(Handle:timer, any:iEntityRef)
{
	new ent = EntRefToEntIndex(iEntityRef);
	if(!IsValidEntity(ent)) return Plugin_Stop;
	AcceptEntityInput(ent, "Kill");
	return Plugin_Continue;
}