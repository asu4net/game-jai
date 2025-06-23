#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Hash_Table";
#import "File";

#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES);

Graphics :: #import "Graphics" (DUMP_ERRORS = DEBUG);
Time     :: #import "Time";
Window   :: #import "Window_Creation" (DUMP_GL_ERRORS = DEBUG, CLOSE_WITH_SCAPE = EDITOR);
Input    :: #import "Input";

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

#load "game.jai";
#load "utils.jai";

#load "systems/core/2d_entities.jai";

#load "components/game/keyboard_movement.jai";
#load "components/core/2d_movement.jai";
#load "components/core/2d_transform.jai";
#load "components/core/blink.jai";
#load "components/core/sprite.jai";
#load "components/core/text.jai";