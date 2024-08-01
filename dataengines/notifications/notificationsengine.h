/*
    SPDX-FileCopyrightText: 2008 Dmitry Suzdalev <dimsuz@gmail.com>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include <Lingmo5Support/DataEngine>
#include <QHash>
#include <QSet>

namespace NotificationManager
{
class Notification;
}

struct NotificationInhibiton {
    QString hint;
    QString value;
};

using NotificationInhibitonPtr = std::shared_ptr<NotificationInhibiton>;

/**
 *  Engine which provides data sources for notifications.
 *  Each notification is represented by one source.
 */
class NotificationsEngine : public Lingmo5Support::DataEngine
{
    Q_OBJECT

public:
    NotificationsEngine(QObject *parent);
    ~NotificationsEngine() override;

    virtual void init();

    /**
     *  This function implements part of Notifications DBus interface.
     *  Once called, will add notification source to the engine
     */
    uint Notify(const QString &app_name,
                uint replaces_id,
                const QString &app_icon,
                const QString &summary,
                const QString &body,
                const QStringList &actions,
                const QVariantMap &hints,
                int timeout);

    Lingmo5Support::Service *serviceForSource(const QString &source) override;

    int createNotification(const QString &appName,
                           const QString &appIcon,
                           const QString &summary,
                           const QString &body,
                           int timeout,
                           const QStringList &actions,
                           const QVariantMap &hints);

    void configureNotification(const QString &appName, const QString &eventId = QString());

    /*
     * Block all notification where a given notification hint matches a given value.
     *
     * Inhibition is dropped when dereferenced.
     */
    NotificationInhibitonPtr createInhibition(const QString &hint, const QString &value);

public Q_SLOTS:
    void removeNotification(uint id, uint closeReason);

private:
    void notificationAdded(const NotificationManager::Notification &notification);

    QHash<QString, QString> m_activeNotifications;

    QList<NotificationInhibiton *> m_inhibitions;

    friend class NotificationAction;
};
