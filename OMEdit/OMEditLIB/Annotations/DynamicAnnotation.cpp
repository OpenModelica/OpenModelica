#include <QDebug>

#include "Element/Element.h"
#include "Plotting/VariablesWidget.h"

DynamicAnnotation::DynamicAnnotation() = default;

DynamicAnnotation::DynamicAnnotation(const QString &str)
{
  parse(str);
}

DynamicAnnotation::~DynamicAnnotation() = default;

/*!
 * \brief DynamicAnnotation::parse
 * Parses an annotation expression string and stores the expression, then either
 * calls reset or clear based on whether the parsing succeeded or not.
 */
void DynamicAnnotation::parse(const QString &str)
{
  try {
    mExp = FlatModelica::Expression::parse(str);
    mState = mExp.isCall("DynamicSelect") ? State::Static : State::None;
    reset();
  } catch (const std::exception &e) {
    qDebug() << "Failed to parse annotation: " << str;
    qDebug() << e.what();
    clear();
  }
}

/*!
 * \brief DynamicAnnotation::update
 * Evaluates the second argument for a given time point if the stored expression
 * is a DynamicSelect call, then passes the evaluated expression to the derived
 * class via fromExp. If the stored expression is not a DynamicSelect call then
 * nothing is done.
 * \return true if the expression was updated, otherwise false.
 */
bool DynamicAnnotation::update(double time, Element *parent)
{
  if (mState != State::None) {
    mState = State::Dynamic;

    fromExp(mExp.arg(1).evaluate([&] (std::string name) {
      auto vname = QString::fromStdString(name);

      if (parent && parent->getComponentInfo()) {
        vname = QString("%1.%2").arg(parent->getName(), vname);
      }

      return MainWindow::instance()->getVariablesWidget()->readVariableValue(vname, time);
    }));
    return true;
  }

  return false;
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

void DynamicAnnotation::setExp()
{
  if (mState == State::None) {
    mExp = toExp();
  } else {
    mExp.setArg(0, toExp());
  }
}
