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

PlotWidget::PlotWidget(MainWindow *pParent)
    : QWidget(pParent)
{
    mpParentMainWindow = pParent;

    mpPlotTypesLabel = new QLabel(tr("Plot Type: "));

    mpPlotTypesCombo = new QComboBox();
    mpPlotTypesCombo->addItem(tr("Plot"));
//    mpPlotTypesCombo->addItem(tr("Plot Parametric"));
//    mpPlotTypesCombo->addItem(tr("Visualize"));

    mpPlotVariablesTree = new QTreeWidget(this);
    mpPlotVariablesTree->setContextMenuPolicy(Qt::DefaultContextMenu);
    mpPlotVariablesTree->setHeaderHidden(true);
    mpPlotVariablesTree->setColumnCount(1);
    mpPlotVariablesTree->setIndentation(Helper::treeIndentation);

    mpVerticalLayout = new QVBoxLayout(this);
    mpVerticalLayout->setContentsMargins(0, 0, 0, 0);
    mpVerticalLayout->addWidget(mpPlotTypesLabel);
    mpVerticalLayout->addWidget(mpPlotTypesCombo);
    mpVerticalLayout->addWidget(mpPlotVariablesTree);

    setLayout(mpVerticalLayout);

    connect(mpPlotVariablesTree, SIGNAL(itemClicked(QTreeWidgetItem*,int)), SLOT(plotVariables(QTreeWidgetItem*,int)));
    connect(mpPlotTypesCombo, SIGNAL(currentIndexChanged(QString)), SLOT(visualize(QString)));
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
    // Remove the simulation result if we already had it in tree
    int count = mpPlotVariablesTree->topLevelItemCount();

    for (int i = 0 ; i < count ; i++)
    {
        QTreeWidgetItem *item = mpPlotVariablesTree->topLevelItem(i);
        if (item->toolTip(0) == fileName)
        {
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

    // Now add the plot variables in top level item
    QList<QString>::iterator it;
    for (it = plotVariablesList.begin(); it != plotVariablesList.end(); ++it)
    {
        QTreeWidgetItem *plotTreePost = new QTreeWidgetItem((QTreeWidget*)0);
        plotTreePost->setFlags(Qt::ItemIsUserCheckable | Qt::ItemIsEnabled);
        plotTreePost->setCheckState(0, Qt::Unchecked);
        plotTreePost->setText(0, (*it));
        plotTreePost->setToolTip(0, (*it));
        newTreePost->addChild(plotTreePost);
    }
    // Expand the current plot variables node
    newTreePost->setExpanded(true);
}

void PlotWidget::plotVariables(QTreeWidgetItem *item, int column)
{
    if (!item->parent())
        return;

    QTreeWidgetItem *parentItem = item->parent();
    QStringList plotVariablesList;
    int count = parentItem->childCount();

    for (int i = 0 ; i < count ; i++)
    {
        QTreeWidgetItem *childItem = parentItem->child(i);
        if (childItem->checkState(column) == Qt::Checked)
            plotVariablesList.append(childItem->toolTip(column));
    }

    if (plotVariablesList.isEmpty())
        return;

    QString plotVariablesString = plotVariablesList.join(",");

    // create Plot Expression to send to OMC and Compound Widget
    QString plotExpression;
    // remove the _res.plt from name
    QString modelName = parentItem->toolTip(column).remove((parentItem->toolTip(column).length() - 8),
                                                           (parentItem->toolTip(column).length() - 1));
    QString plotType = mpPlotTypesCombo->currentText();
    MessageWidget *pMessageWidget = mpParentMainWindow->mpMessageWidget;

    if (plotType ==  "Plot")
    {        
        plotExpression = "plot(" + modelName + ", {" + plotVariablesString + "})";
        setCursor(Qt::WaitCursor);
        //if (!mpParentMainWindow->mpOMCProxy->plot(modelName, plotVariablesString))
        if (!mpParentMainWindow->mpOMCProxy->plot(plotVariablesString, parentItem->toolTip(column)))
        {
            pMessageWidget->printGUIErrorMessage(QString(mpParentMainWindow->mpOMCProxy->getResult())
                                                 .append(mpParentMainWindow->mpOMCProxy->getErrorString()));
        }
        unsetCursor();
    }
    else if (plotType ==  "Plot Parametric")
    {
        plotExpression = "plotParametric(" + modelName + ", {" + plotVariablesString + "})";
        setCursor(Qt::WaitCursor);
        if (!mpParentMainWindow->mpOMCProxy->plotParametric(modelName, plotVariablesString))
        {
            pMessageWidget->printGUIErrorMessage(QString(mpParentMainWindow->mpOMCProxy->getResult())
                                                 .append(mpParentMainWindow->mpOMCProxy->getErrorString()));
        }
        unsetCursor();
    }
    else if (plotType ==  "Visualize")
    {
        plotExpression = "visualize(" + modelName + ")";
        setCursor(Qt::WaitCursor);
        if (!mpParentMainWindow->mpOMCProxy->visualize(modelName))
        {
            pMessageWidget->printGUIErrorMessage(QString(mpParentMainWindow->mpOMCProxy->getResult())
                                                 .append(mpParentMainWindow->mpOMCProxy->getErrorString()));
        }
        unsetCursor();
    }
}

void PlotWidget::visualize(QString value)
{
    Q_UNUSED(value);
}

void PlotWidget::contextMenuEvent(QContextMenuEvent *event)
{
    //QMessageBox::warning(0, "teststs", "sdcsdsdsdv", "OK");
}
