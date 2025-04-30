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

    #if EDITOR then drw : (entity : Entity);

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

    #if EDITOR then drw = (entity : Entity) { drw_component(T, entity); }

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
    entity : Entity = NULL_ENTITY; @JsonIgnore
    uuid   : u64;
}

Entity_Info :: struct {
    flags : Entity_Flag = .LOCAL_ENABLED | .ENABLED;
    uuid  : u64;
}

Entity_Storage :: struct {
    using generated_component_arenas : Generated_Component_Arenas;
    
    component_arenas : [..] *Component_Arena_Base;
    
    free_queue  : Queue(Entity);
    to_clean    : [..] Entity;
    count       : s64;
    initialized : bool;
    
    // @Info: Info_Component dependant.
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
    
    init(*state.info_arena, MAX_ENTITIES, cpy_proc = null, add_proc = null, rem_proc = null);
    init_generated_component_arenas(*state.generated_component_arenas, *state.component_arenas);
    state.uuid_seed = current_time_monotonic().low;
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

deinit_entity_storage :: () {
    EntityStorageContext();

    for 0..entity_count()-1 {
        destroy_entity(get_entity_at(it));
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
    return get_generated_component_arena(*state.generated_component_arenas, T);
}

get_component_arena_base :: (t : Type) -> *Component_Arena_Base {
    EntityStorageContext();
    return get_generated_component_arena_base(*state.generated_component_arenas, t);
}

entity_count :: inline () -> s64 {
    EntityStorageContext();
    return state.count;
}

get_info :: (entity : Entity) -> *Entity_Info {
    EntityStorageContext();
    assert(is_not_cleaned(entity));
    index := search(*state.info_arena.entities, entity);
    return *state.info_arena.components[index];
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

    add_info :: (entity : Entity) -> *Entity_Info {
        EntityStorageContext();
        using state.info_arena;
        assert(count < capacity && !is_not_cleaned(entity));
        count += 1;
        index := insert_id(*entities, entity);
        return *components[index];
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
    
    assert(is_not_destroyed(entity));
    info := get_info(entity);
    info.flags |= .PENDING_CLEAN;
    destroy_raw_entity(entity);
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
        random_seed(state.uuid_seed);
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

    rem_info :: (entity : Entity) {
        EntityStorageContext();
        assert(is_not_cleaned(entity));
        info := get_info(entity);
        if info.uuid != 0 && table_contains(*state.uuid_table, info.uuid)
        then table_remove(*state.uuid_table, info.uuid);
        
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

    immediate_destroy_raw_entity :: (entity : Entity) {
        // Decrement the count and back to the queue.
        EntityStorageContext();
        state.count -= 1;
        push_back(*state.free_queue, entity);
    }

    rem_all_components(entity);
    rem_info(entity);
    immediate_destroy_raw_entity(entity);
}

serialize_entity :: (entity : Entity) -> string {
    EntityStorageContext();

    assert(is_not_cleaned(entity));
    builder : String_Builder;
    
    ref := make_ref(entity);
    append(*builder, "\n@Entity(");
    append(*builder, tprint("%", ref.uuid));
    append(*builder, ")\n");

    for state.component_arenas {
        if !it.has(entity)
        then continue;
        append(*builder, "\n@Component(");
        append(*builder, it.type.name);
        append(*builder, ")\n");
        append(*builder, it.slz(entity));
    }
    return builder_to_string(*builder);
}

deserialize_entity :: (s : string) -> Entity {
    EntityStorageContext();
    
    entity  : Entity = NULL_ENTITY;
    builder : String_Builder;
    arena   : *Component_Arena_Base;
    
    while 1 {
        line, found := consume_next_line(*s);
        line = trim(line);

        // First create the entity.
        // #TODO_asuarez check if an entity was created and decide if it is a children entity.

        if begins_with(line, "@Entity(") {
            expected_uuid := slice(line, 8, line.count-9 ,,temp);
            uuid, success := string_to_int(expected_uuid, 10, u64);
            assert(success && uuid != 0);
            entity = create_entity();
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
            then return entity;

            // If not, store next the component type.
            assert(entity != NULL_ENTITY);
            expected_component_type := slice(line, 11, line.count-12);
            for state.component_arenas {
                if it.type.name != expected_component_type
                then continue;
                arena = it;
                break;
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
    component := get_component(T, entity);
    return json_write_string(component);
}

dlz_component :: ($T : Type, entity : Entity, s : string) -> *T {
    success, parsed_data := json_parse_string(s, T ,,temp);
    
    if has_component(T, entity) {
        using arena := get_component_arena(T);
        component := get_component(T, entity);
        call_cpy_cbk(cpy_cbk_fn, entity, component, *parsed_data);
        return component;
    } 

    return add_component_with_data(parsed_data, entity);  
}

#if EDITOR {
    drw_component :: ($T : Type, entity : Entity) {
        component := get_component(T, entity);
        info := type_info(T);
        editor_draw_property(null, component, info);
    }
}

clean_destroyed_entities :: () {
    EntityStorageContext();
    for entity : state.to_clean {
        immediate_destroy_entity(entity);
    }
    array_reset(*state.to_clean);
}