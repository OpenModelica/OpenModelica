/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef STRINGHANDLER_H
#define STRINGHANDLER_H

#include <QtCore>
#include <QtGui>

class StringHandler : public QObject
{
  Q_OBJECT
public:
  StringHandler();
  ~StringHandler();
  enum ViewType {Icon, Diagram, ModelicaText, NoView};
  enum ModelicaClasses {Model, Class, Connector, ExpandableConnector, Record, Block, Function, Package, Primitive, Type, Operator,
                        OperatorRecord, OperatorFunction, Optimization, Parameter, Constant, Protected};
  enum OpenModelicaErrors {Notification, Warning, OMError, NoOMError};
  static const QString errorLevelToString[NoOMError+1];
  enum OpenModelicaErrorKinds {Syntax, Grammar, Translation, Symbolic, Simulation, Scripting, NoOMErrorKind};
  enum LinePattern {LineNone, LineSolid, LineDash, LineDot, LineDashDot, LineDashDotDot};
  enum FillPattern {FillNone, FillSolid, FillHorizontal, FillVertical, FillCross, FillForward, FillBackward, FillCrossDiag,
                    FillHorizontalCylinder, FillVerticalCylinder, FillSphere};
  enum BorderPattern {BorderNone, BorderRaised, BorderSunken, BorderEngraved};
  enum Smooth {SmoothNone, SmoothBezier};
  enum Arrow {ArrowNone, ArrowOpen, ArrowFilled, ArrowHalf};
  enum TextStyle {TextStyleBold, TextStyleItalic, TextStyleUnderLine};
  enum TextAlignment {TextAlignmentLeft, TextAlignmentCenter, TextAlignmentRight};
  static QString getModelicaClassType(int type);
  static StringHandler::ModelicaClasses getModelicaClassType(QString type);
  static QString getViewType(int type);
  static QString getErrorKind(int kind);
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
  static QString removeFirstLastBrackets(QString value);
  static QString removeFirstLastQuotes(QString value);
  static QString getSubStringFromDots(QString value);
  static QString removeLastDot(QString value);
  static QStringList getStrings(QString value);
  static QStringList getStrings(QString value, char start, char end);
  static QString getLastWordAfterDot(QString value);
  static QString getFirstWordBeforeDot(QString value);
  static QString removeLastSlashWord(QString value);
  /* Handles quoted identifiers A.B.'C.D' -> A.B, A.B.C.D -> A.B.C */
  static QString removeLastWordAfterDot(QString value);
  static QString removeComment(QString value);
  static QString getModifierValue(QString value);
  static QString escapeString(QString value);
  // Returns "" if the string is not a standard Modelica string. Else it unparses it into normal form.
  static QString unparse(QString value);
  // Returns empty list if the string is not a standard Modelica string-array. Else it unparses it into normal form.
  static QStringList unparseStrings(QString value);
  // Returns empty list if the string is not a standard Modelica array. Else it unparses it into normal form.
  static QStringList unparseArrays(QString value);
  // Returns false on failure
  static bool unparseBool(QString value);
  static QString getSaveFileName(QWidget* parent = 0, const QString &caption = QString(), QString * dir = 0, const QString & filter = QString(),
                                 QString * selectedFilter = 0, const QString &defaultSuffix = QString(), const QString *purposedName = 0);
  static QString getOpenFileName(QWidget* parent = 0, const QString &caption = QString(), QString * dir = 0, const QString & filter = QString(),
                                 QString * selectedFilter = 0);
  static QStringList getOpenFileNames(QWidget* parent = 0, const QString &caption = QString(), QString * dir = 0, const QString & filter = QString(),
                                 QString * selectedFilter = 0);
  static QString getExistingDirectory(QWidget* parent = 0, const QString &caption = QString(), QString * dir = 0);
  static QString createTooltip(QStringList info, QString name, QString path);
  static QString createTooltip(QString name, QString location);
  static void setLastOpenDirectory(QString lastOpenDirectory);
  static QString getLastOpenDirectory();
  static QStringList getDialogAnnotation(QString componentAnnotation);
  static QString getPlacementAnnotation(QString componentAnnotation);
  static qreal getNormalizedAngle(qreal angle);
  static QStringList splitStringWithSpaces(QString value);
  static void fillEncodingComboBox(QComboBox *pEncodingComboBox);
  static QStringList makeVariableParts(QString variable);
  static bool isCFile(QString extension);
  static bool isModelicaFile(QString extension);
protected:
  static QString mLastOpenDir;
};

#endif // STRINGHANDLER_H
