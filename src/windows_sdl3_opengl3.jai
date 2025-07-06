//
// This file was auto-generated using the following command:
//
// jai generate.jai - -backend_sdl3_opengl3
//



// Follow "Getting Started" link and check examples/ folder to learn about using backends!
ImplSDL3_InitForOpenGL :: (window: *SDL_Window, sdl_gl_context: *void) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForOpenGL@@YA_NPEAUSDL_Window@@PEAX@Z";
ImplSDL3_InitForVulkan :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForVulkan@@YA_NPEAUSDL_Window@@@Z";
ImplSDL3_InitForD3D :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForD3D@@YA_NPEAUSDL_Window@@@Z";
ImplSDL3_InitForMetal :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForMetal@@YA_NPEAUSDL_Window@@@Z";
ImplSDL3_InitForSDLRenderer :: (window: *SDL_Window, renderer: *SDL_Renderer) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForSDLRenderer@@YA_NPEAUSDL_Window@@PEAUSDL_Renderer@@@Z";
ImplSDL3_InitForSDLGPU :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForSDLGPU@@YA_NPEAUSDL_Window@@@Z";
ImplSDL3_InitForOther :: (window: *SDL_Window) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_InitForOther@@YA_NPEAUSDL_Window@@@Z";
ImplSDL3_Shutdown :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_Shutdown@@YAXXZ";
ImplSDL3_NewFrame :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_NewFrame@@YAXXZ";
ImplSDL3_ProcessEvent :: (event: *SDL_Event) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_ProcessEvent@@YA_NPEBTSDL_Event@@@Z";

// Gamepad selection automatically starts in AutoFirst mode, picking first available SDL_Gamepad. You may override this.
// When using manual mode, caller is responsible for opening/closing gamepad.
ImplSDL3_GamepadMode :: enum s32 {
    AutoFirst :: 0;
    AutoAll   :: 1;
    Manual    :: 2;
    ImGui_ImplSDL3_GamepadMode_AutoFirst :: AutoFirst;
    ImGui_ImplSDL3_GamepadMode_AutoAll   :: AutoAll;
    ImGui_ImplSDL3_GamepadMode_Manual    :: Manual;
}
ImplSDL3_SetGamepadMode :: (mode: ImplSDL3_GamepadMode, manual_gamepads_array: **SDL_Gamepad = null, manual_gamepads_count: s32 = -1) -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplSDL3_SetGamepadMode@@YAXW4ImGui_ImplSDL3_GamepadMode@@PEAPEAUSDL_Gamepad@@H@Z";

// Follow "Getting Started" link and check examples/ folder to learn about using backends!
ImplOpenGL3_Init :: (glsl_version: *u8 = null) -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_Init@@YA_NPEBD@Z";
ImplOpenGL3_Shutdown :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_Shutdown@@YAXXZ";
ImplOpenGL3_NewFrame :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_NewFrame@@YAXXZ";
ImplOpenGL3_RenderDrawData :: (draw_data: *ImDrawData) -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_RenderDrawData@@YAXPEAUImDrawData@@@Z";

// (Optional) Called by Init/NewFrame/Shutdown
ImplOpenGL3_CreateFontsTexture :: () -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_CreateFontsTexture@@YA_NXZ";
ImplOpenGL3_DestroyFontsTexture :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_DestroyFontsTexture@@YAXXZ";
ImplOpenGL3_CreateDeviceObjects :: () -> bool #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_CreateDeviceObjects@@YA_NXZ";
ImplOpenGL3_DestroyDeviceObjects :: () -> void #foreign imgui_sdl3_opengl3 "?ImGui_ImplOpenGL3_DestroyDeviceObjects@@YAXXZ";

#scope_file

imgui_sdl3_opengl3 :: #library,no_dll "ImGui_sdl3_opengl3.static";
