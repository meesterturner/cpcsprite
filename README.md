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
This will paste a copy of the sprite with the given number at the co-ordinates given. Co-ordinates are based on the CPC's text grid, so the top left corner is 1, 1.

## Limitations
The functions currently only work in the CPC's `MODE 0` resolution. This is due to the way the system's video memory works. See the [CPCTelera Website](http://lronaldo.github.io/cpctelera/files/sprites/cpct_drawSprite-asm.html)

## Bugs
There is currently an issue with the 8th line of the completed sprite not being painted as expected.

## To-do
* More accurate pixel-based x/y co-ordinates
* Optimise the code further for speed
* Labels in the assembler to allow better direct calling from 
* Change 8x16 blocks to 16x16 blocks for tiles, and include 8x8 sprite option