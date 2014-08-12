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
import std.datetime;
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
    OpenGLTexture PictureTexture;
    OpenGLTexture[] DescriptionTextures;
    OpenGLTexture[3] PriceTexture; //GE: Bricks, gems, recruits
}
CachedCard[][] CardCache;

struct CardHandle
{
    int Pool;
    int Card;
    bool bDiscarded;
}
CardHandle[] CardsOnTable;
byte CardInTransit = -1;
bool bDiscardedInTransit;

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
    PrecachePictures();
}

void PrecachePictures()
{
    int EarlierCard;
    string CurrentPath;
    SDL_Surface* Surface;

    foreach (int PoolNum, CardInfo[] Cards; CardDB)
    {
        foreach (int CardNum, CardInfo Card; Cards)
        {
            CurrentPath = GetDPicturePath(PoolNum, CardNum);
            // GEm: Find any duplicates and reuse them
            for (EarlierCard = 0; EarlierCard < CardNum; EarlierCard++)
            {
                if (GetDPicturePath(PoolNum, EarlierCard) == CurrentPath)
                {
                    CardCache[PoolNum][CardNum].PictureTexture.Texture
                        = CardCache[PoolNum][EarlierCard].PictureTexture.Texture;
                    break;
                }
            }
            // GEm: If we had no duplicates, do the heavy lifting ourselves
            if (CardNum == 0 || CardCache[PoolNum][CardNum].PictureTexture.Texture
                != CardCache[PoolNum][EarlierCard].PictureTexture.Texture)
            {
                Surface = IMG_Load(toStringz(CurrentPath));
                if (!Surface)
                    throw new Exception("graphics: PrecachePicture: Failed to load "~CurrentPath~": "~SDL_GetError());
                CardCache[PoolNum][CardNum].PictureTexture.Texture = SurfaceToTexture(Surface);
                SDL_FreeSurface(Surface);
            }
            CardCache[PoolNum][CardNum].PictureTexture.TextureSize.X
                = CardDB[PoolNum][CardNum].Picture.Coordinates.w;
            CardCache[PoolNum][CardNum].PictureTexture.TextureSize.Y
                = CardDB[PoolNum][CardNum].Picture.Coordinates.h;
        }
    }
}

/**
 * Function that the library calls when it's time to draw a card moving.
 */
void PlayCardAnimation(int CardPlace, byte bDiscarded, byte bSameTurn)
{
    immutable int FloatToHnsecs = 1000000;

    SizeF CurrentLocation, BankLocation, Destination;
    long StartTime, CurrentTime;
    float ElapsedPercentage;
    long AnimDuration = 5*FloatToHnsecs;

    Destination.X = 0.5 - 192 * GetDrawScale() / 2.0 / 800.0;
    Destination.Y = 0.5 - 256 * GetDrawScale() / 2.0 / 600.0;
    StartTime = CurrentTime = Clock.currTime.stdTime;
    BankLocation = GetCardOnTableLocation(0);

    while (CurrentTime < StartTime + AnimDuration)
    {
        ClearScreen();
        DrawBackground();

        // GEm: Draw the cards moving into the bank, if any.
        if (!bSameTurn)
        {
            foreach(int i, CardHandle CardOnTable; CardsOnTable)
            {
                CurrentLocation = GetCardOnTableLocation(i + 1);
                CurrentLocation.X = CurrentLocation.X + (BankLocation.X - CurrentLocation.X) * ElapsedPercentage;
                CurrentLocation.Y = CurrentLocation.Y + (BankLocation.Y - CurrentLocation.Y) * ElapsedPercentage;
                DrawHandleCardAlpha(CardOnTable.Pool, CardOnTable.Card, CurrentLocation.X, CurrentLocation.Y,
                    (1.0 - ElapsedPercentage) * (Config.CardTranslucency / 255.0));
            }
        }
        else
            DrawCardsOnTable();

        DrawFolded(0, BankLocation, cast(float)Config.CardTranslucency / 255.0);
        DrawUI();
        DrawStatus();
        DrawPlayerCards(Turn, CardPlace);

        //GEm: Draw the card in transit.
        CurrentLocation.X = CardLocations[Turn][CardPlace].X
            + (Destination.X - CardLocations[Turn][CardPlace].X) * ElapsedPercentage;
        CurrentLocation.Y = CardLocations[Turn][CardPlace].Y
            + (Destination.Y - CardLocations[Turn][CardPlace].Y) * ElapsedPercentage;
        if (bDiscarded) //GEm: If it's discarded, draw it translucent from the get-go.
            DrawCardAlpha(Turn, CardPlace, CurrentLocation.X, CurrentLocation.Y,
                (Config.CardTranslucency / 255.0 - 1.0) * ElapsedPercentage + 1.0);
        else
            DrawCard(Turn, CardPlace, CurrentLocation.X, CurrentLocation.Y);

        UpdateScreen();
        SDL_Delay(10);

        CurrentTime = Clock.currTime.stdTime;
        ElapsedPercentage = (CurrentTime - StartTime) / cast(double)AnimDuration;
    }

    CardInTransit = CardPlace;
    if (bDiscarded)
        bDiscardedInTransit = 1;
    else
        bDiscardedInTransit = 0;

    if (!bSameTurn) //GEm: New turn
    {
        if (CardsOnTable.length > 0)
            CardsOnTable.length = 1;
    }
    else
        CardsOnTable.length++;

    foreach (int a, CardInfo[] Cards; CardDB)
    {
        foreach (int b, CardInfo CI; Cards)
        {
            if (CI == Player[Turn].Hand[CardPlace]) //GEm: Thank goodness D allows this! And hopefully there will be no duplicate cards...
            {
                CardsOnTable[CardsOnTable.length-1].Pool = a;
                CardsOnTable[CardsOnTable.length-1].Card = b;
                break;
            }
        }
    }
    if (bDiscarded)
        CardsOnTable[CardsOnTable.length-1].bDiscarded = true;
    else
        CardsOnTable[CardsOnTable.length-1].bDiscarded = false;
}

