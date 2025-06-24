FlipBookKey :: struct {
    name := "";
    time : f32;
}

MAX_FLIPBOOK_KEYS :: 10;

FlipBook_Component :: struct @Component @InitOrder(100) @Max(MAX_ENTITIES) {
    keys        : [MAX_FLIPBOOK_KEYS] FlipBookKey;
    key_count   : u32;
    duration    : f32;
    time        : f32;
    current_key : u32;
    playing     : bool;
    loop        : bool;
}

is_flipbook :: (entity : Entity) -> bool {
    //assert(entity_valid({entity.id}));
    return has_component(FlipBook_Component, entity);
}

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
