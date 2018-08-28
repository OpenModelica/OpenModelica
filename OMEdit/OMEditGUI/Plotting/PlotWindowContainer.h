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

#ifndef PLOTWINDOWCONTAINER_H
#define PLOTWINDOWCONTAINER_H

#if !defined(WITHOUT_OSG)
#include "Animation/AnimationWindow.h"
#endif

#include "Util/Utilities.h"
#include "OMPlot.h"

class AnimationWindow;
class DiagramWindow;
class VariablesTreeItem;

class PlotWindowContainer : public QMdiArea
{
  Q_OBJECT
public:
  PlotWindowContainer(QWidget *pParent = 0);
  QString getUniqueName(QString name = QString("Plot"), int number = 1);
  OMPlot::PlotWindow* getCurrentWindow();
  OMPlot::PlotWindow* getInteractiveWindow(QString targetWindow);
  OMPlot::PlotWindow* getTopPlotWindow();
  void setTopPlotWindowActive();
#if !defined(WITHOUT_OSG)
  AnimationWindow* getCurrentAnimationWindow();
#endif
  QMdiSubWindow* getDiagramSubWindowFromMdi();
  DiagramWindow* getDiagramWindow() {return mpDiagramWindow;}
  bool isPlotWindow(QObject *pObject);
  bool isAnimationWindow(QObject *pObject);
  bool isDiagramWindow(QObject *pObject);
  bool eventFilter(QObject *pObject, QEvent *pEvent);
private:
  DiagramWindow *mpDiagramWindow;
public slots:
  void addPlotWindow(bool maximized = false);
  void addParametricPlotWindow();
  void addArrayPlotWindow(bool maximized = false);
  void addArrayParametricPlotWindow();
  OMPlot::PlotWindow* addInteractivePlotWindow(bool maximized = false, QString owner = QString(), int port = 0);
  void addAnimationWindow(bool maximized = false);
  void addDiagramWindow(bool maximized = false);
  void clearPlotWindow();
  void removeInteractivePlotWindow();
  void exportVariables();
  void updatePlotWindows(QString variable);
};

#endif // PLOTWINDOWCONTAINER_H
