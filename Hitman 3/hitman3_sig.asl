state("hitman3")
{
    // possible sig?
    // 8B 1D ? ? ? ? 48 8D 0D ? ? ? ? FF 15
    // 2
    // +4A
    // bool isLoading: "hitman3.exe", 0x39B0F6C;
    // bool hasTooltip: "hitman3.exe", 0x3176F40;
    // bool isPaused: "hitman3.exe", 0x317B124;
}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.GameName = "HITMAN 3";
}

init
{
    var module = modules.First(x => x.ModuleName == "hitman3.exe");
    var scanner = new SignatureScanner(game, module.BaseAddress, module.ModuleMemorySize);
    var target = new SigScanTarget(2, "8B 1D ?? ?? ?? ?? 48 8D 0D ?? ?? ?? ?? FF 15");
    
    target.OnFound = (proc, sc, address) => {
        var RIPaddr = proc.ReadValue<int>(address);
        return new IntPtr(RIPaddr + 0x48 + (long) address);
    };
    
    IntPtr ptr = scanner.Scan(target);
    vars.isLoading = new MemoryWatcher<bool>(ptr);

    vars.LEVEL_IGT = vars.Helper.ScanRel(0x3, "48 8B 0D ?? ?? ?? ?? 48 89 15 ?? ?? ?? ?? 48 89 05 ?? ?? ?? ??");
    vars.Log(vars.LEVEL_IGT.ToString("X"));
}

onStart
{
    vars.Log(current.LEVEL_IGT);
}

update
{
    vars.isLoading.Update(game);
    current.LEVEL_IGT = vars.Helper.Read<float>(vars.LEVEL_IGT);
}

isLoading
{
    return vars.isLoading.Current;
        // || (current.hasTooltip && !current.isPaused);
}