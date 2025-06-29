//---------------------------
//:GAME
//---------------------------


#scope_file

player : Entity;
inited : bool;

#scope_export

is_game_init :: inline () -> bool {
    return inited;
}

get_player :: () -> Entity {
    return player;
}

init_game :: () {
    log("Init game!");
    player = dlz_entity_from_file("assets/player.prefab");
}

update_game :: () {

    #if EDITOR {
        if !Input.is_key_down(.SHIFT) && Input.is_key_down(.F5) && !inited {
            inited = true;
            init_game();
        } else if  Input.is_key_down(.SHIFT) && Input.is_key_down(.F5) && inited {
            inited = false;
            deinit_game();
        }
    }

    if !inited 
    then return;

    update_enemies();
    update_player(player);
}

deinit_game :: () {
    log("Deinit game!");
    destroy_entity(player);
    player = NULL_ENTITY;  
}

update_enemies :: () {
    view := get_entity_view(Kamikaze_Skull);
    for view {
        kamikaze_update(it);
    }
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#load "components/game/keyboard_movement.jai";
#load "components/game/player.jai";
#load "components/game/kamikaze.jai";