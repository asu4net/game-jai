//---------------------------
//:GAME
//---------------------------

Game_State :: struct {
    player   : Entity;
    kamikaze : Entity;
    homing  : Entity;
}

#add_context game_state: *Game_State;

get_player :: inline () -> Entity {
    return context.game_state.player;
}

is_game_init :: inline () -> bool {
    return context.game_state != null;
}

init_game :: () {
    if is_game_init()
    then deinit_game();
    
    log("Init game!");
    game := New(Game_State);
    context.game_state = game; 

    init_damage_registry();

    game.player   = dlz_entity_from_file("assets/player.prefab");
    game.kamikaze = dlz_entity_from_file("assets/kamikaze.prefab");
    game.homing  = dlz_entity_from_file("assets/homing_missile.prefab");
    set_pos(game.homing, UP_2D * 1);
    set_pos(game.kamikaze, UP_2D * 1);
}

update_game :: () {
    if !should_update_game() 
    then return;
    
    for get_entity_view(Timer_Component) {
        update_timer_component(it);
    }
    for get_entity_view(Kamikaze_Skull) {
        update_kamikaze(it);
    }
    for get_entity_view(Homing_Missile_Component) {
        update_homing_missile(it);
    }

    if get_player() != NULL_ENTITY
    then update_player(get_player());
    
    move_entities();
    query_2d_collisions();
    query_damage_collisions();
    process_player_damage();
}

deinit_game :: () {
    log("Deinit game!");
    assert(is_game_init());

    destroy_game_entity :: (entity : *Entity) {
        if entity.* != NULL_ENTITY {
            destroy_entity(entity.*);
            entity.* = NULL_ENTITY;
        }
    }

    using game := context.game_state;
    destroy_game_entity(*homing);
    destroy_game_entity(*kamikaze);
    destroy_game_entity(*player);

    deinit_damage_registry();

    free(game);
    context.game_state = null;
}