#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo           : bool;
    prefab_name         : TextBuff;
    prefab_type         : PrefabEditorType;
    prefab              : *Entity;
    show_create_prefab  : bool;
}

PrefabEditorType :: struct {
    name : string;
    slot : u32;
}

#add_context editor : Editor;

draw_editor :: () {
    using context.editor;

    if ImGui.BeginMenuBar()  {
        if ImGui.BeginMenu("ImGui") {
            ImGui.Checkbox("Show demo", *show_demo);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Prefab")  {
            if ImGui.MenuItem("New") {
                if prefab {
                    save_prefab_and_close();
                }
                show_create_prefab = true;
            }
            if ImGui.BeginMenu("Load") {
                // Load all the prefabs
                visit_files("assets", true, null, (info: *File_Visit_Info, *void) {
                    path, basename, ext := path_decomp(info.full_name ,,temp);
                    if ext != "prefab" {
                        return;
                    }
                    if ImGui.MenuItem(to_c_string(basename ,,temp)) {
                        if context.editor.prefab {
                            immediate_destroy_entity(context.editor.prefab, true);
                            context.editor.prefab = null;
                        }
                        prefab_str, success := read_entire_file(info.full_name ,,temp);
                        assert(success);
                        context.editor.prefab = deserialize_entity_recursive(prefab_str);
                    }
                });
                ImGui.EndMenu();
            }
            if prefab && ImGui.MenuItem("Save and Close") {
                save_prefab_and_close();
            }
            if prefab && ImGui.MenuItem("Close") {
                immediate_destroy_entity(prefab, true);
                prefab = null;
            }
            ImGui.EndMenu();
        }
        ImGui.EndMenuBar();
    }

    if show_demo {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_demo);
    }
    
    if show_create_prefab {
     ImGui.OpenPopup("Create Prefab");
    }
    
    ImGui.PushStyleColor(.PopupBg, .{0.0, 0.0, 0.0, 1});
    viewpor_size := ImGui.GetMainViewport().WorkSize;
    ImGui.SetNextWindowPos(viewpor_size / 2, .Appearing, .{0.5, 0.5});
    
    if ImGui.BeginPopupModal("Create Prefab", flags = .AlwaysAutoResize | .NoMove)  {
        ImGui.InputText("Name", data(prefab_name), TEXT_BUFF_SIZE);

        prefab_types : [..] PrefabEditorType;
        
        for scene : context.scenes {
            if !scene continue;
            array_add(*prefab_types, .{ scene.type.name, scene.slot } ,,temp);
        }

        if prefab_type.name.count == 0 {
           prefab_type = prefab_types[0];
        }

        if ImGui.BeginCombo("Type", to_c_string(prefab_type.name ,,temp)) {
            for type, i : prefab_types {
                if ImGui.Selectable(to_c_string(type.name ,,temp)) {
                    prefab_type = type;
                }
            }
            ImGui.EndCombo();
        }
        
        if ImGui.Button("Create") {
            show_create_prefab = false;
            scene := context.scenes[prefab_type.slot];
            
            if scene && c_style_strlen(data(prefab_name)) > 0 {
                if prefab {
                    destroy_entity(prefab);
                    prefab = null;
                }
                prefab = scene.entity_procs.create(scene.slot, to_string(data(prefab_name)));
                ImGui.CloseCurrentPopup();
            }
        }

        ImGui.SameLine();
        if ImGui.Button("Cancel") {
            show_create_prefab = false;
            ImGui.CloseCurrentPopup();
        }
        ImGui.EndPopup();
    }
    ImGui.PopStyleColor();

    if prefab {
        ImGui.Begin("Properties");
        scene := get_scene(prefab);
        scene.entity_procs.draw_editor(prefab);
        ImGui.End();
    }
}

save_prefab_and_close :: () {
    using context.editor;
    assert(prefab != null);
    builder : String_Builder;
    serialize_entity_recursive(prefab, *builder);
    write_entire_file(tprint("assets/%.prefab", prefab.tag ,,temp), *builder);
    immediate_destroy_entity(prefab, true);
    ImGui.CloseCurrentPopup();
    prefab = null;
}

