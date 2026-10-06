# herdr-tools

Plugin de [Herdr](https://herdr.dev) con algunas mejoras para trabajar con muchos chats:

- **Workspaces numerados** en la barra lateral: `1. Self dev`, `2. Priorización`… El número se actualiza solo al crear, cerrar, renombrar o reordenar workspaces.
- **Chats del workspace activo**: popup con solo los chats del workspace actual; Enter salta al elegido. (Herdr ya no permite filtrar la barra lateral por workspace).
- **Mover chat a otro workspace**: popup con los demás workspaces; Enter manda el chat actual a una pestaña nueva de ese workspace sin reiniciarlo y te deja donde estás.
- **Atajos propios**: popup con los atajos de tu `config.toml`, primero los comandos propios y después las acciones de Herdr que personalizaste. La ayuda completa de Herdr sigue en `prefix` y después `?`.

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

## Actualizar o desinstalar

Para actualizar, volver a correr `herdr plugin install sebpb/herdr-tools`. Para desinstalar, `herdr plugin uninstall sebpb.herdr-tools` y sacar del `config.toml` los bloques de arriba (si no, los workspaces quedan sin nombre en la barra).

## Notas

- La ayuda de atajos traduce al español las acciones de Herdr conocidas; las que no conoce aparecen con su nombre interno.
- Si un chat era lo único en su workspace, al moverlo Herdr puede cerrar ese workspace.

## Licencia

MIT. Ver [LICENSE](LICENSE).
