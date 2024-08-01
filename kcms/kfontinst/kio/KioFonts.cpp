/*
    SPDX-FileCopyrightText: 2003-2007 Craig Drummond <craig@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "KioFonts.h"
#include "Family.h"
#include "Fc.h"
#include "File.h"
#include "FontInst.h"
#include "FontInstInterface.h"
#include "KfiConstants.h"
#include "Misc.h"
#include "Style.h"
#include "debug.h"
#include <KZip>
#include <QCoreApplication>
#include <QDebug>
#include <QFile>
#include <QMimeDatabase>
#include <QTemporaryDir>
#include <QTemporaryFile>
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <kio_version.h>
#include <pwd.h>
#include <sys/stat.h>
#include <unistd.h>

using namespace Qt::StringLiterals;

static constexpr int s_MAX_IPC_SIZE = 1024 * 32;

static constexpr int constReconfigTimeout = 10;

// Pseudo plugin class to embed meta data
class KIOPluginForMetaData : public QObject
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.kde.kio.worker.fonts" FILE "fonts.json")
};

extern "C" {

Q_DECL_EXPORT int kdemain(int argc, char **argv)
{
    if (argc != 4) {
        fprintf(stderr, "Usage: kio_" KFI_KIO_FONTS_PROTOCOL " protocol domain-socket1 domain-socket2\n");
        exit(-1);
    }

    QCoreApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("kio_" KFI_KIO_FONTS_PROTOCOL));
    KFI::CKioFonts worker(argv[2], argv[3]);

    worker.dispatchLoop();

    return 0;
}
}

namespace KFI
{
inline bool isSysFolder(const QString &folder)
{
    return KFI_KIO_FONTS_SYS.toString() == folder || QLatin1String(KFI_KIO_FONTS_SYS.untranslatedText()) == folder;
}

inline bool isUserFolder(const QString &folder)
{
    return KFI_KIO_FONTS_USER.toString() == folder || QLatin1String(KFI_KIO_FONTS_USER.untranslatedText()) == folder;
}

static CKioFonts::EFolder getFolder(const QStringList &list)
{
    if (list.size() > 0) {
        const QString &folder = list[0];

        if (isSysFolder(folder)) {
            return CKioFonts::FOLDER_SYS;
        } else if (isUserFolder(folder)) {
            return CKioFonts::FOLDER_USER;
        }
        return CKioFonts::FOLDER_UNKNOWN;
    }

    return CKioFonts::FOLDER_ROOT;
}

static int getSize(const QString &file)
{
    QT_STATBUF buff;
    QByteArray f(QFile::encodeName(file));

    if (-1 != QT_LSTAT(f.constData(), &buff)) {
        if (S_ISLNK(buff.st_mode)) {
            char buffer2[1000];
            int n = readlink(f.constData(), buffer2, 999);
            if (n != -1) {
                buffer2[n] = '\0';
            }

            if (-1 == QT_STAT(f.constData(), &buff)) {
                return -1;
            }
        }
        return buff.st_size;
    }

    return -1;
}

static bool writeAll(int fd, const char *buf, size_t len)
{
    while (len > 0) {
        ssize_t written = write(fd, buf, len);
        if (written < 0 && EINTR != errno) {
            return false;
        }
        buf += written;
        len -= written;
    }
    return true;
}

static bool isScalable(const QString &str)
{
    return Misc::checkExt(str, u"ttf") || Misc::checkExt(str, u"otf") || Misc::checkExt(str, u"ttc") || Misc::checkExt(str, u"pfa")
        || Misc::checkExt(str, u"pfb");
}

static const char *const constExtensions[] = {".ttf", KFI_FONTS_PACKAGE, ".otf", ".pfa", ".pfb", ".ttc", ".pcf", ".pcf.gz", ".bdf", ".bdf.gz", nullptr};

static QString removeKnownExtension(const QUrl &url)
{
    QString fname(url.fileName());
    int pos;

    for (int i = 0; constExtensions[i]; ++i) {
        if (-1 != (pos = fname.lastIndexOf(QLatin1String(constExtensions[i]), -1, Qt::CaseInsensitive))) {
            return fname.left(pos);
        }
    }
    return fname;
}

CKioFonts::CKioFonts(const QByteArray &pool, const QByteArray &app)
    : KIO::WorkerBase(KFI_KIO_FONTS_PROTOCOL, pool, app)
    , m_interface(new FontInstInterface())
    , m_tempDir(nullptr)
{
}

CKioFonts::~CKioFonts()
{
    delete m_interface;
    delete m_tempDir;
}

KIO::WorkerResult CKioFonts::listDir(const QUrl &url)
{
    qCDebug(KCM_KFONTINST_KIO) << url;

    KIO::UDSEntry ownRootEntry;
    ownRootEntry.reserve(4);
    ownRootEntry.fastInsert(KIO::UDSEntry::UDS_NAME, QStringLiteral("."));
    ownRootEntry.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    ownRootEntry.fastInsert(KIO::UDSEntry::UDS_SIZE, 0);
    ownRootEntry.fastInsert(KIO::UDSEntry::UDS_ACCESS, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IWGRP | S_IXGRP | S_IROTH | S_IXOTH);
    listEntry(ownRootEntry);

    QStringList pathList(url.adjusted(QUrl::StripTrailingSlash).path().split(QLatin1Char('/'), Qt::SkipEmptyParts));
    EFolder folder = Misc::root() ? FOLDER_SYS : getFolder(pathList);
    KIO::UDSEntry entry;

    switch (folder) {
    case FOLDER_ROOT:
        qCDebug(KCM_KFONTINST_KIO) << "List root folder";
        totalSize(2);
        createUDSEntry(entry, FOLDER_SYS);
        listEntry(entry);
        createUDSEntry(entry, FOLDER_USER);
        listEntry(entry);
        break;
    case FOLDER_SYS:
    case FOLDER_USER:
        listFolder(entry, folder);
        break;
    default:
        break;
    }

    if (FOLDER_UNKNOWN != folder) {
        return KIO::WorkerResult::pass();
    } else {
        return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
    }
}

KIO::WorkerResult CKioFonts::put(const QUrl &url, int /*permissions*/, KIO::JobFlags /*flags*/)
{
    qCDebug(KCM_KFONTINST_KIO) << url;
    QStringList pathList(url.adjusted(QUrl::StripTrailingSlash).path().split(QLatin1Char('/'), Qt::SkipEmptyParts));
    EFolder folder(getFolder(pathList));

    if (!Misc::root() && FOLDER_ROOT == folder) {
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED,
                                       i18n("Can only install fonts to either \"%1\" or \"%2\".", KFI_KIO_FONTS_USER.toString(), KFI_KIO_FONTS_SYS.toString()));
    } else if (Misc::isPackage(url.fileName())) {
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED,
                                       i18n("You cannot install a fonts package directly.\n"
                                            "Please extract %1, and install the components individually.",
                                            url.toDisplayString()));
    } else {
        if (!m_tempDir) {
            m_tempDir = new QTemporaryDir(QDir::tempPath() + u"/kio_fonts_" + QString::number(getpid()));
            m_tempDir->setAutoRemove(true);
        }

        QString tempFile(m_tempDir->filePath(url.fileName()));
        QFile dest(tempFile);

        if (dest.open(QIODevice::WriteOnly)) {
            int result;
            // Loop until we got 0 (end of data)
            do {
                QByteArray buffer;

                dataReq(); // Request for data
                result = readData(buffer);
                if (result > 0 && !writeAll(dest.handle(), buffer.constData(), buffer.size())) {
                    dest.close();
                    if (ENOSPC == errno) // disk full
                    {
                        return KIO::WorkerResult::fail(KIO::ERR_DISK_FULL, dest.fileName());
                    }
                    return KIO::WorkerResult::fail(KIO::ERR_CANNOT_WRITE, dest.fileName());
                }
            } while (result > 0);

            const int resp = m_interface->install(tempFile, Misc::root() || FOLDER_SYS == folder);
            QFile::remove(tempFile);
            return handleResp(resp, url.fileName(), tempFile, FOLDER_SYS == folder);
        } else {
            return KIO::WorkerResult::fail(EACCES == errno ? KIO::ERR_WRITE_ACCESS_DENIED : KIO::ERR_CANNOT_OPEN_FOR_WRITING, dest.fileName());
        }
    }
    return KIO::WorkerResult::pass();
}

