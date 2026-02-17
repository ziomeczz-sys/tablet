const TabletApi = {
  rpc(endpoint, payload = {}) {
    return fetch(`https://${GetParentResourceName()}/tablet:rpc`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ endpoint, payload })
    }).then(r => r.json());
  },
  close() {
    return fetch(`https://${GetParentResourceName()}/tablet:close`, {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({})
    });
  }
};
