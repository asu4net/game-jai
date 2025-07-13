# Libs

https://github.com/Jai-Community/Jai-Community-Library/wiki/References

# SDL Source

https://github.com/overlord-systems/jai-sdl3

# LS

https://github.com/SogoCZE/Jails?tab=readme-ov-file#manual-build

# Asset Packaging 

Aquí va un ejemplo de serialización de paquetes
```
/*
  Package Format spec:
  (this is the format in memory)
    Package_Header              64 bytes
      signature     "PakgData"  8 bytes
      version_major             2 bytes
      version_minor             2 bytes
      flags                     4 bytes

      __reserved                16 bytes

      package_name              32 bytes   (zero terminated if less than 32)

    A single entry consisting of:
      Base_Entry_Header
      [entry_header.data_count] u8

    (this entry is usually a Table of entries, but can be anything)

    END_OF_FILE.


  Entry headers:
    Base_Entry_Header                 24 bytes
      signature      "Ent!"           4 bytes
      entry_type                      2 bytes
      flags                           2 bytes
      data_offset                     8 bytes
      data_count                      8 bytes

    Table_Entry_Header                40 bytes
      Base_Entry_Header               24 bytes
      name_offset                     8 bytes
      name_count                      8 bytes (not including zero byte)

      (table entries offsets start from the start of table header)

  Entry types

  Table of entries:
    Table_Header                      24 bytes
      signature      "Map!"           4 bytes
      entry_count                     4 bytes
      names_data_size_in_bytes        8 bytes (includes signature)
      entry_data_size_in_bytes        8 bytes (includes signature)
    
    [entry_count] Table_Entry_Header  32 bytes
    ...
    
    signature "Nam!"                   4 bytes
    [names_data_size_in_bytes] u8
    ... 
    zero byte "\0"                     1 byte
    
    signature "Dat!"                   4 bytes
    [entry_data_size_in_bytes] u8
    ...

  Array of entries:
    Array_Header                16 bytes
      signature      "Arr!"     4 bytes
      entry_count               4 bytes
      entry_data_size_in_bytes  8 bytes
    [entry_count] Base_Entry_Header
    ...

  Array of data:
    Array_Of_Data_Header        16 bytes
      signature      "Arr!"     4 bytes
      element_size              4 bytes
      element_count             8 bytes
    [entry_count][element_size] u8
    ...

  String:
    String_Header               16 bytes
      signature      "Str!"     4 bytes
      __padding                 4 bytes
      string_count              8 bytes (not including zero byte)
    [count] bytes
    ...
    zero byte "\0"              1 byte

  Plain data:
    [] u8


  Type serialization:
    Structs are serialized as Tables of entries, Arrays are serialized as Arrays of entries.
    An exception to this is when the array element type is trivially copyable, or if the struct is
    masked as @trivial (subject to change), in which case it's serialized as plain data.
    Both Tables and Arrays of entries can recurse, since an Entry can be another array or table.
    Strings are serialized as, well, strings.
    The rest is plain data.

    For struct membes, the following notes can be used:
      @skip - skip writing and reading this member
      @no_read  - skip reading this member
      @no_write - skip writing this member
*/



Package :: struct {
    Entry_Type :: enum u16 #specified {
        DATA   :: 0;
        STRING :: 1;
        TABLE_OF_ENTRIES :: 2;
        ARRAY_OF_ENTRIES :: 3;
        ARRAY_OF_DATA :: 4;
    }

    Entry :: struct {
        data:  []u8;
        type:  Entry_Type;
        flags: u16;
    }

    Table_Entry :: struct {
        name: string;
        #as using entry: Entry;
    }

    name: string;
    data: []u8; // only on import
    flags: u32; // User flags
    base_entry: Entry;
}

find :: inline (table: []Package.Table_Entry, name: string) -> *Package.Table_Entry {
    for * table {
        if it.name == name {
            return it;
        }
    }
    return null;
}

read :: inline (filename: string, package: *Package) -> success: bool {
    data, success := read_entire_file(filename);
    if !success  return false;
    return read(package, xx data);
}

read :: (using package: *Package, input: []u8) -> success: bool {
    if input.count < size_of(Package_Header) {
        log_error("The input size is smaller than a package header size. (% bytes)", input.count);
        return false;
    }

    // Parse package header
    package_header := cast(*Package_Header) input.data;
    if package_header.signature != PACKAGE_HEADER_SIGNATURE {
        log_error("The package signature does not match.");
        return false;
    }
    if package_header.version_major < PACKAGE_FORMAT_VERSION_MAJOR {
        log_error("The package major version is smaller than the minimum version.");
        return false;
    }

    entry_data := []u8.{
        input.count - size_of(Package_Header),
        input.data + size_of(Package_Header)
    };

    // Parse base entry header
    if entry_data.count < size_of(Base_Entry_Header) {
        log_error("Remaining input data size is smaller than an entry header (% - % < %).",
                  input.count, size_of(Package_Header), size_of(Base_Entry_Header));
        return false;
    }
    header := cast(*Base_Entry_Header) entry_data.data;
    if header.data_offset + header.data_count > entry_data.count {
        log_error("Base entry input data is smaller than the specified size (% < %).",
                  header.data_offset + header.data_count, entry_data.count);
        return false;
    }
    if header.type > #run enum_highest_value(Package.Entry_Type) {
        log_error("Entry header specifies unknown type (0x%).", formatInt(header.type, base=16));
        return false;
    }

    base_entry.data = .{
        header.data_count,
        entry_data.data + header.data_offset
    };
    base_entry.type = xx header.type;
    base_entry.flags = header.flags;
    name = .{
        my_strnlen(package_header.package_name.data, PACKAGE_NAME_MAX),
        package_header.package_name.data
    };
    data = input;
    flags = 0;

    return true;
}

write :: (using package: *Package, filename: string) -> bool {
    file, success := file_open(filename, for_writing=true, log_errors=true);
    if !success  return false;

    package_name := package.name;
    if package_name.count > PACKAGE_NAME_MAX {
        log_error("Package name is too big, truncated to %.", PACKAGE_NAME_MAX);
        package_name.count = PACKAGE_NAME_MAX;
    }

    header: Package_Header;
    header.signature     = PACKAGE_HEADER_SIGNATURE;
    header.version_major = PACKAGE_FORMAT_VERSION_MAJOR;
    header.version_minor = PACKAGE_FORMAT_VERSION_MINOR;
    header.flags = package.flags;
    memcpy(header.package_name.data, package_name.data, package_name.count);

    entry: Base_Entry_Header;
    entry.data_offset = size_of(Base_Entry_Header);
    entry.data_count  = base_entry.data.count;
    entry.type  = xx base_entry.type;
    entry.flags = base_entry.flags;

    zero_byte: u8 = 0;
    // Bundle all file_write errors into one
    success &&= file_write(*file, *header, size_of(Package_Header));
    success &&= file_write(*file, *entry, size_of(Base_Entry_Header));
    success &&= file_write(*file, base_entry.data.data, base_entry.data.count);
    if !success {
        log_error("Could not write to file, package, %.", get_error_string());
        return false;
    }

    expected_pos := size_of(Package_Header) + size_of(Base_Entry_Header) + base_entry.data.count;
    success=, pos := file_tell(*file);
    if !success || pos != expected_pos {
        log_error("Written data count doesn't matche the expected size (% != %).",
                  pos, expected_pos );
        return false;
    }
    
    return true;
}


////////////////////
// String entries

write_string_entry :: (s: string) -> data: []u8 {
    data := NewArray(s.count + size_of(String_Header) + 1, u8, false);
    header := cast(*String_Header) data.data;
    header.signature = START_OF_STRING;
    header.string_count = s.count;
    memcpy(data.data + size_of(String_Header), s.data, s.count);
    data.data[size_of(String_Header) + s.count] = 0; // zero termination

    return data;
}

read_string_entry :: (data: []u8) -> success: bool, result: string {
    result: string = ---;
    if data.count < size_of(String_Header) {
        log_error("String entry data is smaller than a string entry header.");
        return false, result;
    }
    header := cast(*String_Header) data.data;
    if header.signature != START_OF_STRING {
        log_error("String entry signature does not match.");
        return false, result;
    }

    if data.count - size_of(String_Header) < header.string_count {
        log_error("Input data size is smaller than string entry's count.");
        return false, result;
    }

    result = .{header.string_count, data.data + size_of(String_Header)};
    return true, result;
}

////////////////////
// Table entries

write_table_entry :: (entries: []Package.Table_Entry) -> data: []u8 {
    assert(entries.count < xx S32_MAX, "Entry count exceeds maximum number of entries (%).", S32_MAX);
    result: [..]u8;
    sig: u32 = ---;
    array_resize(*result, size_of(Table_Header) + entries.count * size_of(Table_Entry_Header));

    names_offset := result.count;
    // Write signature
    sig = START_OF_NAMES_DATA;
    array_add(*result, .. .{size_of(u32), cast(*u8) *sig});

    // Write entry names
    for entries {
        h := cast(*Table_Entry_Header)
            (result.data + size_of(Table_Header) + it_index * size_of(Table_Entry_Header));
        h.name_count = it.name.count;
        h.name_offset = result.count;

        array_add(*result, .. cast([]u8) it.name);
        array_add(*result, cast(u8) 0); // zero termination
    }

    data_offset := result.count;
    // Write signature
    sig = START_OF_ENTRY_DATA;
    array_add(*result, .. .{size_of(u32), cast(*u8) *sig});

    // Write entry data and finish writing the headers
    for entries {
        h := cast(*Table_Entry_Header)
            (result.data + size_of(Table_Header) + it_index * size_of(Table_Entry_Header));
        h.data_count = it.data.count;
        h.data_offset = result.count;
        h.type = xx it.type;
        h.flags = it.flags;

        array_add(*result, .. it.data);
    }

    // Write the table header
    header := cast(*Table_Header) result.data;
    header.signature = START_OF_TABLE;
    header.entry_count = xx entries.count;
    header.names_data_size_in_bytes = data_offset - names_offset;
    header.entry_data_size_in_bytes = result.count - data_offset;

    return result;
}

read_table_entry :: (data: []u8) -> (success: bool, entries: []Package.Table_Entry) {
    entries: []Package.Table_Entry = ---;
    sig: u32 = ---;

    // Check if data fits all headers
    cursor := size_of(Table_Header);
    if data.count < cursor {
        log_error("Expected table, but input data size is too small to fit a table header.");
        return false, entries;
    }
    header := cast(*Table_Header) data.data;
    cursor += header.entry_count * size_of(Table_Entry_Header);
    if data.count < cursor {
        log_error("Input data size is too small to fit % table entry headers.", header.entry_count);
        return false, entries;
    }

    // Check names data signature and size
    sig = (.*) cast(*u32) (data.data + cursor);
    if sig != START_OF_NAMES_DATA {
        log_error("Start of names data signature does not match");
        return false, entries;
    }
    cursor += header.names_data_size_in_bytes;
    if data.count < cursor {
        log_error("Input data size is too small to fit names data.");
        return false, entries;
    }

    // Check entry data signature and size
    sig = (.*) cast(*u32) (data.data + cursor);
    if sig != START_OF_ENTRY_DATA {
        log_error("Start of entry data signature does not match");
        return false, entries;
    }
    cursor += header.entry_data_size_in_bytes;
    if data.count < cursor {
        log_error("Input data size is too entry to fit entry data.");
        return false, entries;
    }

    // Read entries
    entries = NewArray(header.entry_count, Package.Table_Entry, false);
    for 0..header.entry_count-1 {
        h := cast(*Table_Entry_Header)
            (data.data + size_of(Table_Header) + it * size_of(Table_Entry_Header));

        // Check bounds
        if h.name_offset + h.name_count > cursor || h.data_offset + h.data_count > cursor {
            log_error("table entry %'s data exceeds the table's size.", it);
            free(entries.data);
            return false, .{};
        }

        // Fill entry
        e := *entries[it];
        e.name = .{
            h.name_count,
            data.data + h.name_offset
        };
        e.data = .{
            h.data_count,
            data.data + h.data_offset
        };
        e.type = xx h.type;
        e.flags = h.flags;
    }

    return true, entries;
}

////////////////////
// Array entries

read_array_entry :: (data: []u8) -> (success: bool, result: []Package.Entry) {
    entries: []Package.Entry = ---;
    sig: u32 = ---;

    // Check if data fits all headers
    cursor := size_of(Array_Header);
    if data.count < cursor {
        log_error("Expected array, but input data size is too small to fit an array header.");
        return false, entries;
    }
    header := cast(*Array_Header) data.data;
    cursor += header.entry_count * size_of(Base_Entry_Header);
    if data.count < cursor {
        log_error("Input data size is too small to fit % entry headers.", header.entry_count);
        return false, entries;
    }

    // Check entry data signature and size
    sig = (.*) cast(*u32) (data.data + cursor);
    if sig != START_OF_ENTRY_DATA {
        log_error("Start of entry data signature does not match");
        return false, entries;
    }
    cursor += header.entry_data_size_in_bytes;
    if data.count < cursor {
        log_error("Input data size is too entry to fit entry data.");
        return false, entries;
    }

    // Read entries
    entries = NewArray(header.entry_count, Package.Entry, false);
    for 0..header.entry_count-1 {
        h := cast(*Base_Entry_Header)
            (data.data + size_of(Array_Header) + it * size_of(Base_Entry_Header));

        // Check bounds
        if h.data_offset + h.data_count > cursor {
            log_error("Array entry %'s data exceeds the array's size.", it);
            free(entries.data);
            return false, .{};
        }

        // Fill entry
        e := *entries[it];
        e.data = .{
            h.data_count,
            data.data + h.data_offset
        };
        e.type = xx h.type;
        e.flags = h.flags;
    }

    return true, entries;
}

write_array_entry :: (entries: []Package.Entry) -> data: []u8 {
    result: [..]u8;
    sig: u32 = ---;
    array_resize(*result, size_of(Array_Header) + entries.count * size_of(Base_Entry_Header));

    data_offset := result.count;
    // Write signature
    sig = START_OF_ENTRY_DATA;
    array_add(*result, .. .{size_of(u32), cast(*u8) *sig});

    // Write entry data and finish writing the headers
    for entries {
        h := cast(*Base_Entry_Header)
            (result.data + size_of(Array_Header) + it_index * size_of(Base_Entry_Header));
        h.data_count = it.data.count;
        h.data_offset = result.count;
        h.type = xx it.type;
        h.flags = it.flags;

        array_add(*result, .. it.data);
    }

    // Write the array header
    header := cast(*Array_Header) result.data;
    header.signature = START_OF_ARRAY;
    header.entry_count = xx entries.count;
    header.entry_data_size_in_bytes = result.count - data_offset;

    return result;
}

////////////////////
// Array of data entries

write_array_of_data_entry :: (input: *void, count: s64, element_size: s64) -> data: []u8 {
    assert(element_size < xx S32_MAX, "Element size exceeds maximum size.", S32_MAX);
    size_in_bytes := count * element_size;
    data := NewArray(size_of(Array_Of_Data_Header) + size_of(u32) + size_in_bytes, u8, false);
    h := cast(*Array_Of_Data_Header) data.data;
    h.signature = START_OF_ARRAY;
    h.element_size = xx element_size;
    h.element_count = count;
    (.*) cast(*u32) (data.data + size_of(Array_Of_Data_Header)) = START_OF_ARRAY;
    memcpy(data.data + size_of(Array_Of_Data_Header) + size_of(u32), input, size_in_bytes);
    return data;
}

read_array_of_data_entry :: (data: []u8) -> success: bool, data: []u8, element_count: s64, element_size: s32 {
    result: []u8 = ---;
    if data.count < size_of(Array_Of_Data_Header) + size_of(u32) {
        log_error("Array of Data entry size is smaller than the size of a header + signature.");
        return false, result, 0, 0;
    }

    h := cast(*Array_Of_Data_Header) data.data;
    if (.*) cast(*u32) (data.data + size_of(Array_Of_Data_Header)) != START_OF_ARRAY {
        log_error("Array of Data signature does not match.");
        return false, result, 0, 0;
    }
    remaining := []u8.{
        data.count - size_of(Array_Of_Data_Header) - size_of(u32),
        data.data  + size_of(Array_Of_Data_Header) + size_of(u32)
    };

    if remaining.count < h.element_count * h.element_size {
        log_error("Array of data size is smaller than expected. (% < (% * %)).",
                  remaining.count, h.element_count, h.element_size);
        return false, result, 0, 0;
    }

    result = remaining;
    return true, result, h.element_count, h.element_size;
}

////////////////////
// Serialization

write_entry :: (item: Any) -> (type: Package.Entry) {
    item_type := resolve_variant(item.type);
    if item_type.type == {
    case .STRUCT;
        info := cast(*Type_Info_Struct) item_type;
        if struct_is_trivial(info) {
            // Struct is marked as @trivial, so write it as plain data.
            return .{
                data=.{info.runtime_size, item.value_pointer},
                type=.DATA,
            };
        }

        result: [..]Package.Table_Entry; // @Memory:

        highest_offset := -1;
        for info.members {
            if it.flags & (.CONSTANT | .IMPORTED)   continue;
            if it.offset_in_bytes < highest_offset  continue;
            if it.type.runtime_size == 0            continue;
            highest_offset = it.offset_in_bytes + it.type.runtime_size;

            name := it.name;
            params := parse_member_notes(it.notes);
            if params.flags & (.SKIP | .NO_WRITE)  continue;

            member := Any.{
                it.type,
                item.value_pointer + it.offset_in_bytes
            };
            e := write_entry(member);
            array_add(*result, .{ it.name, e });
        }

        return .{
            data=write_table_entry(result),
            type=TABLE_OF_ENTRIES,
        };

    case .ARRAY;
        info := cast(*Type_Info_Array) item_type;

        src_data: *void = ---;
        src_count: s64 = ---;
        if info.array_type == .FIXED {
            src_data  = item.value_pointer;
            src_count = info.array_count;
        } else {
            a := cast(*[]void) item.value_pointer;
            src_data  = a.data;
            src_count = a.count;
        }
        if src_count == 0 || src_data == null {
            return .{
                data=write_array_entry(.[]),
                type=ARRAY_OF_ENTRIES,
            };
        }

        element_type := resolve_variant(info.element_type);
        if is_trivially_copyable(element_type.type) ||
           (element_type.type == .STRUCT && struct_is_trivial(xx element_type)) {
            // Element type is trivially copiable, so write as array of data.
            return .{
                data=write_array_of_data_entry(src_data, src_count, element_type.runtime_size),
                type=.ARRAY_OF_DATA,
            };
        } else {
            // Write as array of entries
            result := NewArray(src_count, Package.Entry, false);
            for 0..src_count-1 {
                element := Any.{
                    element_type,
                    src_data + it * element_type.runtime_size,
                };

                result[it] = write_entry(element);
            }

            return .{
                data=write_array_entry(result),
                type=ARRAY_OF_ENTRIES,
            };
        }

    case .STRING;
        s := (.*) cast(*string) item.value_pointer;
        return .{
            data=write_string_entry(s),
            type=STRING,
        };

    // Trivially copyable types
    case .INTEGER; #through;
    case .FLOAT;   #through;
    case .BOOL;    #through;
    case .ENUM;
        size := item_type.runtime_size;
        data := NewArray(size, u8, false);
        memcpy(data.data, item.value_pointer, size);

        return .{
            data=data,
            type=.DATA,
        };

    }

    return .{};
}

read_entry :: (item: Any, entry: *Package.Entry) -> success: bool {
    auto_release_temp();
    item_type := resolve_variant(item.type);
    if item_type.type == {
    case .STRUCT;
        info := cast(*Type_Info_Struct) item_type;
        if entry.type == .DATA && struct_is_trivial(info) {
            // Got plain data and struct is marked as @trivial
            if entry.data.count > info.runtime_size {
                log_error("While reading struct marked as @trivial, runtime size does not match.");
                return false;
            }
            memcpy(item.value_pointer, entry.data.data, info.runtime_size);
            return true;
        }

        if entry.type != .TABLE_OF_ENTRIES {
            log_error("While reading struct, expected table of entries, got %.");
            return false;
        }
        success, table := read_table_entry(entry.data);
        if !success {
            log_error("- %", info.name);
            return false;
        }

        // Handle struct members
        highest_offset := -1;
        for info.members {
            if it.flags & (.CONSTANT | .IMPORTED)   continue;
            if it.offset_in_bytes < highest_offset  continue;
            if it.type.runtime_size == 0            continue;
            highest_offset = it.offset_in_bytes + it.type.runtime_size;

            name := it.name;
            params := parse_member_notes(it.notes);
            if params.flags & (.SKIP | .NO_READ)  continue;
            if params.flags & .OLD_NAME  name = params.replacement_name;

            e := find(table, name);
            if !e  continue;

            member := Any.{
                it.type,
                item.value_pointer + it.offset_in_bytes
            };
            success = read_entry(member, e);
            // We keep going even if an member fails
        }

        return true;

    case .ARRAY;
        info := cast(*Type_Info_Array) item_type;
        element_type := resolve_variant(info.element_type);

        array: []void = ---;
        if entry.type == .ARRAY_OF_DATA && (is_trivially_copyable(element_type.type) ||
           (element_type.type == .STRUCT && struct_is_trivial(xx element_type))) {
            // Read array of data
            success, a, element_count, element_size := read_array_of_data_entry(entry.data);
            if !success  return false;
            if element_size != element_type.runtime_size {
                log_error("Array of data element size does not match the array element type's size.");
                return false;
            }
            array.data = a.data;
            array.count = element_count;
        } else if entry.type == .ARRAY_OF_ENTRIES {
            // Read array of entries
            success, elements := read_array_entry(entry.data);
            if !success  return false;

            array.data  = talloc(elements.count * element_type.runtime_size);
            array.count = elements.count;
            for * elements {
                element := Any.{
                    element_type,
                    array.data + it_index * element_type.runtime_size,
                };
                success = read_entry(element, it);
                // We keep going even if an element fails
            }
        } else {
            log_error("Expected array of entries, got %.", entry.type);
            return false;
        }

        // Write the array
        if info.array_type == .FIXED {
            if array.count > info.array_count {
                log_error("Input array count is greater than fixed array's size, truncating...");
                array.count = info.array_count;
            }
            memcpy(item.value_pointer, array.data, array.count * element_type.runtime_size);
        } else {
            a := cast(*[]void) item.value_pointer;
            a.count = array.count;
            a.data = alloc(array.count * element_type.runtime_size);
            memcpy(a.data, array.data, array.count * element_type.runtime_size);
        }

        return true;

    case .STRING;
        if entry.type != .STRING {
            log_error("Expected string entry, got %.", entry.type);
            return false;
        }

        success, s := read_string_entry(entry.data);
        if !success  return false;

        (.*) cast(*string) item.value_pointer = s;
        return true;

    // Trivially copyable types
    case .INTEGER; #through;
    case .FLOAT;   #through;
    case .BOOL;    #through;
    case .ENUM;
        size := item_type.runtime_size;
        if entry.data.count != size {
            log_error("For trivially copiable type %, expected size %, but found %.",
                      item_type.type, size, entry.data.count);
            return false;
        }
        memcpy(item.value_pointer, entry.data.data, size);
        return true;
    }

    // Anything else is not serializable, so we return success.
    return true;
}


////////////////////
// Logging

print_indent :: inline (amount: s64, multiplier := 2) -> string {
    SPACES :: #run -> string {
        array: [128]u8 = ---;
        memset(array.data, #char " ", array.count);
        return xx add_global_data(array, .READ_ONLY); 
    }
    return .{min(amount * multiplier, SPACES.count), SPACES.data};
}

do_revert_escapes :: (input: string, skip_newlines: bool) -> string {
    // Prepass to count escapes
    escapes := 0;
    for input  if is_any(it, "\n\r\e\t")  escapes += 1;
    output := cast(string) NewArray(input.count + escapes, u8, false,, temp);

    offset := 0;
    for c, i: input {
        if c == {
        case #char "\n";
            if skip_newlines {
                output[i + offset] = c;
                continue;
            }
            c = #char "n";
        case #char "\r"; c = #char "r";
        case #char "\e"; c = #char "e";
        case #char "\t"; c = #char "t";
        case;
            output[i + offset] = c;
            continue;
        }

        output[i + offset] = #char "\\";
        output[i + offset + 1] = c;
        offset += 1;
    }

    return output;
}

Revert_Escapes :: enum { NO; ALL_EXCEPT_NEWLINES; ALL; }

Log_Entry_Data :: struct {
    revert_escapes: Revert_Escapes;
    print_raw_data: bool;
    recursive: bool;
}

log_entry :: (entry: Package.Entry, print_raw_data := false, recursive := true,
              revert_escapes := Revert_Escapes.ALL_EXCEPT_NEWLINES) {
    data := Log_Entry_Data.{
        print_raw_data=print_raw_data,
        revert_escapes=revert_escapes,
        recursive=recursive,
    };

    log_entry_visitor :: (entry: Package.Entry, user_data: *void, depth: s64, name: string) -> Entry_Visit_Result {
        assert(user_data != null);
        using data := cast(*Log_Entry_Data) user_data;
    
        log("%| % % (% bytes);\n", print_indent(depth), name, entry.type, entry.data.count);
    
        if entry.type == {
        case .STRING;
            success, str := read_string_entry(entry.data);
            if revert_escapes != .NO  str = do_revert_escapes(str, revert_escapes == .ALL_EXCEPT_NEWLINES);
            if success  log("% \"%\"\n", print_indent(depth+1), str);
        case .DATA;
            size := entry.data.count;
            if size == 1 || size == 2 || size == 4 || size == 8 {
                integer := Type_Info_Integer.{type=.INTEGER, runtime_size=size};
                log("% 0x%\n", print_indent(depth+1), formatInt(Any.{integer, entry.data.data}, base=16));
            } else if print_raw_data {
                log("% %\n", print_indent(depth+1), entry.data);
            }
        case .ARRAY_OF_DATA;
            if print_raw_data {
                success, array, element_count, element_size := read_array_of_data_entry(entry.data);
                if success {
                    for 0..element_count-1 {
                        arr := []u8.{
                            element_size,
                            array.data + it * element_size,
                        };
                        log("% %\n", print_indent(depth+1), arr);
                    }
                }
            }
        }
    
        return ifx data.recursive then .RECURSE else .STOP;
    }

    visit_entry(log_entry_visitor, entry, *data);
}

////////////////////
// Entry Visitor

Entry_Visit_Result :: enum { STOP; RECURSE; }
Entry_Visitor :: #type (entry: Package.Entry, data: *void, depth: s64, name: string) -> Entry_Visit_Result;

visit_entry :: ($$visitor: Entry_Visitor, entry: Package.Entry, data := null, depth := 0, name := "") {
    if visitor(entry, data, depth, name) == .STOP  return;

    if entry.type == .TABLE_OF_ENTRIES {
        success, table := read_table_entry(entry.data);
        if !success  return;

        for table {
            visit_entry(visitor, it, data, depth+1, it.name);
        }
    }

    if entry.type == .ARRAY_OF_ENTRIES {
        success, array := read_array_entry(entry.data);
        if !success  return;

        for array {
            visit_entry(visitor, it, data, depth+1);
        }
    }
}

#scope_file

using Package.Entry_Type;


Package_Header :: struct {
    __padding: [64]u8;
#place __padding;

    signature:     u64;
    version_major: u16;
    version_minor: u16;
    flags:         u32;

    __reserved:    [2]u64;

    package_name:  [PACKAGE_NAME_MAX]u8;

}

String_Header :: struct {
    signature: u32 = START_OF_STRING;
    __padding: u32 = ---;
    string_count: s64;
}

Array_Header :: struct {
    signature:   u32 = START_OF_ARRAY;
    entry_count: s32;
    entry_data_size_in_bytes: s64; // is this redundant ?
}

Array_Of_Data_Header :: struct {
    signature:   u32 = START_OF_ARRAY; // maybe use another signature ?
    element_size:  s32;
    element_count: s64;
}

Table_Header :: struct {
    signature:   u32 = START_OF_TABLE;
    entry_count: s32;
    names_data_size_in_bytes: s64;
    entry_data_size_in_bytes: s64; // is this redundant ?
}

Table_Entry_Header :: struct {
    #as using base: Base_Entry_Header;
    name_offset: s64;
    name_count:  s64;
}

Base_Entry_Header :: struct {
    signature: u32 = START_OF_ENTRY_HEADER;
    type:   u16;
    flags:  u16;
    data_offset: s64;
    data_count:  s64;
}


#assert size_of(Package_Header)       == 64;
#assert size_of(String_Header)        == 16;
#assert size_of(Array_Header)         == 16;
#assert size_of(Array_Of_Data_Header) == 16;
#assert size_of(Table_Header)         == 24;
#assert size_of(Table_Entry_Header)   == 40;
#assert size_of(Base_Entry_Header)    == 24;

PACKAGE_HEADER_SIGNATURE: u64 : #run (.*) cast(*u64) "PakgData".data;
PACKAGE_FORMAT_VERSION_MAJOR :: 0;
PACKAGE_FORMAT_VERSION_MINOR :: 1;
PACKAGE_NAME_MAX :: 32;

START_OF_ENTRY_HEADER: u32 : #run (.*) cast(*u32) "Ent!".data;
START_OF_ENTRY_DATA:   u32 : #run (.*) cast(*u32) "Dat!".data;
START_OF_NAMES_DATA:   u32 : #run (.*) cast(*u32) "Nam!".data;
START_OF_TABLE:        u32 : #run (.*) cast(*u32) "Map!".data;
START_OF_ARRAY:        u32 : #run (.*) cast(*u32) "Arr!".data;
START_OF_STRING:       u32 : #run (.*) cast(*u32) "Str!".data;

////////////////////
// Utils

get_error_string :: inline () -> string {
    #import "System";
    error_code, description := get_error_value_and_string();
    return description;
}

my_strnlen :: inline (p: *u8, n: s64) -> s64 {
    i := 0;
    while i < n && p[i]  i += 1;
    return i;
}

resolve_variant :: inline (info: *Type_Info) -> *Type_Info {
    while info.type == .VARIANT  info = (cast(*Type_Info_Variant) info).variant_of;
    return info;
}

is_trivially_copyable :: inline (tag: Type_Info_Tag) -> bool {
    return tag == .INTEGER
        || tag == .FLOAT
        || tag == .BOOL
        || tag == .ARRAY;
}

struct_is_trivial :: inline (info: *Type_Info_Struct) -> bool {
    for info.notes {
        if it == "trivial"  return true;
    }
    return false;
}

Struct_Member_Params :: struct {
    flags: enum_flags {
        SKIP;
        NO_WRITE;
        NO_READ;
        OLD_NAME;
    };
    replacement_name: string;
}

parse_member_notes :: inline (notes: []string) -> Struct_Member_Params {
    params: Struct_Member_Params;
    index := 0;
    while index < notes.count {
        defer index += 1;
        note := notes[index];
        if note == {
        case "skip";
            params.flags |= .SKIP;
        case "no_write";
            params.flags |= .NO_WRITE;
        case "no_read";
            params.flags |= .NO_READ;
        case "old_name";
            index += 1;
            if index >= notes.count  break;
            params.replacement_name = notes[index];
            params.flags |= .OLD_NAME;
        }
    }
    return params;
}
```

