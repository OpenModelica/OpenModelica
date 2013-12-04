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
  connect(mpPreviousToolButton, SIGNAL(clicked()), SLOT(previousPage()));
  // create the next button
  mpNextToolButton = new QToolButton;
  mpNextToolButton->setText(Helper::next);
  mpNextToolButton->setIcon(QIcon(":/Resources/icons/next.png"));
  mpNextToolButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
  connect(mpNextToolButton, SIGNAL(clicked()), SLOT(nextPage()));
  /* info xml file path label */
  mpInfoXMLFilePathLabel = new Label;
  /* create the stacked widget object */
  mpPagesWidget = new QStackedWidget;
  mpPagesWidget->addWidget(new VariablePage(this));
  mpInfoTextBox = new QPlainTextEdit;
  mpInfoTextBox->setFont(QFont(Helper::monospacedFontInfo.family()));
  /* set the layout */
  QGridLayout *pTopLayout = new QGridLayout;
  pTopLayout->setContentsMargins(0, 0, 0, 0);
  pTopLayout->addWidget(mpPreviousToolButton, 0, 0);
  pTopLayout->addWidget(mpNextToolButton, 0, 1);
  pTopLayout->addWidget(mpInfoXMLFilePathLabel, 0, 2);
  pTopLayout->addWidget(mpPagesWidget, 1, 0, 1, 3);
  QFrame *pTopFrame = new QFrame;
  pTopFrame->setLayout(pTopLayout);
  /* splitter */
  QSplitter *pSplitter = new QSplitter;
  pSplitter->setOrientation(Qt::Vertical);
  pSplitter->setChildrenCollapsible(false);
  pSplitter->setHandleWidth(4);
  pSplitter->setContentsMargins(0, 0, 0, 0);
  pSplitter->addWidget(pTopFrame);
  pSplitter->addWidget(mpInfoTextBox);
  QList<int> sizes;
  sizes << pTopFrame->height() << 50;
  pSplitter->setSizes(sizes);
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSplitter, 0, 0);
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
  int i = 0;
  while(i < mpPagesWidget->count())
  {
    QWidget *pWidget = mpPagesWidget->widget(i);
    mpPagesWidget->removeWidget(pWidget);
    delete pWidget;
    i = 0;   //Restart iteration
  }
  /* create a VariablePage and add it to the stacked pages */
  mpVariablePage = new VariablePage(this);
  mpVariablePage->initialize();
  mpPagesWidget->addWidget(mpVariablePage);
  mpEquationPage = new EquationPage(this);
  mpPagesWidget->addWidget(mpEquationPage);
}

void TransformationsWidget::showInfoText(QString message)
{
  mpInfoTextBox->setPlainText(message);
}

void TransformationsWidget::previousPage()
{
  int index = mpPagesWidget->currentIndex();
  if (index <= 0)
    return;
  mpPagesWidget->setCurrentIndex(--index);
}

void TransformationsWidget::nextPage()
{
  int index = mpPagesWidget->currentIndex();
  if (index >= mpPagesWidget->count())
    return;
  mpPagesWidget->setCurrentIndex(++index);
}

