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
COMPILE_FLAGS                 :: (.DEBUG | .EDITOR | .IMGUI).(CompileFlags);

// Entity code generation.

MAX_ENTITIES                  :: 3000;
DEFAULT_COMPONENT_ARENA_COUNT :: 30;

GENERATED_COMPONENT_ARENAS    :: #string SCOPE 

Generated_Component_Arenas :: struct {
    %1
}

init_generated_component_arenas :: (using a : *Generated_Component_Arenas, all : *[..] *Component_Arena_Base) {
    %2    
}

deinit_generated_component_arenas :: (using a : *Generated_Component_Arenas) {
    %3    
}

get_generated_component_arena :: (using a : *Generated_Component_Arenas, $T : Type) -> *Component_Arena(T) {
    #if T == {
        %4
        case; return null;
    }
}

get_generated_component_arena_base :: (using a : *Generated_Component_Arenas, t : Type) -> *Component_Arena_Base {
    if t == {
        %4
        case; return null;
    }
}

#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) Generated_Component_Arenas;
#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) init_generated_component_arenas;
#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) deinit_generated_component_arenas;
#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) get_generated_component_arena;
#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) get_generated_component_arena_base;
#if EDITOR
then #poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) editor_draw_property;

MAX_ENTITIES :: %5;

SCOPE

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
        proc_headers: [..] *Code_Procedure_Header;

        while true {
            message := compiler_wait_for_message();
            if message.kind == {

                case .TYPECHECKED;
                    typechecked := cast(*Message_Typechecked) message;
                    for typechecked.structs {
                        code_struct := it.expression; 
                        array_add(*struct_expressions, code_struct);
                    }
                    for typechecked.procedure_headers {
                        code_header := it.expression;
                        array_add(*proc_headers, code_header);
                    }
                
                case .PHASE;
                    phase := cast(*Message_Phase) message;
                    if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                        if !generated_code {
                            
                            Component_Info :: struct {
                                type_name      : string;
                                max            : s64;
                                init_order     : s64 = 30100;
                                cpy_proc := "null";
                                rem_proc := "null";
                                add_proc := "null";
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
                                        if begins_with(note, "initorder(") {
                                            expected_init_order := slice(note, 10, note.count-11);
                                            info := table_find_pointer(*component_info, it.defined_type.name);
                                            if !info {
                                                log_error("Error: Detected @Max attribute without or before the @Component attribute \n");
                                                continue;
                                            }
                                            init_order, success := parse_int(*expected_init_order);
                                            if !success {
                                                log_error("Error parsing the @InitOrder attribute for %. Expected something like @InitOrder(0) but got this % \n", it.defined_type.name, note_obj.text);
                                                continue;
                                            }
                                            info.init_order = init_order;                                         
                                        }
                                        if begins_with(note, "max(") {
                                            expected_num := slice(note, 4, note.count-5);
                                            info, found := table_find(*component_info, it.defined_type.name);
                                            if !found {
                                                log_error("Error: Detected @Max attribute without or before the @Component attribute \n");
                                                continue;
                                            }
                                            if expected_num == "max_entities" {
                                                info.max = MAX_ENTITIES;
                                                table_set(*component_info, info.type_name, info);
                                            } else {
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
                                }
                            } // Done collecting info.
                            {
                                // This is fucking ugly but who cares.
                                for proc_headers {
                                    for note_obj : it.notes {
                                        note := to_lower_copy(note_obj.text);
                                        if note == "copycomponentcallback" || note == "removecomponentcallback"  {
                                            for argument : it.arguments {
                                                argument_type := argument.entry.base.type;
                                                if argument_type.type == .POINTER {
                                                    pointer_type := argument_type.(*Type_Info_Pointer);
                                                    if pointer_type.pointer_to.type == .STRUCT {
                                                        struct_type := pointer_type.pointer_to.(*Type_Info_Struct);
                                                        info := table_find_pointer(*component_info, struct_type.name);
                                                        if info {
                                                            if note == "copycomponentcallback"
                                                            then info.cpy_proc = it.name;
                                                            else if note == "removecomponentcallback"
                                                            then info.rem_proc = it.name;
                                                        }
                                                    } 
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Generate the code.
                            {
                                arenas_string      : string;
                                arenas_init_string : string;
                                arenas_deinit_string : string;
                                arenas_get_string : string;
                                {
                                    arenas_builder : String_Builder;
                                    arenas_init_builder : String_Builder;
                                    arenas_deinit_builder : String_Builder; 
                                    arenas_get_builder : String_Builder;
                                    
                                    component_info_array : [..] Component_Info;

                                    for value, key : component_info {
                                        array_add(*component_info_array, value);
                                    }
                                                                        
                                    // here sort the array WIP
                                    quick_sort(component_info_array, x => x.init_order);

                                    for value : component_info_array {
                                        arena_name := to_lower_copy(value.type_name);
                                        max := ifx value.max > 0 then value.max else DEFAULT_COMPONENT_ARENA_COUNT; 
                                        print_to_builder(*arenas_builder, "%1_arena: Component_Arena(%2);\n", arena_name, value.type_name);
                                        print_to_builder(*arenas_init_builder, "init(*%1_arena, %2, cpy_proc = %3, add_proc = %4, rem_proc = %5);\n", arena_name, max, value.cpy_proc, value.add_proc, value.rem_proc);
                                        print_to_builder(*arenas_init_builder, "array_add(all, *%1_arena);\n", arena_name);
                                        print_to_builder(*arenas_deinit_builder, "deinit(*%1_arena);\n", arena_name);
                                        print_to_builder(*arenas_get_builder, "case %1; return *%2_arena;\n", value.type_name, arena_name);
                                        
                                        print("Registered component arena of type: %. Max elements: %. InitOrder: % \n", value.type_name, max, value.init_order);
                                    }

                                    arenas_string = builder_to_string(*arenas_builder);
                                    arenas_init_string = builder_to_string(*arenas_init_builder);
                                    arenas_deinit_string = builder_to_string(*arenas_deinit_builder);
                                    arenas_get_string = builder_to_string(*arenas_get_builder);
                                }

                                generated_arenas_string := sprint(GENERATED_COMPONENT_ARENAS, arenas_string, arenas_init_string,
                                arenas_deinit_string, arenas_get_string, MAX_ENTITIES);
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
#import "Math";
#import "Hash_Table";