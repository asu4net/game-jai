// Dynamically resizable double-ended queue/ring-buffer
Queue :: struct($T: Type) {
	data:   [..]T;
	count:  u32;
	offset: u32;
}

DEFAULT_CAPACITY :: 16;

// procedure to initialize a queue
init :: (q: *Queue($T), capacity := DEFAULT_CAPACITY) {
	clear(q);
	reserve(q, capacity);
}

// procedure to destroy a queue
deinit :: (q: *Queue($T)) {
	array_reset(*q.data);
}

// The count of the queue
count :: (q: Queue($T)) -> int {
	return xx q.count;
}

// The current capacity of the queue
cap :: (q: Queue($T)) -> int {
	return q.data.count;
}

// Remaining space in the queue (cap-count)
space :: (q: Queue($T)) -> int {
	return q.data.count - cast(int) q.count;
}

// Reserve enough space for at least the specified capacity
reserve :: (q: *Queue($T), capacity: int) {
	if capacity > space(q.*) {
		grow(q, cast(u32) capacity);
	}
}

get :: (q: *Queue($T), i: int) -> T {
	//runtime.bounds_check_error_loc(loc, i, q.data.count)
	idx := (cast(u32) i+ q.offset)%q.data.count;
	return q.data[idx];
}

front :: (q: *Queue($T)) -> T {
	return q.data[q.offset];
}

front_ptr :: (q: *Queue($T)) -> *T {
	return *q.data[q.offset];
}

back :: (q: *Queue($T)) -> T {
	idx := (q.offset+ cast(u32) (q.count - 1))%q.data.count;
	return q.data[idx];
}

back_ptr :: (q: *Queue($T)) -> *T {
	idx := (q.offset+ cast(u32) (q.count - 1))%q.data.count;
	return *q.data[idx];
}

set :: (q: *Queue($T),  i: int, val: T) {
	idx := (cast(u32)(i)+q.offset)%q.data.count;
	q.data[idx] = val;
}

get_ptr :: (q: *Queue($T),  i: int) -> *T {
	idx := (cast(u32)(i)+q.offset)%q.data.count;
	return *q.data[idx];
}

peek_front :: (q: *Queue($T), loc := #caller_location) -> *T {
	idx := q.offset%q.data.count;
	return *q.data[idx];
}

peek_back :: (q: *Queue($T), loc := #caller_location) -> *T {
	idx := (cast(u32)(q.count - 1)+q.offset)%q.data.count;
	return *q.data[idx];
}

// Push an element to the back of the queue
push_back :: (q: *Queue($T), elem: T) -> (ok: bool) {
	if space(q.*) == 0 {
		grow(q);
	}
	idx := (q.offset+cast(u32)(q.count))%q.data.count;
	q.data[idx] = elem;
	q.count += 1;
	return true;
}

// Push an element to the front of the queue
push_front :: (q: *Queue($T), elem: T) -> (ok: bool)  {
	if space(q.*) == 0 {
		grow(q);
	}	
	q.offset = cast(u32)(q.offset - 1 + q.data.count) % q.data.count;
	q.count += 1;
	q.data[q.offset] = elem;
	return true;
}

// Pop an element from the back of the queue
pop_back :: (q: *Queue($T)) -> (elem: T) {
	assert(q.count > 0);
	q.count -= 1;
	idx := (q.offset+cast(u32)(q.count))%q.data.count;
	return q.data[idx];
}

// Safely pop an element from the back of the queue
pop_back_safe :: (q: *Queue($T)) -> (elem: T, ok: bool) {
	ok : bool;
	if q.count > 0 {
		q.count -= 1;
		idx := (q.offset+cast(u32)(q.count))%q.data.count;
		elem = q.data[idx];
        ok = true;
    }
	return ok;
}

// Pop an element from the front of the queue
pop_front :: (q: *Queue($T)) -> (elem: T) {
	assert(q.count > 0);
	elem := q.data[q.offset];
	q.offset = (q.offset+1)% cast(u32) q.data.count;
	q.count -= 1;
	return elem;
}

// Safely pop an element from the front of the queue
pop_front_safe :: (q: *Queue($T)) -> (elem: T, ok: bool) {
    ok : bool;
	if q.count > 0 {
		elem := q.data[q.offset];
		q.offset = (q.offset+1)%q.data.count;
		q.count -= 1;
		ok = true;
	}
	return elem, ok;
}

// Consume `n` elements from the front of the queue
consume_front :: (q: *Queue($T), n: int) {
	assert(cast(int) q.count >= n);
	if n > 0 {
		nu := cast(u32) n;
		q.offset = (q.offset + nu) % q.data.count;
		q.count -= nu;	
	}
}

// Consume `n` elements from the back of the queue
consume_back :: (q: *Queue($T), n: int) {
	assert(cast(int) q.count >= n);
	if n > 0 {
		q.count -= cast(u32) n;
	}
}

// Clear the contents of the queue
clear :: (q: *Queue($T)) {
	q.count = 0;
	q.offset = 0;
}

#scope_module

// Internal growing procedure
grow :: (q: *Queue($T), min_capacity: u32 = 0) {
	new_capacity := max(min_capacity, cast(u32) 8, cast(u32) q.data.count*2);
    n := cast(u32) q.data.count;
    array_resize(*q.data, cast(int) new_capacity);
    if q.offset + q.count > n {
        diff := n - q.offset;
        for i : 0..diff-1 {
            q.data[new_capacity - diff + i] = q.data[q.offset + i];
        }
        q.offset += new_capacity - n;
    }
}

//#import "Basic";