// Modules
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";

Input :: #import "Input";
// Vendor Modules

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

// Entity
#load "entity/entity_storage.jai";
#load "entity/game_components.jai";
#load "entity/game_systems.jai";