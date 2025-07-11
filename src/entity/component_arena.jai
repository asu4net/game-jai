#load "component_type.jai";

Component_Arena_Base :: struct {
    data      : *void;    
    count     : s64;
    capacity  : s64;
    type      : Component_Type;
    entities  : Sparse_Set;
}

Component_Arena :: struct($T : Type) {
    #as using base : Component_Arena_Base;
    components : []T;
}

init_component_arena :: (using arena : *Component_Arena($T), cap : s64) {
    array := NewArray(cap, T);
    data = array.data;
    capacity = cap;
    components.data = data;
    components.count = cap;
    init_sparse_set(*entities, xx MAX_ENTITIES);
    init_component_type(*type, T);
    log("Initialized % component arena.", arena.type.info.name);
}

deinit_component_arena :: (using arena : *Component_Arena($T)) {
    arena_name := copy_string(arena.type.info.name ,,temp);
    free(data);
    deinit_sparse_set(*entities);
    arena.* = .{};
    log("Freed % component arena.", arena_name);
}