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

#ifndef LANGUAGESERVERTEST_H
#define LANGUAGESERVERTEST_H

#include <QObject>
#include <QString>

/*!
 * \brief The LanguageServerTest class
 * Covers how OMEdit locates the Modelica language server the build installs
 * into <prefix>/share/omedit/ls, and how that interacts with an explicitly
 * configured server.
 */
class LanguageServerTest: public QObject
{
  Q_OBJECT

private slots:
  void initTestCase();
  /*!
   * \brief findsInstalledBinary
   * Tests that ModelicaLSPClient::findBundledServer finds the standalone
   * server the build installs into share/omedit/ls.
   */
  void findsInstalledBinary();
  /*!
   * \brief ignoresEmptyInstallation
   * Tests that nothing is reported when share/omedit/ls holds no server.
   */
  void ignoresEmptyInstallation();
  /*!
   * \brief emptySettingUsesInstalledServer
   * Tests that ModelicaLSPClient::resolveExecutable falls back to the
   * installed server when *Server Executable* is left empty.
   */
  void emptySettingUsesInstalledServer();
  /*!
   * \brief configuredSettingWins
   * Tests that a configured *Server Executable* is used as given, so a user
   * can still point OMEdit at a server of their own.
   */
  void configuredSettingWins();
  /*!
   * \brief reportsMissingRuntimeFiles
   * Tests that a server installed without the tree-sitter files is reported,
   * since such a server starts and then answers nothing.
   */
  void reportsMissingRuntimeFiles();
  /*!
   * \brief reportsNothingWhenRuntimeFilesPresent
   * Tests that a complete installation reports no missing files.
   */
  void reportsNothingWhenRuntimeFilesPresent();
  void cleanupTestCase();

private:
  //! Writes an executable placeholder at \p filePath, creating its directory.
  static void createServerFile(const QString &filePath);
  //! Path of share/omedit/ls inside the fake OpenModelicaHome.
  QString installedServerDirectory() const;

  QString mOriginalOpenModelicaHome;
  QString mTemporaryHome;
};

#endif // LANGUAGESERVERTEST_H
