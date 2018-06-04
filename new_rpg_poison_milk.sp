#include <sdkhooks>
#include <sdktools>
#include <new_rpg>

#define MILK_MODEL "models/weapons/c_models/c_madmilk/c_madmilk.mdl"

public OnMapStart() PrecacheModel(MILK_MODEL, true);

public OnEntityCreated(entity, const String:classname[])
	if(StrEqual(classname, "tf_projectile_cleaver", false)) SDKHook(entity, SDKHook_SpawnPost, OnSpawn);

public OnSpawn(ent)
{
	if(IsValidEntity(ent))
	{
		decl String:EntityName[64];
		GetEntityClassname(ent, EntityName, sizeof(EntityName));
		
		new client = GetEntPropEnt(ent,Prop_Data,"m_hOwnerEntity");
		
		if(PlayerCheck(client) && GetAbility(client, "poison_milk"))
			if(StrEqual(EntityName, "tf_projectile_cleaver")) SetEntityModel(ent, MILK_MODEL);
	}
}