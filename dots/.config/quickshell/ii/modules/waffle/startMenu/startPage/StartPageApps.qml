pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

BodyRectangle {
    id: root

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 32
            rightMargin: 32
            topMargin: 25
            bottomMargin: 30
        }
        spacing: 26

        PinnedApps {
            Layout.fillWidth: true
        }

        AllApps {
            implicitHeight: 300 // for now
        }
    }

    component PinnedApps: PageSection {
        title: Translation.tr("Pinned")

        BigAppGrid {
            Layout.fillWidth: true
            columns: 8
            desktopEntries: Config.options.launcher.pinnedApps.map(appId => DesktopEntries.byId(appId))
        }
    }

    component AllApps: PageSection {
        id: allAppsSection
        title: Translation.tr("All")

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 32
            Layout.rightMargin: 32
            spacing: 8

            WButton {
                Layout.alignment: Qt.AlignRight
                implicitHeight: 32
                implicitWidth: 32
                horizontalPadding: 0
                verticalPadding: 0
                radius: Looks.radius.small
                checked: Config.options.launcher.appsViewMode === "grid"
                onClicked: Config.options.launcher.appsViewMode = "grid"

                contentItem: WAppIcon {
                    anchors.centerIn: parent
                    iconName: "view-grid-symbolic"
                    implicitSize: 18
                    tryCustomIcon: false
                }
            }

            WButton {
                Layout.alignment: Qt.AlignRight
                implicitHeight: 32
                implicitWidth: 32
                horizontalPadding: 0
                verticalPadding: 0
                radius: Looks.radius.small
                checked: Config.options.launcher.appsViewMode === "list"
                onClicked: Config.options.launcher.appsViewMode = "list"

                contentItem: WAppIcon {
                    anchors.centerIn: parent
                    iconName: "view-list-symbolic"
                    implicitSize: 18
                    tryCustomIcon: false
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 32
            Layout.rightMargin: 32
            active: Config.options.launcher.appsViewMode === "grid"
            sourceComponent: AllAppsGrid {
                implicitHeight: 300
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 32
            Layout.rightMargin: 32
            active: Config.options.launcher.appsViewMode === "list"
            sourceComponent: AllAppsListView {
                implicitHeight: 300
            }
        }
    }

    component PageSection: ColumnLayout {
        id: pageSection
        required property string title
        default property alias pageData: pageSectionContentArea.data

        spacing: 16

        WText {
            Layout.leftMargin: 32
            text: pageSection.title
            font.pixelSize: Looks.font.pixelSize.large
            font.weight: Looks.font.weight.stronger
        }

        ColumnLayout {
            id: pageSectionContentArea
            Layout.fillWidth: true
        }
    }
}
