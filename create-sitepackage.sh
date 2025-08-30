#!/bin/bash

# Check if sitepackage name is provided
if [ $# -eq 0 ]; then
    echo "Error: No sitepackage name provided."
    exit 1
fi

SITE_PACKAGE_NAME=$1

# Check if sitepackage name is at least 3 characters long
if [ ${#SITE_PACKAGE_NAME} -lt 3 ]; then
    echo "Error: sitepackage name must be at least 3 characters long."
    exit 1
fi

# Create sitepackage directory
mkdir -p packages/${SITE_PACKAGE_NAME}

# Create sitepackage
cd packages/${SITE_PACKAGE_NAME}

mkdir -p Resources/Private/Layouts/Page
mkdir -p Resources/Private/Templates/Page
mkdir -p Resources/Private/Partials/Page/Navigation
mkdir -p Resources/Private/Language
mkdir -p Resources/Public/Css
mkdir -p Resources/Public/Images
mkdir -p Resources/Public/JavaScript
mkdir -p Configuration/TypoScript/Setup/
mkdir -p Configuration/TsConfig/Page/
mkdir -p Configuration/TsConfig/Page/PageLayout/
mkdir -p Configuration/TCA/Overrides/

touch Resources/Public/Css/app.css
touch Resources/Private/Layouts/Page/Default.html
touch Resources/Private/Templates/Page/Default.html
touch Resources/Private/Partials/Page/Navigation/MainNavigation.html
touch Configuration/TypoScript/constants.typoscript
touch Configuration/TypoScript/setup.typoscript
touch Configuration/TCA/Overrides/sys_template.php
touch Configuration/TsConfig/Page/Page.tsconfig
touch Configuration/TypoScript/Setup/DynamicContent.typoscript
