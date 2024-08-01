/*
 * This file was generated by qdbusxml2cpp version 0.8
 * Command line was: qdbusxml2cpp -m -i loginddbustypes.h -p login1_manager_interface
 * /home/nico/kde6/src/lingmo-workspace/libkworkspace/org.freedesktop.login1.Manager.xml
 *
 * qdbusxml2cpp is Copyright (C) 2022 The Qt Company Ltd.
 */

#ifndef LOGIN1_MANAGER_INTERFACE_H
#define LOGIN1_MANAGER_INTERFACE_H

#include "loginddbustypes.h"
#include <QtCore/QByteArray>
#include <QtCore/QList>
#include <QtCore/QMap>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QStringList>
#include <QtCore/QVariant>
#include <QtDBus/QtDBus>

/*
 * Proxy class for interface org.freedesktop.login1.Manager
 */
class OrgFreedesktopLogin1ManagerInterface : public QDBusAbstractInterface
{
    Q_OBJECT
public:
    static inline const char *staticInterfaceName()
    {
        return "org.freedesktop.login1.Manager";
    }

public:
    OrgFreedesktopLogin1ManagerInterface(const QString &service, const QString &path, const QDBusConnection &connection, QObject *parent = nullptr);

    ~OrgFreedesktopLogin1ManagerInterface();

    Q_PROPERTY(QString BlockInhibited READ blockInhibited)
    inline QString blockInhibited() const
    {
        return qvariant_cast<QString>(property("BlockInhibited"));
    }

    Q_PROPERTY(QString DelayInhibited READ delayInhibited)
    inline QString delayInhibited() const
    {
        return qvariant_cast<QString>(property("DelayInhibited"));
    }

    Q_PROPERTY(QString HandleHibernateKey READ handleHibernateKey)
    inline QString handleHibernateKey() const
    {
        return qvariant_cast<QString>(property("HandleHibernateKey"));
    }

    Q_PROPERTY(QString HandleLidSwitch READ handleLidSwitch)
    inline QString handleLidSwitch() const
    {
        return qvariant_cast<QString>(property("HandleLidSwitch"));
    }

    Q_PROPERTY(QString HandlePowerKey READ handlePowerKey)
    inline QString handlePowerKey() const
    {
        return qvariant_cast<QString>(property("HandlePowerKey"));
    }

    Q_PROPERTY(QString HandleSuspendKey READ handleSuspendKey)
    inline QString handleSuspendKey() const
    {
        return qvariant_cast<QString>(property("HandleSuspendKey"));
    }

    Q_PROPERTY(QString IdleAction READ idleAction)
    inline QString idleAction() const
    {
        return qvariant_cast<QString>(property("IdleAction"));
    }

    Q_PROPERTY(qulonglong IdleActionUSec READ idleActionUSec)
    inline qulonglong idleActionUSec() const
    {
        return qvariant_cast<qulonglong>(property("IdleActionUSec"));
    }

    Q_PROPERTY(bool IdleHint READ idleHint)
    inline bool idleHint() const
    {
        return qvariant_cast<bool>(property("IdleHint"));
    }

    Q_PROPERTY(qulonglong IdleSinceHint READ idleSinceHint)
    inline qulonglong idleSinceHint() const
    {
        return qvariant_cast<qulonglong>(property("IdleSinceHint"));
    }

    Q_PROPERTY(qulonglong IdleSinceHintMonotonic READ idleSinceHintMonotonic)
    inline qulonglong idleSinceHintMonotonic() const
    {
        return qvariant_cast<qulonglong>(property("IdleSinceHintMonotonic"));
    }

    Q_PROPERTY(qulonglong InhibitDelayMaxUSec READ inhibitDelayMaxUSec)
    inline qulonglong inhibitDelayMaxUSec() const
    {
        return qvariant_cast<qulonglong>(property("InhibitDelayMaxUSec"));
    }

    Q_PROPERTY(QStringList KillExcludeUsers READ killExcludeUsers)
    inline QStringList killExcludeUsers() const
    {
        return qvariant_cast<QStringList>(property("KillExcludeUsers"));
    }

    Q_PROPERTY(QStringList KillOnlyUsers READ killOnlyUsers)
    inline QStringList killOnlyUsers() const
    {
        return qvariant_cast<QStringList>(property("KillOnlyUsers"));
    }

    Q_PROPERTY(bool KillUserProcesses READ killUserProcesses)
    inline bool killUserProcesses() const
    {
        return qvariant_cast<bool>(property("KillUserProcesses"));
    }

    Q_PROPERTY(uint NAutoVTs READ nAutoVTs)
    inline uint nAutoVTs() const
    {
        return qvariant_cast<uint>(property("NAutoVTs"));
    }

    Q_PROPERTY(bool PreparingForShutdown READ preparingForShutdown)
    inline bool preparingForShutdown() const
    {
        return qvariant_cast<bool>(property("PreparingForShutdown"));
    }