VariablePage::VariablePage(TransformationsWidget *pTransformationsWidget)
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
  mpVariablesTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  QStringList headerLabels;
  headerLabels << tr("Variable") << tr("Comment");
  mpVariablesTreeWidget->setHeaderLabels(headerLabels);
  connect(mpVariablesTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(fetchVariableData(QTreeWidgetItem*,int)));
  connect(mpVariablesTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(variablesItemChanged(QTreeWidgetItem*)));
  connect(mpVariablesTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(variablesItemChanged(QTreeWidgetItem*)));
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
  mpTypesTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  mpTypesTreeWidget->setHeaderLabel(tr("Types"));
  connect(mpTypesTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(typesItemChanged(QTreeWidgetItem*)));
  connect(mpTypesTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(typesItemChanged(QTreeWidgetItem*)));
  QGridLayout *pTypesGridLayout = new QGridLayout;
  pTypesGridLayout->setContentsMargins(0, 0, 0, 0);
  pTypesGridLayout->addWidget(pTypesLabel, 0, 0);
  pTypesGridLayout->addWidget(mpTypesTreeWidget, 1, 0);
  QFrame *pTypesFrame = new QFrame;
  pTypesFrame->setLayout(pTypesGridLayout);
  /* operations tree widget */
  Label *pOperationsLabel = new Label(tr("Variable Operations"));
  mpOperationsTreeWidget = new QTreeWidget;
  mpOperationsTreeWidget->setItemDelegate(new ItemDelegate(mpOperationsTreeWidget));
  mpOperationsTreeWidget->setObjectName("VariableOperationsTree");
  mpOperationsTreeWidget->setIndentation(Helper::treeIndentation);
  mpOperationsTreeWidget->setColumnCount(1);
  mpOperationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpOperationsTreeWidget->setSortingEnabled(true);
  mpOperationsTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  mpOperationsTreeWidget->setHeaderLabel(tr("Operations"));
  connect(mpOperationsTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(operationsItemChanged(QTreeWidgetItem*)));
  connect(mpOperationsTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(operationsItemChanged(QTreeWidgetItem*)));
  QGridLayout *pOperationsGridLayout = new QGridLayout;
  pOperationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pOperationsGridLayout->addWidget(pOperationsLabel, 0, 0);
  pOperationsGridLayout->addWidget(mpOperationsTreeWidget, 1, 0);
  QFrame *pOperationsFrame = new QFrame;
  pOperationsFrame->setLayout(pOperationsGridLayout);
  /* Defined in tree widget */
  Label *pDefinedInLabel = new Label(tr("Defined In Equations"));
  mpDefinedInTreeWidget = new QTreeWidget;
  mpDefinedInTreeWidget->setItemDelegate(new ItemDelegate(mpDefinedInTreeWidget));
  mpDefinedInTreeWidget->setObjectName("DefinedInTree");
  mpDefinedInTreeWidget->setIndentation(Helper::treeIndentation);
  mpDefinedInTreeWidget->setColumnCount(3);
  mpDefinedInTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDefinedInTreeWidget->setSortingEnabled(true);
  mpDefinedInTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  headerLabels.clear();
  headerLabels << Helper::index << Helper::type << Helper::equation;
  mpDefinedInTreeWidget->setHeaderLabels(headerLabels);
  connect(mpDefinedInTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showEquation(QTreeWidgetItem*,int)));
  connect(mpDefinedInTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(definedInItemChanged(QTreeWidgetItem*)));
  connect(mpDefinedInTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(definedInItemChanged(QTreeWidgetItem*)));
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
  mpUsedInTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  headerLabels.clear();
  headerLabels << Helper::index << Helper::type << Helper::equation;
  mpUsedInTreeWidget->setHeaderLabels(headerLabels);
  connect(mpUsedInTreeWidget, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), SLOT(showEquation(QTreeWidgetItem*,int)));
  connect(mpUsedInTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(usedInItemChanged(QTreeWidgetItem*)));
  connect(mpUsedInTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(usedInItemChanged(QTreeWidgetItem*)));
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
  pSplitter->addWidget(pOperationsFrame);
  pSplitter->addWidget(pDefinedInFrame);
  pSplitter->addWidget(pUsedInFrame);
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSplitter, 0, 0);
  setLayout(pMainLayout);
}

void VariablePage::initialize()
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

void VariablePage::fetchTypes(OMVariable &variable)
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
  for (int i = 1; i < variable.types.size() ; i++)
  {
    QStringList values;
    values << variable.types.value(i);
    QString toolTip = variable.types.value(i);
    QTreeWidgetItem *pTypesTreeItem = new QTreeWidgetItem(values);
    pTypesTreeItem->setToolTip(0, toolTip);
    mpTypesTreeWidget->addTopLevelItem(pTypesTreeItem);
  }
}

void VariablePage::fetchOperations(OMVariable &variable)
{
  /* Clear the operations tree. */
  int i = 0;
  while(i < mpOperationsTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpOperationsTreeWidget->topLevelItem(i)->takeChildren());
    delete mpOperationsTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add operations */
  if (mpTransformationsWidget->getInfoXMLFileHandler()->hasOperationsEnabled)
  {
    foreach (OMOperation *op, variable.ops)
    {
      QStringList values;
      values << op->toString();
      QString toolTip = op->toString();
      QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
      pOperationTreeItem->setToolTip(0, toolTip);
      mpOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
    }
  }
  else
  {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
}

void VariablePage::fetchDefinedInEquations(OMVariable &variable)
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

void VariablePage::fetchUsedInEquations(OMVariable &variable)
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

void VariablePage::fetchVariableData(QTreeWidgetItem *pVariableTreeItem, int column)
{
  Q_UNUSED(column);
  if (!pVariableTreeItem)
    return;
  /* fetch types */
  QString variableName = pVariableTreeItem->text(0);
  OMVariable variable = mpTransformationsWidget->getInfoXMLFileHandler()->variables.value(variableName);
  fetchTypes(variable);
  /* fetch operations */
  fetchOperations(variable);
  /* fetch defined in equations */
  fetchDefinedInEquations(variable);
  /* fetch used in equations */
  fetchUsedInEquations(variable);
}

void VariablePage::variablesItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Variable : " + current->text(0) + "\nComment : " + current->text(1);
  mpTransformationsWidget->showInfoText(info);
}

