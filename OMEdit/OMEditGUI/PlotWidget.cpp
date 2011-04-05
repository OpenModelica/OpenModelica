/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

#include "PlotWidget.h"

using namespace OMPlot;

PlotWidget::PlotWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;

    mpPlotVariablesTree = new QTreeWidget(this);
    mpPlotVariablesTree->setContextMenuPolicy(Qt::DefaultContextMenu);
    mpPlotVariablesTree->setHeaderHidden(true);
    mpPlotVariablesTree->setColumnCount(1);
    mpPlotVariablesTree->setIndentation(Helper::treeIndentation);

    mpVerticalLayout = new QVBoxLayout(this);
    mpVerticalLayout->setContentsMargins(0, 0, 0, 0);
    mpVerticalLayout->addWidget(mpPlotVariablesTree);

    setLayout(mpVerticalLayout);

    connect(mpPlotVariablesTree, SIGNAL(itemChanged(QTreeWidgetItem*,int)), SLOT(plotVariables(QTreeWidgetItem*,int)));
    connect(pParent->mpPlotWindowContainer, SIGNAL(subWindowActivated(QMdiSubWindow*)),
            this, SLOT(updatePlotVariablesTree(QMdiSubWindow*)));
    connect(this, SIGNAL(removePlotFile(QTreeWidgetItem*)), pParent->mpPlotWindowContainer,
            SLOT(updatePlotWindows(QTreeWidgetItem*)));
}

QList<QString> PlotWidget::readPlotVariables(QString fileName)
{
    // need to replace \\ to / so that QFile can close the file properly, otherwise we can't open it second time
    QString filePath = QString(Helper::tmpPath.replace("\\", "/")).append("/").append(fileName);

    QFile simulationResultFile(filePath);
    simulationResultFile.open(QIODevice::ReadOnly);

    QList<QString> plotVariablesList;
    QTextStream inStream(&simulationResultFile);
    QTextStream temp(&simulationResultFile);

    inStream.seek(temp.readAll().indexOf("n string variables"));
    // read this line that says n string variables
    inStream.readLine();
    // now read the variables until the end
    while (!inStream.atEnd())
    {
        QString line = inStream.readLine();
        line = line.mid(line.lastIndexOf("//") + 2, (line.length() - 1)).trimmed();
        plotVariablesList.append(line);
    }
    simulationResultFile.close();
    return plotVariablesList;
}

void PlotWidget::addPlotVariablestoTree(QString fileName, QList<QString> plotVariablesList)
{
    mpPlotVariablesTree->blockSignals(false);
    // Remove the simulation result if we already had it in tree
    int count = mpPlotVariablesTree->topLevelItemCount();

    for (int i = 0 ; i < count ; i++)
    {
        QTreeWidgetItem *item = mpPlotVariablesTree->topLevelItem(i);
        if (item->toolTip(0) == fileName)
        {
            emit removePlotFile(item);
            qDeleteAll(item->takeChildren());
            delete item;
            break;
        }
    }

    // insert the top level item in tree
    QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
    newTreePost->setText(0, QString(fileName));
    newTreePost->setToolTip(0, QString(fileName));
    mpPlotVariablesTree->insertTopLevelItem(0, newTreePost);

    // create two lists from plotVariablesList one contains der's
    QStringList derPlotVariables;
    QStringList plotVariables;
    foreach (QString plotVariable, plotVariablesList)
    {
        if (plotVariable.startsWith("der("))
        {
            derPlotVariables.append(plotVariable.mid(4, (plotVariable.size() - 5)));
        }
        else
            plotVariables.append(plotVariable);
    }

    QString parentStructure;
    // add derPlotVariables to tree
    foreach(QString plotVariable, derPlotVariables)
    {
        QStringList variables = plotVariable.split(".");
        parentStructure = newTreePost->toolTip(0);
        for (int i = 0 ; i < variables.size() ; i++)
        {
            // if its the last variable in the list make it der
            if (i == variables.size() - 1)
            {
                QString structure = QString(newTreePost->toolTip(0)).append(".")
                                    .append("der(").append(variables.join(".")).append(")");
                variables[i].prepend("der(").append(")");
                // make sure you dont add any node twice
                if (!getTreeNode(structure))
                    addPlotVariableToTree(parentStructure, variables[i], structure);
            }
            else
            {
                // make sure you dont add any node twice
                if (!getTreeNode(QString(parentStructure).append(".").append(variables[i])))
                    addPlotVariableToTree(parentStructure, variables[i]);
                parentStructure.append(".").append(variables[i]);
            }
        }
    }
    // add plotVariables to tree
    foreach(QString plotVariable, plotVariables)
    {
        QStringList variables = plotVariable.split(".");
        parentStructure = newTreePost->toolTip(0);
        for (int i = 0 ; i < variables.size() ; i++)
        {
            // make sure you dont add any node twice
            if (!getTreeNode(QString(parentStructure).append(".").append(variables[i])))
                addPlotVariableToTree(parentStructure, variables[i]);
            parentStructure.append(".").append(variables[i]);
        }
    }
    // sort items and expand the current plot variables node and collapse all others
    mpPlotVariablesTree->setSortingEnabled(true);
    mpPlotVariablesTree->sortItems(0, Qt::AscendingOrder);
    // collapse all tree items
    count = mpPlotVariablesTree->topLevelItemCount();
    for (int i = 0 ; i < count ; i++)
    {
        mpPlotVariablesTree->topLevelItem(i)->setExpanded(false);
    }
    newTreePost->setExpanded(true);
    mpPlotVariablesTree->blockSignals(false);
}

