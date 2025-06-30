//---------------------------
//:GAME
//---------------------------


#scope_file

player   : Entity;
kamikaze : Entity;
homing  : Entity;

#scope_export

is_game_init :: inline () -> bool {
    return inited;
}

get_player :: () -> Entity {
    return player;
}

init_game :: () {
    log("Init game!");
    player   = dlz_entity_from_file("assets/player.prefab");
    kamikaze = dlz_entity_from_file("assets/kamikaze.prefab");
    homing  = dlz_entity_from_file("assets/homing_missile.prefab");

    init_player(player);
}

update_game :: () {
    if !should_update_game() 
    then return;

    update_enemies();
    if player != NULL_ENTITY
    then update_player(player);
}

deinit_game :: () {
    log("Deinit game!");

    deinit_player(player);

    destroy_game_entity :: (entity : *Entity) {
        if entity.* != NULL_ENTITY {
            destroy_entity(entity.*);
            entity.* = NULL_ENTITY;
        }
    }
    destroy_game_entity(*homing);
    destroy_game_entity(*kamikaze);
    destroy_game_entity(*player);
}

update_enemies :: () {
    for get_entity_view(Kamikaze_Skull) update_kamikaze(it);
    for get_entity_view(Homing_Missile_Component) update_homing_missile(it);
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#load "components/game/keyboard_movement.jai";
#load "components/game/player.jai";
#load "components/game/kamikaze.jai";
#load "components/game/homing_missile.jai";


#scope_file

//#REVIEW_asuarez More commands stuff (maybe this should be in utils or main)
inited : bool;
should_update_game :: () -> bool {

    #if EDITOR {
        if !Input.is_key_down(.SHIFT) && Input.is_key_down(.F5) && !inited {
            inited = true;
            init_game();
        } else if  Input.is_key_down(.SHIFT) && Input.is_key_down(.F5) && inited {
            inited = false;
            deinit_game();
        }
    }

    return inited;
}