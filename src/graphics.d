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

import std.stdio;
import derelict.sdl2.sdl;

SDL_Window* Window;
SDL_GLContext OGLContext;

void SDLInit()
{
    DerelictSDL2.load(); // GEm: It autothrows things, neat!

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

    OGLContext = SDL_GL_CreateContext(window);
    if (OGLContext == NULL)
        throw new Exception("SDLInit: Couldn't create an OpenGL context:"~SDL_GetError());

    InitOpenGL();

    #ifdef linux
        LoadSurface(GetFilePath("boss_linux.png"),BOSS);
    #else
        LoadSurface(GetFilePath("boss_windows.png"),BOSS);
    #endif
    LoadSurface(GetFilePath("Sprites.PNG"),SPRITES);
    LoadSurface(GetFilePath("Title.PNG"),TITLE);
    LoadSurface(GetFilePath("Layout.PNG"),GAMEBG);
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

    LoadSurface(GetFilePath("dlgmsg.png"),DLGMSG);
    LoadSurface(GetFilePath("dlgerror.png"),DLGERROR);
    LoadSurface(GetFilePath("dlgnetwork.png"),DLGNETWORK);
    LoadSurface(GetFilePath("dlgwinner.png"),DLGWINNER);
    LoadSurface(GetFilePath("dlglooser.png"),DLGLOOSER);

    /*SDL_SetColorKey(GfxData[CASTLE],SDL_SRCCOLORKEY,SDL_MapRGB(GfxData[CASTLE]->format,255,0,255));

    numssmall=BFont_LoadFont(GetFilePath("nums_small.png"));
    if (!numssmall)
        GeneralProtectionFault("Data file 'nums_small.png' is missing or corrupt.");
    bigfont=BFont_LoadFont(GetFilePath("bigfont.png"));
    if (!bigfont)
        GeneralProtectionFault("Data file 'bigfont.png' is missing or corrupt.");
    font=BFont_LoadFont(GetFilePath("font.png"));
    if (!font)
        GeneralProtectionFault("Data file 'font.png' is missing or corrupt.");
    BFont_SetCurrentFont(font);*/

    InitCardLocations(2);
}
