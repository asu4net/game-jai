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
#import "Reflection";
#import "Random";
#import "Gamepad";

Window    :: #import "Window_Creation" (DUMP_GL_ERRORS = DEBUG, CLOSE_WITH_SCAPE = EDITOR);
Input     :: #import "Input";
Clipboard :: #import "Clipboard";
Unicode   :: #import "Unicode";

#if OS == .WINDOWS {
    Win32 :: #import "Windows";
}

// Vendor Modules
#import "Jaison";

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Utils
#load "utils/queue.jai";
#load "utils/sparse_set.jai";
#load "utils/time.jai";

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

#if IMGUI then {
    #load "editor/imgui_utils.jai";
}

// Entity
#load "entity/entity_storage.jai";
#load "entity/game_components.jai";
#load "entity/game_systems.jai";