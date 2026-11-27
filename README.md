# SecNotes

<p align="center">
  <a href="https://yorve.github.io/secnotes/">
    <img src="./SecNotes.png" alt="Logotipo de SecNotes" width="120">
  </a>
</p>

SecNotes es mi bitácora de ciberseguridad en español. Aquí documento cómo resuelvo laboratorios de pentesting, analizo eventos de seguridad y corrijo configuraciones vulnerables. El blog reúne writeups, guías paso a paso y referencias para practicar en laboratorio.

**[Visitar SecNotes](https://yorve.github.io/secnotes/)**

## Explora el blog

| Sección | Qué encontrarás |
| --- | --- |
| [Empieza aquí](https://yorve.github.io/secnotes/empieza-aqui/) | Una ruta para preparar tu laboratorio, seguir un writeup y conectar lo aprendido con la defensa. |
| [Artículos](https://yorve.github.io/secnotes/articulos/) | El índice de writeups y guías. En la portada puedes buscar y filtrar por técnica, etiqueta o sistema. |
| [Hardening de Metasploitable 2](https://yorve.github.io/secnotes/metasploitable2) | Una serie dedicada a identificar configuraciones vulnerables y corregirlas servicio por servicio. |
| [Cheatsheet](https://yorve.github.io/secnotes/cheatsheet) | Una referencia rápida de comandos de reconocimiento, enumeración y escalada de privilegios para laboratorios. |
| [Noticias de IA](https://yorve.github.io/secnotes/noticias.html) | Boletines en español sobre modelos, herramientas, investigación y regulación, con enlaces a las fuentes originales. |

Puedes explorar los artículos por [pentesting web](https://yorve.github.io/secnotes/temas/pentesting-web/), [laboratorios Linux](https://yorve.github.io/secnotes/temas/linux/), [Windows y Active Directory](https://yorve.github.io/secnotes/temas/windows/) o [etiquetas](https://yorve.github.io/secnotes/tags). Los writeups incluyen laboratorios de DockerLabs, TheHackerLabs, TryHackMe y Hack The Box.

También puedes seguir las publicaciones por [RSS](https://yorve.github.io/secnotes/feed.xml), consultar el proyecto [Auto-Recon](https://github.com/yorve/Auto_Recon) o conocer más sobre [Yorve](https://yorve.github.io/secnotes/about).

## Publicación y mantenimiento

El sitio usa Jekyll y se publica con GitHub Pages. Los artículos se guardan en `_posts/` y los boletines aprobados en `_boletines/`.

El flujo [Borrador de noticias de IA](https://github.com/yorve/secnotes/actions/workflows/ai-news.yml) consulta fuentes RSS los martes y viernes a las 09:17, hora de Santiago. También se puede iniciar con **Run workflow**. El secreto `OPENAI_API_KEY` permite redactar los resúmenes en español. Cuando hay novedades, la ejecución guarda el Markdown en el artefacto `borrador-noticias-ia`.

Para publicar una edición, descarga el borrador, comprueba los resúmenes y sus fuentes, y guarda el archivo aprobado en `_boletines/` con su nombre fechado. Si ya hay un boletín de esa fecha, incorpora las novedades a la edición existente.
