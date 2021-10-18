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
    mDynamic = mExp.isCall("DynamicSelect");
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
  if (mDynamic) {
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
 * \brief DynamicAnnotation::update
 * Calls the derived class' fromExp method with the static part of the stored
 * expression (either the expression itself, or the first argument if it's a
 * DynamicSelect call).
 */
void DynamicAnnotation::reset()
{
  fromExp(mDynamic ? mExp.arg(0) : mExp);
}
