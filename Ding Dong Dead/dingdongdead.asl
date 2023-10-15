state("DingDongDead") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Ding Dong Dead";
    vars.Helper.LoadSceneManager = true;
    vars.Helper.Settings.CreateFromXml("Components/DingDongDead.Settings.xml");

    vars.Watch = (Action<IDictionary<string, object>, IDictionary<string, object>, string>)((oldLookup, currentLookup, key) => 
    {
        var oldValue = oldLookup[key];
        var currentValue = currentLookup[key];
        if (!oldValue.Equals(currentValue))
            vars.Log(key + ": " + oldValue + " -> " + currentValue);
    });

    vars.CompletedSplits = new HashSet<string>();
    
    vars.Helper.AlertLoadless();
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        // vars.Helper["items"] = mono.MakeList<IntPtr>("KickStarter", "inventoryManagerPrefab", "items");
        vars.Helper["items"] = mono.MakeList<IntPtr>("KickStarter", "runtimeInventoryComponent", "playerInvCollection", "invInstances");

        var InvItem = mono["InvItem"];
        vars.ReadInvItem = (Func<IntPtr, dynamic>)(item =>
        {
            dynamic ret = new ExpandoObject();
            ret.id = vars.Helper.Read<int>(item + InvItem["id"]);
            ret.label = vars.Helper.ReadString(item + InvItem["label"]);
            ret.count = vars.Helper.Read<int>(item + InvItem["count"]);
            return ret;
        });

        var InvInstance = mono["InvInstance"];
        vars.GetInvInstanceId = (Func<IntPtr, int>)(item =>
        {
            return vars.Helper.Read<int>(item + InvInstance["itemID"]);
        });
        // vars.ReadInvInstance = (Func<IntPtr, dynamic>)(item =>
        // {
        //     dynamic ret = new ExpandoObject();
        //     ret.id = vars.Helper.Read<int>(item + InvInstance["itemID"]);
        //     ret.label = vars.Helper.ReadString(item + InvInstance["overrideLabel"]);
        //     ret.count = vars.Helper.Read<int>(item + InvInstance["count"]);
        //     ret.invItem = vars.Helper.Read<IntPtr>(item + InvInstance["invItem"]);

        //     if (ret.count <= 0 || ret.id < 0 || ret.invItem == null) return null;

        //     return ret;
        // });

        return true;
    });

    // this function is a helper for checking splits that may or may not exist in settings,
    // and if we want to do them only once
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
    current.activeScene = vars.Helper.Scenes.Active.Name ?? current.activeScene;
    current.loadingScene = vars.Helper.Scenes.Loaded[0].Name ?? current.loadingScene;

    vars.Watch(old, current, "activeScene");
    vars.Watch(old, current, "loadingScene");
}

onStart
{
    // refresh all splits when we start the run, none are yet completed
    vars.CompletedSplits.Clear();

    vars.Log(current.activeScene);

    vars.Log("Items: " + current.items.Count);
    foreach (var itemPtr in current.items) {
        var item = vars.ReadInvInstance(itemPtr);
        if (item == null) continue;
        
        vars.Log("Item: " + item.label + " [" + item.id + "]. Count: " + item.count);

        // vars.Log("<Setting Id=\"item_" + item.id + "\" Label=\"" + item.label + "\" State=\"false\" />");
    }
}

start
{
    return old.activeScene == "MainMenu" && current.activeScene == "House";
}

split
{
    if (settings["item"]) {
        foreach (var itemPtr in current.items) {
            var itemId = vars.GetInvInstanceId(itemPtr);
            if (vars.CheckSplit("item_" + itemId)) {
                return true;
            }
        }
    }
}

isLoading
{
    return current.loadingScene != current.activeScene;
}