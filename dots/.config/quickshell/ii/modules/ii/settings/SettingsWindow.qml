pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.ii.settings
import "./pages/"
import "../../components/"

// Floating settings window with sidebar navigation and page loader.
// Opens on Super+I, closes on Escape.
FloatingWindow {
    id: root

    readonly property int sidebarWidth: Math.round(Appearance.font.pixelSize.normal * 16)
    readonly property int maxContentWidth: Math.round(Appearance.font.pixelSize.normal * 48)
    readonly property int boxSize: Math.round(Appearance.font.pixelSize.iconSmall * 2)
    readonly property int pageGutter: Appearance.sizes.spacing * 2
    readonly property size defaultSize: Qt.size(960, 680)

    // Page id -> component mapping
    readonly property var pageComponents: ({
            appearance: appearancePage,
            background: backgroundPage,
            bar: barPage,
            workspaces: workspacesPage,
            lock: lockPage,
            sidebar: sidebarPage,
            quickSettings: quickSettingsPage,
            notifications: notificationsPage,
            about: aboutPage
        })

    visible: SettingsService.visible
    onVisibleChanged: {
        if (visible) {
            SettingsService.buildIndex();
            showPage();
        }
    }

    color: "transparent"

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggle settings window"

        onPressed: SettingsService.toggle()
    }

    // Scrolls sidebar so nav item is visible
    function showNavItem(item: Item) {
        const y = item.mapToItem(navColumn, 0, 0).y;
        const headroom = Appearance.font.pixelSize.small * 2 + Appearance.sizes.spacing;
        if (y - headroom < navFlick.contentY)
            navFlick.contentY = Math.max(0, y - headroom);
        else if (y + item.height > navFlick.contentY + navFlick.height)
            navFlick.contentY = y + item.height - navFlick.height;
    }

    property bool _onB: false
    readonly property Loader pageLoader: _onB ? slotB : slotA
    property int _direction: 1
    property int _pageIndex: -1

    function showPage() {
        const id = SettingsService.currentEntry.id;
        const index = SettingsService.pageOrder.indexOf(id);
        _direction = index >= _pageIndex ? 1 : -1;
        const first = _pageIndex < 0;
        _pageIndex = index;
        const old = pageLoader;
        if (!first) {
            exitAnim.stop();
            old.y -= flick.contentY;
            exitAnim.slot = old;
            exitAnim.toY = old.y - _direction * Appearance.sizes.spacing * 3;
            _onB = !_onB;
        }
        scrollAnim.stop();
        flick.contentY = 0;
        pageLoader.sourceComponent = null;
        pageLoader.y = 0;
        pageLoader.opacity = 0;
        pageLoader.sourceComponent = pageComponents[id];
        if (!first)
            exitAnim.start();
    }

    function pageLoaded(slot: Loader) {
        if (slot !== pageLoader)
            return;
        enterAnim.restart();
        if (SettingsService.pendingReveal)
            revealTimer.restart();
    }

    function clearSlot(slot: Loader) {
        if (slot === pageLoader)
            return;
        slot.sourceComponent = null;
        slot.y = 0;
        slot.opacity = 1;
    }

    onClosing: SettingsService.visible = false

    Component.onCompleted: {
        if (visible)
            showPage();
    }

    property var _flashRows: []

    function revealPending() {
        const r = SettingsService.pendingReveal;
        SettingsService.pendingReveal = null;
        if (!r || !root.pageLoader.item || r.page !== SettingsService.currentPage)
            return;
        const rows = [];
        const groups = [];
        const walk = item => {
            for (const c of item.children) {
                if (!c.visible)
                    continue;
                if (c.isSettingRow === true)
                    rows.push(c);
                else if (c._visibleRows !== undefined)
                    groups.push(c);
                walk(c);
            }
        };
        walk(root.pageLoader.item);
        const groupTitle = item => {
            for (let p = item.parent; p; p = p.parent) {
                if (p._visibleRows !== undefined)
                    return p.title;
            }
            return "";
        };
        let anchor = null;
        let flash = [];
        if (r.label !== "") {
            const matches = rows.filter(x => x.label === r.label);
            const row = matches.find(x => groupTitle(x) === r.group) ?? matches[0];
            if (row) {
                anchor = row;
                flash = [row];
            }
        }
        if (!anchor && r.group !== "") {
            const group = groups.find(x => x.title === r.group);
            if (group) {
                anchor = group;
                flash = group._visibleRows;
            }
        }
        if (!anchor)
            return;
        const y = anchor.mapToItem(root.pageLoader, 0, 0).y;
        const target = Math.max(0, Math.min(flick.contentHeight - flick.height, y - Appearance.sizes.spacing * 4));
        _flashRows = flash;
        if (Math.abs(target - flick.contentY) < 1) {
            flashPending();
        } else {
            scrollAnim.to = target;
            scrollAnim.restart();
        }
    }

    function flashPending() {
        _flashRows.forEach(row => row.flash());
        _flashRows = [];
    }

    Timer {
        id: revealTimer
        interval: Appearance.animation.duration
        onTriggered: root.revealPending()
    }

    Connections {
        target: SettingsService

        function onRevealRequested() {
            revealTimer.restart();
        }

        function onCurrentPageChanged() {
            root.showPage();
        }
    }

    // ================= LAYOUT =================

    Rectangle {
        anchors.fill: parent
        color: Appearance.m3colors.m3surfaceContainerLow
        radius: Appearance.rounding.windowRounding
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        // ========== SIDEBAR ==========
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: root.sidebarWidth
            color: Appearance.colors.colLayer0
            radius: Appearance.rounding.roundedMd

            Flickable {
                id: navFlick
                anchors.fill: parent
                anchors.margins: Appearance.sizes.spacing
                contentHeight: navColumn.height
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: navColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    // ii logo / title
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: Appearance.sizes.spacing * 2
                        spacing: Appearance.sizes.spacing

                        Rectangle {
                            Layout.preferredWidth: root.boxSize
                            Layout.preferredHeight: root.boxSize
                            radius: Appearance.rounding.roundedMd
                            color: Appearance.colors.colAccent

                            Text {
                                anchors.centerIn: parent
                                text: "\u{e9ef}"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: Appearance.font.pixelSize.large
                                color: Appearance.colors.colOnAccent
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "ii"
                                font.family: Appearance.font.family.title
                                font.pixelSize: Appearance.font.pixelSize.larger
                                font.bold: true
                                color: Appearance.colors.colOnSurface
                            }

                            Text {
                                text: "Settings"
                                font.family: Appearance.font.family
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }

                    // Category pages
                    Repeater {
                        model: SettingsService.categories

                        delegate: ColumnLayout {
                            id: categoryColumn
                            Layout.fillWidth: true
                            spacing: 0
                            property string categoryName: modelData

                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: Appearance.sizes.spacing
                                Layout.bottomMargin: Appearance.sizes.spacing / 2
                                text: categoryName.toUpperCase()
                                font.family: Appearance.font.family
                                font.pixelSize: Appearance.font.pixelSize.smallest
                                font.bold: true
                                font.letterSpacing: 1
                                color: Appearance.colors.colAccent
                            }

                            Repeater {
                                model: SettingsService.pages.filter(p => p.category === categoryName)

                                delegate: Item {
                                    id: navItem
                                    required property var modelData
                                    property bool isCurrentPage: SettingsService.currentPage === modelData.id
                                    property var pageInfo: modelData

                                    Layout.fillWidth: true
                                    implicitHeight: navItemRow.implicitHeight + Appearance.sizes.spacing

                                    Rectangle {
                                        id: navItemBg
                                        anchors.fill: parent
                                        radius: Appearance.rounding.roundedSm
                                        color: navItemBgMouse.containsMouse ? Appearance.colors.colLayer1Hover
                                            : isCurrentPage ? Qt.alpha(Appearance.colors.colAccent, 0.12) : "transparent"

                                        RowLayout {
                                            id: navItemRow
                                            anchors.fill: parent
                                            anchors.margins: Appearance.sizes.spacing
                                            spacing: Appearance.sizes.spacing

                                            Text {
                                                Layout.preferredWidth: root.boxSize
                                                Layout.preferredHeight: root.boxSize
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                text: pageInfo.icon
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                color: isCurrentPage ? Appearance.colors.colAccent : Appearance.colors.colOnSurfaceVariant
                                            }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                Text {
                                                    text: pageInfo.label
                                                    font.family: Appearance.font.family
                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                    font.bold: isCurrentPage
                                                    color: isCurrentPage ? Appearance.colors.colAccent : Appearance.colors.colOnSurface
                                                }

                                                Text {
                                                    visible: false
                                                    text: pageInfo.description
                                                    font.family: Appearance.font.family
                                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                                    color: Appearance.colors.colOnSurfaceVariant
                                                    wrapMode: Text.WordWrap
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: navItemBgMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                SettingsService.currentPage = modelData.id;
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Appearance.sizes.spacing
                            }
                        }
                    }
                }
            }
        }

        // ========== CONTENT ==========
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.m3colors.m3surfaceContainerLowest
            radius: Appearance.rounding.roundedMd

            clip: true

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: pageGutter
                contentWidth: width
                contentHeight: Math.max(pageLoader.y + pageLoader.height + pageGutter * 2, flick.height)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    size: 0.15
                }

                // Search bar at top
                Rectangle {
                    id: searchBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: searchRow.implicitHeight + Appearance.sizes.spacing * 2
                    color: Appearance.colors.colLayer1Hover
                    radius: Appearance.rounding.roundedMd
                    visible: searchField.text !== ""

                    RowLayout {
                        id: searchRow
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.sizes.spacing * 2
                        anchors.rightMargin: Appearance.sizes.spacing * 2
                        spacing: Appearance.sizes.spacing

                        Text {
                            text: "\u{e8b6}"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurfaceVariant
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search settings…"
                            font.family: Appearance.font.family
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnSurface
                            selectByMouse: true
                            cursorVisible: activeFocus
                            activeFocusOnPress: false
                            onTextChanged: {
                                if (text.length > 0)
                                    searchResults.visible = true;
                                else
                                    searchResults.visible = false;
                            }
                            onAccepted: {
                                if (searchResults.visible)
                                    searchResults.activateCurrent();
                            }
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Down) {
                                    searchResults.move(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Up) {
                                    searchResults.move(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    text = "";
                                    searchResults.visible = false;
                                    focus = false;
                                }
                            }
                        }
                    }

                    SearchResults {
                        id: searchResults
                        anchors.top: searchBar.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 2
                        height: 300
                        visible: false
                        query: searchField.text

                        onActivated: {
                            searchField.text = "";
                            searchResults.visible = false;
                        }
                    }
                }

                // Page slots (double-buffered for transitions)
                Loader {
                    id: slotA
                    y: flick.contentY
                    opacity: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    onLoaded: root.pageLoaded(slotA)
                }

                Loader {
                    id: slotB
                    y: flick.contentY
                    opacity: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    clip: true
                    onLoaded: root.pageLoaded(slotB)
                }
            }

            // Page enter animation
            NumberAnimation {
                id: enterAnim
                target: pageLoader
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animation.duration
                easing.type: Easing.OutQuad
            }

            // Page exit animation
            ParallelAnimation {
                id: exitAnim
                property Loader slot
                property real toY: 0

                NumberAnimation {
                    target: exitAnim.slot
                    property: "opacity"
                    to: 0
                    duration: Appearance.animation.durationShort
                    easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: exitAnim.slot
                    property: "y"
                    to: exitAnim.toY
                    duration: Appearance.animation.durationMedium
                    easing.type: Easing.InOutQuad
                }
            }

            // Scroll animation
            NumberAnimation {
                id: scrollAnim
                target: flick
                property: "contentY"
                duration: Appearance.animation.duration
                easing.type: Easing.OutQuad
            }
        }
    }

    // ================= PAGE COMPONENTS =================

    Component {
        id: appearancePage
        AppearancePage {}
    }

    Component {
        id: backgroundPage
        BackgroundPage {}
    }

    Component {
        id: barPage
        BarPage {}
    }

    Component {
        id: workspacesPage
        WorkspacesPage {}
    }

    Component {
        id: lockPage
        LockPage {}
    }

    Component {
        id: sidebarPage
        SidebarPage {}
    }

    Component {
        id: quickSettingsPage
        QuickSettingsPage {}
    }

    Component {
        id: notificationsPage
        NotificationsPage {}
    }

    Component {
        id: aboutPage
        AboutPage {}
    }
}
