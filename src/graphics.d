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

module graphics;
import std.stdio;
import std.math;
import std.random;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import opengl;

SDL_Window* Window;
SDL_GLContext OGLContext;

struct Size
{
    int x;
    int y;
}
struct SizeF
{
    float x;
    float y;
}

SizeF[][] CardLocations; //GE: Where on the screen all our cards are.

struct CachedCard
{
    OpenGLTexture TitleTexture;
    int PictureHandle; //GE: Links to PictureFileCache[PictureHandle]
    SDL_Rect PictureCoords;
    OpenGLTexture[] DescriptionTextures;
    OpenGLTexture[3] PriceTexture; //GE: Bricks, gems, recruits
}
CachedCard[][] CardCache;

void SDLInit()
{
    DerelictSDL2.load(); // GEm: It autothrows things, neat!
    DerelictSDL2Image.load();

    // GEm: No worries about parachutes in SDL2, woo!
    if (SDL_Init(SDL_INIT_VIDEO) < 0)
        throw new Exception("SDLInit: Couldn't initialise SDL:"~SDL_GetError()); // GEm: Throwing things like a boss!

    // GEm: A nicer way to get ourselves a window to play in!
    Window = SDL_CreateWindow("DArcomage",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        Config.ResolutionX, Config.ResolutionY,
        (Config.Fullscreen*SDL_WINDOW_FULLSCREEN_DESKTOP) | SDL_WINDOW_OPENGL);
    if (Window == NULL)
        throw new Exception("SDLInit: Couldn't create a window:"~SDL_GetError());

    InitDerelictGL3();

    OGLContext = SDL_GL_CreateContext(window);
    if (OGLContext == NULL)
        throw new Exception("SDLInit: Couldn't create an OpenGL context:"~SDL_GetError());

    InitOpenGL();

    version(Windows)
        LoadSurface("boss_windows.png", GfxSlot.Boss);
    else
        LoadSurface("boss_linux.png", GfxSlot.Boss);
    LoadSurface("Sprites.PNG", GfxSlot.Sprites);
    LoadSurface("Title.PNG", GfxSlot.Title);
    LoadSurface("Layout.PNG", GfxSlot.GameBG);
    /*if (!GetConfig(UseOriginalMenu))
    {
        LoadSurface(GetFilePath("menu.png"),&GfxData[MENU]);
        LoadSurface(GetFilePath("menuitems.png"),&GfxData[MENUITEMS]);
        LoadSurface(GetFilePath("gamebg.png"),&GfxData[GAMEBG]);
    }
    LoadSurface(GetFilePath("credits.png"),&GfxData[CREDITS]);
    if (!GetConfig(UseOriginalCards))
        LoadSurface(GetFilePath("deck.png"),&GfxData[DECK]);
    else
      LoadSurface(GetFilePath("SPRITES.bmp"),&GfxData[DECK]);
    SDL_SetColorKey(GfxData[DECK],SDL_SRCCOLORKEY,SDL_MapRGB(GfxData[DECK]->format,255,0,255));
    LoadSurface(GetFilePath("nums_big.png"),&GfxData[NUMSBIG]);
    SDL_SetColorKey(GfxData[NUMSBIG],SDL_SRCCOLORKEY,SDL_MapRGB(GfxData[NUMSBIG]->format,255,0,255));
    LoadSurface(GetFilePath("castle.png"),&GfxData[CASTLE]);*/

    LoadSurface("dlgmsg.png", GfxSlot.DlgMsg);
    LoadSurface("dlgerror.png", GfxSlot.DlgError);
    LoadSurface("dlgnetwork.png", GfxSlot.DlgNetwork);
    LoadSurface("dlgwinner.png", GfxSlot.DlgWinner);
    LoadSurface("dlglooser.png", GfxSlot.DlgLoser);

    InitCardLocations(2);
}

void LoadSurface(string Filename, int Slot)
{
    SDL_Surface* Surface;
    char* CFilename;

    CFilename = GetCFilePath(Filename);

    Surface = IMG_Load(CFilename);
    if (!Surface)
        throw new Exception("LoadSurface: Failed to load "~Filename~":"~SDL_GetError());
    GfxData[Slot] = SurfaceToTexture(Surface);
    TextureCoordinates[Slot].X = (*Surface).w; TextureCoordinates[Slot].Y = (*Surface).h;
    SDL_FreeSurface(Surface);
}

/**
 * Initialise the position of each card in both hands. It is slightly randomised
 * on height to provide an illusion of being true cards (which are rarely neatly
 * aligned in the real world).
 */
void InitCardLocations(int NumPlayers)
{
    int i, n;
    int NumCards = Config.CardsInHand;
    float DrawScale = GetDrawScale();
    float CardWidth = NumCards*192*DrawScale/float(Config.ResolutionX);
    float Spacing = (1.0-CardWidth)/(NumCards+1);

    CardLocations.length = NumPlayers;
    for (i=0; i < NumPlayers; i++)
    {
        CardLocations[i].length = NumCards;
        for (n=0; n < NumCards; n++)
        {
            CardLocations[i][n].X = Spacing * (n+1) + 192 * DrawScale * n / float(Config.ResolutionX);
            CardLocations[i][n].Y = (uniform(-6.0, 6.0)+(6.0 + 466.0*!i))/600.0; //GEm: TODO: Implement more than 2 players - how to solve this?
        }
    }
}

void PrecacheCards()
{
    CardCache.length = CardDB.length;
    foreach (int i, CardInfo[] Pool; CardDB)
        CardCache[i].length = Pool.length;

    PrecacheFonts();

    PrecachePictures(NumPools, NumCards);
}

/**
 * Returns the element draw size depending on the currently selected
 * window resolution.
 * 1600x1200 is the current native resolution of all the GfxSlot.Sprites assets.
 *
 * Could be made pure, but that requires Config to be immutable, which in turn
 * requires Lua reading code to be in a constructor...
 */
auto GetDrawScale()
{
    return fmin(real(Config.ResolutionX)/1600.0, real(Config.ResolutionY)/1200.0);
}

char* GetCFilePath(string Path)
{
    return toStringz(Config.DataDir~Path);
}
