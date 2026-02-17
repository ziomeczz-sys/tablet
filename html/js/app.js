const state = { configured: false, hasFaction: false, family: null, identity: {}, faction: null };
const app = document.getElementById('app');
const lockScreen = document.getElementById('lockScreen');
const setupScreen = document.getElementById('setupScreen');
const homeScreen = document.getElementById('homeScreen');
const contentArea = document.getElementById('contentArea');
const mainGrid = document.getElementById('mainGrid');
const modal = document.getElementById('modal');
const modalTitle = document.getElementById('modalTitle');
const modalBody = document.getElementById('modalBody');
const modalCancel = document.getElementById('modalCancel');
const modalConfirm = document.getElementById('modalConfirm');

const permLabels = {
  canHire: 'Przyjmowanie do organizacji',
  canFire: 'Zwalnianie z organizacji',
  canWarn: 'Wydawanie ostrzeżeń',
  canStorage: 'Dostęp do magazynu',
  canDeposit: 'Wpłata środków na saldo',
  canWithdraw: 'Wypłata środków z salda',
  canBonus: 'Wypłacanie premii',
  canPromote: 'Zmiana rangi',
  canManageRanks: 'Zarządzanie rangami',
  canLicenses: 'Wydawanie licencji',
  canGNews: 'Dostęp do /gnews',
  canFunding: 'Zarządzanie finansowaniem',
  canJail: 'Dostęp do wysyłania do więzienia',
  canManageBlacklist: 'Zarządzanie czarną listą',
  canDatabase: 'Dostęp do bazy danych',
};

let modalSubmit = null;


window.onerror = function(message, source, lineno, colno) {
  app.classList.remove('hidden');
  lockScreen.classList.remove('hidden');
  setupScreen.classList.add('hidden');
  homeScreen.classList.add('hidden');
  lockScreen.innerHTML = `<div class="pin-card"><h3>Błąd UI tabletu</h3><p class="small">${String(message)} (${lineno}:${colno})</p></div>`;
  return false;
};

function notify(msg) { console.log('[tablet]', msg); }

function showModal(title, bodyHtml, onConfirm) {
  modalTitle.textContent = title;
  modalBody.innerHTML = bodyHtml;
  modal.classList.remove('hidden');
  modalSubmit = onConfirm;
}

modalCancel.onclick = () => modal.classList.add('hidden');
modalConfirm.onclick = async () => {
  if (modalSubmit) await modalSubmit();
  modal.classList.add('hidden');
};

function setFactionMode(enabled) {
  if (!mainGrid) return;
  if (enabled) mainGrid.classList.add('faction-mode');
  else mainGrid.classList.remove('faction-mode');
}

function openLock() {
  app.classList.remove('hidden');
  lockScreen.classList.remove('hidden');
  setupScreen.classList.add('hidden');
  homeScreen.classList.add('hidden');
  lockScreen.innerHTML = Views.lock();
  document.getElementById('unlockBtn').onclick = async () => {
    const pin = document.getElementById('pinInput').value;
    const res = await TabletApi.rpc('unlock', { pin });
    if (res.ok) openHome();
  };
}

function openSetup() {
  app.classList.remove('hidden');
  lockScreen.classList.add('hidden');
  setupScreen.classList.remove('hidden');
  homeScreen.classList.add('hidden');
  setupScreen.innerHTML = Views.setup();
  document.getElementById('setupBtn').onclick = async () => {
    const language = document.getElementById('setupLang').value;
    const pin = document.getElementById('setupPin').value;
    const res = await TabletApi.rpc('setup', { language, pin });
    if (res.ok) {
      state.configured = true;
      openLock();
    }
  };
}

function openHome() {
  setFactionMode(false);
  lockScreen.classList.add('hidden');
  setupScreen.classList.add('hidden');
  homeScreen.classList.remove('hidden');
  document.getElementById('identityText').textContent = `${state.identity.name || ''} • ${state.identity.rankLabel || ''}`;
  contentArea.innerHTML = `<h3>Wybierz aplikację</h3><p class="small">Czarne tło, białe napisy, mniejsze ikony i profesjonalny układ.</p>`;
}

