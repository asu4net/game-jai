
compile_shaders :: () {

    log("Compiling shaders...");
    compile_shader("bin/assets/shaders/simple_shader.vert");
    compile_shader("bin/assets/shaders/simple_shader.frag");
    set_build_options_dc(.{do_output=false});
}

#scope_file
compile_shader :: (file : string) {
    
    log("Compiling shader % ...", file);

    process_result, output_string, error_string, _ := Process.run_command(
        "glslc",
        file,
        "-o",
        String.join(file, ".spv"), working_directory=#filepath, capture_and_return_output=true
    );

    if process_result.type == .FAILED_TO_LAUNCH {
        log_error("Could not run the shader build command.");
        return;
    }
    
    log("Shader compilation finished with exit code: % ", process_result.exit_code);
    log("%", output_string);
    log_error("%", error_string);
}

#import "Basic";
#import "Command_Line";
#import "Compiler";
Process :: #import "Process";
String :: #import "String";