void VariablePage::typesItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Type : " + current->text(0);
  mpTransformationsWidget->showInfoText(info);
}

void VariablePage::operationsItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Operation : " + current->text(0);
  mpTransformationsWidget->showInfoText(info);
}

void VariablePage::definedInItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Index : " + current->text(0) + "\n";
  info += "Type : " + current->text(1) + "\n";
  info += "Equation : " + current->text(2) + "\n";
  mpTransformationsWidget->showInfoText(info);
}

void VariablePage::usedInItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Index : " + current->text(0) + "\n";
  info += "Type : " + current->text(1) + "\n";
  info += "Equation : " + current->text(2) + "\n";
  mpTransformationsWidget->showInfoText(info);
}

void VariablePage::showEquation(QTreeWidgetItem *pVariableTreeItem, int column)
{
  Q_UNUSED(column);
  if (!pVariableTreeItem)
    return;
  mpTransformationsWidget->getEquationPage()->fetchEquationData(pVariableTreeItem->text(0).toInt());
  mpTransformationsWidget->nextPage();
}

EquationPage::EquationPage(TransformationsWidget *pTransformationsWidget)
  : QWidget(pTransformationsWidget)
{
  mpTransformationsWidget = pTransformationsWidget;
  /* defines tree widget */
  Label *pDefinesLabel = new Label(tr("Defines"));
  mpDefinesTreeWidget = new QTreeWidget;
  mpDefinesTreeWidget->setItemDelegate(new ItemDelegate(mpDefinesTreeWidget));
  mpDefinesTreeWidget->setObjectName("DefinesTree");
  mpDefinesTreeWidget->setIndentation(0);
  mpDefinesTreeWidget->setColumnCount(1);
  mpDefinesTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDefinesTreeWidget->setSortingEnabled(true);
  mpDefinesTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  QStringList headerLabels;
  headerLabels << tr("Variable");
  mpDefinesTreeWidget->setHeaderLabels(headerLabels);
  connect(mpDefinesTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(definesItemChanged(QTreeWidgetItem*)));
  connect(mpDefinesTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(definesItemChanged(QTreeWidgetItem*)));
  QGridLayout *pDefinesGridLayout = new QGridLayout;
  pDefinesGridLayout->setContentsMargins(0, 0, 0, 0);
  pDefinesGridLayout->addWidget(pDefinesLabel, 0, 0);
  pDefinesGridLayout->addWidget(mpDefinesTreeWidget, 1, 0);
  QFrame *pDefinesFrame = new QFrame;
  pDefinesFrame->setLayout(pDefinesGridLayout);
  /* depends tree widget */
  Label *pDependsLabel = new Label(tr("Depends"));
  mpDependsTreeWidget = new QTreeWidget;
  mpDependsTreeWidget->setItemDelegate(new ItemDelegate(mpDependsTreeWidget));
  mpDependsTreeWidget->setObjectName("DependsTree");
  mpDependsTreeWidget->setIndentation(Helper::treeIndentation);
  mpDependsTreeWidget->setColumnCount(1);
  mpDependsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDependsTreeWidget->setSortingEnabled(true);
  mpDependsTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  mpDependsTreeWidget->setHeaderLabel(tr("Variable"));
  connect(mpDependsTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(dependsItemChanged(QTreeWidgetItem*)));
  connect(mpDependsTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(dependsItemChanged(QTreeWidgetItem*)));
  QGridLayout *pDependsGridLayout = new QGridLayout;
  pDependsGridLayout->setContentsMargins(0, 0, 0, 0);
  pDependsGridLayout->addWidget(pDependsLabel, 0, 0);
  pDependsGridLayout->addWidget(mpDependsTreeWidget, 1, 0);
  QFrame *pDependsFrame = new QFrame;
  pDependsFrame->setLayout(pDependsGridLayout);
  /* operations tree widget */
  Label *pOperationsLabel = new Label(tr("Equation Operations"));
  mpOperationsTreeWidget = new QTreeWidget;
  mpOperationsTreeWidget->setItemDelegate(new ItemDelegate(mpOperationsTreeWidget));
  mpOperationsTreeWidget->setObjectName("EquationOperationsTree");
  mpOperationsTreeWidget->setIndentation(Helper::treeIndentation);
  mpOperationsTreeWidget->setColumnCount(1);
  mpOperationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpOperationsTreeWidget->setSortingEnabled(true);
  mpOperationsTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  mpOperationsTreeWidget->setHeaderLabel(tr("Operations"));
  connect(mpOperationsTreeWidget, SIGNAL(currentItemChanged(QTreeWidgetItem*,QTreeWidgetItem*)),
          this, SLOT(operationsItemChanged(QTreeWidgetItem*)));
  connect(mpOperationsTreeWidget, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(operationsItemChanged(QTreeWidgetItem*)));
  QGridLayout *pOperationsGridLayout = new QGridLayout;
  pOperationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pOperationsGridLayout->addWidget(pOperationsLabel, 0, 0);
  pOperationsGridLayout->addWidget(mpOperationsTreeWidget, 1, 0);
  QFrame *pOperationsFrame = new QFrame;
  pOperationsFrame->setLayout(pOperationsGridLayout);
  /* splitter */
  QSplitter *pSplitter = new QSplitter;
  pSplitter->setChildrenCollapsible(false);
  pSplitter->setHandleWidth(4);
  pSplitter->setContentsMargins(0, 0, 0, 0);
  pSplitter->addWidget(pDefinesFrame);
  pSplitter->addWidget(pDependsFrame);
  pSplitter->addWidget(pOperationsFrame);
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pSplitter, 0, 0);
  setLayout(pMainLayout);
}

