move_entities2d :: () {
    view := get_entity_view(Transform2D_Component, Movement2D_Component);
    for view {
        if has_component(KeyboardMovement_Component, it) 
        then input_update(it);
        update_movement(it);
    }
}