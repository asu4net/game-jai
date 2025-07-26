#import "Compiler";
#import "Basic";
#import "File";
String :: #import "String";

#load "src/entity/generate.jai";

Build_Flags :: enum_flags {
    DEBUG;
    RELEASE;
    IMGUI;
    EDITOR;
}

Build_Args :: struct {
    exec_name := "game";
    out_dir := "bin";
    build_file := "first.jai";
    flags := Build_Flags.DEBUG; 
}

#run {
    set_build_options_dc(.{do_output=false});
    clone_dependencies();
    build_args : Build_Args;
    collect_build_args(*build_args);
    w := setup_workspace(build_args);
    wait_until_workspace_has_finished(w);
    reset_temporary_storage();
}

clone_dependencies :: () {
    #import "Process";
    #import "File_Utilities";
    
    scope_set_working_directory :: (dir: string) #expand {
        cwd := get_working_directory();
        set_working_directory(dir);
        `defer set_working_directory(cwd);   
    }
    try_clone_dependency :: (name: string, url: string) {
        if file_exists(name) then return;
        run_command("git", "clone", url, name);
    }
    make_directory_if_it_does_not_exist("modules");
    scope_set_working_directory("modules");
    
    // Depencencies
    try_clone_dependency("Tuki"             ,"https://github.com/asu4net/Tuki");
    try_clone_dependency("ImGui"            ,"https://github.com/asu4net/ImGui");
    try_clone_dependency("SDL3"             ,"https://github.com/asu4net/jai-sdl3");
    try_clone_dependency("StbTrueType"      ,"https://github.com/asu4net/StbTrueType");
    try_clone_dependency("Enumerated_Array" ,"https://github.com/rezich/Enumerated_Array");
    try_clone_dependency("Queue"            ,"https://github.com/asu4net/Queue");
    try_clone_dependency("Sparse_Set"       ,"https://github.com/asu4net/Sparse_Set");
    try_clone_dependency("Math"             ,"https://github.com/asu4net/Math");
    try_clone_dependency("Jaison"           ,"https://github.com/rluba/jaison");
    
    copy_file("SDL3/windows/bin/x64/SDL3.dll", "../bin/SDL3.dll");
    copy_file("StbTrueType/libstbtruetype.dll", "../bin/libstbtruetype.dll");
}

collect_build_args :: (using build_args: *Build_Args) {
    args := get_build_options().compile_time_command_line;
    if !args.count {
        log("Unprovided build flag. Compiling with debug. \n");
        return;
    }
    collect_field : (using a: *Build_Args, string);
    for args {
        // Collect field;
        if collect_field && it.count && !String.begins_with(it, "-") {
            collect_field(build_args, it);
            collect_field = null;
            continue;
        }
        arg := String.to_lower_copy(it ,,temp);
        // Collect args.
        if arg == {
            case "-n"; collect_field = (using a: *Build_Args, field: string) { exec_name = field; };
            case "-o"; collect_field = (using a: *Build_Args, field: string) { out_dir = field; };
            case "-f"; collect_field = (using a: *Build_Args, field: string) { build_file = field; };
            case "-r"; flags |= .RELEASE;
            case "-i"; flags |= .IMGUI;
            case "-e"; flags |= .EDITOR;
            case; log("Unrecognized option % \n", arg);
        }
    }
    return;
}

setup_workspace :: (build_args : Build_Args) -> Workspace {
    w := compiler_create_workspace();
    compiler_begin_intercept(w);
    options := get_build_options(w);
    options.output_executable_name = build_args.exec_name;
    options.output_path = build_args.out_dir;
    make_directory_if_it_does_not_exist(options.output_path);
    if build_args.flags & .RELEASE {
        options.backend = .LLVM;
        set_optimization(*options, .OPTIMIZED);
    } else {
        options.backend = .X64;
        set_optimization(*options, .DEBUG);
    }
    set_build_options(options, w);
    add_build_file(build_args.build_file, w);

    add_build_string(tprint("DEBUG  :: %;", (build_args.flags & .DEBUG)  .(bool)), w);
    add_build_string(tprint("IMGUI  :: %;", (build_args.flags & .IMGUI)  .(bool)), w);
    add_build_string(tprint("EDITOR :: %;", (build_args.flags & .EDITOR) .(bool)), w);
    return w;
}

wait_until_workspace_has_finished :: (w: Workspace) {
    log("Building %...", get_build_options(w).output_executable_name);
    ended_with_errors := false;
    while true {
        message := compiler_wait_for_message();
        entity_process_compiler_message(w, message);
        if message.kind == .COMPLETE {
            log("Done building.");
            break;
        }
        if message.kind == .ERROR {
            ended_with_errors = true;
            break;
        }
    }
    compiler_end_intercept(w);
    if ended_with_errors then compiler_set_workspace_status(.FAILED);
}