/**
 * Plays the animation of the card in transit going to the right location on
 * the table and the bank handing out a card to the player.
 */
void PlayCardPostAnimation(int CardPlace)
{
    DrawScene();
    UpdateScreen();
    SDL_Delay(500); // GEm: A *ta-daaa!* moment

    immutable int FloatToHnsecs = 1000000;

    SizeF Source;
    Source.X = 0.5 - 192 * GetDrawScale() / 2.0 / 800.0;
    Source.Y = 0.5 - 256 * GetDrawScale() / 2.0 / 600.0;
    SizeF Destination = GetCardOnTableLocation(CardsOnTableSize);
    SizeF CurrentLocation;
    long AnimDuration = 5 * FloatToHnsecs;
    long StartTime, CurrentTime;
    StartTime = CurrentTime = Clock.currTime.stdTime;
    float ElapsedPercentage;
    SizeF BankLocation = GetCardOnTableLocation(0);

    while (CurrentTime < StartTime + AnimDuration) //GEm: Move transient card to the table
    {
        ClearScreen();
        DrawBackground();
        DrawFoldedAlpha(0, BankLocation.X, BankLocation.Y, GetConfig(CardTranslucency)/255.0);
        DrawCardsOnTable(false);
        DrawUI();
        DrawStatus();
        DrawPlayerCards(Turn, CardPlace);

        CurrentLocation.X = Source.X + (Destination.X - Source.X) * ElapsedPercentage;
        CurrentLocation.Y = Source.Y + (Destination.Y - Source.Y) * ElapsedPercentage;
        if (bDiscardedInTransit)
        {
            DrawCardAlpha(Turn, CardPlace, CurrentLocation.X, CurrentLocation.Y,
                Config.CardTranslucency / 255.0);
            DrawDiscard(CurrentLocation);
        }
        else
            DrawCardAlpha(Turn, CardPlace, CurrentLocation.X, CurrentLocation.Y,
                (Config.CardTranslucency / 255.0 - 1.0) * ElapsedPercentage + 1.0); //GEm: (Alpha-1)*x+1=f(x)

        UpdateScreen();
        SDL_Delay(10);

        CurrentTime = Clock.currTime.stdTime;
        ElapsedPercentage = (CurrentTime - StartTime) / cast(double)AnimDuration;
    }

    StartTime = CurrentTime = Clock.currTime.stdTime;
    ElapsedPercentage = (CurrentTime - StartTime) / cast(double)AnimDuration;

    //GetCardHandle(Turn, CardPlace, &Pool, &Card);
    CardLocations[Turn][CardPlace].Y = (uniform(-6.0, 6.0) + (6 + 466 * !Turn)) / 600.0; //GEm: TODO implement more than 2 players
    Destination.X = CardLocations[Turn][CardPlace].X;
    Destination.Y = CardLocations[Turn][CardPlace].Y;

    while (CurrentTime < StartTime + AnimDuration) //GEm: Move a folded card from bank to hand
    {
        ClearScreen();
        DrawBackground();
        DrawFoldedAlpha(0, BankLocation.X, BankLocation.Y, cast(float)Config.CardTranslucency / 255.0);
        DrawCardsOnTable();
        DrawUI();
        DrawStatus();
        DrawPlayerCards(Turn, CardPlace);
        //DrawCard(Turn, CardPlace, Destination.X, Destination.Y);

        CurrentLocation.X = BankLocation.X + (Destination.X - BankLocation.X) * ElapsedPercentage;
        CurrentLocation.Y = BankLocation.Y + (Destination.Y - BankLocation.Y) * ElapsedPercentage;
        DrawFolded(Turn, CurrentLocation);

        UpdateScreen();
        SDL_Delay(10);

        CurrentTime = Clock.currTime.stdTime;
        ElapsedPercentage = (CurrentTime - StartTime) / (double)AnimDuration;
    }

    CardInTransit = -1;
    bDiscardedInTransit = false;
}

/**
 * Draws the full background (including gradients)
 */
