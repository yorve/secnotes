(() => {
  const button = document.getElementById('theme-toggle');
  const icon = document.getElementById('theme-icon');
  const text = document.getElementById('theme-text');
  let saved; try { saved = localStorage.getItem('theme'); } catch (_) {}
  let current = saved === 'light' || saved === 'dark' ? saved : (matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
  function apply() {
    document.documentElement.dataset.theme = current;
    if (icon) icon.className = current === 'light' ? 'fas fa-moon' : 'fas fa-sun';
    const label = current === 'light' ? 'Activar modo oscuro' : 'Activar modo claro';
    if (button) button.setAttribute('aria-label', label);
    if (text) text.textContent = label;
  }
  apply();
  if (button) button.addEventListener('click', () => {
    current = current === 'dark' ? 'light' : 'dark'; apply();
    try { localStorage.setItem('theme', current); } catch (_) {}
  });
})();
