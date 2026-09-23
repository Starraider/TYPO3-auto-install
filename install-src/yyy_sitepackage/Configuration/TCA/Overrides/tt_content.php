<?php

use TYPO3\CMS\Core\Utility\ExtensionManagementUtility;

ExtensionManagementUtility::addTcaSelectItemGroup(
    'tt_content',
    'CType',
    'yyy_sitepackage',
    'LLL:EXT:yyy_sitepackage/Resources/Private/Language/locallang_be.xlf:content_element.group.yyy_sitepackage',
    'after:default',
);
