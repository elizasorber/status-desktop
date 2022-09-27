import QtQuick 2.13

import StatusQ.Controls 0.1

import utils 1.0

StatusRoundButton {
    id: copyToClipboardButton

    property var onClick: function() {}
    property string textToCopy: ""
    property bool tooltipUnder: false
    property var store

    icon.name: "copy"

    onPressed: {
        if (!toolTip.visible) {
            toolTip.visible = true
        }
    }
    onClicked: {
        if (textToCopy) {
            store.copyToClipboard(textToCopy)
        }
        onClick()
    }

    StatusToolTip {
        id: toolTip
        text: qsTr("Copied!")
        orientation: tooltipUnder ? StatusToolTip.Orientation.Bottom: StatusToolTip.Orientation.Top
        timeout: 2000
    }
}
