typedef char uint8_t;
typedef short uint16_t;
typedef long uint32_t;
typedef long long uint64_t;



// struct FName {
//     uint16_t padding[2];
//     // might actually be uint32_t ?
//     uint16_t entry_index;
//     uint16_t slice_index;
// };
// const FNAME_SIZE = sizeof(struct FName);

uint64_t UPPER_32 = 0xFFFFFFFF00000000;
uint64_t LOWER_32 = 0x00000000FFFFFFFF;
uint64_t LOWER_16 = 0x000000000000FFFF;
uint64_t LOWER_8  = 0x00000000000000FF;

// was at 0xD8EC4F1E48 for e.g. 
char* EMPTY_STRING = "";

// global nameManager at TEW2.exe+1EFE730?
struct NameManager {
    uint64_t padding[12];
    // this looks like a TArray<NameSlice>
    struct NameSlice *name_slices;
    uint64_t size_and_capacity;
    // probably other stuff
};

struct NameSlice {
    struct NameEntry *entries;
    uint64_t padding[2];
};

struct NameEntry {
    char* string_key;
    char* string_value;
};

const SLICE_SIZE = sizeof(struct NameSlice);
const ENTRY_SIZE = sizeof(struct NameEntry);

char* getNameValueFromKey(struct NameManager* nameManager, char* nameKey) {
    /* checking if we should return the empty string early */

    // ????? maybe some global flag
    uint8_t* unknown1; // TEW2.exe+245BB21
    if (*unknown1 == 0) {
        return EMPTY_STRING;
    }

    // names look something like: 0x00000406
    uint32_t name = getFNameFromKey(nameManager, nameKey);

    if (name == -1) {
        return EMPTY_STRING;
    }

    struct NameSlice* slices = nameManager->name_slices;

    // probably just getting fields on a struct
    uint8_t  slice_index =  name & 0x000000FF;
    // not actually sure if this needs to be uint16_t, or if it's only ever uint8_t
    uint16_t entry_index = (name & 0x00FFFF00) >> 0x8;

    struct NameSlice slice = slices[slice_index];
    char* nameValue = slice.entries[entry_index].string_value;

    if (nameValue == 0) {
        return EMPTY_STRING;
    }
    
    return nameValue;
}

uint32_t getFNameFromKey(struct NameManager* nameManager, char* nameKey) {
    // TODO implement
    // This example was 0x00000701, which was PRESS ANY KEY (nameKey being #str_dlg_pc_press_start)
    // return (struct FName){ .padding = 0x0, .entry_index = 0x7, .slice_index = 0x1 };
    return 0x00000701;
}