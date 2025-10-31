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
#include <QDebug>

#include "Element/Element.h"
#include "Plotting/VariablesWidget.h"
#include "Modeling/Model.h"

DynamicAnnotation::DynamicAnnotation() = default;

DynamicAnnotation::~DynamicAnnotation() = default;

/*!
 * \brief DynamicAnnotation::parse
 * Parses an annotation expression string and stores the expression, then either
 * calls reset or clear based on whether the parsing succeeded or not.
 */
bool DynamicAnnotation::parse(const QString &str)
{
  try {
    mExp = FlatModelica::Expression::parse(str);
    mState = mExp.isCall("DynamicSelect") ? State::Static : State::None;
    reset();
  } catch (const std::exception &e) {
    qDebug() << "Failed to parse annotation: " << str;
    qDebug() << e.what();
    clear();
    return false;
  }
  return true;
}

/*!
 * \brief DynamicAnnotation::deserialize
 * Deserialize an annotation expression json and stores the expression, then either
 * calls reset or clear based on whether the deserializing succeeded or not.
 * \param value
 * \return
 */
bool DynamicAnnotation::deserialize(const QJsonValue &value)
{
  try {
    if (value.isObject()) {
      QJsonObject valueObject = value.toObject();
      if (valueObject.contains("$error")) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, valueObject.value("$error").toString(), Helper::scriptingKind, Helper::errorLevel));
        return false;
      }
    }
    mExp.deserialize(value);
    mState = mExp.isCall("DynamicSelect") ? State::Static : State::None;
    reset();
  } catch (const std::exception &e) {
    qDebug() << "Failed to deserialize json: " << value;
    qDebug() << e.what();
    clear();
    return false;
  }
  return true;
}

/*!
 * \brief DynamicAnnotation::update
 * Evaluates the second argument for a given time point if the stored expression
 * is a DynamicSelect call, then passes the evaluated expression to the derived
 * class via fromExp. If the stored expression is not a DynamicSelect call then
 * nothing is done.
 * \param time
 * \param pModel
 * \return true if the expression was updated, otherwise false.
 */
bool DynamicAnnotation::update(double time, ModelInstance::Model *pModel)
{
  if (isDynamicSelectExpression()) {
    mState = State::Dynamic;

    FlatModelica::Expression expression;
    expression = mExp.arg(1);

    if (!expression.isNull()) {
      fromExp(evaluate_wrap_helper(&expression, pModel, true, time, ""));
    }
    return true;
  }

  return false;
}

/*!
 * \brief DynamicAnnotation::evaluate
 * Evaluates the expression using the containing model.
 * Containing model provides the binding variable value.
 * If expression is DynamicSelect then use the static part of the expression.
 * \param pModel
 * \param instanceName - instanceName is prepended to the variable name while evaluating.
 *                       It is used when we go in nested ElementParameters.
 */
void DynamicAnnotation::evaluate(ModelInstance::Model *pModel, const QString &instanceName)
{
  /* Avoid expression evaluation when skip expression evaluation flag is set.
   * We skip expression evaluation when we call getModelInstance for icon.
   */
  if (!MainWindow::instance()->isSkipExpressionEvaluation()) {
    FlatModelica::Expression expression;
    if (isDynamicSelectExpression()) {
      expression = mExp.arg(0);
    } else {
      expression = mExp;
    }
    if (!expression.isNull()) {
      fromExp(evaluate_wrap_helper(&expression, pModel, false, 0.0, instanceName));
    }
  }
}

/*!
 * \brief DynamicAnnotation::reset
 * Calls the derived class' fromExp method with either the static or the dynamic
 * part of the stored expression. The static part is used if the expression
 * isn't using DynamicSelect or update hasn't been called, and the dynamic is
 * used if update has been called on a DynamicSelect expression.
 */
void DynamicAnnotation::reset()
{
  switch (mState) {
    case State::None:
      fromExp(mExp);
      break;

    case State::Static:
      fromExp(mExp.arg(0));
      break;

    case State::Dynamic:
      fromExp(mExp.arg(1));
      break;
  }
}

/*!
 * \brief DynamicAnnotation::resetDynamicToStatic
 * Resets from dynamic to static.
 */
void DynamicAnnotation::resetDynamicToStatic()
{
  if (mState == State::Dynamic) {
    mState = State::Static;
    reset();
  }
}

/*!
 * \brief DynamicAnnotation::isDynamicSelectExpression
 * Returns true if state is not none. DynamicSelect doesn't have state none.
 * \return
 */
