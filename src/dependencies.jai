// Modules
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Compiler";
#import "String";
#import "Hash_Table";
#import "Math";
#import "File";
#import "File_Utilities";
#import "Text_File_Handler";

// Vendor Modules
#import "SDL";
#import "GL" (DUMP_GL_ERRORS = true);
#import "stb_image";
#import "stb_truetype";
#import "stb_image_write";
#import "Jaison";

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Utils
#load "utils/constants.jai";
#load "utils/math.jai";
#load "utils/queue.jai";
#load "utils/sparse_set.jai";
#load "utils/time.jai";

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

#if IMGUI then {
    #load "editor/imgui_sdl_gl.jai";
    #load "editor/imgui.jai";
}

// Entity
#load "entity/scene.jai";
#load "entity/entity.jai";
#load "entity/entity2d.jai";
#load "entity/vfx2d.jai";

//Collisions
#load "entity/collision/collision2d.jai";

// Graphics
#load "graphics/window.jai";
#load "graphics/constants.jai";
#load "graphics/draw2d.jai";
#load "graphics/api.jai";
#load "graphics/buffer_object.jai";
#load "graphics/shader.jai";
#load "graphics/texture.jai";
#load "graphics/font.jai";
#load "graphics/render_camera.jai";
#load "graphics/spritesheet.jai";