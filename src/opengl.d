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
import std.conv;
import derelict.opengl3.gl;
import derelict.sdl2.sdl;
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
}

void InitOpenGL()
{
    // GEm: We need OpenGL 1.4 (for mipmaps)!
    auto MaxVer = DerelictGL.reload();
    if (MaxVer < GLVersion.GL14)
        throw new Exception("opengl.InitDerelictGL3: Could not load OpenGL 1.4! Check if your hardware and software supports it.");

    glEnable(GL_TEXTURE_2D); //Enable 2D texturing support
    glEnable(GL_BLEND); //GE: Enable AlphaBlend
    glEnable(GL_POINT_SMOOTH); // GEm: Enable drawing point particles
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
    nOfColors = surface.format.BytesPerPixel;
    if (nOfColors == 4)     // contains an alpha channel
    {
        if (surface.format.Rmask == 0x000000ff)
            texture_format = GL_RGBA;
        else
            texture_format = GL_BGRA;
    }
    else if (nOfColors == 3)     // no alpha channel
    {
        if (surface.format.Rmask == 0x000000ff)
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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    // GEm: Use mipmaps so that we would get nicer downscaling.
    // GEm: OpenGL 1.4-3.0 only!
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);

    // Edit the texture object's image data using the information SDL_Surface gives us
    glTexImage2D(GL_TEXTURE_2D, 0, nOfColors, surface.w, surface.h, 0,
        texture_format, GL_UNSIGNED_BYTE, surface.pixels);

    return texture;
}

void FreeTexture(GLuint Texture)
{
    if (glIsTexture(Texture))
        glDeleteTextures(1, &Texture);
}

/**
 * Draw an OpenGL texture on the screen.
 * \param Texture The OpenGL texture handler.
 * \param TexSize Two ints that show the size of the texture in the handler. You get this by looking into TextureCoordinates[].
 * \param SourceCoords A SDL_Rect that defines what part of the texture to draw.
 * \param DestinationCoords Two floats that define, in percentage, where the texture is to be positioned on the screen. The values indicate the top left pixel.
 * \param ScaleFactor A float that indicates (in percentage) the amount of scaling to use. For the original data scaled only by the chosen resolution, use 1.0.
 * \param Alpha Lack of translucency (0-1)
 */
void DrawTextureAlpha(GLuint Texture, Size TexSize, SDL_Rect SourceCoords, SizeF DestinationCoords, float ScaleFactor, float Alpha)
{
    int ResX = Config.ResolutionX;
    int ResY = Config.ResolutionY;
    float DestinationW = cast(float)SourceCoords.w * ScaleFactor;
    float DestinationH = cast(float)SourceCoords.h * ScaleFactor;

    if (!glIsTexture(Texture))
        writeln("Warning: opengl: DrawTextureAlpha: This is not a valid OpenGL texture: "~to!string(Texture));
    //printf("Info: DrawTexture: Called with (%d, {%d, %d}, {%d, %d, %d, %d}, {%f, %f}, %f)\n", Texture, TexSize.X, TexSize.Y, SourceCoords.x, SourceCoords.y, SourceCoords.w, SourceCoords.h, DestinationCoords.X, DestinationCoords.Y, ScaleFactor);

    //GEm: Normalise destination coordinates (drop half-pixels)
    DestinationCoords.X = (cast(int)(DestinationCoords.X * ResX)) / cast(float)ResX;
    DestinationCoords.Y = (cast(int)(DestinationCoords.Y * ResY)) / cast(float)ResY;

    // Bind the texture to which subsequent calls refer to
    // GEm: OpenGL 1.1+ only!
    glBindTexture(GL_TEXTURE_2D, Texture);

    glColor4f(1.0, 1.0, 1.0, Alpha);
    glBegin(GL_QUADS);
        //Top-left vertex (corner)
        glTexCoord2f(cast(float)SourceCoords.x / cast(float)TexSize.X,
            cast(float)SourceCoords.y / cast(float)TexSize.Y);
        glVertex2f(cast(float)DestinationCoords.X,
            cast(float)DestinationCoords.Y);
        //printf("Info: DrawTexture: Drawing glTexCoord2f(%f, %f); glVertex2f(%f, %f)\n", (float)SourceCoords.x/(float)TexSize.X, (float)SourceCoords.y/(float)TexSize.Y, (float)DestinationCoords.X, (float)DestinationCoords.Y);

        //Top-right vertex (corner)
        glTexCoord2f((cast(float)SourceCoords.x + cast(float)SourceCoords.w) / cast(float)TexSize.X,
            cast(float)SourceCoords.y / cast(float)TexSize.Y);
        glVertex2f(cast(float)DestinationCoords.X + DestinationW / cast(float)ResX,
            cast(float)DestinationCoords.Y);
        //printf("Info: DrawTexture: Drawing glTexCoord2f(%f, %f); glVertex2f(%f, %f)\n", ((float)SourceCoords.x+(float)SourceCoords.w)/(float)TexSize.X, (float)SourceCoords.y/(float)TexSize.Y, (float)DestinationCoords.X+DestinationW/(float)ResX, (float)DestinationCoords.Y);

        //Bottom-right vertex (corner)
        glTexCoord2f((cast(float)SourceCoords.x + cast(float)SourceCoords.w) / cast(float)TexSize.X,
            (cast(float)SourceCoords.y + cast(float)SourceCoords.h) / cast(float)TexSize.Y);
        glVertex2f(cast(float)DestinationCoords.X + DestinationW / cast(float)ResX,
            cast(float)DestinationCoords.Y + DestinationH / cast(float)ResY);
        //printf("Info: DrawTexture: Drawing glTexCoord2f(%f, %f); glVertex2f(%f, %f)\n", ((float)SourceCoords.x+(float)SourceCoords.w)/(float)TexSize.X, ((float)SourceCoords.y+(float)SourceCoords.h)/(float)TexSize.Y, (float)DestinationCoords.X+DestinationW/(float)ResX, (float)DestinationCoords.Y+DestinationH/(float)ResY);

        //Bottom-left vertex (corner)
        glTexCoord2f(cast(float)SourceCoords.x / cast(float)TexSize.X,
            (cast(float)SourceCoords.y + cast(float)SourceCoords.h) / cast(float)TexSize.Y);
        glVertex2f(cast(float)DestinationCoords.X,
            cast(float)DestinationCoords.Y + DestinationH / cast(float)ResY);
        //printf("Info: DrawTexture: Drawing glTexCoord2f(%f, %f); glVertex2f(%f, %f)\n", (float)SourceCoords.x/(float)TexSize.X, ((float)SourceCoords.y+(float)SourceCoords.h)/(float)TexSize.Y, (float)DestinationCoords.X, (float)DestinationCoords.Y+DestinationH/(float)ResY);
    glEnd();
}

