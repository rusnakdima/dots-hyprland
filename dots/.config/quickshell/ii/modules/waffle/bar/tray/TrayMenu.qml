pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar

PopupWindow {
    id: root
    required property SystemTrayItem item
    property bool menuOpen: root.visible

    closeOnFocusLost: true
    onFocusCleared: root.close()

    color: "transparent"
    property real padding: Looks.radius.medium
    property real menuRadius: Looks.radius.large
    property real itemHeight: 36
    property real horizontalPadding: 12
    property real iconColumnWidth: 20
    property real interactionColumnWidth: 20
    property real chevronColumnWidth: 20

    function open() {
        root.visible = true;
    }

    function close() {
        root.visible = false;
        stackView.pop(null);
    }

    implicitWidth: realContent.implicitWidth + padding * 2
    implicitHeight: realContent.implicitHeight + padding * 2

    property real sourceEdgeMargin: -implicitHeight
    PropertyAnimation {
        id: openAnim
        target: root
        property: "sourceEdgeMargin"
        to: root.padding
        duration: 200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }
    SequentialAnimation {
        id: closeAnim
        PropertyAnimation {
            target: root
            property: "sourceEdgeMargin"
            to: -implicitHeight
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Looks.transition.easing.bezierCurve.easeOut
        }
        ScriptAction {
            script: {
                root.visible = false;
            }
        }
    }

    Component.onCompleted: {
        root.visible = true;
    }

    layer.enabled: true
    layer.effect: WAmbientShadow {
        target: realContent
    }

    Rectangle {
        id: realContent
        z: 1
        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.waffles.bar.bottom ? undefined : parent.top
            bottom: Config.options.waffles.bar.bottom ? parent.bottom : undefined
            margins: root.padding
            bottomMargin: Config.options.waffles.bar.bottom ? root.sourceEdgeMargin : root.padding
            topMargin: Config.options.waffles.bar.bottom ? root.padding : root.sourceEdgeMargin
        }
        color: Looks.colors.bg1Base
        radius: menuRadius

        implicitWidth: stackView.implicitWidth + horizontalPadding * 2
        implicitHeight: stackView.implicitHeight + horizontalPadding * 2

        StackView {
            id: stackView
            anchors {
                fill: parent
                margins: horizontalPadding
            }
            pushEnter: NoAnim {}
            pushExit: NoAnim {}
            popEnter: NoAnim {}
            popExit: NoAnim {}

            initialItem: MenuPage {
                id: rootPage
                menuChildren: root.item.menu.children
                isRootMenu: true
                onSubmenuRequested: (handle) => {
                    stackView.push(subMenuPageComponent.createObject(null, {
                        menuChildren: handle.children,
                        isRootMenu: false
                    }));
                }
            }
        }
    }

    Component {
        id: subMenuPageComponent
        MenuPage {}
    }

    component NoAnim: Transition {
        NumberAnimation {
            duration: 0
        }
    }

    component MenuPage: ColumnLayout {
        id: menuPage
        required property var menuChildren
        property bool isRootMenu: false
        property int depth: isRootMenu ? 0 : (stackView.depth)

        spacing: 0

        Component.onCompleted: {
            if (needsIconColumn || needsInteractionColumn || needsChevronColumn) {
                // Force layout update
            }
        }

        readonly property bool needsIconColumn: {
            for (let i = 0; i < menuChildren.length; i++) {
                if (menuChildren[i].icon && menuChildren[i].icon.length > 0)
                    return true;
            }
            return false;
        }

                readonly property bool needsInteractionColumn: {
            for (let i = 0; i < menuChildren.length; i++) {
                if (menuChildren[i].buttonType !== undefined && menuChildren[i].buttonType !== QsMenuButtonType.None)
                    return true;
            }
            return false;
        }

        readonly property bool needsChevronColumn: {
            for (let i = 0; i < menuChildren.length; i++) {
                if (menuChildren[i].hasChildren)
                    return true;
            }
            return false;
        }

        implicitWidth: contentColumn.implicitWidth
        implicitHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn
            spacing: 0

            // Back button for submenus
            Loader {
                Layout.fillWidth: true
                active: !isRootMenu
                visible: active
                sourceComponent: RippleButton {
                    id: backButtonRipple
                    buttonRadius: menuRadius - root.padding
                    horizontalPadding: root.horizontalPadding
                    implicitWidth: backButtonContentWidth + horizontalPadding * 2
                    implicitHeight: root.itemHeight

                    property real backButtonContentWidth: 20 + 8 + 60 // chevron + spacing + text approx

                    downAction: () => stackView.pop()

                    contentItem: RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: backButtonRipple.horizontalPadding
                            rightMargin: backButtonRipple.horizontalPadding
                        }
                        spacing: 8
                        MaterialSymbol {
                            iconSize: 20
                            text: "chevron_left"
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Back")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                        }
                    }
                }
            }

            // Pin button for root menu
            Loader {
                Layout.fillWidth: true
                active: isRootMenu && root.item.id && root.item.id.length > 0
                visible: active
                sourceComponent: RippleButton {
                    id: pinButtonRipple
                    buttonRadius: menuRadius - root.padding
                    horizontalPadding: root.horizontalPadding
                    implicitWidth: pinButtonContentWidth + horizontalPadding * 2
                    implicitHeight: root.itemHeight

                    property real pinButtonContentWidth: 20 + 8 + 50 // icon + spacing + text approx

                    releaseAction: () => TrayService.togglePin(root.item.id)

                    contentItem: RowLayout {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: pinButtonRipple.horizontalPadding
                            rightMargin: pinButtonRipple.horizontalPadding
                        }
                        spacing: 8
                        MaterialSymbol {
                            iconSize: 18
                            text: "push_pin"
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: TrayService.isPinned(root.item.id) ? Translation.tr("Unpin") : Translation.tr("Pin")
                            font.pixelSize: Appearance.font.pixelSize.smallie
                        }
                    }
                }
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Looks.colors.subfg
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                visible: (isRootMenu && root.item.id && root.item.id.length > 0) || !isRootMenu
            }

            // Menu items
            Repeater {
                model: menuChildren
                delegate: MenuItem {
                    required property var modelData
                    menuEntry: modelData
                }
            }
        }
    }

    component MenuItem: Loader {
        id: menuItem
        required property var menuEntry

        readonly property bool isSeparator: menuEntry.isSeparator
        readonly property bool hasIcon: menuEntry.icon && menuEntry.icon.length > 0
        readonly property bool hasInteraction: menuEntry.buttonType !== undefined && menuEntry.buttonType !== QsMenuButtonType.None
        readonly property bool hasChevron: menuEntry.hasChildren

        Layout.fillWidth: true
        active: !isSeparator
        visible: !isSeparator

        sourceComponent: RippleButton {
            id: rippleButton
            buttonRadius: menuRadius - root.padding
            horizontalPadding: root.horizontalPadding
            implicitWidth: implicitContentWidth + horizontalPadding * 2
            implicitHeight: root.itemHeight
            
            property real implicitContentWidth: {
                let w = 0;
                // interaction column
                if (hasInteraction || menuPage.needsInteractionColumn) w += root.interactionColumnWidth + 8;
                // icon column
                if (hasIcon || menuPage.needsIconColumn) w += root.iconColumnWidth + 8;
                // label
                w += labelMetrics.width;
                // chevron column
                if (hasChevron || menuPage.needsChevronColumn) w += root.chevronColumnWidth + 8;
                return w;
            }
            
            Text {
                id: labelMetrics
                text: menuEntry.text
                font.pixelSize: Appearance.font.pixelSize.smallie
                visible: false
            }

            colBackground: ColorUtils.transparentize(Looks.colors.bg1Base)
            colBackgroundHover: Looks.colors.bg1Hover
            colBackgroundActive: Looks.colors.bg1Active

            releaseAction: () => {
                if (menuEntry.hasChildren) {
                    // Open submenu
                    stackView.push(subMenuPageComponent.createObject(null, {
                        menuChildren: menuEntry.children,
                        isRootMenu: false
                    }));
                    return;
                }
                if (menuEntry.triggered) {
                    menuEntry.triggered();
                }
                root.close();
            }

            contentItem: RowLayout {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    right: parent.right
                    leftMargin: rippleButton.horizontalPadding
                    rightMargin: rippleButton.horizontalPadding
                }
                spacing: 8

                // Interaction column (checkbox/radio)
                Item {
                    visible: hasInteraction || menuPage.needsInteractionColumn
                    implicitWidth: root.interactionColumnWidth
                    implicitHeight: root.interactionColumnWidth

                    Loader {
                        anchors.centerIn: parent
                        active: menuEntry.buttonType === QsMenuButtonType.RadioButton
                        sourceComponent: RadioButton {
                            enabled: false
                            padding: 0
                            checked: menuEntry.checkState === Qt.Checked
                            indicator.width: 16
                            indicator.height: 16
                        }
                    }

                    Loader {
                        anchors.centerIn: parent
                        active: menuEntry.buttonType === QsMenuButtonType.CheckBox && menuEntry.checkState !== Qt.Unchecked
                        sourceComponent: MaterialSymbol {
                            text: menuEntry.checkState === Qt.PartiallyChecked ? "check_indeterminate_small" : "check"
                            iconSize: 20
                        }
                    }
                }

                // Icon column
                Item {
                    visible: hasIcon || menuPage.needsIconColumn
                    implicitWidth: root.iconColumnWidth
                    implicitHeight: root.iconColumnWidth

                    Loader {
                        anchors.centerIn: parent
                        active: hasIcon
                        sourceComponent: IconImage {
                            asynchronous: true
                            source: menuEntry.icon
                            implicitSize: 20
                            mipmap: true
                        }
                    }
                }

                // Label
                StyledText {
                    id: label
                    Layout.fillWidth: true
                    text: menuEntry.text
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    elide: Text.ElideRight
                }

                // Chevron for submenus
                Item {
                    visible: hasChevron || menuPage.needsChevronColumn
                    implicitWidth: root.chevronColumnWidth
                    implicitHeight: root.chevronColumnWidth

                    Loader {
                        anchors.centerIn: parent
                        active: hasChevron
                        sourceComponent: MaterialSymbol {
                            text: "chevron_right"
                            iconSize: 20
                        }
                    }
                }
            }
        }
    }
}
