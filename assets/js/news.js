(() => {
  const controls = document.getElementById('news-controls');
  const filters = document.getElementById('filters');
  const searchInput = document.getElementById('news-search');
  const status = document.getElementById('news-status');
  const empty = document.getElementById('news-empty');
  const editions = [...document.querySelectorAll('.edition')];
  const stories = [...document.querySelectorAll('.item[data-category]')];
  if (!stories.length || !filters) return;

  const normalize = value => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const indexed = stories.map(story => ({
    el: story,
    category: story.dataset.category || '',
    text: normalize(story.dataset.search || story.textContent || '')
  }));

  let activeCategory = '';
  const categories = new Set(indexed.map(item => item.category).filter(Boolean));
  if (controls) controls.hidden = false;
  filters.hidden = false;

  function applyFilters() {
    const terms = searchInput ? normalize(searchInput.value.trim()).split(/\s+/).filter(Boolean) : [];
    let visibleCount = 0;

    for (const item of indexed) {
      const categoryOk = !activeCategory || item.category === activeCategory;
      const searchOk = terms.every(term => item.text.includes(term));
      const show = categoryOk && searchOk;
      item.el.hidden = !show;
      if (show) visibleCount += 1;
    }

    for (const edition of editions) {
      edition.hidden = !edition.querySelector('.item:not([hidden])');
    }

    if (empty) empty.hidden = visibleCount > 0;
    if (status) {
      status.textContent = visibleCount === 1
        ? '1 noticia encontrada'
        : `${visibleCount} noticias encontradas`;
    }
  }

  for (const category of ['', ...categories]) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = category || 'Todas';
    button.setAttribute('aria-pressed', String(category === ''));
    button.addEventListener('click', () => {
      activeCategory = category;
      for (const filter of filters.querySelectorAll('button')) {
        filter.setAttribute('aria-pressed', String(filter === button));
      }
      applyFilters();
    });
    filters.append(button);
  }

  if (searchInput) {
    searchInput.addEventListener('input', applyFilters);
  }

  applyFilters();
})();
