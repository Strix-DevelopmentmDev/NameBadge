Framework = {}
Framework.Type = nil

function DebugPrint(...)
    if Config.Debug then
        print('[strix_badge]', ...)
    end
end

function Locale(key)
    local lang = Locales[Config.Locale] or Locales['en']
    return lang[key] or key
end