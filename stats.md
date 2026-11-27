---
layout: post
title: Estadísticas
description: "Estadísticas de SecNotes: writeups publicados, palabras escritas, cobertura por plataforma y sistema, etiquetas y boletines de SecNews."
permalink: /stats/
---
{% assign total = site.posts | size %}
{% assign words = 0 %}
{% for p in site.posts %}{% assign w = p.content | number_of_words %}{% assign words = words | plus: w %}{% endfor %}
{% assign reading_minutes = words | plus: 249 | divided_by: 250 %}
{% assign reading_hours = reading_minutes | divided_by: 60 %}
{% assign all_tags = "" | split: "" %}
{% for post in site.posts %}{% for t in post.tags %}{% assign all_tags = all_tags | push: t %}{% endfor %}{% endfor %}
{% assign tag_groups = all_tags | group_by_exp: "t", "t | downcase" | sort: "size" | reverse %}
{% assign years = site.posts | group_by_exp: "p", "p.date | date: '%Y'" | sort: "name" | reverse %}
{% assign valid_editions = site.boletines | where_exp: "e", "e.noticias" | sort: "path" | reverse %}
{% assign total_news = 0 %}
{% for e in valid_editions %}{% assign total_news = total_news | plus: e.noticias.size %}{% endfor %}

{% assign linux_posts = site.posts | where_exp: "p", "p.path contains '/linux/'" | size %}
{% assign ms2_posts = site.posts | where_exp: "p", "p.tags contains 'Metasploitable 2'" | size %}
{% assign win_posts = site.posts | where_exp: "p", "p.path contains '/windows/'" | size %}

{% assign plat_dockerlabs = site.posts | where_exp: "p", "p.tags contains 'DockerLabs'" | size %}
{% assign plat_thl = site.posts | where_exp: "p", "p.tags contains 'TheHackerLabs'" | size %}
{% assign plat_vulnhub = site.posts | where_exp: "p", "p.tags contains 'VulnHub'" | size %}
{% assign plat_thm = site.posts | where_exp: "p", "p.tags contains 'TryHackMe'" | size %}
{% assign plat_htb = site.posts | where_exp: "p", "p.tags contains 'HackTheBox'" | size %}
{% assign plat_cyber = site.posts | where_exp: "p", "p.tags contains 'CyberAcademy'" | size %}

<style>
  .stats-intro { color: var(--muted); margin-top: 0; }
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(175px, 1fr));
    gap: 14px;
    margin: 24px 0 32px;
  }
  .stat-card {
    background: var(--sidebar-bg);
    border: 1px solid var(--border);
    border-top: 3px solid var(--accent);
    border-radius: 8px;
    padding: 18px 16px;
  }
  .stat-value {
    display: block;
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    font-size: 1.85rem;
    font-weight: 700;
    color: var(--title);
    line-height: 1.2;
  }
  .stat-label {
    display: block;
    font-size: 0.88rem;
    color: var(--muted);
    margin-top: 4px;
  }
  .stat-sub {
    display: block;
    font-family: monospace;
    font-size: 0.78rem;
    color: var(--accent);
    margin-top: 6px;
  }
  .highlight-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 14px;
    margin: 0 0 32px;
  }
  .highlight-card {
    background: var(--sidebar-bg);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 16px 18px;
  }
  .highlight-card small {
    display: block;
    font-family: monospace;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--muted);
    margin-bottom: 6px;
  }
  .highlight-card a { font-weight: 600; }
  .highlight-meta { display: block; font-size: 0.84rem; color: var(--muted); margin-top: 6px; }
  .bar-list { display: flex; flex-direction: column; gap: 12px; margin: 16px 0 28px; }
  .bar-row { display: flex; flex-direction: column; gap: 5px; }
  .bar-head { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; font-size: 0.94rem; }
  .bar-head span:last-child { font-family: monospace; font-size: 0.85rem; color: var(--muted); }
  .bar-track {
    width: 100%;
    height: 10px;
    background: var(--sidebar-bg);
    border: 1px solid var(--border);
    border-radius: 999px;
    overflow: hidden;
  }
  .bar-fill {
    height: 100%;
    background: var(--accent);
    border-radius: 999px;
    min-width: 4px;
  }
  .top-tags { display: flex; flex-wrap: wrap; gap: 10px; margin: 16px 0 24px; }
  .top-tag {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 6px 12px;
    border: 1px solid var(--border);
    border-radius: 999px;
    background: var(--sidebar-bg);
    text-decoration: none;
    font-family: monospace;
    font-size: 0.86rem;
    color: var(--text) !important;
  }
  .top-tag:hover { border-color: var(--accent); color: var(--accent) !important; }
  .top-tag strong { color: var(--accent); }
</style>

<p class="stats-intro">Métricas generadas automáticamente a partir del contenido publicado en SecNotes y SecNews. No utiliza rastreadores externos ni bases de datos privadas.</p>

