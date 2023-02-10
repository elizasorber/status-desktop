import QtQuick 2.14
import QtQuick.Layouts 1.14

import StatusQ.Core 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Controls 0.1

import SortFilterProxyModel 0.2
import shared.popups 1.0

import AppLayouts.Chat.controls.community 1.0
import AppLayouts.Chat.helpers 1.0
import AppLayouts.Chat.stores 1.0

StatusScrollView {
    id: root

    property var rootStore
    required property CommunitiesStore store

    property int viewWidth: 560 // by design

    signal editPermissionRequested(int index)
    signal duplicatePermissionRequested(int index)
    signal removePermissionRequested(int index)

    QtObject {
        id: d

        property int permissionIndexToRemove
    }

    contentWidth: root.viewWidth
    contentHeight: mainLayout.implicitHeight

    ColumnLayout {
        id: mainLayout
        width: parent.width
        spacing: 24

        ListModel {
            id: communityItemModel

            readonly property var communityData: rootStore.mainModuleInst.activeSection

            Component.onCompleted: {
                append({
                    text: communityData.name,
                    imageSource: communityData.image,
                    color: communityData.color
                })
            }
        }

        Repeater {
            model: root.store.permissionsModel

            delegate: PermissionItem {
                Layout.preferredWidth: root.viewWidth

                holdingsListModel: HoldingsSelectionModel {
                    sourceModel: model.holdingsListModel
                    assetsModel: store.assetsModel
                    collectiblesModel: store.collectiblesModel
                }

                permissionType: model.permissionType

                SortFilterProxyModel {
                    id: proxiedChannelsModel

                    sourceModel: model.channelsListModel

                    proxyRoles: [
                        ExpressionRole {
                            name: "imageSource"
                            expression: model.iconSource
                        }
                   ]
                }

                channelsListModel: proxiedChannelsModel.count
                                   ? proxiedChannelsModel : communityItemModel
                isPrivate: model.isPrivate

                onEditClicked: root.editPermissionRequested(model.index)
                onDuplicateClicked: root.duplicatePermissionRequested(model.index)

                onRemoveClicked: {
                    d.permissionIndexToRemove = index
                    declineAllDialog.open()
                }
            }
        }
    }

    ConfirmationDialog {
        id: declineAllDialog

        header.title: qsTr("Sure you want to delete permission")
        confirmationText: qsTr("If you delete this permission, any of your community members who rely on this permission will lose the access this permission gives them.")

        onConfirmButtonClicked: {
            root.removePermissionRequested(d.permissionIndexToRemove)
            close()
        }
    }
}
