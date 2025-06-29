//---------------------------
//:GAME
//---------------------------

player : Entity;

init_game :: () {
    player = dlz_entity_from_file("assets/player.prefab");
}

update_game :: () {
    update_enemies();
    update_player(player);
}

deinit_game :: () {

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