Y aquí uno de meter cosas directamente en el ejecutable

```
/*
This is the asset bundling/loading system we're using in a game right now.
The “game engine” is a module, and this file is inside that module.
The relevant module parameters are:
    PATH:                 string, // set this to #filepath in your main file
    BUNDLE_ASSETS         := false,
    
    FONT_NAMES:           [] string,
    FONT_FILES:           [] string,
    FONT_SIZES:           [] int,
Example:
    #import "Engine_Module"(
        PATH = #filepath,
        FONT_NAMES = string.[ "DEFAULT"       , "DOCUMENT"          ],
        FONT_FILES = string.[ "nokiafc22.ttf" , "Pixel Georgia.ttf" ],
        FONT_SIZES =    int.[ 8               , 10                  ],
    );
We use pixel sizes for fonts because we are making a pixel art game, but
there's no reason they can't be a fraction of the screen size or something
instead.
In our project directory, we have an “assets” subdirectory, with nested
subdirectories for each asset type: “fonts”, “textures”, “songs”, “sounds”.
This assets system generates an enum for each asset type, with one value per
asset of said type, named with the filename of the asset, sans path and
extension.
So, if we have assets/textures/FOO.png, you refer to its ID with:
    Texture.FOO
Fonts are a little different, because we need that font size metadata --
hence, the module parameter (which could just be constants if your engine
isn't in its own module).
This code makes use of Enumerated_Array from:
  https://github.com/rezich/Enumerated_Array
*/


// Assets system

// Currently the assets system requires all assets of a given type to be in the
// same directory, with no nested subdirectories. This may change in the future.


#scope_export //================================================================


// These are our assets arrays, which are Enumerated_Arrays that you index into
// using enums that we have not defined yet -- we'll get to that in a second.
assets: struct {
    fonts:    Enumerated_Array(Font,    *Simp.Dynamic_Font);
    textures: Enumerated_Array(Texture, Simp.Texture      );
    songs:    Enumerated_Array(Song,    Sound_Data        );
    sounds:   Enumerated_Array(Sound,   Sound_Data        );

    working_directory_set := false;
}

// For example, if you have "FOO.png" texture directory, then you could write:
//
//     some_texture := assets.textures[Font.FOO];
//
// But, because Enumerated_Array generates a union'd struct member for each enum
// name, you can *also* just write this, instead:
//
//     some_texture := assets.textures.FOO;
//

// Fonts have a “font size” metadata value which is why those are defined as
// module parameters -- therefore, we have a couple of helper procedures to get
// font sizes, for convenience.
get_font_size :: inline (font: Font) -> int { return FONT_SIZES[font]; }
get_font      :: inline (font: Font) -> font: *Simp.Dynamic_Font, size: int {
    return assets.fonts[font], FONT_SIZES[font];
}

// We'll define the enums (Font, Texture, Song, Sound) in the next
// #scope_export, in a bit here.


#scope_file //==================================================================


// Now we want to get the files (filenames) and names (filename sans path and
// extension) for each asset in the relevant subdirectories of our assets
// directory. Once we have this information, we can build those enums we needed
// above, plus we can optionally bundle the assets with the executable.

// This is a compile-time only procedure that gets all files in the provided
// relative path, and returns an array of their relative filenames, and an array
// of their names (filename sans path and extension).
Get_Files_And_Names :: (relative_path: string) -> files: [] string, names: [] string #compile_time {
    files, names: [..] string;
    for file_list(sprint("%assets/%", PATH, relative_path)) {
        filename := path_filename(it);
        array_add(*files, filename);
        array_add(*names, path_strip_extension(filename));
    }
    return files, names;
}

// For all assets except fonts, invoke the above procedure, to set these
// constants.
TEXTURE_FILES, TEXTURE_NAMES :: #run,stallable Get_Files_And_Names("textures");
SONG\  _FILES, SONG\  _NAMES :: #run,stallable Get_Files_And_Names("songs"   );
SOUND\ _FILES, SOUND\ _NAMES :: #run,stallable Get_Files_And_Names("sounds"  );

// FONT_FILES, FONT\  _NAMES (along with FONT_SIZES) are defined in module
// parameters, so let's just do a quick check to make sure those are the same
// length.
#assert FONT_NAMES.count == FONT_FILES.count && FONT_FILES.count == FONT_SIZES.count
    "FONT_* parameters have mismatched counts.";


#scope_export //================================================================


// Now let's generate those enums:
#insert -> string { builder: String_Builder;
    Make_Enum :: (kind: string, names: [] string) #expand {
        print_to_builder(*`builder, "% :: enum {\n", kind);
        for names print_to_builder(*`builder, "    %;\n", it);
        append(*`builder, "}\n\n");
    }

    Make_Enum("Font",    FONT_NAMES   );
    Make_Enum("Texture", TEXTURE_NAMES);
    Make_Enum("Song",    SONG_NAMES   );
    Make_Enum("Sound",   SOUND_NAMES  );

    return builder_to_string(*builder);
}