async function loadFaction() {
  if (!state.hasFaction) {
    contentArea.innerHTML = `<h3>Moja Frakcja</h3><p>Nie jesteś w żadnej frakcji.</p>`;
    return;
  }

  const resp = await TabletApi.rpc('factionDashboard');
  if (!resp.ok) return notify(resp.message || 'Błąd frakcji');
  state.faction = resp;
  setFactionMode(true);
  renderFaction('members');
}

function renderFaction(tab) {
  const f = state.faction;
  const tabs = [
    ['members', 'Członkowie'], ['database', 'Baza Danych'], ['storage', 'Magazyn'],
    ['balance', 'Zarządzanie saldem'], ['transport', 'Dostawa transportu'], ['settings', 'Ustawienia'],
    ['bonus', 'Premie'], ['calls', 'Wezwania'], ['blacklist', 'Czarna Lista']
  ];

  const tabHtml = tabs.map(([key, label]) => `<button class="tab-btn ${tab===key?'active':''}" data-tab="${key}">${label}</button>`).join('');
  contentArea.innerHTML = `<div class="row" style="justify-content:space-between;margin-bottom:8px"><button class="btn ghost" id="backApps">← Aplikacje</button><div class="small">${f.me.name} • ${f.me.rank}</div></div><div class="tabs">${tabHtml}</div><div id="tabContent"></div>`;
  document.getElementById('backApps').onclick = () => openHome();
  contentArea.querySelectorAll('.tab-btn').forEach(btn => btn.onclick = () => renderFaction(btn.dataset.tab));

  const box = document.getElementById('tabContent');
  if (tab === 'members') {
    const rows = f.members.map((m, i) => `<tr data-cid="${m.citizenid}"><td>${i+1}</td><td>${m.name}</td><td>${m.source}</td><td>${m.rank}</td><td>${m.todayHours || 0}</td><td><span class="dot ${m.online?'green':'gray'}"></span></td></tr>`).join('');
    box.innerHTML = `
      <div class="split">
        <div>
          <h3>Członkowie</h3>
          <input id="memberSearch" placeholder="Wpisz aby wyszukać" />
          <table class="table"><thead><tr><th>#</th><th>Imię i nazwisko</th><th>ID</th><th>Stanowisko</th><th>Dziś h</th><th>Status</th></tr></thead><tbody id="memberRows">${rows}</tbody></table>
        </div>
        <div>
          <div class="stat"><b>${f.me.name}</b><br/><small>${f.me.rank}</small></div>
          <div class="stat" style="margin-top:8px">Saldo: <b>${money(f.balance)} PLN</b></div>
        </div>
      </div>`;

    document.getElementById('memberSearch').oninput = (e) => {
      const q = e.target.value.toLowerCase();
      document.querySelectorAll('#memberRows tr').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
      });
    };
    document.querySelectorAll('#memberRows tr').forEach(tr => tr.onclick = () => openMemberDetails(tr.dataset.cid));
  }

  if (tab === 'database') {
    const citizensRows = f.members.map(m => `<tr><td>${m.name}</td><td>${m.role}</td><td>xxx</td><td>${(f.warrants||[]).filter(w=>w.citizenid===m.citizenid).length}</td><td>${(f.arrests||[]).filter(a=>a.citizenid===m.citizenid).length}</td><td>${m.online?'Aktywny':'Offline'}</td></tr>`).join('');
    box.innerHTML = `<h3>Baza Danych</h3><div class="tabs"><button class="tab-btn active">Obywatele</button><button class="tab-btn">Transport</button><button class="tab-btn">Aresztowania</button><button class="tab-btn">Mandaty</button></div>
    <button class="btn" id="addWarrant">Ogłoś poszukiwanie</button>
    <button class="btn" id="addFine">Daj mandat</button>
    <table class="table"><thead><tr><th>Imię i Nazwisko</th><th>Organizacja</th><th>Tel</th><th>Poszukiwanie</th><th>Aresztowania</th><th>Status</th></tr></thead><tbody>${citizensRows}</tbody></table>`;
    document.getElementById('addWarrant').onclick = () => {
      showModal('Ogłoś poszukiwanie', '<input id="wCid" placeholder="CitizenID" /><select id="wStars"><option>0</option><option>1</option><option>2</option><option>3</option><option>4</option><option>5</option></select><textarea id="wReason" placeholder="Powód"></textarea>', async () => {
        await TabletApi.rpc('factionAction', { action: 'db_add_warrant', citizenid: document.getElementById('wCid').value, stars: Number(document.getElementById('wStars').value), reason: document.getElementById('wReason').value });
        await loadFaction();
      });
    };
    document.getElementById('addFine').onclick = () => {
      showModal('Daj mandat', '<input id="fName" placeholder="Imię i Nazwisko" /><input id="fAmount" placeholder="Kwota" /><textarea id="fReason" placeholder="Powód"></textarea>', async () => {
        await TabletApi.rpc('factionAction', { action: 'db_add_fine', name: document.getElementById('fName').value, amount: Number(document.getElementById('fAmount').value), reason: document.getElementById('fReason').value });
        await loadFaction();
      });
    };
  }

  if (tab === 'storage') box.innerHTML = '<h3>Magazyn</h3><p>W trakcie roboty</p>';

  if (tab === 'balance') {
    const logs = (f.logs || []).map(l => `<tr><td>${l.who}</td><td>${l.source}</td><td>${l.rank}</td><td>${l.action}</td><td>${l.comment}</td><td>${money(l.amount)}</td><td>${l.date}</td></tr>`).join('');
    box.innerHTML = `<h3>PLN ${money(f.balance)}</h3><div class="row"><button class="btn" id="depBtn">Wpłać</button><button class="btn" id="withBtn">Wypłać</button></div>
    <table class="table"><thead><tr><th>Imię i nazwisko</th><th>ID</th><th>Ranga</th><th>Rodzaj</th><th>Komentarz</th><th>Kwota</th><th>Data</th></tr></thead><tbody>${logs}</tbody></table>`;
    document.getElementById('depBtn').onclick = () => balanceModal('deposit', 'Wpłata pieniędzy');
    document.getElementById('withBtn').onclick = () => balanceModal('withdraw', 'Wypłata pieniędzy');
  }

  if (tab === 'transport') {
    box.innerHTML = `<h3>Dostawa transportu</h3>${f.transport.map(v => `<div class="row"><div class="stat" style="flex:1">${v.label}</div><button class="btn" data-key="${v.key}">Dostarcz</button></div>`).join('')}`;
    box.querySelectorAll('button[data-key]').forEach(btn => btn.onclick = async () => {
      await TabletApi.rpc('factionAction', { action: 'spawn_transport', key: btn.dataset.key });
    });
  }

  if (tab === 'settings') {
    const rankRows = Object.entries(f.ranks).map(([grade, rank]) => `<tr><td>${grade}</td><td>${rank.label}</td><td>${rank.salaryPerHour} PLN/h</td><td><button class="btn" data-grade="${grade}">Edytuj</button></td></tr>`).join('');
    box.innerHTML = `<h3>Ustawienia</h3><div class="tabs"><button class="tab-btn active">Rangi</button><button class="tab-btn">Przedmioty</button></div><table class="table"><thead><tr><th>Stopień</th><th>Nazwa rangi</th><th>Wynagrodzenie</th><th>Opcje</th></tr></thead><tbody>${rankRows}</tbody></table>`;
    box.querySelectorAll('button[data-grade]').forEach(btn => btn.onclick = () => openRankSettings(btn.dataset.grade));
  }

  if (tab === 'bonus') box.innerHTML = '<h3>Premie</h3><p>Premie wydawane z salda przez panel członka.</p>';
  if (tab === 'calls') box.innerHTML = '<h3>Wezwania</h3><p>Moduł gotowy pod integrację dispatch.</p>';

  if (tab === 'blacklist') {
    const rows = (f.blacklist || []).map(b => `<tr data-cid="${b.citizenid}"><td>${b.by}</td><td>${b.targetName || b.citizenid}</td><td>${b.reason}</td><td>${b.date}</td></tr>`).join('');
    box.innerHTML = `<h3>Czarna Lista</h3><button class="btn" id="addBlacklist">Dodaj do listy</button><table class="table"><thead><tr><th>Umieścił</th><th>Obywatel</th><th>Powód</th><th>Data</th></tr></thead><tbody>${rows}</tbody></table>`;
    document.getElementById('addBlacklist').onclick = () => {
      showModal('Dodaj do czarnej listy', '<input id="blCid" placeholder="ID gracza / citizenid" /><input id="blName" placeholder="Imię i Nazwisko" /><textarea id="blReason" placeholder="Powód"></textarea>', async () => {
        await TabletApi.rpc('factionAction', { action: 'member_fire', citizenid: document.getElementById('blCid').value, targetName: document.getElementById('blName').value, reason: document.getElementById('blReason').value, addToBlacklist: true });
        await loadFaction();
      });
    };
    box.querySelectorAll('tr[data-cid]').forEach(tr => tr.onclick = () => {
      showModal('Usuń z czarnej listy', '<p>Czy chcesz usunąć z czarnej listy?</p><input id="blRemoveReason" placeholder="Powód"/>', async () => {
        await TabletApi.rpc('factionAction', { action: 'blacklist_remove', citizenid: tr.dataset.cid, reason: document.getElementById('blRemoveReason').value });
        await loadFaction();
      });
    });
  }
}