void DrawBackground()
{
    int i;
    float ResX = Config.ResolutionX;
    float ResY = Config.ResolutionY;

    //GE: Draw the background. The whole system is a difficult way of caltulating the bounding box to fit the thing in without stretching.
    SDL_Rect SourceCoords = {0,0,0,0};
    SourceCoords.w = TextureCoordinates[GfxSlot.GameBG].X;
    SourceCoords.h = TextureCoordinates[GfxSlot.GameBG].Y;
    SizeF BoundingBox;
    BoundingBox.X = 800.0/cast(float)Config.ResolutionX;
    BoundingBox.Y = 300.0/cast(float)Config.ResolutionY;
    float DrawScale = fmax(BoundingBox.X / (cast(float)TextureCoordinates[GfxSlot.GameBG].X / cast(float)Config.ResolutionX),
        BoundingBox.Y / (cast(float)TextureCoordinates[GfxSlot.GameBG].Y / cast(float)Config.ResolutionY));
    SizeF NewSize;
    NewSize.X = (cast(float)TextureCoordinates[GfxSlot.GameBG].X / cast(float)Config.ResolutionX) * DrawScale;
    NewSize.Y = (cast(float)TextureCoordinates[GfxSlot.GameBG].Y / cast(float)Config.ResolutionY) * DrawScale;
    SizeF Pivot;
    Pivot.X = (BoundingBox.X - NewSize.X) / 2.0;
    Pivot.Y = (BoundingBox.Y - NewSize.Y) / 2.0;
    SizeF DestinationCoords;
    DestinationCoords.X = Pivot.X + 0.0;
    DestinationCoords.Y = Pivot.Y + (BoundingBox.Y / 2.0);
    DrawTexture(GfxData[GfxSlot.GameBG], TextureCoordinates[GfxSlot.GameBG], SourceCoords, DestinationCoords, DrawScale);

    //GE: Draw the card area backgrounds.
    // GEm: TODO: Use Config.Resolution[XY]
    SizeF DestCoords = {0.0, 0.0};
    SizeF DestWH = {1.0, 129.0/600.0};
    SDL_Colour RectCol = {0,16,8,255};
    DrawRectangle(DestCoords, DestWH, RectCol);
    DestCoords.Y = (600.0 - 129.0) / 600.0;
    DrawRectangle(DestCoords, DestWH, RectCol);

    //GE: Draw the gradients on top and bottom of the screen.
    DestCoords.Y = 129.0 / 600.0;
    DestWH.Y = 14.3 / 600.0;
    SDL_Colour RectColA = {0,16,8,255};
    SDL_Colour RectColB = {16,66,41,255};
    DrawGradient(DestCoords, DestWH, RectColA, RectColB);
    DestCoords.Y = 143.3 / 600.0;
    DestWH.Y = 7.7 / 600.0;
    RectColA.r = 16; RectColA.g = 66; RectColA.b = 41;
    RectColB.r = 57; RectColB.g = 115; RectColB.b = 82;
    DrawGradient(DestCoords, DestWH, RectColA, RectColB);

    DestCoords.Y = 450.0 / 600.0;
    DestWH.Y = 7.7 / 600.0;
    RectColA.r = 57; RectColA.g = 115; RectColA.b = 82;
    RectColB.r=16; RectColB.g=66; RectColB.b=41;
    DrawGradient(DestCoords, DestWH, RectColA, RectColB);
    DestCoords.Y = (450.0 + 7.7) / 600.0;
    DestWH.Y = 14.3 / 600.0;
    RectColA.r=16; RectColA.g=66; RectColA.b=41;
    RectColB.r=0; RectColB.g=16; RectColB.b=8;
    DrawGradient(DestCoords, DestWH, RectColA, RectColB);
}

/**
 * Draws a card on the screen by a given card handle.
 *
 * In order to do that, the function needs to know which card to draw
 * and where. A card itself consists of the background, picture and
 * text for the name, description and cost(s). This function requires the full
 * card handle, as defined in D's CardDB(). For the function that needs only
 * the current player number and the place in hand, see DrawCardAlpha().
 */
