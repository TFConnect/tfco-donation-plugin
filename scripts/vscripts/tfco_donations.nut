IncludeScript("worldtext_center")

const TFCO_DONATION_TEXT_NAME = "tfco_donation_text"
const TFCO_DONATION_TEXT_SIZE = 20

local EventsID = UniqueString()
getroottable()[EventsID] <- 
{
	OnGameEvent_teamplay_round_start = function(params)
	{
		if (!Convars.GetBool("sm_tfco_donation_enabled"))
			return

		// Resupply locker (static text)
		local regenerate
		while (regenerate = Entities.FindByClassname(regenerate, "func_regenerate"))
		{
			local prop = NetProps.GetPropEntity(regenerate, "m_hAssociatedModel")
			if (prop == null)
				continue

			local worldtext = SpawnEntityFromTable("point_worldtext",
			{
				targetname = TFCO_DONATION_TEXT_NAME,
				textsize = TFCO_DONATION_TEXT_SIZE,
				origin = prop.GetOrigin(),
				angles = prop.GetAbsAngles() + QAngle(0, 180, 0),
			})

			EntFireByHandle(worldtext, "SetParent", "!activator", -1, prop, null)
			AddThinkToEnt(worldtext, "ResupplyTextThink")
		}

		// Control point (rotating text)
		local point
		while (point = Entities.FindByClassname(point, "team_control_point"))
		{
			local bone = point.LookupBone("spinner")
			if (bone == -1)
				continue

			local worldtext = SpawnEntityFromTable("point_worldtext",
			{
				targetname = TFCO_DONATION_TEXT_NAME,
				textsize = TFCO_DONATION_TEXT_SIZE,
				origin = point.GetBoneOrigin(bone)
			})

			// For smoother bone updates
			NetProps.SetPropBool(point, "m_bUseClientSideAnimation", false)
			AddThinkToEnt(point, "ControlPointThink")

			EntFireByHandle(worldtext, "SetParent", "!activator", -1, point, null)
			AddThinkToEnt(worldtext, "ControlPointTextThink")
		}
	}
}
local EventsTable = getroottable()[EventsID]
foreach (name, callback in EventsTable) EventsTable[name] = callback.bindenv(this)
__CollectGameEventCallbacks(EventsTable)

::ResupplyTextThink <- function()
{
	local parent = NetProps.GetPropEntity(self, "m_hMoveParent")
	if (parent == null)
		return

	CalcTextTotalSize(self)
	local origin = parent.GetOrigin()
	origin.z += parent.GetBoundingMaxsOriented().z + 10.0
	origin += self.GetAbsAngles().Left() * TextSizeOutWidth * -0.5
	self.SetAbsOrigin(origin)

	return -1
}

::ControlPointThink <- function()
{
	self.StudioFrameAdvance()
	return -1
}

::ControlPointTextThink <- function()
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

::UpdateTextEntities <- function(message, silent)
{
	local worldtext
	while (worldtext = Entities.FindByName(worldtext, TFCO_DONATION_TEXT_NAME))
	{
		worldtext.KeyValueFromString("message", message)

		CalcTextTotalSize(worldtext)
		local origin = worldtext.GetOrigin() - worldtext.GetAbsAngles().Left() * TextSizeOutWidth * -0.5

		if (!silent)
		{
			DispatchParticleEffect("bday_confetti", origin, worldtext.GetAbsAngles() + Vector())
			worldtext.EmitSound("Game.HappyBirthdayNoiseMaker")
		}
	}
}