void PlotWidget::addPlotVariableToTree(QString parentStructure, QString childName, QString fullStructure)
{
    QTreeWidgetItem *parentItem = getTreeNode(parentStructure);
    QTreeWidgetItem *plotTreePost = new QTreeWidgetItem((QTreeWidget*)0);
    plotTreePost->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
    plotTreePost->setCheckState(0, Qt::Unchecked);
    plotTreePost->setText(0, childName);
    if (childName.startsWith("der("))
        plotTreePost->setToolTip(0, fullStructure);
    else
        plotTreePost->setToolTip(0, parentStructure.append(".").append(childName));
    if (parentItem)
    {
        parentItem->addChild(plotTreePost);
        if (parentItem->childCount() > 0)
            parentItem->setData(0, Qt::CheckStateRole, QVariant());
    }
}

QTreeWidgetItem* PlotWidget::getTreeNode(QString itemName)
{
    QTreeWidgetItemIterator it(mpPlotVariablesTree);
    while (*it)
    {
        if ((*it)->toolTip(0) == itemName)
        {
            return (*it);
        }
        ++it;
    }
    return 0;
}

QTreeWidget* PlotWidget::getPlotVariablesTree()
{
    return mpPlotVariablesTree;
}

void PlotWidget::plotVariables(QTreeWidgetItem *item, int column)
{
    if (!item->parent())
        return;

    QTreeWidgetItem *parentItem = item->parent();
    while (parentItem->parent())
    {
        parentItem = parentItem->parent();
    }

    try
    {
        // get the current window, if not window found simply return
        PlotWindow *pPlotWindow = mpParentMainWindow->mpPlotWindowContainer->getCurrentWindow();
        if (!pPlotWindow)
        {
            mpPlotVariablesTree->blockSignals(true);
            item->setCheckState(column, Qt::Unchecked);
            mpPlotVariablesTree->blockSignals(false);
            mpParentMainWindow->mpMessageWidget->printGUIInfoMessage(tr("No plot window is active for plotting. Please select a plot window or open a new."));
            return;
        }
        // if plottype is PLOT then
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
        {
            // check the item checkstate
            if (item->checkState(column) == Qt::Checked)
            {
                pPlotWindow->openFile(QString(Helper::tmpPath).append("/").append(parentItem->text(0)));
                pPlotWindow->setVariablesList(QStringList(item->toolTip(column).remove(0, (parentItem->text(column).length()+1))));
                pPlotWindow->plot();
                pPlotWindow->getPlot()->replot();
                pPlotWindow->getPlot()->updateGeometry();
            }
            // if user unchecks the variable then remove it from the plot
            else if (item->checkState(column) == Qt::Unchecked)
            {
                foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
                {
                    QString curveTitle = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text());
                    QString itemTitle = item->toolTip(column);
                    if (curveTitle.compare(itemTitle) == 0)
                    {
                        pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                        pPlotCurve->detach();
                        pPlotWindow->getPlot()->replot();
                        pPlotWindow->getPlot()->updateGeometry();
                        break;
                    }
                }
            }
        }
        // if plottype is PLOTPARAMETRIC then
        else
        {
            // check the item checkstate
            if (item->checkState(column) == Qt::Checked)
            {
                // if mPlotParametricVariables is empty just add one QStringlist with 1 varibale to it
                if (mPlotParametricVariables.isEmpty())
                {
                    mPlotParametricVariables.append(QStringList(item->toolTip(column).remove(0, (parentItem->text(column).length()+1))));
                }
                // if mPlotParametricVariables is not empty then add one string to its last element
                else
                {
                    if (mPlotParametricVariables.last().size() < 2)
                    {
                        mPlotParametricVariables.last().append(QString(item->toolTip(column).remove(0, (parentItem->text(column).length()+1))));
                        pPlotWindow->openFile(QString(Helper::tmpPath).append("/").append(parentItem->text(0)));
                        pPlotWindow->setVariablesList(mPlotParametricVariables.last());
                        pPlotWindow->plotParametric();
                        pPlotWindow->getPlot()->replot();
                    }
                    else
                    {
                        mPlotParametricVariables.append(QStringList(item->toolTip(column).remove(0, (parentItem->text(column).length()+1))));
                    }
                }
            }
            // if user unchecks the variable then remove it from the plot
            else if (item->checkState(column) == Qt::Unchecked)
            {
                // remove the variable from mPlotParametricVariables list
                foreach (QStringList list, mPlotParametricVariables)
                {
                    if (list.contains(item->toolTip(column).remove(0, (parentItem->text(column).length()+1))))
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
                                if (curveTitle.compare(itemTitle) == 0)
                                {
                                    mpPlotVariablesTree->blockSignals(true);
                                    // uncheck the x variable
                                    QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
                                    QTreeWidgetItem *treeItem;
                                    treeItem = getTreeNode(xVariable);
                                    if (treeItem)
                                        treeItem->setCheckState(0, Qt::Unchecked);
                                    // uncheck the y variable
                                    QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
                                    treeItem = getTreeNode(yVariable);
                                    if (treeItem)
                                        treeItem->setCheckState(0, Qt::Unchecked);
                                    mpPlotVariablesTree->blockSignals(false);
                                    pPlotWindow->getPlot()->removeCurve(pPlotCurve);
                                    pPlotCurve->detach();
                                    pPlotWindow->getPlot()->replot();
                                    pPlotWindow->getPlot()->updateGeometry();
                                    break;
                                }
                            }
                            mPlotParametricVariables.removeOne(list);
                        }
                    }
                }
            }
        }
    }
    catch (PlotException &e)
    {
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(e.what());
    }
}

