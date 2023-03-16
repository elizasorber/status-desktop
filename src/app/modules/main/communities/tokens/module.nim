import NimQml, json

import ../../../../../app_service/service/community_tokens/service as community_tokens_service
import ../../../../../app_service/service/community/dto/community
import ../../../../core/eventemitter
import ../../../../global/global_singleton
import ../io_interface as parent_interface
import ./io_interface, ./view , ./controller

export io_interface

type
  Module*  = ref object of io_interface.AccessInterface
    parent: parent_interface.AccessInterface
    controller: Controller
    view: View
    viewVariant: QVariant
    tempAddressFrom: string
    tempCommunityId: string
    tempChainId: int
    tempDeploymentParams: DeploymentParameters
    tempTokenMetadata: CommunityTokensMetadataDto

proc newCommunityTokensModule*(
    parent: parent_interface.AccessInterface,
    events: EventEmitter,
    communityTokensService: community_tokens_service.Service): Module =
  result = Module()
  result.parent = parent
  result.view = newView(result)
  result.viewVariant = newQVariant(result.view)
  result.controller = controller.newCommunityTokensController(result, events, communityTokensService)

method delete*(self: Module) =
  self.view.delete
  self.viewVariant.delete
  self.controller.delete

method resetTempValues(self:Module) =
  self.tempAddressFrom = ""
  self.tempCommunityId = ""
  self.tempDeploymentParams = DeploymentParameters()
  self.tempTokenMetadata = CommunityTokensMetadataDto()
  self.tempChainId = 0

method load*(self: Module) =
  singletonInstance.engine.setRootContextProperty("communityTokensModule", self.viewVariant)
  self.controller.init()
  self.view.load()

method deployCollectible*(self: Module, communityId: string, fromAddress: string, name: string, symbol: string, description: string,
                        supply: int, infiniteSupply: bool, transferable: bool, selfDestruct: bool, chainId: int, image: string) =
  self.tempAddressFrom = fromAddress
  self.tempCommunityId = communityId
  self.tempChainId = chainId
  self.tempDeploymentParams.name = name
  self.tempDeploymentParams.symbol = symbol
  self.tempDeploymentParams.supply = supply
  self.tempDeploymentParams.infiniteSupply = infiniteSupply
  self.tempDeploymentParams.transferable = transferable
  self.tempDeploymentParams.remoteSelfDestruct = selfDestruct
  self.tempTokenMetadata.image = image
  self.tempTokenMetadata.description = description
  if singletonInstance.userProfile.getIsKeycardUser():
    let keyUid = singletonInstance.userProfile.getKeyUid()
    self.controller.authenticateUser(keyUid)
  else:
    self.controller.authenticateUser()

method onUserAuthenticated*(self: Module, password: string) =
  defer: self.resetTempValues()
  if password.len == 0:
    discard
    #TODO signalize somehow
  else:
    self.controller.deployCollectibles(self.tempCommunityId, self.tempAddressFrom, password, self.tempDeploymentParams, self.tempTokenMetadata, self.tempChainId)