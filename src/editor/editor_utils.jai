editor_draw_property :: (name_c: *u8, data: *void, info:*Type_Info) {
    name := to_string(name_c);

    using Type_Info_Tag;
    if info.type == {
        case INTEGER;
            info_int := cast(*Type_Info_Integer) info;
            if info_int.signed {
                editor_draw_drag_s32(name, data);
            } else {
                editor_draw_drag_u32(name, data);
            }
        case FLOAT;
            editor_draw_drag_f32(name, data, 0.1, FLOAT32_MIN, FLOAT32_MAX);
        case BOOL;
            editor_draw_bool(name, data);
        case STRING;
            editor_draw_input_text(name, data.(*string));
        case STRUCT;
            info_struct := cast(*Type_Info_Struct) info;
            tree_opened := false;
            if name_c
            then tree_opened = ImGui.TreeNode(name_c, "%: %", name, info_struct.name);
            else tree_opened = ImGui.TreeNode(to_c_string(info_struct.name ,,temp));
            if tree_opened {
                for member: info_struct.members {
                    ignore : bool;
                    is_color : bool;
                    for note: member.notes {
	                	if note == "EditorIgnore" {
                            ignore = true;
                        }
                        if note == "Color" {
                            is_color = true;
                        }
	                }
                    if !ignore {
                        member_data := data + member.offset_in_bytes;
                        if member.type == type_info(v2) {
                            editor_draw_drag_vector2(member.name, member_data, ZERO_2D, 0.1);
                        } else if member.type == type_info(v3) {
                            editor_draw_drag_vector3(member.name, member_data, ZERO_3D, 0.1);
                        } else if member.type == type_info(v4) {
                            if !is_color {
                                editor_draw_drag_vector4(member.name, member_data, ZERO_4D, 0.1);
                            } else {
                                editor_draw_color_palette(member.name, member_data);
                            }
                        } else {
                            editor_draw_property(temp_c_string(member.name), member_data, member.type);
                        }
                    }
                }
                ImGui.TreePop();
            }
        case ARRAY;
            info_array := cast(*Type_Info_Array) info;
            array_count, array_data := get_array_count_and_data(data, info_array);
            array_name := name;
            element_size := info_array.element_type.runtime_size;
            if ImGui.TreeNode(name_c, "% (count = %)", array_name, array_count) {
                for 0..array_count-1 {
                    item_name := temp_c_string(tprint("%[%]", array_name, it));
                    editor_draw_property(item_name, array_data + it * element_size, info_array.element_type);
                }
                ImGui.TreePop();
            }
        case ENUM;
            editor_draw_enum_combo(name, info, data);
        case VARIANT;
        // @Incomplete: Can do something better here.
            tiv := cast(*Type_Info_Variant) info;
            editor_draw_property(name_c, data, tiv.variant_of);
        case;
    }
}

editor_draw_spacing :: inline (spacing : u32) {
    for 1..spacing ImGui.Spacing();
}

editor_draw_input_text :: (name : string, s : *string) {
    begin_property(name);
    editor_draw_string("##", s);
    end_property();
} 

editor_draw_string :: (name : string, s : *string) {
    
    MAX_COUNT :: 500;
    buffer: [MAX_COUNT] u8;
    count := min(s.count, MAX_COUNT);
    memcpy(*buffer, s.data, count);
    buffer[count] = #char "\0";
    
    if ImGui.InputText(to_c_string(name ,,temp), buffer.data, MAX_COUNT, .EnterReturnsTrue) {
        new_count := c_style_strlen(buffer.data);
        if new_count != s.count {
            new_data := alloc(new_count).(*u8);
            memcpy(new_data, *buffer, new_count);
            free(s.*);
            s.data  = new_data;
            s.count = new_count; 
        } else {
            memcpy(s.data, *buffer, new_count);
        }
    }
}

editor_draw_text :: (name : string, fmt: *u8, __args: ..Any) {
    begin_property(name);
    ImGui.Text("%s", fmt, __args);
    end_property();
}

editor_draw_enum_combo :: (name : string, info : *Type_Info, data : *void) {
    info_enum := cast(*Type_Info_Enum) info;

    if info_enum.enum_type_flags & .FLAGS {
        // @@ How to handle flags?
    } else {
        begin_property(name);
        value := get_enum_value(data, info_enum);
        value_name := "";
        for info_enum.names {
            if value == info_enum.values[it_index]  value_name = it;
        }

        if ImGui.BeginCombo(temp_c_string(join("##", name ,,temp)), temp_c_string(value_name)) {
            for info_enum.names {
                is_selected := value == info_enum.values[it_index];
                if ImGui.Selectable(temp_c_string(it), is_selected) {
                    set_enum_value(data, info_enum, info_enum.values[it_index]);
                }
                if is_selected ImGui.SetItemDefaultFocus();
            }

            ImGui.EndCombo();
        }
        end_property();
    }
}

editor_draw_bool :: (name : string, enabled : *bool) -> bool {
    begin_property(name);
    changed := ImGui.Checkbox("##", enabled);
    if in_property_context {
        ImGui.PopItemWidth();
    }
    end_property();
    return changed;
}

