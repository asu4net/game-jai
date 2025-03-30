/////////////////////////////
//:Sparse_Set
/////////////////////////////

Sparse_Set :: struct {
    sparse   : []u32;
    dense    : []u32;
    count    : u32;
    capacity : u32;        
}

sparse_initialized :: (sparse_set : *Sparse_Set) -> bool {
    using sparse_set;
    return sparse.data != null && dense.data != null && capacity > 0;
}

sparse_init :: (sparse_set : *Sparse_Set, cap : u32) {
    using sparse_set;
    assert(!sparse_initialized(sparse_set));
    capacity = cap + 1; //zero represents the invalid value
    sparse = NewArray(capacity, u32);
    dense  = NewArray(capacity, u32);
    memset(dense.data, 0, capacity * size_of(u32));
    memset(sparse.data, 0, capacity * size_of(u32));
}

sparse_deinit :: (sparse_set : *Sparse_Set) {
    assert(sparse_initialized(sparse_set));
    using sparse_set;
    free(sparse.data);
    free(dense.data);
    sparse_set.* = .{};
}

sparse_test :: (sparse_set : *Sparse_Set, element : u32) -> bool {
    using sparse_set;
    assert(sparse_initialized(sparse_set));
    return element < capacity && sparse[element] < count + 1 && sparse[element] != 0;
}

sparse_search :: (sparse_set : *Sparse_Set, element : u32) -> u32 {
    using sparse_set;
    assert(sparse_initialized(sparse_set) && element != 0);
    assert(sparse_test(sparse_set, element));
    dense_index := sparse[element];
    return dense_index;
}

sparse_is_full :: (sparse_set : *Sparse_Set) -> bool {
    using sparse_set;
    assert(sparse_initialized(sparse_set));
    assert(count <= capacity);
    return count == capacity;
}

sparse_insert :: (sparse_set : *Sparse_Set, element : u32) -> u32 {
    using sparse_set;
    assert(sparse_initialized(sparse_set));
    assert(element < capacity && !sparse_test(sparse_set, element));
    assert(!sparse_is_full(sparse_set));
    next_slot := count + 1;
    sparse[element] = next_slot;
    dense[next_slot] = element;
    count+=1;
    return next_slot;
}

sparse_remove :: (sparse_set : *Sparse_Set, element : u32) -> u32, u32 {
    using sparse_set;
    assert(sparse_initialized(sparse_set));
    assert(element < capacity && sparse_test(sparse_set, element));
    
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
    using sparse_set : Sparse_Set;
    
}

#import "Basic";
#import "Math";