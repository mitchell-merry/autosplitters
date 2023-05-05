# Load remover for Hitman 3

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