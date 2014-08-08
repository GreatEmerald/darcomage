/*
 * Copyright © 2014 GreatEmerald
 *
 * This file is part of DArcomage.
 *
 * DArcomage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

module opengl;
import std.stdio;
import derelict.opengl3.gl;
import arco;
import graphics;

struct OpenGLTexture
{
    GLuint Texture;
    Size TextureSize;
}

enum GfxSlot
{
    Title,
    Sprites,
    GameBG,
    Boss,
    DlgWinner,
    DlgLoser,
    DlgNetwork,
    DlgError,
    DlgMsg,
    OriginalSprites
}

GLuint[GfxSlot.max+1] GfxData;
Size[GfxSlot.max+1] TextureCoordinates;

void InitDerelictGL3()
{
    // GEm: Initialise Derelict OpenGL bindings.
    DerelictGL.load();
    /* GEm: Technically would need to reload to load up non-OpenGL 1.1
            functions. Except we don't use any! Also no sense in checking if we
            have at least OpenGL 1.1 available because Derelict only suspports
            OpenGL 1.1 or above, not plain 1.0. */
}

void InitOpenGL()
{
    glEnable(GL_TEXTURE_2D); //Enable 2D texturing support
    glEnable(GL_BLEND); //GE: Enable AlphaBlend
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); //GE: Set AlphaBlend to not be wacky

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f); //Set the clear colour

    glViewport(0, 0, Config.ResolutionX, Config.ResolutionY); //Set the size of the window.

    glClear(GL_COLOR_BUFFER_BIT); //Clear the screen.

    glMatrixMode(GL_PROJECTION); //Set the output to be a projection (2D plane).
    glLoadIdentity();

    glOrtho(0.0f, 1.0f, 1.0f, 0.0f, -1.0f, 1.0f); //GE: Set the coordinates to be wacky - 1 unit is your resolution

    glMatrixMode(GL_MODELVIEW); //Set to show models.
}

GLuint SurfaceToTexture(SDL_Surface* surface)
{
    GLint  nOfColors;
    GLuint texture;
    GLenum texture_format;

    // get the number of channels in the SDL surface
    nOfColors = surface->format->BytesPerPixel;
    if (nOfColors == 4)     // contains an alpha channel
    {
        if (surface->format->Rmask == 0x000000ff)
            texture_format = GL_RGBA;
        else
            texture_format = GL_BGRA;
    }
    else if (nOfColors == 3)     // no alpha channel
    {
        if (surface->format->Rmask == 0x000000ff)
            texture_format = GL_RGB;
        else
            texture_format = GL_BGR;
    }
    else
    {
        writeln("Warning: SurfaceToTexture: Unknown number of colour channels.");
    }

    // Have OpenGL generate a texture object handle for us
    // GEm: OpenGL 1.1+ only!
    glGenTextures(1, &texture);

    // Bind the texture object
    // GEm: OpenGL 1.1+ only!
    glBindTexture(GL_TEXTURE_2D, texture);

    // Set the texture's stretching properties
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    // Edit the texture object's image data using the information SDL_Surface gives us
    glTexImage2D(GL_TEXTURE_2D, 0, nOfColors, surface->w, surface->h, 0,
        texture_format, GL_UNSIGNED_BYTE, surface->pixels);


    return texture;
}
