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

#include "Style.h"

#include <QApplication>

/*!
 * \brief Style::isDarkMode
 * \return true when OMEdit was started with --DarkMode=true.
 */
bool Style::isDarkMode()
{
  return qApp->property("omeditDarkMode").toBool();
}

/*!
 * \brief Style::pick
 * Returns the color for the current mode.
 */
QColor Style::pick(const QColor &lightColor, const QColor &darkColor)
{
  return isDarkMode() ? darkColor : lightColor;
}

/*!
 * \brief Style::darkPalette
 * The dark palette. Widgets take their colors from here; stylesheet-dark.qss
 * only restyles what stylesheet.qss restyles.
 */
QPalette Style::darkPalette()
{
  QPalette palette;
  const QColor window(32, 33, 36);
  /* Base sits visibly above Window: Fusion draws check box and radio
   * indicators with the Base color, and before Qt 6.9.2 their outline is
   * derived from Window, so the two must not share one brightness. */
  const QColor base(31, 41, 55);
  const QColor alternateBase(55, 65, 81);
  const QColor text(243, 244, 246);
  const QColor button(55, 65, 81);
  const QColor disabledText(156, 163, 175);
  const QColor highlight(29, 78, 216);
  const QColor link(96, 165, 250);
  palette.setColor(QPalette::Window, window);
  palette.setColor(QPalette::WindowText, text);
  palette.setColor(QPalette::Base, base);
  palette.setColor(QPalette::AlternateBase, alternateBase);
  palette.setColor(QPalette::Text, text);
  palette.setColor(QPalette::PlaceholderText, disabledText);
  palette.setColor(QPalette::Button, button);
  palette.setColor(QPalette::ButtonText, text);
  palette.setColor(QPalette::BrightText, Qt::white);
  palette.setColor(QPalette::Highlight, highlight);
  palette.setColor(QPalette::HighlightedText, Qt::white);
  palette.setColor(QPalette::ToolTipBase, base);
  palette.setColor(QPalette::ToolTipText, text);
  palette.setColor(QPalette::Link, link);
  palette.setColor(QPalette::LinkVisited, QColor(192, 132, 252));
  palette.setColor(QPalette::Light, QColor(107, 114, 128));
  palette.setColor(QPalette::Midlight, QColor(75, 85, 99));
  palette.setColor(QPalette::Mid, QColor(43, 45, 49));
  palette.setColor(QPalette::Dark, QColor(24, 24, 27));
  palette.setColor(QPalette::Shadow, Qt::black);
  palette.setColor(QPalette::Disabled, QPalette::WindowText, disabledText);
  palette.setColor(QPalette::Disabled, QPalette::Text, disabledText);
  palette.setColor(QPalette::Disabled, QPalette::ButtonText, disabledText);
  palette.setColor(QPalette::Disabled, QPalette::Highlight, QColor(55, 65, 81));
  palette.setColor(QPalette::Disabled, QPalette::HighlightedText, disabledText);
  return palette;
}

/*!
 * \brief Style::completerToolTipPenColor
 * Frame of the completer tool tip.
 */
QColor Style::completerToolTipPenColor()
{
  return pick(Qt::black, QColor(107, 114, 128));
}

/*!
 * \brief Style::completerToolTipBrushColor
 * Background of the completer tool tip.
 */
QColor Style::completerToolTipBrushColor()
{
  return pick(Qt::white, QColor(31, 41, 55));
}

/*!
 * \brief Style::lineNumberAreaBackgroundColor
 * Background of the line number area.
 */
QColor Style::lineNumberAreaBackgroundColor()
{
  return pick(QColor(240, 240, 240), QColor(31, 41, 55));
}

/*!
 * \brief Style::lineNumberColor
 * Line numbers and folding markers.
 */
QColor Style::lineNumberColor()
{
  return pick(Qt::gray, QColor(156, 163, 175));
}

/*!
 * \brief Style::currentLineNumberColor
 * Line number of the line that holds the cursor.
 */
QColor Style::currentLineNumberColor()
{
  return pick(QColor(64, 64, 64), QColor(229, 231, 235));
}

/*!
 * \brief Style::currentLineHighlightColor
 * Background of the line that holds the cursor.
 */
QColor Style::currentLineHighlightColor()
{
  return pick(QColor(232, 242, 254), QColor(38, 47, 61));
}

/*!
 * \brief Style::readOnlyEditorStyleSheet
 * Gray background that makes a read-only editor look disabled.
 */
QString Style::readOnlyEditorStyleSheet()
{
  return QString("QPlainTextEdit[readOnly=\"true\"] { background-color: %1 }").arg(isDarkMode() ? "#1f2937" : "#f0f0f0");
}

/*!
 * \brief Style::infoBarBackgroundColor
 * Background of the info bars shown above an editor.
 */
QColor Style::infoBarBackgroundColor()
{
  return pick(QColor(255, 255, 225), QColor(31, 41, 55));
}

/*!
 * \brief Style::infoBarTextColor
 * Text of the info bars shown above an editor.
 */
QColor Style::infoBarTextColor()
{
  return pick(Qt::black, QColor(232, 234, 237));
}

/*!
 * \brief Style::documentationPageBackgroundColor
 * Painted behind the documentation page in dark mode; equals the palette Window color.
 */
QColor Style::documentationPageBackgroundColor()
{
  return QColor(32, 33, 36);
}

/*!
 * \brief Style::welcomePageMainFrameStyleSheet
 * Style sheet of the welcome page frame.
 */
QString Style::welcomePageMainFrameStyleSheet()
{
  return isDarkMode() ? "QFrame{color: palette(light);}" : "QFrame{color:gray;}";
}

/*!
 * \brief Style::welcomePagePanelStyleSheet
 * Style sheet of the welcome page panels (recent files, recent models, news).
 */
QString Style::welcomePagePanelStyleSheet()
{
  return isDarkMode() ? "QFrame{background-color: palette(base);}" : "QFrame{background-color: white;}";
}
