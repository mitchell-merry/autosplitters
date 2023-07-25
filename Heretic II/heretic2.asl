state("Heretic2")
{
    // both are good candidates
    bool isLoading: "quake2.dll", 0x76A588;
    // bool isLoading: "quake2.dll", 0x76A5A0;

    string128 scene: "quake2.dll", 0x841B4;
}

startup
{
    vars.Cutscenes = new List<string>() { "intro.smk", "outro.smk" };
    vars.StartScenes = new List<string>() { "tutorial", "ssdocks" };

    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var mbox = MessageBox.Show(
            "\"Heretic II\" uses in-game time.\nWould you like to switch to it?",
            "LiveSplit | \"Heretic II\"",
            MessageBoxButtons.YesNo);

        if (mbox == DialogResult.Yes)
            timer.CurrentTimingMethod = TimingMethod.GameTime;
    }
}

update
{
    if(old.scene != current.scene)
    {
        print("Scene: " + old.scene + " -> " + current.scene);
    }

    if(old.isLoading != current.isLoading)
    {
        print("isLoading: " + old.isLoading + " -> " + current.isLoading);
    }
}

isLoading
{
    return current.isLoading;
}

start
{
    return old.isLoading && !current.isLoading          // start after a load
        && vars.StartScenes.Contains(current.scene);    // if we are loading into a start scene
}

split
{
    return old.scene != current.scene                   // changing scenes
        && old.scene != "" && current.scene != ""        // non-value                                
        && !vars.Cutscenes.Contains(old.scene);         // and we didnt change from a cutscene
}