#!/bin/sh
cd ../src
dmd -m64 -ofdarcomage \
 -I../include -I../../libarcomage/src -I../../libarcomage/include/LuaD \
 -L-lGL -L-lSDL2 -L-lpthread -L-lSDL2_ttf -L-lSDL2_image -L-lSDL2_mixer -L-llua -L-ldl \
 *.d ../../libarcomage/src/*.d \
 ../../libarcomage/include/LuaD/luad/*.d ../../libarcomage/include/LuaD/luad/conversions/*.d ../../libarcomage/include/LuaD/luad/c/*.d \
 ../include/derelict/sdl2/*.d ../include/derelict/opengl3/*.d ../include/derelict/util/*.d
rm darcomage.o
mv darcomage ../bin/linux-x86_64
cd ../utils
