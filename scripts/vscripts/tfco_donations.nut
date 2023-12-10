IncludeScript("worldtext_center")

const TFCO_DONATION_TEXT_NAME = "tfco_donation_text"

ClearGameEventCallbacks()

function OnGameEvent_teamplay_round_start(params)
{
	// Resupply Locker
	local regenerate
	while (regenerate = Entities.FindByClassname(regenerate, "func_regenerate"))
	{
		local prop = NetProps.GetPropEntity(regenerate, "m_hAssociatedModel")
		if (prop == null)
			continue
		
		local worldtext = SpawnEntityFromTable("point_worldtext",
		{
			targetname = TFCO_DONATION_TEXT_NAME,
			textsize = "20",
			origin = prop.GetOrigin(),
			angles = prop.GetAbsAngles() + QAngle(0, 180, 0),
		})
		
		EntFireByHandle(worldtext, "SetParent", "!activator", -1, prop, null)
	}

	// Control Point
	local point
	while (point = Entities.FindByClassname(point, "team_control_point"))
	{
		local bone = point.LookupBone("spinner")
		if (bone == -1)
			continue
		
		local worldtext = SpawnEntityFromTable("point_worldtext",
		{
			targetname = TFCO_DONATION_TEXT_NAME,
			textsize = "20",
			origin = point.GetBoneOrigin(bone)
		})
		EntFireByHandle(worldtext, "SetParent", "!activator", -1, point, null)

		AddThinkToEnt(worldtext, "ControlPointTextThink")
	}
}

__CollectGameEventCallbacks(this)

function ControlPointTextThink()
{
	local parent = NetProps.GetPropEntity(self, "m_hMoveParent")
	if (parent == null)
		return

	local bone = parent.LookupBone("spinner")
	if (bone == -1)
		return

	CalcTextTotalSize(self)
	self.SetAbsAngles(parent.GetBoneAngles(bone) + QAngle(0, 0, -90))
	self.SetAbsOrigin(parent.GetBoneOrigin(bone) + self.GetAbsAngles().Left() * TextSizeOutWidth * -0.5)

	return -1
}

function UpdateDonationDisplays(message)
{
	local worldtext
	while (worldtext = Entities.FindByName(worldtext, TFCO_DONATION_TEXT_NAME))
	{
		worldtext.KeyValueFromString("message", message)

		local parent = NetProps.GetPropEntity(worldtext, "m_hMoveParent")
		if (parent == null)
			continue

		RepositionText(worldtext, parent)
		DispatchParticleEffect("bday_confetti", worldtext.GetOrigin(), worldtext.GetAbsAngles() + Vector())
		worldtext.EmitSound("Game.HappyBirthdayNoiseMaker")
	}
}

function RepositionText(worldtext, parent)
{
	CalcTextTotalSize(worldtext)
	local origin = parent.GetOrigin()
	origin.z += parent.GetBoundingMaxsOriented().z + 10.0
	origin += worldtext.GetAbsAngles().Left() * TextSizeOutWidth * -0.5
	worldtext.SetAbsOrigin(origin)
}