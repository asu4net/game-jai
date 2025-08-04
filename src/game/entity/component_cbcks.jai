Component_Callbacks :: struct {
    // Proc caller signatures.
    CALL_ADD :: #type (*void, Entity, *void);
    CALL_CPY :: #type (*void, Entity, *void, *void);
    CALL_REM :: #type (*void, Entity, *void);

    // Proc caller pointers.
    call_add : CALL_ADD;
    call_cpy : CALL_CPY;
    call_rem : CALL_REM;

    // Proc untyped pointers. 
    // Those will be pased as the first param on the callers.
    add : *void;
    cpy : *void;
    rem : *void;
}

Component_Callback :: struct($T : Type) {
    ADD :: #type (Entity, *T);
    CPY :: #type (Entity, *T, *T);
    REM :: #type (Entity, *T);
}

call_add_component_callback :: inline (t: Component_Type, e : Entity, c : *void) {
    using t.cbkcs;
    if add != null
    then call_add(add, e, c);
}

call_rem_component_callback :: inline (t: Component_Type, e : Entity, c : *void) {
    using t.cbkcs;
    if rem != null
    then call_rem(rem, e, c);      
}

call_cpy_component_callback :: inline (t: Component_Type, e : Entity, s : *void, d : *void) {
    using t.cbkcs;
    assert(call_cpy != null);
    call_cpy(cpy, e, s, d);
}

set_add_component_callback :: inline (t: *Component_Type, $T : Type, cbck : Component_Callback(T).ADD) {
    using t.cbkcs;
    call_add = (p_proc : *void, e : Entity, p_cmp : *void) {
        proc := p_proc.(Component_Callback(T).ADD);
        cmp  := p_cmp.(*T);
        proc(e, cmp);
    }
    add = xx cbck;
}

set_rem_component_callback :: inline (t: *Component_Type, $T : Type, cbck : Component_Callback(T).REM) {
    using t.cbkcs;
    call_rem = (p_proc : *void, e : Entity, p_cmp : *void) {
        proc := p_proc.(Component_Callback(T).REM);
        cmp  := p_cmp.(*T);
        proc(e, cmp);
    }
    rem = xx cbck;
}

set_cpy_component_callback_default :: inline (t: *Component_Type, $T : Type) {
    using t.cbkcs;
    
    call_cpy = (p_proc : *void, e : Entity, p_dst : *void, p_src : *void) {
        dst := p_dst.(*T);
        src := p_src.(*T);
        dst.* = src.*;
    }
}

set_cpy_component_callback :: inline (t: *Component_Type, $T : Type, cbck : Component_Callback(T).CPY) {
    using t.cbkcs;
    
    call_cpy = (p_proc : *void, e : Entity, p_dst : *void, p_src : *void) {
        proc := p_proc.(Component_Callback(T).CPY);
        dst := p_dst.(*T);
        src := p_src.(*T);
        proc(e, dst, src);
    }
    cpy = xx cbck;
}