void EquationPage::fetchEquationData(int equationIndex)
{
  OMEquation equation = mpTransformationsWidget->getInfoXMLFileHandler()->getOMEquation(equationIndex);
  /* fetch defines */
  fetchDefines(equation);
  /* fetch depends */
  fetchDepends(equation);
  /* fetch operations */
  fetchOperations(equation);
}

void EquationPage::fetchDefines(OMEquation &equation)
{
  /* Clear the defines tree. */
  int i = 0;
  while(i < mpDefinesTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpDefinesTreeWidget->topLevelItem(i)->takeChildren());
    delete mpDefinesTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add defines */
  foreach (QString define, equation.defines)
  {
    QStringList values;
    values << define;
    QString toolTip = define;
    QTreeWidgetItem *pDefineTreeItem = new QTreeWidgetItem(values);
    pDefineTreeItem->setToolTip(0, toolTip);
    mpDefinesTreeWidget->addTopLevelItem(pDefineTreeItem);
  }
}

void EquationPage::fetchDepends(OMEquation &equation)
{
  /* Clear the depends tree. */
  int i = 0;
  while(i < mpDependsTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpDependsTreeWidget->topLevelItem(i)->takeChildren());
    delete mpDependsTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add depends */
  foreach (QString depend, equation.depends)
  {
    QStringList values;
    values << depend;
    QString toolTip = depend;
    QTreeWidgetItem *pDependTreeItem = new QTreeWidgetItem(values);
    pDependTreeItem->setToolTip(0, toolTip);
    mpDependsTreeWidget->addTopLevelItem(pDependTreeItem);
  }
}

void EquationPage::fetchOperations(OMEquation &equation)
{
  /* Clear the operations tree. */
  int i = 0;
  while(i < mpOperationsTreeWidget->topLevelItemCount())
  {
    qDeleteAll(mpOperationsTreeWidget->topLevelItem(i)->takeChildren());
    delete mpOperationsTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
  /* add operations */
  if (mpTransformationsWidget->getInfoXMLFileHandler()->hasOperationsEnabled)
  {
    foreach (OMOperation *op, equation.ops)
    {
      QStringList values;
      values << op->toString();
      QString toolTip = op->toString();
      QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
      pOperationTreeItem->setToolTip(0, toolTip);
      mpOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
    }
  }
  else
  {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
}

void EquationPage::definesItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Variable : " + current->text(0);
  mpTransformationsWidget->showInfoText(info);
}

void EquationPage::dependsItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Variable : " + current->text(0);
  mpTransformationsWidget->showInfoText(info);
}

void EquationPage::operationsItemChanged(QTreeWidgetItem *current)
{
  if (!current) return;
  QString info = "Operation : " + current->text(0);
  mpTransformationsWidget->showInfoText(info);
}
