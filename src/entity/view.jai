Entity_View :: struct {
    shortest_arena : *Component_Arena_Base;
    arenas : [..] *Component_Arena_Base;
}

get_entity_view :: (types : ..Type) -> Entity_View {
    EntityStorageContext();
    using view : Entity_View;
    // Optimization: We find the shortest arena of the given types.
    for types {
        arena := get_component_arena_base(it);
        assert(arena != null);
        if !shortest_arena || arena.count < shortest_arena.count
        then shortest_arena = arena;
        else array_add(*arenas, arena ,,temp);
    }
    assert(shortest_arena != null);
    return view;
}

for_expansion :: (view: Entity_View, body: Code, flags: For_Flags) #expand {
    index : int;
    for i : 0..view.shortest_arena.count-1 {
        entity := view.shortest_arena.entities.dense[i];
        
        // If the entity is destroyed we don't care.
        if !is_not_destroyed(entity)
        then continue;

        // We have to test if the entity contains all the components.
        is_not_archetype : bool;
        for arena : view.arenas {
            if !test(*arena.entities, entity) {
                is_not_archetype = true;
                break;
            }
        }
        if is_not_archetype
        then continue;
        
        // If it is the archetype we create the iterator variables. 
        `it_index := index;
        `it := entity;

        // Then insert the user body and increment the index.
        #insert body;
        index += 1;
    }
}