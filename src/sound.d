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

module sound;
import std.conv;
import std.string;
import std.stdio;
import derelict.sdl2.mixer;
import derelict.sdl2.types;
import arco;
import graphics;

enum SoundSlot
{
    Title,
    Deal,
    Shuffle,
    TowerUp,
    WallUp,
    Damage,
    FacilityUp,
    FacilityDown,
    ResourceUp,
    ResourceDown,
    Victory,
    Defeat
}

Mix_Chunk*[SoundSlot.max+1] Sounds;

void InitSound()
{
    DerelictSDL2Mixer.load();
    if (Mix_Init(0) == -1)
        throw new Exception("Error: sound: InitSound: Failed to initialise SDL2_mixer: "~to!string(Mix_GetError()));

    // GEm: These options are due to the default sounds I have. If adding music, should probably change!
    if (Mix_OpenAudio(22050, AUDIO_S16SYS, 1, 4096) == -1)
        throw new Exception("Error: sound: InitSound: Failed to open audio: "~to!string(Mix_GetError()));

    if (Config.UseOriginalCards)
    {
        LoadSound("titleO.wav", SoundSlot.Title);
        LoadSound("dealO.wav", SoundSlot.Deal);
        LoadSound("shuffleO.wav", SoundSlot.Shuffle);
        LoadSound("tower_upO.wav", SoundSlot.TowerUp);
        LoadSound("wall_upO.wav", SoundSlot.WallUp);
        LoadSound("damageO.wav", SoundSlot.Damage);
        LoadSound("resb_upO.wav", SoundSlot.FacilityUp);
        LoadSound("resb_downO.wav", SoundSlot.FacilityDown);
        LoadSound("ress_upO.wav", SoundSlot.ResourceUp);
        LoadSound("ress_downO.wav", SoundSlot.ResourceDown);
        LoadSound("victoryO.wav", SoundSlot.Victory);
        LoadSound("defeatO.wav", SoundSlot.Defeat);
    }
    else
    {
        LoadSound("title.wav", SoundSlot.Title);
        LoadSound("deal.wav", SoundSlot.Deal);
        LoadSound("shuffle.wav", SoundSlot.Shuffle);
        LoadSound("tower_up.wav", SoundSlot.TowerUp);
        LoadSound("wall_up.wav", SoundSlot.WallUp);
        LoadSound("damage.wav", SoundSlot.Damage);
        LoadSound("resb_up.wav", SoundSlot.FacilityUp);
        LoadSound("resb_down.wav", SoundSlot.FacilityDown);
        LoadSound("ress_up.wav", SoundSlot.ResourceUp);
        LoadSound("ress_down.wav", SoundSlot.ResourceDown);
        LoadSound("victory.wav", SoundSlot.Victory);
        LoadSound("defeat.wav", SoundSlot.Defeat);
    }
}

void LoadSound(string Filename, int Slot)
{
    Sounds[Slot] = Mix_LoadWAV(GetCFilePath(Filename));
    if (!Sounds[Slot])
        throw new Exception("Error: sound: LoadSound: Failed to load "~Filename~": "~to!string(Mix_GetError()));
}

void PlaySound(int Slot)
{
    if (!Config.SoundEnabled)
        return;

    if (Mix_PlayChannel(-1, Sounds[Slot], 0) == -1)
        writeln("Warning: sound: PlaySound: Couldn't play sound "~to!string(Slot)~": "~to!string(Mix_GetError()));
}

extern(C) void EffectNotify(int Who, int Type, int Power)
{
    switch (Type)
    {
        case EffectType.DamageWall:
        case EffectType.DamageTower:
            PlaySound(SoundSlot.Damage);
            DrawParticles(Who, Type);
            return;
        case EffectType.QuarryUp:
        case EffectType.MagicUp:
        case EffectType.DungeonUp:
            PlaySound(SoundSlot.FacilityUp);
            DrawParticles(Who, Type);
            return;
        case EffectType.BricksUp:
        case EffectType.GemsUp:
        case EffectType.RecruitsUp:
            PlaySound(SoundSlot.ResourceUp);
            DrawParticles(Who, Type);
            return;
        case EffectType.TowerUp:
            PlaySound(SoundSlot.TowerUp);
            DrawParticles(Who, Type);
            return;
        case EffectType.WallUp:
            PlaySound(SoundSlot.WallUp);
            DrawParticles(Who, Type);
            return;
        case EffectType.QuarryDown:
        case EffectType.MagicDown:
        case EffectType.DungeonDown:
            PlaySound(SoundSlot.FacilityDown);
            DrawParticles(Who, Type);
            return;
        case EffectType.BricksDown:
        case EffectType.GemsDown:
        case EffectType.RecruitsDown:
            PlaySound(SoundSlot.ResourceDown);
            DrawParticles(Who, Type);
            return;
        case EffectType.CardShuffle:
            PlaySound(SoundSlot.Shuffle);
            return;
        default:
            writeln("Warning: sound: EffectNotify: Unknown effect type "~to!string(Type));
            return;
    }
}

void QuitSound()
{
    Mix_HaltChannel(-1);
    foreach (Mix_Chunk* SoundReference; Sounds)
        Mix_FreeChunk(SoundReference);
    Mix_CloseAudio();
    Mix_Quit();
}
