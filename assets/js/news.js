(() => {
  const filters = document.getElementById('filters');
  const editions = [...document.querySelectorAll('.edition')];
  const stories = [...document.querySelectorAll('.item[data-category]')];
  if (!stories.length) return;

  const categories = new Set(stories.map(story => story.dataset.category));
  filters.hidden = false;

  for (const category of ['', ...categories]) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = category || 'Todas';
    button.setAttribute('aria-pressed', String(category === ''));
    button.addEventListener('click', () => {
      for (const filter of filters.querySelectorAll('button')) {
        filter.setAttribute('aria-pressed', String(filter === button));
      }
      for (const story of stories) {
        story.hidden = Boolean(category) && story.dataset.category !== category;
      }
      for (const edition of editions) {
        edition.hidden = !edition.querySelector('.item:not([hidden])');
      }
    });
    filters.append(button);
  }
})();
