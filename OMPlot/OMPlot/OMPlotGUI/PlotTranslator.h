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

#ifndef PLOTTRANSLATOR_H
#define PLOTTRANSLATOR_H

#include <QString>
#include <QTranslator>

namespace OMPlot
{
/*!
 * \brief loadTranslation
 * Loads the OMPlot translation OMPlot_<locale>.qm from <installationDirectory>/share/omplot/nls.
 * The caller installs the translator in its application. Every program that shows OMPlot
 * widgets (OMEdit, OMNotebook, OMPlot) does this, so the strings of OMPlot are translated
 * in one place only.
 * \param translator the translator to load the translation into
 * \param installationDirectory the OpenModelica installation directory
 * \param locale the locale name, e.g. de_DE
 * \return true if the translation was loaded
 */
bool loadTranslation(QTranslator &translator, const QString &installationDirectory, const QString &locale);
}

#endif // PLOTTRANSLATOR_H
