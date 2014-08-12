#!/bin/sh
cd ../src
dmd -m64 -od../bin/linux-x86_64 -ofdarcomage \
 -L-lGL -L-lSDL2 -L-lpthread -L-lSDL2_ttf -L-lSDL2_image \
 -I../include -I../../libarcomage/src -I../../libarcomage/include/LuaD \
 *.d
cd ../utils
