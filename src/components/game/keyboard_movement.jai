KeyboardMovement_Component :: struct @Component @InitOrder(1200) @Max(MAX_ENTITIES) {
}

update_entity_input :: (entity : Entity) {
    using movement := get_component(Movement2D_Component, entity);

    if is_key_down(.W) then dir.y = 1; 
    else if is_key_down(.S) then dir.y = -1;
    else dir.y = 0;

    if is_key_down(.A) then dir.x = -1;    
    else if is_key_down(.D) then dir.x = 1;
    else dir.x = 0;

    if dir != ZERO_2D then dir = normalize(dir);
}