KIO::WorkerResult CKioFonts::get(const QUrl &url)
{
    qCDebug(KCM_KFONTINST_KIO) << url;
    QStringList pathList(url.adjusted(QUrl::StripTrailingSlash).path().split(QLatin1Char('/'), Qt::SkipEmptyParts));
    EFolder folder(getFolder(pathList));
    Family family(getFont(url, folder));

    if (!family.name().isEmpty() && 1 == family.styles().count()) {
        StyleCont::ConstIterator style(family.styles().begin());
        FileCont::ConstIterator it((*style).files().begin()), end((*style).files().end());

        //
        // The thumbnail job always downloads non-local files to /tmp/... and passes this file name to
        // the thumbnail creator. However, in the case of fonts which are split among many files, this
        // wont work. Therefore, when the thumbnail code asks for the font to download, just return
        // the family and style info for enabled fonts, and the filename for disabled fonts. This way
        // the font-thumbnail creator can read this and just ask Xft/fontconfig for the font data.
        if (u'1' == metaData(u"thumbnail"_s)) {
            QByteArray array;
            QTextStream stream(&array, QIODevice::WriteOnly);

            Q_EMIT mimeType(u"text/plain"_s);

            bool hidden(true);

            for (; it != end && hidden; ++it) {
                if (!Misc::isHidden(Misc::getFile((*it).path()))) {
                    hidden = false;
                }
            }

            if (hidden) {
                //
                // OK, its a disabled font - if possible try to return the location of the font file
                // itself.
                bool found = false;
                it = (*style).files().begin();
                end = (*style).files().end();
                for (; it != end && hidden; ++it) {
                    if (isScalable((*it).path())) {
                        qCDebug(KCM_KFONTINST_KIO) << "hasMetaData(\"thumbnail\"), so return FILE: " << (*it).path() << " / " << (*it).index();
                        stream << KFI_PATH_KEY << (*it).path() << Qt::endl << KFI_FACE_KEY << (*it).index() << Qt::endl;
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    qCDebug(KCM_KFONTINST_KIO) << "hasMetaData(\"thumbnail\"), so return Url: " << url;
                    stream << url.toDisplayString();
                }
            } else {
                qCDebug(KCM_KFONTINST_KIO) << "hasMetaData(\"thumbnail\"), so return DETAILS: " << family.name() << " / " << (*style).value();

                stream << KFI_NAME_KEY << family.name() << Qt::endl << KFI_STYLE_KEY << (*style).value() << Qt::endl;
            }

            totalSize(array.size());
            data(array);
            processedSize(array.size());
            data(QByteArray());
            processedSize(array.size());
            qCDebug(KCM_KFONTINST_KIO) << "Finished thumbnail...";
            return KIO::WorkerResult::pass();
        }

        QSet<QString> files;
        QString realPath;
        QT_STATBUF buff;
        bool multiple = false;

        for (; it != end; ++it) {
            QStringList assoc;

            files.insert((*it).path());

            Misc::getAssociatedFiles((*it).path(), assoc);

            QStringList::ConstIterator ait(assoc.constBegin()), aend(assoc.constEnd());

            for (; ait != aend; ++ait) {
                files.insert(*ait);
            }
        }

        if (1 == files.count()) {
            realPath = (*files.begin());
        } else // Font is made up of multiple files - so create .zip of them all!
        {
            QTemporaryFile tmpFile;

            if (tmpFile.open()) {
                KZip zip(tmpFile.fileName());

                tmpFile.setAutoRemove(false);
                realPath = tmpFile.fileName();

                if (zip.open(QIODevice::WriteOnly)) {
                    QMap<QString, QString> map = Misc::getFontFileMap(files);
                    QMap<QString, QString>::ConstIterator it(map.constBegin()), end(map.constEnd());

                    for (; it != end; ++it) {
                        zip.addLocalFile(it.value(), it.key());
                    }

                    multiple = true;
                    zip.close();
                }
            }
        }

        QByteArray realPathC(QFile::encodeName(realPath));
        qCDebug(KCM_KFONTINST_KIO) << "real: " << realPathC;

        if (-2 == QT_STAT(realPathC.constData(), &buff)) {
            return KIO::WorkerResult::fail(EACCES == errno ? KIO::ERR_ACCESS_DENIED : KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
        } else if (S_ISDIR(buff.st_mode)) {
            return KIO::WorkerResult::fail(KIO::ERR_IS_DIRECTORY, url.toDisplayString());
        } else if (!S_ISREG(buff.st_mode)) {
            return KIO::WorkerResult::fail(KIO::ERR_CANNOT_OPEN_FOR_READING, url.toDisplayString());
        } else {
            int fd = QT_OPEN(realPathC.constData(), O_RDONLY);

            if (fd < 0) {
                return KIO::WorkerResult::fail(KIO::ERR_CANNOT_OPEN_FOR_READING, url.toDisplayString());
            } else {
                // Determine the mimetype of the file to be retrieved, and Q_EMIT it.
                // This is mandatory in all workers (for KRun/BrowserRun to work).
                // This code can be optimized by using QFileInfo instead of buff above
                // and passing it to mimeTypeForFile() instead of realPath.
                QMimeDatabase db;
                Q_EMIT mimeType(db.mimeTypeForFile(realPath).name());

                totalSize(buff.st_size);

                KIO::filesize_t processed = 0;
                char buffer[s_MAX_IPC_SIZE];
                QByteArray array;

                while (1) {
                    int n = ::read(fd, buffer, s_MAX_IPC_SIZE);

                    if (-1 == n) {
                        if (EINTR == errno) {
                            continue;
                        }

                        ::close(fd);
                        if (multiple) {
                            ::unlink(realPathC.constData());
                        }
                        return KIO::WorkerResult::fail(KIO::ERR_CANNOT_READ, url.toDisplayString());
                    }
                    if (0 == n) {
                        break; // Finished
                    }

                    array = array.fromRawData(buffer, n);
                    data(array);
                    array.clear();

                    processed += n;
                    processedSize(processed);
                }

                data(QByteArray());
                ::close(fd);
                processedSize(buff.st_size);
                return KIO::WorkerResult::pass();
            }
        }
        if (multiple) {
            ::unlink(realPathC.constData());
        }
    } else {
        return KIO::WorkerResult::fail(KIO::ERR_CANNOT_READ, url.toDisplayString());
    }
    return KIO::WorkerResult::pass();
}

KIO::WorkerResult CKioFonts::copy(const QUrl &, const QUrl &, int, KIO::JobFlags)
{
    return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Cannot copy fonts"));
}

KIO::WorkerResult CKioFonts::rename(const QUrl &, const QUrl &, KIO::JobFlags)
{
    return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Cannot move fonts"));
}

KIO::WorkerResult CKioFonts::del(const QUrl &url, bool isFile)
{
    qCDebug(KCM_KFONTINST_KIO) << url;
    QStringList pathList(url.adjusted(QUrl::StripTrailingSlash).path().split(QLatin1Char('/'), Qt::SkipEmptyParts));
    EFolder folder(getFolder(pathList));
    QString name(removeKnownExtension(url));

    if (!isFile) {
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Only fonts may be deleted."));
    }
    if (!Misc::root() && FOLDER_ROOT == folder) {
        return KIO::WorkerResult::fail(
            KIO::ERR_WORKER_DEFINED,
            i18n("Can only remove fonts from either \"%1\" or \"%2\".", KFI_KIO_FONTS_USER.toString(), KFI_KIO_FONTS_SYS.toString()));
    }
    if (!name.isEmpty()) {
        return handleResp(m_interface->uninstall(name, Misc::root() || FOLDER_SYS == folder), name);
    }

    return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
}

KIO::WorkerResult CKioFonts::stat(const QUrl &url)
{
    qCDebug(KCM_KFONTINST_KIO) << url;

    QStringList pathList(url.adjusted(QUrl::StripTrailingSlash).path().split(QLatin1Char('/'), Qt::SkipEmptyParts));
    EFolder folder = getFolder(pathList);
    KIO::UDSEntry entry;
    bool ok = true;

    switch (pathList.count()) {
    case 0:
        createUDSEntry(entry, FOLDER_ROOT);
        break;
    case 1:
        if (Misc::root()) {
            ok = createStatEntry(entry, url, FOLDER_SYS);
        } else if (FOLDER_SYS == folder || FOLDER_USER == folder) {
            createUDSEntry(entry, folder);
        } else {
            return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED,
                                           i18n("Please specify \"%1\" or \"%2\".", KFI_KIO_FONTS_USER.toString(), KFI_KIO_FONTS_SYS.toString()));
        }
        break;
    default:
        ok = createStatEntry(entry, url, folder);
    }

    if (ok) {
        statEntry(entry);
        return KIO::WorkerResult::pass();
    } else {
        return KIO::WorkerResult::fail(KIO::ERR_DOES_NOT_EXIST, url.toDisplayString());
    }
}

KIO::WorkerResult CKioFonts::special(const QByteArray &a)
{
    if (!a.isEmpty()) {
        return KIO::WorkerResult::fail(KIO::ERR_UNSUPPORTED_ACTION, i18n("No special methods supported."));
    } else {
        setTimeoutSpecialCommand(-1);
        m_interface->reconfigure();
        return KIO::WorkerResult::pass();
    }
}

void CKioFonts::listFolder(KIO::UDSEntry &entry, EFolder folder)
{
    qCDebug(KCM_KFONTINST_KIO) << folder;

    int styleCount(0);
    KFI::Families families(m_interface->list(FOLDER_SYS == folder));
    FamilyCont::ConstIterator family(families.items.begin()), end(families.items.end());

    qCDebug(KCM_KFONTINST_KIO) << "Num families:" << families.items.count();

    for (; family != end; ++family) {
        StyleCont::ConstIterator styleIt((*family).styles().begin()), styleEnd((*family).styles().end());

        styleCount += (*family).styles().count();
        for (; styleIt != styleEnd; ++styleIt) {
            createUDSEntry(entry, *family, *styleIt);
            listEntry(entry);
        }
    }

    totalSize(styleCount);
}

QString CKioFonts::getUserName(uid_t uid)
{
    if (!m_userCache.contains(uid)) {
        struct passwd *user = getpwuid(uid);
        if (user) {
            m_userCache.insert(uid, QString::fromLatin1(user->pw_name));
        } else {
            return QString::number(uid);
        }
    }
    return m_userCache[uid];
}

QString CKioFonts::getGroupName(gid_t gid)
{
    if (!m_groupCache.contains(gid)) {
        struct group *grp = getgrgid(gid);
        if (grp) {
            m_groupCache.insert(gid, QString::fromLatin1(grp->gr_name));
        } else {
            return QString::number(gid);
        }
    }
    return m_groupCache[gid];
}

bool CKioFonts::createStatEntry(KIO::UDSEntry &entry, const QUrl &url, EFolder folder)
{
    Family fam(getFont(url, folder));

    if (!fam.name().isEmpty() && 1 == fam.styles().count()) {
        createUDSEntry(entry, fam, *fam.styles().begin());
        return true;
    }

    return false;
}

void CKioFonts::createUDSEntry(KIO::UDSEntry &entry, EFolder folder)
{
    qCDebug(KCM_KFONTINST_KIO) << QString(FOLDER_SYS == folder ? KFI_KIO_FONTS_SYS.toString() : KFI_KIO_FONTS_USER.toString());
    entry.clear();
    entry.fastInsert(KIO::UDSEntry::UDS_NAME,
                     FOLDER_ROOT == folder || Misc::root() ? i18n("Fonts")
                         : FOLDER_SYS == folder            ? KFI_KIO_FONTS_SYS.toString()
                                                           : KFI_KIO_FONTS_USER.toString());
    entry.fastInsert(KIO::UDSEntry::UDS_ACCESS, !Misc::root() && FOLDER_SYS == folder ? 0444 : 0744);
    entry.fastInsert(KIO::UDSEntry::UDS_USER, Misc::root() || FOLDER_SYS == folder ? QString::fromLatin1("root") : getUserName(getuid()));
    entry.fastInsert(KIO::UDSEntry::UDS_GROUP, Misc::root() || FOLDER_SYS == folder ? QString::fromLatin1("root") : getGroupName(getgid()));
    entry.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, S_IFDIR);
    entry.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, QString::fromLatin1("inode/directory"));
}

