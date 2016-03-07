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

module input;
import std.stdio;
import std.conv;
import derelict.sdl2.sdl;
import arco;
import cards;
import frontend;
import graphics;
import opengl;
import font;
import sound;

enum MenuButton
{
    Start,
    Multiplayer,
    Hotseat,
    Score,
    Credits,
    Quit
};

SDL_Event event;

/**
 * Main menu chooser.
 *
 * Defines what happens on each button press.
 *
 * Bugs: Should allow the player to input his name. Alternatively, use Lua.
 * Bugs: Should handle all menu buttons, not just the one.
 */
void MenuSelection()
{
    int MenuAction;

    // GEm: Get the menu button pressed
    MenuAction = Menu();
    // GEm: Handle the button (still needs handling of all others than regular play!)
    switch (MenuAction)
    {
        case MenuButton.Start:
            initGame();
            // GEm: Should read the names from somewhere (config or input)
            // GEm: F...something should toggle fullscreen!
            Player[Turn].Name = "Player";
            Player[Turn].AI = false;
            Player[GetEnemy()].Name = "AI";
            Player[GetEnemy()].AI = true;
            PrecachePlayerNames(); //GEm: We couldn't precache it earlier, since we didn't know the names!

            DoGame();
            break;
        case MenuButton.Hotseat:
            initGame();
            // GEm: Should read the names from somewhere (config or input)
            Player[Turn].Name = "Player 1";
            Player[Turn].AI = false;
            Player[GetEnemy()].Name = "Player 2";
            Player[GetEnemy()].AI = false;
            PrecachePlayerNames(); //GEm: We couldn't precache it earlier, since we didn't know the names!

            DoGame();
            break;

        default: break;
    }
}

int Menu()
{
    int i, value=-1;
    float ResX = cast(float)Config.ResolutionX;
    float ResY = cast(float)Config.ResolutionY;
    float DrawScale = GetDrawScale();
    int LitButton = -1; //GE: Which button is lit.

    DrawMenuBackground();
    UpdateScreen();

    PlaySound(SoundSlot.Title);

    while (value == -1)
    {
        if (!SDL_PollEvent(&event)) //GE: Read the event loop. If it's empty, sleep instead of repeating the old events.
        {
            //SDL_Delay(0);
            continue;
        }
        switch (event.type)
        {
            case SDL_QUIT:
                value = MenuButton.Quit;
                break;
            case SDL_MOUSEMOTION:
                for (i = 0; i < 6; i++)
                {
                    if ( (i < 3
                        && FInRect(event.motion.x / ResX, event.motion.y/ResY,
                        (2.0 * i + 1.0) / 6.0 - (250.0 * DrawScale / ResX / 2.0), //GE: These correspond to entries in DrawMenuItem().
                        ((130.0 / 600.0) - (108.0 * DrawScale / 600.0)) / 2.0,
                        (2.0 * i + 1.0) / 6.0 + (250.0 * DrawScale / ResX / 2.0),
                        ((130.0 / 600.0) + (108.0 * DrawScale / 600.0)) / 2.0))
                        || (i >= 3
                        && FInRect(event.motion.x / ResX, event.motion.y / ResY,
                        (2.0 * (i - 3.0) + 1.0) / 6.0 - (250.0 * DrawScale / ResX / 2.0),
                        ((600.0 - 130.0 / 2.0) - (108.0 * DrawScale / 2.0)) / 600.0,
                        (2.0 * (i - 3.0) + 1.0) / 6.0 + (250.0 * DrawScale / ResX / 2.0),
                        ((600.0 - 130.0 / 2.0) + (108.0 * DrawScale / 2.0)) / 600.0))
                    )
                    {
                        if (LitButton < 0) //GE: We are on a button, and there are no lit buttons. Light the current one.
                        {
                            DrawMenuBackground();
                            DrawMenuItem(i, true);
                            UpdateScreen();
                            LitButton = i;
                        }
                    }
                    else if (LitButton == i) //GE: We are not on the current button, yet it is lit.
                    {
                        DrawMenuBackground();
                        UpdateScreen();
                        LitButton = -1;
                    }
                }
                break;
            case SDL_MOUSEBUTTONUP:
                if (event.button.button == SDL_BUTTON_LEFT)
                {
                    for (i = 0; i < 6; i++)
                    {
                        if ( (i < 3
                        && FInRect(event.motion.x / ResX, event.motion.y/ResY,
                        (2.0 * i + 1.0) / 6.0 - (250.0 * DrawScale / ResX / 2.0), //GE: These correspond to entries in DrawMenuItem().
                        ((130.0 / 600.0) - (108.0 * DrawScale / 600.0)) / 2.0,
                        (2.0 * i + 1.0) / 6.0 + (250.0 * DrawScale / ResX / 2.0),
                        ((130.0 / 600.0) + (108.0 * DrawScale / 600.0)) / 2.0))
                        || (i >= 3
                        && FInRect(event.motion.x / ResX, event.motion.y / ResY,
                        (2.0 * (i - 3.0) + 1.0) / 6.0 - (250.0 * DrawScale / ResX / 2.0),
                        ((600.0 - 130.0 / 2.0) - (108.0 * DrawScale / 2.0)) / 600.0,
                        (2.0 * (i - 3.0) + 1.0) / 6.0 + (250.0 * DrawScale / ResX / 2.0),
                        ((600.0 - 130.0 / 2.0) + (108.0 * DrawScale / 2.0)) / 600.0))
                        )
                        {
                            //printf("Debug: Menu: MouseUp with %d\n", i);
                            value = i;
                        }
                    }
                    UpdateScreen();//GE: Workaround for black screen on certain drivers
                    UpdateScreen();
                }
                break;
            default:
                break;
        }
        //SDL_Delay(0);//CPUWAIT); //GE: FIXME: This is not the same between platforms and causes major lag in Linux.
    }
    return value;
}

