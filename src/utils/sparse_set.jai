/////////////////////////////
//:Sparse_Set
/////////////////////////////

Sparse_Set :: struct {
    sparse   : []u32;
    dense    : []u32;
    count    : u32;
    capacity : u32;        
}

initialized :: (s : *Sparse_Set) -> bool {
    using s;
    return sparse.data != null && dense.data != null && capacity > 0;
}

init :: (s : *Sparse_Set, cap : u32) {
    using s;
    assert(!initialized(s));
    capacity = cap + 1; //zero represents the invalid value
    sparse = NewArray(capacity, u32);
    dense  = NewArray(capacity, u32);
    memset(dense.data, 0, capacity * size_of(u32));
    memset(sparse.data, 0, capacity * size_of(u32));
}

deinit :: (s : *Sparse_Set) {
    assert(initialized(s));
    using s;
    free(sparse.data);
    free(dense.data);
    s.* = .{};
}

test :: (s : *Sparse_Set, element : u32) -> bool {
    using s;
    assert(initialized(s));
    return element < capacity && sparse[element] < count + 1 && sparse[element] != 0;
}

search :: (s : *Sparse_Set, element : u32) -> u32 {
    using s;
    assert(initialized(s) && element != 0);
    assert(test(s, element));
    dense_index := sparse[element];
    return dense_index;
}

is_full :: (s : *Sparse_Set) -> bool {
    using s;
    assert(initialized(s));
    assert(count <= capacity);
    return count == capacity;
}

insert_id :: (s : *Sparse_Set, element : u32) -> u32 {
    using s;
    assert(initialized(s));
    assert(element < capacity && !test(s, element));
    assert(!is_full(s));
    next_slot := count + 1;
    sparse[element] = next_slot;
    dense[next_slot] = element;
    count+=1;
    return next_slot;
}

remove_id :: (s : *Sparse_Set, element : u32) -> u32, u32 {
    using s;
    assert(initialized(s));
    assert(element < capacity && test(s, element));
    
    deleted := sparse[element];
    last    := count - 1;

    sparse[element] = 0;
    count -= 1;

    if deleted != last {
        last_element := dense[last];
        dense[deleted] = last_element;
        sparse[last_element] = deleted;
    }
    
    return deleted, last;
}

Sparse_Array :: struct {
    using s : Sparse_Set;
    
}

#import "Basic";
#import "Math";