bool DynamicAnnotation::isDynamicSelectExpression() const
{
  return mState != State::None;
}

/*!
 * \brief DynamicAnnotation::toQString
 * Unparses the Annotation into a string.
 * \return
 */
QString DynamicAnnotation::toQString() const
{
  return mExp.toQString();
}

/*!
 * \brief DynamicAnnotation::serialize
 * Unparses the Annotation into a JSON value.
 * \return
 */
QJsonValue DynamicAnnotation::serialize() const
{
  return mExp.serialize();
}

/*!
 * \brief DynamicAnnotation::evaluate_wrap_helper
 * Helper function for DynamicAnnotation::evaluate and DynamicAnnotation::update.
 * \param pExpression
 * \param pModel
 * \param readFromResultFileForDynamicSelect
 * \param time
 * \param instanceName
 * \return
 */
FlatModelica::Expression DynamicAnnotation::evaluate_wrap_helper(FlatModelica::Expression *pExpression, ModelInstance::Model *pModel,
                                                                 bool readFromResultFileForDynamicSelect, double time, const QString &instanceName)
{
  FlatModelica::Expression bindingExpression = evaluate_helper(pExpression, pModel, readFromResultFileForDynamicSelect, time, false, instanceName);

  // if we fail to evaluate using binding values then try with expresison value.
  if (bindingExpression.isNull() && !readFromResultFileForDynamicSelect) {
    // qDebug() << "Using value to evaluate expression.";
    FlatModelica::Expression valueExpression = evaluate_helper(pExpression, pModel, readFromResultFileForDynamicSelect, time, true, instanceName);
    // if we fail to evaluate using value then return the original expresison.
    if (valueExpression.isNull()) {
      return *pExpression;
    } else {
      // qDebug() << "valueExpression is:" << valueExpression.toQString() << valueExpression.isNull();
      return valueExpression;
    }
  } else {
    // qDebug() << "bindingExpression is:" << bindingExpression.toQString() << bindingExpression.isNull();
    return bindingExpression;
  }
}

/*!
 * \brief DynamicAnnotation::evaluate_helper
 * Helper function for DynamicAnnotation::evaluate_wrap_helper
 * \param pExpression
 * \param pModel
 * \param readFromResultFileForDynamicSelect
 * \param time - only used when readFromResultFileForDynamicSelect is true.
 * \param instanceName
 * \return
 */
FlatModelica::Expression DynamicAnnotation::evaluate_helper(FlatModelica::Expression *pExpression, ModelInstance::Model *pModel,
                                                            bool readFromResultFileForDynamicSelect, double time, bool value, const QString &instanceName)
{
  try {
    auto expression = pExpression->evaluate([&](std::string name) -> auto {
      auto vname = QString::fromStdString(name);
      if (!instanceName.isEmpty() && !vname.startsWith(instanceName + ".")) {
        vname = instanceName + "." + vname;
      }
      if (readFromResultFileForDynamicSelect) {
        QPair<double, bool> value = MainWindow::instance()->getVariablesWidget()->readVariableValue(vname, time, false);
        if (value.second) {
          return FlatModelica::Expression(value.first);
        } else {
          throw std::runtime_error(vname.toStdString() + " could not be found in " + pModel->getName().toStdString());
        }
      } else {
        // qDebug() << "Evaluating variable:" << vname << "from model:" << (pModel ? pModel->getName() : "null") << "using value:" << value;
        auto valueOrBindingExpression = pModel ? pModel->getVariableValueOrBinding(vname, value) : nullptr;
        if (!valueOrBindingExpression) {
          throw std::runtime_error(vname.toStdString() + " could not be found in " + pModel->getName().toStdString());
        } else {
          return *valueOrBindingExpression;
        }
      }
    });

    if (!value && !expression.isLiteral()) {
      // qDebug() << "Expression is not literal:" << expression.toQString();
      return evaluate_helper(&expression, pModel, readFromResultFileForDynamicSelect, time, value, instanceName);
    } else {
      // qDebug() << "Expression is literal:" << expression.toQString() << expression.isNull();
      return expression;
    }
  } catch (const std::exception &e) {
    if (MainWindow::instance()->isDebug()) {
      qDebug() << "Failed to evaluate expression.";
      qDebug() << e.what();
    }

    return FlatModelica::Expression();
  }
}

void DynamicAnnotation::setExp()
{
  if (mState == State::None) {
    mExp = toExp();
  } else {
    mExp.setArg(0, toExp());
  }
}
