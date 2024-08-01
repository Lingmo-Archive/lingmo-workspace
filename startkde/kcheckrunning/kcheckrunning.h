/*
    SPDX-FileCopyrightText: 2019 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#pragma once

enum CheckRunningState {
    LingmoRunning,
    NoLingmoRunning,
    NoX11,
};

CheckRunningState kCheckRunning();
