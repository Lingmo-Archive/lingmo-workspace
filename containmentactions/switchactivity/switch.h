/*
    SPDX-FileCopyrightText: 2009 Chani Armitage <chani@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

#include <lingmo/containmentactions.h>

#include <lingmoactivities/consumer.h>
#include <lingmoactivities/controller.h>

class QAction;

class SwitchActivity : public Lingmo::ContainmentActions
{
    Q_OBJECT
public:
    SwitchActivity(QObject *parent, const QVariantList &args);
    ~SwitchActivity() override;

    QList<QAction *> contextualActions() override;

    void performNextAction() override;
    void performPreviousAction() override;

private Q_SLOTS:
    void switchTo(QAction *action);
    void makeMenu();

private:
    QList<QAction *> m_actions;
    KActivities::Consumer m_consumer;
    KActivities::Controller m_controller;
};
