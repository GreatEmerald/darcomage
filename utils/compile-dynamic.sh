#!/bin/sh

# GEm: This is the DArcomage compilation script for Linux amd64, dynamic libraries.
#      Tested only on openSUSE, so on other distributions certain changes may be needed.
#      Requires DMD (DigitalMars D compiler) 2.065 or later to run.

# GEm: The way it works: -m64 says to compile for 64-bit (change to -m32 if you need 32bit)
#      -of is the output file name, -defaultlib and -map are needed for dynamic libraries,
#      the next two arguments point to where the libarcomage.so library is in
#      (-L-L may be unnecessary for distributions, as libarcomage.so will be in /usr/lib64),
#      -I lists include directories, so the compiler knows all the symbols the shared library has but doesn't compile them statically
#      (in distributions, these should point to libarcomage-devel's /usr/include files)
#      -L-l includes all the other required shared libraries (maybe could use pkgconfig)
#      and finally the compiler gets paths to DArcomage source and Derelict (that's a static library)

cd ../src
dmd -m64 -ofdarcomage \
 -defaultlib=libphobos2.so -map -L-L../../libarcomage/lib -L-larcomage -L-llua \
 -I../include -I../../libarcomage/src -I../../libarcomage/include/LuaD \
 -L-lGL -L-lSDL2 -L-lpthread -L-lSDL2_ttf -L-lSDL2_image -L-lSDL2_mixer -L-ldl \
 *.d \
 ../include/derelict/sdl2/*.d ../include/derelict/opengl3/*.d ../include/derelict/util/*.d
rm darcomage.o darcomage.map
mv darcomage ../bin/linux-x86_64
cd ../utils
