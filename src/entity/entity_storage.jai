Entity_Storage :: struct {
    #as using generated_component_arenas : Generated_Component_Arenas;
    component_arenas : [..] *Component_Arena_Base;
}

Some_Component :: struct @Component @Max(100) {
    dummy : float;
}

#add_context entity_storage : Entity_Storage;

init_entity_storage :: () {
    using context.entity_storage;
    init_generated_component_arenas(*generated_component_arenas);
}

deinit_entity_storage :: () {
    using context.entity_storage;
    deinit_generated_component_arenas(*generated_component_arenas);
    context.entity_storage = .{};
}

clean_destroyed_entities :: () {
    
}