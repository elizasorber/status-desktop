import allure

from gui.components.community.create_community_popups import CreateCommunitiesBanner
from gui.elements.qt.button import Button
from gui.elements.qt.object import QObject
from gui.screens.community import CommunityScreen


class CommunitiesPortal(QObject):

    def __init__(self):
        super().__init__('mainWindow_communitiesPortalLayout_CommunitiesPortalLayout')
        self._create_community_button = Button('mainWindow_Create_New_Community_StatusButton')

    @allure.step('Open create community popup')
    def open_create_community_popup(self) -> CommunityScreen:
        self._create_community_button.click()
        return CreateCommunitiesBanner().wait_until_appears().open_create_community_popup()