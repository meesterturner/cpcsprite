# CPC Sprites
Z80 assembler based sprite library for the Amstrad CPC computer. Although I'm probably reinventing the wheel, I'm using it as an experiment in programming in assembler, and potentially on a personal project I'd like to do.

It also integrates with the Amstrad's built in Locomotive BASIC interpreter by providing RSX commands

## Using
### Initialisation
The code will need compiling to memory location `&8000`, then run `CALL &8000` to initialise the new commands.

### Locomotive BASIC
The RSX commands are as follows:

`|get, <spritenumber>`
This will copy an 8x16 block, starting at the uppermost-left corner of the screen, into the sprite bank at the position specified by the sprite number.

`|put, <spritenumber>, <x>, <y>`
This will paste a copy of the sprite with the given number at the co-ordinates given. X co-ordinates are 1-80 (160 pixels in `MODE 0`, can anchor to every second pixel due to screen memory) Y co-ordinates are 1-200, 1 being the top line.

## Limitations
* The functions currently only work in the CPC's `MODE 0` resolution. This is due to the way the system's video memory works. See the [CPCTelera Website](http://lronaldo.github.io/cpctelera/files/sprites/cpct_drawSprite-asm.html)
* Don't try to position the sprite so it needs to paint outside the screen boundaries as this will cause (at best) odd video effects, or (at worst) crashes

## Bugs
* None known

## To-do
* Optimise the code further for speed
* Labels in the assembler to allow better direct calling from other assembler code
* Change 8x16 blocks to 16x16 blocks for tiles, and include 8x8 sprite option
* Run `BUILD_SCREEN_LINE_LOOKUP` routine automatically only if required during Get/Put calls, rather than at initialisation of RSXs