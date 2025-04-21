Component_Arena_Base :: struct {
    data      : *void;    
    count     : s64;
    capacity  : s64;
    type      : *Type_Info_Struct;
    entities  : Sparse_Set;

    // Generic procs.
    get : (entity : Entity) -> *void;
    add : (entity : Entity) -> *void;
    has : (entity : Entity) -> bool;
    rem : (entity : Entity);
    slz : (entity : Entity) -> string;
#if EDITOR {
    drw : (entity : Entity);
}

    // Callbacks.
    CPY_CBK :: #type (entity : Entity, dst : *void, src : *void);
    REM_CBK :: #type (entity : Entity, component : *void);
    ADD_CBK :: #type (entity : Entity, component : *void);   
    
    add_cbk : ADD_CBK;
    rem_cbk : REM_CBK;
    cpy_cbk : CPY_CBK;   
}

Component_Arena :: struct($T : Type) {
    #as using base : Component_Arena_Base;
    components : []T;
}

init :: (using arena : *Component_Arena($T), cap : s64, 
cpy_proc : Component_Arena_Base.CPY_CBK = null, 
rem_proc : Component_Arena_Base.REM_CBK = null, 
add_proc : Component_Arena_Base.ADD_CBK = null
) 
{
    array := NewArray(cap, T);
    data = array.data;
    capacity = cap;
    components.data = data;
    components.count = cap;
    type = type_info(T);
    init(*entities, xx cap);
    
    get = (entity : Entity) -> *void {
        return get_component(T, entity);
    }
    add = (entity : Entity) -> *void {
        return add_component(T, entity);
    }
    has = (entity : Entity) -> bool {
        return has_component(T, entity);
    }
    rem = (entity : Entity) {
        rem_component(T, entity);
    }
    slz = (entity : Entity) -> string {
        return slz_component(T, entity);
    }
#if EDITOR {
    drw = (entity : Entity) {

    }
}
    cpy_cbk = ifx !cpy_proc then (entity : Entity, dst : *void, src : *void) {
        d := dst.(*T);    
        s := src.(*T);    
        d.* = s.*;
    } else cpy_proc;
}

deinit :: (using arena : *Component_Arena($T)) {
    print("deinited component arena!\n");
    free(data);
    deinit(*entities);
    arena.* = .{};
}

//---------------------------

Some_Component :: struct @Component @Max(100) {
    dummy : float;
}

Some_Other_Component :: struct @Component @Max(100) {
    dummy : float;
}

//---------------------------

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

Entity_Storage :: struct {
    using generated_component_arenas : Generated_Component_Arenas;
    
    component_arenas : [..] *Component_Arena_Base;
    
    free_queue  : Queue(Entity);
    to_clean    : [..] Entity;
    count       : s64;
    uuid_seed   : u64;
    uuid_table  : Table(u64, Entity);
    initialized : bool;
}

Info_Component :: struct @Component @Max(MAX_ENTITIES) {
    flags : Entity_Flag = .LOCAL_ENABLED | .ENABLED;
    uuid  : u64;
}

Tag_Component :: struct @Component @Max(MAX_ENTITIES) {
    text : string;
}

on_copy_tag_component :: (e : Entity, d : *void, s : *void) {
    dst := d.(*Tag_Component); src := s.(*Tag_Component);
    dst.text = copy_string(src.text);
} @CopyComponentCallback(Tag_Component)

on_remove_tag_component :: (e : Entity, c : *void) {
    component := c.(*Tag_Component);
    free(component.text);
} @RemoveComponentCallback(Tag_Component)

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
    
    init_generated_component_arenas(*state.generated_component_arenas, *state.component_arenas);
    state.uuid_seed = random_get();
    init(*state.free_queue, MAX_ENTITIES);
    
    for 0..MAX_ENTITIES {
        push_back(*state.free_queue, xx it);
    }
}

deinit_entity_storage :: () {
    EntityStorageContext();
    for 0..entity_count()-1 {
        immediate_destroy_entity(get_entity_at(it));
    }
    deinit_generated_component_arenas(*state.generated_component_arenas);
    deinit(*state.free_queue);
    array_reset(*state.component_arenas);
    array_reset(*state.to_clean);
    state.* = .{};
}

