/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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

/*!
 * \brief The OutputPlainTextEdit class
 * Generic class to display the output in a non blocking way.\n
 * It accumulates the output and uses a QTimer to display the result.\n
 * The timer can be disabled with mUseTimer flag.
 */
class OutputPlainTextEdit : public QPlainTextEdit
{
  Q_OBJECT
public:
  /*!
   * \brief OutputPlainTextEdit
   * \param parent
   */
  OutputPlainTextEdit(QWidget *parent = 0);
  /*!
   * \brief appendOutput
   * Appends the output to mQueuedOutput is mUseTimer is set.\n
   * Otherwise writes the output directly.
   * \param output
   * \param format
   */
  void appendOutput(const QString &output, const QTextCharFormat &format = QTextCharFormat());
  void setUseTimer(bool useTimer) {mUseTimer = useTimer;}
private:
  QTextCursor mTextCursor;
  QVector<QPair<QString, QTextCharFormat>> mQueuedOutput;
  QTimer mQueueTimer;
  bool mUseTimer;

  /*!
   * \brief handleOutputChunk
   * Writes the output with format.
   * \param output
   * \param format
   */
  void handleOutputChunk(const QString &output, const QTextCharFormat &format);
private slots:
  /*!
   * \brief handleNextOutputChunk
   * Called when the mQueueTimer timeout is triggered.\n
   * Reads one item from mQueuedOutput vector and restarts the mQueueTimer if vector is not empty.
   */
  void handleNextOutputChunk();
};

#endif // OUTPUTPLAINTEXTEDIT_H
