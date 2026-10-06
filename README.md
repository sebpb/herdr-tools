# herdr-tools

Plugin de [Herdr](https://herdr.dev) con algunas mejoras para trabajar con muchos chats:

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

## Opcional: chats agrupados por workspace

Con el build de Herdr de [sebpb/herdr](https://github.com/sebpb/herdr/tree/group-agents-by-space) (rama `group-agents-by-space`), el panel de chats muestra un encabezado por workspace con sus chats debajo, en lugar de repetir el workspace en cada fila. Además:

- Arrastrar un chat lo reordena, o lo mueve a otro workspace soltándolo debajo de otro encabezado.
- Clic derecho en un chat abre el menú de su pestaña (nueva, renombrar, cerrar); en un encabezado, el del workspace.

Para compilarlo hace falta Rust y [Zig 0.16.0](https://ziglang.org/download/):

```bash
git clone -b group-agents-by-space https://github.com/sebpb/herdr.git
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
