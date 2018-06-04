#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

#define Explosion_disance 200
#define Explosion_force 470.0

new Float:blackholePos[33][3];

public OnEntityDestroyed(iEntity)
{
	if(!IsValidEdict(iEntity)) return;
	decl String:szBuffer[64];
	GetEdictClassname(iEntity, szBuffer, 64);
	
	if(StrEqual(szBuffer, "tf_projectile_syringe"))
	{
		new client = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		
		if(!PlayerCheck(client)) return;
		if(!GetAbility(client, "medic_medic")) return;
		
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", blackholePos[client]);
		SpawnExplosion(iEntity);
	}
}

stock SpawnExplosion(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(!PlayerCheck(owner)) return;
	if(!GetAbility(owner, "medic_medic")) return;
	 
	AcceptEntityInput(entity, "Kill")
	
	new particle = effect(entity, blackholePos[owner], 1.0, "xms_snowburst");
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if(AliveCheck(client) && GetClientTeam(owner) != GetClientTeam(client) || owner == client)
		{
			float clientPos[3], explosionPos[3];
			GetClientAbsOrigin(client, clientPos);
			GetEntPropVector(particle, Prop_Send, "m_vecOrigin", explosionPos);
			clientPos[2] += 30.0;
			float distance = GetVectorDistance(clientPos, explosionPos);
		
			if(distance < Explosion_disance)
			{
				SetEntPropEnt(client, Prop_Data, "m_hGroundEntity", -1);
				float direction[3];
				SubtractVectors(clientPos, explosionPos, direction);
				NormalizeVector(direction, direction);
				if (distance <= 20.0) distance = 20.0;
				ScaleVector(direction, Explosion_force);
		
				float playerVel[3];
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", playerVel);
				AddVectors(playerVel, direction, direction);
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, direction);
			}
		}
	}
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
					
		CreateTimer(time, DeleteParticle, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	}
	return ent;
}

public Action:DeleteParticle(Handle:timer, any:pc)
{
    if (IsValidEntity(pc))
    {
        new String:classN[64];
        GetEdictClassname(pc, classN, sizeof(classN));
        if (StrEqual(classN, "info_particle_system", false)) RemoveEdict(pc);
    }
}