/*
    SPDX-FileCopyrightText: 2007 Fredrik Höglund <fredrik@kde.org>

    SPDX-License-Identifier: LGPL-2.0-only
*/

#pragma once

#include <QPoint>
#include <QTimerEvent>

#include <Lingmo5Support/DataEngine>

#include <config-X11.h>

#ifdef HAVE_XFIXES
class CursorNotificationHandler;
#endif

class MouseEngine : public Lingmo5Support::DataEngine
{
    Q_OBJECT

public:
    MouseEngine(QObject *parent);
    ~MouseEngine() override;

    QStringList sources() const override;

protected:
    void init();
    void timerEvent(QTimerEvent *) override;

private Q_SLOTS:
    void updateCursorName(const QString &name);

private:
    QPoint lastPosition;
    int timerId;
#ifdef HAVE_XFIXES
    CursorNotificationHandler *handler;
#endif
};