#scope_file //==================================================================


// If the BUNDLE_ASSETS module parameter is set, then we want to bundle all of
// our assets in with the compiled executable.
#if BUNDLE_ASSETS {

    // A “bundled asset” is just an array view into readonly memory in the
    // executable!
    Bundled_Asset :: #type [] u8;

    // Compile-time-only procedure that takes a relative path and a array of
    // filenames within said relative path and return an array of Bundled_Asset.
    Bundle :: (relative_path: string, files: [] string) -> [] Bundled_Asset #compile_time {
        if !files.count then return .[];
        bundled_assets: [..] Bundled_Asset;
        for files {
            filename := tprint("%assets/%0%", PATH, relative_path, it);
            asset, success := read_entire_file(filename);
            if !success then compiler_report(tprint("Unable to read file '%' for bundling!\n", filename));
            array_add(*bundled_assets, add_global_data(xx asset, .READ_ONLY));
        }
        log("Bundled % %", files.count, string.{data=relative_path.data, count=relative_path.count-1});
        return bundled_assets;
    }

    // Bundle each kind of asset using the above procedure.
    BUNDLED_FONTS    :: #run,stallable Bundle("fonts/",    FONT\  _FILES);
    BUNDLED_TEXTURES :: #run,stallable Bundle("textures/", TEXTURE_FILES);
    BUNDLED_SONGS    :: #run,stallable Bundle("songs/",    SONG_\  FILES);
    BUNDLED_SOUNDS   :: #run,stallable Bundle("sounds/",   SOUND_\ FILES);

}


