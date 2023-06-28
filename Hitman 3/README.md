# Load remover for Hitman 3

This README details how you can update this ASL with different versions, or different updates.

## Basic Tooling

- LiveSplit, setup with a layout that has a ScriptableAutosplitter component with the ASL in this repo (`hitman3.asl`) loaded.
- [DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) allows you to see the logs of LiveSplit.

Also see the [LiveSplit docs on ASL](https://github.com/LiveSplit/LiveSplit.AutoSplitters).

## Adding a new "state"

There are a few blocks at the beginning of the function that look like `state("HITMAN3", <version>) {}`. These correspond to different published versions of the game.

We differentiate the versions by calculating the MD5 hash of the HITMAN3 executable file. Try running the loading the ASL once; if you're using a supported version, then you should see `Chose version: Steam` or similar in the logs. If it is not supported, you will see `UNKNOWN` in place of Steam. Above that log will be a `Hash is: ` line. Copy the hash from there and add it as a case to the switch block, setting the version to an appropriate identifier (if an update has come out, you will need to replace the appropriate version with the new hash. the old version is presumably no longer playable, so no need to keep it around).

Once you've done this you can add a new state block to the script.

Next, you need to find the values used in the script. The addresses used in other versions will not work in another version or update (That is why we differentiate them in the first place).

## isLoading

The address we're finding is a value that is 1 during specific loading screens, and 0 everywhere else. 

The loading screen it is 1 on is very important - they are the larger, longer loading screens when loading maps. Here's a video to showcase what it should look like:

https://cdn.discordapp.com/attachments/1100260194635747349/1103234261663895562/2023-05-03_18-16-41.mp4

(When the value is 1, the timer pauses. 0 means the timer is running)

### Finding the address

To find this address, you need Cheat Engine (CE).

We're looking for what's called a "static address". They appear green in the address list.

Start by opening Hitman and CE, attach CE to Hitman, set the "Value Type" to "Byte" and the "Scan Type" to "Exact Value".

A useful tool for searching for values is the ability to freeze the game. In CE, go to edit -> settings -> hotkeys, and set a hotkey for "Pause the selected process".

You can begin the search with "First Scan" for a value of 0 outside of a loading screen. You will see a lot of results. Then, load freelancer, and once the loading screens we're looking for start (reference the above video), pause the game using the hotkey, the earlier the better.

You can then change the "Value" from 0 to 1, and do another scan. That should whittle down the list quite a lot. Unpause the game, and before that loading screen finishes, pause again and re-scan for 1. Then let the loading screen finish, pause the game again, and search for 0. Do this over and over!

Now, with the gift of hindsight, we know this address is static. That means it won't change if you close the game and open it again. So do that - close hitman, reopen it, reattach, and then keep searching. You should have just static addresses left.

Keep doing this until you get one or just a few addresses! Then just pick one. I'd keep all viable static addresses around just in case the one you pick breaks.
