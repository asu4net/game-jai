// see the Default_Metaprogram in modules
// another option tprint("%./bin", #filepath);

//TODO: Copy SDL dll on comptime depending on the operating system.

EXECUTABLE_NAME :: "game";
OUTPUT_PATH     ::"../bin";
BUILD_FILE      ::"../src/first.jai";
MODULES_PATH     ::"../src/modules";

#run compile();

compile :: () {

    //compile_shaders();

    log("Compiling game...");   
    w := compiler_create_workspace("game");

    if !w {
        print("Workspace creation failed.\n");
        return;
    }
    
    target_options := get_build_options(w);
    target_options.output_executable_name = EXECUTABLE_NAME;
    target_options.output_path = String.join(#filepath, OUTPUT_PATH);

    new_import_path : [..] string;
    array_copy(*new_import_path, target_options.import_path);
    array_add(*new_import_path, MODULES_PATH);
    target_options.import_path = new_import_path;


    set_optimization(*target_options, .DEBUG);
    set_build_options(target_options, w);
    add_build_file(String.join(#filepath, BUILD_FILE), w);
    add_build_string("DEBUG   :: true;", w);
    add_build_string("RELEASE :: false;", w);
    add_build_string("DIST    :: false;", w);
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Compiler";
String :: #import "String";
#load "compile_shaders.jai";