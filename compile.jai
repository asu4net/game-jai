//#TODO_asuarez: Copy SDL dll on comptime depending on the operating system.

EXECUTABLE_NAME               :: "game";
OUTPUT_PATH                   :: "bin";
BUILD_FILE                    :: "src/game.jai";
DEFAULT_COMPONENT_ARENA_COUNT :: 30;

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
    
    compiler_begin_intercept(w);
    
    add_build_string("DEBUG     :: true;", w);
    add_build_string("RELEASE   :: false;", w);
    add_build_string("DIST      :: false;", w);
    add_build_string("EDITOR    :: true;", w);
    add_build_string("IMGUI     :: true;", w);

    add_build_file(join(#filepath, BUILD_FILE), w);

    message_loop();
    
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
}

generated_code := false;

Component_Info :: struct {
    type_name : string;
    max : s64;
}

component_info: Table(string, Component_Info);
struct_expressions: [..] *Code_Struct;

message_loop :: () {

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
                                    print("Error parsing the @Max attribute for %. Expected something like Max(30) but got this % \n", it.defined_type.name, note_obj.text);
                                    continue;
                                } else {
                                    info, found := table_find(*component_info, it.defined_type.name);
                                    if !found {
                                        print("Error: Detected @Max attribute without or before the @Component attribute \n");
                                        continue;
                                    }
                                    info.max = max;
                                    table_set(*component_info, info.type_name, info);
                                }
                            }
                        }
                    }
                    generate_code(message.workspace);
                    generated_code = true;
                }
            }
            
          case .COMPLETE;
            break;
        }
    }
}

// Vamos a generar tres cosas
//
// 1. La declaración de cada component arena templatizada.
// 2. Las llamadas de inicialización y destrucción de las arenas.
// 3. Las función templatizada que devuelve la arena según el tipo.

GENERATED_COMPONENT_ARENAS :: #string SCOPE 
#add_context generated_component_arenas : Generated_Component_Arenas;

Generated_Component_Arenas :: struct {
    %1
}

SCOPE

generate_code :: (w : Workspace) {
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
}

#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "Hash_Table";