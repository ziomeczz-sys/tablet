const Views = {
  lock() {
    return `<div class="pin-card"><h1>iPad Security</h1><p>Wpisz swój PIN</p><input id="pinInput" type="password" maxlength="8" /><button class="btn" id="unlockBtn">Odblokuj</button></div>`;
  },
  setup() {
    return `<div class="pin-card"><h2>Pierwsza konfiguracja</h2><label>Język</label><select id="setupLang"><option value="pl">Polski</option><option value="en">English</option></select><label>PIN</label><input id="setupPin" type="password" maxlength="8" /><button id="setupBtn" class="btn">Zapisz</button></div>`;
  },
  family(state) {
    if (state.family) return `<h3>Moja Rodzina</h3><p>Twoja rodzina: <b>${state.family}</b></p>`;
    return `<h3>Moja Rodzina</h3><p>Utwórz rodzinę</p><input id="familyName" placeholder="Nazwa rodziny" /><button id="familyCreate" class="btn">Utwórz</button>`;
  }
};

function money(v) {
  return new Intl.NumberFormat('pl-PL').format(Number(v || 0));
}
