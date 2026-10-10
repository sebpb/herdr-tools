# herdr-tools

Plugin de [Herdr](https://herdr.dev) con algunas mejoras para trabajar con muchos chats:

- **Proyectos**: popup con tus proyectos, cada uno con sus propios workspaces y chats. Al cambiar de proyecto, el actual se suspende: se cierran sus terminales y, cuando volvés, se recuperan los workspaces y los chats de Claude retoman su conversación. Ver [Proyectos](#proyectos).
- **Workspaces numerados** en la barra lateral: `1. Self dev`, `2. Priorización`… El número se actualiza solo al crear, cerrar, renombrar o reordenar workspaces.
- **Chats del workspace activo**: popup con solo los chats del workspace actual; Enter salta al elegido. (Herdr ya no permite filtrar la barra lateral por workspace).
- **Mover chat a otro workspace**: popup con los demás workspaces; Enter manda el chat actual a una pestaña nueva de ese workspace sin reiniciarlo y te deja donde estás.
- **Atajos propios**: popup con los atajos de tu `config.toml`, primero los comandos propios y después las acciones de Herdr que personalizaste. Si tenés los chats agrupados (ver abajo), también lista los gestos del mouse. La ayuda completa de Herdr sigue en `prefix` y después `?`.

En los popups se filtra escribiendo, Enter confirma y Esc cierra.

## Requisitos

- Herdr 0.9.3 o más nuevo, en Linux o macOS.
- `jq`, `fzf` y `python3` (3.11 o más nuevo).

## Instalación

1. Instalar el plugin:

   ```bash
   herdr plugin install sebpb/herdr-tools
   ```

2. Agregar a tu `config.toml` (`herdr --help` muestra dónde está). Los atajos son una sugerencia: cambialos si ya usás esas teclas. Los bloques `[[keys.command]]` van después de tu sección `[keys]`, y `[ui.sidebar.spaces]` después de `[ui]`.

   ```toml
   [[keys.command]]
   key = "ctrl+alt+p"
   type = "plugin_action"
   command = "sebpb.herdr-tools.projects"
   description = "proyectos"

   [[keys.command]]
   key = "ctrl+alt+v"
   type = "plugin_action"
   command = "sebpb.herdr-tools.chats"
   description = "chats del workspace activo"

   [[keys.command]]
   key = "ctrl+alt+m"
   type = "plugin_action"
   command = "sebpb.herdr-tools.move-chat"
   description = "mover chat a otro workspace"

   [[keys.command]]
   key = "ctrl+alt+h"
   type = "plugin_action"
   command = "sebpb.herdr-tools.shortcuts"
   description = "atajos propios"

   # Workspaces numerados. Sin el plugin, las filas de workspace quedan sin nombre.
   [ui.sidebar.spaces]
   rows = [["state_icon", "$numbered"], ["branch", "git_status"]]
   ```

3. Aplicar los cambios:

   ```bash
   herdr config check
   herdr server reload-config
   herdr plugin action invoke sebpb.herdr-tools.number-workspaces
   ```

   El último comando numera los workspaces ahora; después el plugin lo hace solo, también cuando arranca el servidor.

## Proyectos

Cada proyecto es una [sesión de Herdr](https://herdr.dev/docs/concepts/#session): un servidor aparte con sus propios workspaces, pestañas y chats, guardados en disco. El proyecto de siempre es `default`.

Para cambiar de proyecto sin salir de Herdr, hay que abrirlo con el lanzador `herdr-proyectos` en lugar de `herdr`:

```bash
ln -s ~/Proyectos/herdr-tools/scripts/herdr-proyectos ~/.local/bin/herdr-proyectos
herdr-proyectos           # abre el último proyecto usado
herdr-proyectos trabajo   # o uno en particular
```

Si tu terminal abre `herdr` sola al iniciar, cambiá ese comando por `herdr-proyectos`.

En el popup (`ctrl+alt+p`):

- **Enter** cambia al proyecto elegido. `●` marca el actual y `○` los que siguen abiertos en otra ventana.
- Si escribís un nombre que no existe y das **Enter** (o **ctrl-n**, aunque coincida con otro), se crea un proyecto nuevo y se pide la carpeta donde arranca.
- **ctrl-x** borra el proyecto elegido con todo lo que tenga guardado. No se puede borrar el actual.

Al cambiar, el proyecto actual se suspende: Herdr guarda sus workspaces y cierra todas sus terminales. Los chats de Claude (y los demás agentes con retomado nativo) vuelven con su conversación al reabrir el proyecto. Todo lo demás vuelve como una shell vacía en la misma carpeta. Si hay algo que se perdería (un chat trabajando, un servidor de dev, tests corriendo), el popup lo lista y pide confirmación antes de cambiar.

El plugin también publica el nombre del proyecto como token `$project` en cada workspace, por si lo querés ver en la barra lateral:

```toml
[ui.sidebar.spaces]
rows = [["state_icon", "$numbered"], ["$project", "branch", "git_status"]]
```

Notas:

- Los nombres de sesión solo admiten letras, números, `.`, `_` y `-`: «Cliente Álamo» queda como `cliente-alamo`, pero el popup sigue mostrando el nombre que escribiste.
- Si abriste Herdr con `herdr` y no con el lanzador, cambiar de proyecto igual suspende el actual, pero Herdr se cierra y hay que abrir el otro a mano con `herdr --session <nombre>`. El popup avisa antes.
- Los comandos `herdr` que corras dentro de un pane apuntan siempre al proyecto de ese pane.

## Opcional: chats agrupados por workspace

Con el build de Herdr de [sebpb/herdr](https://github.com/sebpb/herdr/tree/projects) (rama `projects`), el panel de chats muestra un encabezado por workspace con sus chats debajo, en lugar de repetir el workspace en cada fila. Además:

- Arrastrar un chat lo reordena, o lo mueve a otro workspace soltándolo debajo de otro encabezado.
- Clic derecho en un chat abre el menú de su pestaña (nueva, renombrar, cerrar); en un encabezado, el del workspace.
- Clic en un encabezado («▾ Álamo») oculta o muestra sus chats; clic en el título de una sección («projects», «spaces», «agents») la minimiza.
- Sección **projects** arriba de «spaces»: un clic cambia de proyecto sin salir de Herdr (suspende el actual, avisando si se pierde algo), «new» crea uno y el clic derecho permite renombrarlo o borrarlo. Con este build no hacen falta el lanzador `herdr-proyectos` ni el popup de Proyectos.

Para compilarlo hace falta Rust y [Zig 0.16.0](https://ziglang.org/download/):

```bash
git clone -b projects https://github.com/sebpb/herdr.git
cd herdr
ZIG=/ruta/a/zig cargo build --release
cp target/release/herdr ~/.local/bin/herdr
```

Y en el `config.toml`, después de `[ui]`:

```toml
[ui.sidebar.agents]
group_by_space = true
rows = [["state_icon", "machine", "tab"]]
```

### Actualizar Herdr sin perder los cambios

`herdr update` reemplaza este build por el oficial. En su lugar, usá `scripts/update-herdr.sh`:

```bash
sh ~/Proyectos/herdr-tools/scripts/update-herdr.sh
```

El script:

1. Busca la última versión estable de Herdr y aplica encima los cambios de la rama. Si no aplican limpio, frena sin tocar nada y hay que adaptarlos a mano.
2. Compila, corre los tests del panel de chats e instala el binario. El anterior queda como `herdr.prev` al lado.
3. Sube la rama actualizada al fork.
4. Ofrece pasar el servidor al binario nuevo en vivo, sin cortar los chats (lo mismo que `herdr update --handoff`).

Si ya estás en la última versión no hace nada; `--force` recompila igual. Se configura con variables de entorno: `HERDR_FORK_DIR` (clon del fork, por defecto `~/Proyectos/herdr`), `HERDR_FORK_BRANCH`, `HERDR_FORK_REMOTE` (por defecto `fork`) y `ZIG` (por defecto, el Zig 0.16 de `~/.local/opt`).

Con el Herdr oficial, `group_by_space` se ignora y el plugin funciona igual.

## Actualizar o desinstalar

Para actualizar, volver a correr `herdr plugin install sebpb/herdr-tools`. Para desinstalar, `herdr plugin uninstall sebpb.herdr-tools` y sacar del `config.toml` los bloques de arriba (si no, los workspaces quedan sin nombre en la barra).

## Notas

- La ayuda de atajos traduce al español las acciones de Herdr conocidas; las que no conoce aparecen con su nombre interno.
- Si un chat era lo único en su workspace, al moverlo Herdr puede cerrar ese workspace.

## Licencia

MIT. Ver [LICENSE](LICENSE).