/**
 * The main input loop in the game.
 *
 * Includes the event loop, victory/loss handling, AI and eventually network support.
 */
void DoGame()
{
    int n;
    int CardToPlay, netcard;
    bool bDiscarded, bAllowedToPlay;

    SizeF HighlightRect, HighlightLocation;
    SDL_Color HighlightColour = {255, 0, 0, 255};
    int HighlightedCard = -1;

    while (!IsVictorious(0) && !IsVictorious(1))
    {
        DrawScene();
        if (HighlightedCard != -1)
        {
            HighlightLocation = CardLocations[Turn][HighlightedCard];
            HighlightRect.X = 94 / 800.0; // GEm: TODO: support for non-4:3
            HighlightRect.Y = 128 / 600.0;
            DrawHollowRectangle(HighlightLocation, HighlightRect, HighlightColour);
        }
        UpdateScreen();

        while (SDL_PollEvent(&event))
        {} //GE: Delete all events from the event queue before our turn.

        if (Player[Turn].AI)
        {
            SDL_Delay(500); // GEm: Let's pretend we're "thinking" so those organics would feel better.
            AIPlay();
        } /*else //GEm: TODO Netplay
        if (turn==netplayer)
        {
            if (NetRemPlay(&i,&discrd) && CanPlayCard(i,discrd))
                        {
                                PlayCardAnimation(i, discrd);
                                PlayCard(i,discrd);
                        }
            else {
                DrawDialog(DLGERROR,"Server dropped connection ...");
                WaitForInput();
                return;
            }
        } */
        else
        {
            while (!SDL_PollEvent(&event))
                continue;//SDL_Delay(0); //GEm: HACK
            if (event.type == SDL_KEYUP && event.key.keysym.sym == SDLK_ESCAPE)
            {
                //GEm: Back if Esc is pressed.
                FrontendReset();
                return;
            }
            /*if (event.type == SDL_KEYDOWN && event.key.keysym.sym == SDLK_b) //GE: Keeping as "down" since it's urgent ;)
                Boss();*/ //GEm: TODO boss screen
            if (event.type == SDL_MOUSEMOTION) //GE: Support for highlighting cards, to be done: card tooltips.
            {
                HighlightedCard = -1;
                foreach (int i, SizeF CardLocation; CardLocations[Turn])
                {
                    HighlightRect.X = CardLocation.X + 94 / 800.0;
                    HighlightRect.Y = CardLocation.Y + 128 / 600.0;
                    if (FInRect(event.motion.x / cast(float)Config.ResolutionX, event.motion.y / cast(float)Config.ResolutionY,
                        CardLocation.X, CardLocation.Y, HighlightRect.X, HighlightRect.Y))
                    {
                        HighlightedCard = i;
                        break;
                    }
                }
            }

            if (event.type != SDL_MOUSEBUTTONUP || event.button.button > 3)
            {
                //SDL_Delay(0); //GEm: HACK
                continue;
            }
            HighlightedCard = -1;
            bDiscarded = (event.button.button == 2) || (event.button.button == 3);
            foreach (int i, SizeF CardLocation; CardLocations[Turn])
            {
                if (FInRect(event.button.x / cast(float)Config.ResolutionX, event.button.y / cast(float)Config.ResolutionY,
                    CardLocation.X, CardLocation.Y,
                    CardLocation.X + 94 / 800.0, CardLocation.Y + 128 / 600.0)
                    /*&&  GetCanPlayCard(Turn, i, bDiscarded)*/)
                {
                    CardToPlay = i;
                    bAllowedToPlay = true; //GEm: This only checks for special conditions, not resources!
                    break;
                }
            }
            //netcard = Player[turn].Hand[crd];//GEm: TODO: Netplay
            if (bAllowedToPlay)
            {
                PlayCard(CardToPlay, bDiscarded);
                bAllowedToPlay = false;
            }

            /*if (netplayer!=-1)
                NetLocPlay(crd,discrd,netcard);*/ //GEm: TODO: Netplay
        }
        SDL_Delay(Config.FrameDelay);
    }

    //printf("DoGame(): Info: Game ended: Red gets %d, blue gets %d!\n", IsVictorious(0), IsVictorious(1));
    DrawScene();
    if (IsVictorious(0) && IsVictorious(1))
    {
        DrawDialog(GfxSlot.DlgWinner, "Draw!");
        PlaySound(SoundSlot.Victory);
    }
    else
    {
        if (Player[1].AI)              // 1 local Player //GEm: TODO: more than 2 players
        {
            //i=aiplayer;if (i==-1) i=netplayer;i=!i; //GEm: TODO: Networking support
            if (IsVictorious(0))
            {
                if (Player[0].Tower >= Config.TowerVictory)
                    DrawDialog(GfxSlot.DlgWinner, "You win by a\ntower building victory!");
                else if (Player[1].Tower <= 0)
                    DrawDialog(GfxSlot.DlgWinner, "You win by a tower\ndestruction victory!");
                else DrawDialog(GfxSlot.DlgWinner, "You win by a\nresource victory!");
                PlaySound(SoundSlot.Victory);
            }
            else
            {
                if (Player[1].Tower >= Config.TowerVictory)
                    DrawDialog(GfxSlot.DlgLoser, "You lose by a\ntower building defeat!");
                else if (Player[0].Tower <= 0)
                    DrawDialog(GfxSlot.DlgLoser, "You lose by a\ntower destruction defeat!");
                else DrawDialog(GfxSlot.DlgLoser, "You lose by a\nresource defeat!");
                PlaySound(SoundSlot.Defeat);
            }
        } else {                                         // 2 local Players
            if (IsVictorious(0))
                DrawDialog(GfxSlot.DlgWinner, "Winner is\n"~Player[0].Name~"!");
            else
                DrawDialog(GfxSlot.DlgWinner, "Winner is\n"~Player[1].Name~"!");
            PlaySound(SoundSlot.Victory);
        }
    }
    UpdateScreen();
    SDL_Delay(1000);
    while (SDL_PollEvent(&event))
    {}
    WaitForInput();
    FrontendReset();
}

void WaitForInput()
{
    do
    {
        SDL_WaitEvent(&event);
    } while (!((event.type == SDL_KEYUP) || ((event.type == SDL_MOUSEBUTTONUP) && (event.button.button == SDL_BUTTON_LEFT))));
}

bool FInRect(float x, float y, float x1, float y1, float x2, float y2)
{
    return (x >= x1) && (x <= x2) && (y >= y1) && (y <= y2);
}
