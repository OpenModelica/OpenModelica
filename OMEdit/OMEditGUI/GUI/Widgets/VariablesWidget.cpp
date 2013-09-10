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

#include "VariablesWidget.h"

using namespace OMPlot;

VariableTreeItem::VariableTreeItem(QString text, QString parentName, QString nameStructure, QString fileName, QString filePath,
                                   QString tooltip, QTreeWidget *parent)
  : QTreeWidgetItem(parent)
{
  setName(text);
  setParentName(parentName);
  setNameStructure(nameStructure);
  setFileName(fileName);
  setFilePath(filePath);

  setText(0, mName);
  setToolTip(0, tooltip);
}

QIcon VariableTreeItem::getVariableTreeItemIcon(QString name)
{
  if (name.endsWith(".mat"))
    return QIcon(":/Resources/icons/mat.svg");
  else if (name.endsWith(".plt"))
    return QIcon(":/Resources/icons/plt.svg");
  else if (name.endsWith(".csv"))
    return QIcon(":/Resources/icons/csv.svg");
  else
    return QIcon();
}

void VariableTreeItem::setName(QString name)
{
  mName = name;
}

QString VariableTreeItem::getName()
{
  return mName;
}

void VariableTreeItem::setParentName(QString parentName)
{
  mParentName = parentName;
}

QString VariableTreeItem::getParentName()
{
  return mParentName;
}

void VariableTreeItem::setNameStructure(QString nameStructure)
{
  mNameStructure = nameStructure;
}

QString VariableTreeItem::getNameStructure()
{
  return mNameStructure;
}

void VariableTreeItem::setFileName(QString fileName)
{
  mFileName = fileName;
}

QString VariableTreeItem::getFileName()
{
  return mFileName;
}

void VariableTreeItem::setFilePath(QString filePath)
{
  mFilePath = filePath;
}

QString VariableTreeItem::getFilePath()
{
  return mFilePath;
}

QString VariableTreeItem::getPlotVariable()
{
  return QString(mNameStructure).remove(0, mFileName.length() + 1);
}

VariablesTreeWidget::VariablesTreeWidget(VariablesWidget *pParent)
  : QTreeWidget(pParent)
{
  mpVariablesWidget = pParent;
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setHeaderLabel(tr("Variables"));
  setColumnCount(1);
  setIndentation(Helper::treeIndentation);
  setIconSize(Helper::iconSize);
  setContextMenuPolicy(Qt::CustomContextMenu);
  setExpandsOnDoubleClick(false);
}

VariableTreeItem* VariablesTreeWidget::getVariableTreeItem(QString name)
{
  QTreeWidgetItemIterator it(this);
  while (*it)
  {
    VariableTreeItem *pItem = dynamic_cast<VariableTreeItem*>((*it));
    if (pItem->getNameStructure() == name)
    {
      return pItem;
    }
    ++it;
  }
  return 0;
}

VariablesWidget* VariablesTreeWidget::getVariablesWidget()
{
  return mpVariablesWidget;
}

VariablesWidget::VariablesWidget(MainWindow *pParent)
  : QWidget(pParent)
{
  setMinimumWidth(175);
  mpMainWindow = pParent;
  // create the find text box
  mpFindVariablesTextBox = new QLineEdit(Helper::findVariables);
  mpFindVariablesTextBox->installEventFilter(this);
  connect(mpFindVariablesTextBox, SIGNAL(returnPressed()), SLOT(findVariables()));
  connect(mpFindVariablesTextBox, SIGNAL(textEdited(QString)), SLOT(findVariables()));
  // create variables tree widget
  mpVariablesTreeWidget = new VariablesTreeWidget(this);
  // create actions for Variables Widget
  createActions();
  // create the layout
  QVBoxLayout *pMainLayout = new QVBoxLayout(this);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpFindVariablesTextBox);
  pMainLayout->addWidget(mpVariablesTreeWidget);
  setLayout(pMainLayout);
  connect(mpVariablesTreeWidget, SIGNAL(itemChanged(QTreeWidgetItem*,int)), SLOT(plotVariables(QTreeWidgetItem*,int)));
  connect(mpVariablesTreeWidget, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(pParent->getPlotWindowContainer(), SIGNAL(subWindowActivated(QMdiSubWindow*)), this, SLOT(updatePlotVariablesTree(QMdiSubWindow*)));
  connect(this, SIGNAL(resultFileRemoved(VariableTreeItem*)), pParent->getPlotWindowContainer(), SLOT(updatePlotWindows(VariableTreeItem*)));
  connect(this, SIGNAL(resultFileUpdated(VariablesTreeWidget*)), pParent->getPlotWindowContainer(), SLOT(updatePlotWindows(VariablesTreeWidget*)));
}

