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
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENT'S CHOICE.
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

#include "ArrayParameterEditor.h"
#include "Util.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Element/Element.h"
#include "Element/ElementProperties.h"

#include <QLineEdit>
#include <QSpinBox>
#include <QTableWidget>

OMEDITTEST_MAIN(ArrayParameterEditor)

static QStringList unconstrainedDimensions(int rank)
{
  QStringList dimensions;
  for (int i = 0; i < rank; ++i) {
    dimensions.append(":");
  }
  return dimensions;
}

void ArrayParameterEditor::initTestCase()
{
  const QString fileName = QFINDTESTDATA("ArrayParameterEditor.mo");
  MainWindow::instance()->getLibraryWidget()->openFile(fileName);
  if (!MainWindow::instance()->getOMCProxy()->existClass("ArrayParameterEditor.System")) {
    QFAIL(QString("Failed to load file %1").arg(fileName).toStdString().c_str());
  }
}

void ArrayParameterEditor::arrayEditorButtonExistsForArrayParameters()
{
  LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem("ArrayParameterEditor.System");
  QVERIFY(pLibraryTreeItem);
  MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  QVERIFY(pModelWidget);
  GraphicsView *pDiagramGraphicsView = pModelWidget->getDiagramGraphicsView();
  QVERIFY(pDiagramGraphicsView);
  Element *pComponent = pDiagramGraphicsView->getElementObject("component");
  QVERIFY(pComponent);
  ModelInstance::Component *pComponentModel = pComponent->getModelComponent();
  QVERIFY(pComponentModel);
  /* Create the ElementParameters dialog without exec() so that no dialog is shown. */
  ElementParameters *pElementParameters = new ElementParameters(pComponentModel, pDiagramGraphicsView, false, false, false, 0, 0, 0, MainWindow::instance());
  Parameter *pMatrixParameter = pElementParameters->findParameter("matrix");
  QVERIFY(pMatrixParameter);
  QVERIFY(pMatrixParameter->getArrayEditorButton());
  Parameter *pIntegerMatrixParameter = pElementParameters->findParameter("integerMatrix");
  QVERIFY(pIntegerMatrixParameter);
  QVERIFY(pIntegerMatrixParameter->getArrayEditorButton());
  Parameter *pEmptyMatrixParameter = pElementParameters->findParameter("emptyMatrix");
  QVERIFY(pEmptyMatrixParameter);
  QVERIFY(pEmptyMatrixParameter->getArrayEditorButton());
  Parameter *pMatrixBracketsParameter = pElementParameters->findParameter("matrixBrackets");
  QVERIFY(pMatrixBracketsParameter);
  QVERIFY(pMatrixBracketsParameter->getArrayEditorButton());
  Parameter *pMatrixBracesParameter = pElementParameters->findParameter("matrixBraces");
  QVERIFY(pMatrixBracesParameter);
  QVERIFY(pMatrixBracesParameter->getArrayEditorButton());
  Parameter *pVectorBracketsParameter = pElementParameters->findParameter("vectorBrackets");
  QVERIFY(pVectorBracketsParameter);
  QVERIFY(pVectorBracketsParameter->getArrayEditorButton());
  Parameter *pVectorBracesParameter = pElementParameters->findParameter("vectorBraces");
  QVERIFY(pVectorBracesParameter);
  QVERIFY(pVectorBracesParameter->getArrayEditorButton());
  Parameter *pArray3DParameter = pElementParameters->findParameter("array3D");
  QVERIFY(pArray3DParameter);
  QVERIFY(pArray3DParameter->getArrayEditorButton());
  Parameter *pArray3DDynamicParameter = pElementParameters->findParameter("array3DDynamic");
  QVERIFY(pArray3DDynamicParameter);
  QVERIFY(pArray3DDynamicParameter->getArrayEditorButton());
  Parameter *pScalarParameter = pElementParameters->findParameter("scalar");
  QVERIFY(pScalarParameter);
  QVERIFY(!pScalarParameter->getArrayEditorButton());
  delete pElementParameters;
}

