import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import AppLayouts.Communities.panels 1.0

import utils 1.0

SplitView {
    id: root

    Item {
        id: wrapper
        SplitView.fillWidth: true
        SplitView.fillHeight: true
        OverviewSettingsFooter {
            id: footer
            width: parent.width
            anchors.centerIn: parent
            isControlNode: controlNodeSwitch.checked
            communityName: "Socks"
        }
    }
    
    Pane {
        SplitView.preferredWidth: 300
        SplitView.fillHeight: true

        ColumnLayout {
            Switch {
                id: controlNodeSwitch
                text: "Control node on/off"
                checked: true
            }
        }
    }
}

// category: Panels
