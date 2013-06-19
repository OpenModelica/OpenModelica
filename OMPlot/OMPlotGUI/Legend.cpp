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
 * Main Author 2011: Adeel Asghar
 *
 */

#include "Legend.h"
#include "iostream"
#if QWT_VERSION < 0x060100
#include "qwt_legend_item.h"
#else
#include "qwt_legend_label.h"
#endif

using namespace OMPlot;

Legend::Legend(Plot *pParent)
{        
    setContextMenuPolicy(Qt::CustomContextMenu);
    connect(this,SIGNAL(customContextMenuRequested(const QPoint&)),this,SLOT(legendMenu(const QPoint&)));
    mpPlot = pParent;

    // create actions for context menu
    mpChangeColorAction = new QAction(QString(tr("Change Color")), this);
    connect(mpChangeColorAction, SIGNAL(triggered()), this, SLOT(selectColor()));

    mpAutomaticColorAction = new QAction(QString(tr("Automatic Color")), this);
    mpAutomaticColorAction->setCheckable(true);
    mpAutomaticColorAction->setChecked(true);
    connect(mpAutomaticColorAction, SIGNAL(triggered(bool)), this, SLOT(automaticColor(bool)));

    mpHideAction = new QAction(QString(tr("Hide")), this);
    mpHideAction->setCheckable(true);
    connect(mpHideAction, SIGNAL(triggered(bool)), this, SLOT(toggleHide(bool)));
}

Legend::~Legend()
{

}

void Legend::legendMenu(const QPoint& pos)
{        
#if QWT_VERSION >= 0x060100
  QwtLegendLabel *pItem = dynamic_cast<QwtLegendLabel*>(childAt(pos));
#else
  QwtLegendItem *pItem = dynamic_cast<QwtLegendItem*>(childAt(pos));
#endif
    if(pItem)
    {
        mLegendItemStr = pItem->text().text();
        /* context menu */
        QMenu menu(mpPlot);
        menu.addAction(mpChangeColorAction);
        menu.addAction(mpAutomaticColorAction);
        menu.addSeparator();
        menu.addAction(mpHideAction);
        menu.exec(mapToGlobal(pos));
    }
}

void Legend::selectColor()
{
    QColor c = QColorDialog::getColor();
    QList<PlotCurve*> list = mpPlot->getPlotCurvesList();

    if(c.isValid())
    {
        for(int i = 0; i < list.length(); i++)
        {
            if(list[i]->title() == mLegendItemStr)
            {
                list[i]->setCustomColor(true);
                QPen pen = list[i]->pen();
                pen.setColor(c);
                list[i]->setPen(pen);
                mpAutomaticColorAction->setChecked(false);
            }
        }
        mpPlot->replot();
    }
}

void Legend::toggleHide(bool hide)
{
    QList<PlotCurve*> list = mpPlot->getPlotCurvesList();

    for(int i = 0; i < list.length(); i++)
    {
        if(list[i]->title().text() == mLegendItemStr)
        {
            if (hide)
            {
                QwtText text = list[i]->title();
                text.setColor(QColor(Qt::gray));
                list[i]->setTitle(text);
                list[i]->setVisible(false);
            }
            else
            {
                QwtText text = list[i]->title();
                text.setColor(QColor(Qt::black));
                list[i]->setTitle(text.text());
                list[i]->setVisible(true);
            }
        }
    }
    mpPlot->replot();
}

void Legend::automaticColor(bool automatic)
{
    QList<PlotCurve*> list = mpPlot->getPlotCurvesList();

    for(int i = 0; i < list.length(); i++)
    {
        if(list[i]->title().text() == mLegendItemStr)
        {
            if (automatic)
            {
                list[i]->setCustomColor(false);
            }
            else
            {
                if (list[i]->hasCustomColor())
                {
                    list[i]->setCustomColor(true);
                }
                else
                {
                    mpAutomaticColorAction->blockSignals(true);
                    mpAutomaticColorAction->setChecked(true);
                    mpAutomaticColorAction->blockSignals(false);
                }
            }
        }
    }
    mpPlot->replot();
}

void Legend::setLegendItemStr(QString value)
{
  mLegendItemStr = value;
}

QAction* Legend::getAutomaticColorAction()
{
  return mpAutomaticColorAction;
}

QAction* Legend::getHideAction()
{
  return mpHideAction;
}
