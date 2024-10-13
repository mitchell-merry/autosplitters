uint64_t UPPER_32 = 0xFFFFFFFF00000000;
uint64_t LOWER_32 = 0x00000000FFFFFFFF;
uint64_t LOWER_16 = 0x000000000000FFFF;
uint64_t LOWER_8  = 0x00000000000000FF;

uint8_t* unknown1 = 0; // TEW2.exe+245BB21
char* EMPTY_STRING = 0xD8EC4F1E48;

char* readString(uint64_t rcx, uint64_t rdx, uint64_t r8, uint64_t r9) {
    /* Stack Nonsense */
    // mov [rsp+08],rbx
    // push rdi
    // sub rsp,20

    /* checking if we should return the empty string early */
    // cmp byte ptr [],00
    // mov rbx,rdx
    // mov rdi,rcx
    // jne TEW2.exe+26E36E
    // call TEW2.exe+26E380
    // mov r9d,eax
    // cmp eax,-01
    // je TEW2.exe+26E36E

    uint64_t rax;

    uint64_t rbx = rdx;
    uint64_t rdi = rcx;

    if (*unknown1 == 0) {
        // mov rax,rbx
        return EMPTY_STRING;
    }

    // ?? RAX looks like, e.g.: 0x406
    rax = some_other_function();

    uint32_t eax = rax & LOWER_32;
    r9 = (r9 & UPPER_32) | eax;

    if (eax == -1) {
        // mov rax,rbx
        return EMPTY_STRING;
    }

    /* the core Bit */
    // mov rax,[rdi+60]
    // movzx ecx,r9w
    // movzx edx,cl
    
    // shr r9d,08
    // movzx ecx,r9w
    // add rcx,rcx
    // lea r8,[rdx+rdx*2]
    // mov rax,[rax+r8*8]
    // mov rax,[rax+rcx*8+08]
    // test rax,rax

    // possibly a field on an instance or something
    // maybe a list of arrays of strings? 0x68 and 0x70 are
    // like size / capacity, so 0x60 is probably a TArray<char**>
    rax = *(rdi + 0x60);

    // maybe getting fields on a struct?
    rcx = r9 & LOWER_16;
    rdx = rcx & LOWER_8;

    r9 = r9 >> 0x8;
    rcx = r9 & LOWER_16;
    rcx = rcx * 0x2;

    // these structs are 0x3 * 0x8 big (0x18)
    r8 = rdx * 0x3;
    rax = *(rax + r8 * 0x8);
    rax = *(rax + rcx * 0x8 + 0x8);

    if (rax == 0) {
        // mov rax,rbx
        return EMPTY_STRING;
    }
    
    /* Stack Nonsense */
    // mov rbx,[rsp+30]
    // add rsp,20
    // pop rdi
    // ret 

    return (char*)rax;
}