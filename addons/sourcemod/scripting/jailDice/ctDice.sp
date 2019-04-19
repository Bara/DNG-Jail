int ctDiceOne(int client, Panel panel)
{
    SetRandomSeed(GetTime() * 100 * GetRandomInt(2, 9));

    int iNumber = GetRandomInt(1, 100);
    
    char sOption[32];

    // Types: 0 - Negative, 1 - Neutral, 2 - Positive
    int type = -1;

    char sText[128];
    
    if(iNumber >= 1 && iNumber <= 7)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 8 && iNumber <= 11)
    {
        float fDamage = view_as<float>(RoundToNearest(GetRandomFloat(10.0, 30.0)));
        g_fDamage[client] = (1.0 + (fDamage / 100.0));

        g_bCTMoreDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %smehr Schaden (%.0f mehr geben)%s gewürfelt.", SPECIAL, fDamage, TEXT);
        Format(sOption, sizeof(sOption), "(ct) moreDamage");
        type = 2;
    }
    else if (iNumber >= 12 && iNumber <= 16)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 17 && iNumber <= 20)
    {
        float fDamage = view_as<float>(RoundToNearest(GetRandomFloat(5.0, 15.0)));
        g_fDamage[client] = (1.0 + (fDamage / 100.0));

        g_bCTLessDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sweniger Schaden (%.0f weniger bekommen)%s gewürfelt.", SPECIAL, fDamage, TEXT);
        Format(sOption, sizeof(sOption), "(ct) lessDamage");
        type = 2;
    }
    else if (iNumber >= 21 && iNumber <= 25)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 26 && iNumber <= 29)
    {
        g_bCTHeadshot[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %skein Headshot Schaden (bekommen)%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) noHeadshot");
        type = 2;
    }
    else if (iNumber >= 30 && iNumber <= 34)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 35 && iNumber <= 38)
    {
        int iSpeed = GetRandomInt(1, 3);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", (GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue") + (iSpeed / 10.0)));

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sSpeed (%d%)%s gewürfelt.", SPECIAL, (iSpeed * 10), TEXT);
        Format(sOption, sizeof(sOption), "(ct) speed");
        type = 2;
    }
    else if (iNumber >= 39 && iNumber <= 43)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 44 && iNumber <= 47)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 48 && iNumber <= 52)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 53 && iNumber <= 56)
    {
        g_bCTRespawn[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sRespawn (50% Chance)%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) respawn");
        type = 2;
    }
    else if (iNumber >= 57 && iNumber <= 71)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 72 && iNumber <= 75)
    {
        SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sein Helm%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) helm");
        type = 2;
    }
    else if (iNumber >= 76 && iNumber <= 80)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 81 && iNumber <= 84)
    {
        g_iCount[client] = 0;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sErneut Würfeln%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) reroll");
        type = 2;
    }
    else if (iNumber >= 85 && iNumber <= 100)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }

    AddDiceToMySQL(client, 1, sOption);

    CPrintToChat(client, sText);

    char sTitle[32];
    Format(sTitle, sizeof(sTitle), "Dice - Option: %d", iNumber);
    panel.SetTitle(sTitle);

    CRemoveTags(sText, sizeof(sText));
    panel.DrawText(sText);

    return type;
}
