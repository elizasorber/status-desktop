import QtQuick 2.14
import QtQuick.Layouts 1.14

import StatusQ.Controls 0.1
import StatusQ.Core 0.1
import StatusQ.Core.Theme 0.1
import StatusQ.Components 0.1

import utils 1.0

import AppLayouts.Wallet 1.0

ActivityNotificationBase {
    id: root

    // Community properties:
    required property string communityId
    required property string communityName
    required property string communityImage

    // Notification type related properties:
    property bool isFirstTokenReceived: root.notification.isFirstTokenReceived
    property bool isAssetType: root.notification.tokenType === Constants.TokenType.ERC20

    // Token related properties:
    property string tokenAmount: root.notification.tokenAmount
    property string tokenName: root.notification.tokenName
    property string tokenSymbol: root.notification.tokenSymbol
    property string tokenImage: root.notification.tokenImage

    // Wallet related:
    property string walletAccountName: root.notification.walletAccountName
    property string txHash: root.notification.txHash

    QtObject {
        id: d

        readonly property string formattedTokenName: root.isAssetType ? root.tokenSymbol : root.tokenName

        readonly property string ctaText: root.isFirstTokenReceived ? qsTr("Learn more") : qsTr("Transaction details")
        readonly property string title: root.isFirstTokenReceived ? (root.isAssetType ? qsTr("You received your first community asset") : qsTr("You received your first community collectible")) :
                                                                    qsTr("Tokens received")
        readonly property string info: root.isFirstTokenReceived ? qsTr("%1 %2 was airdropped to you from the %3 community").arg(root.tokenAmount).arg(d.formattedTokenName).arg(root.communityName) :
                                                                   qsTr("You were airdropped %1 %2 from %3 to %4").arg(root.tokenAmount).arg(root.tokenName).arg(root.communityName).arg(root.walletAccountName)
    }

    bodyComponent: RowLayout {
        spacing: 8

        StatusRoundedImage {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignTop
            Layout.leftMargin: Style.current.padding
            Layout.topMargin: 2

            radius: root.isAssetType ? width / 2 : 8
            width: 44
            height: width
            image.source: root.tokenImage
            showLoadingIndicator: false
            image.fillMode: Image.PreserveAspectCrop
        }

        ColumnLayout {
            spacing: 2
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true

            StatusMessageHeader {
                Layout.fillWidth: true
                displayNameLabel.text: d.title
                timestamp: root.notification.timestamp
            }

            RowLayout {
                spacing: Style.current.padding

                StatusBaseText {
                    Layout.fillWidth: true
                    text: d.info
                    font.italic: true
                    wrapMode: Text.WordWrap
                    color: Theme.palette.baseColor1
                }
            }
        }
    }

    ctaComponent: StatusFlatButton {
        size: StatusBaseButton.Size.Small
        text: d.ctaText
        onClicked: {
            root.closeActivityCenter()
            if(root.isFirstTokenReceived) {
                Global.openFirstTokenReceivedPopup(root.communityId,
                                                   root.communityName,
                                                   root.communityImage,
                                                   root.tokenSymbol,
                                                   root.tokenName,
                                                   root.tokenAmount,
                                                   root.notification.tokenType,
                                                   root.tokenImage);
            }
            else {
                Global.changeAppSectionBySectionType(Constants.appSection.wallet,
                                                     WalletLayout.LeftPanelSelection.AllAddresses,
                                                     WalletLayout.RightPanelSelection.Activity)
                // TODO: Final navigation to the specific transaction entry --> {transaction: txHash}) --> Issue #13249
            }
        }
    }
}