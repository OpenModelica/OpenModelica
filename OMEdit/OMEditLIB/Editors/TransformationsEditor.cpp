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

#include "TransformationsEditor.h"
#include "Util/Helper.h"

#include <QMenu>

/*!
  \class TransformationsEditor
  \class TSourceEditor
  \brief An editor for Modelica Text used for Transformational Debugger.
  */
/*!
  \param pTransformationsWidget - pointer to TransformationsWidget
  */
TransformationsEditor::TransformationsEditor(TransformationsWidget *pTransformationsWidget)
  : BaseEditor(pTransformationsWidget)
{
  mpTransformationsWidget = pTransformationsWidget;
}

/*!
 * \brief TransformationsEditor::popUpCompleter()
 * \we do not have completer for this
 */
void TransformationsEditor::popUpCompleter()
{

}

/*!
 * \brief TransformationsEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void TransformationsEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = BaseEditor::createStandardContextMenu();
  pMenu->addSeparator();
  pMenu->addAction(mpToggleCommentSelectionAction);
  pMenu->addSeparator();
  pMenu->addAction(mpFoldAllAction);
  pMenu->addAction(mpUnFoldAllAction);
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

//! Slot activated when TSourceEditor's QTextDocument contentsChanged SIGNAL is raised.
void TransformationsEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (charsRemoved == 0 && charsAdded == 0)
    return;

  InfoBar *pInfoBar = mpTransformationsWidget->getTSourceEditorInfoBar();
  pInfoBar->showMessage(Helper::debuggingFileNotSaveInfo);
}
