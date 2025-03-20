//TODO:
/*
- Dar soporte en el renderer para pintar el sprite_sheet con draw_sprite o mover los sprite sheets a comp-time.
- Pintado de primitivas de GUI (Mirar SIMP) (Revisar funcionamiento de camara de Render)
- Leer shaders de ficheros
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Meter ImGUI
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights
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

#load "draw_2d.jai";
#load "api.jai";
#load "buffer_object.jai";
#load "primitives.jai";
#load "shader.jai";
#load "texture.jai";
#load "font.jai";
#load "render_camera.jai";
#load "spritesheet.jai";