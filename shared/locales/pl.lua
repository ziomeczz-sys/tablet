local Translations = {
    ui = {
        not_in_faction = 'Nie jesteś w żadnej frakcji',
        create_family = 'Utwórz rodzinę',
        in_progress = 'W trakcie roboty',
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = false,
    fallbackLang = 'pl'
})
