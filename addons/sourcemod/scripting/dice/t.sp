int tDiceOne(int client, Panel panel, int option = -1)
{
    SetRandomSeed(GetTime() * 100 * GetRandomInt(2, 9));
    
    int iNumber = GetRandomInt(1, 100);

    if (option != -1)
    {
        iNumber = option;
    }
    
    char sOption[32];
    
    // Types: 0 - Negative, 1 - Neutral, 2 - Positive
    int type = -1;
    
    char sText[128];

    if(iNumber >= 1 && iNumber <= 7)
    {
        // +50 hp
        SetHealth(client, 50, true);
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %s+50 HP%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "+50hp");
        type = 2;
    }
    else if(iNumber >= 8 && iNumber <= 14)
    {
        // low grav
        SetEntityGravity(client, 0.5);
        g_hLowGravity[client] = CreateTimer(1.0, LowGravityTimer, client, TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %slow Gravity%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "lowGravity");
        type = 2;
    }
    else if(iNumber >= 15 && iNumber <= 21)
    {
        // taser
        RequestFrame(Frame_GiveTaser, GetClientUserId(client));
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %seinen Taser%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "taser");
        type = 2;
    }
    else if(iNumber >= 22 && iNumber <= 28)
    {
        // froggy
        g_bFroggyjump[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %sFroggyjump%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "froggyjump");
        type = 2;
    }
    else if(iNumber >= 29 && iNumber <= 41)
    {
        // -45 hp
        SetHealth(client, 45, false);
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %s-45 HP%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "-45hp");
        type = 0;
    }
    else if(iNumber >= 42 && iNumber <= 52)
    {
        // anbrennen
        IgniteEntity(client, 14.0);
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %sanbrennen%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "burn");
        type = 0;
    }
    else if(iNumber == 53)
    {
        // nichts
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "nothing");
        type = 1;
    }
    else if(iNumber >= 54 && iNumber <= 65)
    {
        // slow
        int iSpeed = GetRandomInt(3, 6);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) - fSpeed));
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %sSlow (+%.0f%%)%s gewürfelt.", SPECIAL, (fSpeed * 100), TEXT);
        Format(sOption, sizeof(sOption), "slow");
        type = 0;
    }
    else if(iNumber >= 66 && iNumber <= 80)
    {
        // nichts
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "nothing");
        type = 1;
    }
    else if(iNumber >= 81 && iNumber <= 90)
    {
        // 2 flashes
        GivePlayerItem(client, "weapon_flashbang");
        GivePlayerItem(client, "weapon_flashbang");
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %s2 Flashes%s gewürfellt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "flashbang");
        type = 2;
    }
    else if(iNumber >= 91 && iNumber <= 100)
    {
        // smoke
        GivePlayerItem(client, "weapon_smokegrenade");
        
        Format(sText, sizeof(sText), "Du hast beim 1. Würfeln %seine Smoke%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "smokegrenade");
        type = 2;
    }
    
    AddDiceToMySQL(client, 1, sOption);

    CPrintToChat(client, sText);

    char sBuffer[32];
    Format(sBuffer, sizeof(sBuffer), "Dice - Option: %d", iNumber);
    panel.SetTitle(sBuffer);

    CRemoveTags(sText, sizeof(sText));
    panel.DrawText(sText);

    return type;
}

