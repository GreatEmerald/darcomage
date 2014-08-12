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

module frontend;
import std.stdio;
import arco;
import cards;
import graphics;
import ttf;
import input;

/**
 * Entry function.
 *
 * Calls initialisation functions and handles exceptions.
 */
int main()
{
    // GEm: Exception guarding.
    try
    {
        Init();
        MenuSelection();
    }
    catch (Exception e)
        writeln("Error: %s", e.msg);
    finally
        {}//Quit();

    return 0;
}

/**
 * Game subsystem initialisation.
 */
void Init()
{
    InitArcomage(); //GEm: Init libarcomage
    InitSDL(); // GEm: Init SDL2
    InitTTF(); // GEm: Init SDL2 TTF
    //if (Config.SoundEnabled)
    //    Sound_Init();

    FrontendFunctions.PlayCardAnimation = &PlayCardAnimation;
    FrontendFunctions.PlayCardPostAnimation = &PlayCardPostAnimation;

    initGame(); //GEm: Init a 1vs1 game, will choose player types later
}

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
        /*case MenuButton.Start:
            // GEm: Should read the names from somewhere (config or input)
            // GEm: F...something should toggle fullscreen!
            SetPlayerInfo(Turn, "Player", 0); //GE: Set up a player VS AI game.
            SetPlayerInfo(GetEnemy(), "AI", 1);//Player[GetEnemy()].AI = 1;
            PrecachePlayerNames(); //GEm: We couldn't precache it earlier, since we didn't know the names!

            DoGame();*/

        default: break;
    }
}
