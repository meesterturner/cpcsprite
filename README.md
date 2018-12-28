# CPC Sprites
Z80 assembler based sprite library for the Amstrad CPC computer. Although I'm probably reinventing the wheel, I'm using it as an experiment in programming in assembler, and potentially on a personal project I'd like to do.

It also integrates with the Amstrad's built in Locomotive BASIC interpreter by providing RSX commands

## Using
### Initialisation
The code will need compiling to memory location `&8000`. To use the RSXs, you then need to run `CALL &8000` to initialise the new commands. If you are using from assembler, you must `call PSPRITE_BUILD_SCREEN_LINE_LOOKUP` before using. You can change the compile location by changing the `ORG &8000` compiler directive at the top of the code.

### Locomotive BASIC
The RSX commands are as follows:

`|get, <spritenumber>`
This will copy an 8x16 block, starting at the uppermost-left corner of the screen, into the sprite bank at the position specified by the sprite number.

`|put, <spritenumber>, <x>, <y>`
This will paste a copy of the sprite with the given number at the co-ordinates given. X co-ordinates are 1-80 (160 pixels in `MODE 0`, can anchor to every second pixel due to screen memory) Y co-ordinates are 1-200, 1 being the top line.

`|relocate, <memorylocation>`
This will move the start of the sprite storage memory to the specified location. It does not copy or move any existing data. This could, for example, give you the ability to have multiple "banks" of sprites.

### Z80 Assembler
Labels have been added to call the various functions

`call PSPRITE_GET`
Copy an 8x16 block. Unlike RSX version, screen memory start location can be specified. At present, the top-left corner must be aligned to the top of a character block (e.g. pixel lines 1, 9, 17, etc). Uses registers:
`A` = Sprite number
`DE` = Screen memory location of top-left corner

`call PSPRITE_PUT`
Paste a sprite on screen. Same functionality as `|put` RSX. Uses registers:
`A` = Sprite number
`HL` = X co-ordinate
`BC` = Y co-ordinate

`call PSPRITE_RELOCATE`
This will move the start of the sprite storage memory to the location specified. Uses register:
`HL` = Memory location
(Use `LD HL, SPRITE_DEFAULT_LOCATION` then perform the call to move back to default location).

## Limitations
* The functions currently only work in the CPC's `MODE 0` resolution. This is due to the way the system's video memory works. See the [CPCTelera Website](http://lronaldo.github.io/cpctelera/files/sprites/cpct_drawSprite-asm.html)
* Don't try to position the sprite so it needs to paint outside the screen boundaries as this will cause (at best) odd video effects, or (at worst) crashes
* Limited to 8x16 `MODE 0` sprites 

## Bugs
* None known

## To-do
* Optimise the code further for speed
* Run `PSPRITE_BUILD_SCREEN_LINE_LOOKUP` routine automatically only if required during Get/Put calls, rather than at initialisation of RSXs or on demand.