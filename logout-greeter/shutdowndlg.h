/*
    ksmserver - the KDE session management server

    SPDX-FileCopyrightText: 2000 Matthias Ettrich <ettrich@kde.org>

    SPDX-License-Identifier: MIT
*/

#pragma once

#include <QScreen>

#include <LingmoQuick/QuickViewSharedEngine>
#include <kworkspace.h>
#include <sessionmanagement.h>

#include <KPackage/Package>

// The confirmation dialog
class KSMShutdownDlg : public LingmoQuick::QuickViewSharedEngine
{
    Q_OBJECT

public:
    KSMShutdownDlg(QWindow *parent, KWorkSpace::ShutdownType sdtype, QScreen *screen);

    void setWindowed(bool windowed)
    {
        m_windowed = windowed;
    }
    void init(const KPackage::Package &package);
    bool result() const;

public Q_SLOTS:
    void accept();
    void reject();
    void slotLogout();
    void slotHalt();
    void slotReboot();
    void slotReboot(int);
    void slotSuspend(int);
    void slotLockScreen();
    void slotCancelSoftwareUpdate();

Q_SIGNALS:
    void accepted();
    void rejected();

protected:
    void resizeEvent(QResizeEvent *e) override;

private:
    void checkSoftwareUpdatePending();

    bool m_windowed = false;
    QString m_bootOption;
    QStringList rebootOptions;
    bool m_result : 1;
    SessionManagement m_session;
};
