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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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

#ifndef STRINGHANDLER_H
#define STRINGHANDLER_H

#include <QObject>
#include <QComboBox>
#include <QProcessEnvironment>

class StringHandler : public QObject
{
  Q_OBJECT
public:
  StringHandler();
  ~StringHandler();
  enum ViewType {Icon, Diagram, ModelicaText, NoView};
  enum ModelicaClasses {Model, Class, ExpandableConnector, Connector, Record, Block, Function, Package, Primitive, Type, Operator,
                        OperatorRecord, OperatorFunction, Optimization, Parameter, Constant, Protected, Enumeration};
  enum OpenModelicaErrors {Notification, Warning, OMError, NoOMError};
  enum OpenModelicaErrorKinds {Syntax, Grammar, Translation, Symbolic, Simulation, Scripting, NoOMErrorKind};
  enum LinePattern {LineNone, LineSolid, LineDash, LineDot, LineDashDot, LineDashDotDot};
  enum FillPattern {FillNone, FillSolid, FillHorizontal, FillVertical, FillCross, FillForward, FillBackward, FillCrossDiag,
                    FillHorizontalCylinder, FillVerticalCylinder, FillSphere};
  enum BorderPattern {BorderNone, BorderRaised, BorderSunken, BorderEngraved};
  enum Smooth {SmoothNone, SmoothBezier};
  enum Arrow {ArrowNone, ArrowOpen, ArrowFilled, ArrowHalf};
  enum TextStyle {TextStyleBold, TextStyleItalic, TextStyleUnderLine};
  enum TextAlignment {TextAlignmentLeft, TextAlignmentCenter, TextAlignmentRight};
  enum SimulationMessageType {
    Unknown,
    Info,
    SMWarning,
    Error,
    Assert,
    Debug,
    OMEditInfo  /* used internally by OMEdit to mark message blue. */
  };
  enum TLMCausality { TLMBidirectional, TLMInput, TLMOutput };
  static QString getTLMCausality(int causality);
  enum TLMDomain { Mechanical, Electric, Hydraulic, Pneumatic, Magnetic, Signal };
  static QString getTLMDomain(int domain);
  enum SimulationTools {Adams, Beast, Dymola, OpenModelica, Simulink, WolframSystemModeler, Other};
  static QString getSimulationTool(int tool);
  static QString getSimulationToolStartCommand(QString tool, QString simulationToolStartCommand);
  static StringHandler::SimulationTools getSimulationTool(QString simulationToolStartCommand);
  static QString getModelicaClassType(int type);
  static StringHandler::ModelicaClasses getModelicaClassType(QString type);
  static QString getViewType(int type);
  static StringHandler::OpenModelicaErrorKinds getErrorKind(QString errorKind);
  static QString getErrorKindString(StringHandler::OpenModelicaErrorKinds errorKind);
  static StringHandler::OpenModelicaErrors getErrorType(QString errorType);
  static QString getErrorTypeDisplayString(StringHandler::OpenModelicaErrors errorType);
  static QString getErrorTypeString(StringHandler::OpenModelicaErrors errorType);
  static Qt::PenStyle getLinePatternType(StringHandler::LinePattern type);
  static StringHandler::LinePattern getLinePatternType(QString type);
  static QString getLinePatternString(StringHandler::LinePattern type);
  static QComboBox* getLinePatternComboBox();
  static Qt::BrushStyle getFillPatternType(StringHandler::FillPattern type);
  static StringHandler::FillPattern getFillPatternType(QString type);
  static QString getFillPatternString(StringHandler::FillPattern type);
  static QComboBox* getFillPatternComboBox();
  static StringHandler::BorderPattern getBorderPatternType(QString type);
  static QString getBorderPatternString(StringHandler::BorderPattern type);
  static StringHandler::Smooth getSmoothType(QString type);
  static QString getSmoothString(StringHandler::Smooth type);
  static StringHandler::Arrow getArrowType(QString type);
  static QString getArrowString(StringHandler::Arrow type);
  static QComboBox* getStartArrowComboBox();
  static QComboBox* getEndArrowComboBox();
  static int getFontWeight(QList<StringHandler::TextStyle> styleList);
  static bool getFontItalic(QList<StringHandler::TextStyle> styleList);
  static bool getFontUnderline(QList<StringHandler::TextStyle> styleList);
  static Qt::Alignment getTextAlignment(StringHandler::TextAlignment alignment);
  static StringHandler::TextAlignment getTextAlignmentType(QString alignment);
  static QString getTextAlignmentString(StringHandler::TextAlignment alignment);
  static QString getTextStyleString(StringHandler::TextStyle textStyle);
  static QString removeFirstLastCurlBrackets(QString value);
  static QString removeFirstLastParentheses(QString value);
  static QString removeFirstLastSquareBrackets(QString value);
  static QString removeFirstLastQuotes(QString value);
  static QString removeFirstLastSingleQuotes(QString value);
  static QStringList getStrings(QString value);
  static QStringList getStrings(QString value, char start, char end);
  /* Handles quoted identifiers A.B.'C.D' -> A.B, A.B.C.D -> A.B.C */
  static QString getLastWordAfterDot(QString value);
  static QString removeLastWordAfterDot(QString value);
  static QString getFirstWordBeforeDot(QString value);
  static QString removeFirstWordAfterDot(QString value);
  static QString escapeString(QString value);
  static QString escapeStringQuotes(QString value);
  // Returns "" if the string is not a standard Modelica string. Else it unparses it into normal form.
  static QString unparse(QString value);
  // Returns empty list if the string is not a standard Modelica string-array. Else it unparses it into normal form.
  static QStringList unparseStrings(QString value);
  // Returns empty list if the string is not a standard Modelica array. Else it unparses it into normal form.
  static QStringList unparseArrays(QString value);
  // Returns false on failure
  static bool unparseBool(QString value);
  static QString getSaveFileName(QWidget* parent = 0, const QString &caption = "", QString * dir = 0, const QString & filter = "",
                                 QString * selectedFilter = 0, const QString &defaultSuffix = "", const QString *proposedName = 0);
  static QString getSaveFolderName(QWidget* parent = 0, const QString &caption = "", QString * dir = 0, const QString & filter = "",
                                   QString * selectedFilter = 0, const QString *proposedName = 0);
  static QString getOpenFileName(QWidget* parent = 0, const QString &caption = "", QString * dir = 0, const QString & filter = "",
                                 QString * selectedFilter = 0);
  static QStringList getOpenFileNames(QWidget* parent = 0, const QString &caption = "", QString * dir = 0, const QString & filter = "",
                                      QString * selectedFilter = 0);
  static QString getExistingDirectory(QWidget* parent = 0, const QString &caption = "", QString * dir = 0);
  static void setLastOpenDirectory(QString lastOpenDirectory);
  static QString getLastOpenDirectory();
  static QStringList getAnnotation(QString componentAnnotation, QString annotationName);
  static QString getPlacementAnnotation(QString componentAnnotation);
  static qreal getNormalizedAngle(qreal angle);
  static QStringList splitStringWithSpaces(QString value);
  static void fillEncodingComboBox(QComboBox *pEncodingComboBox);
  static QStringList makeVariableParts(QString variable);
  static QStringList makeVariablePartsWithInd(QString variable);
  static bool naturalSort(const QString &s1, const QString &s2);
#ifdef WIN32
  static QProcessEnvironment simulationProcessEnvironment();
#endif
  static StringHandler::SimulationMessageType getSimulationMessageType(QString type);
  static QString getSimulationMessageTypeString(StringHandler::SimulationMessageType type);
  static QColor getSimulationMessageTypeColor(StringHandler::SimulationMessageType type);
  static QString makeClassNameRelative(QString draggedClassName, QString droppedClassName);
  static QString toCamelCase(QString str);
  static QMap<int, int> getLeadingSpaces(QString contents);
  static int getLeadingSpacesSize(QString str);
  static bool isFileWritAble(QString filePath);
  static bool containsSpace(QString str);
  static QString trimmedEnd(const QString &str);
  static QString joinDerivativeAndPreviousVariable(QString fullVariableName, QString variableName, QString derivativeOrPrevious);
  static QString removeLeadingSpaces(QString contents);
  static QString removeLine(QString text, QString lineToRemove);
  static QString insertClassAtPosition(QString parentClassText, QString childClassText, int linePosition, int nestedLevel);
protected:
  static QString mLastOpenDir;
};

#endif // STRINGHANDLER_H