void DrawHandleCardAlpha(int Pool, int Card, float X, float Y, float Alpha)
{
    float ResX = cast(float)Config.ResolutionX;
    float ResY = cast(float)Config.ResolutionY;

    SizeF BoundingBox, TextureSize;
    float Spacing;
    int BlockHeight;

    //GE: Draw the background.
    //GE: First, get the background that we will be using.
    // GEm: This uses wrapper.d, because this is just a useful function.
    int Colour = GetColourType(Pool, Card);

    SDL_Rect ItemPosition;
    SizeF ScreenPosition; ScreenPosition.X = X; ScreenPosition.Y = Y;
    float DrawScale = GetDrawScale();

    //GEm: Draw background.
    ItemPosition.x = Colour * 192;  ItemPosition.w = 192; // GEm: Make sure to keep wrapper.d in sync
    ItemPosition.y = 324;           ItemPosition.h = 256;

    DrawTextureAlpha(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale, Alpha);

    //GEm: Draw title text.
    ItemPosition = AbsoluteTextureSize(CardCache[Pool][Card].TitleTexture.TextureSize);

    ScreenPosition.X += 4 / ResX;
    ScreenPosition.Y += 4 / ResY;
    BoundingBox.X = 88 / ResX;
    BoundingBox.Y = 12 / ResY;
    TextureSize.X = CardCache[Pool][Card].TitleTexture.TextureSize.X / ResX;
    TextureSize.Y = CardCache[Pool][Card].TitleTexture.TextureSize.Y / ResY;
    ScreenPosition = CentreOnX(ScreenPosition, TextureSize, BoundingBox);

    DrawTextureAlpha(CardCache[Pool][Card].TitleTexture.Texture, CardCache[Pool][Card].TitleTexture.TextureSize,
        ItemPosition, ScreenPosition, 1.0, Alpha);

    //GEm: Draw description text.
    ScreenPosition.X = X + 4 / ResX;
    ScreenPosition.Y = Y + 72 / ResY;
    foreach (OpenGLTexture DescriptionTexture; CardCache[Pool][Card].DescriptionTextures)
        BlockHeight += DescriptionTexture.TextureSize.Y;
    if (CardCache[Pool][Card].DescriptionTextures[CardCache[Pool][Card].DescriptionTextures.length].TextureSize.X > 66 * DrawScale * 2
        && CardCache[Pool][Card].DescriptionTextures.length > 1
        && BlockHeight <= 41 * DrawScale * 2) //GEm: If we'd overlap with price and have enough space
        Spacing = ((41 * DrawScale * 2 - BlockHeight) / (CardCache[Pool][Card].DescriptionTextures.length+1)) / ResY;
    else
        Spacing = ((53 * DrawScale * 2 - BlockHeight) / (CardCache[Pool][Card].DescriptionTextures.length+1)) / ResY;
    ScreenPosition.Y += Spacing;
    foreach (int i, OpenGLTexture DescriptionTexture; CardCache[Pool][Card].DescriptionTextures)
    {
        ItemPosition = AbsoluteTextureSize(DescriptionTexture.TextureSize);
        TextureSize.X = DescriptionTexture.TextureSize.X / ResX;
        TextureSize.Y = DescriptionTexture.TextureSize.Y / ResY;
        ScreenPosition = CentreOnX(ScreenPosition, TextureSize, BoundingBox);
        DrawTextureAlpha(DescriptionTexture.Texture, DescriptionTexture.TextureSize, ItemPosition, ScreenPosition, 1.0, Alpha);
        ScreenPosition.Y += Spacing + DescriptionTexture.TextureSize.Y / ResY;
        ScreenPosition.X = X + 4 / ResX; //GEm: Reset X, keep Y.
    }

    // GEm: Draw card cost. TODO: Use Config.Resolution[XY]
    BoundingBox.X = 19 / 800.0;
    BoundingBox.Y = 12 / 600.0;
    ScreenPosition.X = X + 77 / 800.0;
    ScreenPosition.Y = Y + 111 / 600.0;
    switch (Colour)
    {
        case 1:
            ItemPosition = AbsoluteTextureSize(CardCache[Pool][Card].PriceTexture[1].TextureSize);
            TextureSize.X = CardCache[Pool][Card].PriceTexture[1].TextureSize.X / ResX;
            TextureSize.Y = CardCache[Pool][Card].PriceTexture[1].TextureSize.Y / ResY;
            ScreenPosition = CentreOnX(ScreenPosition, TextureSize, BoundingBox);
            DrawTextureAlpha(CardCache[Pool][Card].PriceTexture[1].Texture, CardCache[Pool][Card].PriceTexture[1].TextureSize,
                ItemPosition, ScreenPosition, 1.0, Alpha);
            break;
        case 2:
            ItemPosition = AbsoluteTextureSize(CardCache[Pool][Card].PriceTexture[2].TextureSize);
            TextureSize.X = CardCache[Pool][Card].PriceTexture[2].TextureSize.X / ResX;
            TextureSize.Y = CardCache[Pool][Card].PriceTexture[2].TextureSize.Y / ResY;
            ScreenPosition = CentreOnX(ScreenPosition, TextureSize, BoundingBox);
            DrawTextureAlpha(CardCache[Pool][Card].PriceTexture[2].Texture, CardCache[Pool][Card].PriceTexture[2].TextureSize,
                ItemPosition, ScreenPosition, 1.0, Alpha);
            break;
        case 3:
            writeln("Warning: graphics: DrawHandleCardAlpha: White cards not yet supported!");
        default: //GEm: Black and red cards, and anything else strange goes here.
            ItemPosition = AbsoluteTextureSize(CardCache[Pool][Card].PriceTexture[0].TextureSize);
            TextureSize.X = CardCache[Pool][Card].PriceTexture[0].TextureSize.X/ResX; TextureSize.Y = CardCache[Pool][Card].PriceTexture[0].TextureSize.Y/ResY;
            ScreenPosition = CentreOnX(ScreenPosition, TextureSize, BoundingBox);
            DrawTextureAlpha(CardCache[Pool][Card].PriceTexture[0].Texture, CardCache[Pool][Card].PriceTexture[0].TextureSize, ItemPosition, ScreenPosition, 1.0, Alpha);
            break;
    }

    //GEm: Draw card image.
    ItemPosition = CardCache[Pool][Card].PictureTexture.TextureSize;
    BoundingBox.X = 88 / 800.0;
    BoundingBox.Y = 52 / 600.0;
    float CustomDrawScale = fmax(BoundingBox.X / (ItemPosition.w / ResX),
        BoundingBox.Y / (ItemPosition.h / ResY));
    SizeF NewSize;
    NewSize.X = (ItemPosition.w / ResX) * CustomDrawScale;
    NewSize.Y = (ItemPosition.h / ResY) * CustomDrawScale;
    SizeF DeltaSize;
    DeltaSize.X = NewSize.X - BoundingBox.X;
    DeltaSize.Y = NewSize.Y - BoundingBox.Y;
    ItemPosition.x += DeltaSize.X * ResX / 2.0;
    ItemPosition.y += DeltaSize.Y * ResY / 2.0;
    ItemPosition.w -=  DeltaSize.X * ResX;
    ItemPosition.h -=  DeltaSize.Y * ResY;
    ScreenPosition.X = X + 4 / 800.0;
    ScreenPosition.Y = Y + 19 / 600.0;
    DrawTextureAlpha(CardCache[Pool][Card].PictureTexture.Texture, CardCache[Pool][Card].PictureTexture.TextureSize,
        ItemPosition, ScreenPosition, CustomDrawScale, Alpha);
}

