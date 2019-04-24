#if defined _ctcontroller_included
 #endinput
#endif
#define _ctcontroller_included

forward Action CTC_OnPlayerCheck(int client);
forward Action CTC_OnValidCheck(int client, bool &allow)

native bool CTC_IsClientValidCT(int client);
native bool CTC_HasClientCTBan(int client);
native bool CTC_GetClientBanReason(int client, char[] reason, int size);

public SharedPlugin __pl_ctcontroller = 
{
	name = "ctcontroller",
	file = "ctcontroller.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ctcontroller_SetNTVOptional()
{
	MarkNativeAsOptional("CTC_IsClientValidCT");
	MarkNativeAsOptional("CTC_HasClientCTBan");
	MarkNativeAsOptional("CTC_GetClientBanReason");
}
#endif
