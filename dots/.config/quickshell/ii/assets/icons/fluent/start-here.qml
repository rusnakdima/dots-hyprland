// Generated from SVG file start-here.svg
import QtQuick
import QtQuick.VectorImage
import QtQuick.VectorImage.Helpers
import QtQuick.Shapes
import QtQuick.Effects

StartHere {
    implicitWidth: 64
    implicitHeight: 64
    component AnimationsInfo : QtObject
    {
        property bool paused: false
        property int loops: 1
        signal restart()
    }
    property AnimationsInfo animations : AnimationsInfo {}
    transform: [
        Scale { xScale: width / 64; yScale: height / 64 }
    ]
    objectName: "svg11"
    transformOrigin: Item.TopLeft
    Shape {
        objectName: "g11"
        id: _qt_node1
        transformOrigin: Item.TopLeft
        transform: TransformGroup {
            id: _qt_node1_transform_base_group
            Translate { x: 0.5; y: 0.5}
        }
        ShapePath {
            id: _qt_node2_fill_stroke
            objectName: "svg_path:path1"
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: 1
                focalX:0
                focalY:0
                GradientStop { position: 0; color: "#ff81dfff" }
                GradientStop { position: 1; color: "#ff0a99f9" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(55, 55, -55, 55, 4, 4)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 4 6.2 C 4 4.98497 4.98497 4 6.2 4 L 28.2 4 C 29.415 4 30.4 4.98497 30.4 6.2 L 30.4 28.2 C 30.4 29.415 29.415 30.4 28.2 30.4 L 6.2 30.4 C 4.98497 30.4 4 29.415 4 28.2 L 4 6.2 " }
        }
        ShapePath {
            id: _qt_node3_fill_stroke
            objectName: "svg_path:path2"
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: 1
                focalX:0
                focalY:0
                GradientStop { position: 0; color: "#ff81dfff" }
                GradientStop { position: 1; color: "#ff0a99f9" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(55, 55, -55, 55, 4, 4)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 32.6 6.2 C 32.6 4.98497 33.585 4 34.8 4 L 56.8 4 C 58.015 4 59 4.98497 59 6.2 L 59 28.2 C 59 29.415 58.015 30.4 56.8 30.4 L 34.8 30.4 C 33.585 30.4 32.6 29.415 32.6 28.2 L 32.6 6.2 " }
        }
        ShapePath {
            id: _qt_node4_fill_stroke
            objectName: "svg_path:path3"
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: 1
                focalX:0
                focalY:0
                GradientStop { position: 0; color: "#ff81dfff" }
                GradientStop { position: 1; color: "#ff0a99f9" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(55, 55, -55, 55, 4, 4)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 32.6 34.8 C 32.6 33.585 33.585 32.6 34.8 32.6 L 56.8 32.6 C 58.015 32.6 59 33.585 59 34.8 L 59 56.8 C 59 58.015 58.015 59 56.8 59 L 34.8 59 C 33.585 59 32.6 58.015 32.6 56.8 L 32.6 34.8 " }
        }
        ShapePath {
            id: _qt_node5_fill_stroke
            objectName: "svg_path:path4"
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: 0
                centerY: 0
                centerRadius: 1
                focalX:0
                focalY:0
                GradientStop { position: 0; color: "#ff81dfff" }
                GradientStop { position: 1; color: "#ff0a99f9" }
            }
            fillTransform: PlanarTransform.fromAffineMatrix(55, 55, -55, 55, 4, 4)
            fillRule: ShapePath.WindingFill
            PathSvg { path: "M 4 34.8 C 4 33.585 4.98497 32.6 6.2 32.6 L 28.2 32.6 C 29.415 32.6 30.4 33.585 30.4 34.8 L 30.4 56.8 C 30.4 58.015 29.415 59 28.2 59 L 6.2 59 C 4.98497 59 4 58.015 4 56.8 L 4 34.8 " }
        }
    }
}
