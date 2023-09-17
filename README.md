# autosplitters
A collection of all of my autosplitters and load removers - tools for the speedrunning program LiveSplit.

## Other Autosplitters
Scripts I've worked on outside of this repo:
- **In Sound Mind:** https://github.com/ontrigger/ism-autosplitter
- **My Friendly Neighbourhood:** https://github.com/TheDementedSalad/My-Friendly-Neighborhood-Splitter/tree/main
- **The Blair Witch Volumes:** https://github.com/MildGothDaddy/Bw_asl
- **Trepang2:** https://github.com/LiterallyMetaphorical/Livesplit.Trepang2

I have worked on other autosplitters, those that are either
full LiveSplit components or use the Auto Splitting Runtime (ASR):
- **Aliens versus Predator 2:** https://github.com/mitchell-merry/LiveSplit.AVP2

## Templates
This repository contains a number of template files that I use frequently in my autosplitters.
You are free to use these, but I don't guarantee that they are at all good.

Note that these all require the use of [asl-help](https://github.com/just-ero/asl-help/).

## How to Install
Usually, if you want to use one of these autosplitters, you don't have to do anything special.
1. Open LiveSplit
2. Right click -> Edit Splits
3. Type in the game name
4. Text should appear, something like "Autosplitting and load removal is available (by diggity)."
    next to a box that says "Activate". Click Activate.
5. The autosplitter should now be loaded. Click "Edit Settings" to set up your splits and such.

However, if the text doesn't appear, that means the autosplitter is not yet on LiveSplit and you'll
have to manually install.
1. Download the `.asl` file you want to use, and any accompanying files (A `.Settings.xml` file if it exists).
2. Download [`asl-help`](https://github.com/just-ero/asl-help/raw/main/lib/asl-help).
3. Place all of those files under `<LiveSplit install directory>/Components`.
4. Open LiveSplit, right click -> edit layout
5. Add (+) -> Control -> Scriptable Autosplitter
6. Then choose the filepath of the `.asl` you downloaded. It should then load the autosplitter. You can tell if it worked if some of the options start appearing (start etc).
7. Change your settings in this window.

Open an issue if something appears to be broken, or feel free to open a PR yourself!