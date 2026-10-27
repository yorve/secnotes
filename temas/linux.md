---
layout: post
title: "Pentesting en Linux — Laboratorios y escalada de privilegios"
description: "Writeups de pentesting en Linux: reconocimiento de servicios, enumeración, permisos SUID, escalada de privilegios y contenedores."
permalink: /temas/linux/
topic: linux
---

## Qué encontrarás

Resoluciones de máquinas Linux de distintas plataformas. La colección permite seguir una cadena de trabajo desde el reconocimiento de servicios hasta la revisión de permisos y la escalada de privilegios.

## Qué conviene repasar

Usuarios y grupos, permisos de archivos, procesos, servicios y tareas programadas. Cuando encuentres un binario SUID o una configuración especial, investiga qué privilegio concede y bajo qué condiciones se puede abusar de él.

Documenta tanto el acceso inicial como la causa de la escalada. Completa la práctica con la [serie de hardening de Metasploitable 2]({{ "/metasploitable2" | relative_url }}) para conectar los hallazgos con su corrección.

{% include topic-posts.html %}
