# PC Engine for Analogue Pocket

Ported from the core originally developed by [Gregory Estrade](https://github.com/Torlus/FPGAPCE) and heavily modified by [@srg320](https://github.com/srg320) and [@greyrogue](https://github.com/greyrogue). Core icon based on TG-16 icon by [spiritualized1997](https://github.com/spiritualized1997). Latest upstream available at https://github.com/MiSTer-devel/TurboGrafx16_MiSTer

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

### 6 button controller

Some games support a 6 button controller. For those games, enable the `Use 6 Button Ctrl` option in `Core Settings`. Please note that this option can break games that don't support the 6 button controller, so turn it off if you're not using it.

### Controller Turbo

Like the original PC Engine controllers, this core supports multiple turbo modes. Adjust the `I` and `II` button turbo modes, and use the `X` and `Y` buttons (by default) as your turbo buttons. Note that the original PCE controllers had the turbo on the `I` and `II` buttons directly, rather than having separate buttons, but since the Pocket has more than just two, we use them for the turbo.

### Video Modes

The PC Engine is unique in that it can arbitrarily decide what resolution to display at. The Pocket is more limited, requiring fixed resolutions at all times. I've tried to compromise and cover the most common resolutions output by the PCE, but some are better supported than others. You should see the video centered on the screen with surrounding black bars on some resolutions, but the aspect ratios should be correct.

### Video Options

* `Extra Sprites` - Allows extra sprites to be displayed on each line. Will decrease flickering in some games
* `Raw RGB Color` - Use the raw RGB color palette output by the HUC6260. If disabled, will use the composite color palette

### Audio Options

The core can be quiet in some games, so there are options to boost the master audio (`Master Audio Boost`) and ADPCM channels (`PCM Audio Boost`).

### Memory Cards

Instead of sharing a memory card (as you would in real life), each game gets its own save file and therefore memory card. Some games don't have the ability to initialize a memory card, so each newly created save file is pre-initialized for use.

## Licensing

All source included in this project from me or the [MiSTer project](https://github.com/MiSTer-devel/TurboGrafx16_MiSTer) is licensed as GPLv2, unless otherwise noted. The original source for [FPGAPCE](https://github.com/Torlus/FPGAPCE), the project this core is based off of, is [public domain](https://twitter.com/Torlus/status/1582663978068893696). The contents of the public domain tweet are reproduced here:

> Indeed. The main reason why I haven't provided a license is that I didn't know how to deal with the different licenses attached to parts of the cores.
Anyway, consider *my own* source code as public domain, i.e do what you want with it, for any use you want. (1/2)

[Additionally, he wrote](https://twitter.com/Torlus/status/1582664299973341184):

> If stated otherwise in the comments at the beginning of a given source file, the license attached prevails. That applies to my FPGAPCE project (https://github.com/Torlus/FPGAPCE).