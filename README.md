# PhotoSoup

Just chuck all your photos in the soup and let it simmer for a bit...

## Description

Managing large volumes of visual files (photo and video) through PowerShell.

Starts with indexing the files found in the specified folders (and extensions)
The index contains both meta-information (e.g DateTaken & GPS coordinates) as well as
visual-information (e.g. histogram, Compact Composite Descriptors, MPEG-7 Descriptors)

Using the index allows for searching, deduplication, transformation, feature classification.

## Requirements

Powershell 7 or higher

## Installation

Powershell Gallery
`Install-Module PhotoSoup -Repository PSGallery`

## Contribute

Please feel free to contribute by opening new issues or providing pull requests.
For the best development experience, open this project as a folder in Visual
Studio Code and ensure that the PowerShell extension is installed.

* [Visual Studio Code](https://code.visualstudio.com/)
* [PowerShell Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell)

This module is tested with the PowerShell testing framework Pester. To run all tests, just start the included build scrip with the test param `.\Build.ps1 -test`.

## Other Information

**Author:** RapTapApp

[**Website:**](https://github.com/RapTapApp/PhotoSoup)
