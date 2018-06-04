#include <tf2items>
#include <tf2idb>
#include <sdktools>
#include <tf2_stocks>
#include <new_rpg>

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], index, &Handle:hItem)
{
	if(GetClientLevel(client) >= 0)
	{
		if(GetWeaponSlot(client, index, 0)) return Plugin_Handled;
		if(GetWeaponSlot(client, index, 1)) return Plugin_Handled;
		if(GetWeaponSlot(client, index, 2)) return Plugin_Handled;
		if(TF2_GetPlayerClass(client) == TFClassType:TFClass_Spy) if(GetWeaponSlot(client, index, 3)) return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock bool:GetWeaponSlot(client, index, num)
{ 
	if(TF2IDB_GetItemSlot(index) == TF2ItemSlot:num) return true;
	return false;
}