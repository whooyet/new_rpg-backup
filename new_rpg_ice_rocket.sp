#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define FREEZE "physics/glass/glass_impact_bullet4.wav"

public OnPluginStart()
	for(new i = 1; i <= MaxClients; i++) if(PlayerCheck(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	
public OnClientPutInServer(i) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
public OnMapStart() PrecacheSound(FREEZE, true);


public Action:OnTakeDamage(attacker, &client, &inflictor, &Float:fDamage, &iDamagetype, &iWeapon, Float:fForce[3], Float:fForcePos[3], damagecustom)
{
	if(AliveCheck(attacker) && AliveCheck(client))
	{
		if(GetAbility(client, "ice_rocket"))
		{
			if(GetClientTeam(client) != GetClientTeam(attacker))
			{
				if(IsValidEntity(inflictor))
				{
					decl String:Entclassname[64];
					GetEntityClassname(inflictor, Entclassname, sizeof(Entclassname));
					
					if(StrEqual(Entclassname, "tf_projectile_rocket"))
					{
						EmitSoundToClient(attacker, FREEZE);
						if(GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity") == client)
						{
							SetEntityRenderMode(attacker, RENDER_TRANSCOLOR);
							SetEntityRenderColor(attacker, 0, 17, 255, 255);
							SetEntityMoveType(attacker, MOVETYPE_NONE);
							CreateTimer(1.0, ice_off, attacker);
						}
					}
				}
			}
			else
			{
				fDamage = 75.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:ice_off(Handle:timer, any:client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR)
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityMoveType(client, MOVETYPE_WALK);
}
