/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "LSP/LSPFileWatcher.h"

#include <QFileInfo>
#include <QRegularExpression>
#include <QUrl>

/*!
 * \class LSPFileWatcher
 * \brief Watches library roots for Modelica files changed outside OMEdit and
 * reports them as LSP file events.
 *
 * A language server indexes the files it loaded from disk. Edits made in OMEdit
 * reach it through textDocument/didChange, but a git checkout, an external
 * editor or a script leaves that index stale. This watcher spots such changes
 * so the client can send workspace/didChangeWatchedFiles.
 *
 * Only the files matching the patterns the server registered are watched.
 */
/*!
 * \brief LSPFileWatcher::LSPFileWatcher
 * \param pParent
 */
LSPFileWatcher::LSPFileWatcher(QObject *pParent)
  : RecursiveFileWatcher(pParent)
{
  connect(this, &RecursiveFileWatcher::filesChanged, this, &LSPFileWatcher::onFilesChanged);
}

/*!
 * \brief LSPFileWatcher::setPatterns
 * Takes the file extensions to watch from the glob patterns the server
 * registered. Only the extension part of a "*.{mo,mos}"-style pattern is
 * honoured; any pattern that is not of that shape falls back to watching every
 * file, which is correct but noisier.
 * \param globPatterns glob patterns from the registration
 */
void LSPFileWatcher::setPatterns(const QStringList &globPatterns)
{
  static const QRegularExpression extensionList(QStringLiteral("\\*\\.\\{([^}]+)\\}$"));
  static const QRegularExpression singleExtension(QStringLiteral("\\*\\.([A-Za-z0-9_]+)$"));

  QStringList suffixes;
  for (const QString &pattern : globPatterns) {
    QRegularExpressionMatch match = extensionList.match(pattern);
    if (match.hasMatch()) {
      const QStringList parts = match.captured(1).split(QLatin1Char(','), Qt::SkipEmptyParts);
      for (const QString &part : parts) {
        const QString suffix = part.trimmed();
        if (!suffix.isEmpty() && !suffixes.contains(suffix)) {
          suffixes.append(suffix);
        }
      }
      continue;
    }
    match = singleExtension.match(pattern);
    if (match.hasMatch()) {
      if (!suffixes.contains(match.captured(1))) {
        suffixes.append(match.captured(1));
      }
      continue;
    }
    // An unrecognised pattern: watch everything rather than silently ignore it.
    suffixes.clear();
    break;
  }
  mSuffixes = suffixes;
}

/*!
 * \brief LSPFileWatcher::isRelevant
 * Accepts directories so the search can descend into them, and files whose
 * suffix matches the patterns registered by the language server.
 * \param fileInfo file or directory found below a watched root
 * \return true if the entry should take part in the watch
 */
bool LSPFileWatcher::isRelevant(const QFileInfo &fileInfo) const
{
  // A directory must stay relevant so that the search descends into it even
  // when none of its own entries match the patterns.
  if (fileInfo.isDir()) {
    return true;
  }
  return matches(fileInfo.fileName());
}

bool LSPFileWatcher::matches(const QString &fileName) const
{
  if (mSuffixes.isEmpty()) {
    return true;
  }
  const QString suffix = QFileInfo(fileName).suffix();
  for (const QString &candidate : mSuffixes) {
    if (suffix.compare(candidate, Qt::CaseInsensitive) == 0) {
      return true;
    }
  }
  return false;
}

/*!
 * \brief LSPFileWatcher::onFilesChanged
 * Turns the changed paths into the events the language server expects.
 * \param changedFiles modified files
 * \param createdFiles new files
 * \param deletedFiles removed files
 */
void LSPFileWatcher::onFilesChanged(const QStringList &changedFiles, const QStringList &createdFiles, const QStringList &deletedFiles)
{
  QList<LSP::FileEvent> events;
  events.reserve(changedFiles.size() + createdFiles.size() + deletedFiles.size());
  for (const QString &filePath : changedFiles) {
    LSP::FileEvent event;
    event.uri = uriOf(filePath);
    event.type = LSP::FileEvent::Changed;
    events.append(event);
  }
  for (const QString &filePath : createdFiles) {
    LSP::FileEvent event;
    event.uri = uriOf(filePath);
    event.type = LSP::FileEvent::Created;
    events.append(event);
  }
  for (const QString &filePath : deletedFiles) {
    LSP::FileEvent event;
    event.uri = uriOf(filePath);
    event.type = LSP::FileEvent::Deleted;
    events.append(event);
  }
  if (!events.isEmpty()) {
    emit eventsChanged(events);
  }
}

QString LSPFileWatcher::uriOf(const QString &filePath)
{
  return QUrl::fromLocalFile(filePath).toString();
}
