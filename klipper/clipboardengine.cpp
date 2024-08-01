/*
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "clipboardengine.h"
#include "clipboardservice.h"
#include "history.h"
#include "historyitem.h"
#include "historymodel.h"
#include "klipper.h"

#include <QCoreApplication>

static const QString s_clipboardSourceName = QStringLiteral("clipboard");
static const QString s_barcodeKey = QStringLiteral("supportsBarcodes");

ClipboardEngine::ClipboardEngine(QObject *parent)
    : Lingmo5Support::DataEngine(parent)
    , m_klipper(new Klipper(this, KSharedConfig::openConfig(QStringLiteral("klipperrc"))))
    , m_model(HistoryModel::self())
{
    // TODO: use a filterproxymodel
    setModel(s_clipboardSourceName, m_model.get());
    // Unset parent to avoid double delete as DataEngine::setModel will set parent for the model
    m_model.get()->setParent(nullptr);
    setData(s_clipboardSourceName, s_barcodeKey, true);
    auto updateCurrent = [this]() {
        setData(s_clipboardSourceName, QStringLiteral("current"), m_klipper->history()->empty() ? QString() : m_klipper->history()->first()->text());
    };
    connect(m_klipper->history(), &History::topChanged, this, updateCurrent);
    updateCurrent();
    auto updateEmpty = [this]() {
        setData(s_clipboardSourceName, QStringLiteral("empty"), m_klipper->history()->empty());
    };
    connect(m_klipper->history(), &History::changed, this, updateEmpty);
    updateEmpty();
}

ClipboardEngine::~ClipboardEngine()
{
    if (!QCoreApplication::closingDown()) {
        m_klipper->saveClipboardHistory();
    }
}

Lingmo5Support::Service *ClipboardEngine::serviceForSource(const QString &source)
{
    Lingmo5Support::Service *service = new ClipboardService(m_klipper, source);
    service->setParent(this);
    return service;
}

K_PLUGIN_CLASS_WITH_JSON(ClipboardEngine, "lingmo-dataengine-clipboard.json")

#include "clipboardengine.moc"
