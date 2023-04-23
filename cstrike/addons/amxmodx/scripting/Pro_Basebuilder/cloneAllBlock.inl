#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>
#include <fun>
#include <cstrike>
#include <hamsandwich>
#include <fvault>

new cloneBlockOffset;
new szFile[88];

new Float:userBlockConnectOrigin[2][3];
new userBlockConnect[33];
new bool:userBlockStart[33][2];
public cloneOffset(id){
	if( !has_flag(id, "a") )
		return PLUGIN_CONTINUE
	new szOffset[4]
	read_argv(1, szOffset, sizeof(szOffset))
	cloneBlockOffset=str_to_num(szOffset);
	writeOffsetBlock()
	adminLockBlock(id)
	return PLUGIN_CONTINUE
	
}
adminLockBlock(id, item=1){
	if( !has_flag(id, "a" ) )
		return 0;
	new gText[128], iLen
	iLen = format(gText[iLen], sizeof(gText)-iLen-1, "Block Menu")
	iLen = format(gText[iLen], sizeof(gText)-iLen-1, "\d^nOffset: %d",cloneBlockOffset)
	new menu=menu_create(gText, "adminLockBlock_2")
	menu_additem(menu, "Lock/Unlock the Block")	
	menu_additem(menu, "Delete Block")	
	menu_additem(menu, "Save")	
	menu_additem(menu, "Load")	
	menu_additem(menu, "Reset")	
	format(gText, sizeof(gText), "Change offset: %d",cloneBlockOffset)
	menu_additem(menu, gText)
	if( !userBlockStart[id][0] )
		menu_additem(menu, "Select a block")
	else menu_additem(menu, "Connect the blocks")	
	menu_additem(menu, "Reverse vec")
	menu_additem(menu, "Reset vec")
	menu_additem(menu, "Delete Time")
	menu_additem(menu, "ID")
	
	menu_display(id,menu,item/7)
	return 1;
}
public removeColor(ent){	
	set_pev(ent,pev_rendermode,kRenderNormal)
	set_pev(ent,pev_renderamt, 255.0 )
}
public adminLockBlock_2(id, menu, item){
	if( item == MENU_EXIT ){
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	new ent, body
	get_user_aiming(id, ent, body)
	switch(item){
		case 0:{
			
			if( !is_valid_ent(ent) ){
				print_color(id, "^x01--- ^x04 Eat for anything^x01  ---")	
				adminLockBlock(id)			
				return PLUGIN_HANDLED;
			}
			switch(GetEntMover(ent)){
				case 0:{
					set_pev(ent,pev_rendermode,kRenderTransColor)
					set_pev(ent,pev_rendercolor, Float:{163.0, 1.0, 37.0} )
					set_pev(ent,pev_renderamt, 240.0 )	
					SetEntMover(ent, 1)
					print_color(id, "^x01--- ^x04 Blocked ^x01[ ^x04%d^x01 ]  ---", ent)
					set_task(0.5, "removeColor", ent)
				}
				case 1:{					
					set_pev(ent,pev_rendermode,kRenderTransColor)
					set_pev(ent,pev_rendercolor, Float:{37.0, 167.0, 1.0} )
					set_pev(ent,pev_renderamt, 240.0 )	
					UnsetEntMover(ent)
					print_color(id, "^x01---^x04  Unlocked ^x01[ ^x04%d^x01 ]  ---", ent)
					set_task(0.5, "removeColor", ent)
				}
			}		
			
			adminLockBlock(id)
				
			
		}
		case 1:{
			
			if( ent == 0 )							
				return PLUGIN_HANDLED;
				
			if( !is_valid_ent(ent) ){
				print_color(id, "^x01--- ^x04 Eat for anything^x01  ---")		
				adminLockBlock(id)			
				return PLUGIN_HANDLED;
			}
			remove_entity(ent)
			
			adminLockBlock(id)
		}
		case 2:{
			saveCloneBlock()
			adminLockBlock(id)
		}
		case 3:{
			loadCloneBlock()
			adminLockBlock(id)
		}
		case 4:{
			new file = fopen(szFile, "wt")	
			fclose(file)
			adminLockBlock(id)
		}	
		case 5:{
			client_cmd(id, "messagemode bb_offset")
			adminLockBlock(id)
		}
		case 6:{
			if( !ent ){
				print_color(id, "^x01---^x04  Eat for anything^x01  ---")
				adminLockBlock(id, item)
				return PLUGIN_CONTINUE
			}
			if( !userBlockStart[id][0] ){
				userBlockConnect[id] = ent;
				userBlockStart[id][0] = true
				userBlockStart[id][1] = false;
				adminLockBlock(id, item)
			}else{
				new iOrigin[3]
				get_user_origin(id, iOrigin, 3)
			
				
				
				if( !userBlockStart[id][1]  ){
					IVecFVec(iOrigin, userBlockConnectOrigin[0])	
					userBlockStart[id][1] = true
					if( userBlockConnect[id] != ent ){
						entity_set_int(userBlockConnect[id], EV_INT_team, ent)
					}
					
				}else{			
					IVecFVec(iOrigin, userBlockConnectOrigin[1])	
					
					if( userBlockConnect[id] != ent ){
						entity_set_int(userBlockConnect[id], EV_INT_team, ent)
					}
					
					new Float:fVec[3]
					fVec[0] = userBlockConnectOrigin[0][0] - userBlockConnectOrigin[1][0]
					fVec[1] = userBlockConnectOrigin[0][1] - userBlockConnectOrigin[1][1]
					fVec[2] = userBlockConnectOrigin[0][2] - userBlockConnectOrigin[1][2]
					entity_set_vector(userBlockConnect[id], EV_VEC_vuser1, fVec)
					
					BeamLight(userBlockConnectOrigin[0], userBlockConnectOrigin[1], spriteBeam, 0, 0, 40, 30, 0, 255, 255, 255, 255, 255)
					
					print_color(id, "^x01--- ^x04 Blocks have been merged^x01  ---")
					
					
					userBlockConnect[id] = 0
					userBlockStart[id][0] = false;
					userBlockStart[id][1] = false;
				}
				adminLockBlock(id, item)
			}
		}
		case 7:{
			if( userBlockConnect[id] == 0){				
				print_color(id, "^x01---^x04  The clipboard is empty^x01  ---")
				adminLockBlock(id)
				return PLUGIN_CONTINUE
			}
			
			new Float:fVec[3]
			entity_get_vector(userBlockConnect[id], EV_VEC_vuser1, fVec)
			fVec[0] *=  -1.0
			fVec[1] *=  -1.0
			fVec[2] *=  -1.0
			entity_set_vector(userBlockConnect[id], EV_VEC_vuser1, fVec)
					
			userBlockConnect[id] = 0
			userBlockStart[id][0] = false;
			userBlockStart[id][1] = false;
			adminLockBlock(id, item)
			
			
		}
		case 8:{
			if( ent ){
				print_color(id, "^x01---^x04  Vector reset^x01  ---")				
				entity_set_vector(ent, EV_VEC_vuser1, Float:{0.0,0.0,0.0})					
			}else{
				print_color(id, "^x01---^x04  Go to the Block^x01  ---")		
			}
			adminLockBlock(id, item)			
		
		}
		case 9:{
			adminLockBlock(id, item)
		}
		case 10:{
			
			print_color(id, "---^x01  ENT:^x03 %d^x04  ---", ent)
			adminLockBlock(id, item)
		}
	}	
	return PLUGIN_HANDLED;
}

public rotateBlock(id){
	new ent = g_iOwnedEnt[id]
	
	if( isPlayer(ent) ) return;
	
	if( ent != 0 ){			
		
		new entNew 	= entity_get_int(ent, EV_INT_team)
		if( entNew == 0 ){
			set_dhudmessage(255, 42, 85, -1.0, 0.65, 0, 6.0, 12.0)
			show_dhudmessage(id, "--- It can not be rotated ---")
			return;
		}	
		new entNext 	= entity_get_int(entNew, EV_INT_team)
		
		
		new Float:fFloat[3]
		pev(entNew, pev_mins, fFloat)
		set_pev(ent, pev_mins, fFloat)
		
		pev(entNew, pev_maxs, fFloat)
		set_pev(ent, pev_maxs, fFloat)	
	
		new Float:fVec[3]
		pev(ent, pev_vuser1, fVec)
		fOffset[id][0] += fVec[0]
		fOffset[id][1] += fVec[1]
		fOffset[id][2] += fVec[2]		
		entity_set_int(ent, EV_INT_modelindex, entity_get_int(entNew, EV_INT_modelindex))
		entity_set_int(ent, EV_INT_team, entNext)		
		pev(entNew, pev_vuser1, fVec)
		set_pev(ent, pev_vuser1, fVec)
		//moveEnt(id)
		
	}
}

public autoLoadCloneBlock(){
	if( file_exists(szFile) ){
		loadCloneBlock()
		serverLetClone=true
	}else serverLetClone=false;
}

public readOffsetBlock(){	
	new szOffsetFile[128]
	new szFolder[32]
	new szMap[32]
	get_mapname(szMap, sizeof(szMap))
	get_configsdir(szFolder, sizeof(szFolder))			
	format(szOffsetFile,sizeof(szOffsetFile),"%s/CloneOffset/%s.bb", szFolder, szMap)
	
	new file = fopen(szOffsetFile, "rt")	
	
	new szData[4]
	fgets(file, szData, sizeof(szData));
	cloneBlockOffset=str_to_num(szData)
	fclose(file)
}

public writeOffsetBlock(){	
	new szOffsetFile[128]
	new szFolder[32]
	new szMap[32]
	get_mapname(szMap, sizeof(szMap))
	get_configsdir(szFolder, sizeof(szFolder))			
	format(szOffsetFile,sizeof(szOffsetFile),"%s/CloneOffset/%s.bb", szFolder, szMap)
	
	new file = fopen(szOffsetFile, "wt")	
	
	new szData[4]
	format(szData, sizeof(szData), "%d", cloneBlockOffset)
	fputs(file, szData)
	fclose(file)
}

public loadCloneBlock(){
	new szData[256]
	if( file_exists(szFile) ){	
		new file = fopen(szFile, "rt")		
		new szType[2]
		new szEnt[5]
		new szOrigin[3][17]
		new szVec[3][17]
		new szRotate[6]	
		new Float:fOrigin[3], Float:fVec[3]
		new szClass[10], szTarget[7];
		while( !feof(file) ){	
			
			fgets(file, szData, sizeof(szData));
			parse(szData, 
				szType, 	sizeof(szType),
				szEnt, 		sizeof(szEnt),
				szOrigin[0], 	sizeof(szOrigin[]),
				szOrigin[1], 	sizeof(szOrigin[]),
				szOrigin[2], 	sizeof(szOrigin[]),
				szRotate,	sizeof(szRotate),
				szVec[0], 	sizeof(szVec[]),
				szVec[1], 	sizeof(szVec[]),
				szVec[2], 	sizeof(szVec[])
			)
			
			new ent = str_to_num(szEnt)+cloneBlockOffset
			if( !is_valid_ent(ent) || ent == 0 )			
				continue;
			
			if( ent == g_iEntBarrier )
				continue
				
			entity_get_string(ent, EV_SZ_classname, szClass, 9);
			entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
				
				
			if( !equal(szClass, "func_wall")) 
				continue
			if( equal(szTarget, "ignore") )
				continue
			if( equal(szTarget, "barrier") )
				continue
				
			if( equal(szTarget, "JUMP") )
				continue
				
			for( new i = 0;i <3; i ++ ){
				fOrigin[i]=str_to_float(szOrigin[i])
				fVec[i]=str_to_float(szVec[i])
			}
			switch( str_to_num(szType) ){
				case 0:{		
					remove_entity(ent)
					//entity_set_origin(ent, Float:{-8192.0,-8192.0,-8192.0})
				}
				case 1:{			
						
			
					//set_pev(ent, pev_movetype, MOVETYPE_FLY)
					//set_pev(ent, pev_solid, SOLID_SLIDEBOX)
					//log_amx("%s : Rotate: %d", szData, str_to_num(szRotate))
					entity_set_int(ent, EV_INT_team, str_to_num(szRotate))
					SetEntMover(ent, 2)
					set_pev(ent ,pev_vuser3, fOrigin)	
					entity_set_origin(ent, fOrigin)
					entity_set_vector(ent, EV_VEC_vuser1, fVec)
					//set_pev(ent,pev_rendermode,kRenderTransTexture)
					//set_pev(ent,pev_renderamt, 255.0 )
				}
				case 2:{
					entity_set_int(ent, EV_INT_team, str_to_num(szRotate))
					entity_set_vector(ent, EV_VEC_vuser1, fVec)
					
				}
			}
		}
		
		fclose(file)
	}
}

public saveCloneBlock(){
	new szData[128]
	new file = fopen(szFile, "wt")	
	if( file ){
		for( new ent = 1024 ; ent> MAXPLAYERS; ent -- ){
			if( !is_valid_ent(ent)  )
				continue;
			
			if( ent == g_iEntBarrier )
				continue
			
			new szClass[10], szTarget[7];
			entity_get_string(ent, EV_SZ_classname, szClass, 9);
			entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
			
			if( !equal(szClass, "func_wall")) 
				continue
			if( equal(szTarget, "ignore") )
				continue
			if( equal(szTarget, "barrier") )
				continue
			
			new Float:fOrigin[3], Float:fVec[3]
			pev(ent, pev_origin, fOrigin)
			pev(ent, pev_vuser1, fVec)
			format(szData, sizeof(szData), "%d %d %f %f %f %d %f %f %f^n", GetEntMover(ent), ent, fOrigin[0], fOrigin[1], fOrigin[2], entity_get_int(ent, EV_INT_team), fVec[0], fVec[1], fVec[2])
		
			fputs(file, szData)
			
		}
		fclose(file)
		print_color(0, "^x01---^x04  Blocks Saved^x01  ---")
	}
	
}

public clonePrepare(){
	readOffsetBlock()
	new szDir[128]
	new szFolder[32]
	new szMap[32]
	get_mapname(szMap, sizeof(szMap))
	get_configsdir(szFolder, sizeof(szFolder))			
	format(szFile,sizeof(szFile),"%s/CloneBlock/%s.bb", szFolder, szMap)
	autoLoadCloneBlock()
	
	get_basedir(szDir,sizeof(szDir))
	
	
	format(szDir,sizeof(szDir),"%s/itemsLog",szDir)
	if( !file_exists(szDir) )
		mkdir(szDir)
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/

stock BeamLight(Float:fOriginStart[3], Float:fOriginEnd[3], sprite, framestart, framerate, life, width, noise, r, g, b, bright, scroll){
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY) ;
    write_byte(TE_BEAMPOINTS);
    engfunc(EngFunc_WriteCoord,fOriginStart[0]);
    engfunc(EngFunc_WriteCoord,fOriginStart[1]);
    engfunc(EngFunc_WriteCoord,fOriginStart[2]);
    engfunc(EngFunc_WriteCoord,fOriginEnd[0]);
    engfunc(EngFunc_WriteCoord,fOriginEnd[1]);
    engfunc(EngFunc_WriteCoord,fOriginEnd[2]);
    write_short(sprite);
    write_byte(framestart);
    write_byte(framerate);
    write_byte(life) ;
    write_byte(width); 
    write_byte(noise);
    write_byte(r);
    write_byte(g);
    write_byte(b);
    write_byte(bright);
    write_byte(scroll);
    message_end();
} 