    Q_PROPERTY(bool PreparingForSleep READ preparingForSleep)
    inline bool preparingForSleep() const
    {
        return qvariant_cast<bool>(property("PreparingForSleep"));
    }

public Q_SLOTS: // METHODS
    inline QDBusPendingReply<> ActivateSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("ActivateSession"), argumentList);
    }

    inline QDBusPendingReply<> ActivateSessionOnSeat(const QString &in0, const QString &in1)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1);
        return asyncCallWithArgumentList(QStringLiteral("ActivateSessionOnSeat"), argumentList);
    }

    inline QDBusPendingReply<> AttachDevice(const QString &in0, const QString &in1, bool in2)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1) << QVariant::fromValue(in2);
        return asyncCallWithArgumentList(QStringLiteral("AttachDevice"), argumentList);
    }

    inline QDBusPendingReply<QString> CanHibernate()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanHibernate"), argumentList);
    }

    inline QDBusPendingReply<QString> CanSuspendThenHibernate()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanSuspendThenHibernate"), argumentList);
    }

    inline QDBusPendingReply<QString> CanHybridSleep()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanHybridSleep"), argumentList);
    }

    inline QDBusPendingReply<QString> CanPowerOff()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanPowerOff"), argumentList);
    }

    inline QDBusPendingReply<QString> CanReboot()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanReboot"), argumentList);
    }

    inline QDBusPendingReply<QString> CanSuspend()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("CanSuspend"), argumentList);
    }

    inline QDBusPendingReply<> FlushDevices(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("FlushDevices"), argumentList);
    }

    inline QDBusPendingReply<QDBusObjectPath> GetSeat(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("GetSeat"), argumentList);
    }

    inline QDBusPendingReply<QDBusObjectPath> GetSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("GetSession"), argumentList);
    }

    inline QDBusPendingReply<QDBusObjectPath> GetSessionByPID(uint in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("GetSessionByPID"), argumentList);
    }

    inline QDBusPendingReply<QDBusObjectPath> GetUser(uint in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("GetUser"), argumentList);
    }

    inline QDBusPendingReply<QDBusObjectPath> GetUserByPID(uint in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("GetUserByPID"), argumentList);
    }

    inline QDBusPendingReply<> Hibernate(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("Hibernate"), argumentList);
    }

    inline QDBusPendingReply<> HybridSleep(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("HybridSleep"), argumentList);
    }

    inline QDBusPendingReply<> SuspendThenHibernate(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("SuspendThenHibernate"), argumentList);
    }

    inline QDBusPendingReply<QDBusUnixFileDescriptor> Inhibit(const QString &in0, const QString &in1, const QString &in2, const QString &in3)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1) << QVariant::fromValue(in2) << QVariant::fromValue(in3);
        return asyncCallWithArgumentList(QStringLiteral("Inhibit"), argumentList);
    }

    inline QDBusPendingReply<> KillSession(const QString &in0, const QString &in1, int in2)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1) << QVariant::fromValue(in2);
        return asyncCallWithArgumentList(QStringLiteral("KillSession"), argumentList);
    }

    inline QDBusPendingReply<> KillUser(uint in0, int in1)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1);
        return asyncCallWithArgumentList(QStringLiteral("KillUser"), argumentList);
    }

    inline QDBusPendingReply<InhibitorList> ListInhibitors()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("ListInhibitors"), argumentList);
    }

    inline QDBusPendingReply<NamedSeatPathList> ListSeats()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("ListSeats"), argumentList);
    }

    inline QDBusPendingReply<SessionInfoList> ListSessions()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("ListSessions"), argumentList);
    }

    inline QDBusPendingReply<UserInfoList> ListUsers()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("ListUsers"), argumentList);
    }

    inline QDBusPendingReply<> LockSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("LockSession"), argumentList);
    }

    inline QDBusPendingReply<> LockSessions()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("LockSessions"), argumentList);
    }

    inline QDBusPendingReply<> PowerOff(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("PowerOff"), argumentList);
    }

    inline QDBusPendingReply<> Reboot(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("Reboot"), argumentList);
    }

    inline QDBusPendingReply<> ReleaseSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("ReleaseSession"), argumentList);
    }

    inline QDBusPendingReply<> SetUserLinger(uint in0, bool in1, bool in2)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0) << QVariant::fromValue(in1) << QVariant::fromValue(in2);
        return asyncCallWithArgumentList(QStringLiteral("SetUserLinger"), argumentList);
    }

    inline QDBusPendingReply<> Suspend(bool in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("Suspend"), argumentList);
    }

    inline QDBusPendingReply<> TerminateSeat(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("TerminateSeat"), argumentList);
    }

    inline QDBusPendingReply<> TerminateSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("TerminateSession"), argumentList);
    }

    inline QDBusPendingReply<> TerminateUser(uint in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("TerminateUser"), argumentList);
    }

    inline QDBusPendingReply<> UnlockSession(const QString &in0)
    {
        QList<QVariant> argumentList;
        argumentList << QVariant::fromValue(in0);
        return asyncCallWithArgumentList(QStringLiteral("UnlockSession"), argumentList);
    }

    inline QDBusPendingReply<> UnlockSessions()
    {
        QList<QVariant> argumentList;
        return asyncCallWithArgumentList(QStringLiteral("UnlockSessions"), argumentList);
    }

Q_SIGNALS: // SIGNALS
    void PrepareForShutdown(bool in0);
    void PrepareForSleep(bool in0);
    void SeatNew(const QString &in0, const QDBusObjectPath &in1);
    void SeatRemoved(const QString &in0, const QDBusObjectPath &in1);
    void SessionNew(const QString &in0, const QDBusObjectPath &in1);
    void SessionRemoved(const QString &in0, const QDBusObjectPath &in1);
    void UserNew(uint in0, const QDBusObjectPath &in1);
    void UserRemoved(uint in0, const QDBusObjectPath &in1);
};

namespace org
{
namespace freedesktop
{
namespace login1
{
using Manager = ::OrgFreedesktopLogin1ManagerInterface;
}
}
}
#endif