#scope_module //================================================================


// In our main game flow, at some point we want to load assets. Depending on
// whether the BUNDLE_ASSETS module parameter is set, we either want to load
// them from disk (false), or load them from memory, in those constant BUNDLED_*
// arrays we just defined above.
load_assets :: () { using assets;

    // Set the working directory if we haven't already.
    if !working_directory_set {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        working_directory_set = true;
    }

    // If the BUNDLE_ASSETS module parameter is true, then we need to load the
    // assets from memory. To do this, we'll build a code string and insert it
    // into the body of this procedure.
    #if BUNDLE_ASSETS then #insert -> string { builder: String_Builder;

        // Helper macro that prints the provided code string to our string
        // builder, with:
        //   %1 = asset name
        //   %2 = asset index
        Unbundle :: (names: [] string, code_string: string) #expand {
            for names print(*`builder, code_string, it, it_index);
        }

        // Font
        Unbundle(FONT_NAMES, #string JAI
            fonts.%1 = Simp.get_font_at_size(BUNDLED_FONTS[%2], FONT_SIZES[%2]);
        JAI);

        // Texture
        Unbundle(TEXTURE_NAMES, #string JAI
            { success := Simp.texture_load_from_memory(*textures.%1, BUNDLED_TEXTURES[%2]);
                assert(success,
                    "Failed to load texture '%1' from executable.",
                );
            }
        JAI);

        // Song
        Unbundle(SONG_NAMES, #string JAI
            songs.%1 = load_audio_data("%1", xx BUNDLED_SONGS[%2]);
            assert(songs.%1.loaded,
                "Failed to load song '%1' from executable.",
            );
        JAI);

        // Sound
        Unbundle(SOUND_NAMES, #string JAI
            sounds.%1 = xx load_audio_data("%1", xx BUNDLED_SOUNDS[%2]);
            assert(sounds.%1.loaded,
                "Failed to load sound '%1' from executable.",
            );
        JAI);

        return builder_to_string(*builder);

    }

    // If BUNDLE_ASSETS is false, then we want to load the assets from disk
    // instead.
    else {

        // Font
        for * fonts {
            file, size := FONT_FILES[it_index], FONT_SIZES[it_index];
            it.* = Simp.get_font_at_size("assets/fonts", file, size);
            assert(!!it.*,
                "Failed to load font '%' from file.",
                it_index, file, size
            );
        }

        // Texture
        for * textures {
            success := Simp.texture_load_from_file(it, tprint("%assets/textures/%", PATH, TEXTURE_FILES[it_index]));
            assert(success,
                "Failed to load texture '%' from file.",
                TEXTURE_FILES[it_index]
            );
        }

        // Song
        for * songs {
            file := tprint("assets/songs/%", SONG_FILES[it_index]);
            it.* = load_audio_file(file);
            assert(it.loaded,
                "Failed to load song '%1' from file %2.",
                SONG_NAMES[it_index],
                file
            );
        }

        // Sound
        for * sounds {
            file := tprint("assets/sounds/%", SOUND_FILES[it_index]);
            it.* = load_audio_file(file);
            assert(it.loaded,
                "Failed to load sound '%1' from file %2.",
                SOUND_NAMES[it_index],
                file
            );
        }

    }

}
```