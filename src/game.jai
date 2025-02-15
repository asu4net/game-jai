#import "Input";
#import "Window_Creation";

#load "graphics_pipeline.jai";
#load "graphics_device.jai";

width                 : u32 = 640;
height                : u32 = 480;
window                : Window_Type;

main :: () {
    // Create window
    window = create_window(xx width, xx height, "Hello Vulkan");

    init_graphics();
    defer deinit_graphics();

    quit := false;
    while !quit {
        
        update_window_events();

        for event: events_this_frame {
            if event.type == .QUIT then quit = true;
        }

        draw_frame();
    }
}