void VariablesWidget::createActions()
{
  mpDeleteResultAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete Result"), this);
  mpDeleteResultAction->setStatusTip(tr("Delete the result"));
  connect(mpDeleteResultAction, SIGNAL(triggered()), SLOT(deleteVariablesTreeItem()));
}

void VariablesWidget::addPlotVariablestoTree(QString fileName, QString filePath, QStringList plotVariablesList)
{
  mpVariablesTreeWidget->blockSignals(true);
  // Remove the simulation result if we already had it in tree
  if (!filePath.endsWith('/'))
    filePath = filePath.append("/");

  bool isResultFileRemoved = false;
  int count = mpVariablesTreeWidget->topLevelItemCount();
  for (int i = 0 ; i < count ; i++)
  {
    VariableTreeItem *pItem = dynamic_cast<VariableTreeItem*>(mpVariablesTreeWidget->topLevelItem(i));
    if (pItem->getNameStructure() == fileName)
    {
      isResultFileRemoved = true;
      qDeleteAll(pItem->takeChildren());
      delete pItem;
      break;
    }
  }
  // insert the top level item in tree
  QString toolTip = tr("Simulation Result File: ").append(fileName).append("\n")
      .append(Helper::fileLocation).append(": ").append(filePath).append(fileName);
  QString text = QString(fileName).remove(QRegExp("(_res.mat|_res.plt|_res.csv)"));
  VariableTreeItem *pVariableTreeItem = new VariableTreeItem(text, "", fileName, fileName, filePath, toolTip, (QTreeWidget*)0);
  pVariableTreeItem->setIcon(0, pVariableTreeItem->getVariableTreeItemIcon(fileName));
  mpVariablesTreeWidget->insertTopLevelItem(0, pVariableTreeItem);
  // create two lists from plotVariablesList one contains der's
  QStringList derPlotVariables;
  QStringList derContainer;
  QStringList plotVariables;
  foreach (QString plotVariable, plotVariablesList)
  {
    if (plotVariable.startsWith("der("))
    {
      QString str = plotVariable;
      str.chop((str.lastIndexOf("der(")/4)+1);
      derPlotVariables.append(str.mid(str.lastIndexOf("der(") + 4));
      derContainer.append(plotVariable.left(plotVariable.lastIndexOf("der(") + 4));
    }
    else
      plotVariables.append(plotVariable);
  }
  QString parentStructure;
  // add derPlotVariables to tree
  int j = 0;
  foreach(QString plotVariable, derPlotVariables)
  {
    QStringList variables = plotVariable.split(QRegExp("\\.(?![^\\[\\]]*\\])"), QString::SkipEmptyParts);
    parentStructure = pVariableTreeItem->getNameStructure();
    for (int i = 0 ; i < variables.size() ; i++)
    {
      // if its the last variable in the list make it der
      if (i == variables.size() - 1)
      {
        QString derPrependString = derContainer.at(j);
        int size = derPrependString.count("der(");
        QString derAppendString;
        derAppendString = QString(derAppendString.toStdString().append(size, ')').c_str());
        QString structure = QString(pVariableTreeItem->getNameStructure()).append(".")
            .append(derPrependString).append(variables.join(".")).append(derAppendString);
        variables[i].prepend(derPrependString).append(derAppendString);
        // make sure you dont add any node twice
        if (!mpVariablesTreeWidget->getVariableTreeItem(structure))
          addPlotVariableToTree(fileName, filePath, parentStructure, variables[i], structure, true);
      }
      else
      {
        // make sure you dont add any node twice
        if (!mpVariablesTreeWidget->getVariableTreeItem(QString(parentStructure).append(".").append(variables[i])))
          addPlotVariableToTree(fileName, filePath, parentStructure, variables[i]);
        parentStructure.append(".").append(variables[i]);
      }
    }
    j++;
  }
  // add plotVariables to tree
  foreach(QString plotVariable, plotVariables)
  {
    QStringList variables = plotVariable.split(QRegExp("\\.(?![^\\[\\]]*\\])"), QString::SkipEmptyParts);
    parentStructure = pVariableTreeItem->getNameStructure();
    for (int i = 0 ; i < variables.size() ; i++)
    {
      // make sure you dont add any node twice
      if (!mpVariablesTreeWidget->getVariableTreeItem(QString(parentStructure).append(".").append(variables[i])))
        addPlotVariableToTree(fileName, filePath, parentStructure, variables[i]);
      parentStructure.append(".").append(variables[i]);
    }
  }
  mpVariablesTreeWidget->blockSignals(false);
  if (isResultFileRemoved)
    emit resultFileUpdated(mpVariablesTreeWidget);
  // sort items and expand the current plot variables node.
  mpVariablesTreeWidget->setSortingEnabled(true);
  mpVariablesTreeWidget->sortItems(0, Qt::AscendingOrder);
  mpVariablesTreeWidget->collapseAll();
  pVariableTreeItem->setExpanded(true);
}

