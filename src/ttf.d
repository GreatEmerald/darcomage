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
import std.string;
import std.conv;
import std.stdio;
import std.math;
import derelict.sdl2.ttf;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import arco;
import cards;
import graphics;
import opengl;

enum FontSlots
{
    Title,
    Description,
    Name, //GEm: This is the font for the player's name.
    Message
}
TTF_Font*[FontSlots.max+1] Fonts; //GE: Array of fonts in use.

enum NumberSlots
{
    Big,
    Medium,
    Small
}
TTF_Font*[NumberSlots.max+1] NumberFonts; //GE: Array of fonts that render numbers in use.
OpenGLTexture NumberCache[NumberSlots.max+1][10];

OpenGLTexture[2] NameCache; //GEm: FIXME - needs to be dynamic

/**
 * A shortened initialisation function for TTF.
 */
void InitTTF()
{
    int a, b, c, d;

    DerelictSDL2ttf.load();

    if (TTF_Init() == -1)
        throw new Exception("Error: ttf: InitTTF: Failed to init: "~to!string(TTF_GetError()));

    Fonts[FontSlots.Description] = TTF_OpenFont(GetCFilePath("fonts/FreeSans.ttf"), cast(int)(GetDrawScale()*2*10));
    Fonts[FontSlots.Message] = TTF_OpenFont(GetCFilePath("fonts/FreeSansBold.ttf"), cast(int)(GetDrawScale()*2*20));
    Fonts[FontSlots.Title] = TTF_OpenFont(GetCFilePath("fonts/FreeSans.ttf"), FindOptimalFontSize());
    Fonts[FontSlots.Name] = TTF_OpenFont(GetCFilePath("fonts/FreeMono.ttf"), cast(int)(GetDrawScale()*2*11));//7
    if (!Fonts[FontSlots.Description])
        throw new Exception("Error: ttf: InitTTF: Failed to load fonts: "~to!string(TTF_GetError()));

    NumberFonts[NumberSlots.Big] = TTF_OpenFont(GetCFilePath("fonts/FreeMonoBold.ttf"), cast(int)(GetDrawScale()*2*27));//17
    NumberFonts[NumberSlots.Medium] = TTF_OpenFont(GetCFilePath("fonts/FreeMonoBold.ttf"), cast(int)(GetDrawScale()*2*16));//10
    NumberFonts[NumberSlots.Small] = TTF_OpenFont(GetCFilePath("fonts/FreeMono.ttf"), cast(int)(GetDrawScale()*2*11));//7

    PrecacheCards();
}