bool CKioFonts::createUDSEntry(KIO::UDSEntry &entry, const Family &family, const Style &style)
{
    int size = 0;
    QString name(FC::createName(family.name(), style.value()));
    FileCont::ConstIterator file(style.files().begin()), fileEnd(style.files().end());
    QList<File> files;
    bool hidden = true, haveExtraFiles = false;

    qCDebug(KCM_KFONTINST_KIO) << name;

    for (; file != fileEnd; ++file) {
        size += getSize((*file).path());
        // TODO: Make scalable a property of the file?
        // Then isScalable() is not needed!!!
        if (isScalable((*file).path())) {
            files.prepend(*file);
        } else {
            files.append(*file);
        }

        if (hidden && !Misc::isHidden(Misc::getFile((*file).path()))) {
            hidden = false;
        }

        QStringList assoc;
        Misc::getAssociatedFiles((*file).path(), assoc);

        QStringList::ConstIterator oit(assoc.constBegin()), oend(assoc.constEnd());

        if (!haveExtraFiles && !assoc.isEmpty()) {
            haveExtraFiles = true;
        }

        for (; oit != oend; ++oit) {
            size += getSize(*oit);
        }
    }

    entry.clear();

    entry.fastInsert(KIO::UDSEntry::UDS_DISPLAY_NAME, name);
    entry.fastInsert(KIO::UDSEntry::UDS_SIZE, size);
    entry.fastInsert(UDS_EXTRA_FC_STYLE, style.value());

    QList<File>::ConstIterator it(files.constBegin()), end(files.constEnd());

    for (; it != end; ++it) {
        const QString fontPath = it->path();
        QByteArray cPath(QFile::encodeName(fontPath));
        QT_STATBUF buff;

        if (-1 != QT_LSTAT(cPath.constData(), &buff)) {
            const QString fileName = Misc::getFile(fontPath);
            QString mt;
            int dotPos(fileName.lastIndexOf(u'.'));
            QString extension(-1 == dotPos ? QString() : fileName.mid(dotPos));

            if (QLatin1String(".gz") == extension) {
                dotPos = fileName.lastIndexOf(u'.', dotPos - 1);
                extension = -1 == dotPos ? QString() : fileName.mid(dotPos);
            }

            if (QLatin1String(".ttf") == extension || QLatin1String(".ttc") == extension) {
                mt = u"application/x-font-ttf"_s;
            } else if (QLatin1String(".otf") == extension) {
                mt = u"application/x-font-otf"_s;
            } else if (QLatin1String(".pfa") == extension || QLatin1String(".pfb") == extension) {
                mt = u"application/x-font-type1"_s;
            } else if (QLatin1String(".pcf.gz") == extension || QLatin1String(".pcf") == extension) {
                mt = u"application/x-font-pcf"_s;
            } else if (QLatin1String(".bdf.gz") == extension || QLatin1String(".bdf") == extension) {
                mt = u"application/x-font-bdf"_s;
            } else {
                // File extension check failed, use QMimeDatabase to read contents...
                QMimeDatabase db;
                QMimeType mime = db.mimeTypeForFile(fontPath);
                QStringList patterns = mime.globPatterns();
                mt = mime.name();
                if (patterns.size() > 0) {
                    extension = (*patterns.begin()).remove(u'*');
                }
            }

            entry.fastInsert(KIO::UDSEntry::UDS_FILE_TYPE, buff.st_mode & S_IFMT);
            entry.fastInsert(KIO::UDSEntry::UDS_ACCESS, buff.st_mode & 07777);
            entry.fastInsert(KIO::UDSEntry::UDS_MODIFICATION_TIME, buff.st_mtime);
            entry.fastInsert(KIO::UDSEntry::UDS_ACCESS_TIME, buff.st_atime);
            entry.fastInsert(KIO::UDSEntry::UDS_USER, getUserName(buff.st_uid));
            entry.fastInsert(KIO::UDSEntry::UDS_GROUP, getGroupName(buff.st_gid));
            entry.fastInsert(KIO::UDSEntry::UDS_MIME_TYPE, mt);
            const QUrl entryUrl = QUrl::fromLocalFile(fontPath);
            entry.fastInsert(KIO::UDSEntry::UDS_URL, entryUrl.toDisplayString());
            entry.fastInsert(KIO::UDSEntry::UDS_NAME, entryUrl.fileName());

            if (hidden) {
                entry.fastInsert(KIO::UDSEntry::UDS_HIDDEN, 1);
                entry.fastInsert(UDS_EXTRA_FILE_NAME, fontPath);
                entry.fastInsert(UDS_EXTRA_FILE_FACE, fontPath);
            }
            return true;
        }
    }

    return false;
}

