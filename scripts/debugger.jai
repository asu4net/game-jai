#scope_file

#run run_debugger();

CONFIG_FILE :: "../bin/debug.rdbg";

run_debugger :: () {

    log("Running debugger...");

    process_result, output_string, error_string, _ := Process.run_command(
        "remedybg",
        CONFIG_FILE
    );
    
    if process_result.type == .FAILED_TO_LAUNCH {
        log_error("Could not run the debugger!");
    }
    
    log("%", output_string);
    log_error("%", error_string);
    log("Debugger closed!");
    set_build_options_dc(.{do_output=false});
}

#import "Basic";
#import "Command_Line";
#import "Compiler";
Process :: #import "Process";
String :: #import  "String";