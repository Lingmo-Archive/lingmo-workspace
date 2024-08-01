/*
    SPDX-FileCopyrightText: 2023 Fushan Wen <qydwhotmail@gmail.com>

    SPDX-License-Identifier: LGPL-2.1-or-later
*/

#pragma once

#include <qnamespace.h>
#include <qqmlregistration.h>

namespace RegionFilterMode
{
Q_NAMESPACE
QML_ELEMENT

enum Mode {
    Disabled = 0,
    Inside, /**< Window is inside the region */
    Intersect, /**< Window intersects with the region */
    Outside, /**< Window is not inside the region, and does not intersect with the region */
};
Q_ENUM_NS(Mode)
}