Family CKioFonts::getFont(const QUrl &url, EFolder folder)
{
    QString name(removeKnownExtension(url));

    qCDebug(KCM_KFONTINST_KIO) << url << name;

    return m_interface->statFont(name, FOLDER_SYS == folder);
}

KIO::WorkerResult CKioFonts::handleResp(int resp, const QString &file, const QString &tempFile, bool destIsSystem)
{
    switch (resp) {
    case FontInst::STATUS_NO_SYS_CONNECTION:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Failed to start the system daemon"));
    case FontInst::STATUS_SERVICE_DIED:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Backend died"));
    case FontInst::STATUS_BITMAPS_DISABLED:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("%1 is a bitmap font, and these have been disabled on your system.", file));
    case FontInst::STATUS_ALREADY_INSTALLED:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED,
                                       i18n("%1 contains the font <b>%2</b>, which is already installed on your system.", file, FC::getName(tempFile)));
    case FontInst::STATUS_NOT_FONT_FILE:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("%1 is not a font.", file));
    case FontInst::STATUS_PARTIAL_DELETE:
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("Could not remove all files associated with %1", file));
    case KIO::ERR_FILE_ALREADY_EXIST: {
        QString name(Misc::modifyName(file)), destFolder(Misc::getDestFolder(m_interface->folderName(destIsSystem), name));
        return KIO::WorkerResult::fail(KIO::ERR_WORKER_DEFINED, i18n("<i>%1</i> already exists.", destFolder + name));
    }
    case FontInst::STATUS_OK:
        setTimeoutSpecialCommand(constReconfigTimeout);
        return KIO::WorkerResult::pass();
    default:
        return KIO::WorkerResult::fail(resp, file);
    }
}
}

#include "KioFonts.moc"