void PlotWidget::updatePlotVariablesTree(QMdiSubWindow *window)
{
    if (!window and mpParentMainWindow->mpPlotWindowContainer->subWindowList().size() != 0)
        return;

    // first clear all the check boxes in the tree
    mpPlotVariablesTree->blockSignals(true);
    QTreeWidgetItemIterator it(mpPlotVariablesTree);
    while (*it)
    {
        if ((*it)->childCount() == 0)
            (*it)->setCheckState(0, Qt::Unchecked);
        ++it;
    }
    mpPlotVariablesTree->blockSignals(false);
    // all plotwindows are closed down then simply return
    if (mpParentMainWindow->mpPlotWindowContainer->subWindowList().size() == 0)
        return;

    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(window->widget());

    // now loop through the curves and tick variables in the tree whose curves are on the plot
    mpPlotVariablesTree->blockSignals(true);
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
    {
        QTreeWidgetItem *treeItem;
        if (pPlotWindow->getPlotType() == PlotWindow::PLOT)
        {
            treeItem = getTreeNode(QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->title().text()));
            if (treeItem)
                treeItem->setCheckState(0, Qt::Checked);
        }
        else if (pPlotWindow->getPlotType() == PlotWindow::PLOTPARAMETRIC)
        {
            // check the xvariable
            QString xVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getXVariable());
            treeItem = getTreeNode(xVariable);
            if (treeItem)
                treeItem->setCheckState(0, Qt::Checked);
            // check the y variable
            QString yVariable = QString(pPlotCurve->getFileName()).append(".").append(pPlotCurve->getYVariable());
            treeItem = getTreeNode(yVariable);
            if (treeItem)
                treeItem->setCheckState(0, Qt::Checked);
        }
    }
    mpPlotVariablesTree->blockSignals(false);
}

void PlotWidget::contextMenuEvent(QContextMenuEvent *event)
{
    //QMessageBox::warning(0, "teststs", "sdcsdsdsdv", "OK");
}