function openMemberDetails(citizenid) {
  const m = state.faction.members.find(x => x.citizenid === citizenid);
  if (!m) return;
  contentArea.innerHTML = `<button class="btn ghost" id="backToMembers">← Wróć</button>
    <h3>${m.name}</h3>
    <p>ID: ${m.source} | Ranga: ${m.rank} | Warny: ${m.warns || 0} | Dziś h: ${m.todayHours || 0} | Przyjął do org: ${m.hiredBy || 'Brak'}</p>
    <div class="member-actions">
      <button class="btn" id="promoteBtn">Awansuj</button>
      <button class="btn" id="demoteBtn">Degraduj</button>
      <button class="btn" id="warnAddBtn">Wydaj WARN</button>
      <button class="btn" id="warnRmBtn">Zdejmij WARN</button>
      <button class="btn danger" id="fireBtn">Zwolnij</button>
      <button class="btn" id="bonusBtn">Wydaj premię</button>
      <button class="btn" id="jailBtn">Uwięź</button>
    </div>`;
  document.getElementById('backToMembers').onclick = () => renderFaction('members');

  document.getElementById('promoteBtn').onclick = () => rankChangeModal('member_promote', 'Awansuj na rangę', m.citizenid);
  document.getElementById('demoteBtn').onclick = () => rankChangeModal('member_demote', 'Degraduj na rangę', m.citizenid);

  document.getElementById('warnAddBtn').onclick = () => reasonModal('Wydaj WARN', async reason => {
    await TabletApi.rpc('factionAction', { action: 'member_warn_add', citizenid: m.citizenid, reason });
    await loadFaction();
  });
  document.getElementById('warnRmBtn').onclick = () => reasonModal('Zdejmij WARN', async reason => {
    await TabletApi.rpc('factionAction', { action: 'member_warn_remove', citizenid: m.citizenid, reason });
    await loadFaction();
  });
  document.getElementById('fireBtn').onclick = () => {
    showModal('Zwolnij', '<textarea id="fireReason" placeholder="Powód"></textarea><label><input id="fireBlacklist" type="checkbox"/> umieść na czarnej liście</label>', async () => {
      await TabletApi.rpc('factionAction', { action: 'member_fire', citizenid: m.citizenid, targetName: m.name, reason: document.getElementById('fireReason').value, addToBlacklist: document.getElementById('fireBlacklist').checked });
      await loadFaction();
    });
  };
  document.getElementById('bonusBtn').onclick = () => {
    showModal('Wydaj premię', `<p>Dostępne saldo: ${money(state.faction.balance)} PLN</p><input id="bonusAmount" placeholder="Ile zł"/><textarea id="bonusReason" placeholder="Powód"></textarea>`, async () => {
      await TabletApi.rpc('factionAction', { action: 'member_bonus', citizenid: m.citizenid, amount: Number(document.getElementById('bonusAmount').value), reason: document.getElementById('bonusReason').value });
      await loadFaction();
    });
  };
  document.getElementById('jailBtn').onclick = () => {
    showModal('Uwięź obywatela', '<input id="jMonths" placeholder="Ilość miesięcy"/><input id="jFine" placeholder="Kwota grzywny"/>', async () => {
      await TabletApi.rpc('factionAction', { action: 'db_add_arrest', citizenid: m.citizenid, months: Number(document.getElementById('jMonths').value), fine: Number(document.getElementById('jFine').value) });
      await loadFaction();
    });
  };
}

