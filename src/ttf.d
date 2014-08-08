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

module ttf;
import derelict.sdl2.ttf;
import graphics;

enum FontSlots
{
    Title,
    Description,
    Name, //GEm: This is the font for the player's name.
    Message
}
TTF_Font*[FontSlots.max] Fonts; //GE: Array of fonts in use.

enum NumberSlots
{
    Big,
    Medium,
    Small
}
TTF_Font*[NumberSlots.max] NumberFonts; //GE: Array of fonts that render numbers in use.
/**
 * A shortened initialisation function for TTF.
 */
void InitTTF()
{
    int a, b, c, d;

    DerelictSDL2ttf.load();

    if (TTF_Init() == -1)
        throw new Exception("Error: ttf: InitTTF: Failed to init, "~TTF_GetError());

    Fonts[FontSlots.Description] = TTF_OpenFont(GetCFilePath("fonts/FreeSans.ttf"), FindOptimalFontSize());
    Fonts[FontSlots.Message] = TTF_OpenFont(GetCFilePath("fonts/FreeSansBold.ttf"), cast(int)(GetDrawScale()*2*20));
    Fonts[FontSlots.Title] = TTF_OpenFont(GetCFilePath("fonts/FreeSans.ttf"), cast(int)(GetDrawScale()*2*10));
    Fonts[FontSlots.Name] = TTF_OpenFont(GetCFilePath("fonts/FreeMono.ttf"), cast(int)(GetDrawScale()*2*11));//7
    if (Fonts[Font_Description] == NULL)
        throw new Exception("Error: ttf: InitTTF: Failed to load fonts, "~TTF_GetError());

    NumberFonts[NumberSlots.Big] = TTF_OpenFont(GetCFilePath("fonts/FreeMonoBold.ttf"), cast(int)(GetDrawScale()*2*27));//17
    NumberFonts[NumberSlots.Medium] = TTF_OpenFont(GetCFilePath("fonts/FreeMonoBold.ttf"), cast(int)(GetDrawScale()*2*16));//10
    NumberFonts[NumberSlots.Small] = TTF_OpenFont(GetCFilePath("fonts/FreeMono.ttf"), cast(int)(GetDrawScale()*2*11));//7

    PrecacheCards();
}

void PrecacheFonts()
{
    PrecacheTitleText();
    PrecacheDescriptionText();
    PrecachePriceText();
    PrecacheNumbers();
    //GEm: Make sure you precache player names later on
}

void PrecacheTitleText()
{
    foreach (int PoolNum, CardInfo[] Cards; CardDB)
    {
        foreach (int CardNum, CardInfo CurrentCard; Cards)
        {
            CardCache[PoolNum][CardNum].TitleTexture.Texture = TextToTexture(Fonts[FontSlots.Title], CurrentCard.Name);
            TTF_SizeText(Fonts[FontSlots.Title], toStringz(CurrentCard.Name),
                &(CardCache[PoolNum][CardNum].TitleTexture.TextureSize.X),
                &(CardCache[PoolNum][CardNum].TitleTexture.TextureSize.Y));
        }
    }
}

/**
 * Convert text string into OpenGL texture. Returns its handle.
 */
GLuint TextToTextureColour(TTF_Font* Font, string Text, SDL_Color Colour)
{
    SDL_Surface* Initial;
    GLuint Texture;

    Initial = TTF_RenderText_Blended(Font, toStringz(Text), Colour);
    Texture = SurfaceToTexture(Initial);

    SDL_FreeSurface(Initial);
    return Texture;
}

/**
 * Convert text string into OpenGL texture. Returns its handle.
 */
GLuint TextToTexture(TTF_Font* Font, string Text)
{
    SDL_Color Colour = {0, 0, 0};
    return TextToTextureColour(Font, Text, Colour);
}

// GEm: See Arcomage Clone for a clever but slow algorithm, 10 works for Arcomage
int FindOptimalFontSize()
{
    return 10;
}
