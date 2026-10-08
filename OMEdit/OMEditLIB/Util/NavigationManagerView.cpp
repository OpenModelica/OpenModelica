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
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include "Util/NavigationManagerView.h"

#include "Editors/BaseEditor.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Util/StringHandler.h"

#include <QLabel>
#include <QListWidget>
#include <QMdiSubWindow>
#include <QVBoxLayout>

/*!
 * \class NavigationManagerView
 * \brief A debug view for the navigation history of the NavigationManager.
 */

/*!
 * \brief NavigationManagerView::NavigationManagerView
 * \param pParent
 */
NavigationManagerView::NavigationManagerView(QWidget *pParent)
  : QWidget(pParent)
{
  mpPositionLabel = new QLabel(this);
  mpListWidget = new QListWidget(this);
  mpListWidget->setEditTriggers(QAbstractItemView::NoEditTriggers);
  // layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(mpPositionLabel);
  pMainLayout->addWidget(mpListWidget);
  setLayout(pMainLayout);
  // keep the view updated whenever the navigation history changes
  connect(NavigationManager::instance(), SIGNAL(navigationChanged()), SLOT(refresh()));
  refresh();
}

/*!
 * \brief NavigationManagerView::refresh
 * Repopulates the list from the current navigation history and highlights the
 * current position.
 */
void NavigationManagerView::refresh()
{
  mpListWidget->clear();
  NavigationManager *pNavigationManager = NavigationManager::instance();
  const QVector<NavigationManager::NavigationPoint> navigationPoints = pNavigationManager->getNavigationPoints();
  const int navigationPosition = pNavigationManager->getNavigationPosition();
  mpPositionLabel->setText(QString("Position: %1 of %2").arg(navigationPosition + 1).arg(navigationPoints.size()));
  QPalette palette = mpListWidget->palette();
  for (int i = 0; i < navigationPoints.size(); ++i) {
    QListWidgetItem *pItem = new QListWidgetItem(navigationPointText(navigationPoints.at(i)), mpListWidget);
    if (i == navigationPosition) {
      QFont font = pItem->font();
      font.setBold(true);
      pItem->setFont(font);
      pItem->setBackground(palette.highlight());
      pItem->setForeground(palette.highlightedText());
    }
  }
}

/*!
 * \brief NavigationManagerView::navigationPointText
 * Returns a human readable description of the given navigation point.
 * \param navigationPoint
 * \return
 */
QString NavigationManagerView::navigationPointText(const NavigationManager::NavigationPoint &navigationPoint) const
{
  switch (navigationPoint.type) {
    case NavigationManager::NavigationPoint::Type::Editor: {
      PlainTextEdit *pEditor = navigationPoint.editor;
      QString name;
      if (pEditor) {
        BaseEditor *pBaseEditor = pEditor->getBaseEditor();
        if (pBaseEditor && pBaseEditor->getModelWidget() && pBaseEditor->getModelWidget()->getLibraryTreeItem()) {
          name = pBaseEditor->getModelWidget()->getLibraryTreeItem()->getNameStructure();
        } else {
          name = "Editor";
        }
      } else {
        name = "Deleted editor";
      }
      return QString("Editor: %1 @ %2").arg(name).arg(navigationPoint.position);
    }
    case NavigationManager::NavigationPoint::Type::View: {
      ModelWidget *pModelWidget = navigationPoint.modelWidget;
      QString name;
      if (pModelWidget && pModelWidget->getLibraryTreeItem()) {
        name = pModelWidget->getLibraryTreeItem()->getNameStructure();
      } else {
        name = "Deleted model";
      }
      return QString("View: %1 (%2)").arg(name, StringHandler::getViewType(navigationPoint.viewType));
    }
    case NavigationManager::NavigationPoint::Type::Perspective: {
      QStringList perspectiveNames;
      perspectiveNames << "Welcome" << "Modeling" << "Plotting" << "Debugging";
      QString name;
      if (navigationPoint.perspectiveIndex >= 0 && navigationPoint.perspectiveIndex < perspectiveNames.size()) {
        name = perspectiveNames.at(navigationPoint.perspectiveIndex);
      } else {
        name = QString::number(navigationPoint.perspectiveIndex);
      }
      return QString("Perspective: %1").arg(name);
    }
    case NavigationManager::NavigationPoint::Type::Plot: {
      QMdiSubWindow *pSubWindow = navigationPoint.plotSubWindow;
      QString name;
      if (pSubWindow && pSubWindow->widget()) {
        name = pSubWindow->widget()->windowTitle();
      } else {
        name = "Deleted plot window";
      }
      return QString("Plot: %1").arg(name);
    }
  }
  return QString();
}
