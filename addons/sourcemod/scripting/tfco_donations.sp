#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ripext>

#define PLUGIN_VERSION	"1.0.3"

#define TFCONNECT_TAG	"\x01[\a9E3083TFConnect\x01] "

#define DONATION_SCRIPT_FILE	"tfco_donations"

#define CAMPAIGN_API_URL	"https://tfconnect.org/api/campaigns/active"
#define DONATION_API_URL	CAMPAIGN_API_URL ... "/donations"
#define GOAL_API_URL		CAMPAIGN_API_URL ... "/goals"

#define DONATION_API_MAX_NAME_LENGTH		MAX_NAME_LENGTH
#define DONATION_API_MAX_MESSAGE_LENGTH		500
#define DONATION_API_TIME_FORMAT			"%Y-%m-%dT%H:%M:%S"

#define CROAKER_MODEL	"models/props_tfconnect/festive_2023/croaker_pickup.mdl"
#define CROAKER_SOUND	")tfconnect/croaker_pickup/croaker_pickup_01.mp3"

ConVar sm_tfco_donation_enabled;
ConVar sm_tfco_donation_debug;
ConVar sm_tfco_donation_request_interval;
ConVar tf_player_drop_bonus_ducks;

bool g_bEnabled;
int g_nTotalRaisedCents;
int g_iLastDonationReceivedTime;
Handle g_hRequestTimer;

enum struct DonationData
{
	char name[DONATION_API_MAX_NAME_LENGTH];
	char message[DONATION_API_MAX_MESSAGE_LENGTH];
	int cents_amount;
	int campaign_total;
	int time;
	
	bool InitFromJSON(JSONObject data)
	{
		if (!data.GetString("name", this.name, sizeof(this.name)))
			strcopy(this.name, sizeof(this.name), "Anonymous");
		
		data.GetString("message", this.message, sizeof(this.message));
		
		this.cents_amount = data.GetInt("cents_amount");
		this.campaign_total = data.GetInt("campaign_total");
		
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
	
	g_iLastDonationReceivedTime = GetTime();
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
	
	ServerCommand("script_execute %s", DONATION_SCRIPT_FILE);
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
		HookEvent("teamplay_round_start", OnGameEvent_teamplay_round_start);
		
		tf_player_drop_bonus_ducks.IntValue = 1;
		
		g_hRequestTimer = CreateTimer(sm_tfco_donation_request_interval.FloatValue, Timer_RequestDonations, _, TIMER_REPEAT);
		TriggerTimer(g_hRequestTimer);
	}
	else
	{
		RemoveNormalSoundHook(OnSoundPlayed);
		UnhookEvent("teamplay_round_start", OnGameEvent_teamplay_round_start);
		
		tf_player_drop_bonus_ducks.RestoreDefault();
		
		g_hRequestTimer = null;
	}
	
	g_bEnabled = bEnable;
}

bool FormatMoney(float amount, char[] buffer, int maxlength, int decimals = 2)
{
	char szAmount[16], szFormatted[16], szDecimal[16], szFormat[8];
	Format(szFormat, sizeof(szFormat), "%%.%df", decimals);
	Format(szAmount, sizeof(szAmount), szFormat, amount);
	
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
	
	return Format(buffer, maxlength, "$%s%s%s", szAmount, szFormatted, szDecimal) != 0;
}

void OnDonationReceived(DonationData donation)
{
	char szAmount[16], szTotal[16];
	FormatMoney(donation.cents_amount / 100.0, szAmount, sizeof(szAmount));
	FormatMoney(donation.campaign_total / 100.0, szTotal, sizeof(szTotal), 0);
	
	PrintToChatAll(TFCONNECT_TAG ... "\aE1C5F1%s \x01has donated \a3EFF3E%s\x01. We have raised \a3EFF3E%s\x01 for SpecialEffect!", donation.name, szAmount, szTotal);
	
	// Blank message?
	if (donation.message[0])
		PrintToChatAll("\aE1C5F1%s: \x01\"%s\"", donation.name, donation.message);
}

void OnTotalUpdated(int amount, bool bSilent = false)
{
	char message[16];
	if (!FormatMoney(amount / 100.0, message, sizeof(message), 0))
		return;
	
	// Update donation displays
	char szScriptCode[256];
	Format(szScriptCode, sizeof(szScriptCode), "UpdateTextEntities(\"%s\", %s)", message, bSilent ? "true" : "false");
	
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
	
	// Fetch campaign total
	HTTPRequest request = new HTTPRequest(CAMPAIGN_API_URL);
	request.Get(GET_ActiveCampaign);
	
	// Check incoming donations
	request = new HTTPRequest(DONATION_API_URL);
	request.AppendQueryParam("after_time", "%d", g_iLastDonationReceivedTime);
	request.Get(GET_Donations);
	
	return Plugin_Continue;
}

// /api/campaigns/active
static void GET_ActiveCampaign(HTTPResponse response, any value)
{
	if (!g_bEnabled)
		return;
	
	if (response.Status != HTTPStatus_OK)
	{
		LogError("GET_ActiveCampaign: Failed with status %d", response.Status);
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
	
	if (raised_cents != g_nTotalRaisedCents)
	{
		g_nTotalRaisedCents = raised_cents;
		OnTotalUpdated(raised_cents);
	}
}

// /api/campaigns/active/donations
static void GET_Donations(HTTPResponse response, any value)
{
	if (!g_bEnabled)
		return;
	
	if (response.Status != HTTPStatus_OK)
	{
		LogError("GET_Donations: Failed with status %d", response.Status);
		return;
	}
	
	JSONArray data_array = view_as<JSONArray>(view_as<JSONObject>(response.Data).Get("data"));
	
	// No new donations!
	if (data_array.Length == 0)
		return;
	
	g_iLastDonationReceivedTime = GetTime();
	
	for (int i = 0; i < data_array.Length; i++)
	{
		JSONObject data = view_as<JSONObject>(data_array.Get(i));
		
		DonationData donation;
		if (donation.InitFromJSON(data))
		{
			if (sm_tfco_donation_debug.BoolValue)
			{
				char log[2048];
				if (data.ToString(log, sizeof(log), JSON_INDENT(4)))
					LogMessage("Received donation:\n%s", log);
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
	donation.campaign_total = g_nTotalRaisedCents + donation.cents_amount;
	donation.time = GetTime();
	
	OnDonationReceived(donation);
	OnTotalUpdated(donation.campaign_total);
	
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
	// Give the vscript enough time to initialize the text
	RequestFrame(OnRoundStarted);
}

static void OnRoundStarted()
{
	OnTotalUpdated(g_nTotalRaisedCents, true);
}
