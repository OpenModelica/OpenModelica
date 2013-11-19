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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "TransformationsWidget.h"

TransformationsWidget::TransformationsWidget(MainWindow *pMainWindow)
  : QWidget(pMainWindow)
{
  mpMainWindow = pMainWindow;
  mpInfoXMLFileHandler = 0;
  // create the previous button
  mpPreviousToolButton = new QToolButton;
  mpPreviousToolButton->setText(Helper::previous);
  mpPreviousToolButton->setIcon(QIcon(":/Resources/icons/previous.png"));
  mpPreviousToolButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  mpPreviousToolButton->setDisabled(true);
//  connect(mpPreviousToolButton, SIGNAL(clicked()), SLOT(previousDocumentation()));
  // create the next button
  mpNextToolButton = new QToolButton;
  mpNextToolButton->setText(Helper::next);
  mpNextToolButton->setIcon(QIcon(":/Resources/icons/next.png"));
  mpNextToolButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  mpNextToolButton->setDisabled(true);
//  connect(mpNextToolButton, SIGNAL(clicked()), SLOT(nextDocumentation()));
  /* info xml file path label */
  mpInfoXMLFilePathLabel = new Label;
  /* create the stacked widget object */
  mpPagesWidget = new QStackedWidget;
  mpPagesWidget->addWidget(new TransformationPage(this));
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpPreviousToolButton, 0, 0);
  pMainLayout->addWidget(mpNextToolButton, 0, 1);
  pMainLayout->addWidget(mpInfoXMLFilePathLabel, 0, 2);
  pMainLayout->addWidget(mpPagesWidget, 1, 0, 1, 3);
  setLayout(pMainLayout);
}

void TransformationsWidget::showTransformations(QString fileName)
{
  /* create the info xml handler */
  if (mpInfoXMLFileHandler)
    delete mpInfoXMLFileHandler;
  QFile file(fileName);
  mpInfoXMLFileHandler = new MyHandler(file);
  mpInfoXMLFilePathLabel->setText(fileName);
  /* clear the pages */
  for (int i = 0 ; i < mpPagesWidget->count() ; i++)
  {
    QWidget *pWidget = mpPagesWidget->widget(i);
    mpPagesWidget->removeWidget(pWidget);
    delete pWidget;
  }
  /* create a TransformationPage and add it to the stacked pages */
  TransformationPage *pTransformationPage = new TransformationPage(this);
  pTransformationPage->initialize();
  mpPagesWidget->addWidget(pTransformationPage);
}