function reasonModal(title, cb) {
  showModal(title, '<textarea id="reasonBox" placeholder="Powód"></textarea>', async () => cb(document.getElementById('reasonBox').value));
}

function rankChangeModal(action, title, citizenid) {
  const options = Object.entries(state.faction.ranks).map(([k, rank]) => `<option value="${k}">${k} ${rank.label}</option>`).join('');
  showModal(title, `<label>${title}:</label><select id="targetRank">${options}</select><textarea id="rankReason" placeholder="Powód"></textarea>`, async () => {
    await TabletApi.rpc('factionAction', { action, citizenid, gradeLevel: Number(document.getElementById('targetRank').value), reason: document.getElementById('rankReason').value });
    await loadFaction();
  });
}

function openRankSettings(grade) {
  const rank = state.faction && state.faction.ranks && state.faction.ranks[grade];
  if (!rank) return;
  const perms = rank.permissions || {};

  const permRows = Object.keys(permLabels).map((key) => {
    const value = !!perms[key];
    return `<div class="toggle"><span>${permLabels[key]}</span><input type="checkbox" id="perm_${key}" ${value ? 'checked' : ''} /></div>`;
  }).join('');

  showModal(`Ranga ${rank.label}`, `
    <label>Nazwa rangi</label>
    <input id="rankName" value="${rank.label}" />
    <label>Wynagrodzenie za godzinę (max 10000)</label>
    <div class="range-wrap">
      <input id="salaryRange" type="range" min="0" max="10000" step="100" value="${Math.min(Number(rank.salaryPerHour || 0), 10000)}" />
      <input id="salaryValue" type="number" min="0" max="10000" step="100" value="${Math.min(Number(rank.salaryPerHour || 0), 10000)}" style="width:120px" />
    </div>
    <div class="small">Maksymalna kwota: 10000 PLN / godzinę</div>
    <hr style="border-color:#222" />
    ${permRows}
  `, async () => {
    const salary = Math.min(10000, Math.max(0, Number(document.getElementById('salaryValue').value || 0)));
    const updatedPerms = {};
    Object.keys(permLabels).forEach((key) => {
      const el = document.getElementById(`perm_${key}`);
      updatedPerms[key] = !!(el && el.checked);
    });

    await TabletApi.rpc('factionAction', {
      action: 'rank_update',
      gradeLevel: Number(grade),
      label: document.getElementById('rankName').value,
      salaryPerHour: salary,
      permissions: updatedPerms,
    });

    await loadFaction();
  });

  const salaryRange = document.getElementById('salaryRange');
  const salaryValue = document.getElementById('salaryValue');
  salaryRange.oninput = () => salaryValue.value = salaryRange.value;
  salaryValue.oninput = () => {
    const v = Math.min(10000, Math.max(0, Number(salaryValue.value || 0)));
    salaryValue.value = v;
    salaryRange.value = v;
  };
}

