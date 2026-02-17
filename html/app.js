let state = { configured: false, hasFaction: false, family: null, identity: {} };

const tablet = document.getElementById('tablet');
const lockScreen = document.getElementById('lockScreen');
const setupScreen = document.getElementById('setupScreen');
const homeScreen = document.getElementById('homeScreen');
const content = document.getElementById('content');

document.getElementById('closeBtn').onclick = () => post('tablet:close');
document.getElementById('appFaction').onclick = () => openFaction();
document.getElementById('appFamily').onclick = () => openFamily();

function post(action, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${action}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data)
  }).then(r => r.json());
}

function renderLock() {
  lockScreen.innerHTML = `<h1>${new Date().toLocaleTimeString()}</h1><p>Wpisz PIN</p><input id="pinInput" placeholder="****" /><button id="unlockBtn">Odblokuj</button>`;
  document.getElementById('unlockBtn').onclick = async () => {
    const ok = await post('tablet:unlock', { pin: document.getElementById('pinInput').value });
    if (ok.ok) showHome();
  };
}

function renderSetup() {
  setupScreen.innerHTML = `<h2>Pierwsza konfiguracja</h2><label>Język</label><select id="lang"><option value="pl">Polski</option><option value="en">English</option></select><label>PIN</label><input id="setupPin" /><button id="saveSetup">Zapisz</button>`;
  document.getElementById('saveSetup').onclick = async () => {
    const res = await post('tablet:completeSetup', { language: document.getElementById('lang').value, pin: document.getElementById('setupPin').value });
    if (res.ok) {
      state.configured = true;
      showLock();
    }
  };
}

function showLock() { tablet.classList.remove('hidden'); setupScreen.classList.add('hidden'); homeScreen.classList.add('hidden'); lockScreen.classList.remove('hidden'); renderLock(); }
function showSetup() { tablet.classList.remove('hidden'); setupScreen.classList.remove('hidden'); homeScreen.classList.add('hidden'); lockScreen.classList.add('hidden'); renderSetup(); }
function showHome() { lockScreen.classList.add('hidden'); setupScreen.classList.add('hidden'); homeScreen.classList.remove('hidden'); content.innerHTML = `<p>Witaj ${state.identity.name || ''}</p>`; }

async function openFamily() {
  if (state.family) {
    content.innerHTML = `<h3>Moja Rodzina</h3><p>Nazwa rodziny: <b>${state.family}</b></p>`;
    return;
  }
  content.innerHTML = `<h3>Moja Rodzina</h3><p>Utwórz rodzinę</p><input id="familyName" placeholder="Nazwa" /><button id="createFamily">Utwórz</button>`;
  document.getElementById('createFamily').onclick = async () => {
    const resp = await post('tablet:createFamily', { name: document.getElementById('familyName').value });
    if (resp.ok) { state.family = resp.family; openFamily(); }
  };
}

async function openFaction() {
  if (!state.hasFaction) {
    content.innerHTML = '<h3>Moja Frakcja</h3><p>Nie jesteś w żadnej frakcji</p>';
    return;
  }
  const data = await post('tablet:getFaction');
  if (!data.ok) return;
  const rows = (data.members || []).map((m, i) => `<tr><td>${i + 1}</td><td>${m.name}</td><td>${m.source}</td><td>${m.rank}</td><td>-</td><td><span class="dot ${m.online ? 'online' : 'offline'}"></span></td></tr>`).join('');
  content.innerHTML = `
    <h3>Członkowie</h3>
    <p>${state.identity.name} • ${state.identity.grade}</p>
    <input placeholder="Wpisz aby wyszukać" />
    <table class="table"><thead><tr><th>#</th><th>Imię i nazwisko</th><th>ID</th><th>Stanowisko</th><th>Dziś godziny</th><th>Status</th></tr></thead><tbody>${rows}</tbody></table>
    <h4>Zarządzanie saldem: ${data.balance} PLN</h4>
    <button id="btnDeposit">Wpłać</button><button id="btnWithdraw">Wypłać</button>
    <h4>Baza danych / Magazyn / Dostawa transportu / Ustawienia / Premie / Wezwania / Czarna Lista</h4>
    <p>Magazyn: W trakcie roboty</p>
  `;
  document.getElementById('btnDeposit').onclick = async () => {
    const amount = prompt('Kwota wpłaty');
    if (!amount) return;
    await post('tablet:factionAction', { type: 'deposit', amount, comment: 'Wpłata z tabletu' });
    openFaction();
  };
  document.getElementById('btnWithdraw').onclick = async () => {
    const amount = prompt('Kwota wypłaty');
    if (!amount) return;
    await post('tablet:factionAction', { type: 'withdraw', amount, comment: 'Wypłata z tabletu' });
    openFaction();
  };
}

window.addEventListener('message', (event) => {
  const { action, payload } = event.data;
  if (action === 'open') {
    state = payload;
    if (!state.configured) showSetup(); else showLock();
  }
  if (action === 'close') tablet.classList.add('hidden');
});
