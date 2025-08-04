Component_Procs :: struct {
    // Proc signatures
    GET :: #type (Entity) -> *void;
    ADD :: #type (Entity) -> *void;
    HAS :: #type (Entity) -> bool;
    REM :: #type (Entity);
    SLZ :: #type (Entity) -> string;
    DLZ :: #type (Entity, string) -> *void;

    #if EDITOR
    DRW :: #type (Entity);
    
    // Proc pointers
    get : GET;
    add : ADD;
    has : HAS;
    rem : REM;
    slz : SLZ;
    dlz : DLZ;

    #if EDITOR
    drw : DRW;
}

init_component_procs :: (using procs: *Component_Procs, $T : Type) {
    get = (e : Entity) -> *void {
        return get_component(T, e);
    }
    add = (e : Entity) -> *void {
        return add_component(T, e);
    }
    has = (e : Entity) -> bool {
        return has_component(T, e);
    }
    rem = (e : Entity) {
        rem_component(T, e);
    }
    slz = (e : Entity) -> string {
        return slz_component(T, e);
    }
    dlz = (e: Entity, s: string) -> *void {
        return dlz_component(T, e, s);
    }
    #if EDITOR {
        drw = (e: Entity) {
            drw_component(T, e);
        }
    }
}

generic_dlz_component :: inline (t: Component_Type, e: Entity, s: string) -> *void {
    using t.procs;
    return dlz(e, s);
}

generic_slz_component :: inline (t: Component_Type, e: Entity) -> string {
    using t.procs;
    return slz(e);
}

generic_has_component :: inline (t: Component_Type, e: Entity) -> bool {
    using t.procs;
    return has(e);
}

generic_get_component :: inline (t: Component_Type, e: Entity) -> *void {
    using t.procs;
    return get(e);
}

generic_add_component :: inline (t: Component_Type, e: Entity) -> *void {
    using t.procs;
    return add(e);
}

generic_rem_component :: inline (t: Component_Type, e: Entity) {
    using t.procs;
    rem(e);
}

#if EDITOR {
    generic_drw_component :: inline (t: Component_Type, e: Entity) {
    using t.procs;
    drw(e);
}
}