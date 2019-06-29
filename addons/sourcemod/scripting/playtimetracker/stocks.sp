/* Empty SQL Callbacl*/
public void Query_DoNothing(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null || strlen(error) > 0)
    {
        LogError("Query_DoNothing reported: %s", error);
        return;
    }
}