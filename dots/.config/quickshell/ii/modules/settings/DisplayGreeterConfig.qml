import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    // ─── Helper: run a bash command and return stdout ───────────────────────
    function runBash(cmd) {
        let proc = null;
        let result = "";
        try {
            proc = new Process;
            proc.setProgram("bash");
            proc.setArguments(["-c", cmd]);
            proc.readyReadStandardOutput.connect(() => {
                result += proc.readAllStandardOutput();
            });
            proc.start();
            proc.waitForFinished(5000);
            result = proc.readAllStandardOutput();
            proc.close();
        } catch(e) {
            console.warn("[DisplayGreeterConfig] bash failed:", cmd, e);
        }
        return (result || "").trim();
    }

    // ─── Load available themes on start ─────────────────────────────────────
    Component.onCompleted: loadThemes()

    function loadThemes() {
        // Run `dots sddm use --list` to enumerate available themes
        let out = runBash("dots sddm use --list 2>/dev/null");
        if (!out) return;
        let lines = out.split("\n").filter(l => l.trim().length > 0);
        _themeOptions = lines.map(name => ({ displayName: name, value: name }));
        if (_themeOptions.length > 0 && _currentTheme === "") {
            // Lazy-load current theme from drop-in
            let dropin = runBash("cat /etc/sddm.conf.d/ii-theme.conf 2>/dev/null | grep '^Current=' | cut -d= -f2").trim();
            if (dropin) _currentTheme = dropin;
            else _currentTheme = _themeOptions[0].value;
        }
    }

    property var _themeOptions: []
    property string _currentTheme: ""
    property string _statusMsg: ""

    ContentSection {
        icon: "display_settings"
        title: Translation.tr("SDDM Greeter")

        ContentSubsection {
            title: Translation.tr("Theme")

            ColumnLayout {
                spacing: 8

                ConfigSelectionArray {
                    currentValue: _currentTheme
                    onSelected: newValue => {
                        _currentTheme = newValue;
                        let out = runBash("dots sddm use " + newValue + " 2>&1");
                        _statusMsg = out ? out.split("\n")[0] : "";
                    }
                    options: _themeOptions
                }

                Label {
                    Layout.fillWidth: true
                    text: _statusMsg
                    color: _statusMsg.indexOf("[sddm]") === 0 ? "#4caf50" : "#ff9800"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    visible: _statusMsg !== ""
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Actions")

            RowLayout {
                spacing: 8

                StyledButton {
                    label: Translation.tr("Verify")
                    onClicked: {
                        let out = runBash("dots sddm verify 2>&1");
                        _statusMsg = out;
                    }
                }

                StyledButton {
                    label: Translation.tr("Reset")
                    onClicked: {
                        let out = runBash("dots sddm reset 2>&1");
                        _statusMsg = out ? out.split("\n")[0] : "";
                        _currentTheme = "";
                        loadThemes();
                    }
                }
            }
        }
    }
}
