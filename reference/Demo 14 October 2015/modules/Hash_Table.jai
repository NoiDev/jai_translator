
TABLE_SIZE_DEFAULT :: 40;

Hash_Record :: struct {
    key:  s64;
    data: *void;
}

Hash_Slot :: struct {
    entries: [..] Hash_Record;
}

Hash_Table :: struct {
    slots:   [..] Hash_Slot;
}

table_resize :: (using table: *Hash_Table, size: s64) {
    array_reserve(*slots, size);
    slots.count = size;
    
    for *slots {  // @Cleanup: Some way to just call the implicit constructor.
        it.entries.count = 0;
        it.entries.allocated = 0;
        it.entries.data = null;
        it.entries.allocator = null;
    }
}


get_hash_slot_index :: (using table: *Hash_Table, key: s64) -> s64 {
    positive := key;
    if positive < 0 positive = -positive;
    return positive % slots.count;
}

table_add :: (using table: *Hash_Table, data: *void, key: s64) {
    if slots.count == 0 table_resize(table, TABLE_SIZE_DEFAULT);

    slot_index := get_hash_slot_index(table, key);

    record: Hash_Record;
    record.key = key;
    record.data = data;

    array := *table.slots[slot_index].entries;

    array_add(array, record);
}

table_find :: (using table: *Hash_Table, key: s64) -> *void {
    if slots.count == 0 return null;
    slot_index := get_hash_slot_index(table, key);

    slot := *table.slots[slot_index];

    for *slot.entries {
        if it.key == key return it.data;
    }

    return null;
}

