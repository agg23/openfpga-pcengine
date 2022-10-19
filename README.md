# PC Engine for Analogue Pocket

Ported from the core originally developed by [Gregory Estrade](https://github.com/Torlus/FPGAPCE) and heavily modified by [@srg320](https://github.com/srg320) and [@greyrogue](https://github.com/greyrogue). Core icon by [spiritualized1997](https://github.com/spiritualized1997). Latest upstream available at https://github.com/MiSTer-devel/TurboGrafx16_MiSTer

Please report any issues encountered to this repo. Most likely any problems are a result of my port, not the original core. Issues will be upstreamed as necessary.

## Installation

### Easy mode

I highly recommend the updater tools by [@mattpannella](https://github.com/mattpannella) and [@RetroDriven](https://github.com/RetroDriven). If you're running Windows, use [the RetroDriven GUI](https://github.com/RetroDriven/Pocket_Updater), or if you prefer the CLI, use [the mattpannella tool](https://github.com/mattpannella/pocket_core_autoupdate_net). Either of these will allow you to automatically download and install openFPGA cores onto your Analogue Pocket. Go donate to them if you can

### Manual mode
Download the core by clicking Releases on the right side of this page, then download the `agg23.*.zip` file from the latest release.

To install the core, copy the `Assets`, `Cores`, and `Platform` folders over to the root of your SD card. Please note that Finder on macOS automatically _replaces_ folders, rather than merging them like Windows does, so you have to manually merge the folders.

## Usage

ROMs should be placed in `/Assets/pce/common`

Please note that SuperGrafx and CD games are not currently supported, due to needing fixes/feature support in the firmware. They will be added in a future update.

## Features

### Dock Support

Core supports four players/controllers via the Analogue Dock. To enable four player mode, turn on `Use Turbo Tap` setting.

### Video Modes

The PC Engine is unique in that it can arbitrarily decide what resolution to display at. The Pocket is more limited, requiring fixed resolutions at all times. I've tried to compromise and cover the most common resolutions output by the PCE, but some are better supported than others. You should see the best support with horizontal resolutions of 256, 320, 352, and 512 pixels wide. It seems that some of these resolutions drop one or two pixels on the right-hand side of the screen. I haven't figured out what is causing this. Resolutions between 320 and 352 will have some amount of blank black space on the right side.

### Video Options

There are several options provided for tweaking the displayed video:

* `Hide Overscan` - Adjusts the top and bottom of the video to mask lines that would normally be masked by the CRT. Adjusts the aspect ratio to correspond with this modification
* `Extra Sprites` - Allows extra sprites to be displayed on each line. Will decrease flickering in some games

## Licensing

All source included in this project from me or the [MiSTer project](https://github.com/MiSTer-devel/TurboGrafx16_MiSTer) is licensed as GPLv2, unless otherwise noted. The original source for [FPGAPCE](https://github.com/Torlus/FPGAPCE), the project this core is based off of, is [public domain](https://twitter.com/Torlus/status/1582663978068893696). The contents of the public domain tweet are reproduced here:

> Indeed. The main reason why I haven't provided a license is that I didn't know how to deal with the different licenses attached to parts of the cores.
Anyway, consider *my own* source code as public domain, i.e do what you want with it, for any use you want. (1/2)