void DrawHandleCard(int Pool, int Card, float X, float Y)
{
    DrawHandleCardAlpha(Pool, Card, X, Y, 1.0);
}

void DrawCardAlpha(byte PlayerNum, byte PositionInHand, float X, float Y, float Alpha)
{
    int Pool, Card;
    GetCardHandle(Player, Number, &Pool, &Card);
    foreach (int a, CardInfo[] Cards; CardDB)
    {
        foreach (int b, CardInfo CI; Cards)
        {
            if (CI == Player[PlayerNum].Hand[PositionInHand]) //GEm: Thank goodness D allows this!
            {
                Pool = a;
                Card = b;
                break;
            }
        }
    }

    DrawHandleCardAlpha(Pool, Card, X, Y, Alpha);
}

void DrawCard(byte PlayerNum, byte PositionInHand, float X, float Y)
{
        DrawCardAlpha(PlayerNum, PositionInHand, X, Y, 1.0);
}

/**
 * Draws cards in players' hands. Optional ExcludePlayer and ExcludeCard allows
 * not drawing a specified card.
 */
void DrawPlayerCards(int ExcludePlayer, int ExcludeCard)
{
    int i, n;

    for (n = 0; n < 2; n++) //GEm: TODO More than 2 players
    {
        for (i = 0; i < Config.CardsInHand; i++)
        {
            if (n == ExcludePlayer && i == ExcludeCard)
                continue;
            if (CanAffordCard(Player[n].Hand[i], n))
                DrawCard(n, i, CardLocations[n][i].X, CardLocations[n][i].Y);
            else
                DrawCardAlpha(n, i, CardLocations[n][i].X, CardLocations[n][i].Y, Config.CardTranslucency/255.0);
        }
    }
}

void DrawPlayerCards()
{
    DrawPlayerCards(-1, -1);
}

/**
 * Draws a graphic that reads "DISCARDED!" or such. Or maybe some symbol, who knows.
 */
void DrawDiscard(SizeF ScreenPosition;)
{
    SDL_Rect ItemPosition;
    float DrawScale = GetDrawScale();
    SizeF TextureSize, CardSize;

    ItemPosition.x = 1259;
    ItemPosition.y = 0;
    ItemPosition.w = 146;
    ItemPosition.h = 32;

    TextureSize.X = 146 * DrawScale / cast(float)Config.ResolutionX;
    TextureSize.Y = 32 * DrawScale / cast(float)Config.ResolutionX;
    CardSize.X = 192 * DrawScale / cast(float)Config.ResolutionX;
    CardSize.Y = 256 * DrawScale / cast(float)Config.ResolutionX;
    ScreenPosition = CentreOnX(ScreenPosition, TextureSize, CardSize);
    ScreenPosition.Y += (CardSize.Y - TextureSize.Y) / 2.0;

    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);
}

/**
 * Draws a picture of a folded card, depending on the side (red vs blue).
 * Currently used to draw the bank only!
 */
void DrawFolded(int Team, SizeF ScreenPosition, float Alpha)
{
    SDL_Rect DeckPosition;
    float DrawScale = GetDrawScale();

    DeckPosition.x = 960 + 192 * Team;
    DeckPosition.y = 324;
    DeckPosition.w = 192;
    DeckPosition.h = 256;

    DrawTextureAlpha(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        DeckPosition, ScreenPosition, DrawScale, Alpha);
}

void DrawFolded(int Team, SizeF ScreenPosition)
{
    DrawFolded(Team, ScreenPosition, 1.0);
}

/**
 * Draw cards that are out of player hands.
 * If !bAll, don't draw the last one (when animating it)
 */
void DrawCardsOnTable(bool bAll)
{
    int i;
    SizeF Destination;

    foreach(int i, CardHandle CardOnTable; CardsOnTable)
    {
        if (!bAll && i == CardsOnTable.length-1)
            return;
        Destination = GetCardOnTableLocation(i + 1);
        DrawHandleCardAlpha(CardOnTable.Pool, CardOnTable.Card,
            Destination.X, Destination.Y, Config.CardTranslucency / 255.0);
        if (CardOnTable.bDiscarded)
            DrawDiscard(Destination);
    }
}

