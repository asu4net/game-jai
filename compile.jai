//#TODO_asuarez: Copy SDL dll on comptime depending on the operating system.
EXECUTABLE_NAME :: "game";
OUTPUT_PATH     :: "bin";
BUILD_FILE      :: "src/game.jai";

#run compile();

compile :: () {

    log("Compiling game...");   
    w := compiler_create_workspace("game");

    if !w {
        print("Workspace creation failed.\n");
        return;
    }
    
    target_options := get_build_options(w);
    target_options.output_executable_name = EXECUTABLE_NAME;
    target_options.output_path = join(#filepath, OUTPUT_PATH);
    
    set_optimization(*target_options, .DEBUG);
    set_build_options(target_options, w);
    add_build_file(join(#filepath, BUILD_FILE), w);

    //#TODO_asuarez Parse arguments from console.
    add_build_string("DEBUG     :: true;", w);
    add_build_string("RELEASE   :: false;", w);
    add_build_string("DIST      :: false;", w);
    add_build_string("EDITOR    :: true;", w);
    add_build_string("IMGUI     :: true;", w);
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";
#import "String";