function balanceModal(action, title) {
  showModal(title, '<input id="balAmount" placeholder="Wpisz wartość" /><textarea id="balComment" placeholder="Zostaw komentarz"></textarea>', async () => {
    await TabletApi.rpc('factionAction', { action, amount: Number(document.getElementById('balAmount').value), comment: document.getElementById('balComment').value });
    await loadFaction();
  });
}

function openFamily() {
  setFactionMode(false);
  contentArea.innerHTML = Views.family(state);
  const btn = document.getElementById('familyCreate');
  if (btn) {
    btn.onclick = async () => {
      const name = document.getElementById('familyName').value;
      const res = await TabletApi.rpc('createFamily', { name });
      if (res.ok) {
        state.family = res.family;
        openFamily();
      }
    };
  }
}

document.getElementById('closeBtn').onclick = () => TabletApi.close();
document.getElementById('appFaction').onclick = () => loadFaction();
document.getElementById('appFamily').onclick = () => openFamily();

window.addEventListener('message', (event) => {
  const data = event.data;
  if (data.action === 'tablet:open') {
    Object.assign(state, data.payload || {});
    if (!state.configured) openSetup(); else openLock();
  }
  if (data.action === 'tablet:close') {
    app.classList.add('hidden');
    setFactionMode(false);
    modal.classList.add('hidden');
  }
});