editor_draw_drag_s32 :: (name: string, value: *s32, speed: f32 = 1.0) -> bool {
    begin_property(name);
    changed := ImGui.DragInt("##", value, speed);
    if in_property_context {
        ImGui.PopItemWidth();
    }
    end_property();
    return changed;
}

editor_draw_drag_u32 :: (name: string, value: *u32, speed: f32 = 1.0) -> bool {
    begin_property(name);
    tmp: s32 = xx value.*;
    changed := ImGui.DragInt("##", *tmp, speed);
    value.* = xx tmp;
    if in_property_context {
        ImGui.PopItemWidth();
    }
    end_property();
    return changed;
}

editor_draw_drag_f32 :: (name: string, value: *f32, speed: f32, min: f32, max: f32) -> bool {
    begin_property(name);
    changed := ImGui.DragFloat("##", value, speed, min, max, "%.3f");
    if in_property_context {
        ImGui.PopItemWidth();
    }
    end_property();
    return changed;
}

editor_draw_drag_f32_with_button :: (label: string, value: *f32, reset_color: Vector4, reset_value: f32, speed: f32) -> bool {
    ImGui.PushID(label);

    line_height: f32 = ImGui.GetFontSize() + ImGui.GetStyle().FramePadding.y * 2.0;
    button_size := v2.{ line_height + 3.0, line_height };

    ImGui.PushStyleColor(.Button, v4.{reset_color.x, reset_color.y, reset_color.z, reset_color.w});
    reset := ImGui.Button(to_c_string(label ,,temp), button_size);
    ImGui.PopStyleColor();

    ImGui.SameLine();
    changed := ImGui.DragFloat("##value", value, speed, 0.0, 0.0, "%.3f");

    if reset {
        value.* = reset_value;
    }

    if in_property_context {
        ImGui.PopItemWidth();
    }

    ImGui.PopID();
    return changed || reset;
}

editor_draw_drag_vector2 :: (name: string, v: *Vector2, reset: Vector2, speed: f32) -> bool {
    begin_property(name, 2);
    x_changed := editor_draw_drag_f32_with_button("X", *v.x, COLOR_X, reset.x, speed);
    ImGui.SameLine();
    y_changed := editor_draw_drag_f32_with_button("Y", *v.y, COLOR_Y, reset.y, speed);
    end_property();
    return x_changed || y_changed;
}

editor_draw_drag_vector3 :: (name: string, v: *Vector3, reset: Vector3, speed: f32) -> bool {
    begin_property(name, 3);
    x_changed := editor_draw_drag_f32_with_button("X", *v.x, COLOR_X, reset.x, speed);
    ImGui.SameLine();
    y_changed := editor_draw_drag_f32_with_button("Y", *v.y, COLOR_Y, reset.y, speed);
    ImGui.SameLine();
    z_changed := editor_draw_drag_f32_with_button("Z", *v.z, COLOR_Z, reset.z, speed);
    end_property();
    return x_changed || y_changed || z_changed;
}

editor_draw_drag_vector4 :: (name: string, v: *Vector4, reset: Vector4, speed: f32) -> bool {
    begin_property(name, 4);
    x_changed := editor_draw_drag_f32_with_button("X", *v.x, COLOR_X, reset.x, speed);
    ImGui.SameLine();
    y_changed := editor_draw_drag_f32_with_button("Y", *v.y, COLOR_Y, reset.y, speed);
    ImGui.SameLine();
    z_changed := editor_draw_drag_f32_with_button("Z", *v.z, COLOR_Z, reset.z, speed);
    ImGui.SameLine();
    w_changed := editor_draw_drag_f32_with_button("W", *v.w, COLOR_W, reset.w, speed);
    end_property();
    return x_changed || y_changed || z_changed || w_changed;
}

editor_draw_color_palette :: (name: string, color: *Vector4) -> bool {
    begin_property(name);
    changed := ImGui.ColorEdit4("", *color.component, .NoLabel | .NoInputs);
    end_property();
    return changed;
}

#scope_file

COLUMN_WIDTH :: 120;

ITEM_SPACING :: v2.{0, 6 };

COLOR_X :: v4.{1.000, 0.300, 0.300, 1.000};
COLOR_Y :: v4.{0.368, 0.737, 0.521, 1.000};
COLOR_Z :: v4.{0.300, 0.300, 1.000, 1.000};
COLOR_W :: v4.{0.430, 0.258, 0.960, 1.000};

in_property_context := true;

begin_property :: (name : string, items : u32 = 1) {
    ImGui.PushID(name);
    ImGui.Columns(2);
    ImGui.SetColumnWidth(0, COLUMN_WIDTH);
    ImGui.Text(name);
    ImGui.NextColumn();
    ImGui.PushMultiItemsWidths(xx items, ImGui.CalcItemWidth());
    ImGui.PushStyleVar(.ItemSpacing, ITEM_SPACING);
    in_property_context = true;
}

end_property :: () {
    ImGui.PopStyleVar();
    ImGui.Columns(1);
    ImGui.PopID();
    in_property_context = false;
}