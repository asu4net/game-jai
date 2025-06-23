Transform2D_Component :: struct @Component @InitOrder(0) @Max(MAX_ENTITIES) {
    pos := ZERO_2D;
    scl := ONE_2D;
    ang := (0.0).(f32);
}

get_matrix :: (entity : Entity) -> m4 {
    
    transform := get_component(Transform2D_Component, entity);
    child_matrix := make_transform(transform.pos, transform.ang, transform.scl);
    
    if !is_not_destroyed(entity)
    then return child_matrix;

    parent := get_parent(entity);

    child_pos := transform.pos;
    child_ang := transform.ang;
    child_scl := transform.scl;

    current_entity := entity;

    while is_not_destroyed(get_parent(current_entity)) {
        parent = get_parent(current_entity);
        
        if !has_component(Transform2D_Component, parent)
        then continue;

        parent_transform := get_component(Transform2D_Component, parent);
        child_pos += parent_transform.pos;
        
        child_pos = rotate_around(parent_transform.pos, parent_transform.ang, child_pos);

        child_ang += parent_transform.ang;
        child_scl *= parent_transform.scl;

        current_entity = parent;
    }

    return make_transform(child_pos, child_ang, child_scl);
}