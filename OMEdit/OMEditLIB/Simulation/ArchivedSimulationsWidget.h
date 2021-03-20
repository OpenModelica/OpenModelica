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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */
#ifndef ARCHIVEDSIMULATIONSWIDGET_H
#define ARCHIVEDSIMULATIONSWIDGET_H

#include <QTreeWidget>

class ArchivedSimulationItem : public QTreeWidgetItem
{
public:
  ArchivedSimulationItem(const QString &name, const double startTime, const double stopTime, QWidget *pSimulationOutputWidget);
  QWidget* getSimulationOutputWidget() {return mpSimulationOutputWidget;}
  void setStatus(QString status);
private:
  QWidget *mpSimulationOutputWidget;
};

/*!
 * \class ArchivedSimulationsWidget
 * \brief Shows the list of archived simulations.
 */
class ArchivedSimulationsWidget : public QWidget
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  ArchivedSimulationsWidget(QWidget *pParent = 0);

  static ArchivedSimulationsWidget *mpInstance;
  QTreeWidget *mpArchivedSimulationsTreeWidget;
public:
  static ArchivedSimulationsWidget* instance() {return mpInstance;}
  QTreeWidget* getArchivedSimulationsTreeWidget() {return mpArchivedSimulationsTreeWidget;}

  /*!
   * \brief show
   * Reads the geometry from settings and shows the widget.
   */
  void show();
public slots:
  /*!
   * \brief showArchivedSimulation
   * Slot activated when mpArchivedSimulationsListWidget itemDoubleClicked signal is raised.\n
   * Shows the archived simulation.
   * \param pTreeWidgetItem
   */
  void showArchivedSimulation(QTreeWidgetItem *pTreeWidgetItem);

  // QWidget interface
protected:
  /*!
   * \brief keyPressEvent
   * Closes the on ESC key.
   * \param event
   */
  virtual void keyPressEvent(QKeyEvent *event) override;
  /*!
   * \brief closeEvent
   * Saves the geometry in settings.
   * \param event
   */
  virtual void closeEvent(QCloseEvent *event) override;
};

#endif // ARCHIVEDSIMULATIONSWIDGET_H