void ArrayParameterEditor::arrayParameterEditorDialogSerializesArrayLiterals()
{
  // matrix literal {{1, 2}, {3, 4}}
  ArrayParameterEditorDialog matrixDialog("{{1, 2}, {3, 4}}", "{{1, 2}, {3, 4}}", "table",
                                          unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pTable = matrixDialog.findChild<QTableWidget*>();
  QVERIFY(pTable);
  QCOMPARE(pTable->rowCount(), 2);
  QCOMPARE(pTable->columnCount(), 2);
  QCOMPARE(pTable->item(0, 0)->text(), QString("1"));
  QCOMPARE(pTable->item(0, 1)->text(), QString("2"));
  QCOMPARE(pTable->item(1, 0)->text(), QString("3"));
  QCOMPARE(pTable->item(1, 1)->text(), QString("4"));

  pTable->item(1, 1)->setText("9");
  QVERIFY(QMetaObject::invokeMethod(&matrixDialog, "okClicked"));
  // serialization uses compact curly brace syntax
  QCOMPARE(matrixDialog.getArrayValue(), QString("{{1,2},{3,9}}"));

  // vector literal {1, 2, 3} with an empty cell
  ArrayParameterEditorDialog vectorDialog("{1, 2, 3}", "{1, 2, 3}", "table",
                                          unconstrainedDimensions(1), unconstrainedDimensions(1), MainWindow::instance());
  QTableWidget *pVectorTable = vectorDialog.findChild<QTableWidget*>();
  QVERIFY(pVectorTable);
  QCOMPARE(pVectorTable->rowCount(), 3);
  QCOMPARE(pVectorTable->columnCount(), 1);
  pVectorTable->item(1, 0)->setText("");
  QVERIFY(QMetaObject::invokeMethod(&vectorDialog, "okClicked"));
  QCOMPARE(vectorDialog.getArrayValue(), QString("{1,0,3}"));

  // vector literal {1, 2, 3}
  ArrayParameterEditorDialog columnDialog("{1, 2, 3}", "{1, 2, 3}", "table",
                                          unconstrainedDimensions(1), unconstrainedDimensions(1), MainWindow::instance());
  QTableWidget *pColumnTable = columnDialog.findChild<QTableWidget*>();
  QVERIFY(pColumnTable);
  QCOMPARE(pColumnTable->rowCount(), 3);
  QCOMPARE(pColumnTable->columnCount(), 1);
  QCOMPARE(pColumnTable->item(0, 0)->text(), QString("1"));
  QCOMPARE(pColumnTable->item(1, 0)->text(), QString("2"));
  QCOMPARE(pColumnTable->item(2, 0)->text(), QString("3"));

  // empty array literal [] keeps the table enabled with the default value []
  ArrayParameterEditorDialog emptyDialog("[]", "[]", "table",
                                         unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pEmptyTable = emptyDialog.findChild<QTableWidget*>();
  QVERIFY(pEmptyTable);
  QCOMPARE(pEmptyTable->rowCount(), 0);
  QCOMPARE(pEmptyTable->columnCount(), 0);
  QVERIFY(QMetaObject::invokeMethod(&emptyDialog, "okClicked"));
  // clearing the expression reverts to the default value (placeholder)
  QCOMPARE(emptyDialog.getArrayValue(), QString("[]"));

  // function calls remain raw expressions and do not need special handling.
  ArrayParameterEditorDialog functionExpressionDialog("fill(0.0, 0, 2)", "fill(0.0, 0, 2)", "table",
                                                      unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pFunctionTable = functionExpressionDialog.findChild<QTableWidget*>();
  QVERIFY(pFunctionTable);
  QCOMPARE(pFunctionTable->rowCount(), 0);
  QCOMPARE(pFunctionTable->columnCount(), 0);
  QLineEdit *pFunctionExpression = functionExpressionDialog.findChild<QLineEdit*>();
  QVERIFY(pFunctionExpression);
  QCOMPARE(pFunctionExpression->text(), QString("fill(0.0, 0, 2)"));
  QCOMPARE(pFunctionExpression->placeholderText(), QString("fill(0.0, 0, 2)"));
  QVERIFY(QMetaObject::invokeMethod(&functionExpressionDialog, "okClicked"));
  QCOMPARE(functionExpressionDialog.getArrayValue(), QString("fill(0.0, 0, 2)"));

  ArrayParameterEditorDialog rawDialog("x", "x", "table",
                                       unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pRawTable = rawDialog.findChild<QTableWidget*>();
  QVERIFY(pRawTable);
  QCOMPARE(pRawTable->rowCount(), 0);
  QCOMPARE(pRawTable->columnCount(), 0);
  QLineEdit *pRawExpression = rawDialog.findChild<QLineEdit*>();
  QVERIFY(pRawExpression);
  QCOMPARE(pRawExpression->text(), QString("x"));
  QCOMPARE(pRawExpression->placeholderText(), QString("x"));
  pRawExpression->setText("2:size(table, 2)");
  QVERIFY(QMetaObject::invokeMethod(&rawDialog, "expressionTextEdited", Q_ARG(QString, pRawExpression->text())));
  QCOMPARE(pRawExpression->text(), QString("2:size(table, 2)"));
  QVERIFY(QMetaObject::invokeMethod(&rawDialog, "okClicked"));
  QCOMPARE(rawDialog.getArrayValue(), QString("2:size(table, 2)"));
}

void ArrayParameterEditor::arrayParameterEditorDialogParsesCurlyBraces()
{
  // vector literal {1, 2, 3}
  ArrayParameterEditorDialog vectorDialog("{1, 2, 3}", "{1, 2, 3}", "table",
                                          unconstrainedDimensions(1), unconstrainedDimensions(1), MainWindow::instance());
  QTableWidget *pVectorTable = vectorDialog.findChild<QTableWidget*>();
  QVERIFY(pVectorTable);
  QCOMPARE(pVectorTable->rowCount(), 3);
  QCOMPARE(pVectorTable->columnCount(), 1);
  QCOMPARE(pVectorTable->item(0, 0)->text(), QString("1"));
  QCOMPARE(pVectorTable->item(1, 0)->text(), QString("2"));
  QCOMPARE(pVectorTable->item(2, 0)->text(), QString("3"));

  // matrix literal {{1, 2}, {3, 4}}
  ArrayParameterEditorDialog matrixDialog("{{1, 2}, {3, 4}}", "{{1, 2}, {3, 4}}", "table",
                                          unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pTable = matrixDialog.findChild<QTableWidget*>();
  QVERIFY(pTable);
  QCOMPARE(pTable->rowCount(), 2);
  QCOMPARE(pTable->columnCount(), 2);
  QCOMPARE(pTable->item(0, 0)->text(), QString("1"));
  QCOMPARE(pTable->item(0, 1)->text(), QString("2"));
  QCOMPARE(pTable->item(1, 0)->text(), QString("3"));
  QCOMPARE(pTable->item(1, 1)->text(), QString("4"));

  // serialization uses compact curly brace syntax
  QVERIFY(QMetaObject::invokeMethod(&matrixDialog, "okClicked"));
  // no cell was edited so the expression reverts to the default value (placeholder)
  QCOMPARE(matrixDialog.getArrayValue(), QString("{{1, 2}, {3, 4}}"));

  // matrix loaded then edited
  ArrayParameterEditorDialog mixedDialog("{{1, 2, 3}, {4, 5, 6}}", "{{1, 2, 3}, {4, 5, 6}}", "table",
                                         unconstrainedDimensions(2), unconstrainedDimensions(2), MainWindow::instance());
  QTableWidget *pMixedTable = mixedDialog.findChild<QTableWidget*>();
  QVERIFY(pMixedTable);
  QCOMPARE(pMixedTable->rowCount(), 2);
  QCOMPARE(pMixedTable->columnCount(), 3);
  pMixedTable->item(1, 2)->setText("9");
  QVERIFY(QMetaObject::invokeMethod(&mixedDialog, "okClicked"));
  QCOMPARE(mixedDialog.getArrayValue(), QString("{{1,2,3},{4,5,9}}"));
}

void ArrayParameterEditor::arrayDimensionsConstrainEditorShape()
{
  ArrayParameterEditorDialog threeDimensionalDialog("", "", "f",
                                                   QStringList() << "2" << "3" << "2",
                                                   QStringList() << "2" << "3" << "2", MainWindow::instance());
  QTableWidget *pThreeDimensionalTable = threeDimensionalDialog.findChild<QTableWidget*>();
  QVERIFY(pThreeDimensionalTable);
  QCOMPARE(pThreeDimensionalTable->rowCount(), 2);
  QCOMPARE(pThreeDimensionalTable->columnCount(), 3);
  QCOMPARE(pThreeDimensionalTable->item(0, 0)->text(), QString("{0,0}"));

  ArrayParameterEditorDialog fourDimensionalDialog("", "", "g",
                                                   QStringList() << "2" << "3" << "2" << "3",
                                                   QStringList() << "2" << "3" << "2" << "3", MainWindow::instance());
  QTableWidget *pFourDimensionalTable = fourDimensionalDialog.findChild<QTableWidget*>();
  QVERIFY(pFourDimensionalTable);
  QCOMPARE(pFourDimensionalTable->rowCount(), 2);
  QCOMPARE(pFourDimensionalTable->columnCount(), 3);
  const QString defaultFourDimensionalCell = "{{0.0,0.0,0.0},{0.0,0.0,0.0}}";
  QCOMPARE(pFourDimensionalTable->item(0, 0)->text(), defaultFourDimensionalCell);
  QCOMPARE(pFourDimensionalTable->item(1, 2)->text(), defaultFourDimensionalCell);

  const QString matrix = "{{1, 2, 3}, {4, 5, 6}}";
  ArrayParameterEditorDialog literalDimensions(matrix, matrix, "table",
                                               QStringList() << "2" << "3", QStringList() << "2" << "3",
                                               MainWindow::instance());
  QList<QSpinBox*> spinBoxes = literalDimensions.findChildren<QSpinBox*>();
  QCOMPARE(spinBoxes.size(), 2);
  QCOMPARE(spinBoxes.at(0)->value(), 2);
  QCOMPARE(spinBoxes.at(1)->value(), 3);
  QVERIFY(!spinBoxes.at(0)->isEnabled());
  QVERIFY(!spinBoxes.at(1)->isEnabled());

  ArrayParameterEditorDialog variableDimension(matrix, matrix, "table",
                                               QStringList() << "n" << ":", QStringList() << "2" << "3",
                                               MainWindow::instance());
  spinBoxes = variableDimension.findChildren<QSpinBox*>();
  QCOMPARE(spinBoxes.at(0)->value(), 2);
  QCOMPARE(spinBoxes.at(1)->value(), 3);
  QVERIFY(!spinBoxes.at(0)->isEnabled());
  QVERIFY(spinBoxes.at(1)->isEnabled());

  ArrayParameterEditorDialog colonDimensions(matrix, matrix, "table",
                                             QStringList() << ":" << ":", QStringList() << "2" << "3",
                                             MainWindow::instance());
  spinBoxes = colonDimensions.findChildren<QSpinBox*>();
  QVERIFY(spinBoxes.at(0)->isEnabled());
  QVERIFY(spinBoxes.at(1)->isEnabled());

  const QString vector = "{1, 2, 3}";
  ArrayParameterEditorDialog vectorDialog(vector, vector, "vector",
                                          QStringList() << "3", QStringList() << "3", MainWindow::instance());
  QTableWidget *pVectorTable = vectorDialog.findChild<QTableWidget*>();
  QVERIFY(pVectorTable);
  QCOMPARE(pVectorTable->rowCount(), 3);
  QCOMPARE(pVectorTable->columnCount(), 1);
  spinBoxes = vectorDialog.findChildren<QSpinBox*>();
  QCOMPARE(spinBoxes.at(0)->value(), 3);
  QVERIFY(!spinBoxes.at(0)->isEnabled());
  QVERIFY(spinBoxes.at(1)->isHidden());
  pVectorTable->item(2, 0)->setText("4");
  QVERIFY(QMetaObject::invokeMethod(&vectorDialog, "okClicked"));
  QCOMPARE(vectorDialog.getArrayValue(), QString("{1,2,4}"));

  ArrayParameterEditorDialog vectorExpressionDialog("2:size(table, 2)", "2:size(table, 2)", "columns",
                                                    QStringList() << ":", QStringList() << ":", MainWindow::instance());
  QTableWidget *pVectorExpressionTable = vectorExpressionDialog.findChild<QTableWidget*>();
  QVERIFY(pVectorExpressionTable);
  QCOMPARE(pVectorExpressionTable->rowCount(), 0);
  QCOMPARE(pVectorExpressionTable->columnCount(), 1);
  QList<QSpinBox*> vectorSpinBoxes = vectorExpressionDialog.findChildren<QSpinBox*>();
  vectorSpinBoxes.at(0)->setValue(2);
  QCOMPARE(pVectorExpressionTable->rowCount(), 2);
  QCOMPARE(pVectorExpressionTable->columnCount(), 1);
  pVectorExpressionTable->item(0, 0)->setText("2");
  QVERIFY(QMetaObject::invokeMethod(&vectorExpressionDialog, "okClicked"));
  QCOMPARE(vectorExpressionDialog.getArrayValue(), QString("{2,0}"));
}

void ArrayParameterEditor::arrayTableContextMenuDeletesSelection()
{
  ArrayParameterEditorDialog rowDialog("{{1, 2}, {3, 4}, {5, 6}}", "", "table",
                                       QStringList() << ":" << ":", QStringList() << "3" << "2", MainWindow::instance());
  QTableWidget *pRowTable = rowDialog.findChild<QTableWidget*>();
  QVERIFY(pRowTable);
  pRowTable->setRangeSelected(QTableWidgetSelectionRange(1, 0, 1, 1), true);
  QVERIFY(QMetaObject::invokeMethod(&rowDialog, "deleteSelectedRows"));
  QCOMPARE(pRowTable->rowCount(), 2);
  QVERIFY(QMetaObject::invokeMethod(&rowDialog, "okClicked"));
  QCOMPARE(rowDialog.getArrayValue(), QString("{{1,2},{5,6}}"));

  ArrayParameterEditorDialog columnDialog("{{1, 2, 3}, {4, 5, 6}}", "", "table",
                                          QStringList() << ":" << ":", QStringList() << "2" << "3", MainWindow::instance());
  QTableWidget *pColumnTable = columnDialog.findChild<QTableWidget*>();
  QVERIFY(pColumnTable);
  pColumnTable->setRangeSelected(QTableWidgetSelectionRange(0, 1, 1, 1), true);
  QVERIFY(QMetaObject::invokeMethod(&columnDialog, "deleteSelectedColumns"));
  QCOMPARE(pColumnTable->columnCount(), 2);
  QVERIFY(QMetaObject::invokeMethod(&columnDialog, "okClicked"));
  QCOMPARE(columnDialog.getArrayValue(), QString("{{1,3},{4,6}}"));
}

void ArrayParameterEditor::arrayParameterEditorDialogHandlesThreeDimensionalArray()
{
  // a 3D array literal is shown as a 2D table where each cell holds a nested vector
  ArrayParameterEditorDialog dialog3D("{{{1, 7}, {2, 8}, {3, 9}}, {{4, 10}, {5, 11}, {6, 12}}}",
                                      "{{{1, 7}, {2, 8}, {3, 9}}, {{4, 10}, {5, 11}, {6, 12}}}", "table",
                                      unconstrainedDimensions(3), unconstrainedDimensions(3), MainWindow::instance());
  QTableWidget *pTable = dialog3D.findChild<QTableWidget*>();
  QVERIFY(pTable);
  QCOMPARE(pTable->rowCount(), 2);
  QCOMPARE(pTable->columnCount(), 3);
  QCOMPARE(pTable->item(0, 0)->text(), QString("{1,7}"));
  QCOMPARE(pTable->item(0, 1)->text(), QString("{2,8}"));
  QCOMPARE(pTable->item(0, 2)->text(), QString("{3,9}"));
  QCOMPARE(pTable->item(1, 0)->text(), QString("{4,10}"));
  QCOMPARE(pTable->item(1, 1)->text(), QString("{5,11}"));
  QCOMPARE(pTable->item(1, 2)->text(), QString("{6,12}"));

  // serialization recreates the nested 3D literal
  QVERIFY(QMetaObject::invokeMethod(&dialog3D, "okClicked"));
  QCOMPARE(dialog3D.getArrayValue(),
           QString("{{{1, 7}, {2, 8}, {3, 9}}, {{4, 10}, {5, 11}, {6, 12}}}"));
}

void ArrayParameterEditor::cleanupTestCase()
{
  MainWindow::instance()->close();
}
