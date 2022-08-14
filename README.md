# Aseprite Split & Merge
**WIP/Incomplete**

This is an [Aseprite](https://www.aseprite.org) extension that can split and merge frames from
one or more sprite files to another. It preserves any associated tags, layers, and other metadata.

# Purpose
This is mainly intended for sitautions where you have a large group of static images per Aseprite
file, with one frame per image. The process can be tedious if you want to reorganize frames across
multiple such files, especially if you make heavy use of tags and tag/layer userdata, which need to
be manually copied one at a time.

This extension makes this task much simpler.

# Installation

## Extension
1. Download [split-merge.aseprite-extension](https://raw.githubusercontent.com/JWCook/aseprite-split-merge/main/split-merge.aseprite-extension)
2. Either drag the file onto an Aseprite window, or select the file from `Edit > Preferences > Extensions > Add Extension`

See [Extensions](https://www.aseprite.org/docs/extensions/) in the Aseprite docs for more information.

## Script only
1. Download [split-merge.lua](https://raw.githubusercontent.com/JWCook/aseprite-split-merge/main/split-merge.lua)
2. Copy to [user scripts folder](https://community.aseprite.org/t/locate-user-scripts-folder/2170)

Example one-liner to install on Linux:
```bash
curl \
  https://raw.githubusercontent.com/JWCook/aseprite-split-merge/main/split-merge.lua \
  -o ~/.config/aseprite/scripts/split-merge.lua
```

# GUI Usage
![](screenshot.png)

## Extension
To run, either select `Frames > Split/Merge`, or press `Ctrl+Shift+M`

## Script only
Select `File > Scripts > split-merge`


# CLI Usage
`aseprite-split-merge` can also be run from the [Aseprite CLI](https://www.aseprite.org/docs/cli/),
using the `--script` and (optionally) `--script-param` arguments.

## Parameters
* `src-sprite`: Sprite file to copy from; otherwise use active sprite
* `dest-sprite`: Sprite file to copy to; otherwise create new sprite
  * Default filename: `{src-sprite}_{start}-{end}.aseprite`
* `start-frame`: Frame to start copying from; default: `1`
* `end-frame`: Frame to stop copying from; default: last frame of `src-sprite`
* `overwrite`: Overwrite an existing file instead of appending to it; default: `false`

## Example
```bash
aseprite -b my_sprite.aseprite \
   --script-param dest-sprite=my_sprite_subset.aseprite \
   --script-param start-frame=1 \
   --script-param end-frame=10 \
   --script-param overwrite=true \
   --script split-merge.lua
```
