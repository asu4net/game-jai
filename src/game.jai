moveplc : Entity;

start_game :: () {
    moveplc = dlz_entity(read_entire_file("assets/moveplaceholder.prefab",,temp));
    get_component(Movement2D_Component, moveplc).start = true;
}

update_game :: () {
    move_entities2d();
}