TransformationPage::TransformationPage(TransformationsWidget *pTransformationsWidget)
  : QWidget(pTransformationsWidget)
{
  mpTransformationsWidget = pTransformationsWidget;
  /* variables tree widget */
  Label *pVariablesLabel = new Label(Helper::variables);
  mpVariablesTreeWidget = new QTreeWidget;
  mpVariablesTreeWidget->setItemDelegate(new ItemDelegate(mpVariablesTreeWidget));
  mpVariablesTreeWidget->setObjectName("VariablesTree");
  mpVariablesTreeWidget->setIndentation(0);
  mpVariablesTreeWidget->setColumnCount(2);
  mpVariablesTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpVariablesTreeWidget->setSortingEnabled(true);
  QStringList headerLabels;
  headerLabels << tr("Variable") << tr("Comment");
  mpVariablesTreeWidget->setHeaderLabels(headerLabels);
  connect(mpVariablesTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(fetchTypesDefinedInAndUsedIn(QTreeWidgetItem*,int)));
  QGridLayout *pVariablesGridLayout = new QGridLayout;
  pVariablesGridLayout->setContentsMargins(0, 0, 0, 0);
  pVariablesGridLayout->addWidget(pVariablesLabel, 0, 0);
  pVariablesGridLayout->addWidget(mpVariablesTreeWidget, 1, 0);
  QFrame *pVariablesFrame = new QFrame;
  pVariablesFrame->setLayout(pVariablesGridLayout);
  /* types tree widget */
  Label *pTypesLabel = new Label(tr("Variable Types"));
  mpTypesTreeWidget = new QTreeWidget;
  mpTypesTreeWidget->setItemDelegate(new ItemDelegate(mpTypesTreeWidget));
  mpTypesTreeWidget->setObjectName("TypesTree");
  mpTypesTreeWidget->setIndentation(Helper::treeIndentation);
  mpTypesTreeWidget->setColumnCount(1);
  mpTypesTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpTypesTreeWidget->setSortingEnabled(true);
  mpTypesTreeWidget->setHeaderLabel(tr("Types"));
  QGridLayout *pTypesGridLayout = new QGridLayout;
  pTypesGridLayout->setContentsMargins(0, 0, 0, 0);
  pTypesGridLayout->addWidget(pTypesLabel, 0, 0);
  pTypesGridLayout->addWidget(mpTypesTreeWidget, 1, 0);
  QFrame *pTypesFrame = new QFrame;
  pTypesFrame->setLayout(pTypesGridLayout);
  /* Defined in tree widget */
  Label *pDefinedInLabel = new Label(tr("Defined In Equations"));
  mpDefinedInTreeWidget = new QTreeWidget;
  mpDefinedInTreeWidget->setItemDelegate(new ItemDelegate(mpDefinedInTreeWidget));
  mpDefinedInTreeWidget->setObjectName("DefinedInTree");
  mpDefinedInTreeWidget->setIndentation(Helper::treeIndentation);
  mpDefinedInTreeWidget->setColumnCount(3);
  mpDefinedInTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDefinedInTreeWidget->setSortingEnabled(true);
  headerLabels.clear();
  headerLabels << Helper::index << Helper::type << Helper::equation;
  mpDefinedInTreeWidget->setHeaderLabels(headerLabels);
  QGridLayout *pDefinedInGridLayout = new QGridLayout;
  pDefinedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pDefinedInGridLayout->addWidget(pDefinedInLabel, 0, 0);
  pDefinedInGridLayout->addWidget(mpDefinedInTreeWidget, 1, 0);
  QFrame *pDefinedInFrame = new QFrame;
  pDefinedInFrame->setLayout(pDefinedInGridLayout);
  /* Used in tree widget  */
  Label *pUsedInLabel = new Label(tr("Used In Equations"));
  mpUsedInTreeWidget = new QTreeWidget;
  mpUsedInTreeWidget->setItemDelegate(new ItemDelegate(mpUsedInTreeWidget));
  mpUsedInTreeWidget->setObjectName("UsedInTree");
  mpUsedInTreeWidget->setIndentation(Helper::treeIndentation);
  mpUsedInTreeWidget->setColumnCount(3);
  mpUsedInTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpUsedInTreeWidget->setSortingEnabled(true);
  headerLabels.clear();
  headerLabels << Helper::index << Helper::type << Helper::equation;
  mpUsedInTreeWidget->setHeaderLabels(headerLabels);
  QGridLayout *pUsedInGridLayout = new QGridLayout;
  pUsedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pUsedInGridLayout->addWidget(pUsedInLabel, 0, 0);
  pUsedInGridLayout->addWidget(mpUsedInTreeWidget, 1, 0);
  QFrame *pUsedInFrame = new QFrame;
  pUsedInFrame->setLayout(pUsedInGridLayout);
  /* splitter */
  QSplitter *pSplitter = new QSplitter;
  pSplitter->setChildrenCollapsible(false);
  pSplitter->setHandleWidth(4);
  pSplitter->setContentsMargins(0, 0, 0, 0);
  pSplitter->addWidget(pVariablesFrame);
  pSplitter->addWidget(pTypesFrame);
  pSplitter->addWidget(pDefinedInFrame);
  pSplitter->addWidget(pUsedInFrame);
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSplitter, 0, 0);
  setLayout(pMainLayout);
}

