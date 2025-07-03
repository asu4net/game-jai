#module_parameters(DUMP_ERRORS := false);

#load "constants.jai";
#load "draw2d.jai";
#load "api.jai";
#load "buffer_object.jai";
#load "shader.jai";
#load "texture.jai";
#load "font.jai";
#load "render_camera.jai";
#load "spritesheet.jai";
#load "frame_buffer.jai";
#load "math.jai";

#scope_module

#import "Jaison";
#import "File";
#import "File_Utilities";
#import "String";
#import "Hash_Table";
#import "Basic";
#import "Math";
#import "GL" (DUMP_GL_ERRORS = DUMP_ERRORS);
#import "stb_image";
#import "stb_truetype";
#import "stb_image_write";