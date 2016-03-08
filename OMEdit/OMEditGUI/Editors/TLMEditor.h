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


#ifndef TLMEDITOR_H
#define TLMEDITOR_H

#include <QSyntaxHighlighter>

#include "MainWindow.h"
#include "Helper.h"
#include "Utilities.h"
#include "BaseEditor.h"

class MainWindow;
class ModelWidget;
class TLMEditor;

/*!
 * \class XMLDocument
 * \brief Inherit from QDomDocument just to reimplement toString function with default argument 2.
 */
class XMLDocument : public QDomDocument
{
public:
  XMLDocument();
  XMLDocument(TLMEditor *pTLMEditor);
  QString toString() const;
private:
  TLMEditor *mpTLMEditor;
};

class TLMEditor : public BaseEditor
{
  Q_OBJECT
public:
  TLMEditor(ModelWidget *pModelWidget);
  QString getLastValidText() {return mLastValidText;}
  bool validateText();
  QDomElement getSubModelsElement();
  QDomNodeList getSubModels();
  QDomElement getConnectionsElement();
  QDomNodeList getConnections();
  QString getSimulationToolStartCommand(QString name);
  bool addSubModel(QString name, QString exactStep, QString modelFile, QString startCommand, QString visible, QString origin, QString extent,
                   QString rotation);
  void createAnnotationElement(QDomElement subModel, QString visible, QString origin, QString extent, QString rotation);
  void updateSubModelPlacementAnnotation(QString name, QString visible, QString origin, QString extent, QString rotation);
  void updateSubModelParameters(QString name, QString startCommand, QString exactStepFlag);
  bool isExactStepFlagSet(QString subModelName);
  bool createConnection(QString From, QString To, QString delay, QString alpha, QString zf, QString zfr, QString points);
  void updateTLMConnectiontAnnotation(QString fromSubModel, QString toSubModel, QString points);
  void addInterfacesData(QDomElement interfaces);
  bool existInterfaceData(QString subModelName, QString interfaceName);
  bool deleteSubModel(QString name);
  bool deleteConnection(QString startComponentName, QString endComponentName);
private:
  QString mLastValidText;
  bool mTextChanged;
  bool mForceSetPlainText;
  XMLDocument mXmlDocument;
private slots:
  virtual void showContextMenu(QPoint point);
public slots:
  void setPlainText(const QString &text);
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded);
  virtual void toggleCommentSelection() {}
};

class TLMEditorPage;
class TLMHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  TLMHighlighter(TLMEditorPage *pTLMEditorPage, QPlainTextEdit *pPlainTextEdit = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
protected:
  virtual void highlightBlock(const QString &text);
private:
  TLMEditorPage *mpTLMEditorPage;
  QPlainTextEdit *mpPlainTextEdit;
  struct HighlightingRule
  {
    QRegExp mPattern;
    QTextCharFormat mFormat;
  };
  QVector<HighlightingRule> mHighlightingRules;
  QRegExp mCommentStartExpression;
  QRegExp mCommentEndExpression;
  QRegExp mStringStartExpression;
  QRegExp mStringEndExpression;
  QTextCharFormat mTextFormat;
  QTextCharFormat mTagFormat;
  QTextCharFormat mElementFormat;
  QTextCharFormat mQuotationFormat;
  QTextCharFormat mCommentFormat;
public slots:
  void settingsChanged();
};
#endif // TLMEDITOR_H
