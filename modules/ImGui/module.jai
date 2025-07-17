#module_parameters ();

ImVec2      :: Vector2;
ImVec4      :: Vector4;
ImColor     :: Vector4;

ImVector :: struct (T: Type) {
    Size: s32;
    Capacity: s32;
    Data: *T;
}

ImDrawCallback :: #type (parent_list: *ImDrawList, cmd: *ImDrawCmd) #c_call;

// #NOTE_asuarez If you get an error around here, it's probably because the
// bindings haven't been generated yet. Open the ImGui folder in the command prompt and type:
// jai generate.jai --backend_sdl3_opengl3.
// If the backend generation is still failing check generate.jai, maybe something is missing.

#if OS == {
    case .WINDOWS;  #load "backends/windows/windows_sdl3_opengl3.jai";
    case .LINUX;    #load "backends/unix_sdl3_opengl3.jai";
    case .MACOS;    #load "backends/macos/macos_sdl3_opengl3.jai";
}

#scope_module

#import "SDL3";
#import "Basic";
#import "Math";

#if OS == .WINDOWS {
    #load "windows/windows.jai";

    // Note: Check imconfig.h for a full list of compilation flags and the resulting
    // changes in features and system libraries required

    // Needed by imgui unless ImGui is compiled with IMGUI_DISABLE_WIN32_DEFAULT_CLIPBOARD_FUNCS"
    #library,system,link_always "user32";

    // Needed by imgui unless ImGui is compiled with IMGUI_DISABLE_DEFAULT_SHELL_FUNCTIONS
    #library,system,link_always "shell32";
} else {
    #load "unix.jai";
}