/// Function overloading for easier handling!
void DrawCardsOnTable()
{
    DrawCardsOnTable(true);
}

/**
 * Draw the widgets (resource boxes, towers and whatnot, but not the numbers)
 * TODO: Use Config.Resolution[XY]
 */
void DrawUI()
{
    //GE: Draw status boxes
    SDL_Rect ItemPosition;
    SizeF ScreenPosition;
    float DrawScale = GetDrawScale();

    ItemPosition.x = 1181;
    ItemPosition.y = 0;
    ItemPosition.w = 78;
    ItemPosition.h = 216;

    ScreenPosition.X = 8.0 / 800.0;
    ScreenPosition.Y = 196.0 / 600.0;

    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale*2.0);

    ScreenPosition.X = (800.0 - 8.0 - 78.0) / 800.0;
    ScreenPosition.Y = 196.0 / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites], ItemPosition, ScreenPosition, DrawScale*2.0);

    //GE: Draw two towers
    ItemPosition.x = 1000;
    ItemPosition.y = 0;
    ItemPosition.w = 68;
    ItemPosition.h = 94 + 200 * (Player[0].Tower / cast(float)Config.TowerVictory); //GEm: TODO: Implement more than 2 players

    ScreenPosition.X = 92.0 / 800.0;
    ScreenPosition.Y = (433.0 - cast(float)ItemPosition.h) / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale * 2.0 * 284.0 / 294.0);

    ItemPosition.x = 1068;
    ItemPosition.h = 94 + 200 * (Player[1].Tower / cast(float)Config.TowerVictory);
    ScreenPosition.X = (800.0 - ItemPosition.w - 92.0) / 800.0;
    ScreenPosition.Y = (433.0 - cast(float)ItemPosition.h) / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale * 2.0 * 284.0 / 294.0);

    //GE: Draw two walls
    ItemPosition.x = 1136;
    ItemPosition.y = 0;
    ItemPosition.w = 45;
    ItemPosition.h = 38 + 200 * (Player[0].Wall / cast(float)Config.MaxWall);

    ScreenPosition.X = 162.0 / 800.0;
    ScreenPosition.Y = (433.0 - cast(float)ItemPosition.h) / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale * 2.0 * 284.0 / 294.0);

    ItemPosition.h = 38 + 200 * (Player[1].Wall / cast(float)Config.MaxWall);
    ScreenPosition.X = (800.0 - ItemPosition.w - 162.0) / 800.0;
    ScreenPosition.Y = (433.0 - cast(float)ItemPosition.h) / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale * 2.0 * 284.0 / 294.0);

    //GE: Draw the tower/wall boxes
    //GE: Tower
    ItemPosition.x = 1246;
    ItemPosition.y = 276;
    ItemPosition.w = 98;
    ItemPosition.h = 48;

    ScreenPosition.X = 100.0 / 800.0;
    ScreenPosition.Y = 434.0 / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);

    ScreenPosition.X = (800.0 - (ItemPosition.w * DrawScale) - 100.0) / 800.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);

    //GE: Wall
    ItemPosition.x = 1162;
    ItemPosition.y = 276;
    ItemPosition.w = 84;
    ItemPosition.h = 48;

    ScreenPosition.X = 163.0 / 800.0;
    ScreenPosition.Y = 434.0 / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);

    ScreenPosition.X = (800.0 - (ItemPosition.w * DrawScale) - 163.0) / 800.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);

    //GE: Names
    ItemPosition.x = 1188;
    ItemPosition.y = 228;
    ItemPosition.w = 156;
    ItemPosition.h = 48;

    ScreenPosition.X = 8.0 / 800.0;
    ScreenPosition.Y = 162.0 / 600.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);

    ScreenPosition.X = (800.0 - (ItemPosition.w * DrawScale) - 8.0) / 800.0;
    DrawTexture(GfxData[GfxSlot.Sprites], TextureCoordinates[GfxSlot.Sprites],
        ItemPosition, ScreenPosition, DrawScale);
}

/**
 * Draws the text and numbers inside the UI widgets.
 */
