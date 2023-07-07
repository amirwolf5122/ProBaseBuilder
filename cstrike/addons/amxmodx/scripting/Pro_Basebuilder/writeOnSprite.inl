#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <engine>

new szSpriteAlfa[] = "sprites/firealfi1.spr";

public writeText(id){	
	new szSpriteTextHud[60], szScale[5], Float:scale = 0.5
	copy(szSpriteTextHud, sizeof(szSpriteTextHud)-1, "")
	read_argv(1, szSpriteTextHud, sizeof(szSpriteTextHud)-1)
	read_argv(2, szScale, sizeof(szScale)-1)
	if( str_to_float(szScale) != 0.0 )
		scale = floatabs(str_to_float(szScale))
	
	new ent = 0;
	while((ent = find_ent_by_class(ent, "writeHUD")) ){
		if( !pev_valid(ent) )
			continue
		remove_entity(ent)
	}
	ent = 0
	new Float:fOrigin[3], Float:fOriginTemp[3]
	entity_get_vector(id, EV_VEC_origin, fOrigin)
	fOrigin[2] += 16.0;
	fOriginTemp[0] = fOrigin[0]
	fOriginTemp[1] = fOrigin[1]
	fOriginTemp[2] = fOrigin[2]
	for( new i = 0; i < strlen(szSpriteTextHud); i ++ ){
		if( szSpriteTextHud[i] == 32 ){
			fOriginTemp[1] -= (52.0*scale);
			continue
		}
		if( szSpriteTextHud[i] == 33 ){			
			fOriginTemp[0] = fOrigin[0]
			fOriginTemp[1] = fOrigin[1]
			fOrigin[2] 	-= (52.0*scale)
			fOriginTemp[2] = fOrigin[2]
			continue
		}
		szSpriteTextHud[i] = tolower(szSpriteTextHud[i]);
		
		ent = create_entity("info_target")		
		entity_set_string(ent, EV_SZ_classname, "writeHUD")
		entity_set_model(ent, szSpriteAlfa)
		
		if( szSpriteTextHud[i] >= 97 ){
			entity_set_float(ent, EV_FL_frame, 	float(szSpriteTextHud[i]-97))
		}else entity_set_float(ent, EV_FL_frame, 	float(szSpriteTextHud[i]-22))
		
		
		entity_set_int(ent, EV_INT_rendermode, 5)
		entity_set_float(ent, EV_FL_renderamt, 255.0)
		entity_set_float(ent, EV_FL_scale, scale)
		entity_set_float(ent, EV_FL_framerate, 	0.0)
		entity_set_origin(ent, fOriginTemp)
		fOriginTemp[1] -= (36.0*scale);
	}
	
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