void QuitTTF()
{
    foreach (TTF_Font* Font; Fonts)
        TTF_CloseFont(Font);
    foreach (TTF_Font* NumberFont; NumberFonts)
        TTF_CloseFont(NumberFont);
    TTF_Quit();
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

void PrecacheDescriptionText()
{
    Size CardSize;
    string[] SplitLines, SplitWords;
    int LineLength;
    string CurrentLine;

    CardSize.X = cast(int)(GetDrawScale()*2*92);

    foreach (int PoolNum, CardInfo[] Cards; CardDB)
    {
        foreach (int CardNum, CardInfo CurrentCard; Cards)
        {
            SplitLines = split(CurrentCard.Description, "\n");
            foreach (string Line; SplitLines)
            {
                CurrentLine = "";
                SplitWords = split(Line);
                foreach (int WordNum, string Word; SplitWords)
                {
                    if (WordNum == 0)
                    {
                        // GEm: We always assume the first word fits.
                        CurrentLine = Word;
                        // GEm: If this is both the first and last word in the line, automatically write.
                        if (WordNum == SplitWords.length - 1)
                            CacheDescription(PoolNum, CardNum, CurrentLine);
                        continue;
                    }
                    else
                        TTF_SizeText(Fonts[FontSlots.Description], toStringz(CurrentLine~" "~Word), &LineLength, null);

                    // GEm: Will adding one more word make it not fit the card?
                    if (LineLength > CardSize.X)
                    {
                        // GEm: Write CurrentLine
                        CacheDescription(PoolNum, CardNum, CurrentLine);
                        CurrentLine = Word;
                    }
                    else
                        CurrentLine ~= " "~Word;

                    // GEm: Are we at the end of the line already?
                    if (WordNum == SplitWords.length - 1)
                    {
                        // GEm: Write whatever is left.
                        CacheDescription(PoolNum, CardNum, CurrentLine);
                    }
                }
            }
        }
    }
}

void CacheDescription(int PoolNum, int CardNum, string Text)
{
    GLuint CurrentTexture;
    Size TextureSize;
    OpenGLTexture CachedTexture;

    CurrentTexture = TextToTexture(Fonts[FontSlots.Description], Text);
    TTF_SizeText(Fonts[FontSlots.Description], toStringz(Text), &(TextureSize.X), &(TextureSize.Y));

    CachedTexture.Texture = CurrentTexture;
    CachedTexture.TextureSize = TextureSize;
    CardCache[PoolNum][CardNum].DescriptionTextures ~= CachedTexture;
}

void PrecachePriceText()
{
    Size ZeroSize;
    GLuint ZeroTexture = TextToTexture(Fonts[FontSlots.Title], "0"); //GE: Small optimisation - 0 is very common, so use a common texture for that
    TTF_SizeText(Fonts[FontSlots.Title], toStringz("0"), &(ZeroSize.X), &(ZeroSize.Y));

    foreach (int PoolNum, CardInfo[] Cards; CardDB)
    {
        foreach (int CardNum, CardInfo CurrentCard; Cards)
        {
            PrecacheSingleResource(PoolNum, CardNum, 0, CurrentCard.BrickCost, ZeroTexture, ZeroSize);
            PrecacheSingleResource(PoolNum, CardNum, 1, CurrentCard.GemCost, ZeroTexture, ZeroSize);
            PrecacheSingleResource(PoolNum, CardNum, 2, CurrentCard.RecruitCost, ZeroTexture, ZeroSize);
        }
    }
}

void PrecacheSingleResource(int PoolNum, int CardNum, int ResourceType, int ResourceCost, GLuint ZeroTexture, Size ZeroSize)
{
    Size TexSize;
    string ReadableNumber;

    if (ResourceCost > 0)
    {
        ReadableNumber = to!string(ResourceCost);
        TTF_SizeText(Fonts[FontSlots.Title], toStringz(ReadableNumber), &(TexSize.X), &(TexSize.Y));
        CardCache[PoolNum][CardNum].PriceTexture[ResourceType].Texture = TextToTexture(Fonts[FontSlots.Title], ReadableNumber);
        CardCache[PoolNum][CardNum].PriceTexture[ResourceType].TextureSize = TexSize;
    }
    else
    {
        CardCache[PoolNum][CardNum].PriceTexture[ResourceType].Texture = ZeroTexture;
        CardCache[PoolNum][CardNum].PriceTexture[ResourceType].TextureSize = ZeroSize;
    }
}

void PrecacheNumbers()
{
    int i, n;
    string ReadableNumber; // GEm: Has to be a string, even if it's a single char
    SDL_Color Colour = {200, 200, 0};

    for (n = 0; n <= NumberSlots.max; n++)
    {
        for (i = 0; i < 10; i++) // GEm: Numbers match their positions, NS[0]=0, NS[9]=9
        {
            ReadableNumber = to!string(i);
            if (n == NumberSlots.Medium)
                NumberCache[n][i].Texture = TextToTexture(NumberFonts[n], ReadableNumber);
            else
                NumberCache[n][i].Texture = TextToTextureColour(NumberFonts[n], ReadableNumber, Colour);
            TTF_SizeText(NumberFonts[n], toStringz(ReadableNumber),
                &(NumberCache[n][i].TextureSize.X), &(NumberCache[n][i].TextureSize.Y)); //GEm: We are the knights who say NI!
        }
    }
}

void PrecachePlayerNames()
{
    int NumPlayers = 2; //GEm: TODO implement variable amount of players!
    int i;
    SDL_Color Colour = {200, 200, 0};

    for (i=0; i<NumPlayers; i++)
    {
        NameCache[i].Texture = TextToTextureColour(Fonts[FontSlots.Name], Player[i].Name, Colour);
        TTF_SizeText(Fonts[FontSlots.Name], toStringz(Player[i].Name), &(NameCache[i].TextureSize.X), &(NameCache[i].TextureSize.Y));
    }
}

/**
 * Draws specified text in a specified font and specified position
 */
void DrawCustomTextCentred(string Text, int FontType, SizeF BoxLocation, SizeF BoxSize)
{
    GLuint Texture;
    Size TextureSize;
    SizeF RelativeSize;

    SDL_Color Colour = {255, 255, 255};
    Texture = TextToTextureColour(Fonts[FontType], Text, Colour);

    TTF_SizeText(Fonts[FontSlots.Message], toStringz(Text), &(TextureSize.X), &(TextureSize.Y));
    RelativeSize.X = TextureSize.X / cast(float)Config.ResolutionX;
    RelativeSize.Y = TextureSize.Y / cast(float)Config.ResolutionY;
    BoxLocation = CentreOnX(BoxLocation, RelativeSize, BoxSize);

    DrawTexture(Texture, TextureSize, AbsoluteTextureSize(TextureSize), BoxLocation, 1.0);

    /* Clean up */
    glDeleteTextures(1, &Texture);
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

/**
 * Finds the best card name font size for the current resolution and deck.
 */
int FindOptimalFontSize()
{
    Size CardSize;
    int LineLength;
    TTF_Font* ProbeFont;
    int InitialSize = cast(int)(GetDrawScale()*2*10);
    float FontScaler = 1.0;

    CardSize.X = cast(int)(GetDrawScale()*2*92);
    ProbeFont = TTF_OpenFont(GetCFilePath("fonts/FreeSans.ttf"), InitialSize);

    foreach (CardInfo[] Cards; CardDB)
    {
        foreach (CardInfo CurrentCard; Cards)
        {
            TTF_SizeText(ProbeFont, toStringz(CurrentCard.Name), &LineLength, null);
            FontScaler = fmin(FontScaler, cast(float)CardSize.X / cast(float)LineLength);
        }
    }
    TTF_CloseFont(ProbeFont);
    return cast(int)(cast(float)InitialSize * FontScaler);
}
