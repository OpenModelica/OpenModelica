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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "LibraryFileWatcher.h"

#include <QFileInfo>

/*!
 * \class LibraryFileWatcher
 * \brief Watches loaded library files for changes made outside OMEdit.
 *
 * Editor backup and temporary files are not part of a library and are skipped.
 */
/*!
 * \brief LibraryFileWatcher::LibraryFileWatcher
 * \param pParent
 */
LibraryFileWatcher::LibraryFileWatcher(QObject *pParent)
  : RecursiveFileWatcher(pParent)
{

}

/*!
 * \brief LibraryFileWatcher::isRelevant
 * Skips editor scratch files and OMEdit's .bak-mo backups so they do not
 * trigger a library reload prompt. An irrelevant directory is not descended into.
 * \param fileInfo file or directory found below a watched library root
 * \return true if the entry should take part in the watch
 */
bool LibraryFileWatcher::isRelevant(const QFileInfo &fileInfo) const
{
  const QString fileName = fileInfo.fileName();
  // Hidden files and files ending in ~ are editor backups.
  if (fileName.startsWith(QLatin1Char('.')) || fileName.endsWith(QLatin1Char('~'))) {
    return false;
  }
  // Swap, patch and OMEdit backup files are not library sources.
  static const QStringList temporarySuffixes = {
    QStringLiteral("swp"), QStringLiteral("swx"), QStringLiteral("swo"),
    QStringLiteral("tmp"), QStringLiteral("temp"), QStringLiteral("orig"),
    QStringLiteral("rej"), QStringLiteral("bak-mo")
  };
  return !temporarySuffixes.contains(fileInfo.suffix(), Qt::CaseInsensitive);
}
