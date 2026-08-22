/*
 * Copyright (C) 2026 OPENOS-dev
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the OPENOS-PROJECT-LICENSE (OPL) v1.2.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * OPL for more details.
 *
 * You should have received a copy of the OPL along with this program.
 * If not, see <https://github.com/OPENOS-dev/OPL>.
 */

import QtQuick 2.15
import QtQuick.Window 2.15

/* OPENOS 文件管理器 (独立应用, OPENUI)
 * Windows 文件资源管理器风格: 多标签浏览, 每个标签独立导航
 * 生产: 对接 openos-files 子系统 (隔离文件系统)
 */
Window {
    id: fmWin
    width: 720; height: 500
    minimumWidth: 400; minimumHeight: 300
    flags: Qt.FramelessWindowHint
    title: "文件管理器"
    color: "transparent"

    // ---- 标签系统 ----
    ListModel { id: tabModel }
    property int activeTab: 0

    function addTab(path) {
        tabModel.append({
            currentPath: path || "/",
            history: [path || "/"],
            historyPos: 0,
            files: []
        })
        activeTab = tabModel.count - 1
        loadDir(activeTab)
    }
    function closeTab(idx) {
        if (tabModel.count <= 1) return
        tabModel.remove(idx)
        if (activeTab >= tabModel.count) activeTab = tabModel.count - 1
    }
    function curTab() {
        if (activeTab < 0 || activeTab >= tabModel.count) return null
        return tabModel.get(activeTab)
    }

    function loadDir(tabIdx) {
        var tab = tabModel.get(tabIdx)
        if (!tab) return
        var files = []
        var path = tab.currentPath
        if (path === "/") {
            files = [{name:"home", type:"dir", size:"---", mtime:"2026-08-18"},
                     {name:"etc", type:"dir", size:"---", mtime:"2026-08-10"},
                     {name:"usr", type:"dir", size:"---", mtime:"2026-08-01"},
                     {name:"var", type:"dir", size:"---", mtime:"2026-08-15"},
                     {name:"opt", type:"dir", size:"---", mtime:"2026-08-18"},
                     {name:"tmp", type:"dir", size:"---", mtime:"2026-08-18"},
                     {name:"vmapp", type:"dir", size:"---", mtime:"2026-08-12"}]
        } else if (path.startsWith("/home")) {
            files = [{name:"user", type:"dir", size:"---", mtime:"2026-08-18"},
                     {name:"user/文档", type:"dir", size:"---", mtime:"2026-08-17"},
                     {name:"user/下载", type:"dir", size:"---", mtime:"2026-08-16"},
                     {name:"user/桌面", type:"dir", size:"---", mtime:"2026-08-18"}]
        } else {
            files = [{name:"readme.txt", type:"file", size:"1.2 KB", mtime:"2026-08-15"},
                     {name:"notes.md", type:"file", size:"4.5 KB", mtime:"2026-08-14"},
                     {name:"config.json", type:"file", size:"0.8 KB", mtime:"2026-08-13"},
                     {name:"subdir", type:"dir", size:"---", mtime:"2026-08-18"}]
        }
        tab.files = files
        tabModel.set(tabIdx, tab)
        fileListView.model = tab.files
    }

    function navigateTo(path) {
        var tab = curTab()
        if (!tab) return
        if (tab.historyPos < tab.history.length - 1)
            tab.history = tab.history.slice(0, tab.historyPos + 1)
        tab.history.push(path); tab.historyPos = tab.history.length - 1
        tab.currentPath = path
        tabModel.set(activeTab, tab)
        loadDir(activeTab)
    }
    function goBack() {
        var tab = curTab()
        if (!tab || tab.historyPos <= 0) return
        tab.historyPos--; tab.currentPath = tab.history[tab.historyPos]
        tabModel.set(activeTab, tab); loadDir(activeTab)
    }
    function goForward() {
        var tab = curTab()
        if (!tab || tab.historyPos >= tab.history.length - 1) return
        tab.historyPos++; tab.currentPath = tab.history[tab.historyPos]
        tabModel.set(activeTab, tab); loadDir(activeTab)
    }
    function goUp() {
        var tab = curTab()
        if (!tab) return
        var parts = tab.currentPath.replace(/\/+$/, "").split("/")
        if (parts.length > 1) { parts.pop(); navigateTo(parts.join("/") || "/") }
    }

    Component.onCompleted: addTab("/")

    Rectangle {
        anchors.fill: parent; anchors.margins: 1
        radius: OpenUI.shapeLg
        color: Qt.rgba(OpenUI.surface6.r, OpenUI.surface6.g, OpenUI.surface6.b, OpenUI.glassMenuAlpha)
        border.color: OpenUI.outlineVariant; border.width: 1
        clip: true

        Column {
            anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: 2

            // ---- 标签栏 (Windows 文件资源管理器风格) ----
            Rectangle {
                width: parent.width; height: 30; color: "transparent"
                Row { width: parent.width; spacing: 2; clip: true
                    Repeater {
                        model: tabModel
                        Rectangle {
                            width: Math.min(120, (parent.width - 32) / Math.max(tabModel.count, 1))
                            height: 26; radius: 4
                            color: index === activeTab ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.12) : Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.06)
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.currentPath; color: index === activeTab ? OpenUI.primary : OpenUI.onSurfaceVariant
                                font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 28
                            }
                            Rectangle {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.rightMargin: 4
                                width: 16; height: 16; radius: 3
                                color: tabClose.hovered ? Qt.rgba(OpenUI.error.r,OpenUI.error.g,OpenUI.error.b,0.3) : "transparent"
                                ThemedIcon { anchors.centerIn: parent; name: "window-close"; ctx: "Actions"; size: 12; color: tabClose.hovered ? OpenUI.error : OpenUI.onSurfaceDisabled }
                                MouseArea { id: tabClose; anchors.fill: parent; hoverEnabled: true; onClicked: closeTab(index) }
                            }
                            MouseArea { anchors.fill: parent; onClicked: activeTab = index }
                        }
                    }
                    Rectangle {
                        width: 26; height: 26; radius: 4
                        color: newTabHover.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2) : "transparent"
                        Text { anchors.centerIn: parent; text: "+"; color: OpenUI.primary; font.pixelSize: 16 }
                        MouseArea { id: newTabHover; anchors.fill: parent; hoverEnabled: true; onClicked: addTab("/") }
                    }
                }
            }

            // ---- 导航栏 ----
            Row { width: parent.width; height: 32; spacing: 2
                Repeater {
                    model: [
                        {icon:"go-previous", ctx:"Navigation", tip:"后退", act:"back"},
                        {icon:"go-next", ctx:"Navigation", tip:"前进", act:"fwd"},
                        {icon:"go-up", ctx:"Navigation", tip:"上层", act:"up"},
                        {icon:"view-refresh", ctx:"Actions", tip:"刷新", act:"refresh"}
                    ]
                    Rectangle {
                        width: 30; height: 30; radius: OpenUI.shapeXs
                        color: navHover.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"
                        ThemedIcon { anchors.centerIn: parent; name: modelData.icon; ctx: modelData.ctx; size: 14; color: OpenUI.onSurfaceVariant }
                        MouseArea { id: navHover; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                if (modelData.act === "back") goBack()
                                else if (modelData.act === "fwd") goForward()
                                else if (modelData.act === "up") goUp()
                                else if (modelData.act === "refresh") loadDir(activeTab)
                            }
                        }
                    }
                }
                Rectangle {
                    width: parent.width - 132; height: 30; radius: OpenUI.shapeXs
                    color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b, 0.3)
                    Row { anchors.fill: parent; anchors.margins: 6; spacing: 4
                        ThemedIcon { name: "go-next"; ctx: "Navigation"; size: 12; color: OpenUI.primary; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: curTab() ? curTab().currentPath : "/"
                            color: OpenUI.onSurface; font.pixelSize: 12; elide: Text.ElideLeft
                            verticalAlignment: Text.AlignVCenter; width: parent.width - 20
                        }
                    }
                }
            }

            // ---- 文件列表 ----
            ListView {
                id: fileListView
                width: parent.width; height: parent.height - 90
                clip: true
                header: Rectangle {
                    width: parent.width; height: 28
                    color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.15)
                    Row { anchors.fill: parent; anchors.margins: OpenUI.sp1; spacing: OpenUI.sp2
                        Text { width: 28; height: 24; text: ""; color: OpenUI.onSurfaceVariant; font.pixelSize: 11 }
                        Text { width: parent.width - 160; height: 24; text: "名称"; color: OpenUI.onSurfaceVariant; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                        Text { width: 60; height: 24; text: "大小"; color: OpenUI.onSurfaceVariant; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                        Text { width: 80; height: 24; text: "修改日期"; color: OpenUI.onSurfaceVariant; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                    }
                }
                delegate: Rectangle {
                    width: parent.width; height: 32; radius: OpenUI.shapeXs
                    color: itemHover.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.12) : "transparent"
                    Row { anchors.fill: parent; anchors.margins: OpenUI.sp1; spacing: OpenUI.sp2
                        Item { width: 28; height: 24
                            ThemedIcon {
                                anchors.centerIn: parent
                                name: modelData.type === "dir" ? "folder" : "document"; ctx: "Places"
                                size: 14
                                color: modelData.type === "dir" ? OpenUI.primary : OpenUI.onSurfaceVariant
                            }
                        }
                        Text { width: parent.width - 160; height: 24; text: modelData.name; color: OpenUI.onSurface; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                        Text { width: 60; height: 24; text: modelData.size; color: OpenUI.onSurfaceDisabled; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight }
                        Text { width: 80; height: 24; text: modelData.mtime; color: OpenUI.onSurfaceDisabled; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter }
                    }
                    MouseArea { id: itemHover; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (modelData.type === "dir") {
                                var tab = curTab()
                                if (tab) navigateTo(tab.currentPath.replace(/\/$/, "") + "/" + modelData.name)
                            }
                        }
                    }
                }
            }
        }
    }
}