/**
 * Simplified version of DrawTextureAlpha.
 */
void DrawTexture(GLuint Texture, Size TexSize, SDL_Rect SourceCoords, SizeF DestinationCoords, float ScaleFactor)
{
    DrawTextureAlpha(Texture, TexSize, SourceCoords, DestinationCoords, ScaleFactor, 1.0);
}

/// Draws a solid-colour rectangle.
void DrawRectangle(SizeF DestinationCoords, SizeF DestinationWH, SDL_Color Colour)
{
    //We need a solid colour, thus texturing support is irrelevant. Also, this does not affect things we have already rendered.
    glDisable(GL_TEXTURE_2D);
    MakeGLColour(Colour);
    glRectf(DestinationCoords.X, DestinationCoords.Y,
        DestinationCoords.X + DestinationWH.X, DestinationCoords.Y + DestinationWH.Y);
    glEnable(GL_TEXTURE_2D);
}

/// Draws a gradient rectangle between colours A and B
void DrawGradient(SizeF DestinationCoords, SizeF DestinationWH, SDL_Color ColourA, SDL_Color ColourB)
{
    //We need a solid colour, thus texturing support is irrelevant. Also, this does not affect things we have already rendered.
    glDisable(GL_TEXTURE_2D);
    glBegin(GL_POLYGON);
        MakeGLColour(ColourA);
        glVertex2f(DestinationCoords.X, DestinationCoords.Y);
        glVertex2f(DestinationCoords.X + DestinationWH.X, DestinationCoords.Y);
        MakeGLColour(ColourB);
        glVertex2f(DestinationCoords.X + DestinationWH.X, DestinationCoords.Y + DestinationWH.Y);
        glVertex2f(DestinationCoords.X, DestinationCoords.Y + DestinationWH.Y);
    glEnd();
    glEnable(GL_TEXTURE_2D);
}

/**
 * Draws a 1px+ border of a rectangle, in the given rectangle.
 *
 * Fairly hackily, by drawing four rectangles. Could be done more neatly using
 * a texture, but a rectangle isn't regarded as a texture.
 */
void DrawHollowRectangle(SizeF DestinationCoords, SizeF DestinationWH, SDL_Color Colour)
{
    SizeF NewSize = DestinationWH;
    SizeF NewDestination = DestinationCoords;

    NewSize.X = 1.0 / 800.0;
    DrawRectangle(DestinationCoords, NewSize, Colour);

    NewSize = DestinationWH;
    NewSize.Y = 1.0 / 600.0;
    DrawRectangle(DestinationCoords, NewSize, Colour);

    NewSize = DestinationWH;
    NewDestination.Y += DestinationWH.Y;
    NewSize.Y = 1.0 / 800.0;
    DrawRectangle(NewDestination, NewSize, Colour);

    NewDestination = DestinationCoords;
    NewSize = DestinationWH;
    NewDestination.X += DestinationWH.X;
    NewSize.X = 1.0 / 600.0;
    DrawRectangle(NewDestination, NewSize, Colour);
}

/// Draws a coloured point in the destination. Used for particles!
void DrawPoint(SizeF DestinationCoords, float Radius, SDL_Color Colour)
{
    glPointSize(Radius * 1.0/GetDrawScale()); // GEm: The radius of particles. This is actual pixels, as internally pixel shaders are used.
    glDisable(GL_TEXTURE_2D);
    glBegin(GL_POINTS);
        MakeGLColour(Colour);
        glVertex2f(DestinationCoords.X, DestinationCoords.Y);
    glEnd();
    glEnable(GL_TEXTURE_2D);
}

void ClearScreen()
{
    glClear(GL_COLOR_BUFFER_BIT);
}

void MakeGLColour(SDL_Color Colour)
{
    glColor4f(cast(float)Colour.r / 255.0, cast(float)Colour.g / 255.0,
            cast(float)Colour.b / 255.0, cast(float)Colour.unused / 255.0);
}
