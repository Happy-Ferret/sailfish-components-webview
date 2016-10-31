/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.2

QtObject {
    property var pageStack
    property QtObject contentItem
    readonly property var listeners: ["embed:filepicker", "embed:selectasync"]

    // Defer compilation of picker components
    readonly property string _multiSelectComponentUrl: Qt.resolvedUrl("MultiSelectDialog.qml")
    readonly property string _singleSelectComponentUrl: Qt.resolvedUrl("SingleSelectPage.qml")
    readonly property string _filePickerComponentUrl: Qt.resolvedUrl("PickerCreator.qml")
    property Component _filePickerComponent

    property var _messageHandler: Connections {
        target: contentItem

        onRecvAsyncMessage: {
            if (!contentItem) {
                console.warn("PickerOpener has no contentItem. Assign / Bind contentItem for each PickerOpener.")
                return
            }

            if (!pageStack) {
                console.log("PickerOpener has no pageStack. Add missing binding.")
                return
            }

            var winid = data.winid
            switch (message) {
            case "embed:selectasync": {
                pageStack.push(data.multiple ? _multiSelectComponentUrl : _singleSelectComponentUrl,
                                               { "options": data.options, "webview": contentItem })
                break
            }
            case "embed:filepicker": {
                if (!_filePickerComponent) {
                    _filePickerComponent = Qt.createComponent(_filePickerComponentUrl)
                }

                if (_filePickerComponent.status === Component.Ready) {
                    _filePickerComponent.createObject(pageStack, {
                                                          "pageStack": pageStack,
                                                          "winid": winid,
                                                          "webView": contentItem,
                                                          "filter": data.filter,
                                                          "mode": data.mode})
                } else if (_filePickerComponent.status === Component.Error) {
                    // Component development time issue, component creation should newer fail.
                    console.warn("PickerOpener failed to create PickerOpener: ", _filePickerComponent.errorString())
                }

                break
            }
            }
        }
    }

    function handlesMessage(message) {
        return listeners.indexOf(message) >= 0
    }

    Component.onCompleted: {
        if (contentItem) {
            contentItem.addMessageListeners(listeners)
        } else {
            console.log("PickerOpener has no contentItem. Each created WebView/WebPage",
                        "instance can have own PickerOpener. Add missing binding.")
        }
    }
}
