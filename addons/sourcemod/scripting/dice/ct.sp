int ctDiceOne(int client, Panel panel, int option = -1)
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
    
    if(iNumber >= 1 && iNumber <= 6)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 7 && iNumber <= 11)
    {
        float fDamage = GetRandomFloat(10.0, 30.0);
        g_fDamage[client] = 1.0 + (fDamage / 100.0);

        g_bCTMoreDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %smehr Schaden (%.2f mehr geben)%s gewürfelt.", SPECIAL, g_fDamage[client], TEXT);
        Format(sOption, sizeof(sOption), "(ct) moreDamage");
        type = 2;
    }
    else if (iNumber >= 12 && iNumber <= 15)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 16 && iNumber <= 20)
    {
        float fDamage = GetRandomFloat(5.0, 15.0);
        g_fDamage[client] = 1.0 + (fDamage / 100.0);

        g_bCTLessDamage[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sweniger Schaden (%.2f weniger bekommen)%s gewürfelt.", SPECIAL, g_fDamage[client], TEXT);
        Format(sOption, sizeof(sOption), "(ct) lessDamage");
        type = 2;
    }
    else if (iNumber >= 21 && iNumber <= 24)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if(iNumber >= 25 && iNumber <= 29)
    {
        g_bCTHeadshot[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %skein Headshot Schaden (bekommen)%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) noHeadshot");
        type = 2;
    }
    else if (iNumber >= 30 && iNumber <= 33)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 34 && iNumber <= 38)
    {
        int iSpeed = GetRandomInt(1, 3);
        float fSpeed = iSpeed / 10.0;

        SetClientSpeed(client, (GetClientSpeed(client) + fSpeed));

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sSpeed (%.0f%)%s gewürfelt.", SPECIAL, (fSpeed * 100), TEXT);
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
    else if (iNumber >= 48 && iNumber <= 51)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 52 && iNumber <= 56)
    {
        g_bCTRespawn[client] = true;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sRespawn (50% Chance)%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) respawn");
        type = 2;
    }
    else if (iNumber >= 57 && iNumber <= 70)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 71 && iNumber <= 75)
    {
        SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sein Helm%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) helm");
        type = 2;
    }
    else if (iNumber >= 76 && iNumber <= 79)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 80 && iNumber <= 84)
    {
        g_iCount[client] = 0;

        Format(sText, sizeof(sText), "Du hast beim CT Würfel %sErneut Würfeln%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) reroll");
        type = 2;
    }
    else if (iNumber >= 85 && iNumber <= 97)
    {
        Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
        Format(sOption, sizeof(sOption), "(ct) nothing");
        type = 1;
    }
    else if (iNumber >= 98 && iNumber <= 100)
    {
        bool bSkip = false;

        int iWeapon = GetPlayerWeaponSlot(client, 11);
        if(iWeapon != -1)
        {
            if(IsValidEdict(iWeapon) && IsValidEntity(iWeapon))
            {
                char sClass[128];
                GetEntityClassname(iWeapon, sClass, sizeof(sClass));

                if(StrEqual(sClass, "weapon_shield", false))
                {
                    Format(sText, sizeof(sText), "Du hast beim CT Würfel %snichts%s gewürfelt.", SPECIAL, TEXT);
                    Format(sOption, sizeof(sOption), "(ct) nothing");

                    type = 1;

                    bSkip = true;
                }
            }
        }

        if (!bSkip)
        {
            GivePlayerItem(client, "weapon_shield");
            
            Format(sText, sizeof(sText), "Du hast durch den CT Würfel %ein Schield%s gewürfelt.", SPECIAL, TEXT);
            Format(sOption, sizeof(sOption), "(ct) shield");
            type = 2;
        }
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
