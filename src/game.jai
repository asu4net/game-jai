#load "game/editor/editor.jai";
#load "game/components/core/all.jai";
#load "game/components/game/all.jai";
#load "game/entity/entity_storage.jai";
#load "game/entity/entity_pool.jai";

//---------------------------
//:GAME
//---------------------------

Game_State :: struct {
    player : Entity;
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

    init_collisions2d();
    init_damage_registry();

    game.player = dlz_entity_from_file("assets/player.prefab");
    game.kamikaze = dlz_entity_from_file("assets/kamikaze.prefab");
    game.homing = dlz_entity_from_file("assets/homing_missile.prefab");

    init_player(game.player);

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

draw_game_frame :: () {

    //---------------------------
    //:DRAW ENTITIES 2D
    //---------------------------
    
    // // FlipBook.
    // {
    //     view := get_entity_view(FlipBook_Component);
    //     for view update_flipbook_entity(it);
    // }
    // Sprites.
    {
        view := get_entity_view(Transform2D_Component, Sprite_Component);
        for view draw_sprite_entity(it);
    }
    // Sprites.
    {
        view := get_entity_view(Transform2D_Component, GUI_Sprite_Component);
        for view draw_gui_sprite_entity(it);
    }
    // Texts.
    {
        view := get_entity_view(Transform2D_Component, GUI_Text_Component);
        for view draw_text_entity(it, *font);
    }
    // Collisions.
    #if EDITOR {
        if is_shortcut_pressed(.TOGGLE_SHOW_COLLIDERS) {
            show_colliders = !show_colliders;   
        }
        if show_colliders {
            view := get_entity_view(Transform2D_Component, Circle_Collider_Component);
            collisions_table := context.collisions2d.collisions_table;
            for view {
                coll := get_component(Circle_Collider_Component, it);
                ref := make_ref(it);
                if table_contains(*collisions_table, ref) {
                    collides_with := table_find_pointer(*collisions_table, ref);
                    if collides_with.count == 0 
                    then draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                    else draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_RED);
                } else {
                    draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                }
            }
        }
    }

    //---------------------------
    //:DRAW IMGUI
    //---------------------------

    #if IMGUI {
        draw_editor();
    }
}

deinit_game :: () {
    log("Deinit game!");
    assert(is_game_init());

    deinit_player(context.game_state.player);

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
    deinit_collisions2d();

    free(game);
    context.game_state = null;
}