void DrawStatus()
{
    int i;
    char* Name;
    SDL_Rect AbsoluteSize;
    SizeF ScreenPosition, RelativeSize, BoundingBox;

    //GEm: TODO: implement more than 2 players
    for (i=0; i<2; i++)
    {
        //GEm: Draw the name of the players, centred
        AbsoluteSize = AbsoluteTextureSize(NameCache[i].TextureSize);

        ScreenPosition.X = (11 + 706 * i) / 800.0;
        ScreenPosition.Y = 168 / 600.0;
        RelativeSize.X = NameCache[i].TextureSize.X / cast(float)Config.ResolutionX;
        RelativeSize.Y = NameCache[i].TextureSize.Y / cast(float)Config.ResolutionY;
        BoundingBox.X = 72 / 800.0;
        BoundingBox.Y = 7 / 600.0;
        ScreenPosition = CentreOnX(ScreenPosition, RelativeSize, BoundingBox);

        DrawTexture(NameCache[i].Texture, NameCache[i].TextureSize,
            AbsoluteSize, ScreenPosition, 1.0);

        //GEm: Draw the facility numbers.
        DrawBigNumbers(i);
        //GEm: Draw the resource numbers.
        DrawMediumNumbers(i);

        //GEm: Draw the tower height.
        ScreenPosition.X = (103 + 551 * i) / 800.0;
        ScreenPosition.Y = (443 - 3) / 600.0;
        BoundingBox.X = 43 / 800.0;
        BoundingBox.Y = 7 / 600.0;
        DrawSmallNumber(Player[i].Tower), ScreenPosition, BoundingBox);

        //GEm: Draw the wall height.
        ScreenPosition.X = (166 + 433 * i) / 800.0;
        ScreenPosition.Y = (443 - 3) / 600.0;
        BoundingBox.X = 36 / 800.0;
        BoundingBox.Y = 7 / 600.0;
        DrawSmallNumber(Player[i].Wall, ScreenPosition, BoundingBox);
    }
}

/**
 * Draws the facility count numbers.
 */
void DrawBigNumbers(int PlayerNum)
{
    //GEm: Draw one or two numbers, aligned to the left.
    //GEm: TODO: implement more than 2 players
    SDL_Rect AbsoluteSize;
    SizeF ScreenPosition;
    int i, Resource;

    int TensDigit;
    int OnesDigit;

    for (i = 0; i < 3; i++)
    {
        switch(i)
        {
            case 0:
                Resource = Player[PlayerNum].Quarry);
                break;
            case 1:
                Resource = Player[PlayerNum].Magic);
                break;
            default:
                Resource = Player[PlayerNum].Dungeon);
        }
        TensDigit = Resource / 10;
        OnesDigit = Resource % 10;

        ScreenPosition.X = (15 + 706 * PlayerNum) / 800.0;
        ScreenPosition.Y = (241 - 15 + 72 * i) / 600.0;

        if (TensDigit > 0)
        {
            AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Big][TensDigit].TextureSize);
            DrawTexture(NumberCache[NumberSlots.Big][TensDigit].Texture,
                NumberCache[NumberSlots.Big][TensDigit].TextureSize,
                AbsoluteSize, ScreenPosition, 1.0);

            ScreenPosition.X += NumberCache[NumberSlots.Big][TensDigit].TextureSize.X / cast(float)Config.ResolutionX;
        }

        AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Big][OnesDigit].TextureSize);
        DrawTexture(NumberCache[NumberSlots.Big][OnesDigit].Texture,
            NumberCache[NumberSlots.Big][OnesDigit].TextureSize, AbsoluteSize, ScreenPosition, 1.0);
    }
}

/**
 * Draws the resource count numbers.
 */
void DrawMediumNumbers(int PlayerNum)
{
    //GEm: Draw one, two or three numbers, aligned to the left.
    //GEm: TODO: implement more than 2 players
    SDL_Rect AbsoluteSize;
    SizeF ScreenPosition;
    int i, Resource;

    int HundredsDigit, TensDigit, OnesDigit;

    for (i=0; i<3; i++)
    {
        switch(i)
        {
            case 0:
                Resource = Player[PlayerNum].Bricks);
                break;
            case 1:
                Resource = Player[PlayerNum].Gems);
                break;
            default:
                Resource = Player[PlayerNum].Recruits);
        }
        HundredsDigit = Resource / 100;
        TensDigit = Resource / 10 % 10;
        OnesDigit = Resource % 10;

        ScreenPosition.X = (11 + 706 * PlayerNum) / 800.0;
        ScreenPosition.Y = (263 - 13 + 72 * i) / 600.0;

        if (HundredsDigit > 0)
        {
            AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Medium][HundredsDigit].TextureSize);
            DrawTexture(NumberCache[NumberSlots.Medium][HundredsDigit].Texture,
                NumberCache[NumberSlots.Medium][HundredsDigit].TextureSize,
                AbsoluteSize, ScreenPosition, 1.0);

            ScreenPosition.X += NumberCache[NumberSlots.Medium][HundredsDigit].TextureSize.X / cast(float)Config.ResolutionX;
        }

        if (TensDigit > 0 || HundredsDigit > 0)
        {
            AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Medium][TensDigit].TextureSize);
            DrawTexture(NumberCache[NumberSlots.Medium][TensDigit].Texture,
                NumberCache[NumberSlots.Medium][TensDigit].TextureSize,
                AbsoluteSize, ScreenPosition, 1.0);

            ScreenPosition.X += NumberCache[NumberSlots.Medium][TensDigit].TextureSize.X / cast(float)Config.ResolutionX;
        }

        AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Medium][OnesDigit].TextureSize);
        DrawTexture(NumberCache[NumberSlots.Medium][OnesDigit].Texture,
            NumberCache[NumberSlots.Medium][OnesDigit].TextureSize,
            AbsoluteSize, ScreenPosition, 1.0);
    }
}

/**
 * Draws a single number specified in the Destination, fitting the BoundingBox.
 * Supports up to three digit numbers at the moment.
 */