draw_editor_value :: (value : Any, inside_struct_or_array := true, may_be_uninitialized := false) {
    using Type_Info_Tag;

    //#TODO_asuarez Maybe I should draw this property anyway, with an empty value.
    if !value.value_pointer {
        return;
    }

    t := value.type.type;
    if t == {
        case STRING;

            get_full_sized_string :: (any: Any) -> string {
                assert(any.type && (any.type.type == .STRING));
                tis := cast(*Type_Info_String) any.type;
                return (.*) cast(*string) any.value_pointer;
            }

            s := get_full_sized_string(value);
            ImGui.Text(s);

        case BOOL;
            b := (.*) cast(*u8) value.value_pointer;
        case INTEGER;
        case FLOAT;
        case POINTER;
            info_pt := cast(*Type_Info_Pointer) value.type;
            if info_pt.pointer_to.type == {
                // pasar por todos los tipos, castearlo al tipo que toca, construir un any, y llamar a esta función.
            }
        case STRUCT;
            
            info_struct := cast(*Type_Info_Struct) value.type;
            
            for * info_struct.members {

                may_be_uninitialized := false;

                for note: it.notes {
                    if note == "---" {
                        may_be_uninitialized = true;
                        break;
                    }
                }

                address := (cast(*u8) value.value_pointer) + it.offset_in_bytes;

                any: Any = ---;
                any.type = it.type;
                any.value_pointer = address;

                draw_editor_value(any, true, may_be_uninitialized);
            }

        case ARRAY;
            info_array := cast(*Type_Info_Array) value.type;
        case ENUM;
            
            info_enum := cast(*Type_Info_Enum) value.type;
            info_int  := cast(*Type_Info_Integer) info_enum.internal_type;
            assert(info_int.type == INTEGER);

            size := info_int.runtime_size;

            if info_enum.enum_type_flags & .FLAGS {
                target_value := get_u64_from_void_pointer(value.value_pointer, size);  // Treat flags as unsigned, even for signed types. Simpler.

                if target_value == 0 {
                    // Check for a named 0-value before printing 0.
                    name := "0";
                    for info_enum.values  if it == 0 {
                        name = info_enum.names[it_index];
                        break;
                    }
                    
                    //append(builder, name);
                    return;
                }

                // I felt like doing this in unsigned for some reason!
                flags_total := target_value;
                flags_printed : u64 = 0;

                first := true;
                for info_enum.values {
                    value := cast(u64) it;
                    matching := flags_total & value;
                    if matching != value  matching = 0;  // We need to match all of the bits in the enum member.

                    if !matching continue;
                    if !(matching & ~flags_printed) continue;

                    flags_printed |= matching;

                    //if !first  append(builder, " | ");
                    //append(builder, info_enum.names[it_index]);
                    first = false;
                }

                unmatched := flags_total & ~flags_printed;
                if unmatched {
                    //if !first  append(builder, " | 0x");
                    format := FormatInt.{base=16};
                    //print_u64_base_n(builder, unmatched, format);
                }
            } else {
                assert(info_enum.names.count == info_enum.values.count);

                target_value_s64 := get_s64_from_void_pointer(value.value_pointer, size);
                if info_int.signed {
                    for info_enum.values  if target_value_s64 == it {
                        //append(builder, info_enum.names[it_index]);
                        return;
                    }
                } else {
                    target_value_u64 := get_u64_from_void_pointer(value.value_pointer, size);

                    for info_enum.values  if target_value_u64 == cast,no_check(u64) it {
                        //append(builder, info_enum.names[it_index]);
                        return;
                    }
                }

                if target_value_s64 {
                    //append(builder, "(enum out of range: ");
                    // Print an unsigned value if the enum is unsigned,
                    // otherwise we allow it to be signed.
                    //if info_int.signed  draw_editor_value(builder, target_value_s64);
                    //else                draw_editor_value(builder, get_u64_from_void_pointer(value.value_pointer, size));
                    //append(builder, ")");
                } else {
                    //draw_editor_value(builder, target_value_s64);
                }
            }

        case;
            return;
    }
}

} //#if IMGUI