<div class="stats-grid">
  <div class="stat-card">
    <span class="stat-value">{{ total }}</span>
    <span class="stat-label">Artículos y writeups</span>
    <span class="stat-sub">{{ linux_posts }} Linux · {{ ms2_posts }} Hardening · {{ win_posts }} Windows</span>
  </div>
  <div class="stat-card">
    <span class="stat-value">{{ words }}</span>
    <span class="stat-label">Palabras escritas</span>
    <span class="stat-sub">~{{ reading_hours }} h de lectura ({{ reading_minutes }} min)</span>
  </div>
  <div class="stat-card">
    <span class="stat-value">{{ tag_groups | size }}</span>
    <span class="stat-label">Etiquetas únicas</span>
    <span class="stat-sub"><a href="{{ '/tags/' | relative_url }}">Explorar etiquetas →</a></span>
  </div>
  <div class="stat-card">
    <span class="stat-value">{{ total_news }}</span>
    <span class="stat-label">Noticias en SecNews</span>
    <span class="stat-sub">{{ valid_editions.size }} boletines · <a href="{{ '/noticias.html' | relative_url }}">Ver SecNews →</a></span>
  </div>
</div>

<div class="highlight-grid">
  {% if total > 0 %}
  <div class="highlight-card">
    <small>Último writeup publicado</small>
    <a href="{{ site.posts.first.url | relative_url }}">{{ site.posts.first.title | escape }}</a>
    <span class="highlight-meta">{{ site.posts.first.date | date: "%d/%m/%Y" }}</span>
  </div>
  {% endif %}
  {% if valid_editions.first %}
  <div class="highlight-card">
    <small>Última edición de SecNews</small>
    <a href="{{ '/noticias.html' | relative_url }}#{{ valid_editions.first.slug | escape }}">{{ valid_editions.first.title | escape }}</a>
    <span class="highlight-meta">{{ valid_editions.first.noticias.size }} noticias en esta edición</span>
  </div>
  {% endif %}
</div>

## Distribución por área

<div class="bar-list">
  {% if total > 0 %}
  <div class="bar-row">
    <div class="bar-head"><span><a href="{{ '/temas/linux/' | relative_url }}">Laboratorios Linux (Ofensivo)</a></span><span>{{ linux_posts }} ({{ linux_posts | times: 100 | divided_by: total }}%)</span></div>
    <div class="bar-track"><div class="bar-fill" style="width: {{ linux_posts | times: 100 | divided_by: total }}%"></div></div>
  </div>
  <div class="bar-row">
    <div class="bar-head"><span><a href="{{ '/metasploitable2' | relative_url }}">Hardening Metasploitable 2 (Defensivo / Blue Team)</a></span><span>{{ ms2_posts }} / 22 ({{ ms2_posts | times: 100 | divided_by: total }}%)</span></div>
    <div class="bar-track"><div class="bar-fill" style="width: {{ ms2_posts | times: 100 | divided_by: total }}%"></div></div>
  </div>
  <div class="bar-row">
    <div class="bar-head"><span><a href="{{ '/temas/windows/' | relative_url }}">Windows y Active Directory</a></span><span>{{ win_posts }} ({{ win_posts | times: 100 | divided_by: total }}%)</span></div>
    <div class="bar-track"><div class="bar-fill" style="width: {{ win_posts | times: 100 | divided_by: total }}%"></div></div>
  </div>
  {% endif %}
</div>

## Cobertura por plataforma

<div class="bar-list">
  {% if total > 0 %}
  {% assign platforms = "Metasploitable 2:" | append: ms2_posts | append: "|DockerLabs:" | append: plat_dockerlabs | append: "|TheHackerLabs:" | append: plat_thl | append: "|VulnHub:" | append: plat_vulnhub | append: "|TryHackMe:" | append: plat_thm | append: "|HackTheBox:" | append: plat_htb | append: "|CyberAcademy:" | append: plat_cyber | split: "|" %}
  {% for entry in platforms %}
    {% assign parts = entry | split: ":" %}
    {% assign pname = parts[0] %}
    {% assign pcount = parts[1] | plus: 0 %}
    {% if pcount > 0 %}
    <div class="bar-row">
      <div class="bar-head"><span><a href="{{ '/tags/' | relative_url }}#tag-{{ pname | downcase | slugify }}">{{ pname }}</a></span><span>{{ pcount }}</span></div>
      <div class="bar-track"><div class="bar-fill" style="width: {{ pcount | times: 100 | divided_by: total }}%"></div></div>
    </div>
    {% endif %}
  {% endfor %}
  {% endif %}
</div>

## Publicaciones por año

<div class="bar-list">
  {% if total > 0 %}
  {% for y in years %}
  <div class="bar-row">
    <div class="bar-head"><span>{{ y.name }}</span><span>{{ y.size }} artículos ({{ y.size | times: 100 | divided_by: total }}%)</span></div>
    <div class="bar-track"><div class="bar-fill" style="width: {{ y.size | times: 100 | divided_by: total }}%"></div></div>
  </div>
  {% endfor %}
  {% endif %}
</div>

## Etiquetas más usadas

<div class="top-tags">
  {% for g in tag_groups limit: 12 %}
  <a class="top-tag" href="{{ '/tags/' | relative_url }}#tag-{{ g.name | slugify }}">{{ g.items | first | escape }} <strong>{{ g.size }}</strong></a>
  {% endfor %}
</div>
