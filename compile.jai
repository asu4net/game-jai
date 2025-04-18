CompileFlags :: enum_flags {
    DEBUG;
    RELEASE;
    EDITOR;
    IMGUI;
}

// Compile settings.
EXECUTABLE_NAME               :: "game";
OUTPUT_PATH                   :: "bin";
BUILD_FILE                    :: "src/game.jai";
DEFAULT_COMPONENT_ARENA_COUNT :: 30;
COMPILE_FLAGS                 :: (.DEBUG | .EDITOR | .IMGUI).(CompileFlags);

#run {
    set_build_options_dc(.{do_output=false});
    log("Compiling %...", EXECUTABLE_NAME);  

    // Workspace creation.
    w := compiler_create_workspace(EXECUTABLE_NAME);

    if !w {
        print("Workspace creation failed.\n");
        assert(false);
    }
    
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
        then add_build_string("EDITOR :: true;", w);
        else add_build_string("EDITOR :: false;", w);
        
    }
    // Message loop.
    {
        generated_code := false;
        struct_expressions: [..] *Code_Struct;

        while true {
            message := compiler_wait_for_message();
            if message.kind == {

                case .TYPECHECKED;
                    typechecked := cast(*Message_Typechecked) message;
                    for typechecked.structs {
                        code_struct := it.expression; 
                        array_add(*struct_expressions, code_struct);
                    }
                
                case .PHASE;
                    phase := cast(*Message_Phase) message;
                    if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                        if !generated_code {
                            
                            Component_Info :: struct {
                                type_name : string;
                                max : s64;
                            }

                            // Info
                            component_info: Table(string, Component_Info);
                            
                            // Collect info from the structs.
                            {
                                for struct_expressions {
                                    for note_obj : it.notes {
                                        note := to_lower_copy(note_obj.text); 
                                        if note == "component" {
                                            info := Component_Info.{ type_name = it.defined_type.name };
                                            table_add(*component_info, info.type_name, info);
                                        }
                                        if begins_with(note, "max(") {
                                            expected_num := slice(note, 4, note.count-5);
                                            max, success := parse_int(*expected_num);
                                            if !success {
                                                log_error("Error parsing the @Max attribute for %. Expected something like Max(30) but got this % \n", it.defined_type.name, note_obj.text);
                                                continue;
                                            } else {
                                                info, found := table_find(*component_info, it.defined_type.name);
                                                if !found {
                                                    log_error("Error: Detected @Max attribute without or before the @Component attribute \n");
                                                    continue;
                                                }
                                                info.max = max;
                                                table_set(*component_info, info.type_name, info);
                                            }
                                        }
                                    }
                                }
                            } // Done collecting info.
                            
                            // Generate the code.
                            {
                                GENERATED_COMPONENT_ARENAS :: #string SCOPE 
                                #add_context generated_component_arenas : Generated_Component_Arenas;

                                Generated_Component_Arenas :: struct {
                                    %1
                                }

                                SCOPE

                                arenas_string : string;
                                {
                                    builder : String_Builder;
                                    for value, _ : component_info {
                                        arena_name := to_lower_copy(value.type_name);
                                        max := ifx value.max > 0 then value.max else DEFAULT_COMPONENT_ARENA_COUNT; 
                                        print_to_builder(*builder, " %1_arena: Component_Arena(%2, %3);", arena_name, value.type_name, max);
                                        print("Registered component arena of type: %. Max elements: %. \n", value.type_name, max);
                                    }
                                    arenas_string = builder_to_string(*builder);
                                }

                                generated_arenas_string := sprint(GENERATED_COMPONENT_ARENAS, arenas_string);
                                add_build_string(generated_arenas_string, w);
                                generated_code = true;

                            } // Done generating the code.
                        }
                    }
                
                case .COMPLETE;
                    break;
            }
        }
        
    } // Done with the message loop.
    
    compiler_end_intercept(w);
    
    log("Done!");
}

#import "File";
#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "Hash_Table";