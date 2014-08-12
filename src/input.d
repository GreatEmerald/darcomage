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
import derelict.sdl2.sdl;
import arco;
import graphics;

enum MenuButton
{
    Start,
    Hotseat,
    Multiplayer,
    Score,
    Credits,
    Quit
};

SDL_Event event;

int Menu()
{
    int i, value=-1;
    float ResX = cast(float)Config.ResolutionX;
    float ResY = cast(float)Config.ResolutionY;
    float DrawScale = GetDrawScale();
    int LitButton = -1; //GE: Which button is lit.

    DrawMenuBackground();
    UpdateScreen();

    //Sound_Play(TITLE);

    while (value == -1)
    {
        if (!SDL_PollEvent(&event)) //GE: Read the event loop. If it's empty, sleep instead of repeating the old events.
        {
            SDL_Delay(0);
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
        SDL_Delay(0);//CPUWAIT); //GE: FIXME: This is not the same between platforms and causes major lag in Linux.
    }
    return value;
}

bool FInRect(float x, float y, float x1, float y1, float x2, float y2)
{
    return (x >= x1) && (x <= x2) && (y >= y1) && (y <= y2);
}
