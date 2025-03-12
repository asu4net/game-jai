// see the Default_Metaprogram in modules
// another option tprint("%./bin", #filepath);

EXECUTABLE_NAME :: "game";
OUTPUT_PATH     ::"./bin";
BUILD_FILE      ::"./src/first.jai";


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