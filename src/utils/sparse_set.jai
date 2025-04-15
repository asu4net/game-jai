Sparse_Set :: struct {
    NULL :: U32_MAX; 
    sparse   : [..] u32;
    dense    : [..] u32;
    count    : u32;
    capacity : u32;        
}

initialized :: (using s : *Sparse_Set) -> bool {
    return sparse.data != null && dense.data != null && capacity > 0;
}

init :: (using s : *Sparse_Set, start_capacity : u32 = 30) {
    assert(!initialized(s));
    assert(start_capacity < Sparse_Set.NULL);
    capacity = start_capacity;
    array_resize(*sparse, capacity);
    array_resize(*dense, capacity);
    for * sparse it.* = Sparse_Set.NULL;
    for * dense  it.* = Sparse_Set.NULL;
}

deinit :: (using s : *Sparse_Set) {
    assert(initialized(s));
    array_reset(*sparse);
    array_reset(*dense);
    s.* = .{};
}

test :: (using s : *Sparse_Set, element : u32) -> bool {
    assert(initialized(s));
    return element < capacity && sparse[element] < count;
}

search :: (using s : *Sparse_Set, element : u32) -> u32 {
    assert(initialized(s));
    assert(test(s, element));
    dense_index := sparse[element];
    return dense_index;
}

is_full :: (using s : *Sparse_Set) -> bool {
    assert(initialized(s));
    assert(count <= capacity);
    return count == capacity;
}

insert_id :: (using s : *Sparse_Set, element : u32) -> u32 {
    assert(initialized(s));
    // If it is full just grow the sparse and dense arrays and increase the capacity
    if is_full(s) {
        array_add(*sparse, Sparse_Set.NULL);
        array_add(*dense,  Sparse_Set.NULL);
        capacity = xx sparse.allocated;
        assert(capacity < Sparse_Set.NULL);
    }
    assert(element < capacity && !test(s, element));
    assert(!is_full(s));
    next_slot := count;
    sparse[element] = next_slot;
    dense[next_slot] = element;
    count+=1;
    return next_slot;
}

remove_id :: (using s : *Sparse_Set, element : u32) -> u32, u32 {
    assert(initialized(s));
    assert(element < capacity && test(s, element));
    
    deleted := sparse[element];
    last    := count;
    
    sparse[element] = Sparse_Set.NULL;
    count -= 1;

    if deleted != last {
        last_element := dense[last];
        dense[deleted] = last_element;
        sparse[last_element] = deleted;
    }

    return deleted, last;
}