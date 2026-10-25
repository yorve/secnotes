(function () {
  var root = document.getElementById('post-content');
  if (!root) return;

  root.querySelectorAll('img').forEach(function (img) { img.loading = 'lazy'; img.decoding = 'async'; });

  // Botón de copiar código
  root.querySelectorAll('pre').forEach(function (pre) {
    var wrap = document.createElement('div');
    wrap.className = 'code-wrap';
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'copy-btn';
    btn.textContent = 'Copiar';
    btn.addEventListener('click', function () {
      var done = function () {
        btn.textContent = 'Copiado';
        setTimeout(function () { btn.textContent = 'Copiar'; }, 1500);
      };
      if (navigator.clipboard) navigator.clipboard.writeText((pre.querySelector('code') || pre).textContent).then(done).catch(function () { btn.textContent = 'Selecciona el código'; });
    });
    wrap.appendChild(btn);
  });

  // Tabla de contenidos automática (h2/h3)
  var heads = root.querySelectorAll('h2, h3');
  if (heads.length < 3) return;
  var toc = document.createElement('nav');
  toc.className = 'toc post-toc';
  toc.setAttribute('aria-label', 'Índice del artículo');
  toc.innerHTML = '<strong>Contenido</strong><ul></ul>';
  var ul = toc.querySelector('ul');
  heads.forEach(function (h, i) {
    if (!h.id) h.id = 'sec-' + i;
    var li = document.createElement('li');
    li.className = 'toc-' + h.tagName.toLowerCase();
    var link = document.createElement('a');
    link.href = '#' + encodeURIComponent(h.id);
    li.appendChild(link);
    li.firstChild.textContent = h.textContent;
    ul.appendChild(li);
  });
  root.insertBefore(toc, root.firstChild);
})();
