import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    IpcHandler {
        target: "debug"

        function activeWindow(): string {
            const toplevel = ToplevelManager.activeToplevel;
            if (!toplevel)
                return "null";
            return JSON.stringify({
                title: toplevel.title,
                appId: toplevel.appId
            });
        }

        function toplevels(): string {
            return Hyprland.toplevels.values.map(t => `${t.address}:${t.activated}:${t.title}`).join(" | ");
        }

        function activatedToplevel(): string {
            const toplevel = Hyprland.toplevels.values.find(t => t.activated);
            return toplevel ? toplevel.title : "none";
        }

        function managerToplevel(): string {
            const toplevel = ToplevelManager.activeToplevel;
            return toplevel ? toplevel.title : "null";
        }

        function workspaces(): string {
            return Hyprland.workspaces.values.map(ws => `${ws.id}:${ws.name}:active=${ws.active}`).join(" ");
        }
    }
}
