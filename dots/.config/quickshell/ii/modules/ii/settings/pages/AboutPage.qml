pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.services
import "../rows/"
import "../../../components/"

// About page: version, system info, update check
ColumnLayout {
    id: page
    spacing: Appearance.sizes.spacing * 3

    readonly property string repoUrl: "https://github.com/ii/dots-hyprland"
    readonly property string dotsDir: Quickshell.env("HOME") + "/ii"

    property var info: ({})
    property var git: ({})
    property bool checking: false

    readonly property int behind: git.behind !== undefined && git.behind !== "" ? parseInt(git.behind) : -1
    readonly property int dirty: parseInt(git.dirty ?? "0")

    function parse(text: string): var {
        const result = {};
        for (const line of text.split("\n")) {
            const i = line.indexOf("=");
            if (i > 0)
                result[line.slice(0, i)] = line.slice(i + 1).trim();
        }
        return result;
    }

    function checkUpdates() {
        if (gitProc.running)
            return;
        checking = true;
        gitProc.running = true;
    }

    Component.onCompleted: {
        infoProc.running = true;
        checkUpdates();
    }

    Process {
        id: infoProc
        command: ["bash", "-c", `
            . /etc/os-release 2>/dev/null; echo "os=$PRETTY_NAME"
            echo "kernel=$(uname -r)"
            echo "host=$(cat /etc/hostname 2>/dev/null)"
            echo "model=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
            echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
            echo "gpu=$(lspci 2>/dev/null | grep -Ei 'vga|3d' | sed 's/.*: //' | paste -sd ';')"
            echo "memory=$(awk '/MemTotal/ {printf "%.1f GiB", $2/1048576}' /proc/meminfo)"
            echo "uptime=$(uptime -p | sed 's/^up //')"
            echo "packages=$(pacman -Qq 2>/dev/null | wc -l)"
            echo "hyprland=$(hyprctl version -j 2>/dev/null | jq -r .tag)"
            echo "quickshell=$(qs --version 2>/dev/null | head -1 | awk '{print $2}')"
        `]
        stdout: StdioCollector {
            onStreamFinished: root.info = root.parse(text)
        }
    }

    Process {
        id: gitProc
        command: ["bash", "-c", `
            cd "${root.dotsDir}" 2>/dev/null || exit 1
            echo "branch=$(git rev-parse --abbrev-ref HEAD)"
            echo "commit=$(git log -1 --format=%h)"
            echo "date=$(git log -1 --format=%cd --date=short)"
            echo "dirty=$(git status --porcelain | wc -l)"
            timeout 15 git fetch --quiet 2>/dev/null && echo "fetched=1"
            echo "behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                root.git = root.parse(text);
                root.checking = false;
            }
        }
    }

    // ================= HERO =================
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + Appearance.sizes.spacing * 4
        radius: Appearance.rounding.roundedLg
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: Appearance.sizes.spacing * 2
            spacing: Appearance.sizes.spacing * 2

            Rectangle {
                Layout.preferredWidth: Math.round(Appearance.font.pixelSize.iconLarge * 2)
                Layout.preferredHeight: Math.round(Appearance.font.pixelSize.iconLarge * 2)
                radius: Appearance.rounding.roundedLg
                color: Qt.alpha(Appearance.colors.colAccent, 0.15)

                Text {
                    anchors.centerIn: parent
                    text: "\u{e9ef}"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Appearance.font.pixelSize.iconLarge
                    color: Appearance.colors.colAccent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(Appearance.sizes.spacing / 3)

                Text {
                    Layout.fillWidth: true
                    text: "ii"
                    font.family: Appearance.font.family.title
                    font.pixelSize: Appearance.font.pixelSize.iconSmall
                    font.bold: true
                    color: Appearance.colors.colOnSurface
                }

                Text {
                    Layout.fillWidth: true
                    text: "dots-hyprland"
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSurfaceVariant
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.git.commit !== undefined
                    text: "\u{e250} " + root.git.branch + " · " + root.git.commit + " · " + root.git.date
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colAccent
                }
            }

            // GitHub button
            RippleButton {
                buttonIcon: "code"
                text: "GitHub"
                baseColor: Appearance.colors.colLayer1Hover
                onClicked: Qt.openUrlExternally(root.repoUrl)
            }
        }
    }

    // ================= VERSION INFO =================
    SettingsGroup {
        title: "Version"

        InfoRow {
            label: "Version"
            value: root.git.commit !== undefined ? root.git.branch + " @" + root.git.commit : "—"
        }

        InfoRow {
            label: "Update status"
            value: {
                if (root.checking) return "Checking…";
                if (root.git.fetched !== "1") return root.behind > 0 ? root.behind + " updates" : "Unknown";
                if (root.behind > 0) return root.behind + " update" + (root.behind === 1 ? "" : "s") + " available";
                return "Up to date";
            }
        }
    }

    // ================= SYSTEM INFO =================
    SettingsGroup {
        title: "System"

        InfoRow {
            label: "OS"
            value: root.info.os ?? "—"
        }

        InfoRow {
            label: "Kernel"
            value: root.info.kernel ?? "—"
        }

        InfoRow {
            label: "CPU"
            value: root.info.cpu ?? "—"
        }

        InfoRow {
            label: "GPU"
            value: (root.info.gpu ?? "").split(";").filter(g => g !== "").join(", ") || "—"
        }

        InfoRow {
            label: "Memory"
            value: root.info.memory ?? "—"
        }

        InfoRow {
            label: "Hyprland"
            value: root.info.hyprland ?? "—"
        }

        InfoRow {
            label: "Quickshell"
            value: root.info.quickshell ?? "—"
        }

        InfoRow {
            label: "Uptime"
            value: root.info.uptime ?? "—"
        }
    }

    // ================= UPDATE CHECK =================
    SettingsGroup {
        title: "Updates"

        SettingRow {
            label: "Check for updates"
            description: root.dirty > 0
                ? root.dirty + " uncommitted change" + (root.dirty === 1 ? "" : "s") + " in ~/ii"
                : "Pull latest dotfiles and run pending migrations"

            leading: Text {
                text: root.checking ? "\u{e863}" : "\u{e8a7}"
                font.family: "Material Symbols Rounded"
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnSurfaceVariant
            }

            trailing: RippleButton {
                buttonIcon: "sync"
                text: "Check"
                baseColor: page.controlColor
                onClicked: root.checkUpdates()
            }
        }
    }
}
