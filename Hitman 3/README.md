# Load remover for Hitman 3

This README details how you can update this ASL with different versions, or different updates.

**INSTALLATION GUIDE:**
- [Video Guide](https://www.youtube.com/watch?v=u8pa8kJcy30)
- [Text Guide](https://hitruns-wiki.vercel.app/docs/livesplit_freelancer)

## Basic Tooling

- LiveSplit, setup with a layout that has a ScriptableAutosplitter component with the ASL in this repo (`hitman3.asl`) loaded.
- [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) allows you to see the logs of LiveSplit.

Also see the [LiveSplit docs on ASL](https://github.com/LiveSplit/LiveSplit.AutoSplitters).

## Adding a new "state"

There are a few blocks at the beginning of the function that look like `state("HITMAN3", <version>) {}`. These correspond to different published versions of the game.

We differentiate the versions by calculating the MD5 hash of the HITMAN3 executable file. Try running the loading the ASL once; if you're using a supported version, then you should see `Chose version: Steam` or similar in the logs. If it is not supported, you will see `UNKNOWN` in place of Steam. Above that log will be a `Hash is: ` line. Copy the hash from there and add it as a case to the switch block, setting the version to an appropriate identifier (if an update has come out, you will need to replace the appropriate version with the new hash. the old version is presumably no longer playable, so no need to keep it around).

Once you've done this you can add a new state block to the script.

Next, you need to find the values used in the script. The addresses used in other versions will probably not work in another version or update
(That is why we differentiate them in the first place).

### Finding the address

#### Setup
To find the addresses, you need Cheat Engine (CE). Start by opening Hitman and CE, and attach CE to Hitman.

All of our addresses are what's called a "static address". They appear green in the address list. We can restrict our results to just static addresses by changing
the "Memory Range" option in CE. Go to Memory View (below the address list) -> Tools -> Find static addresses, and there will be twwo fields - "From" and "To".
This is the range of memory in our process which is designated as static. Copy these two values into the "Start" and "Stop" fields under Memory Scan Options on the main CE window.

A useful tool for searching for values is the ability to freeze the game. In CE, go to edit -> settings -> hotkeys, and set a hotkey for "Pause the selected process".

Then, set the "Value Type" to "Byte" and the "Scan Type" to "Exact Value". You should be now ready to start searching for values.

(We know our values are static because of hindsight! There wasn't a way to know this before finding them the first time, but static addresses are always preferred.)

#### Doing the finding
We will use the isLoading value (described below this section) as an example.

You can begin the search with "First Scan" for a value of 0 outside of a loading screen. You will see a lot of results. Then, load freelancer, and once the loading screens we're looking for start (reference the above video), pause the game using the hotkey, the earlier the better.

You can then change the "Value" from 0 to 1, and do another scan. That should whittle down the list quite a lot. Unpause the game, and before that loading screen finishes, pause again and re-scan for 1. Then let the loading screen finish, pause the game again, and search for 0. Do this over and over!

Keep doing this until you get one or just a few addresses! Then just pick one. I'd keep all viable static addresses around just in case the one you pick breaks.

You can take this procedure and apply it to any other address.

## Addresses to find

We (at the time of writing) need *4* static addresses to boolean values.

### isLoading

The address we're finding is a value that is 1 during specific loading screens, and 0 everywhere else. 

The loading screen it is 1 on is very important - they are the larger, longer loading screens when loading maps. Here's a video to showcase what it should look like:

https://cdn.discordapp.com/attachments/1100260194635747349/1103234261663895562/2023-05-03_18-16-41.mp4

(When the value is 1, the timer pauses. 0 means the timer is running)

### isInMainMenu

Fairly self explanatory - 1 in while in the main menu, 0 otherwise.

### inCutscene

Also self explanatory - 1 while in a cutscene, 0 otherwise. These include all the enter / exit cutscenes of both the safehouse and the missions.

### hasControl

This is a byte that is 1 when the player has control (is able to run around, while paused, etc), and 0 otherwise.

### usingCamera
1 when right clicking with the camera held (using it)
0 otherwise.

## Other address we don't necessarily care about right now
...but may be useful in the future.

### statusBarState

Enum with the following (known) values:

```cpp
enum StatusBarState {
    NONE = 0,
    SAVING = 6,
    LOADING = 7,
    FETCHING = 8,
    CONNECTED = 9,
    CONNECTING = 13,
    SYNCHRONIZING = 16,
    AUTHENTICATING = 17,
    FETCHING_PROFILE = 19,
}
```

Note that:
- it's value during the main loading screen is practically bogus (but we have isLoading for this regardless)
- whenever the player pauses, it will load for a bit (since it does some loading on pause)
- running around levels, it will save occassionally

## isPaused

1 while paused, 0 otherwise!