void VariablesWidget::addPlotVariableToTree(QString fileName, QString filePath, QString parentStructure, QString childName,
                                            QString fullStructure, bool derivative)
{
  QString nameStructure;
  if (derivative)
    nameStructure = fullStructure;
  else
    nameStructure = QString(parentStructure).append(".").append(childName);

  if (!filePath.endsWith('/'))
    filePath = filePath.append("/");

  VariableTreeItem *parentItem = mpVariablesTreeWidget->getVariableTreeItem(parentStructure);
  QString toolTip = QString(tr("File: ")).append(filePath).append(fileName).append("\n").append(tr("Variable: ").append(nameStructure));
  VariableTreeItem *newTreePost;
  newTreePost = new VariableTreeItem(childName, parentItem->getName(), nameStructure, fileName, filePath, toolTip, (QTreeWidget*)0);
  newTreePost->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled | Qt::ItemIsSelectable);
  newTreePost->setCheckState(0, Qt::Unchecked);
  if (parentItem)
  {
    parentItem->addChild(newTreePost);
    if (parentItem->childCount() > 0)
      parentItem->setData(0, Qt::CheckStateRole, QVariant());
  }
}

bool VariablesWidget::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pObject != mpFindVariablesTextBox)
    return false;
  if (pEvent->type() == QEvent::FocusIn)
  {
    if (mpFindVariablesTextBox->text().compare(Helper::findVariables) == 0)
      mpFindVariablesTextBox->setText("");
  }
  if (pEvent->type() == QEvent::FocusOut)
  {
    if (mpFindVariablesTextBox->text().isEmpty())
      mpFindVariablesTextBox->setText(Helper::findVariables);
  }
  return false;
}

void VariablesWidget::unHideChildItems(QTreeWidgetItem *pItem)
{
  QTreeWidgetItem *pChildItem;
  for (int i = 0 ; i < pItem->childCount() ; i++)
  {
    pChildItem = pItem->child(i);
    pChildItem->setHidden(false);
    if (pChildItem->childCount() > 0)
      unHideChildItems(pChildItem);
  }
}

