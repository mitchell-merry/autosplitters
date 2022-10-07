state("Late Work") { }

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.GameName = "LW";
	// vars.Helper.LoadSceneManager = true;
	vars.Watch = (Action<string>)(key => { if(vars.Helper[key].Changed) vars.Log(key + ": " + vars.Helper[key].Old + " -> " + vars.Helper[key].Current); });
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var gms = mono["GameManagerScript"];
		vars.Helper["Task"] = mono.Make<IntPtr>(gms, "activeEvent");

		return true;
	});
}

update
{
	vars.Log(vars.Helper["Task"].Current.ToString("X"));
	vars.Watch("Task");
	// current.activeScene = vars.Helper.Scenes.Active.Name == null ? current.activeScene : vars.Helper.Scenes.Active.Name;
	// current.loadingScene = vars.Helper.Scenes.Loaded[0].Name == null ? current.loadingScene : vars.Helper.Scenes.Loaded[0].Name;
}