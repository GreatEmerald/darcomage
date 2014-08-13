SDL2 & D Arcomage Frontend (darcomage) 1.alpha
Revision 2014.08.13, GreatEmerald

This is the SDL 2.0 + OpenGL graphical frontend for the Arcomage Clone project.
It handles all input, rendering and sound operations in the game.

The frontend is written in the D programming language, using Derelict bindings
for SDL 2.0.

=======
RUNNING
=======

In order to play the game, the user has to either obtain the precompiled
binaries or compile the code manually. For the latter, check the "Building"
section of this document to generate binaries before you proceed to run them.

Once you have the binaries, make sure that the 'lua' directory is in the same
directory as the binary file (the 'lua' directory is part of libarcomage).
Currently, the binary expects the lua directory to be in the same directory,
but that will most likely change in the future to make it more flexible.

Similarly, make sure that the 'data' directory is in the same directory as the
binary file. Alternatively, you may indicate another place for the data
directory by editing the lua/Configuration.lua file.

Using symlinks (junctions on Windows) is also a possible option.

If you are using Linux, you will have to install libSDL2 2.0, libSDL2_image 2.0
and libSDL2_ttf 2.0 to run the game (or their equivalents in your Linux
distribution; see the building section for hints). You also need something that
provides OpenGL, that's usually Mesa.

Due to the fact that the DMD compiler does not support dynamic libraries, you
don't need libarcomage to run the game, as it is included in the binary during
the compilation of the program.

After that, simply run the binary and enjoy!

========
BUILDING
========

Quick list of what you need to build the frontend, depending on the OS:

Windows:
  Mandatory:
    DMD 2.065 (Digital Mars D compiler; might work with GDC or LDC as well, but
      not tested): http://dlang.org/download.html
    SDL 2.0 (Simple DirectMedia Layer, 2.0.12)
    SDL 2.0 image
    SDL 2.0 TTF

Linux:
  Mandatory:
    DMD 2.065 (Digital Mars D compiler; might work with GDC or LDC as well, but
      not tested): http://dlang.org/download.html
    GNU Make (make)
    Embedded GNU C Library (libc6, glibc)
    SDL 2.0.3 (Simple DirectMedia Layer; libSDL2-devel on openSUSE)
    SDL 2.0 image (libSDL2_image-devel on openSUSE)
    SDL 2.0 TTF (2.0.10 preferred; libSDL2_ttf-devel on openSUSE)
    OpenGL (Mesa-devel on openSUSE)
    Lua 5.1 (lua51-devel on openSUSE)

DMD is needed because the frontend is written in the D language (and I simply
haven't tested it with other compilers; testing and patches welcome).

SDL is the component that handles all the input and output, which is exactly
what a game frontend needs. SDL2 is the latest (at the moment) version of it,
sporting some important improvements. Note that you need at least 2.0.2 or
2.0.3, 2.0.0 is not going to cut it.

OpenGL is what is used to create fancy things, like a gradient background and
dynamically scaled cards.

Lua is just needed for the backend, libarcomage, since this is currently
statically linked. The requirement might be dropped later.
    
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

Right now I only have the build scripts for 64-bit Linux and 32-bit Windows, but
if you need to, you should be able to compile in different environments as well
by changing the build scripts a little. Contact me if in doubt.

=========
STRUCTURE
=========

The project has several directories. Here's the current directory tree:

  +-- bin
  +-- data
  |   +-- fonts
  +-- include
  +-- lib
  +-- src
  +-- utils
  |-- COPYING.TXT
  |-- README.TXT

The bin directory is where the binaries that are needed in order to run the game
are put. I used to make precompiled builds, but that's not very clean, because
everyone can compile it themselves if they want to try a prerelease version.

data is the directory that contains resources for the program. At the moment
they are standalone, but might become integrated into a resource file later on.
The directory contains .wav, .ico and .png files for the players. The
subdirectory fonts includes the GNU FreeFonts, used to render fonts in the game.

include contains external dependencies (Derelict3 libraries) needed to bind the
frontend with SDL2. It might also contain any header files needed by Windows
(like for OpenGL).

lib is the directory where you should put the compiled version of libarcomage
in.

src is the D source code. That's the crucial (and the most interesting) part of
the frontend.

utils contains utilities for building the code. Included are scripts for quick
compilation on both Linux and Windows.

COPYING.TXT is a text file that contains GPL licensing information.

README.TXT is this file, in case you haven't noticed :)