get_component_arena :: ($T : Type) -> *Component_Arena(T) {
    EntityStorageContext();
    return get_generated_component_arena(*state.generated_component_arenas, T);
}

entity_count :: inline () -> s64 {
    EntityStorageContext();
    return state.count;
}

get_entity_at :: (index : s64) -> Entity {
    EntityStorageContext();
    assert(index < state.count);
    info_arena := get_component_arena(Info_Component);
    return info_arena.entities.dense.data[index];
}

create_entity :: () -> Entity {
    EntityStorageContext();
    assert(state.count < MAX_ENTITIES);
    entity := pop_front(*state.free_queue);
    state.count += 1;
    info := add_component(Info_Component, entity, unsafe = true);
    return entity;
}

destroy_entity :: (entity : Entity) {
    EntityStorageContext();
    assert(is_not_destroyed(entity));
    info := get_component(Info_Component, entity);
    info.flags |= .PENDING_CLEAN;
    array_add(*state.to_clean, entity);
}

immediate_destroy_entity :: (entity : Entity) {
    EntityStorageContext();
    assert(is_not_cleaned(entity));
    rem_component(Info_Component, entity, unsafe = true);
    for state.component_arenas {
        if it.has(entity)
        then it.rem(entity);
    }
    push_back(*state.free_queue, entity);
}

is_not_cleaned :: inline (entity : Entity) -> bool {
    info_arena := get_component_arena(Info_Component);
    assert(info_arena != null);
    return test(*info_arena.entities, entity);
}

is_not_destroyed :: (entity : Entity) -> bool {
    if !is_not_cleaned(entity)
    then return false;
    
    info := get_component(Info_Component, entity);
    return !(info.flags & .PENDING_CLEAN).(bool);
}

make_entity_ref :: (entity : Entity) -> Entity_Ref {
    EntityStorageContext();
    assert(is_not_destroyed(entity));
    info := get_component(Info_Component, entity);
    if info.uuid != 0 {
        assert(table_contains(*state.uuid_table, info.uuid));
        return .{ entity = entity, uuid = info.uuid };
    }
    random_seed(state.uuid_seed);
    info.uuid = random_get();
    table_add(*state.uuid_table, info.uuid, entity);
    return .{ entity = entity, uuid = info.uuid };
}

resolve_entity_ref :: (ref : *Entity_Ref) -> Entity {
    EntityStorageContext();
    assert(ref.uuid != 0);
    entity, success := table_find(*state.uuid_table, ref.uuid);
    if !success 
    then return NULL_ENTITY;
    ref.entity = entity;
    return entity; 
} 

serialize_entity :: (entity : Entity) -> string {
    EntityStorageContext();
    assert(is_not_destroyed(entity));
    builder : String_Builder;
    append(*builder, "\n@Entity\n");
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

has_component :: ($T : Type, entity : Entity) -> bool {
    component_arena := get_component_arena(T);
    assert(component_arena != null);
    return test(*component_arena.entities, entity);
}

get_component :: ($T : Type, entity : Entity) -> *T {
    component_arena := get_component_arena(T);
    assert(component_arena != null);
    assert(has_component(T, entity));
    index := search(*component_arena.entities, entity);
    return *component_arena.components[index];
}

add_component :: ($T : Type, entity : Entity, unsafe := false) -> *T {
    if !unsafe 
    then assert(has_component(Info_Component, entity));
    assert(!has_component(T, entity));
    using component_arena := get_component_arena(T);
    assert(count < capacity);
    count += 1;
    index := insert_id(*entities, entity);
    return *components[index];    
}

rem_component :: ($T : Type, entity : Entity, unsafe := false) {
    assert(has_component(T, entity));
    if !unsafe
    then assert(T != Info_Component);
    using component_arena := get_component_arena(T);
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

clean_destroyed_entities :: () {
    EntityStorageContext();
    for entity : state.to_clean {
        immediate_destroy_entity(entity);
    }
    array_reset(*state.to_clean);
}