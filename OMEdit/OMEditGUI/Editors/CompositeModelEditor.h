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


#ifndef COMPOSITEMODELEDITOR_H
#define COMPOSITEMODELEDITOR_H

#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Editors/BaseEditor.h"
#include "Component/Component.h"

#include <QDomDocument>
#include <QSyntaxHighlighter>

class CompositeModelEditor;
class LineAnnotation;

/*!
 * \class XMLDocument
 * \brief Inherit from QDomDocument just to reimplement toString function with default argument 2.
 */
class XMLDocument : public QDomDocument
{
public:
  XMLDocument();
  XMLDocument(CompositeModelEditor *pCompositeModelEditor);
  QString toString() const;
private:
  CompositeModelEditor *mpCompositeModelEditor;
};

class CompositeModelEditor : public BaseEditor
{
  Q_OBJECT
public:
  CompositeModelEditor(QWidget *pParent);
  QString getLastValidText() {return mLastValidText;}
  bool validateText();
  QString getXmlDocumentContent() {return mXmlDocument.toString();}
  void setXmlDocumentContent(QString content) {mXmlDocument.setContent(content);}
  QString getCompositeModelName();
  QDomElement getSubModelsElement();
  QDomNodeList getSubModels();
  QDomElement getInterfacePoint(QString subModelName, QString interfaceName);
  QDomElement getConnectionsElement();
  QDomNodeList getConnections();
  QDomElement getSubModelElement(QString name);
  QStringList getParameterNames(QString subModelName);
  QString getParameterValue(QString subModelName, QString parameterName);
  void setParameterValue(QString subModelName, QString parameterName, QString value);
  void setCompositeModelName(QString name);
  bool addSubModel(Component *pComponent);
  void createAnnotationElement(QDomElement subModel, QString visible, QString origin, QString extent, QString rotation);
  void updateSubModelPlacementAnnotation(QString name, QString visible, QString origin, QString extent, QString rotation);
  void updateSubModelParameters(QString name, QString startCommand, QString exactStep, QString geometryFile);
  void updateSubModelOrientation(QString name, QGenericMatrix<3,1,double> rot, QGenericMatrix<3,1,double> pos);
  bool createConnection(LineAnnotation *pConnectionLineAnnotation);
  bool okToConnect(LineAnnotation *pConnectionLineAnnotation);
  void updateConnection(LineAnnotation *pConnectionLineAnnotation);
  void updateSimulationParams(QString startTime, QString stopTime);
  bool isSimulationParams();
  QString getSimulationStartTime();
  QString getSimulationStopTime();
  void addInterfacesData(QDomElement interfaces, QDomElement parameters, QString singleModel=QString());
  void addInterface(Component *pInterfaceComponent, QString subModel);
  bool interfacesAligned(QString interface1, QString interface2);
  bool deleteSubModel(QString name);
  bool deleteConnection(QString startComponentName, QString endComponentName);
  virtual void popUpCompleter();
private:
  QString mLastValidText;
  bool mTextChanged;
  XMLDocument mXmlDocument;

  bool existInterfacePoint(QString subModelName, QString interfaceName);
  bool existParameter(QString subModelName, QDomElement parameterDataElement);
  bool getPositionAndRotationVectors(QString interfacePoint, QGenericMatrix<3,1,double> &CG_X_PHI_CG, QGenericMatrix<3,1,double> &X_C_PHI_X,
                                     QGenericMatrix<3,1,double> &CG_X_R_CG, QGenericMatrix<3,1,double> &X_C_R_X);
  bool fuzzyCompare(double p1, double p2);
  QGenericMatrix<3, 1, double> getRotationVector(QGenericMatrix<3, 3, double> R);
private slots:
  virtual void showContextMenu(QPoint point);
  void updateAllOrientations();
public slots:
  void setPlainText(const QString &text, bool useInserText = true);
  virtual void contentsHasChanged(int position, int charsRemoved, int charsAdded);
  virtual void toggleCommentSelection() {}
  void alignInterfaces(QString fromSubModel, QString toSubModel, bool showError = true);
  int getInterfaceDimensions(QString interfacePoint);
  QString getInterfaceCausality(QString interfacePoint);
  QString getInterfaceDomain(QString interfacePoint);
};

class CompositeModelEditorPage;
class CompositeModelHighlighter : public QSyntaxHighlighter
{
  Q_OBJECT
public:
  CompositeModelHighlighter(CompositeModelEditorPage *pCompositeModelEditorPage, QPlainTextEdit *pPlainTextEdit = 0);
  void initializeSettings();
  void highlightMultiLine(const QString &text);
protected:
  virtual void highlightBlock(const QString &text);
private:
  CompositeModelEditorPage *mpCompositeModelEditorPage;
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
#endif // COMPOSITEMODELEDITOR_H
