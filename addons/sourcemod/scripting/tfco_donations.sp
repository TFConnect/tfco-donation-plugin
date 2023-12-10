#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ripext>

#define PLUGIN_VERSION	"1.0.1"

#define TFCONNECT_TAG	"\x01[\x079E3083TFConnect\x01] "

#define DONATION_SCRIPT_FILE	"tfco_donations"

#define CAMPAIGN_API_URL	"https://tfconnect.org/api/campaigns/active"
#define DONATION_API_URL	CAMPAIGN_API_URL ... "/donations"
#define GOAL_API_URL		CAMPAIGN_API_URL ... "/goals"

#define DONATION_API_MAX_NAME_LENGTH		33
#define DONATION_API_MAX_MESSAGE_LENGTH		101
#define DONATION_API_TIME_FORMAT			"%Y-%m-%dT%H:%M:%S"

#define CROAKER_MODEL	"models/props_tfconnect/festive_2023/croaker_pickup.mdl"
#define CROAKER_SOUND	")tfconnect/croaker_pickup/croaker_pickup_01.mp3"

ConVar sm_tfco_donation_enabled;
ConVar sm_tfco_donation_debug;
ConVar sm_tfco_donation_request_interval;
ConVar tf_player_drop_bonus_ducks;

bool g_bEnabled;
int g_nRaisedCents;
int g_iLastCheckedTimestamp;
Handle g_hRequestTimer;

enum struct DonationData
{
	char name[DONATION_API_MAX_NAME_LENGTH];
	char message[DONATION_API_MAX_MESSAGE_LENGTH];
	int cents_amount;
	int time;
	
	bool InitFromJSON(JSONObject data)
	{
		if (!data.GetString("name", this.name, sizeof(this.name)))
			strcopy(this.name, sizeof(this.name), "Anonymous");
		
		data.GetString("message", this.message, sizeof(this.message));
		
		this.cents_amount = data.GetInt("cents_amount");
		
		char time[32];
		if (data.GetString("time", time, sizeof(time)))
			this.time = ParseTime(time, DONATION_API_TIME_FORMAT);
		
		return true;
	}
}

public Plugin myinfo = 
{
	name = "TFConnect Donation Plugin", 
	author = "Mikusch", 
	description = "Plugin to handle incoming donations for TFConnect servers.", 
	version = PLUGIN_VERSION, 
	url = "https://tfconnect.org"
}

public void OnPluginStart()
{
	sm_tfco_donation_enabled = CreateConVar("sm_tfco_donation_enabled", "1");
	sm_tfco_donation_enabled.AddChangeHook(OnPluginEnabled);
	sm_tfco_donation_debug = CreateConVar("sm_tfco_donation_debug", "0");
	sm_tfco_donation_request_interval = CreateConVar("sm_tfco_donation_request_interval", "10.0");
	tf_player_drop_bonus_ducks = FindConVar("tf_player_drop_bonus_ducks");
	
	RegAdminCmd("sm_tfco_test_donation", HandleCommand_TestDonation, ADMFLAG_CHEATS);
	
	g_iLastCheckedTimestamp = GetTime();
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup.dx80.vtx");
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup.dx90.vtx");
	AddFileToDownloadsTable(CROAKER_MODEL);
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup.sw.vtx");
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup.vvd");
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup.phy");
	PrecacheModel(CROAKER_MODEL);
	
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup/croaker_plush.vmt");
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup/croaker_plush_nm.vtf");
	AddFileToDownloadsTable("models/props_tfconnect/festive_2023/croaker_pickup/croaker_plush.vtf");
	
	PrecacheSound(CROAKER_SOUND);
}

public void OnConfigsExecuted()
{
	if (g_bEnabled != sm_tfco_donation_enabled.BoolValue)
	{
		TogglePlugin(sm_tfco_donation_enabled.BoolValue);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bEnabled)
		return;
	
	if (StrEqual(classname, "tf_bonus_duck_pickup"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnDuckSpawnPost);
	}
}

void TogglePlugin(bool bEnable)
{
	if (bEnable)
	{
		AddNormalSoundHook(OnSoundPlayed);
		ServerCommand("script_execute %s", DONATION_SCRIPT_FILE);
		HookEvent("teamplay_round_start", OnGameEvent_teamplay_round_start);
		
		tf_player_drop_bonus_ducks.IntValue = 1;
		
		g_hRequestTimer = CreateTimer(sm_tfco_donation_request_interval.FloatValue, Timer_RequestDonations, _, TIMER_REPEAT);
		TriggerTimer(g_hRequestTimer);
	}
	else
	{
		RemoveNormalSoundHook(OnSoundPlayed);
		
		tf_player_drop_bonus_ducks.RestoreDefault();
		
		g_hRequestTimer = null;
	}
	
	g_bEnabled = bEnable;
}

int FormatMoney(float amount, char[] buffer, int maxlength)
{
	char szAmount[16], szFormatted[16], szDecimal[16];
	Format(szAmount, sizeof(szAmount), "%.2f", amount);
	
	int iDecimalPos = StrContains(szAmount, ".");
	if (iDecimalPos != -1)
	{
		strcopy(szDecimal, sizeof(szDecimal), szAmount[iDecimalPos]);
		szAmount[iDecimalPos] = EOS;
	}
	else
	{
		szDecimal[0] = EOS;
	}
	
	while (strlen(szAmount) > 3)
	{
		char szLastThree[4];
		strcopy(szLastThree, sizeof(szLastThree), szAmount[strlen(szAmount) - 3]);
		Format(szFormatted, sizeof(szFormatted), ",%s%s", szLastThree, szFormatted);
		szAmount[strlen(szAmount) - 3] = EOS;
	}
	
	return Format(buffer, maxlength, "$%s%s%s", szAmount, szFormatted, szDecimal);
}

