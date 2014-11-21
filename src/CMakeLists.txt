include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# GEm: Our own sources
SET (DARCOMAGE_SOURCES frontend.d input.d graphics.d font.d opengl.d sound.d)
if (NOT DYNAMIC_LINKING)
  add_executable (darcomage WIN32
    ${DARCOMAGE_SOURCES}
    ${LUAD_FILE_PATHS}
    ${LIBARCOMAGE_FILE_PATHS}
    ${DERELICT_FILE_PATHS}
  )
endif (NOT DYNAMIC_LINKING)

# GEm: Tell the linker about Lua 5.1, needed for LuaD
find_package (Lua51 REQUIRED)
if (LUA51_FOUND)
  include_directories(${LUA_INCLUDE_DIR})
  target_link_libraries (darcomage ${LUA_LIBRARIES})
endif (LUA51_FOUND)

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
find_package (OpenGL REQUIRED)
if (OPENGL_FOUND)
  include_directories(${OPENGL_INCLUDE_DIR})
  target_link_libraries (darcomage ${OPENGL_LIBRARIES})
endif (OPENGL_FOUND)
