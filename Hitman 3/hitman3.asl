// how to find the values & what they mean are in the README.md file
state("HITMAN3") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Hitman WoA: Freelancer";
    vars.Helper.AlertGameTime();
}

init
{
    // in short, each of these signatures match one section in the assembly that contain a reference to the
    //   memory address we want to find. we scan that signature, once we find it we add the 0x5 or whatever offset
    //   from the beginning of the signature to get the address
    // some magic behind the scenes converts that from a relative address to an absolute one
    // find this by looking at what instructions write to your addresses, then work backwards to find where the address
    //   comes from with cheat engine's stack trace

    // 75 13                 - jne hitman3.AK::WriteBytesMem::Count+1504
    // 48 8B 05 ????????     - mov rax,[hitman3.exe+????????]
    // 48 8D 0D ????????     - lea rcx,[hitman3.exe+????????]
    // B2 01                 - mov dl,01
    var isLoadingBase = vars.Helper.ScanRel(0x5, "75 13 48 8B 05 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? B2 01");
    vars.Helper["isLoading"] = vars.Helper.Make<bool>(isLoadingBase + 0x3C);
    vars.Log(vars.Helper["isLoading"].ToString());

    // 48 89 35 ????????     - mov [hitman3.exe+????????],rsi
    // 48 8D 0D ????????     - lea rcx,[hitman3.exe+????????]
    // 40 88 35 ????????     - mov [hitman3.exe+????????],sil
    var isInMainMenuBase = vars.Helper.ScanRel(0xA, "48 89 35 ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? 40 88 35");
    vars.Helper["isInMainMenu"] = vars.Helper.Make<bool>(isInMainMenuBase + 0x194);
    vars.Log(vars.Helper["isInMainMenu"].ToString());

    // 88 44 24 20           - mov [rsp+20],al
    // E8 ????????           - call hitman3.exe+????????
    // FF 0D ????????        - dec [hitman3.exe+????????]
    var inCutsceneBase = vars.Helper.ScanRel(0xB, "88 44 24 ?? E8 ?? ?? ?? ?? FF 0D");
    vars.Helper["inCutscene"] = vars.Helper.Make<bool>(inCutsceneBase + 0x0);
    vars.Log(vars.Helper["inCutscene"].ToString());

    // find this by doing the inverse of usingCamera
    // this one appears to be the most shakey, so I've included more of the surrounding opcodes to see if you can forge a stronger signature (if this breaks again)
    // 2025/10/03 - Happened again. No luck besides just updating the signature.
    // 48 8B D0              - mov rdx,rax
    // 48 C1 EA ??           - shr rdx,??
    // C6 05 ???????? 01     - mov byte ptr [hitman3.exe+????????],01
    // 80 E2 01              - and dl,01
    // 74 ??                 - je hitman3.exe+????????
    // 0FB6 C0               - movzx eax,al
    // EB ??                 - jmp hitman3.exe+????????
    // 48 8B 05 ????????     - mov rax,[hitman3.exe+????????]
    var hasControlBase = vars.Helper.ScanRel(0x9, "4C 8B C0 49 C1 E8 ?? C6 05 ?? ?? ?? ?? 01");
    vars.Helper["hasControl"] = vars.Helper.Make<bool>(hasControlBase + 0x1);
    vars.Log(vars.Helper["hasControl"].ToString());

    // 48 8B CB              - mov rcx,rbx
    // 48 89 1D ????????     - mov [hitman3.exe+????????],rbx
    // EB ??                 - jmp hitman3.exe+????????
    // 48 39 1D ????????     - cmp [hitman3.exe+????????],rbx
    // Note: ?? the jmp byte amount because I have had that change before
    var usingCameraBase = vars.Helper.ScanRel(0x6, "48 8B CB 48 89 1D ?? ?? ?? ?? EB ?? 48 39 1D");
    vars.Helper["usingCamera"] = vars.Helper.Make<bool>(usingCameraBase + 0x4);
    vars.Log(vars.Helper["usingCamera"].ToString());


    // assume we are not in the intro cutscene on init
    // this does technically mean if the timer is opened and started during the intro cutscene, it will falsely pause
    // but this doesn't actually matter at all
    vars.inIntroCutscene = false;
}

update
{
    // load new values from set pointers in init {} into current
    // https://github.com/just-ero/asl-help/blob/main/src/Basic/Helper/Basic.Pointers.cs
    vars.Helper.Update();
    vars.Helper.MapPointers();


    // if we have just loaded in, we are in an intro cutscene
    // (or the main menu, which is paused regardless anyway)
    if (old.isLoading && !current.isLoading) {
        vars.inIntroCutscene = true;
        // vars.Log("in intro cutscene");
    }

    // if we were in the intro cutscene, but we have gained control, then the cutscene is over
    if (vars.inIntroCutscene && (
        // Showdown cutscenes - you spawn in with "control" immediately, time should continue when you leave the cutscene
        (current.hasControl && old.inCutscene && !current.inCutscene) ||
        // Other level cutscenes - you don't have control in the beginning, time should continue when you gain it
        (!current.inCutscene && !old.hasControl && current.hasControl)
    )) {
        vars.inIntroCutscene = false;

        // vars.Log("out of intro cutscene");
    }

    // if (old.isLoading != current.isLoading) vars.Log("isLoading: " + old.isLoading + " -> " + current.isLoading);
    // if (old.isInMainMenu != current.isInMainMenu) vars.Log("isInMainMenu: " + old.isInMainMenu + " -> " + current.isInMainMenu);
    // if (old.inCutscene != current.inCutscene) vars.Log("inCutscene: " + old.inCutscene + " -> " + current.inCutscene);
    // if (old.hasControl != current.hasControl) vars.Log("hasControl: " + old.hasControl + " -> " + current.hasControl);
    // if (old.usingCamera != current.usingCamera) vars.Log("usingCamera: " + old.usingCamera + " -> " + current.usingCamera);
}

isLoading
{
    // hasControl is false while using the camera, both are false when we actually don't have control
    // "having control" really means being able to move around and shit
    var reallyHasControl = current.hasControl || current.usingCamera;

    // we're in a cutscene, or we're on a screen we don't have control in (e.g. results screen after level),
    //   and we're not in the intro cutscene (to the safehouse or the level)
    var inCutsceneWeShouldPauseFor = (current.inCutscene || !reallyHasControl) && !vars.inIntroCutscene;

    return current.isLoading    // if we are in a loading screen...
        || current.isInMainMenu // or we're in the main menu...
        || inCutsceneWeShouldPauseFor; // see above
}
