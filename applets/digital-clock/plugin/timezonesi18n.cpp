/*
    SPDX-FileCopyrightText: 2014 Martin Klapetek <mklapetek@kde.org>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

#include "timezonesi18n.h"

#include <KCountry>
#include <KLocalizedString>

#include <unicode/localebuilder.h>

#include "timezonesi18n_generated.h"

TimeZonesI18n::TimeZonesI18n(QObject *parent)
    : QObject(parent)
    , m_isInitialized(false)
{
}

QString TimeZonesI18n::i18nContinents(const QString &continent)
{
    if (!m_isInitialized) {
        init();
    }
    return m_i18nContinents.value(continent, continent);
}

QString TimeZonesI18n::i18nCountry(QLocale::Country country)
{
    if (!m_isInitialized) {
        init();
    }

    QString countryName = KCountry::fromQLocale(country).name();

    if (countryName.isEmpty()) {
        return QLocale::countryToString(country);
    }

    return countryName;
}

QString TimeZonesI18n::i18nCity(const QString &timezoneId)
{
    if (!m_isInitialized) {
        init();
    }

    if (!m_tzNames) {
        return timezoneId;
    }

    icu::UnicodeString result;
    const auto &cityName = m_tzNames->getExemplarLocationName(icu::UnicodeString::fromUTF8(icu::StringPiece(timezoneId.toStdString())), result);

    return cityName.isBogus() ? timezoneId : QStringView(cityName.getBuffer(), cityName.length()).toString();
}

void TimeZonesI18n::init()
{
    m_i18nContinents = TimeZonesI18nData::timezoneContinentToL10nMap();

    const auto locale = icu::Locale(QLocale::system().name().toLatin1().constData());
    UErrorCode error = U_ZERO_ERROR;
    m_tzNames.reset(icu::TimeZoneNames::createInstance(locale, error));
    if (!U_SUCCESS(error)) {
        qWarning() << "failed to create timezone names:" << u_errorName(error);
    }

    m_isInitialized = true;
}
