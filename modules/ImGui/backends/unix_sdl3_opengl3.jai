//
// This file was auto-generated using the following command:
//
// jai generate.jai - -backend_sdl3_opengl3
//



// Follow "Getting Started" link and check examples/ folder to learn about using backends!
ImplSDL3_InitForOpenGL :: (window: *SDL_Window, sdl_gl_context: *void) -> bool #foreign imgui_sdl3_opengl3 "_Z28ImGui_ImplSDL3_InitForOpenGLP10SDL_WindowPv";
ImplSDL3_InitForVulkan :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "_Z28ImGui_ImplSDL3_InitForVulkanP10SDL_Window";
ImplSDL3_InitForD3D :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "_Z25ImGui_ImplSDL3_InitForD3DP10SDL_Window";
ImplSDL3_InitForMetal :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "_Z27ImGui_ImplSDL3_InitForMetalP10SDL_Window";
ImplSDL3_InitForSDLRenderer :: (window: *SDL_Window, renderer: *SDL_Renderer) -> bool #foreign imgui_sdl3_opengl3 "_Z33ImGui_ImplSDL3_InitForSDLRendererP10SDL_WindowP12SDL_Renderer";
ImplSDL3_InitForSDLGPU :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "_Z28ImGui_ImplSDL3_InitForSDLGPUP10SDL_Window";
ImplSDL3_InitForOther :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "_Z27ImGui_ImplSDL3_InitForOtherP10SDL_Window";
ImplSDL3_Shutdown :: () -> void #foreign imgui_sdl3_opengl3 "_Z23ImGui_ImplSDL3_Shutdownv";
ImplSDL3_NewFrame :: () -> void #foreign imgui_sdl3_opengl3 "_Z23ImGui_ImplSDL3_NewFramev";
ImplSDL3_ProcessEvent :: (event: *SDL_Event) -> bool #foreign imgui_sdl3_opengl3 "_Z27ImGui_ImplSDL3_ProcessEventPK9SDL_Event";

// Gamepad selection automatically starts in AutoFirst mode, picking first available SDL_Gamepad. You may override this.
// When using manual mode, caller is responsible for opening/closing gamepad.
ImplSDL3_GamepadMode :: enum u32 {
    AutoFirst :: 0;
    AutoAll   :: 1;
    Manual    :: 2;
    ImGui_ImplSDL3_GamepadMode_AutoFirst :: AutoFirst;
    ImGui_ImplSDL3_GamepadMode_AutoAll   :: AutoAll;
    ImGui_ImplSDL3_GamepadMode_Manual    :: Manual;
}
ImplSDL3_SetGamepadMode :: (mode: ImplSDL3_GamepadMode, manual_gamepads_array: **SDL_Gamepad = null, manual_gamepads_count: s32 = -1) -> void #foreign imgui_sdl3_opengl3 "_Z29ImGui_ImplSDL3_SetGamepadMode26ImGui_ImplSDL3_GamepadModePP11SDL_Gamepadi";

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
ImplOpenGL3_Init :: (glsl_version: *u8 = null) -> bool #foreign imgui_sdl3_opengl3 "_Z22ImGui_ImplOpenGL3_InitPKc";
ImplOpenGL3_Shutdown :: () -> void #foreign imgui_sdl3_opengl3 "_Z26ImGui_ImplOpenGL3_Shutdownv";
ImplOpenGL3_NewFrame :: () -> void #foreign imgui_sdl3_opengl3 "_Z26ImGui_ImplOpenGL3_NewFramev";
ImplOpenGL3_RenderDrawData :: (draw_data: *ImDrawData) -> void #foreign imgui_sdl3_opengl3 "_Z32ImGui_ImplOpenGL3_RenderDrawDataP10ImDrawData";

// (Optional) Called by Init/NewFrame/Shutdown
ImplOpenGL3_CreateFontsTexture :: () -> bool #foreign imgui_sdl3_opengl3 "_Z36ImGui_ImplOpenGL3_CreateFontsTexturev";
ImplOpenGL3_DestroyFontsTexture :: () -> void #foreign imgui_sdl3_opengl3 "_Z37ImGui_ImplOpenGL3_DestroyFontsTexturev";
ImplOpenGL3_CreateDeviceObjects :: () -> bool #foreign imgui_sdl3_opengl3 "_Z37ImGui_ImplOpenGL3_CreateDeviceObjectsv";
ImplOpenGL3_DestroyDeviceObjects :: () -> void #foreign imgui_sdl3_opengl3 "_Z38ImGui_ImplOpenGL3_DestroyDeviceObjectsv";

#scope_file

#if OS == .MACOS imgui_sdl3_opengl3 :: #library,no_dll "macos/ImGui_sdl3_opengl3";
#if OS == .LINUX imgui_sdl3_opengl3 :: #library,no_dll "linux/ImGui_sdl3_opengl3";
