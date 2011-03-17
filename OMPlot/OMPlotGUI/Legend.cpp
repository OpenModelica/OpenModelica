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
#include "qwt_legend_item.h"

using namespace OMPlot;

Legend::Legend(Plot *pParent)
{        
    setContextMenuPolicy(Qt::CustomContextMenu);
    connect(this,SIGNAL(customContextMenuRequested(const QPoint&)),this,SLOT(legendMenu(const QPoint&)));
    mpPlot = pParent;
}

Legend::~Legend()
{

}

void Legend::legendMenu(const QPoint& pos)
{        
    QwtLegendItem *lgdItem = dynamic_cast<QwtLegendItem*>(childAt(pos));

    QAction *color = new QAction(QString("Change Color"), this);
    color->setCheckable(false);
    connect(color, SIGNAL(triggered()), this, SLOT(selectColor()));

    QAction *hide;
    if(lgdItem->text().color() == Qt::gray)
        hide = new QAction(QString("Show"), this);
    else
        hide = new QAction(QString("Hide"), this);
    hide->setCheckable(false);
    connect(hide, SIGNAL(triggered()), this, SLOT(toggleShow()));

    if(lgdItem)
    {
        legendItem = lgdItem->text().text();

        QMenu menu(mpPlot);        
        menu.addAction(color);
        menu.addSeparator();
        menu.addAction(hide);
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
            if(list[i]->title() == legendItem)
                list[i]->setPen(QPen(c));
        }
        mpPlot->replot();
    }
}

void Legend::toggleShow()
{
    QList<PlotCurve*> list = mpPlot->getPlotCurvesList();

    for(int i = 0; i < list.length(); i++)
    {
        if(list[i]->title().text() == legendItem)
        {
            if(list[i]->isVisible())
            {
                QwtText text = list[i]->title();
                text.setColor(QColor(Qt::gray));
                list[i]->setTitle(text);
                list[i]->setVisible(false);
            }
            else if(!list[i]->isVisible())
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
