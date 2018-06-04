#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define MINE_MODEL "models/props_lab/tpplug.mdl"
#define BOMB_SOUND "weapons/explode3.wav"


public OnPluginStart()
{
	HookEvent("player_death", EventDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", iv, EventHookMode_Post);
}

public OnMapStart()
{
	PrecacheModel(MINE_MODEL, true);
	PrecacheSound(BOMB_SOUND, true);
}

public OnClientDisconnected(client) FindMine(client);


public OnEntityDestroyed(iEntity)
{
	if(!IsValidEdict(iEntity)) return;
	decl String:szBuffer[64];
	GetEdictClassname(iEntity, szBuffer, 64);
	
	decl Float:origin[3], Float:vAngles[3];
	GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(iEntity, Prop_Data, "m_angRotation", vAngles);
		
	if(StrEqual(szBuffer, "tf_projectile_arrow"))
	{
		new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(!PlayerCheck(client)) return;
		if(!GetAbility(client, "mine")) return;

		new ent = CreateEntityByName("prop_dynamic_override");
		if(!IsValidEntity(ent)) return;
		SetEntityModel(ent, MINE_MODEL);
		DispatchKeyValue(ent, "targetname", "mine");
		SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client); 
		SetEntProp(ent, Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
		SetEntProp(ent, Prop_Data, "m_nSolidType", 6);
		DispatchSpawn(ent);
		
		vAngles[0] = -90.0;
		TeleportEntity(ent, origin, vAngles, NULL_VECTOR);
		
		SDKHook(ent, SDKHook_StartTouch, OnTouch);
	}
}

public Action:OnTouch(entity, other) 
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!PlayerCheck(client)) return Plugin_Handled;
	
	if (AliveCheck(other))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", origin);
		
		if(GetClientTeam(other) != GetClientTeam(client))
		{
			Boooom(other, origin);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(AliveCheck(i) && GetClientTeam(client) != GetClientTeam(i))
				{
					new Float:vEPosit[3], Float:Dist;
					GetClientAbsOrigin(i, vEPosit);
					Dist = GetVectorDistance(origin, vEPosit);
					
					if(Dist <= 450.0)
					{
						SDKHooks_TakeDamage(i, client, client, 999.0);
						if(other != i) PrintToChat(i, "\x07FFFFFF%N \x04님이 밟은 지뢰로 피해를 받아 사망하였습니다.", other);
						else PrintToChat(other, "\x04당신은 지뢰에 밟아 사망하였습니다.");
					}
				}
			}
			AcceptEntityInput(entity, "Kill");
		}
	}
	return Plugin_Handled;
}

public iv(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	FindMine(client);
}


public EventDeath(Handle:event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetAbility(client, "mine")) FindMine(client);
}

stock FindMine(client)
{
	new iEnt = -1;
	decl String:szName[16];
	while((iEnt = FindEntityByClassname2(iEnt, "prop_dynamic")) != -1)
	{
		if(IsValidEntity(iEnt) && iEnt > MaxClients)
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", szName, 16, 0);
			if(StrEqual(szName, "mine")) if(GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity") == client) AcceptEntityInput(iEnt, "Kill");
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