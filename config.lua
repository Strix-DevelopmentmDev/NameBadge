Config = {}

Config.Framework = 'auto' -- auto / esx / qb / qbox / custom
Config.Locale = 'en'

Config.BadgeCommand = 'badge'
Config.PlaceCommand = 'badgeplace'
Config.ResetCommand = 'badgereset'

Config.InteractionDistance = 15.0
Config.DrawDistance = 20.0
Config.Use3DText = true

Config.BadgeProp = `prop_fib_badge`
Config.BadgeBone = 24818 -- SKEL_Spine2 / chest-ish
Config.DefaultOffset = vec3(0.11, 0.06, 0.0)
Config.DefaultRotation = vec3(0.0, 90.0, 180.0)

Config.SavePlacement = true
Config.Debug = false

Config.RestrictJobs = true
Config.AllowedJobs = {
    police = true,
    sheriff = true,
    ambulance = true,
    fib = true,
    government = true,
    doj = true,
    lawyer = true,
    realestate = true,
    mechanic = false
}

Config.UseJobGradesAsRank = true

Config.CustomRanks = {
    police = {
        [0] = 'Cadet',
        [1] = 'Officer',
        [2] = 'Senior Officer',
        [3] = 'Sergeant',
        [4] = 'Lieutenant',
        [5] = 'Captain',
        [6] = 'Chief'
    },
    ambulance = {
        [0] = 'EMT',
        [1] = 'Paramedic',
        [2] = 'Field Supervisor',
        [3] = 'Chief'
    }
}

Config.CustomFramework = {
    getPlayerData = function(source)
        -- Example return format:
        -- return {
        --     citizenid = tostring(source),
        --     firstname = 'John',
        --     lastname = 'Doe',
        --     job = 'police',
        --     grade = 2,
        --     jobLabel = 'Police',
        --     rankLabel = 'Senior Officer'
        -- }
        return nil
    end
}

Locales = {
    ['en'] = {
        badge_on = 'Badge equipped.',
        badge_off = 'Badge removed.',
        no_job = 'You are not allowed to use this badge.',
        placement_on = 'Placement mode enabled. Use arrow keys + scroll, ENTER to save, BACKSPACE to cancel.',
        placement_saved = 'Badge placement saved.',
        placement_cancelled = 'Placement cancelled.',
        placement_reset = 'Badge placement reset.'
    }
}