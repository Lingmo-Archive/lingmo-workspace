/*
    SPDX-FileCopyrightText: 2020 Aleix Pol Gonzalez <aleixpol@kde.org>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

#pragma once

#include "screencasting.h"
#include <QObject>
#include <qqmlregistration.h>

/**
 * Allows us to request a stream for a window identified by its universally
 * unique identifier.
 *
 * We will get a PipeWire node id that can be fed to any pipewire player, be it
 * the PipeWireSourceItem, GStreamer's pipewiresink or any other.
 */
class ScreencastingRequest : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    /**
     * The unique identifier of the window we want to cast.
     *
     * @see LingmoWindow::uuid
     * @see LingmoWindow::stackingOrderUuids
     * @see LingmoWindowModel::Uuid
     * @see TasksModel::WinIdList
     */
    Q_PROPERTY(QString uuid READ uuid WRITE setUuid RESET resetUuid NOTIFY uuidChanged)

    /**
     * The output name as define in Screen.name
     */
    Q_PROPERTY(QString outputName READ outputName WRITE setOutputName RESET resetOutputName NOTIFY outputNameChanged)

    /** The offered nodeId to give to a source */
    Q_PROPERTY(quint32 nodeId READ nodeId NOTIFY nodeIdChanged)
public:
    ScreencastingRequest(QObject *parent = nullptr);
    ~ScreencastingRequest();

    void resetUuid();
    void setUuid(const QString &uuid);
    QString uuid() const;

    void resetOutputName();
    void setOutputName(const QString &outputName);
    QString outputName() const;

    quint32 nodeId() const;

Q_SIGNALS:
    void nodeIdChanged(quint32 nodeId);
    void uuidChanged(const QString &uuid);
    void outputNameChanged(const QString &outputNames);

private:
    void setNodeid(uint nodeId);
    void setStream(std::unique_ptr<ScreencastingStream> stream);

    std::unique_ptr<Screencasting> m_screenCasting;
    std::unique_ptr<ScreencastingStream> m_stream;
    QString m_uuid;
    QString m_outputName;
    quint32 m_nodeId = 0;
};
