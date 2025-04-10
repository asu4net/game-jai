Entity2D :: struct {
    #as using entity : Entity;
    using transform : Transform2D;
    sprite : Sprite;
    vfx : VFX2D;
}

#add_context entities2d : Entities2D;

Entities2D :: struct {
    scene : Scene(Entity2D);
    sheet : Spritesheet;
}

copy_entity2d :: (dst : *Entity, src : *Entity) {
    s_dst := dst.(*Entity2D);
    s_src := src.(*Entity2D);
    base_entity := s_dst.entity;
    s_dst.* = s_src.*;
    s_dst.entity = base_entity;
}

init_entities2d :: () {
    using context.entities2d;
    init(*sheet);
    init(*scene, xx Scenes.ENTITIES_2D, copy_proc = copy_entity2d);
}

deinit_entities2d :: () {
    using context.entities2d;
    deinit(*sheet);
    deinit(*scene);
    context.entities2d = .{};
}

draw_entities2d :: () {
    using context.entities2d;
    for i : 1..scene.count {
        e := *scene.entities[i];
        if should_update(e) {
             update_vfx(*e.vfx, *e.sprite.tint);
             draw_sprite(*e.transform, *e.sprite);
        }
    }
}