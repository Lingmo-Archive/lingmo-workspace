/*
    SPDX-FileCopyrightText: 2007-2009 Aaron Seigo <aseigo@kde.org>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

#include <KPackage/PackageStructure>

class LayoutTemplatePackage : public KPackage::PackageStructure
{
    Q_OBJECT
public:
    using KPackage::PackageStructure::PackageStructure;

    void initPackage(KPackage::Package *package) override
    {
        package->setDefaultPackageRoot(QStringLiteral("lingmo/layout-templates/"));
        package->addFileDefinition("mainscript", QStringLiteral("layout.js"));
        package->setRequired("mainscript", true);
    }
};

K_PLUGIN_CLASS_WITH_JSON(LayoutTemplatePackage, "lingmo-packagestructure-layouttemplate.json")

#include "layouttemplate.moc"
