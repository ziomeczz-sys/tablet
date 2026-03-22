local Translations = {
    ui = {
        not_in_faction = 'You are not in any faction',
        create_family = 'Create family',
        in_progress = 'Work in progress',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = false,
    fallbackLang = 'en'
})
