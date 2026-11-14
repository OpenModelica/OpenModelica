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

#ifndef CRMLVERIFICATIONGENERATOR_H
#define CRMLVERIFICATIONGENERATOR_H

#include "BindingEngine.h"

namespace CRMLBindings {

/*! A requirement status output of the verification model, read back for the dashboard. */
struct RequirementStatusVariable {
  QString mComponent;   // e.g. R2_pump1_status; its output y is the status
  QString mRequirement;
  QString mElement;     // empty for a top level requirement
  int mLine = 0;        // line of the requirement in the CRML file
};

/*! The requirement status at the end of a simulation run (D2.1.1 3.5 step 6). */
enum class RequirementResult { Satisfied, Violated, Undecided };
QString requirementResultToString(RequirementResult result);
/*! Maps the end value of a CRMLtoModelica.Types.Boolean4 status: true4 is satisfied, false4 violated, else undecided. */
RequirementResult requirementResultFromBoolean4(int value);

/*!
 * Writes the verification package of a resolved configuration: the translated requirement model,
 * the behaviour model instance, the architecture parameters, the binding equations and one status
 * per requirement. The source models are never changed.
 */
class VerificationGenerator
{
public:
  static constexpr const char *verificationModelName = "Verification";

  VerificationGenerator(const VerificationConfiguration &configuration, const CrmlExternals &externals,
                        const ModelIndex &index, const Resolution &resolution);
  /*!
   * Returns the package text. translatedRequirement is the Modelica text the CRML compiler wrote for
   * the requirement model; its within clause is dropped.
   */
  QString generate(const QString &translatedRequirement);
  QString packageName() const;
  QString verificationModel() const {return packageName() + "." + verificationModelName;}
  const QList<RequirementStatusVariable> &statusVariables() const {return mStatusVariables;}
  static QString toModelica(const QJsonValue &value);
private:
  const VerificationConfiguration &mConfiguration;
  const CrmlExternals &mExternals;
  const ModelIndex &mIndex;
  const Resolution &mResolution;
  QList<RequirementStatusVariable> mStatusVariables;
};

} // namespace CRMLBindings

#endif // CRMLVERIFICATIONGENERATOR_H
