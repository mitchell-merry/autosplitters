state("Christmas Massacre") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.LoadSceneManager = true;
    vars.Helper.AlertLoadless();
    // vars.Helper.Settings.CreateFromXml("Components/ChristmasMassacre.Settings.xml");
}

update
{
    current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;

    if(current.activeScene != old.activeScene) vars.Log("a: " + old.activeScene + ", " + current.activeScene);
    if(current.loadingScene != old.loadingScene) vars.Log("l: " + old.loadingScene + ", " + current.loadingScene);
}


start
{
   if (current.activeScene == "02 Catholic Scene" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "02 Catholic Scene" && old.activeScene == "01 Intro Cutscene") return true;

   if (current.activeScene == "05 House 1st Floor" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "09 Store" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "12 House 1" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "16 Brothal" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "20 Theater" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "25 Catholic School Return 1" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "32 Asylum Escape" && old.activeScene == "00 Main Menu with Level select") return true;
   if (current.activeScene == "33 Training" && old.activeScene == "00 Main Menu with Level select") return true;
}

split
{
    if (old.loadingScene != current.loadingScene) {
        if (current.activeScene == "02 Catholic Scene" && current.loadingScene == "03 Larry's House 0 new") return true;

        if (current.activeScene == "03 Larry's House 0 new" && current.loadingScene == "04 Approach House") return true;
        if (current.activeScene == "04 Approach House" && current.loadingScene == "05 House 1st Floor") return true;
        if (current.activeScene == "05 House 1st Floor" && current.loadingScene == "06 House 2nd Floor") return true;
        if (current.activeScene == "06 House 2nd Floor" && current.loadingScene == "07 Larry's House 1") return true;
        if (current.activeScene == "07 Larry's House 1" && current.loadingScene == "08 Approach Store") return true;
        if (current.activeScene == "08 Approach Store" && current.loadingScene == "09 Store") return true;
        if (current.activeScene == "09 Store" && current.loadingScene == "10 Larry's House 2 new") return true;
        if (current.activeScene == "10 Larry's House 2 new" && current.loadingScene == "11 Approach House 2") return true;
        if (current.activeScene == "11 Approach House 2" && current.loadingScene == "12 House 1") return true;
        if (current.activeScene == "12 House 1" && current.loadingScene == "13 House 2") return true;
        if (current.activeScene == "13 House 2" && current.loadingScene == "14 Larry's House 3 new") return true;
        if (current.activeScene == "14 Larry's House 3 new" && current.loadingScene == "15 Approach Brothal") return true;
        if (current.activeScene == "15 Approach Brothal" && current.loadingScene == "16 Brothal") return true;
        if (current.activeScene == "16 Brothal" && current.loadingScene == "17 Concert") return true;
        if (current.activeScene == "17 Concert" && current.loadingScene == "18 Larry's House 4") return true;
        if (current.activeScene == "18 Larry's House 4" && current.loadingScene == "19 Approach Theater") return true;
        if (current.activeScene == "19 Approach Theater" && current.loadingScene == "20 Theater") return true;
        if (current.activeScene == "20 Theater" && current.loadingScene == "21 Larry's House 5") return true;
        if (current.activeScene == "21 Larry's House 5" && current.loadingScene == "22 Morgue") return true;
        if (current.activeScene == "22 Larry's House 6" && current.loadingScene == "24 Catholic School Outside 0") return true;
        if (current.activeScene == "24 Catholic School Outside 0" && current.loadingScene == "25 Catholic School Return 1") return true;
        if (current.activeScene == "25 Catholic School Return 1" && current.loadingScene == "26 Catholic School Return 2") return true;
        if (current.activeScene == "26 Catholic School Return 2" && current.loadingScene == "27 Catholic School Return 3") return true;
        if (current.activeScene == "27 Catholic School Return 3" && current.loadingScene == "28 Catholic School Return 4") return true;
        if (current.activeScene == "28 Catholic School Return 4" && current.loadingScene == "29 Catholic School Outside 5") return true;
        if (current.activeScene == "30 Larry's House 7 end" && current.loadingScene == "31 Asylum Cutscene") return true;

        if (current.activeScene == "32 Asylum Escape" && current.loadingScene == "00 Main Menu with Level select") return true;
        if (current.activeScene == "33 Training" && current.loadingScene == "00 Main Menu with Level select") return true;
    }
}

isLoading
{
    return current.activeScene != current.loadingScene;
}