void DrawSmallNumber(int Number, SizeF Destination, SizeF BoundingBox)
{
    //GEm: Draw one, two or three numbers, aligned to the left.
    //GEm: TODO: implement more than 2 players
    SDL_Rect AbsoluteSize;
    SizeF ObjectSize;
    int i;
    float NumberLength;

    int HundredsDigit, TensDigit, OnesDigit;

    HundredsDigit = Number / 100;
    TensDigit = Number / 10 % 10;
    OnesDigit = Number % 10;

    if (HundredsDigit > 0)
        NumberLength += NumberCache[NumberSlots.Small][HundredsDigit].TextureSize.X / cast(float)Config.ResolutionX;
    if (TensDigit > 0 || HundredsDigit > 0)
        NumberLength += NumberCache[NumberSlots.Small][TensDigit].TextureSize.X / cast(float)Config.ResolutionX;
    NumberLength += NumberCache[NumberSlots.Small][OnesDigit].TextureSize.X / cast(float)Config.ResolutionX;
    ObjectSize.X = NumberLength;
    ObjectSize.Y = BoundingBox.Y;
    Destination = CentreOnX(Destination, ObjectSize, BoundingBox);

    if (HundredsDigit > 0)
    {
        AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Small][HundredsDigit].TextureSize);
        DrawTexture(NumberCache[NumberSlots.Small][HundredsDigit].Texture,
            NumberCache[NumberSlots.Small][HundredsDigit].TextureSize,
            AbsoluteSize, Destination, 1.0);

        Destination.X += NumberCache[NumberSlots.Small][HundredsDigit].TextureSize.X / cast(float)Config.ResolutionX;
    }

    if (TensDigit > 0 || HundredsDigit > 0)
    {
        AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Small][TensDigit].TextureSize);
        DrawTexture(NumberCache[NumberSlots.Small][TensDigit].Texture,
            NumberCache[NumberSlots.Small][TensDigit].TextureSize, AbsoluteSize, Destination, 1.0);

        Destination.X += NumberCache[NumberSlots.Small][TensDigit].TextureSize.X / cast(float)Config.ResolutionX;
    }

    AbsoluteSize = AbsoluteTextureSize(NumberCache[NumberSlots.Small][OnesDigit].TextureSize);
    DrawTexture(NumberCache[NumberSlots.Small][OnesDigit].Texture,
        NumberCache[NumberSlots.Small][OnesDigit].TextureSize, AbsoluteSize, Destination, 1.0);
}

/// Pushes drawn content to the screen. Fast.
void UpdateScreen()
{
    SDL_GL_SwapWindow(Window);
}

/**
 * Deduces the location of a given card on the table. They are all fitted inside
 * a bounding box.
 * This could be precached, if it takes too long. Doesn't look like it, though.
 */
SizeF GetCardOnTableLocation(int CardSlot)
{
    int i;
    SizeF Result;
    //GEm: Bounding box: 15% margin from left and right, 25% from top and bottom

    //GEm: Figure out how many cards fit the bounding box
    //GEm: Good thing that int = float means int = floor(float)!
    auto CardWidth = 192 * GetDrawScale() / Config.ResolutionX;
    auto CardHeight = 256 * GetDrawScale() / Config.ResolutionY;
    int CardsX = 0.7 / CardWidth;
    int CardsY = 0.5 / CardHeight;
    auto CombinedCardWidth = CardWidth * CardsX;
    auto CombinedCardHeight = CardHeight * CardsY;
    auto SpacingX = (0.7 - CombinedCardWidth) / (CardsX - 1);
    auto SpacingY = (0.5 - CombinedCardHeight) / (CardsY + 1);

    for (i = 0; i < CardsY; i++)
    {
        if (CardSlot / (CardsX * (i + 1)) > 0) //GEm: Does not fit to this line!
            continue;

        CardSlot -= CardsX * i;
        Result.X = SpacingX * (CardSlot + 1 - 1) + CardWidth * CardSlot + 0.15;
        Result.Y = SpacingY * (i + 1) + CardHeight * i + 0.25;
        return Result;
    }
    writeln("Warning: graphics: GetCardOnTableLocation: Cards do not fit on the table!");
    return Result;
}

/**
 * Centre a box in another box. Ignores Y.
 * Parameters:
 * Destination - The (top) left edge of the bounding box.
 * ObjectSize - The length of the texture you wish to draw.
 * BoundingBox - The size of the bounding box you want to fit things in.
 */
SizeF CentreOnX(SizeF Destination, SizeF ObjectSize, SizeF BoundingBox)
{
    Destination.X += (BoundingBox.X - ObjectSize.X) / 2.0;
    return Destination;
}

/**
 * Returns the whole size of the texture in SDL_Rect
 */
SDL_Rect AbsoluteTextureSize(Size TextureSize)
{
    SDL_Rect Result;
    Result.x = 0; Result.w = TextureSize.X;
    Result.y = 0; Result.h = TextureSize.Y;
    return Result;
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

string GetDPicturePath(int PoolNum, int CardNum)
{
    return "lua/"~PoolNames[PoolNum]~"/"~CardDB[PoolNum][CardNum].Picture.File;
}