void VariablesWidget::plotVariables(QTreeWidgetItem *item, int column, PlotWindow *pPlotWindow)
{
  if (!item->parent())
    return;
  VariableTreeItem *pItem = dynamic_cast<VariableTreeItem*>(item);
  try
  {
    // if pPlotWindow is 0 then get the current window, if no window found simply return
    if (!pPlotWindow)
      pPlotWindow = mpMainWindow->getPlotWindowContainer()->getCurrentWindow();
    if (!pPlotWindow)
    {
      mpVariablesTreeWidget->blockSignals(true);
      pItem->setCheckState(column, Qt::Unchecked);
      mpVariablesTreeWidget->blockSignals(false);
      QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                               tr("No plot window is active for plotting. Please select a plot window or open a new."), Helper::ok);
      return;
    }
    // if plottype is PLOT then
    if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
    {
      // check the item checkstate
      if (pItem->checkState(column) == Qt::Checked)
      {
        pPlotWindow->initializeFile(QString(pItem->getFilePath()).append(pItem->getFileName()));
        pPlotWindow->setCurveWidth(mpMainWindow->getOptionsDialog()->getCurveStylePage()->getCurveThickness());
        pPlotWindow->setCurveStyle(mpMainWindow->getOptionsDialog()->getCurveStylePage()->getCurvePattern());
        pPlotWindow->setVariablesList(QStringList(pItem->getPlotVariable()));
        pPlotWindow->plot();
        pPlotWindow->fitInView();
        pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
      }
      // if user unchecks the variable then remove it from the plot
      else if (pItem->checkState(column) == Qt::Unchecked)
      {
        foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
        {
          QString curveTitle = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
          if (curveTitle.compare(pItem->getNameStructure()) == 0)
          {
            pPlotWindow->getPlot()->removeCurve(pPlotCurve);
            pPlotCurve->detach();
            pPlotWindow->fitInView();
            pPlotWindow->getPlot()->updateLayout();
            pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
          }
        }
      }
    }
    // if plottype is PLOTPARAMETRIC then
    else
    {
      // check the item checkstate
      if (pItem->checkState(column) == Qt::Checked)
      {
        // if mPlotParametricVariables is empty just add one QStringlist with 1 varibale to it
        if (mPlotParametricVariables.isEmpty())
        {
          mPlotParametricVariables.append(QStringList(pItem->getPlotVariable()));
          mFileName = pItem->getFileName();
        }
        // if mPlotParametricVariables is not empty then add one string to its last element
        else
        {
          if (mPlotParametricVariables.last().size() < 2)
          {
            if (mFileName.compare(pItem->getFileName()) != 0)
            {
              mpVariablesTreeWidget->blockSignals(true);
              pItem->setCheckState(0, Qt::Unchecked);
              QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                                    GUIMessages::getMessage(GUIMessages::PLOT_PARAMETRIC_DIFF_FILES), Helper::ok);
              mpVariablesTreeWidget->blockSignals(false);
              return;
            }
            mPlotParametricVariables.last().append(QStringList(pItem->getPlotVariable()));
            pPlotWindow->initializeFile(QString(pItem->getFilePath()).append(pItem->getFileName()));
            pPlotWindow->setCurveWidth(mpMainWindow->getOptionsDialog()->getCurveStylePage()->getCurveThickness());
            pPlotWindow->setCurveStyle(mpMainWindow->getOptionsDialog()->getCurveStylePage()->getCurvePattern());
            pPlotWindow->setVariablesList(mPlotParametricVariables.last());
            pPlotWindow->plotParametric();
            if (mPlotParametricVariables.size() > 1)
            {
              pPlotWindow->setXLabel("");
              pPlotWindow->setYLabel("");
            }
            pPlotWindow->fitInView();
            pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
          }
          else
          {
            mPlotParametricVariables.append(QStringList(pItem->getPlotVariable()));
            mFileName = pItem->getFileName();
          }
        }
      }
      // if user unchecks the variable then remove it from the plot
      else if (pItem->checkState(column) == Qt::Unchecked)
      {
        // remove the variable from mPlotParametricVariables list
        foreach (QStringList list, mPlotParametricVariables)
        {
          if (list.contains(pItem->getPlotVariable()))
          {
            // if list has only one variable then clear the list and return;
            if (list.size() < 2)
            {
              mPlotParametricVariables.removeOne(list);
              break;
            }
            // if list has more than two variables then remove both and remove the curve
            else
            {
              QString itemTitle = QString(list.last()).append("(").append(list.first()).append(")");
              foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
              {
                QString curveTitle = pPlotCurve->title().text();
                if ((curveTitle.compare(itemTitle) == 0) and (pItem->getFileName().compare(pPlotCurve->getFileName()) == 0))
                {
                  mpVariablesTreeWidget->blockSignals(true);
                  // uncheck the x variable
                  QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
                  VariableTreeItem *pTreeItem;
                  pTreeItem = mpVariablesTreeWidget->getVariableTreeItem(xVariable);
                  if (pTreeItem)
                    pTreeItem->setCheckState(0, Qt::Unchecked);
                  // uncheck the y variable
                  QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
                  pTreeItem = mpVariablesTreeWidget->getVariableTreeItem(yVariable);
                  if (pTreeItem)
                    pTreeItem->setCheckState(0, Qt::Unchecked);
                  mpVariablesTreeWidget->blockSignals(false);
                  pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                  pPlotCurve->detach();
                  pPlotWindow->fitInView();
                  pPlotWindow->getPlot()->updateLayout();
                  pPlotWindow->getPlot()->getPlotZoomer()->setZoomBase(false);
                }
              }
              mPlotParametricVariables.removeOne(list);
              if (mPlotParametricVariables.size() == 1)
              {
                if (mPlotParametricVariables.last().size() > 1)
                {
                  pPlotWindow->setXLabel(mPlotParametricVariables.last().at(0));
                  pPlotWindow->setYLabel(mPlotParametricVariables.last().at(1));
                }
                else
                {
                  pPlotWindow->setXLabel("");
                  pPlotWindow->setYLabel("");
                }
              }
              else
              {
                pPlotWindow->setXLabel("");
                pPlotWindow->setYLabel("");
              }
            }
          }
        }
      }
    }
  }
  catch (PlotException &e)
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error), e.what(), Helper::ok);
  }
}

