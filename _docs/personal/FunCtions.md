This document is intended to be a reference for some funCtions (fun functions) that
I find particularly useful, but do not belong in the base templates.

This is meant for me (mitchell) only!

## GetEntries (Traversing a C# Dictionary)
Taken from an old version of the In Sound Mind autosplitter, written a while ago and
completely untested since. Tried adding comments from my recollection.

Reads the `entries` list - could probably be refactored to read into an actual dictionary.

```cs
vars.GetEntries = (Func<IntPtr, int, List<dynamic>>)((dictionary, maxEntries) =>
{
    // function assumes 64 bit

    // entries are 0x18 from the dict
    var ENTRIES_OFFSET = 0x18;

    // data about the entries array
    var LENGTH_OFFSET = 0x18;
    var ITEMS_OFFSET = 0x20;

    // each item is a struct (following is from memory)
    // struct Entry {
    //     int hashCode;
    //     int next;
    //     (type) key;
    //     (type) value;
    // }

    // this code assumes some things about the types of the key and value
    // make sure to change this to suit your needs
    var KEY_SIZE = 0x8;
    var VAL_SIZE = 0x8;
    var ITEM_SIZE = 0x8 + KEY_SIZE + VAL_SIZE;

    // where the key/value are in each item
    var KEY_OFFSET = 0x8;
    var VAL_OFFSET = 0x8 + KEY_SIZE;

    var entries = vars.Helper.Read<IntPtr>(dictionary + ENTRIES_OFFSET);
    var length = vars.Helper.Read<int>(entries + LENGTH_OFFSET);

    var ret = new List<dynamic>();
    for(var i = 0; i < length && i < maxEntries; i++)
    {
        var entryPointer = entries + ITEMS_OFFSET + (i * ITEM_SIZE);

        var key = vars.Helper.Read<IntPtr>(entryPointer + KEY_OFFSET);
        var val = vars.Helper.Read<IntPtr>(entryPointer + VAL_OFFSET);

        dynamic entry = new ExpandoObject();
        entry.key = key;
        entry.value = val;
        ret.Add(entry);
    }

    return ret;
});
```