include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# GEm: Our own sources
SET (DARCOMAGE_SOURCES frontend.d input.d graphics.d font.d opengl.d sound.d)
add_executable (darcomage WIN32
  ${DARCOMAGE_SOURCES}
  ${LUAD_FILE_PATHS}
  ${LIBARCOMAGE_FILE_PATHS}
  ${DERELICT_FILE_PATHS}
)

# GEm: Include dynamic libarcomage
if (DYNAMIC_LINKING)
  find_library(LIBARCOMAGE_LIBRARY arcomage)
  if (LIBARCOMAGE_LIBRARY)
    target_link_libraries(darcomage ${LIBARCOMAGE_LIBRARY})
  else (LIBARCOMAGE_LIBRARY)
    message(FATAL_ERROR "Unable to find an installed instance of libarcomage. Install it first or try a static build.")
  endif (LIBARCOMAGE_LIBRARY)
endif (DYNAMIC_LINKING)

# GEm: Include libDL, needed for Lua
if (UNIX AND NOT APPLE AND NOT BEOS AND NOT HAIKU)
  target_link_libraries (darcomage dl)
endif (UNIX AND NOT APPLE AND NOT BEOS AND NOT HAIKU)

if (NOT DYNAMIC_LINKING)
  # GEm: Tell the linker about Lua 5.1, needed for LuaD
  find_package (Lua51 REQUIRED)
  if (LUA51_FOUND)
    include_directories(${LUA_INCLUDE_DIR})
    target_link_libraries (darcomage ${LUA_LIBRARIES})
  endif (LUA51_FOUND)
endif (NOT DYNAMIC_LINKING)

# GEm: Do not link in SDL2main.lib, it's not needed for Derelict
SET (SDL2_BUILDING_LIBRARY ON)
# GEm: Tell the linker about SDL2, needed for window creation
find_package (SDL2 REQUIRED)
if (SDL2_FOUND)
  include_directories(${SDL2_INCLUDE_DIR})
  target_link_libraries (darcomage ${SDL2_LIBRARY})
endif (SDL2_FOUND)

# GEm: Tell the linker about SDL2_ttf, needed for fonts
find_package (SDL2_ttf REQUIRED)
if (SDL2_TTF_FOUND)
  include_directories(${SDL2_TTF_INCLUDE_DIRS})
  target_link_libraries (darcomage ${SDL2_TTF_LIBRARIES})
endif (SDL2_TTF_FOUND)

# GEm: Tell the linker about SDL2_image, needed for resource loading
find_package (SDL2_image REQUIRED)
if (SDL2_IMAGE_FOUND)
  include_directories(${SDL2_IMAGE_INCLUDE_DIRS})
  target_link_libraries (darcomage ${SDL2_IMAGE_LIBRARIES})
endif (SDL2_IMAGE_FOUND)

# GEm: Tell the linker about SDL2_mixer, needed for audio
find_package (SDL2_mixer REQUIRED)
if (SDL2_MIXER_FOUND)
  include_directories(${SDL2_MIXER_INCLUDE_DIRS})
  target_link_libraries (darcomage ${SDL2_MIXER_LIBRARIES})
endif (SDL2_MIXER_FOUND)

# GEm: Tell the linker about OpenGL, needed for graphics
# GEm: Workaround for broken search script
SET (X11_FOUND "ON")
find_package (OpenGL REQUIRED)
if (OPENGL_FOUND)
  include_directories(${OPENGL_INCLUDE_DIR})
  target_link_libraries (darcomage ${OPENGL_LIBRARIES})
endif (OPENGL_FOUND)

