---
layout: post
title: Estadísticas
permalink: /stats/
---
{% assign total = site.posts | size %}
{% assign words = 0 %}
{% for p in site.posts %}{% assign w = p.content | number_of_words %}{% assign words = words | plus: w %}{% endfor %}
{% assign all_tags = "" | split: "" %}
{% for post in site.posts %}{% for t in post.tags %}{% assign all_tags = all_tags | push: t %}{% endfor %}{% endfor %}
{% assign tag_groups = all_tags | group_by_exp: "t", "t | downcase" | sort: "size" | reverse %}
{% assign years = site.posts | group_by_exp: "p", "p.date | date: '%Y'" %}

- **Writeups publicados:** {{ total }}
- **Palabras escritas:** {{ words }}
- **Tags distintos:** {{ tag_groups | size }}
- **Último post:** {% if total > 0 %}[{{ site.posts.first.title }}]({{ site.posts.first.url | relative_url }}) ({{ site.posts.first.date | date: "%d/%m/%Y" }}){% endif %}

## Posts por año
{% for y in years %}- {{ y.name }}: {{ y.size }}
{% endfor %}

## Tags más usados
{% for g in tag_groups limit: 10 %}- {{ g.items | first }}: {{ g.size }}
{% endfor %}
