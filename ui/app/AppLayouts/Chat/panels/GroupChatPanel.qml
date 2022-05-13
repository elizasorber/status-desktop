import QtQuick 2.13
import QtQuick.Layouts 1.13

import StatusQ.Components 0.1
import StatusQ.Controls 0.1

import utils 1.0


RowLayout {
     id: root

     property var sectionModule
     property var chatContentModule
     property var rootStore
     property int maxHeight

     signal panelClosed()

     QtObject {
         id: d

         property ListModel groupUsersModel: ListModel { }
         property ListModel contactsModel: ListModel { }
         property var addedMembersIds: []
         property var removedMembersIds: []

         function initialize () {
             groupUsersModel.clear()
             contactsModel.clear()
             addedMembersIds = []
             removedMembersIds = []
             tagSelector.namesModel.clear()
         }
     }

     ListView {
         id: groupUsersModelListView
         visible: false
         model: root.chatContentModule.usersModule.model
         delegate: Item {
             property string publicId: model.id
             property string name: model.name
             property string icon: model.icon
             property bool isAdmin: model.isAdmin
         }
     }

     ListView {
         id: contactsModelListView
         visible: false
         model: root.rootStore.contactsModel
         delegate: Item {
             property string publicId: model.pubKey
             property string name: model.name
             property string icon: model.icon
         }
     }

     clip: true

     Component.onCompleted: {
         d.initialize()

         // Build groupUsersModel type from model type (to fit with expected StatusTagSelector format
         for (var i = 0; i < groupUsersModelListView.count; i ++) {
             var entry = groupUsersModelListView.itemAtIndex(i)

             // Add all group users different than me
             if(!entry.isAdmin) {
                 d.groupUsersModel.insert(d.groupUsersModel.count,
                                      {"publicId": entry.publicId,
                                       "name": entry.name,
                                       "icon": entry.icon})
             }
         }

         // Build contactsModel type from model type (to fit with expected StatusTagSelector format
         for (var j = 0; j < contactsModelListView.count; j ++) {
             var entry2 = contactsModelListView.itemAtIndex(j)
             d.contactsModel.insert(d.contactsModel.count,
                                {"publicId": entry2.publicId,
                                 "name": entry2.name,
                                 "icon": entry2.icon,
                                 "isIdenticon": false,
                                 "onlineStatus": false})
         }

         // Update contacts list used by StatusTagSelector
         tagSelector.sortModel(d.contactsModel)
     }

     StatusTagSelector {
         id: tagSelector

         function memberExists(memberId) {
             var exists = false
             for (var i = 0; i < groupUsersModelListView.count; i ++) {
                 var entry = groupUsersModelListView.itemAtIndex(i)
                 if(entry.publicId === memberId) {
                     exists = true
                     break
                 }
             }
             return exists
         }

         function find(val, array) {
             for(var i = 0; i < array.length; i++) {
                 if(array[i] === val) {
                     return true
                 }
             }
             return false
         }

         function addNewMember(memberId) {
            if(find(memberId, d.addedMembersIds)) {
                return
            }

             if(!memberExists(memberId)) {
                 d.addedMembersIds.push(memberId)
             }

             if(memberExists(memberId) && find(memberId, d.removedMembersIds)) {
                 d.removedMembersIds.pop(memberId)
             }
         }

         function removeExistingMember(memberId) {
             if(find(memberId, d.removedMembersIds)) {
                 return
             }

             if(memberExists(memberId)) {
                 d.removedMembersIds.push(memberId)
             }

             if(!memberExists(memberId) && find(memberId, d.addedMembersIds)) {
                 d.addedMembersIds.pop(memberId)
             }
         }

         namesModel: d.groupUsersModel
         Layout.fillWidth: true
         Layout.alignment: Qt.AlignTop | Qt.AlignLeft
         maxHeight: root.maxHeight
         nameCountLimit: 20
         showSortedListOnlyWhenText: true
         toLabelText: qsTr("To: ")
         warningText: qsTr("USER LIMIT REACHED")
         onTextChanged: sortModel(d.contactsModel)
         onAddMember: addNewMember(memberId)
         onRemoveMember: removeExistingMember(memberId)
         ringSpecModelGetter: function(pubKey) {
             return Utils.getColorHashAsJson(pubKey);
         }
         compressedKeyGetter: function(pubKey) {
             return Utils.getCompressedPk(pubKey);
         }
     }

     StatusButton {
         id: confirmButton
         implicitHeight: 44
         Layout.alignment: Qt.AlignTop
         text: "Confirm"
         onClicked: {
             if(root.chatContentModule.chatDetails.id &&((d.addedMembersIds.length > 0) || (d.removedMembersIds.length > 0))) {
                 // Add request:
                 root.sectionModule.addGroupMembers(root.chatContentModule.chatDetails.id, JSON.stringify(d.addedMembersIds))

                 // Remove request:
                 root.sectionModule.removeMembersFromGroupChat("", root.chatContentModule.chatDetails.id, JSON.stringify(d.removedMembersIds))
             }
             root.panelClosed()
         }
     }
}
