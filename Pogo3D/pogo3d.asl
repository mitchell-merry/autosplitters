state("pogo") { }

startup
{
    vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Pogo3D";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.Settings.CreateFromXml("Components/Pogo3D.Settings.xml");

    vars.CompletedSplits = new HashSet<string>();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var pgm = mono["PogoGameManager", 1];
        var chd = mono["ChapterDescriptor"];
        var pc = mono["PlayerController"];
        var gpt = mono["GameProgressTracker"];

        vars.Helper["chapter"] = mono.Make<int>(
            pgm,
            "GameInstance",
            pgm["currentChapter"],
            chd["Number"]
        );

        vars.Helper["paused"] = mono.Make<bool>(
            pgm,
            "GameInstance",
            pgm["paused"]
        );
        
        vars.Helper["playerState"] = mono.Make<int>(
            pgm,
            "GameInstance",
            pgm["player"],
            pc["currentState"]
        );
        
        vars.Helper["startTime"] = mono.Make<int>(
            pgm,
            "GameInstance",
            pgm["currentChapterProgressTracker"],
            gpt["startTime"]
        );

        return true;
    });

    vars.ReadSceneName = (Func<IntPtr, string>)(scene => {
        // this seems to work best?
        string name = vars.Helper.ReadString(256, ReadStringType.UTF8, scene + 0x38);
        return name == "" ? null : name;
    });

    vars.CheckSplit = (Func<string, bool>)(key => {
        // if the split doesn't exist, or it's off, or we've done it already
        if (!settings.ContainsKey(key)
          || !settings[key]
          || !vars.CompletedSplits.Add(key)
        ) {
            return false;
        }

        vars.Log("Completed: " + key);
        return true;
    });
}

update
{
    current.scene = vars.ReadSceneName(vars.Helper.Scenes.Loaded[0].Address);
    vars.Watch("chapter");
    vars.Watch("paused");
    vars.Watch("playerState");
    vars.Watch("startTime");
    if (old.scene != current.scene) vars.Log("scene: " + old.scene + " -> " + current.scene);
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.scene);
    vars.Log(current.chapter);
    vars.Log(current.paused);
    vars.Log(current.playerState);
    vars.Log(current.startTime);
}

isLoading
{
    return current.paused || current.playerState == 1;

}

start
{
    return old.startTime < current.startTime;
    // return old.scene == "MainMenu" && (current.scene == "C1L1" || current.scene == "C2L1");
}

split
{
    if (settings["chapter"]) {
        if (old.chapter < current.chapter) {
            return vars.CheckSplit("chapter_" + old.chapter) || vars.CheckSplit("chapter_start_" + current.chapter);
        }

        if (old.chapter == 4 && current.chapter == 1 && current.scene == "C5L1") {
            return vars.CheckSplit("chapter_yard");
        }
    }

    return old.scene != current.scene && current.scene == "Credits";
}

reset
{
    return old.scene != current.scene && current.scene == "MainMenu";
}