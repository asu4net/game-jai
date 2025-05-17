// @Info:
// @InitOrder Range here: 0 - 10000

// @Note:

// If you want initialize a component before those, you can use negative
// numbers, since the native components start at @InitOrder(0).  

// Even if, for some reason, you don't want to use this components, the 
// entity storage calls procedures from this file, so if you remove it 
// it won't compile. This does not mean the entities add these components
// by default, as occurs with the Entity_Info. So if you want to save some
// memory, just set the @Max note to whatever you want. (I think 0 is not
// an option at this point, I will eventually fix that).

// Alex - 03/05/2025

// ------------------------------------------------

Node_Component :: struct @Component @EditorIgnore @InitOrder(0) @Max(MAX_ENTITIES) {
    parent   : Entity_Ref;
    children : [..] Entity_Ref;
}

on_rem_node_component :: (entity : Entity, cmp : *Node_Component) {
    array_reset(*cmp.children);
} @RemoveComponentCallback

get_parent :: (entity : Entity) -> Entity {
    if !has_component(Node_Component, entity)
    then return NULL_ENTITY;
    node := get_component(Node_Component, entity);
    return resolve_ref(*node.parent);
}

get_children :: (entity : Entity) -> [] Entity_Ref {
    if !has_component(Node_Component, entity)
    then return .{};
    node := get_component(Node_Component, entity);
    return node.children;
}

set_parent :: (entity : Entity, parent : Entity) {

    entity_node := ifx has_component(Node_Component, entity) 
        then get_component(Node_Component, entity) 
        else add_component(Node_Component, entity);
    
    current_parent := resolve_ref(*entity_node.parent);
    
    if is_not_destroyed(current_parent) {
        
        remove_child :: (entity : Entity, child : Entity) {    
            entity_node := get_component(Node_Component, entity);
            index := -1;
            found := false;
            for entity_node.children { 
                if child == it.entity then { 
                    found = true;
                    index = it_index;
                    break; 
                }
            }
            if found then array_unordered_remove_by_index(*entity_node.children, index);
            compute_enabled_iterative(make_ref(child));
            //#TODO_asuarez Remove the Node_Component if it is not being used.
        }
        
        remove_child(current_parent, entity);
    }

    if is_not_destroyed(parent) {

        entity_node.parent = make_ref(parent);
        add_child :: (entity : Entity, child : Entity) {
        
            entity_node := ifx has_component(Node_Component, entity) 
                then get_component(Node_Component, entity) 
                else add_component(Node_Component, entity);

            if !has_component(Node_Component,  child)
            then add_component(Node_Component, child);

            for ref : entity_node.children {
                current_child := resolve_ref(*ref);
                if current_child == child 
                then return;
            }

            child_ref := make_ref(child);
            array_add(*entity_node.children, child_ref);
            compute_enabled_iterative(child_ref);
        }

        add_child(parent, entity);

    } else {
        entity_node.parent = .{};
    }
   
}

compute_enabled_iterative :: (ref : Entity_Ref) { 
    stack : [..] Entity_Ref;
    array_add(*stack, ref ,,temp);

    while stack.count > 0 {
        current_ref := pop(*stack);
        current_entity := resolve_ref(*current_ref);
        current_entity_node := get_component(Node_Component, current_entity);
        parent_ref := current_entity_node.parent;

        parent := resolve_ref(*parent_ref);
        parent_enabled := ifx is_not_cleaned(parent) && is_not_destroyed(parent) then is_enabled(parent) else true;
        current_entity_info := get_info(current_entity);
        new_enabled := (.LOCAL_ENABLED & current_entity_info.flags).(bool) && parent_enabled;
        
        if((.ENABLED & current_entity_info.flags).(bool) != new_enabled) {
            for child : current_entity_node.children {
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

Prefab_Component :: struct @Component @EditorIgnore @InitOrder(100) @Max(MAX_ENTITIES) {
    #if EDIT_MODE {
        
    }
}

// ------------------------------------------------

Tag_Component :: struct @Component @EditorIgnore @InitOrder(200) @Max(MAX_ENTITIES) {
    text : string;
}

on_copy_tag_component :: (e : Entity, dst : *Tag_Component, src : *Tag_Component) {
    dst.* = src.*;
    dst.text = copy_string(src.text);
} @CopyComponentCallback

on_remove_tag_component :: (e : Entity, cmp : *Tag_Component) {
    free(cmp.text);
} @RemoveComponentCallback

// ------------------------------------------------

Transform2D_Component :: struct @Component @InitOrder(300) @Max(MAX_ENTITIES) {
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