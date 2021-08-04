love-fuser
=====

`love-fuser` (temporary name, name ideas pending), fuses your game using GitHub Actions. Work in progress.

Usage
=====

**Soon, this repository will become a template repository.**

Before fusing your game, enable/disable the workflow files for particular platform. Available workflows are:

* `windows-release` - Package your game for Windows using officially released LOVE binaries.

* `linux-source` - Package your game for Linux with AppImages by compiling LOVE and its dependencies from source.

Afterwards, put all your game source code into `game` folder, or use submodules.

AppImage Notes
=====

It's possible to extract the AppImage contents and package the game as tarball if special modifications are needed.
It's compiled with relocatibility in-mind so running it without packaging it into AppImage first is already sufficient.

License
=====

* An example "game" (LOVE 11.0 no-game screen) is placed in `game`- zlib license.

* `game/30log.lua` - MIT license

* Unless noted otherwise, the rest is public domain.
