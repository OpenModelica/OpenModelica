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
 * @author bakemocho <bake@seimei.do>
 */

#ifndef STYLE_H
#define STYLE_H

#include <QColor>
#include <QPalette>
#include <QString>

/*!
 * \class Style
 * \brief Colors and style sheets that differ between light and dark mode.
 *
 * Dark mode is chosen at startup with --DarkMode=true and stored as the
 * application property "omeditDarkMode". Widgets that paint their own colors
 * ask this class instead of branching on the property themselves. User
 * configurable colors (editor syntax, messages) stay in OptionsDialog.
 */
class Style
{
public:
  static bool isDarkMode();
  static QColor pick(const QColor &lightColor, const QColor &darkColor);
  static QPalette darkPalette();
  // editors
  static QColor completerToolTipPenColor();
  static QColor completerToolTipBrushColor();
  static QColor lineNumberAreaBackgroundColor();
  static QColor lineNumberColor();
  static QColor currentLineNumberColor();
  static QColor currentLineHighlightColor();
  static QString readOnlyEditorStyleSheet();
  static QColor infoBarBackgroundColor();
  static QColor infoBarTextColor();
  // documentation
  static QColor documentationPageBackgroundColor();
  // welcome page
  static QString welcomePageMainFrameStyleSheet();
  static QString welcomePagePanelStyleSheet();
};

#endif // STYLE_H