void VariablesWidget::updatePlotVariablesTree(QMdiSubWindow *window)
{
  if (!window and mpMainWindow->getPlotWindowContainer()->subWindowList().size() != 0)
    return;
  // first clear all the check boxes in the tree
  mpVariablesTreeWidget->blockSignals(true);
  QTreeWidgetItemIterator it(mpVariablesTreeWidget);
  while (*it)
  {
    if ((*it)->childCount() == 0)
      (*it)->setCheckState(0, Qt::Unchecked);
    ++it;
  }
  mpVariablesTreeWidget->blockSignals(false);
  // all plotwindows are closed down then simply return
  if (mpMainWindow->getPlotWindowContainer()->subWindowList().size() == 0)
    return;

  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(window->widget());
  // now loop through the curves and tick variables in the tree whose curves are on the plot
  mpVariablesTreeWidget->blockSignals(true);
  foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
  {
    VariableTreeItem *pTreeItem;
    if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
    {
      pTreeItem = mpVariablesTreeWidget->getVariableTreeItem(QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text()));
      if (pTreeItem)
        pTreeItem->setCheckState(0, Qt::Checked);
    }
    else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
    {
      // check the xvariable
      QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
      pTreeItem = mpVariablesTreeWidget->getVariableTreeItem(xVariable);
      if (pTreeItem)
        pTreeItem->setCheckState(0, Qt::Checked);
      // check the y variable
      QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
      pTreeItem = mpVariablesTreeWidget->getVariableTreeItem(yVariable);
      if (pTreeItem)
        pTreeItem->setCheckState(0, Qt::Checked);
    }
  }
  mpVariablesTreeWidget->blockSignals(false);
}

void VariablesWidget::showContextMenu(QPoint point)
{
  int adjust = 48;
  QTreeWidgetItem *item = 0;
  item = mpVariablesTreeWidget->itemAt(point);
  // check if we have item at point and if the item is toplevelitem....because you can only delete toplevel items
  if (item and !item->parent())
  {
    mSelectedPlotTreeItem = dynamic_cast<VariableTreeItem*>(item);
    QMenu menu(this);
    menu.addAction(mpDeleteResultAction);
    point.setY(point.y() + adjust);
    menu.exec(mapToGlobal(point));
  }
}

void VariablesWidget::deleteVariablesTreeItem()
{
  emit resultFileRemoved(mSelectedPlotTreeItem);
  qDeleteAll(mSelectedPlotTreeItem->takeChildren());
  delete mSelectedPlotTreeItem;
}

void VariablesWidget::findVariables()
{
  mpVariablesTreeWidget->collapseAll();
  if (mpFindVariablesTextBox->text().isEmpty())
  {
    QTreeWidgetItemIterator it(mpVariablesTreeWidget);
    while (*it)
    {
      VariableTreeItem *pItem = dynamic_cast<VariableTreeItem*>((*it));
      pItem->setHidden(false);
      ++it;
    }
    return;
  }
  QList<QTreeWidgetItem*> foundedItemsList;
  foundedItemsList = mpVariablesTreeWidget->findItems(mpFindVariablesTextBox->text(), Qt::MatchContains | Qt::MatchRecursive);
  // hide all the items first
  QTreeWidgetItemIterator it(mpVariablesTreeWidget);
  while (*it)
  {
    VariableTreeItem *pItem = dynamic_cast<VariableTreeItem*>((*it));
    pItem->setHidden(true);
    ++it;
  }
  // unhide the founded items
  foreach (QTreeWidgetItem *pItem, foundedItemsList)
  {
    pItem->setExpanded(true);
    pItem->setHidden(false);
    // if the item has childs then unhide all the child items as well
    if (pItem->childCount() > 0)
      unHideChildItems(pItem);
    // we must unhide all the parent items as well
    while (pItem->parent())
    {
      pItem = pItem->parent();
      pItem->setExpanded(true);
      pItem->setHidden(false);
    }
  }
}
