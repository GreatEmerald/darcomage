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
import sound;

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
        writeln("FATAL: darcomage: ", e.msg);
    finally
        Quit();

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
    if (Config.SoundEnabled)
        InitSound();

    FrontendFunctions.PlayCardAnimation = &PlayCardAnimation;
    FrontendFunctions.PlayCardPostAnimation = &PlayCardPostAnimation;
    FrontendFunctions.EffectNotify = &EffectNotify;
}

void FrontendReset()
{
    ClearCardCache();
    FreePictures();
    CardsOnTable = CardsOnTable.init;
    CardInTransit = -1;
    bDiscardedInTransit = false;
    BackendReset();
    InitCardLocations(2);
    PrecacheCards();
    MenuSelection();
}

/**
 * Game termination and memory cleanup.
 */
void Quit()
{
    QuitSound();
    QuitTTF();
    QuitSDL();
}
