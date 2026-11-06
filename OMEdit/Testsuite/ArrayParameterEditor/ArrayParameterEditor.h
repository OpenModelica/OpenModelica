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
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENT'S CHOICE.
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

#ifndef ARRAYPARAMETEREDITOR_H
#define ARRAYPARAMETEREDITOR_H

#include <QObject>

/*!
 * \brief The ArrayParameterEditor class
 * Tests the array editor button of the element parameters dialog and the
 * ArrayParameterEditorDialog serialization.
 */
class ArrayParameterEditor : public QObject
{
  Q_OBJECT
private slots:
  void initTestCase();
  /*!
   * \brief arrayEditorButtonExistsForArrayParameters
   * Checks that the array editor button is shown for array parameters and
   * hidden for scalar parameters in the element parameters dialog.
   */
  void arrayEditorButtonExistsForArrayParameters();
  /*!
   * \brief arrayParameterEditorDialogSerializesArrayLiterals
   * Checks that ArrayParameterEditorDialog parses array literals into cells
   * and serializes them using curly brace syntax e.g. {{1,2},{3,4}}.
   */
  void arrayParameterEditorDialogSerializesArrayLiterals();
  /*!
   * \brief arrayParameterEditorDialogParsesCurlyBraces
   * Checks that ArrayParameterEditorDialog parses curly brace array literals and that
   * serialization always uses curly braces.
   */
  void arrayParameterEditorDialogParsesCurlyBraces();
  /*!
   * \brief arrayDimensionsConstrainEditorShape
   * Checks that literal and typed dimensions control the editor while ':' dimensions remain editable.
   */
  void arrayDimensionsConstrainEditorShape();
  /*!
   * \brief arrayTableContextMenuDeletesSelection
   * Checks that selected rows and columns can be deleted from the array table.
   */
  void arrayTableContextMenuDeletesSelection();
  /*!
   * \brief arrayParameterEditorDialogHandlesThreeDimensionalArray
   * Checks that a 3D array literal is shown as a 2D table where each cell holds
   * a nested vector and that serialization recreates the nested 3D literal.
   */
  void arrayParameterEditorDialogHandlesThreeDimensionalArray();
  void cleanupTestCase();
};

#endif // ARRAYPARAMETEREDITOR_H
