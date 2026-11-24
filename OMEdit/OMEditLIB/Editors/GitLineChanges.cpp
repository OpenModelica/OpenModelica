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

#include "Editors/GitLineChanges.h"
#include "Editors/BaseEditor.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/LibraryTreeWidget.h"
#include "TransformationalDebugger/diff_match_patch.h"

#include <QDir>
#include <QFileInfo>
#include <QHash>
#include <QSignalBlocker>
#include <limits>

namespace {

/*!
 * \brief linesToChars
 * diff_match_patch compares characters, so each distinct line becomes one character.
 * A QChar has 16 bits, so at most 65536 distinct lines (old and new together) can be encoded.
 * This is a limit of the encoding, not of the diff algorithm.
 * Returns false if there are more distinct lines.
 */
bool linesToChars(const QStringList &lines, QHash<QString, int> &lineIds, QString &chars)
{
  chars.reserve(lines.size());
  for (const QString &line : lines) {
    auto it = lineIds.constFind(line);
    if (it == lineIds.constEnd()) {
      if (lineIds.size() > std::numeric_limits<char16_t>::max()) {
        return false;
      }
      it = lineIds.insert(line, lineIds.size());
    }
    chars.append(QChar(static_cast<char16_t>(it.value())));
  }
  return true;
}

} // namespace

/*!
 * \class GitLineChanges
 * \brief Compares the editor text with the version of the file in Git HEAD.
 * Shows nothing if the file is not in a Git repository or if git is not found.
 */
/*!
 * \brief GitLineChanges::GitLineChanges
 * \param pBaseEditor
 */
GitLineChanges::GitLineChanges(BaseEditor *pBaseEditor)
  : QObject(pBaseEditor), mpBaseEditor(pBaseEditor)
{
  mUpdateTimer.setSingleShot(true);
  mUpdateTimer.setInterval(300);
  connect(&mUpdateTimer, &QTimer::timeout, this, &GitLineChanges::updateChanges);
#if !defined(__EMSCRIPTEN__)
  connect(&mGitProcess, &QProcess::finished, this, &GitLineChanges::gitProcessFinished);
  connect(&mGitProcess, &QProcess::errorOccurred, this, &GitLineChanges::gitProcessErrorOccurred);
#endif
}

GitLineChanges::~GitLineChanges()
{
  stopGitProcess();
}

/*!
 * \brief GitLineChanges::lineChange
 * Returns the Change flags of the block.
 * \param blockNumber
 * \return
 */
int GitLineChanges::lineChange(int blockNumber) const
{
  if (blockNumber >= 0 && blockNumber < mChanges.size()) {
    return mChanges.at(blockNumber);
  }
  return None;
}

/*!
 * \brief GitLineChanges::computeChanges
 * Returns the Change flags of each line in newLines compared to oldLines.
 * \param oldLines
 * \param newLines
 * \return
 */
QVector<int> GitLineChanges::computeChanges(const QStringList &oldLines, const QStringList &newLines)
{
  const int n = oldLines.size();
  const int m = newLines.size();
  QVector<int> changes(m, None);
  // only the lines between the common first and last lines need a character
  int prefix = 0;
  while (prefix < n && prefix < m && oldLines.at(prefix) == newLines.at(prefix)) {
    prefix++;
  }
  int suffix = 0;
  while (suffix < n - prefix && suffix < m - prefix && oldLines.at(n - 1 - suffix) == newLines.at(m - 1 - suffix)) {
    suffix++;
  }

  int newIndex = prefix;
  int oldCount = 0;
  int newCount = 0;
  auto markHunk = [&]() {
    if (newCount > 0) {
      const Change change = oldCount > 0 ? Modified : Added;
      for (int i = newIndex - newCount; i < newIndex; ++i) {
        changes[i] |= change;
      }
    } else if (oldCount > 0) {
      if (newIndex < m) {
        changes[newIndex] |= DeletedAbove;
      } else if (m > 0) {
        changes[m - 1] |= DeletedBelow;
      }
    }
    oldCount = 0;
    newCount = 0;
  };

  QHash<QString, int> lineIds;
  QString oldChars, newChars;
  if (linesToChars(oldLines.mid(prefix, n - prefix - suffix), lineIds, oldChars)
      && linesToChars(newLines.mid(prefix, m - prefix - suffix), lineIds, newChars)) {
    diff_match_patch dmp;
    // the diff runs while the user types; after the timeout the result is correct but not minimal
    dmp.Diff_Timeout = 0.2f;
    const QList<Diff> diffs = dmp.diff_main(oldChars, newChars, false);
    for (const Diff &diff : diffs) {
      switch (diff.operation) {
        case OMC_OP_EQUAL:
          markHunk();
          newIndex += diff.text.size();
          break;
        case OMC_OP_DELETE:
          oldCount += diff.text.size();
          break;
        case OMC_OP_INSERT:
          newCount += diff.text.size();
          newIndex += diff.text.size();
          break;
      }
    }
  } else {
    // too many distinct lines for diff_match_patch; the whole changed range is one change
    oldCount = n - prefix - suffix;
    newCount = m - prefix - suffix;
    newIndex = m - suffix;
  }
  markHunk();
  return changes;
}

/*!
 * \brief GitLineChanges::updateHeadText
 * Reads the file from Git HEAD in the background.
 */
