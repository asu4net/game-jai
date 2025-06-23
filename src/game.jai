player : Entity;
moveplc : Entity;

start_game :: () {
    player = dlz_entity(read_entire_file("assets/player.prefab" ,,temp));
    moveplc = dlz_entity(read_entire_file("assets/moveplaceholder.prefab",,temp));
    
}

update_game :: (delta_seconds : f32) {
    get_component(Transform2D_Component, player).pos += RIGHT_2D * 0.5 * delta_seconds;

    get_component(Movement2D_Component, moveplc).start = true;
    get_component(Movement2D_Component, moveplc).target = get_component(Transform2D_Component, player).pos;

    movement := get_entity_view(Transform2D_Component, Movement2D_Component);
    for entity : movement {
        if has_component(KeyboardMovement_Component, entity) then input_update(entity);
        update_movement(entity);
    } 
}