void OnDonationReceived(DonationData donation)
{
	char szAmount[16], szTotal[16];
	FormatMoney(donation.cents_amount / 100.0, szAmount, sizeof(szAmount));
	FormatMoney(g_nRaisedCents / 100.0, szTotal, sizeof(szTotal));
	
	PrintToChatAll(TFCONNECT_TAG ... "\aE1C5F1%s \x01has donated \a3EFF3E%s\x01. The total amount raised is now \a3EFF3E%s\x01!", donation.name, szAmount, szTotal);
	
	if (donation.message[0] != EOS)
		PrintToChatAll("\aE1C5F1%s: \x01\"%s\"", donation.name, donation.message);
}

void UpdateDonationDisplays(char[] message)
{
	char szScriptCode[256];
	Format(szScriptCode, sizeof(szScriptCode), "UpdateDonationDisplays(\"%s\")", message);
	
	SetVariantString(szScriptCode);
	AcceptEntityInput(0, "RunScriptCode");
}

static void OnDuckSpawnPost(int entity)
{
	SetEntityModel(entity, CROAKER_MODEL);
}

static Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, ")ambient_mp3/bumper_car_quack", 29) == 0)
	{
		strcopy(sample, sizeof(sample), CROAKER_SOUND);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

static Action Timer_RequestDonations(Handle timer)
{
	if (g_hRequestTimer != timer)
		return Plugin_Stop;
	
	// Query the campaign details first.
	// Once that succeeds, we know that we can fetch current donations and goals.
	HTTPRequest request = new HTTPRequest(CAMPAIGN_API_URL);
	request.Get(OnCampaignGetRequest);
	
	return Plugin_Continue;
}

// /api/campaigns/active
static void OnCampaignGetRequest(HTTPResponse response, any value)
{
	if (!g_bEnabled)
		return;
	
	if (response.Status != HTTPStatus_OK)
	{
		LogError("OnCampaignGetRequest: Failed with status %d", response.Status);
		return;
	}
	
	JSONObject data = view_as<JSONObject>(view_as<JSONObject>(response.Data).Get("data"));
	
	int goal_cents = data.GetInt("goal_cents");
	int raised_cents = data.GetInt("raised_cents");
	
	if (sm_tfco_donation_debug.BoolValue)
	{
		char title[256];
		if (data.GetString("title", title, sizeof(title)))
			LogMessage("Retrieved campaign details for '%s': %d / %d raised", title, raised_cents, goal_cents);
	}
	
	if (raised_cents != g_nRaisedCents)
	{
		g_nRaisedCents = raised_cents;
		
		char message[16];
		if (FormatMoney(raised_cents / 100.0, message, sizeof(message)))
			UpdateDonationDisplays(message);
	}
	
	// Now, query donations.
	HTTPRequest request = new HTTPRequest(DONATION_API_URL);
	request.AppendQueryParam("after_time", "%d", g_iLastCheckedTimestamp);
	request.Get(OnDonationGetRequest);
}

// /api/campaigns/active/donations
static void OnDonationGetRequest(HTTPResponse response, any value)
{
	if (!g_bEnabled)
		return;
	
	if (response.Status != HTTPStatus_OK)
	{
		LogError("OnDonationGetRequest: Failed with status %d", response.Status);
		return;
	}
	
	// Store at which time we checked donations
	g_iLastCheckedTimestamp = GetTime();
	
	JSONArray hResponseDataArray = view_as<JSONArray>(view_as<JSONObject>(response.Data).Get("data"));
	
	// No new donations!
	if (hResponseDataArray.Length == 0)
		return;
	
	for (int i = 0; i < hResponseDataArray.Length; i++)
	{
		JSONObject hDonationData = view_as<JSONObject>(hResponseDataArray.Get(i));
		
		DonationData donation;
		if (donation.InitFromJSON(hDonationData))
		{
			if (sm_tfco_donation_debug.BoolValue)
			{
				char szLogMsg[2048];
				if (hDonationData.ToString(szLogMsg, sizeof(szLogMsg), JSON_INDENT(4)))
					LogMessage("Received donation:\n%s", szLogMsg);
			}
			
			OnDonationReceived(donation);
		}
	}
}

static Action HandleCommand_TestDonation(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tfco_test_donation <amount> [message]");
		return Plugin_Handled;
	}
	
	DonationData donation;
	GetClientName(client, donation.name, sizeof(donation.name));
	
	if (args < 2)
		strcopy(donation.message, sizeof(donation.message), "Test Donation");
	else
		GetCmdArg(2, donation.message, sizeof(donation.message));
	
	donation.cents_amount = GetCmdArgInt(1);
	donation.time = GetTime();
	
	g_nRaisedCents += donation.cents_amount;
	
	char message[64];
	if (FormatMoney(g_nRaisedCents / 100.0, message, sizeof(message)))
		UpdateDonationDisplays(message);
	
	OnDonationReceived(donation);
	
	return Plugin_Handled;
}

static void OnPluginEnabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bEnabled != convar.BoolValue)
	{
		TogglePlugin(convar.BoolValue);
	}
}

static void OnGameEvent_teamplay_round_start(Event event, const char[] name, bool dontBroadcast)
{
	// Give the vscript enough time to initialize the text.
	RequestFrame(OnRoundStarted);
}

static void OnRoundStarted()
{
	char message[16];
	if (FormatMoney(g_nRaisedCents / 100.0, message, sizeof(message)))
		UpdateDonationDisplays(message);
}
