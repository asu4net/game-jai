Component_Arena_Base :: struct {
    data      : *void;    
    count     : s64;
    capacity  : s64;
    type      : *Type_Info_Struct;
    entities  : Sparse_Set;

    // Generic procs.
    get : (entity : Entity)             -> *void;
    add : (entity : Entity)             -> *void;
    has : (entity : Entity)             -> bool;
    rem : (entity : Entity);
    slz : (entity : Entity)             -> string;
    dlz : (entity : Entity, s : string) -> *void;

    #if EDIT_MODE then drw : (entity : Entity);

    // Callbacks generic callers.
    call_add_cbk : (fn : *void, entity : Entity, component : *void);
    call_cpy_cbk : (fn : *void, entity : Entity, dst : *void, src : *void);
    call_rem_cbk : (fn : *void, entity : Entity, component : *void);

    // Callback generic proc ptrs.
    add_cbk_fn : *void;
    rem_cbk_fn : *void;
    cpy_cbk_fn : *void;
}

Component_Arena :: struct($T : Type) {
    #as using base : Component_Arena_Base;

    ADD_CBK :: #type (entity : Entity, cmp : *T);
    REM_CBK :: #type (entity : Entity, cmp : *T);
    CPY_CBK :: #type (entity : Entity, dst : *T, src : *T);
    
    components : []T;
}

init :: (using arena : *Component_Arena($T), cap : s64, add_proc : Component_Arena(T).ADD_CBK = null, rem_proc : Component_Arena(T).REM_CBK = null, cpy_proc : Component_Arena(T).CPY_CBK = null) {
    array := NewArray(cap, T);
    data = array.data;
    capacity = cap;
    components.data = data;
    components.count = cap;
    type = type_info(T);
    init(*entities, xx cap);
     
    get = (entity : Entity)             -> *void        { return get_component(T, entity);    }
    add = (entity : Entity)             -> *void        { return add_component(T, entity);    }
    has = (entity : Entity)             -> bool         { return has_component(T, entity);    }
    rem = (entity : Entity)                             {        rem_component(T, entity);    }
    slz = (entity : Entity)             -> string       { return slz_component(T, entity);    }
    dlz = (entity : Entity, s : string) -> *void        { return dlz_component(T, entity, s); } 

    #if EDIT_MODE then drw = (entity : Entity) { drw_component(T, entity); }

    add_cbk_fn = xx add_proc;
    rem_cbk_fn = xx rem_proc;
    
    def_cpy :: (entity : Entity, dst : *T, src : *T) { dst.* = src.*; }
    cpy_cbk_fn = xx ifx cpy_proc then cpy_proc else def_cpy;

    call_add_cbk = (fn : *void, entity : Entity, cmp : *void) {
        add_typed := fn.(Component_Arena(T).ADD_CBK);
        cmp_typed := cmp.(*T);
        add_typed(entity, cmp_typed);
    }
    
    call_rem_cbk = (fn : *void, entity : Entity, cmp : *void) {
        rem_typed := fn.(Component_Arena(T).REM_CBK);
        cmp_typed := cmp.(*T);
        rem_typed(entity, cmp_typed);
    }

    call_cpy_cbk = (fn : *void, entity : Entity, src : *void, dst : *void) {
        cpy_typed := fn.(Component_Arena(T).CPY_CBK);
        src_typed := src.(*T);
        dst_typed := dst.(*T);
        cpy_typed(entity, src, dst);
    }
    log("Initialized % component arena.", arena.type.name);
}

deinit :: (using arena : *Component_Arena($T)) {
    arena_name := copy_string(arena.type.name ,,temp);
    free(data);
    deinit(*entities);
    arena.* = .{};
    log("Freed % component arena.", arena_name);
}

Entity :: u32;
NULL_ENTITY :: U32_MAX;

Entity_Flag :: enum_flags u16 {
    LOCAL_ENABLED;
    ENABLED;
    PENDING_CLEAN;
}

Entity_Ref :: struct { 
    entity : Entity = NULL_ENTITY; @JsonIgnore @EditorReadOnly
    uuid   : u64; @EditorIgnore
}

Entity_Info :: struct {
    #if EDIT_MODE id : u32; @JsonIgnore @EditorReadOnly
    name : string;
    flags : Entity_Flag = .LOCAL_ENABLED | .ENABLED;
    uuid : u64; @JsonIgnore @EditorIgnore
    parent : Entity_Ref;
    children : [..] Entity_Ref;
}

