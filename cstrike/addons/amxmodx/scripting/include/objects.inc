#if defined _objects_core_included
	#endinput
#endif

#define _objects_core_included

enum {
	MENU_MAIN,
	MENU_OBJECTS
};

#if !defined _obj_block_natives
	native obj_register 		(const szName[], const szModel[], const szSize[], const szClassname[]);
	native obj_remove			(iObject);
	native obj_create			(Float:fOrigin[3], Float:fAngles[3] = {0.0, 0.0, 0.0}, iObject, iSeq = 0, iSolid = 2);
	native obj_show_menu		(iPlayer, iMenu, iPosition = 0);
	
	forward player_touch_object	(iPlayer, iEntity);
	forward creating_object		(iObject, iEntity, iSeq, iSolid);
#endif