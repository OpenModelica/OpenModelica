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
 * @author John Tinnerholm
 */

#ifndef XMILETRANSLATOR_H
#define XMILETRANSLATOR_H

#include <QString>
#include <QStringList>

/*!
 * \brief Translates System Dynamics models (XMILE: .xmile, .stmx, .itmx) to Modelica with XMILEToModelica.jl.
 * The translator is the shared library libxmile2mo (C functions xmile2mo_translate and xmile2mo_error,
 * loaded once and kept loaded) or the executable xmile2mo (run as a process).
 */
class XMILETranslator
{
public:
  // The form of the Modelica model (the values of the argument modular of xmile2mo_translate): a block per variable with
  // the stock and flow diagram (Blocks: the blocks of a large model without a diagram in sectors), or the flat model
  enum Form {Flat = 0, Blocks = 1, BlocksWithoutSectors = 2, BlocksInSectors = 3};
  struct Options {
    QString input;         // the XMILE file
    QString output;        // the Modelica file to write
    QString name;          // the name of the Modelica model
    Form form = Blocks;
    QStringList excel;     // Excel workbooks with time series the model uses but does not define
  };
  static QString translator();
  static QString savedTranslator();
  static void setTranslator(const QString &path);
  static QString findTranslator();
  static bool translate(const Options &options, QString *pError);
  static QString modelName(const QString &fileName);
private:
  static bool translateWithLibrary(const QString &library, const Options &options, QString *pError);
  static bool translateWithExecutable(const QString &executable, const Options &options, QString *pError);
};

#endif // XMILETRANSLATOR_H