Entity_Storage :: struct {
    using generated_component_arenas : Generated_Component_Arenas;
    
    component_arenas : [..] *Component_Arena_Base;
    
    free_queue  : Queue(Entity);
    to_clean    : [..] Entity;
    count       : s64;
    initialized : bool;
    
    info_arena  : Component_Arena(Entity_Info);
    uuid_seed   : u64;
    uuid_table  : Table(u64, Entity);
}

#add_context entity_storage : Entity_Storage;

is_entity_storage_initialized :: inline () -> bool {
    return context.entity_storage.initialized;
}

EntityStorageContext :: () #expand {
    assert(is_entity_storage_initialized());
    `state := *context.entity_storage;
    using state;
}

init_entity_storage :: () {
    assert(!is_entity_storage_initialized());
    context.entity_storage.initialized = true;
    EntityStorageContext();
    
    // Manually init the info arena.
    init(*state.info_arena, MAX_ENTITIES, cpy_proc = cpy_info, add_proc = null, rem_proc = null);
    init_generated_component_arenas(*state.generated_component_arenas, *state.component_arenas);
    state.uuid_seed = current_time_monotonic().low;
    random_seed(state.uuid_seed);
    init(*state.free_queue, MAX_ENTITIES);
    
    for 0..MAX_ENTITIES {
        push_back(*state.free_queue, xx it);
    }
}

is_local_enabled :: (entity : Entity) -> bool {
    assert(is_not_destroyed(entity));
    flags := get_info(entity).flags;
    return is_not_destroyed(entity) && (.LOCAL_ENABLED & flags).(bool);   
}

is_enabled :: (entity : Entity) -> bool {
    assert(is_not_destroyed(entity));
    flags := get_info(entity).flags;
    return is_local_enabled(entity) && (.ENABLED & flags).(bool);   
}

set_enabled :: (entity : Entity, enabled := true) {
    assert(is_not_destroyed(entity));
    info := get_info(entity);
    
    if !has_component(Node_Component, entity) {
        if enabled 
        then info.flags |= .ENABLED | .LOCAL_ENABLED;
        else {
            info.flags = info.flags &~ .ENABLED;
            info.flags = info.flags &~ .LOCAL_ENABLED;
        }
        return;
    }

    is_local_enabled := (.LOCAL_ENABLED & info.flags).(bool);
    if enabled != is_local_enabled
    then compute_enabled_iterative(make_ref(entity));
}

get_name :: (entity : Entity) -> string {
    return get_info(entity).name;
}

set_name :: (entity : Entity, name : string) {
    get_info(entity).name = copy_string(name);
}

get_parent :: (entity : Entity) -> Entity {
    info := get_info(entity);
    return resolve_ref(*info.parent);
}

get_children :: (entity : Entity) -> [] Entity_Ref {
    info := get_info(entity);
    return info.children;
}

set_parent :: (entity : Entity, parent : Entity) {

    info := get_info(entity);
    current_parent := resolve_ref(*info.parent);
    
    if is_not_destroyed(current_parent) {
        
        remove_child :: (entity : Entity, child : Entity) {    
            info := get_info(entity);
            index := -1;
            found := false;
            for info.children { 
                if child == it.entity then { 
                    found = true;
                    index = it_index;
                    break; 
                }
            }
            if found then array_unordered_remove_by_index(*info.children, index);
            compute_enabled_iterative(make_ref(child));
            //#TODO_asuarez Remove the Node_Component if it is not being used.
        }
        
        remove_child(current_parent, entity);
    }

    if is_not_destroyed(parent) {

        info.parent = make_ref(parent);
        add_child :: (entity : Entity, child : Entity) {

            info := get_info(entity);

            for ref : info.children {
                current_child := resolve_ref(*ref);
                if current_child == child 
                then return;
            }

            child_ref := make_ref(child);
            array_add(*info.children, child_ref);
            compute_enabled_iterative(child_ref);
        }

        add_child(parent, entity);

    } else {
        info.parent = .{};
    }
   
}

deinit_entity_storage :: () {
    EntityStorageContext();

    for 0..entity_count()-1 {
        e := get_entity_at(it);
        if is_not_destroyed(e)
        then destroy_entity(e);
    }

    clean_destroyed_entities();
    deinit_generated_component_arenas(*state.generated_component_arenas);
    deinit(*state.info_arena);
    deinit(*state.free_queue);
    deinit(*state.uuid_table);
    array_reset(*state.component_arenas);
    array_reset(*state.to_clean);
    state.* = .{};
}

get_component_arena :: ($T : Type) -> *Component_Arena(T) {
    EntityStorageContext();
    #if T == Entity_Info
    then return *state.info_arena;
    else return get_generated_component_arena(*state.generated_component_arenas, T);
}

get_component_arena_base :: (t : Type) -> *Component_Arena_Base {
    EntityStorageContext();
    if t == Entity_Info
    then return *state.info_arena;
    else return get_generated_component_arena_base(*state.generated_component_arenas, t);
}

entity_count :: inline () -> s64 {
    EntityStorageContext();
    return state.count;
}

get_info :: (entity : Entity) -> *Entity_Info {
    return get_component(Entity_Info, entity);
}

is_not_cleaned :: inline (entity : Entity) -> bool {
    EntityStorageContext();
    return test(*state.info_arena.entities, entity);
}

is_not_destroyed :: (entity : Entity) -> bool {
    if !is_not_cleaned(entity)
    then return false;
    info := get_info(entity);
    return !(info.flags & .PENDING_CLEAN).(bool);
}

create_entity :: () -> Entity {

    create_raw_entity :: () -> Entity {
        EntityStorageContext();
        assert(state.count < MAX_ENTITIES);
        entity := pop_front(*state.free_queue);
        state.count += 1;
        return entity;
    }

    entity := create_raw_entity();
    add_info(entity);
    return entity;
}

destroy_entity :: (entity : Entity) {

    destroy_raw_entity :: (entity : Entity) {
        EntityStorageContext();
        array_add(*state.to_clean, entity);
    }
    
    try_mark_for_clean :: (entity : Entity) -> success : bool {
        if is_not_cleaned(entity) {
            info := get_info(entity);
            info.flags |= .PENDING_CLEAN;
            return true;
        }
        return false;
    }

    mark_for_clean_recursive :: (entity : Entity) {
        success := try_mark_for_clean(entity);
        if !success
        then return;
        children := get_children(entity);
        for children {
            mark_for_clean_recursive(resolve_ref(*it));
        }
    }

    destroy_raw_entity(entity);
    mark_for_clean_recursive(entity);
}

get_entity_at :: (index : s64) -> Entity {
    EntityStorageContext();
    assert(index < state.count);
    return state.info_arena.entities.dense.data[index];
}

make_ref :: (entity : Entity, uuid : u64 = 0) -> Entity_Ref {
    EntityStorageContext();
    assert(is_not_destroyed(entity));
    info := get_info(entity);
    if info.uuid != 0 {
        assert(table_contains(*state.uuid_table, info.uuid));
        return .{ entity = entity, uuid = info.uuid };
    }
    if !uuid {
        info.uuid = random_get();
    } else {
        info.uuid = uuid;
    }
    
    table_add(*state.uuid_table, info.uuid, entity);
    return .{ entity = entity, uuid = info.uuid };
}

resolve_ref :: (ref : *Entity_Ref) -> Entity {
    EntityStorageContext();

    entity, success := table_find(*state.uuid_table, ref.uuid);
    if !success 
    then return NULL_ENTITY;
    ref.entity = entity;
    return entity; 
}

immediate_destroy_entity :: (entity : Entity) {
    
    rem_all_components :: (entity : Entity) {
        EntityStorageContext();
        for < state.component_arenas {
            if it.has(entity)
            then it.rem(entity);
        }
    }

    immediate_destroy_raw_entity :: (entity : Entity) {
        // Decrement the count and back to the queue.
        EntityStorageContext();
        state.count -= 1;
        push_back(*state.free_queue, entity);
    }

    set_parent(entity, NULL_ENTITY);
    children := array_copy(get_children(entity) ,,temp);
    
    rem_all_components(entity);
    rem_info(entity);
    immediate_destroy_raw_entity(entity);

    for children {
        immediate_destroy_entity(resolve_ref(*it));
    }
}

slz_single_entity :: (entity : Entity) -> string {
    
    EntityStorageContext();
    assert(is_not_cleaned(entity));
    
    entity_section :: (builder : *String_Builder, entity : Entity) {
        ref := make_ref(entity);
        print_to_builder(builder, "\n@Entity(%)\n", ref.uuid);
    }

    component_section :: (builder : *String_Builder, entity : Entity, arena : *Component_Arena_Base) {
        print_to_builder(builder, "\n@Component(%)\n", arena.type.name);
        print_to_builder(builder, "%\n", arena.slz(entity));
    }

    builder : String_Builder;
    
    entity_section(*builder, entity);
    component_section(*builder, entity, *state.info_arena);

    for state.component_arenas {
        if !it.has(entity)
        then continue;
        component_section(*builder, entity, it);
    }

    return builder_to_string(*builder);
}

slz_entity :: (builder : *String_Builder, entity : Entity) {
    append(builder, slz_single_entity(entity));
    children := get_children(entity);
    if !children.count
    then return;
    for children {
        child := resolve_ref(*it);
        if is_not_destroyed(child)
        then slz_entity(builder, child);
    }
    return;
}

dlz_entity :: (s : string) -> Entity {
    EntityStorageContext();
    
    first_entity : Entity = NULL_ENTITY;
    entity       : Entity = NULL_ENTITY;
    builder      : String_Builder;
    arena        : *Component_Arena_Base;
    
    while 1 {
        line, found := consume_next_line(*s);
        line = trim(line);

        // First create the entity.
        // #TODO_asuarez check if an entity was created and decide if it is a children entity.

        if begins_with(line, "@Entity(") {

            if arena != null {
                arena.dlz(entity, builder_to_string(*builder ,,temp));
                arena = null;
                reset(*builder);
            }            
            
            expected_uuid := slice(line, 8, line.count-9 ,,temp);
            uuid, success := string_to_int(expected_uuid, 10, u64);
            assert(success && uuid != 0);
            entity = create_entity();
            if first_entity == NULL_ENTITY
            then first_entity = entity;
            make_ref(entity, uuid);
            continue;
        }

        if begins_with(line, "@Component(") || !found {

            // Check if we have been storing component lines.
            // If it is the case we add it to the entity and reset the builder.
            
            if arena != null {
                arena.dlz(entity, builder_to_string(*builder ,,temp));
                arena = null;
                reset(*builder);
            }

            // If it is the end of the line we're done.
            if !found
            then return first_entity;

            // If not, store next the component type.
            assert(entity != NULL_ENTITY);
            expected_component_type := slice(line, 11, line.count-12);
            if expected_component_type == "Entity_Info" {
                arena = state.info_arena;
            } else {
                for state.component_arenas {
                    if it.type.name != expected_component_type
                    then continue;
                    arena = it;
                    break;
                }
            }
            
            assert(arena != null);
            continue;
        }

        // Append component line to the builder.
        if entity != NULL_ENTITY && arena
        then append(*builder, line);
    }

    return NULL_ENTITY;
}

has_component :: ($T : Type, entity : Entity) -> bool {
    assert(is_not_cleaned(entity));
    component_arena := get_component_arena(T);
    assert(component_arena != null);
    return test(*component_arena.entities, entity);
}

get_component :: ($T : Type, entity : Entity) -> *T {
    assert(is_not_cleaned(entity));
    component_arena := get_component_arena(T);
    assert(component_arena != null);
    assert(has_component(T, entity));
    index := search(*component_arena.entities, entity);
    return *component_arena.components[index];
}

add_component :: ($T : Type, entity : Entity) -> *T {
    #if T == Entity_Info 
    then return null;
    assert(is_not_cleaned(entity));
    assert(!has_component(T, entity));
    using component_arena := get_component_arena(T);
    assert(count < capacity);
    count += 1;
    index := insert_id(*entities, entity);
    component := *components[index]; 
    if add_cbk_fn != null
    then call_add_cbk(add_cbk_fn, entity, component);
    return component;    
}

add_component_with_data :: (d : $T, entity : Entity) -> *T {
    #if T == Entity_Info 
    then return null;
    assert(is_not_cleaned(entity));
    assert(!has_component(T, entity));
    using component_arena := get_component_arena(T);
    assert(count < capacity);
    count += 1;
    index := insert_id(*entities, entity);
    component := *components[index];
    call_cpy_cbk(cpy_cbk_fn, entity, component, *d);
    if add_cbk_fn != null
    then call_add_cbk(add_cbk_fn, entity, component);
    return component;
}

rem_component :: ($T : Type, entity : Entity) {
    #if T == Entity_Info 
    then return;
    assert(has_component(T, entity));
    using component_arena := get_component_arena(T);
    if rem_cbk_fn != null
    then call_rem_cbk(rem_cbk_fn, entity, get_component(T, entity));
    count -= 1;
    deleted, last := remove_id(*entities, entity);
    if deleted != last {
        components[deleted] = components[last];
        components[last] = .{}; 
    } else {
        components[deleted] = .{};
    }
}

slz_component :: ($T : Type, entity : Entity) -> string {
    EntityStorageContext();
    c := get_component(T, entity);
    return json_write_string(c);
}

dlz_component :: ($T : Type, entity : Entity, s : string) -> *T {
    success, parsed_data := json_parse_string(s, T ,,temp);
    
    if has_component(T, entity) {
        using arena := get_component_arena(T);
        component := get_component(T, entity);
        call_cpy_cbk(cpy_cbk_fn, entity, component, *parsed_data);
        return component;
    } 

    #if T == Entity_Info
    then return add_info(entity, parsed_data); // @Note: This should not happen....
    else return add_component_with_data(parsed_data, entity);  
}

#if EDIT_MODE {
    drw_component :: ($T : Type, entity : Entity) {
        EntityStorageContext();
        c := get_component(T, entity);
        info := type_info(T);
        editor_draw_property(null, c, info);
        compute_enabled_iterative(make_ref(entity));
    }
}

clean_destroyed_entities :: () {
    EntityStorageContext();
    for entity : state.to_clean {
        immediate_destroy_entity(entity);
    }
    array_reset(*state.to_clean);
}

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
        
        // If the entity is destroyed or disabled we don't care.
        if !is_not_destroyed(entity) || !is_enabled(entity)
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

#scope_file

// Just add the info component if the entity is created.
add_info :: (entity : Entity, info := Entity_Info.{}) -> *Entity_Info {
    EntityStorageContext();
    using state.info_arena;
    assert(count < capacity && !is_not_cleaned(entity));
    count += 1;
    index := insert_id(*entities, entity);
    info_ptr := *components[index]; 
    #if EDIT_MODE info_ptr.id = entity;
    call_cpy_cbk(cpy_cbk_fn, entity, info_ptr, *info);
    return info_ptr;
}

// Just rem the info component if the entity is destroyed.
rem_info :: (entity : Entity) {
    EntityStorageContext();
    assert(is_not_cleaned(entity));
    info := get_info(entity);

    if info.uuid != 0 && table_contains(*state.uuid_table, info.uuid)
    then table_remove(*state.uuid_table, info.uuid);

    array_reset(*info.children);
    if info.name.count
    then free(info.name);

    using state.info_arena;
    count -= 1;
    deleted, last := remove_id(*entities, entity);
    if deleted != last {
        components[deleted] = components[last];
        components[last] = .{}; 
    } else {
        components[deleted] = .{};
    }
}

//#TODO_asuarez this is going to be a problem when we add the clone feature...
// - This procedure es being used to deserialize the entity and it is not meant for clone purposes.
// - We should create a dlz_callback and use that for dlz and keep this to for clone.
cpy_info :: (entity : Entity, d : *Entity_Info, s : *Entity_Info) {
    d.flags  = s.flags;
    d.name   = copy_string(s.name);
    d.parent = s.parent;
    if s.children.count
    then array_copy(*d.children, s.children);
}

compute_enabled_iterative :: (ref : Entity_Ref) { 
    stack : [..] Entity_Ref;
    array_add(*stack, ref ,,temp);

    while stack.count > 0 {
        current_ref := pop(*stack);
        current_entity := resolve_ref(*current_ref);
        current_entity_info := get_info(current_entity);
        parent_ref := current_entity_info.parent;

        parent := resolve_ref(*parent_ref);
        parent_enabled := ifx is_not_cleaned(parent) && is_not_destroyed(parent) then is_enabled(parent) else true;
        new_enabled := (.LOCAL_ENABLED & current_entity_info.flags).(bool) && parent_enabled;
        
        if((.ENABLED & current_entity_info.flags).(bool) != new_enabled) {
            for child : current_entity_info.children {
                array_add(*stack, child);
            } 
        }

        if new_enabled && !(.ENABLED & current_entity_info.flags) { 
            current_entity_info.flags |= .ENABLED;
        } 
        else if !new_enabled && .ENABLED & current_entity_info.flags { 
            current_entity_info.flags = current_entity_info.flags &~ .ENABLED;
        }
    }
}