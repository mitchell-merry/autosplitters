# Load remover for Hitman 3

This README details how you can update this ASL with different versions, or different updates.

**INSTALLATION GUIDE:**
- [Video Guide](https://www.youtube.com/watch?v=u8pa8kJcy30)
- [Text Guide](https://hitruns-wiki.vercel.app/docs/livesplit_freelancer)

## Basic Tooling

- LiveSplit, setup with a layout that has a ScriptableAutosplitter component with the ASL in this repo (`hitman3.asl`) loaded.
- [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) allows you to see the logs of LiveSplit.

Also see the [LiveSplit docs on ASL](https://github.com/LiveSplit/LiveSplit.AutoSplitters).

# 10-05-2024 UPDATE:

We use signatures instead of raw addresses now. It hopefully works between versions. If it stops working, then let me know
and I'll have a crack once I have time. Or if you're familiar with how signature scanning works, please have a go yourself.
They should be cross-platform.

You'll still need to find the addresses if the signatures break, so the following section is still relevant.

### Finding the addresses

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

Apparently sometimes 2?

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

## currentMap

A string that shows the current map. Sometimes is null, as in during brief periods in the loading screen and while in the main menu, but otherwise is a string like the following:
- `assembly:/_pro/scenes/missions/snug/scene_vanilla.entity` (The safehouse)
- `assembly:/_pro/scenes/missions/paris/scene_peacock_mild_craps.entity` (Paris)
etc

THIS IS NOT A STATIC ADDRESS. The way you find this is:
Open DebugView and transition between maps. There will be a message like:

`[22396] HandleTransition: assembly:/_pro/scenes/missions/paris/scene_peacock_mild_craps.entity`

where the string is the map you're transitioning too. If you search for this string (make sure you expand the scan to all memory), you will find a few entries. If you search each of the addresses that appear (as in, add all the addresses that show up to the address list, then search for the address as 8 bytes), one of those will have many results.

Among those results is a static address. That static address is what you want.
Add that static address to your address list, then add an offset of 0x0 to it (select Pointer).

# ignore everything below here

im just storing these here, it's nonsensical

```
enum UIConnectionStatus {
    UI_CONNECTION_STATUS_EOFFLINE = 0x1,
    UI_CONNECTION_STATUS_EOFFLINE = 0x2,
    return param_2;
  default:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002b;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EBEGIN_CONNECTION_FLOW";
    return param_2;
  case 4:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000022;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EDISCONNECTED";
    return param_2;
  case 6:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000025;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EPREAUTHENTICATE";
    return param_2;
  case 7:
  case 8:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000027;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCH_API_VERSION";
    return param_2;
  case 9:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002a;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EAPI_VERSION_RECEIVED";
    return param_2;
  case 10:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002c;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_CONFIGURATION";
    return param_2;
  case 0xb:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002c;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ECONFIGURATION_RECEIVED";
    return param_2;
  case 0xc:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000031;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EONLINE_CONSENT_CONFIRMATION";
    return param_2;
  case 0xf:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000024;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EAUTHENTICATING";
    return param_2;
  case 0x10:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002d;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EAUTHENTICATION_RECEIVED";
    return param_2;
  case 0x11:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000038;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ENTITLEMENTS_SYNCHRONIZE_INPROGRESS";
    return param_2;
  case 0x12:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000032;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ENTITLEMENTS_SYNCHRONIZE_DONE";
    return param_2;
  case 0x13:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000030;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EAUTHENTICATING_GAMESERVICE";
    return param_2;
  case 0x14:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000039;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EAUTHENTICATION_GAMESERVICE_RECEIVED";
    return param_2;
  case 0x15:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002c;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFSP_IOI_ACCOUNT_SIGNUP";
    return param_2;
  case 0x16:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000034;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_OFFLINE_CACHE_DB_DIFF";
    return param_2;
  case 0x17:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000038;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_OFFLINE_CACHE_DB_RECEIVED";
    return param_2;
  case 0x18:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000030;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_DYNAMIC_RESOURCES";
    return param_2;
  case 0x19:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002f;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EDYNAMIC_RESOURCES_MOUNTED";
    return param_2;
  case 0x1b:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000030;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_PLATFORM_USERINFO";
    return param_2;
  case 0x1c:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000030;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EPLATFORM_USERINFO_RECEIVED";
    return param_2;
  case 0x1f:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000026;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EFETCHING_PROFILE";
    return param_2;
  case 0x20:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000026;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EPROFILE_RECEIVED";
    return param_2;
  case 0x21:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002b;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ESYNCHRONYZING_PROFILE";
    return param_2;
  case 0x22:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000002a;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EPROFILE_SYNCHRONIZED";
    return param_2;
  case 0x23:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000027;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ERETRIEVING_EVENTS";
    return param_2;
  case 0x24:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000026;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EEVENTS_RETRIEVED";
    return param_2;
  case 0x25:
    FUN_1400648a0(param_2);
    *param_2 = 0x80000036;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_EWAITING_FOR_SYNCHRONIZING_EVENTS";
    return param_2;
  case 0x26:
    FUN_1400648a0(param_2);
    *param_2 = 0x8000001f;
    *(char **)(param_2 + 2) = "UI_CONNECTION_STATUS_ECONNECTED";
    return param_2;
  }
}
```