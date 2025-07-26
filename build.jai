#load "src/entity/generate.jai";

CompileFlags :: enum_flags {
    DEBUG;
    RELEASE;
    EDITOR;
    IMGUI;
}

EXECUTABLE_NAME :: "game";
OUTPUT_PATH     :: "bin";
BUILD_FILE      :: "first.jai";
COMPILE_FLAGS   :: (.DEBUG | .IMGUI | .EDITOR).(CompileFlags);

#run {
    set_build_options_dc(.{do_output=false});
    log("Compiling %...", EXECUTABLE_NAME);

    w := compiler_create_workspace(EXECUTABLE_NAME);
    if !w assert(false);

    // Build options.
    {
        target_options := get_build_options(w);
        target_options.output_executable_name = EXECUTABLE_NAME;
        target_options.output_path = join(#filepath, OUTPUT_PATH);
        
        if COMPILE_FLAGS & .DEBUG {
            target_options.backend = .X64;
            set_optimization(*target_options, .DEBUG);
        } else if COMPILE_FLAGS & .RELEASE {
            target_options.backend = .LLVM;
            set_optimization(*target_options, .OPTIMIZED);
        } else {
            log_error("Error: Optimization level is required");
            assert(false);
        }
        set_build_options(target_options, w);
    }

    // Compiler starts running.
    compiler_begin_intercept(w);   

    // Build file.
    add_build_file(join(#filepath, BUILD_FILE), w);

    // Add compiler flags to the code. 
    {
        if COMPILE_FLAGS & .DEBUG {
            add_build_string("DEBUG :: true;", w);
            add_build_string("RELEASE :: false;", w);
        } else if COMPILE_FLAGS & .RELEASE {
            add_build_string("DEBUG :: false;", w);
            add_build_string("RELEASE :: true;", w);
        } else {
            log_error("Error: Optimization level is required");
            assert(false);
        }

        if COMPILE_FLAGS & .IMGUI 
        then add_build_string("IMGUI :: true;", w);
        else add_build_string("IMGUI :: false;", w);
        
        if COMPILE_FLAGS & .EDITOR
        then add_build_string("EDITOR :: IMGUI && true;", w);
        else add_build_string("EDITOR :: IMGUI && false;", w);
        
    }
    
    while 1 {
        msg := compiler_wait_for_message();
        entity_process_compiler_message(w, msg);
        if msg.kind == {
            case .COMPLETE; break;
        }
    }

    compiler_end_intercept(w);
    log("Done!");
}

#import "File";
#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "Math";
#import "Hash_Table";