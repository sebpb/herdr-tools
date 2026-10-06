#!/usr/bin/env python3
"""Lista los atajos propios de Herdr leyendo config.toml: comandos propios primero,
despues las acciones de Herdr con atajos personalizados."""

import sys
import tomllib
from pathlib import Path

ACCIONES = {
    "help": "Ayuda completa de Herdr",
    "settings": "Abrir configuración",
    "new_workspace": "Nuevo workspace",
    "new_worktree": "Crear worktree de Git",
    "open_worktree": "Abrir worktree de Git existente",
    "remove_worktree": "Borrar worktree de Git",
    "rename_workspace": "Renombrar workspace",
    "close_workspace": "Cerrar workspace",
    "workspace_picker": "Navegar workspaces",
    "goto": "Navegador de sesión",
    "navigate_workspace_up": "Modo navegar: workspace de arriba",
    "navigate_workspace_down": "Modo navegar: workspace de abajo",
    "navigate_pane_left": "Modo navegar: pane de la izquierda",
    "navigate_pane_down": "Modo navegar: pane de abajo",
    "navigate_pane_up": "Modo navegar: pane de arriba",
    "navigate_pane_right": "Modo navegar: pane de la derecha",
    "detach": "Desconectarse de Herdr",
    "reload_config": "Recargar config.toml",
    "open_notification_target": "Ir a la notificación visible",
    "previous_workspace": "Workspace anterior",
    "next_workspace": "Workspace siguiente",
    "previous_agent": "Agente anterior",
    "next_agent": "Agente siguiente",
    "focus_agent": "Elegir agente de la barra lateral",
    "remote_image_paste": "Pegar imagen en sesión remota",
    "new_tab": "Nueva pestaña",
    "rename_tab": "Renombrar pestaña",
    "previous_tab": "Pestaña anterior",
    "next_tab": "Pestaña siguiente",
    "move_tab_previous": "Mover pestaña hacia adelante",
    "move_tab_next": "Mover pestaña hacia atrás",
    "switch_tab": "Elegir pestaña",
    "switch_workspace": "Elegir workspace",
    "close_tab": "Cerrar pestaña",
    "rename_pane": "Renombrar pane",
    "edit_scrollback": "Abrir historial del pane en $EDITOR",
    "clear_pane": "Limpiar pane",
    "copy_mode": "Modo copia",
    "focus_pane_left": "Pane de la izquierda",
    "focus_pane_down": "Pane de abajo",
    "focus_pane_up": "Pane de arriba",
    "focus_pane_right": "Pane de la derecha",
    "swap_pane_left": "Intercambiar con el pane de la izquierda",
    "swap_pane_down": "Intercambiar con el pane de abajo",
    "swap_pane_up": "Intercambiar con el pane de arriba",
    "swap_pane_right": "Intercambiar con el pane de la derecha",
    "cycle_pane_next": "Pane siguiente",
    "cycle_pane_previous": "Pane anterior",
    "last_pane": "Último pane usado",
    "split_vertical": "Dividir pane al costado",
    "split_horizontal": "Dividir pane abajo",
    "close_pane": "Cerrar pane",
    "zoom": "Zoom del pane",
    "fullscreen": "Zoom del pane",
    "resize_mode": "Modo redimensionar",
    "resize_pane_left": "Agrandar pane hacia la izquierda",
    "resize_pane_down": "Agrandar pane hacia abajo",
    "resize_pane_up": "Agrandar pane hacia arriba",
    "resize_pane_right": "Agrandar pane hacia la derecha",
    "toggle_sidebar": "Mostrar u ocultar la barra lateral",
}

INDEXADOS = {
    "tabs": "Elegir pestaña",
    "workspaces": "Elegir workspace",
    "agents": "Elegir agente de la barra lateral",
}

FLECHAS = {"left": "←", "right": "→", "up": "↑", "down": "↓"}


def atajo(texto):
    partes = texto.split("+")
    return "+".join(p if p == "prefix" else FLECHAS.get(p, p[:1].upper() + p[1:]) for p in partes)


def atajos(valor):
    valores = valor if isinstance(valor, list) else [valor]
    return "  ·  ".join(atajo(v) for v in valores)


def main():
    keys = tomllib.loads(Path(sys.argv[1]).read_text()).get("keys", {})
    filas = []
    for cmd in keys.get("command", []):
        descripcion = cmd.get("description") or cmd.get("command", "").strip().splitlines()[0]
        filas.append(("Comandos propios", atajos(cmd["key"]), descripcion))
    for accion, valor in keys.items():
        if accion in ("command", "prefix", "extra_prefixes"):
            continue
        if accion == "indexed" and isinstance(valor, dict):
            for grupo, modificador in valor.items():
                filas.append(("Atajos personalizados", atajo(modificador) + "+1..9", INDEXADOS.get(grupo, grupo)))
            continue
        filas.append(("Atajos personalizados", atajos(valor), ACCIONES.get(accion, accion)))

    if not filas:
        print("No hay atajos propios en", sys.argv[1])
    else:
        ancho = max(len(f[1]) for f in filas)
        seccion = None
        for nombre, teclas, descripcion in filas:
            if nombre != seccion:
                if seccion:
                    print()
                print(f"── {nombre} ──")
                seccion = nombre
            print(f"  {teclas.ljust(ancho)}   {descripcion}")
    prefix = atajos(keys.get("prefix", "ctrl+b"))
    print(f"\nTodos los atajos de Herdr: {prefix} y después ?")


if __name__ == "__main__":
    main()
