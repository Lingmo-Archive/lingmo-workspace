/*
    SPDX-FileCopyrightText: 2012 Gregor Taetzner <gregor@freenet.de>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

#include "packagekitservice.h"
#include "packagekitjob.h"

PackagekitService::PackagekitService(QObject *parent)
    : Lingmo5Support::Service(parent)
{
    setName(QStringLiteral("packagekit"));
}

Lingmo5Support::ServiceJob *PackagekitService::createJob(const QString &operation, QMap<QString, QVariant> &parameters)
{
    return new PackagekitJob(destination(), operation, parameters, this);
}
