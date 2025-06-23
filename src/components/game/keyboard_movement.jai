KeyboardMovement_Component :: struct @Component @InitOrder(1200) @Max(MAX_ENTITIES) {
}

update_entity_input :: (entity : Entity) {
    using movement := get_component(Movement2D_Component, entity);

    if Input.is_key_down(#char "W") then dir.y = 1; 
    else if Input.is_key_down(#char "S") then dir.y = -1;
    else dir.y = 0;

    if Input.is_key_down(#char "A") then dir.x = -1;    
    else if Input.is_key_down(#char "D") then dir.x = 1;
    else dir.x = 0;

    if dir != ZERO_2D then dir = normalize(dir);
}