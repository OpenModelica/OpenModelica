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
#ifndef DYNAMICANNOTATION_H
#define DYNAMICANNOTATION_H

#include <QString>
#include "FlatModelica/Expression.h"

class Element;
namespace ModelInstance
{
  class Model;
}

/*!
 * \class DynamicAnnotation
 * \brief Base class for DynamicSelect-aware types.
 *
 * This class implements the generic parts of handling annotations with
 * DynamicSelect, like parsing and evaluating the annotation expression.
 *
 * Derived classes don't have to handle DynamicSelect directly, they just need
 * to implement fromExp for the type they're representing and will then be given
 * the static or dynamic expression for a certain time point when parse, update
 * or reset is called.
 *
 * parse will call fromExp with the static expression (the expression itself or
 * the first argument if it's a DynamicSelect call), while update calls fromExp
 * with the dynamic expression (second argument if it's a DynamicSelect call)
 * evaluated for a given time point. reset will call fromExp with either the
 * static or the dynamic expression depending on whether the expression is a
 * DynamicSelect call and update has been called.
 */
class DynamicAnnotation
{
  public:
    enum State
    {
      None,
      Static,
      Dynamic
    };

  public:
    DynamicAnnotation();
    virtual ~DynamicAnnotation() = 0;

    bool parse(const QString &str);
    bool deserialize(const QJsonValue &value);
    bool update(double time, ModelInstance::Model *pModel);
    void evaluate(ModelInstance::Model *pModel);
    void reset();
    void resetDynamicToStatic();
    virtual void clear() = 0;
    virtual FlatModelica::Expression toExp() const = 0;
    bool isDynamicSelectExpression() const;
    QString toQString() const;
    QJsonValue serialize() const;

  private:
    FlatModelica::Expression evaluate_helper(FlatModelica::Expression *pExpression, ModelInstance::Model *pModel, bool readFromResultFileForDynamicSelect, double time);

  protected:
    virtual void fromExp(const FlatModelica::Expression &exp) = 0;
    void setExp();

  protected:
    FlatModelica::Expression mExp;
    State mState = State::None;
};

#endif /* DYNAMICANNOTATION_H */
