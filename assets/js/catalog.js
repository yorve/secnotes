// Filter the server-rendered catalog. All articles remain available without JavaScript.
(() => {
  const catalog = document.getElementById('catalog');
  if (!catalog) return;
  const cards = [...catalog.querySelectorAll('.post-card')];
  const search = document.getElementById('search-input');
  const tag = document.getElementById('tag-filter');
  const system = document.getElementById('system-filter');
  const status = document.getElementById('catalog-status');
  const previous = document.getElementById('previous-page');
  const next = document.getElementById('next-page');
  const pageStatus = document.getElementById('page-status');
  const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const entries = cards.map(card => ({card, text: normalize(card.dataset.search), tags: JSON.parse(card.dataset.tags), system: card.dataset.system}));
  let page = 1;
  const size = 9;
  function render(reset = false) {
    if (reset) page = 1;
    const terms = normalize(search.value.trim()).split(/\s+/).filter(Boolean);
    const matches = entries.filter(entry => terms.every(term => entry.text.includes(term)) && (!tag.value || entry.tags.includes(tag.value)) && (!system.value || entry.system === system.value));
    const pages = Math.max(1, Math.ceil(matches.length / size));
    page = Math.min(page, pages);
    cards.forEach(card => { card.hidden = true; });
    matches.slice((page - 1) * size, page * size).forEach(entry => { entry.card.hidden = false; });
    status.textContent = matches.length ? `${matches.length} artículos encontrados` : 'No hay coincidencias. Prueba otra técnica o restablece los filtros.';
    pageStatus.textContent = `Página ${page} de ${pages}`;
    previous.disabled = page === 1;
    next.disabled = page === pages;
    document.getElementById('catalog-pagination').hidden = matches.length <= size;
  }
  search.addEventListener('input', () => render(true));
  tag.addEventListener('change', () => render(true));
  system.addEventListener('change', () => render(true));
  document.getElementById('reset-filters').addEventListener('click', () => {
    search.value = ''; tag.value = ''; system.value = ''; render(true); search.focus();
  });
  function move(delta) { page += delta; render(); document.getElementById('catalog-title').focus(); }
  previous.addEventListener('click', () => move(-1));
  next.addEventListener('click', () => move(1));
  document.getElementById('catalog-controls').hidden = false;
  render();
})();
