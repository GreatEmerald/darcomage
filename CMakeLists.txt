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
SET (PROJECT_VERSION "1.alpha.14.14")
SET (PROJECT_VERSION_MAJOR "1")
SET (PROJECT_VERSION_MINOR "alpha")
SET (PROJECT_VERSION_PATCH "14")
SET (PROJECT_VERSION_TWEAK "14")

# GEm: Guess whether static or dynamic linking is desired
IF (WIN32)
  SET (dynlink "NO")
ELSE (WIN32)
  SET (dynlink "YES")
ENDIF (WIN32)
SET (DYNAMIC_LINKING ${dynlink} CACHE BOOL "Whether to use dynamic (default) or static linking. Dynamic is recommended, but not possible on Win32.")

# GEm: Detect architecture
if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
  message(STATUS "Target is 64 bits")
  set(bits "64")
elseif("${CMAKE_SIZEOF_VOID_P}" EQUAL "4")
  message(STATUS "Target is 32 bits")
  set(bits "32")
else ("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
  message(STATUS "Target has unknown bitness: " "${CMAKE_SIZEOF_VOID_P}")
endif("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
SET (ARCH ${bits} CACHE STRING "Bitness of the architecture you're building for. It's autodetected, but change this value (32 or 64) for cross-compilation.")

IF (ARCH EQUAL "64")
  SET (CMAKE_D_FLAGS "${CMAKE_D_FLAGS} -m64")
ELSE (ARCH EQUAL "64")
  SET (CMAKE_D_FLAGS "${CMAKE_D_FLAGS} -m32")
ENDIF (ARCH EQUAL "64")


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
# GEm: Find LuaD sources
find_path (LUAD_PATH luad/all.d
  PATH_SUFFIXES dlang d dmd
  PATHS ${CMAKE_SOURCE_DIR}/../libarcomage/include/LuaD
  DOC "Path to the LuaD root directory")
if (NOT DYNAMIC_LINKING)
  # GEm: Get a full path
  foreach (luad_src ${LUAD_SOURCES})
    list (APPEND LUAD_FILE_PATHS "${LUAD_PATH}/${luad_src}")
  endforeach()
endif (NOT DYNAMIC_LINKING)

# GEm: Add libarcomage
# GEm: These are the files we need (from LuaD Makefile)
SET (LIBARCOMAGE_SOURCES
  arco.d
  cards.d
  wrapper.d
)
find_path (LIBARCOMAGE_PATH arco.d
  PATHS ${CMAKE_SOURCE_DIR}/../libarcomage/src
  PATH_SUFFIXES arcomage libarcomage dlang/libarcomage d/libarcomage dmd/libarcomage dlang/arcomage d/arcomage dmd/arcomage
  DOC "Path to the libarcomage source directory")
if (NOT DYNAMIC_LINKING)
  # GEm: Get a full path
  foreach (libarcomage_src ${LIBARCOMAGE_SOURCES})
    list (APPEND LIBARCOMAGE_FILE_PATHS "${LIBARCOMAGE_PATH}/${libarcomage_src}")
  endforeach()
endif (NOT DYNAMIC_LINKING)

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
include_directories(${LUAD_PATH})
include_directories(${LIBARCOMAGE_PATH})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_SDL2_SUBDIR})
include_directories(${CMAKE_SOURCE_DIR}/${DERELICT_PATH}/${DERELICT_OPENGL_SUBDIR})

# GEm: Continue processing
ADD_SUBDIRECTORY (src)

# GEm: Install resources
INSTALL (DIRECTORY data/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/arcomage/darcomage-data)
if (NOT DYNAMIC_LINKING)
  # GEm: Install config
  INSTALL (DIRECTORY ${LIBARCOMAGE_PATH}/../lua/ DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/arcomage/libarcomage)
endif (NOT DYNAMIC_LINKING)

SET (CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
SET (CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_PATCH})
SET (CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_TWEAK})
SET (CPACK_PACKAGE_VENDOR "GreatEmerald")
# GEm: CPack specifics below. This can be openSUSE-specific, so other distros should use their own packaging.
SET (CPACK_PACKAGE_DESCRIPTION_SUMMARY "SDL2 frontend for libarcomage")
SET (CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING.TXT")
SET (CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.MD")
#SET (CPACK_PACKAGE_DESCRIPTION_FILE "${CMAKE_CURRENT_SOURCE_DIR}/DESCRIPTION.TXT")
# GEm: RPM specifics, this is definitely openSUSE-specific
SET (CPACK_RPM_PACKAGE_LICENSE "GPL-3.0+")
SET (CPACK_RPM_PACKAGE_GROUP "Amusements/Games")
# GEm: NSIS specific
SET (CPACK_NSIS_PACKAGE_NAME "DArcomage")
SET (CPACK_NSIS_MUI_ICON "${CMAKE_SOURCE_DIR}/data/arcomage.ico")
SET (CPACK_NSIS_MUI_UNIICON ${CPACK_NSIS_MUI_ICON})
SET (CPACK_NSIS_CREATE_ICONS_EXTRA "CreateShortcut '\$SMPROGRAMS\\\\\$STARTMENU_FOLDER\\\\DArcomage.lnk' '\$INSTDIR\\\\bin\\\\darcomage.exe' '' '\$INSTDIR\\\\share\\\\arcomage\\\\darcomage-data\\\\arcomage.ico'")
SET (CPACK_NSIS_DELETE_ICONS_EXTRA "Delete '\$SMPROGRAMS\\\\\$MUI_TEMP\\\\DArcomage.lnk'")
SET (CPACK_NSIS_URL_INFO_ABOUT "http://greatemerald.eu")
INCLUDE (CPack)
