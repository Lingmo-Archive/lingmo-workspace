/*
    SPDX-FileCopyrightText: 2018 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <QList>
#include <QObject>
#include <QString>

#include "../libdbusmenuqt/dbusmenutypes_p.h"
#include "gdbusmenutypes_p.h"
#include "gtkmenus_interface.h"

class Menu : public QObject
{
    Q_OBJECT

public:
    Menu(const QString &serviceName, const QString &objectPath, QObject *parent = nullptr);
    ~Menu() override;

    void init();
    void cleanup();

    void start(uint id);
    void stop(const QList<uint> &ids);

    bool hasMenu() const;
    bool hasSubscription(uint subscription) const;

    GMenuItem getSection(int id, bool *ok = nullptr) const;
    GMenuItem getSection(int subscription, int sectionId, bool *ok = nullptr) const;

    QVariantMap getItem(int id) const; // bool ok argument?
    QVariantMap getItem(int subscription, int sectionId, int id) const;

public Q_SLOTS:
    void actionsChanged(const QStringList &dirtyActions, const QString &prefix);

Q_SIGNALS:
    void menuAppeared(); // emitted the first time a menu was successfully loaded
    void menuDisappeared();

    void subscribed(uint id);
    void failedToSubscribe(uint id);

    void itemsChanged(const QList<uint> &itemIds);
    void menusChanged(const QList<uint> &menuIds);

private Q_SLOTS:
    void onMenuChanged(const GMenuChangeList &changes);

private:
    void initMenu();

    void menuChanged(const GMenuChangeList &changes);

    // QSet?
    QList<uint> m_subscriptions; // keeps track of which menu trees we're subscribed to

    QHash<uint, GMenuItemList> m_menus;

    QScopedPointer<OrgGtkMenusInterface, QScopedPointerDeleteLater> m_interface;
};