void TransformationPage::initialize()
{
  QHashIterator<QString, OMVariable> variables(mpTransformationsWidget->getInfoXMLFileHandler()->variables);
  while (variables.hasNext())
  {
    variables.next();
    OMVariable variable = variables.value();
    QStringList values;
    values << variable.name << variable.comment;
    QTreeWidgetItem *pVariableTreeItem = new QTreeWidgetItem(values);
    pVariableTreeItem->setToolTip(0, variable.name);
    pVariableTreeItem->setToolTip(1, variable.comment);
    mpVariablesTreeWidget->addTopLevelItem(pVariableTreeItem);
  }
}

void TransformationPage::fetchTypes(OMVariable &variable)
{
  /* Clear the types tree. */
  int i = 0;
  while(i < mpTypesTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpTypesTreeWidget->topLevelItem(i)->takeChildren());
    delete mpTypesTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add varibale types */
  QTreeWidgetItem *pTypesTreeItem = 0;
  for (int i = 1; i < variable.types.size() ; i++)
  {
    QStringList values;
    values << variable.types.value(i);
    QString toolTip = variable.types.value(i);
    if (pTypesTreeItem)
    {
      QTreeWidgetItem *pParentTypesTreeItem = pTypesTreeItem;
      pTypesTreeItem = new QTreeWidgetItem(values);
      pTypesTreeItem->setToolTip(0, toolTip);
      pParentTypesTreeItem->addChild(pTypesTreeItem);
    }
    else
    {
      pTypesTreeItem = new QTreeWidgetItem(values);
      pTypesTreeItem->setToolTip(0, toolTip);
      mpTypesTreeWidget->addTopLevelItem(pTypesTreeItem);
    }
  }
}

void TransformationPage::fetchDefinedInEquations(OMVariable &variable)
{
  /* Clear the defined in tree. */
  int i = 0;
  while(i < mpDefinedInTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpDefinedInTreeWidget->topLevelItem(i)->takeChildren());
    delete mpDefinedInTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add defined in equations */
  for (int i = 0; i < equationTypeSize; i++)
  {
    if (variable.definedIn[i])
    {
      OMEquation equation = mpTransformationsWidget->getInfoXMLFileHandler()->getOMEquation(variable.definedIn[i]);
      QStringList values;
      values << QString::number(variable.definedIn[i]) << OMEquationTypeToString(i) << equation.toString();
      QTreeWidgetItem *pDefinedInTreeItem = new QTreeWidgetItem(values);
      pDefinedInTreeItem->setToolTip(0, values[0]);
      pDefinedInTreeItem->setToolTip(1, values[1]);
      pDefinedInTreeItem->setToolTip(2, values[2]);
      mpDefinedInTreeWidget->addTopLevelItem(pDefinedInTreeItem);
    }
  }
}

void TransformationPage::fetchUsedInEquations(OMVariable &variable)
{
  /* Clear the used in tree. */
  int i = 0;
  while(i < mpUsedInTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpUsedInTreeWidget->topLevelItem(i)->takeChildren());
    delete mpUsedInTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add used in equations */
  for (int i = 0; i < equationTypeSize; i++)
  {
    foreach (int index, variable.usedIn[i])
    {
      OMEquation equation = mpTransformationsWidget->getInfoXMLFileHandler()->getOMEquation(index);
      QStringList values;
      values << QString::number(index) << OMEquationTypeToString(i) << equation.toString();
      QTreeWidgetItem *pUsedInTreeItem = new QTreeWidgetItem(values);
      pUsedInTreeItem->setToolTip(0, values[0]);
      pUsedInTreeItem->setToolTip(1, values[1]);
      pUsedInTreeItem->setToolTip(2, values[2]);
      mpUsedInTreeWidget->addTopLevelItem(pUsedInTreeItem);
    }
  }
}

void TransformationPage::fetchTypesDefinedInAndUsedIn(QTreeWidgetItem *pVariableTreeItem, int column)
{
  Q_UNUSED(column);
  if (!pVariableTreeItem)
    return;
  /* fetch types */
  QString variableName = pVariableTreeItem->text(0);
  OMVariable variable = mpTransformationsWidget->getInfoXMLFileHandler()->variables.value(variableName);
  fetchTypes(variable);
  /* fetch defined in equations */
  fetchDefinedInEquations(variable);
  /* fetch used in equations */
  fetchUsedInEquations(variable);
}
