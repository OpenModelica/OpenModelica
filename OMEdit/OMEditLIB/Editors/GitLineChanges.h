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


#ifndef GITLINECHANGES_H
#define GITLINECHANGES_H

#include <QObject>
#include <QStringList>
#include <QTimer>
#include <QVector>
#include <QProcess>

class BaseEditor;

/*!
 * \class GitLineChanges
 * \brief Compares the editor text with the version of the file in Git HEAD.
 * The result is one set of Change flags for each block of the editor.
 */
class GitLineChanges : public QObject
{
  Q_OBJECT
public:
  enum Change {
    None = 0,
    Added = 1,
    Modified = 2,
    DeletedAbove = 4,
    DeletedBelow = 8
  };
  GitLineChanges(BaseEditor *pBaseEditor);
  ~GitLineChanges();
  bool hasHeadText() const {return mHasHeadText;}
  int lineChange(int blockNumber) const;
  static QVector<int> computeChanges(const QStringList &oldLines, const QStringList &newLines);
public slots:
  void updateHeadText();
  void scheduleUpdate();
  void fileSaved(const QString &fileName);
private:
  BaseEditor *mpBaseEditor;
#if !defined(__EMSCRIPTEN__)
  QProcess mGitProcess;
#endif
  QTimer mUpdateTimer;
  QStringList mHeadLines;
  bool mHasHeadText = false;
  QVector<int> mChanges;

  QString fileName() const;
  void stopGitProcess();
  void setHeadLines(bool hasHeadText, const QStringList &headLines);
  static QStringList splitLines(QString text);
private slots:
  void gitProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
  void gitProcessErrorOccurred(QProcess::ProcessError error);
  void updateChanges();
signals:
  void changesUpdated(bool headTextChanged);
};

#endif // GITLINECHANGES_H
