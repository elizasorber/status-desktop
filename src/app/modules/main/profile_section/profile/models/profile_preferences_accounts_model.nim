import NimQml, tables, strutils, sequtils, json

import profile_preferences_account_item
import app_service/service/profile/dto/profile_showcase_entry

type
  ModelRole {.pure.} = enum
    ShowcaseVisibility = UserRole + 1
    Order

    Address
    Name
    Emoji
    WalletType
    ColorId

QtObject:
  type
    ProfileShowcaseAccountsModel* = ref object of QAbstractListModel
      items: seq[ProfileShowcaseAccountItem]

  proc delete(self: ProfileShowcaseAccountsModel) =
    self.items = @[]
    self.QAbstractListModel.delete

  proc setup(self: ProfileShowcaseAccountsModel) =
    self.QAbstractListModel.setup

  proc newProfileShowcaseAccountsModel*(): ProfileShowcaseAccountsModel =
    new(result, delete)
    result.setup

  proc countChanged(self: ProfileShowcaseAccountsModel) {.signal.}
  proc getCount(self: ProfileShowcaseAccountsModel): int {.slot.} =
    self.items.len
  QtProperty[int] count:
    read = getCount
    notify = countChanged

  proc recalcOrder(self: ProfileShowcaseAccountsModel) =
    for order, item in self.items:
      item.order = order

  proc items*(self: ProfileShowcaseAccountsModel): seq[ProfileShowcaseAccountItem] =
    self.items

  method rowCount(self: ProfileShowcaseAccountsModel, index: QModelIndex = nil): int =
    return self.items.len

  method roleNames(self: ProfileShowcaseAccountsModel): Table[int, string] =
    {
      ModelRole.ShowcaseVisibility.int: "showcaseVisibility",
      ModelRole.Order.int: "order",

      ModelRole.Address.int: "address",
      ModelRole.Name.int: "name",
      ModelRole.WalletType.int: "walletType",
      ModelRole.Emoji.int: "emoji",
      ModelRole.ColorId.int: "colorId",
    }.toTable

  method data(self: ProfileShowcaseAccountsModel, index: QModelIndex, role: int): QVariant =
    if (not index.isValid):
      return

    if (index.row < 0 or index.row >= self.items.len):
      return

    let item = self.items[index.row]
    let enumRole = role.ModelRole

    case enumRole:
    of ModelRole.ShowcaseVisibility:
      result = newQVariant(item.showcaseVisibility.int)
    of ModelRole.Order:
      result = newQVariant(item.order)
    of ModelRole.Address:
      result = newQVariant(item.address)
    of ModelRole.Name:
      result = newQVariant(item.name)
    of ModelRole.WalletType:
      result = newQVariant(item.walletType)
    of ModelRole.Emoji:
      result = newQVariant(item.emoji)
    of ModelRole.ColorId:
      result = newQVariant(item.colorId)

  proc findIndexForAccount(self: ProfileShowcaseAccountsModel, address: string): int =
    for index in 0 ..< self.items.len:
      if (self.items[index].address == address):
        return index
    return -1

  proc hasItemInShowcase*(self: ProfileShowcaseAccountsModel, address: string): bool {.slot.} =
    let ind = self.findIndexForAccount(address)
    if ind == -1:
      return false
    return self.items[ind].showcaseVisibility != ProfileShowcaseVisibility.ToNoOne

  proc baseModelFilterConditionsMayChanged*(self: ProfileShowcaseAccountsModel) {.signal.}

  proc appendItem*(self: ProfileShowcaseAccountsModel, item: ProfileShowcaseAccountItem) =
    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete
    self.beginInsertRows(parentModelIndex, self.items.len, self.items.len)
    self.items.add(item)
    self.endInsertRows()
    self.countChanged()
    self.baseModelFilterConditionsMayChanged()

  proc upsertItemImpl(self: ProfileShowcaseAccountsModel, item: ProfileShowcaseAccountItem) =
    let ind = self.findIndexForAccount(item.address)
    if ind == -1:
      self.appendItem(item)
    else:
      self.items[ind] = item

      let index = self.createIndex(ind, 0, nil)
      defer: index.delete
      self.dataChanged(index, index, @[
        ModelRole.ShowcaseVisibility.int,
        ModelRole.Order.int,
        ModelRole.Address.int,
        ModelRole.Name.int,
        ModelRole.WalletType.int,
        ModelRole.Emoji.int,
        ModelRole.ColorId.int,
      ])

  proc upsertItemJson(self: ProfileShowcaseAccountsModel, itemJson: string) {.slot.} =
    self.upsertItemImpl(itemJson.parseJson.toProfileShowcaseAccountItem())
    self.recalcOrder()
    self.baseModelFilterConditionsMayChanged()

  proc upsertItem*(self: ProfileShowcaseAccountsModel, item: ProfileShowcaseAccountItem) =
    self.upsertItemImpl(item)
    self.recalcOrder()
    self.baseModelFilterConditionsMayChanged()

  proc upsertItems*(self: ProfileShowcaseAccountsModel, items: seq[ProfileShowcaseAccountItem]) =
    for item in items:
      self.upsertItemImpl(item)
    self.recalcOrder()
    self.baseModelFilterConditionsMayChanged()

  proc reset*(self: ProfileShowcaseAccountsModel) {.slot.} =
    self.beginResetModel()
    self.items = @[]
    self.endResetModel()
    self.countChanged()
    self.baseModelFilterConditionsMayChanged()

  proc remove*(self: ProfileShowcaseAccountsModel, index: int) {.slot.} =
    if index < 0 or index >= self.items.len:
      return

    let parentModelIndex = newQModelIndex()
    defer: parentModelIndex.delete
    self.beginRemoveRows(parentModelIndex, index, index)
    self.items.delete(index)
    self.endRemoveRows()
    self.countChanged()
    self.baseModelFilterConditionsMayChanged()

  proc removeEntry*(self: ProfileShowcaseAccountsModel, address: string) {.slot.} =
    let ind = self.findIndexForAccount(address)
    if ind != -1:
      self.remove(ind)

  proc move*(self: ProfileShowcaseAccountsModel, fromIndex: int, toIndex: int) {.slot.} =
    if fromIndex < 0 or fromIndex >= self.items.len:
      return

    self.beginResetModel()
    let item = self.items[fromIndex]
    self.items.delete(fromIndex)
    self.items.insert(@[item], toIndex)
    self.recalcOrder()
    self.endResetModel()

  proc setVisibilityByIndex*(self: ProfileShowcaseAccountsModel, ind: int, visibility: int) {.slot.} =
    if (visibility >= ord(low(ProfileShowcaseVisibility)) and
        visibility <= ord(high(ProfileShowcaseVisibility)) and
        ind >= 0 and ind < self.items.len):
      self.items[ind].showcaseVisibility = ProfileShowcaseVisibility(visibility)
      let index = self.createIndex(ind, 0, nil)
      defer: index.delete
      self.dataChanged(index, index, @[ModelRole.ShowcaseVisibility.int])
      self.baseModelFilterConditionsMayChanged()

  proc setVisibility*(self: ProfileShowcaseAccountsModel, address: string, visibility: int) {.slot.} =
    let index = self.findIndexForAccount(address)
    if index != -1:
      self.setVisibilityByIndex(index, visibility)