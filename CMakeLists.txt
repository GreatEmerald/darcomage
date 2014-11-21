# GEm: The main CMake file to build the shared library.
# GEm: Usage: cd to build/ and execute `cmake ..`

cmake_minimum_required(VERSION 2.8)

# where to look first for cmake modules, before ${CMAKE_ROOT}/Modules/ 
# is checked
SET (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Modules)

# Using Phobos
SET(CMAKE_D_USE_PHOBOS True)

# check for DDoc usage
INCLUDE(UseDDoc)

# GEm: Make sure we allow setting the right lib[64] path
INCLUDE (GNUInstallDirs)

#################################
# Project
##############

PROJECT (darcomage D)
SET (PROJECT_VERSION "1.alpha.14.06")

SET (DYNAMIC_LINKING "YES" CACHE BOOL "Whether to use dynamic (default) or static linking. Dynamic is recommended, but not possible on Win32.")
IF (WIN32)
  SET (DYNAMIC_LINKING "NO")
ENDIF (WIN32)

# GEm: Static compilation below

# GEm: Add LuaD
# GEm: These are the files we need (from LuaD Makefile)
SET (LUAD_SOURCES
  luad/all.d
  luad/base.d
  luad/dynamic.d
  luad/error.d
  luad/lfunction.d
  luad/lmodule.d
  luad/stack.d
  luad/state.d
  luad/table.d
  luad/testing.d
  luad/c/all.d
  luad/c/lauxlib.d
  luad/c/lua.d
  luad/c/luaconf.d
  luad/c/lualib.d
  luad/c/tostring.d
  luad/conversions/arrays.d
  luad/conversions/assocarrays.d
  luad/conversions/classes.d
  luad/conversions/functions.d
  luad/conversions/structs.d
  luad/conversions/variant.d
)
# GEm: Hopefully it's in a subdirectory called ../libarcomage/include/LuaD (change if you need to)
SET (LUAD_PATH ../libarcomage/include/LuaD CACHE PATH "Path to the LuaD root directory")
# GEm: Get a full path
foreach (luad_src ${LUAD_SOURCES})
  list (APPEND LUAD_FILE_PATHS "${CMAKE_SOURCE_DIR}/${LUAD_PATH}/${luad_src}")
endforeach()

# GEm: Add libarcomage
# GEm: These are the files we need (from LuaD Makefile)
SET (LIBARCOMAGE_SOURCES
  arco.d
  cards.d
  wrapper.d
)
# GEm: Hopefully it's in a subdirectory called ../libarcomage/src (change if you need to)
SET (LIBARCOMAGE_PATH ../libarcomage/src CACHE PATH "Path to the libarcomage source directory")
# GEm: Get a full path
foreach (libarcomage_src ${LIBARCOMAGE_SOURCES})
  list (APPEND LIBARCOMAGE_FILE_PATHS "${CMAKE_SOURCE_DIR}/${LIBARCOMAGE_PATH}/${libarcomage_src}")
endforeach()

# GEm: Add Derelict
# GEm: Files for SDL2
SET (DERELICT_SDL2_SOURCES
  functions.d
  image.d
  mixer.d
  net.d
  sdl.d
  ttf.d
  types.d
)
SET (DERELICT_SDL2_SUBDIR derelict/sdl2)
# GEm: Files for OpenGL
SET (DERELICT_OPENGL_SOURCES
  arb.d
  cgl.d
  constants.d
  deprecatedConstants.d
  deprecatedFunctions.d
  ext.d
  functions.d
  gl.d
  gl3.d
  glx.d
  glxext.d
  internal.d
  types.d
  wgl.d
  wglext.d
)
SET (DERELICT_OPENGL_SUBDIR derelict/opengl3)
# GEm: Files in general
SET (DERELICT_UTIL_SOURCES
  exception.d
  loader.d
  sharedlib.d
  system.d
  wintypes.d
  xtypes.d
)
SET (DERELICT_UTIL_SUBDIR derelict/util)
# GEm: Hopefully there's a "derelict" subdirectory in a directory called include (change if you need to)
SET (DERELICT_PATH include CACHE PATH "Path to the directory one level higher than 'derelict'")
# GEm: Get a full path
foreach (derelict_sdl2_src ${DERELICT_SDL2_SOURCES})
  list (APPEND DERELICT_FILE_PATHS "${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_SDL2_SUBDIR}/${derelict_sdl2_src}")
endforeach()
foreach (derelict_opengl_src ${DERELICT_OPENGL_SOURCES})
  list (APPEND DERELICT_FILE_PATHS "${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_OPENGL_SUBDIR}/${derelict_opengl_src}")
endforeach()
foreach (derelict_util_src ${DERELICT_UTIL_SOURCES})
  list (APPEND DERELICT_FILE_PATHS "${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_UTIL_SUBDIR}/${derelict_util_src}")
endforeach()

# GEm: Include the directories for linking
include_directories(${CMAKE_SOURCE_DIR}/${LUAD_PATH})
include_directories(${CMAKE_SOURCE_DIR}/${LIBARCOMAGE_PATH})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_SDL2_SUBDIR})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_OPENGL_SUBDIR})

# GEm: Continue processing
ADD_SUBDIRECTORY (src)

# GEm: Install config and decks
INSTALL (DIRECTORY lua/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/arcomage/libarcomage)

# GEm: CPack specifics below. This can be openSUSE-specific, so other distros should use their own packaging.
SET (CPACK_PACKAGE_DESCRIPTION_SUMMARY "Backend for free Arcomage-like games")
SET (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING.TXT")
SET (CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.MD")
#SET (CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/DESCRIPTION.TXT")
# GEm: RPM specifics, this is definitely openSUSE-specific
SET (CPACK_RPM_PACKAGE_LICENSE "GPL-3.0+")
SET (CPACK_RPM_PACKAGE_GROUP "Amusements/Games")
INCLUDE (CPack)