# GEm: Install the executable
INSTALL (TARGETS darcomage RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

# GEm: Install the DLLs
IF (WIN32)
  STRING (REPLACE ".lib" ".dll" LUA_DLLS ${LUA_LIBRARIES})
  SET (LUA_DLLS "${LUA_DLLS}" CACHE FILEPATH "Path to the Lua51 DLL file")
  INSTALL (FILES ${LUA_DLLS} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "lua51.lib" "lua5.1.dll" LUA_DLL ${LUA_LIBRARIES})
  SET (LUA_DLL "${LUA_DLL}" CACHE FILEPATH "Path to the Lua5.1 DLL file")
  INSTALL (FILES ${LUA_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE ".lib" ".dll" SDL2_DLL ${SDL2_LIBRARY})
  SET (SDL2_DLL "${SDL2_DLL}" CACHE FILEPATH "Path to the SDL2 DLL file")
  INSTALL (FILES ${SDL2_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE ".lib" ".dll" SDL2_IMAGE_DLL ${SDL2_IMAGE_LIBRARY})
  SET (SDL2_IMAGE_DLL "${SDL2_IMAGE_DLL}" CACHE FILEPATH "Path to the SDL2_image DLL file")
  INSTALL (FILES ${SDL2_IMAGE_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_image.lib" "zlib1.dll" ZLIB_DLL ${SDL2_IMAGE_LIBRARY})
  SET (ZLIB_DLL "${ZLIB_DLL}" CACHE FILEPATH "Path to the zlib DLL file")
  INSTALL (FILES ${ZLIB_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_image.lib" "libjpeg-9.dll" JPEG_DLL ${SDL2_IMAGE_LIBRARY})
  SET (JPEG_DLL "${JPEG_DLL}" CACHE FILEPATH "Path to the JPEG DLL file")
  INSTALL (FILES ${JPEG_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_image.lib" "libpng16-16.dll" PNG_DLL ${SDL2_IMAGE_LIBRARY})
  SET (PNG_DLL "${PNG_DLL}" CACHE FILEPATH "Path to the PNG DLL file")
  INSTALL (FILES ${PNG_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_image.lib" "libtiff-5.dll" TIFF_DLL ${SDL2_IMAGE_LIBRARY})
  SET (TIFF_DLL "${TIFF_DLL}" CACHE FILEPATH "Path to the TIFF DLL file")
  INSTALL (FILES ${TIFF_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_image.lib" "libwebp-4.dll" WEBP_DLL ${SDL2_IMAGE_LIBRARY})
  SET (WEBP_DLL "${WEBP_DLL}" CACHE FILEPATH "Path to the WEBP DLL file")
  INSTALL (FILES ${WEBP_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE ".lib" ".dll" SDL2_TTF_DLL ${SDL2_TTF_LIBRARY})
  SET (SDL2_TTF_DLL "${SDL2_TTF_DLL}" CACHE FILEPATH "Path to the SDL2_ttf DLL file")
  INSTALL (FILES ${SDL2_TTF_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_ttf.lib" "libfreetype-6.dll" FREETYPE_DLL ${SDL2_TTF_LIBRARY})
  SET (FREETYPE_DLL "${FREETYPE_DLL}" CACHE FILEPATH "Path to the FreeType DLL file")
  INSTALL (FILES ${FREETYPE_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE ".lib" ".dll" SDL2_MIXER_DLL ${SDL2_MIXER_LIBRARY})
  SET (SDL2_MIXER_DLL "${SDL2_MIXER_DLL}" CACHE FILEPATH "Path to the SDL2_mixer DLL file")
  INSTALL (FILES ${SDL2_MIXER_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "smpeg2.dll" SMPEG_DLL ${SDL2_MIXER_LIBRARY})
  SET (SMPEG_DLL "${SMPEG_DLL}" CACHE FILEPATH "Path to the SMPEG DLL file")
  INSTALL (FILES ${SMPEG_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libFLAC-8.dll" FLAC_DLL ${SDL2_MIXER_LIBRARY})
  SET (FLAC_DLL "${FLAC_DLL}" CACHE FILEPATH "Path to the FLAC DLL file")
  INSTALL (FILES ${FLAC_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libmikmod-2.dll" MIKMOD_DLL ${SDL2_MIXER_LIBRARY})
  SET (MIKMOD_DLL "${MIKMOD_DLL}" CACHE FILEPATH "Path to the MikMod DLL file")
  INSTALL (FILES ${MIKMOD_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libmodplug-1.dll" MODPLUG_DLL ${SDL2_MIXER_LIBRARY})
  SET (MODPLUG_DLL "${MODPLUG_DLL}" CACHE FILEPATH "Path to the MODPlug DLL file")
  INSTALL (FILES ${MODPLUG_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libogg-0.dll" OGG_DLL ${SDL2_MIXER_LIBRARY})
  SET (OGG_DLL "${OGG_DLL}" CACHE FILEPATH "Path to the OGG DLL file")
  INSTALL (FILES ${OGG_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libvorbis-0.dll" VORBIS_DLL ${SDL2_MIXER_LIBRARY})
  SET (VORBIS_DLL "${VORBIS_DLL}" CACHE FILEPATH "Path to the Vorbis DLL file")
  INSTALL (FILES ${VORBIS_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
  STRING (REPLACE "SDL2_mixer.lib" "libvorbisfile-3.dll" VORBISFILE_DLL ${SDL2_MIXER_LIBRARY})
  SET (VORBISFILE_DLL "${VORBISFILE_DLL}" CACHE FILEPATH "Path to the VorbisFile DLL file")
  INSTALL (FILES ${VORBISFILE_DLL} DESTINATION ${CMAKE_INSTALL_BINDIR})
ENDIF (WIN32)
