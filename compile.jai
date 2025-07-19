CompileFlags :: enum_flags {
    DEBUG;
    RELEASE;
    EDITOR;
    IMGUI;
}

EXECUTABLE_NAME :: "game";
OUTPUT_PATH     :: "bin";
BUILD_FILE      :: "src/main.jai";
COMPILE_FLAGS   :: (.DEBUG | .IMGUI | .EDITOR).(CompileFlags);

MAX_ENTITIES                  :: 3000;
DEFAULT_COMPONENT_ARENA_COUNT :: 1000;

ADD_CALLBACK_STR :: "addcomponentcallback";
REM_CALLBACK_STR :: "removecomponentcallback";
CPY_CALLBACK_STR :: "copycomponentcallback"; 

GENERATED_COMPONENT_ARENAS :: #string SCOPE

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

//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) Generated_Component_Arenas;
//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) init_generated_component_arenas;
//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) deinit_generated_component_arenas;
//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) get_generated_component_arena;
//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) get_generated_component_arena_base;
//#if EDITOR && IMGUI
//then #poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) editor_draw_property;

MAX_ENTITIES :: %5;

SCOPE

GENERATED_COMPONENT_CALLBACKS :: #string SCOPE
set_component_callbacks_for_generated_arenas :: (using a : *Generated_Component_Arenas) {
    %1
}

//#poke_name (#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES) ) set_component_callbacks_for_generated_arenas;

SCOPE

Component_Info :: struct {
    type_name  : string;
    max        : s64;
    init_order : s64 = 30100;
    cpy_proc   : string;
    rem_proc   : string;
    add_proc   : string;
}

collect_component_info :: (structs: [..] *Code_Struct, result : *Table(string, Component_Info)) {
    for s : structs {
        for note_obj : s.notes {
            note := to_lower_copy(note_obj.text);

            if note == "component" {
                info := Component_Info.{ type_name = s.defined_type.name };
                table_add(result, info.type_name, info);
            }

            if begins_with(note, "initorder(") {
                info := table_find_pointer(result, s.defined_type.name);
                if !info continue;

                parsed, ok := parse_int(*slice(note, 10, note.count-11));
                if ok info.init_order = parsed;
            }

            if begins_with(note, "max(") {

                parsed_text := slice(note, 4, note.count-5);
                found, info := table_find_new(result, s.defined_type.name);
                if !found continue;

                if parsed_text == "max_entities" {
                    info.max = MAX_ENTITIES;
                } else {
                    parsed, ok := parse_int(*parsed_text);
                    if ok info.max = parsed;
                }

                table_set(result, info.type_name, info);
            }
        }
    }
}

generate_component_arenas_code :: (info_table: Table(string, Component_Info)) -> string {
    log("Generating code...");
    builder      : String_Builder;
    builder_init : String_Builder;
    builder_deinit : String_Builder;
    builder_get  : String_Builder;

    info_array: [..] Component_Info;
    for val, _ : info_table array_add(*info_array, val);

    quick_sort(info_array, x => x.init_order);

    for info : info_array {

        name := to_lower_copy(info.type_name);
        max := ifx info.max > 0 then info.max else DEFAULT_COMPONENT_ARENA_COUNT;

        print_to_builder(*builder, "%1_arena: Component_Arena(%2);\n", name, info.type_name);
        print_to_builder(*builder_init, "init_component_arena(*%1_arena, %2);\n", name, max);
        print_to_builder(*builder_init, "array_add(all, *%1_arena);\n", name);
        print_to_builder(*builder_get, "case %1; return *%2_arena;\n", info.type_name, name);
        log("Registered component arena of type: %. Max elements: %. InitOrder: % \n", info.type_name, max, info.init_order);
    }

    for info : info_array {
        name := to_lower_copy(info.type_name);
        print_to_builder(*builder_deinit, "deinit_component_arena(*%1_arena);\n", name);
    }

    log("Done generating code.");
    return sprint(GENERATED_COMPONENT_ARENAS,
        builder_to_string(*builder),
        builder_to_string(*builder_init),
        builder_to_string(*builder_deinit),
        builder_to_string(*builder_get),
        MAX_ENTITIES
    );
}

assign_component_callbacks :: (procs: [..] *Code_Procedure_Header, info_table: *Table(string, Component_Info)) {
    
    for p : procs {
        for note_obj : p.notes {
            note := to_lower_copy(note_obj.text);
            if note != CPY_CALLBACK_STR && note != REM_CALLBACK_STR && note != ADD_CALLBACK_STR
            then continue;
            for arg : p.arguments {
                argument_type := arg.entry.base.type;
                if argument_type.type == .POINTER {
                    struct_type := argument_type.(*Type_Info_Pointer).pointer_to.(*Type_Info_Struct);
                    info := table_find_pointer(info_table, struct_type.name);
                    if note == {
                        case ADD_CALLBACK_STR; info.add_proc = p.name;
                        case REM_CALLBACK_STR; info.rem_proc = p.name;
                        case CPY_CALLBACK_STR; info.cpy_proc = p.name;
                    }
                }
            }
        }
    }
}

generate_component_callbacks_code :: (info_table: Table(string, Component_Info)) -> string {
    log("Generating code...");
    builder : String_Builder;

    for info, _ : info_table {
        name := to_lower_copy(info.type_name);
        if info.add_proc.count > 0  {
            print_to_builder(*builder, "set_add_component_callback(*%1_arena.type, %2, %3);\n", name, info.type_name, info.add_proc);
        }
        if info.cpy_proc.count > 0  {
            print_to_builder(*builder, "set_cpy_component_callback(*%1_arena.type, %2, %3);\n", name, info.type_name, info.cpy_proc);
        } else {
            print_to_builder(*builder, "set_cpy_component_callback_default(*%1_arena.type, %2);\n", name, info.type_name);
        }
        if info.rem_proc.count > 0  {
            print_to_builder(*builder, "set_rem_component_callback(*%1_arena.type, %2, %3);\n", name, info.type_name, info.rem_proc);
        }
    }
    log("Done generating code.");
    return sprint(GENERATED_COMPONENT_CALLBACKS,
        builder_to_string(*builder)
    );
}

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
    
    generated_code := false;
    generated_callbacks_code := false;
    structs: [..] *Code_Struct;
    procs: [..] *Code_Procedure_Header;
    component_info : Table(string, Component_Info);

    while true {
        msg := compiler_wait_for_message();
        if msg.kind == {
            case .TYPECHECKED;
                m := cast(*Message_Typechecked) msg;
                for m.structs array_add(*structs, it.expression);
                for m.procedure_headers {
                    found := false;
                    name := it.expression.name;
                    for it.expression.notes {
                        if to_lower_copy(it.text) == ADD_CALLBACK_STR || to_lower_copy(it.text) == REM_CALLBACK_STR || to_lower_copy(it.text) == CPY_CALLBACK_STR {
                            found = true;
                            log("Collected callback procedure %", name);
                        } 

                    }
                    if found
                    then array_add(*procs, it.expression);
                }

                if procs.count > 0 && generated_code && !generated_callbacks_code {
                    assign_component_callbacks(procs, *component_info);
                    code := generate_component_callbacks_code(*component_info);
                    add_build_string(code, w);
                    generated_callbacks_code = true;
                }

            case .PHASE;
                phase := cast(*Message_Phase) msg;
                if phase.phase == .TYPECHECKED_ALL_WE_CAN && !generated_code {
                    collect_component_info(structs, *component_info);
                    code := generate_component_arenas_code(component_info);
                    add_build_string(code, w);
                    generated_code = true;
                }

            case .COMPLETE;
                break;
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