void GitLineChanges::updateHeadText()
{
#if !defined(__EMSCRIPTEN__)
  stopGitProcess();
  const QString file = fileName();
  if (file.isEmpty()) {
    setHeadLines(false, QStringList());
    return;
  }
  QFileInfo fileInfo(file);
  mGitProcess.setWorkingDirectory(fileInfo.absolutePath());
  mGitProcess.start("git", QStringList() << "show" << QString("HEAD:./%1").arg(fileInfo.fileName()));
#endif
}

/*!
 * \brief GitLineChanges::scheduleUpdate
 * Updates the changes after a short delay, so that typing stays fast.
 */
void GitLineChanges::scheduleUpdate()
{
  if (mHasHeadText) {
    mUpdateTimer.start();
  }
}

/*!
 * \brief GitLineChanges::fileSaved
 * Reads the file from Git HEAD again when it is saved, since it can be committed after it was read.
 * \param fileName
 */
void GitLineChanges::fileSaved(const QString &fileName)
{
  const QString file = this->fileName();
  if (!file.isEmpty() && QDir::cleanPath(QFileInfo(fileName).absoluteFilePath()) == file) {
    updateHeadText();
  }
}

/*!
 * \brief GitLineChanges::fileName
 * Returns the file of the editor, or an empty string if the editor text is not the contents of a file.
 * \return
 */
QString GitLineChanges::fileName() const
{
  ModelWidget *pModelWidget = mpBaseEditor->getModelWidget();
  LibraryTreeItem *pLibraryTreeItem = pModelWidget ? pModelWidget->getLibraryTreeItem() : nullptr;
  if (!pLibraryTreeItem || !(pLibraryTreeItem->isModelica() || pLibraryTreeItem->isText()) || !pLibraryTreeItem->isFilePathValid()) {
    return QString();
  }
  QFileInfo fileInfo(pLibraryTreeItem->getFileName());
  // encrypted libraries are not plain text
  if (!fileInfo.isFile() || fileInfo.suffix().compare(QStringLiteral("moc"), Qt::CaseInsensitive) == 0) {
    return QString();
  }
  return QDir::cleanPath(fileInfo.absoluteFilePath());
}

/*!
 * \brief GitLineChanges::stopGitProcess
 * Kills the running git process. QProcess must not be destroyed while the process runs.
 */
void GitLineChanges::stopGitProcess()
{
#if !defined(__EMSCRIPTEN__)
  if (mGitProcess.state() != QProcess::NotRunning) {
    // the result of the killed process is not used
    const QSignalBlocker signalBlocker(mGitProcess);
    mGitProcess.kill();
    mGitProcess.waitForFinished(1000);
  }
#endif
}

/*!
 * \brief GitLineChanges::setHeadLines
 * \param hasHeadText
 * \param headLines
 */
void GitLineChanges::setHeadLines(bool hasHeadText, const QStringList &headLines)
{
  const bool headTextChanged = hasHeadText != mHasHeadText;
  mHasHeadText = hasHeadText;
  mHeadLines = headLines;
  mUpdateTimer.stop();
  if (mHasHeadText) {
    updateChanges();
  } else {
    mChanges.clear();
  }
  emit changesUpdated(headTextChanged);
}

/*!
 * \brief GitLineChanges::splitLines
 * Splits the text into lines. Ignores the byte order mark, carriage returns and the newline at the end.
 * \param text
 * \return
 */
QStringList GitLineChanges::splitLines(QString text)
{
  if (text.startsWith(QChar(0xFEFF))) {
    text.remove(0, 1);
  }
  text.remove(QLatin1Char('\r'));
  if (text.endsWith(QLatin1Char('\n'))) {
    text.chop(1);
  }
  return text.split(QLatin1Char('\n'));
}

/*!
 * \brief GitLineChanges::gitProcessFinished
 * Slot activated when git finishes.
 * A non-zero exit code means that the file is not in a Git repository or not in HEAD.
 * \param exitCode
 * \param exitStatus
 */
void GitLineChanges::gitProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
#if !defined(__EMSCRIPTEN__)
  if (exitStatus != QProcess::NormalExit || exitCode != 0) {
    setHeadLines(false, QStringList());
    return;
  }
  setHeadLines(true, splitLines(QString::fromUtf8(mGitProcess.readAllStandardOutput())));
#else
  Q_UNUSED(exitCode);
  Q_UNUSED(exitStatus);
#endif
}

/*!
 * \brief GitLineChanges::gitProcessErrorOccurred
 * Slot activated when git is not found.
 * \param error
 */
void GitLineChanges::gitProcessErrorOccurred(QProcess::ProcessError error)
{
  if (error == QProcess::FailedToStart) {
    setHeadLines(false, QStringList());
  }
}

/*!
 * \brief GitLineChanges::updateChanges
 * Compares the editor text with the text in Git HEAD.
 */
void GitLineChanges::updateChanges()
{
  if (!mHasHeadText) {
    return;
  }
  int lineOffset = 0;
  const QVector<int> fileChanges = computeChanges(mHeadLines, splitLines(mpBaseEditor->fileTextForGitDiff(lineOffset)));
  const int blockCount = mpBaseEditor->getPlainTextEdit()->document()->blockCount();
  mChanges.fill(None, blockCount);
  for (int i = 0; i < blockCount && i + lineOffset < fileChanges.size(); ++i) {
    mChanges[i] = fileChanges.at(i + lineOffset);
  }
  emit changesUpdated(false);
}
