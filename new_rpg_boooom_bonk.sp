#include <sdkhooks>
#include <tf2_stocks>
#include <new_rpg>

#define BOMB_SOUND "weapons/explode3.wav"

new bool:BonkCheck[33];

public OnClientConnected(client) BonkCheck[client] = false;

public Action:OnPlayerRunCmd(client, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon)
{
	if(AliveCheck(client))
	{
		if(GetAbility(client, "boooom_bonk"))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Bonked)) BonkCheck[client] = true;
			else
			{
				if(BonkCheck[client])
				{
					decl Float:pos[3];
					GetClientAbsOrigin(client, pos);
					Boooom(client, pos);
					
					for(new i = 1; i <= MaxClients; i++)
					{
						if(AliveCheck(i) && GetClientTeam(client) != GetClientTeam(i))
						{
							new Float:vEPosit[3], Float:Dist;
							GetClientAbsOrigin(i, vEPosit);
							Dist = GetVectorDistance(pos, vEPosit);
			
							if(Dist <= 230.0) SDKHooks_TakeDamage(i, client, client, 999.0);
						}
					}
					
					Boooom(client, pos);
					ForcePlayerSuicide(client);
					BonkCheck[client] = false;
				}
			}
		}
	}
}

stock Boooom(client, Float:pos[3])
{
	new particle = CreateEntityByName("info_particle_system");
	
	if(IsValidEntity(particle)) 
	{
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", "fireSmokeExplosion_track");
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.1, DeleteParticles, particle);

		if(!IsSoundPrecached(BOMB_SOUND)) PrecacheSound(BOMB_SOUND);
 
		PrefetchSound(BOMB_SOUND);
	
		EmitAmbientSound(BOMB_SOUND, pos, client, SNDLEVEL_SCREAMING);
	}
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	new ent = EntRefToEntIndex(particle);

	if (ent != INVALID_ENT_REFERENCE)
	{
		new String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
			AcceptEntityInput(ent, "kill");
	}
}