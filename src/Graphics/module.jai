//TODO:
/*
- Add gui_scope, game_scope functions to switch primitives between gui and normal.
    - for this use the camera type
- we have to decide things about gui
    - the quad coordinate system:
        - specify a fake resolution
        - we should transform from our fake res to the real one.
- texture options for sprite_sheet (maybe could be a struct??)
- remove draw_gui_quad and make the gui version of the text
- Optimize the 2d version of make_transform
- Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).
- Intentar generalizar un poco más las llamadas de draw, convertir en función el draw header
- Leer shaders de ficheros
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Meter ImGUI
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights

Spritesheet :: struct {
    textures:   Bucket_Array(*Texture, 8);
    frames:     Bucket_Array(Animation_Frame, 64);
    animations: Bucket_Array(Animation, 64);
    sprites:    Bucket_Array(Sprite, 16);
    index: struct {
        frames:     Table(string, *Animation_Frame);
        animations: Table(string, *Animation);
        sprites:    Table(string, *Sprite);
    }
}

Animation_Frame :: struct {
    id: string;
    rect: UV_Rect;
    texture: *Texture;  @NoSerialize
}
Animation :: struct {
    id: string;
    frame_rate: int;  // in ticks per frame
    frames: [] Animation_Frame;
}
Sprite :: struct {
    id: string;
    animations: [#run enum_highest_value(Direction)+1] *Animation;  // n w s e nw sw se ne
}

*/

#scope_module

#import "Core";
#import "GL" (DUMP_GL_ERRORS = true);
#import "Math";
#import "Basic";
#import "stb_image";
#import "Hash_Table";
#import "stb_truetype";
#import "File";
#import "File_Utilities";
#import "stb_image_write";
#import "Jaison";
#import "String";

#load "constants.jai";
#load "draw_2d.jai";
#load "api.jai";
#load "buffer_object.jai";
#load "shader.jai";
#load "texture.jai";
#load "font.jai";
#load "render_camera.jai";
#load "spritesheet.jai";