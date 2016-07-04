SDL2 & D Arcomage Frontend (darcomage) 1.rc

Revision 2016-07-04, GreatEmerald

This is the SDL 2.0 + OpenGL graphical frontend for the Arcomage Clone project.
It handles all input, rendering and sound operations in the game.

The frontend is written in the D programming language, using Derelict bindings
for SDL 2.0.

RUNNING
============================================

In order to play the game, the user has to either obtain the precompiled
binaries or compile the code manually. For the latter, check the "Building"
section of this document to generate binaries before you proceed to run them.

Make sure to have the "lua" (from libarcomage) and "data" directories in places 
where the game can find them. That can be: the directory the binary is, one 
directory up, ../../../libarcomage/lua and .../../data, and then on OS-specific 
paths: /usr/share/arcomage/libarcomage/lua, /usr/share/arcomage/darcomage/data, 
~/.local/share/arcomage/libarcomage/lua, ~/.local/share/arcomage/darcomage/data, 
and on Windows in %APPDATA%/arcomage/libarcomage/lua and 
%APPDATA%/arcomage/darcomage/data. This should be already handled by the 
distribtion, however (but it's good to keep in mind that you can override the 
directories: ones in user directories have a higher priority).

If you are using Linux, you will have to install libSDL2 2.0, libSDL2_image 2.0,
libSDL2_mixer 2.0 and libSDL2_ttf 2.0 to run the game (or their equivalents in
your Linux distribution; see the building section for hints). You also need
something that provides OpenGL, that's usually Mesa.

After that, simply run the binary and enjoy!

BUILDING ON WINDOWS
============================================

Building on Windows is quite a bit complicated, so the instructions for it have 
been split out to the files BUILDING-WIN64.TXT and BUILDING-WIN32.TXT depending 
on the architecture you want to build on. See those files for instructions.

BUILDING ON LINUX
============================================

Quick list of what you need to build the frontend:

* libarcomage: https://github.com/GreatEmerald/libarcomage
* DMD 2.065+ (Digital Mars D compiler; might work with GDC or LDC as well, but
      not tested): http://dlang.org/download.html
* GNU Make (make)
* SDL 2.0.3+ (Simple DirectMedia Layer; libSDL2-devel on openSUSE)
* SDL 2.0 image (libSDL2_image-devel on openSUSE)
* SDL 2.0 TTF (2.0.10 preferred; libSDL2_ttf-devel on openSUSE)
* SDL 2.0 Mixer (libSDL2_mixer-devel on openSUSE)
* OpenGL (Mesa-devel on openSUSE)
* CMake 2.8+ (cmake)
* If building statically: Lua 5.1 (lua51-devel on openSUSE)

First clone the repository, then clone the libarcomage repository (ideally in
the same directory). Then initialise the git submodules (in both darcomage and
libarcomage). Use CMake in build/ to compile the projects.

Example:

```bash
git clone https://github.com/GreatEmerald/libarcomage.git
cd libarcomage
git submodule update --init
cd build
cmake ..
make
sudo make install
cd ..

git clone https://github.com/GreatEmerald/darcomage.git
cd darcomage
git submodule update --init
cd build
cmake ..
make
sudo make install
```

The output directories are controlled by CMake switches or by editing the 
CMakeCache.txt file in the build/ directory.

Note that shared library builds are default. You can make static libraries by 
passing `-DDYNAMIC_LINKING=NO` to CMake.

Instead of using make install, you can crete and install an RPM, for instance 
like this:

```bash
cpack -G RPM
sudo zypper install *.rpm
```

DMD is needed because the frontend is written in the D language (and I simply
haven't tested it with other compilers; testing and patches welcome).

SDL is the component that handles all the input and output, which is exactly
what a game frontend needs. SDL2 is the latest (at the moment) version of it,
sporting some important improvements. Note that you need at least 2.0.2 or
2.0.3, 2.0.0 is not going to cut it.

OpenGL is what is used to create fancy things, like a gradient background,
dynamically scaled cards and particles.

Why is D my primary language of choice? Well, when I started working on this
project, I was primarily an UnrealScript coder (in case you're wondering,
UnrealScript is the programming language of Unreal Engine games, which is a mix
of C++ and Java). So to me, C felt and still feels archaic. I never had to use
pointers in UnrealScript, and I never needed it, so why should I care about them
here? Or about memory allocation? Plus, without doing all kinds of archaic
tricks, you can't create a lot of things in C, and that includes dynamic arrays
(for example, if you want to use a different amount of cards than is set by
default, you need dynamic arrays, period).
So, being familiar with UnrealScript, after looking into quite a few of
different languages, I have found that D is the most fitting one for me, because
all the programming methods and the syntax is familiar to me.

So that's why I am using D in this project - it handles everything that C can't,
such as dynamic arrays and string manipulation, as well as garbage collection.
Originally, D was only used for libarcomage, but eventually the support for the
SDL2 bindings matured and I was able to make a graphical D frontend (which makes
it much easier to talk to the library).

STRUCTURE
============================================

The project has several directories. Here's the current directory tree:

```
+-- build
+-- cmake
+-- data
|   +-- fonts
+-- include
+-- src
+-- utils
|-- BUILDING-WIN32.TXT
|-- BUILDING-WIN64.TXT
|-- CMakeLists.txt
|-- COPYING.TXT
|-- DESCRIPTION.TXT
|-- README.MD
```

The `build` directory is the working directory for CMake, where the binaries that 
are needed in order to run the game are generated. I used to make precompiled 
builds, but that's not very clean, because everyone can compile it themselves if 
they want to try a prerelease version.

The `cmake` directory contains CMakeD, D compiler integration modules for CMake.

`data` is the directory that contains resources for the program. At the moment
they are standalone, but might become integrated into a resource file later on.
The directory contains .wav, .ico and .png files for the players. The
subdirectory `fonts` includes the GNU FreeFonts, used to render fonts in the game.

`include` contains external dependencies (Derelict3 libraries) needed to bind the
frontend with SDL2.

`src` is the D source code. That's the crucial (and the most interesting) part of
the frontend.

`utils` contains miscellaneous files. It has old build scripts that are no 
longer used in favour of CMake, but can be useful to see what is (supposed to 
be) happening under the hood. It also contains the desktop file for integrating 
with Linux menus.

`BUILDING-WIN??.TXT` files are build instructions for Windows, 32-bit and 64-bit.

`CMakeLists.txt` are instructions for the build system, it's not human-readable.

`COPYING.TXT` is a text file that contains GPL licensing information.

`DESCRIPTION.TXT` contains a description of DArcomage itself and is used to add
descriptions to things like installers and packages made in CPack.

`README.MD` is this file, in case you haven't noticed :) .MD is because it's 
Markdown, so you can render it in a nice way.
