import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtQml.Models 2.14

import utils 1.0

import StatusQ.Core 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Controls 0.1
import StatusQ.Components 0.1
import StatusQ.Popups.Dialog 0.1

import "../controls"

StatusDialog {
    id: root

    property var store

    title: qsTr("Import a community from Discord into Status")

    horizontalPadding: 16
    verticalPadding: 20
    width: 640

    onClosed: destroy()

    Component.onCompleted: {
        const buttons = contents.rightButtons
        for (let i = 0; i < buttons.length; i++) {
            footer.rightButtons.append(buttons[i])
        }
    }

    footer: StatusDialogFooter {
        id: footer
        rightButtons: ObjectModel {}
    }

    background: StatusDialogBackground {
        color: Theme.palette.baseColor4
    }

    contentItem: DiscordImportProgressContents {
        id: contents
        width: root.availableWidth
        store: root.store
        onClose: root.close()
    }
}