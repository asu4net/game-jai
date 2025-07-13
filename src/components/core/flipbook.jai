FlipBookKey :: struct {
    name := "";
    time : f32;
}

FlipBook_Component :: struct @Component @InitOrder(100) @Max(MAX_ENTITIES) {
    keys            : [..] FlipBookKey;
    key_count       : u32;
    duration        : f32;
    time            : f32;
    current_key     : u32;
    playing         : bool;
    loop            : bool;
    adjust_duration : bool;
}

on_copy_flipbook_component :: (e : Entity, dst : *FlipBook_Component, src : *FlipBook_Component) {
    dst.* = src.*;
    
    dst.keys.data  = null;
    dst.keys.count = 0;
    dst.keys.allocated = 0;

    for src.keys {
        array_add(*dst.keys, .{ 
            name = copy_string(it.name),
            time = it.time,
        });
    }
} @CopyComponentCallback

on_remove_sprite_component :: (e : Entity, cmp : *FlipBook_Component) {
    for cmp.keys free(it.name);
    array_reset(*cmp.keys);
} @RemoveComponentCallback

flipbook_create :: (flipbook : *FlipBook_Component, duration : f32 = 1.0, loop := false, items : []string) {
    flipbook.duration = duration;
    flipbook.loop = loop;

    i := 0;
    
    for item : items {
        flipbook.keys[i].name = item;
        flipbook.key_count += 1;
        i+=1;
    }
    flipbook_adjust_to_duration(flipbook);
}

flipbook_adjust_to_duration :: (flipbook : *FlipBook_Component) {
    using flipbook;

    if key_count == 0 || duration <= 0 then return;
    
    if key_count == 1 {
        keys[0].time = duration;
        return;
    }

    key_duration := duration / cast(f32) (key_count);
    acc_time : f32;

    for i : 0..key_count-1 {
        acc_time += key_duration;
        keys[i].time = acc_time;
    }
}

update_flipbook_entity :: (entity : Entity) {

    using flipbook := get_component(FlipBook_Component, entity);
    using sprite := get_component(Sprite_Component, entity);

    if key_count > keys.count {
        array_resize(*keys, key_count);
    }

    if adjust_duration {
        flipbook_adjust_to_duration(flipbook);
        adjust_duration = false;
    }
    if playing && key_count != 0 {
        time += delta_seconds();
        key := keys[current_key];
        if time >= key.time {
            current_key += 1;
            if current_key == key_count {
                time = 0;
                current_key = 0;
                if !loop then playing = false;
            }
        }
        item = key.name;
    }
}