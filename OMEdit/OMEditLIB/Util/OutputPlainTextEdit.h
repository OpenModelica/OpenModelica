/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Link�pings universitet, Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#ifndef OUTPUTPLAINTEXTEDIT_H
#define OUTPUTPLAINTEXTEDIT_H

#include <QPlainTextEdit>
#include <QTimer>

const int chunkSize = 10000;

class OutputPlainTextEdit : public QPlainTextEdit
{
  Q_OBJECT
public:
  OutputPlainTextEdit(QWidget *parent = 0);
  void appendOutput(const QString &output, const QTextCharFormat &format = QTextCharFormat());
  void setUseTimer(bool useTimer) {mUseTimer = useTimer;}
private:
  QTextCursor mTextCursor;
  QVector<QPair<QString, QTextCharFormat>> mQueuedOutput;
  QTimer mQueueTimer;
  bool mUseTimer;

  void handleOutputChunk(const QString &output, const QTextCharFormat &format);
private slots:
  void handleNextOutputChunk();
};

#endif // OUTPUTPLAINTEXTEDIT_H
