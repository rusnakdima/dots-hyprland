pragma ComponentBehavior: Bound

import qs.modules.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.clock.dateIndicator
import qs.modules.ii.background.widgets.clock.minuteMarks
import QtQuick
import QtQuick.Layouts

/**
 * Clock widget shown on the lock surface above the toolbar.
 * Mirrors SDDM's clock position by showing the user's chosen cookie or
 * digital clock style using the same components as the wallpaper clock.
 */
Item {
    id: root

    readonly property string clockStyle: Config.options?.background?.widgets?.clock?.styleLocked ?? "cookie"

    // Size matches wallpaper cookie clock
    readonly property real clockSize: Config.options?.background?.widgets?.clock?.cookie?.size ?? 230

    implicitWidth: clockStyle === "cookie" ? clockSize : digitalClockLoader.implicitWidth
    implicitHeight: clockStyle === "cookie" ? clockSize : digitalClockLoader.implicitHeight

    // Cookie clock (inline copy of qs.modules.ii.background.widgets.clock.CookieClock
    // so this widget is self-contained and doesn't depend on wallpaper context)
    Item {
        id: cookieRoot
        anchors.centerIn: parent
        visible: root.clockStyle === "cookie"
        implicitWidth: root.clockSize
        implicitHeight: root.clockSize

        readonly property list<string> clockNumbers: DateTime.time.split(/[: ]/)
        readonly property int clockHour: parseInt(clockNumbers[0] ?? "0") % 12
        readonly property int clockMinute: DateTime.clock.minutes
        readonly property int clockSecond: DateTime.clock.seconds

        property bool useSineCookie: Config.options?.background?.widgets?.clock?.cookie?.useSineCookie ?? false

        StyledDropShadow {
            target: cookieRoot.useSineCookie ? sineCookieLoader.item : roundedPolygonLoader.item
            RotationAnimation on rotation {
                running: Config.options?.background?.widgets?.clock?.cookie?.constantlyRotate ?? false
                duration: 30000
                easing.type: Easing.Linear
                loops: Animation.Infinite
                from: 360; to: 0
            }
        }

        Loader {
            id: sineCookieLoader
            active: cookieRoot.useSineCookie
            anchors.centerIn: parent
            sourceComponent: SineCookie {
                implicitSize: root.clockSize
                sides: Config.options?.background?.widgets?.clock?.cookie?.sides ?? 14
                color: Appearance.colors.colPrimaryContainer
            }
        }
        Loader {
            id: roundedPolygonLoader
            active: !cookieRoot.useSineCookie
            anchors.centerIn: parent
            sourceComponent: MaterialCookie {
                implicitSize: root.clockSize
                sides: Config.options?.background?.widgets?.clock?.cookie?.sides ?? 14
                color: Appearance.colors.colPrimaryContainer
            }
        }

        // Minute marks
        MinuteMarks {
            anchors.fill: parent
            color: ColorUtils.mix(Appearance.colors.colSecondary, Appearance.colors.colPrimaryContainer, 0.15)
        }

        // Hour marks
        Loader {
            anchors.centerIn: parent
            active: Config.options?.background?.widgets?.clock?.cookie?.hourMarks ?? false
            sourceComponent: HourMarks {
                implicitSize: 135 * 1.75
                color: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.55)
                colOnBackground: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondaryContainer, 0.55)
            }
        }

        // Time column
        Loader {
            anchors.centerIn: parent
            active: Config.options?.background?.widgets?.clock?.cookie?.timeIndicators ?? true
            scale: 1.4
            sourceComponent: TimeColumn {
                color: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.55)
            }
        }

        // Hour hand
        Loader {
            anchors.fill: parent; z: 1
            active: (Config.options?.background?.widgets?.clock?.cookie?.hourHandStyle ?? "fill") !== "hide"
            sourceComponent: HourHand {
                clockHour: cookieRoot.clockHour
                clockMinute: cookieRoot.clockMinute
                style: Config.options?.background?.widgets?.clock?.cookie?.hourHandStyle ?? "fill"
                color: Appearance.colors.colPrimary
            }
        }

        // Minute hand
        Loader {
            anchors.fill: parent; z: 2
            active: (Config.options?.background?.widgets?.clock?.cookie?.minuteHandStyle ?? "bold") !== "hide"
            sourceComponent: MinuteHand {
                clockMinute: cookieRoot.clockMinute
                style: Config.options?.background?.widgets?.clock?.cookie?.minuteHandStyle ?? "bold"
                color: Appearance.colors.colTertiary
            }
        }

        // Second hand
        Loader {
            id: secLoader
            anchors.fill: parent; z: 3
            active: (Config.options?.time?.secondPrecision ?? false) &&
                    (Config.options?.background?.widgets?.clock?.cookie?.secondHandStyle ?? "dot") !== "hide"
            sourceComponent: SecondHand {
                clockSecond: cookieRoot.clockSecond
                style: Config.options?.background?.widgets?.clock?.cookie?.secondHandStyle ?? "dot"
                color: Appearance.colors.colPrimary
            }
        }

        // Center dot
        Loader {
            z: 4
            anchors.centerIn: parent
            active: (Config.options?.background?.widgets?.clock?.cookie?.minuteHandStyle ?? "bold") !== "bold"
            sourceComponent: Rectangle {
                implicitWidth: 6; implicitHeight: implicitWidth; radius: implicitWidth / 2
                color: Appearance.colors.colTertiary
            }
        }

        // Date
        Loader {
            id: dateLoader
            anchors.fill: parent; z: 5
            active: (Config.options?.background?.widgets?.clock?.cookie?.dateStyle ?? "hide") !== "hide"
            sourceComponent: DateIndicator {
                color: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.55)
                style: Config.options?.background?.widgets?.clock?.cookie?.dateStyle ?? "hide"
            }
        }
    }

    // Digital clock
    Loader {
        id: digitalClockLoader
        active: root.clockStyle === "digital"
        visible: active
        anchors.centerIn: parent
        sourceComponent: DigitalClock {
            colText: Appearance.colors.colOnSecondaryContainer
            textHorizontalAlignment: Text.AlignHCenter
        }
    }
}
