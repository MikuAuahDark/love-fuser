love-fuser
=====

`love-fuser` (name ideas welcome), fuses your game using GitHub Actions. Work in progress but usable.

Usage
=====

Before fusing your game, enable/disable the workflow files for particular platform. Available workflows are:

* `windows-release` - Package your game for Windows using officially released LOVE binaries.

* `windows-source` - Package your game for Windows by compiling LOVE and Megasource from source.

* `linux-source` - Package your game for Linux with AppImages by compiling LOVE and its dependencies from source.

* `android-source` - Package your game for Android by compiling love-android from source. AAB and debug APK is provided as artifacts.

Afterwards, put all your game source code into `game` folder, or use submodules.

AppImage Notes
=====

It's possible to extract the AppImage contents and package the game as tarball if special modifications are needed.
It's compiled with relocatibility in-mind so running it without packaging it into AppImage is already sufficient.

License
=====

* An example "game" (LOVE 0.10.x no-game screen **modified** to run in 11.x) is placed in `game` by LOVE Development Team - zlib license.

* `game/30log.lua` - MIT license

* Unless noted otherwise, the rest is public domain.
