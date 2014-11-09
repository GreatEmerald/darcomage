#!/bin/sh

# GEm: This is the DArcomage compilation script for Linux amd64, static libraries.
#      Tested only on openSUSE, so on other distributions certain changes may be needed.
#      Requires DMD (DigitalMars D compiler).

# GEm: The way it works: -m64 says to compile for 64-bit (change to -m32 if you need 32bit)
#      -of is the output file name,
#      -L-l includes all the other required shared libraries (maybe could use pkgconfig)
#      and finally the compiler gets paths to all of the required static libraries' source:
#      DArcomage, libarcomage, LuaD and Derelict3.

cd ../src
dmd -m64 -ofdarcomage \
 -L-lGL -L-lSDL2 -L-lpthread -L-lSDL2_ttf -L-lSDL2_image -L-lSDL2_mixer -L-llua -L-ldl \
 *.d ../../libarcomage/src/*.d \
 ../../libarcomage/include/LuaD/luad/*.d ../../libarcomage/include/LuaD/luad/conversions/*.d ../../libarcomage/include/LuaD/luad/c/*.d \
 ../include/derelict/sdl2/*.d ../include/derelict/opengl3/*.d ../include/derelict/util/*.d
rm darcomage.o
mv darcomage ../bin/linux-x86_64
cd ../utils