int tDiceTwo(int client, Panel panel, int option = -1)
{
    char sOption[32];
    
    SetRandomSeed(GetTime() * 100 * GetRandomInt(2, 9));
    
    int iNumber = GetRandomInt(1, 100);

    if (option != -1)
    {
        iNumber = option;
    }
    
    // Types: 0 - Negative, 1 - Neutral, 2 - Positive
    int type = -1;

    char sText[128];
    char sText1[64];
    char sText2[64];
    
    if(iNumber >= 1 && iNumber <= 6)
    {
        // longjump
        g_bLongjump[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sLongjump%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "longjump");
        type = 2;
    }
    else if(iNumber >= 7 && iNumber <= 12)
    {
        // bhop
        g_bBhop[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sein Bhop Script%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "bhop");
        type = 2;
    }
    else if(iNumber >= 13 && iNumber <= 18)
    {
        // kevlar + helm
        GivePlayerItem(client, "item_assaultsuit");
        SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %seine Kevlar mit Helm%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "kevlarHelm");
        type = 2;
    }
    else if(iNumber >= 19 && iNumber <= 24)
    {
        // speed
        int iSpeed = GetRandomInt(3, 6);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) + fSpeed));
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sSpeed (+%.0f%%)%s gewürfelt.", SPECIAL, (fSpeed * 100), TEXT);
        Format(sOption, sizeof(sOption), "speed");
        type = 2;
    }
    else if(iNumber >= 25 && iNumber <= 27)
    {
        if (GetRandomInt(1, 2) == 1)
        {
            Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %snichts%s gewürfelt.", SPECIAL, TEXT);
            Format(sOption, sizeof(sOption), "nothing");
            type = 1;
        }
        else
        {
            // noclip
            SetEntityMoveType(client, MOVETYPE_NOCLIP);
            g_hNoclip[client] = CreateTimer(1.0, NoclipTimer, client, TIMER_REPEAT);
            
            Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sNoclip%s gewürfelt.", SPECIAL, TEXT);
            Format(sOption, sizeof(sOption), "noclip");
            type = 2;
        }
    }
    else if(iNumber >= 28 && iNumber <= 30)
    {
        // glock
        GivePlayerItem(client, "weapon_glock");
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %seine Glock%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "glock");
        type = 2;
    }
    else if(iNumber >= 31 && iNumber <= 43)
    {
        // -50 hp
        SetHealth(client, 50, false);
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %s-50 HP%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "-50hp");
        type = 0;
    }
    else if(iNumber >= 44 && iNumber <= 53)
    {
        // anbrennen
        IgniteEntity(client, 14.0);
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sanbrennen%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "burn");
        type = 0;
    }
    else if(iNumber >= 54 && iNumber <= 55)
    {
        // Assassine
        g_bAssassine[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sAssassine%s gewürfelt.", SPECIAL, TEXT);
        Format(sText1, sizeof(sText1), "Man kann deine Kill's nicht mehr sehen");
        Format(sText2, sizeof(sText2), "Kleiner Tipp: Ergib dich als Assassine nicht!");
        Format(sOption, sizeof(sOption), "assassine");
        type = 2;
    }
    else if(iNumber >= 56 && iNumber <= 60)
    {
        // Strip all
        DNG_StripAllWeapons(client);
        g_bLose[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %salles verloren%s.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "loseall");
        type = 0;
    }
    else if(iNumber >= 61 && iNumber <= 62)
    {
        // selbstmordattentäter
        ForcePlayerSuicide(client);

        Format(sText, sizeof(sText), "Zur Seite mit dir...!");
        Format(sOption, sizeof(sOption), "slay");
        type = 0;
    }
    else if(iNumber >= 63 && iNumber <= 65)
    {
        // High grav
        SetEntityGravity(client, 1.8);
        g_hHighGravity[client] = CreateTimer(1.0, HighGravityTimer, client, TIMER_REPEAT);
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %shigh Gravity%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "highGravity");
        type = 0;
    }
    else if(iNumber >= 66 && iNumber <= 70)
    {
        // Tollpatsch
        g_bTollpatsch[client] = true;
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %sTollpatsch%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "tollpatsch");
        type = 0;
    }
    else if(iNumber >= 71 && iNumber <= 85)
    {
        // nichts
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "nothing");
        type = 1;
    }
    else if(iNumber >= 86 && iNumber <= 100)
    {
        // Granate
        GivePlayerItem(client, "weapon_hegrenade");
        
        Format(sText, sizeof(sText), "Du hast beim 2. Würfeln %seine Granate%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "hegrenade");
        type = 2;
    }
    
    AddDiceToMySQL(client, 2, sOption);

    CPrintToChat(client, sText);

    char sBuffer[32];
    Format(sBuffer, sizeof(sBuffer), "Dice - Option: %d", iNumber);
    panel.SetTitle(sBuffer);

    CRemoveTags(sText, sizeof(sText));
    panel.DrawText(sText);

    if (strlen(sText1) > 2)
    {
        CPrintToChat(client, sText1);
        CRemoveTags(sText1, sizeof(sText1));
        panel.DrawText(sText1);
    }

    if (strlen(sText2) > 2)
    {
        CPrintToChat(client, sText2);
        CRemoveTags(sText2, sizeof(sText2));
        panel.DrawText(sText2);
    }

    return type;
}

public void Frame_GiveTaser(any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client))
    {
        GivePlayerItem(client, "weapon_taser");
    }
}
