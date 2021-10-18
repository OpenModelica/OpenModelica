#ifndef DYNAMICANNOTATION_H
#define DYNAMICANNOTATION_H

#include <QString>
#include "FlatModelica/Expression.h"

class Element;

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
 * parse and reset will call fromExp with the static expression (the expression
 * itself or the first argument if it's a DynamicSelect call), while update
 * calls fromExp with the dynamic expression (second argument if it's a
 * DynamicSelect call) evaluated for a given time point.
 */
class DynamicAnnotation
{
  public:
    DynamicAnnotation();
    DynamicAnnotation(const QString &str);
    virtual ~DynamicAnnotation() = 0;

    void parse(const QString &str);
    bool update(double time, Element *parent);
    void reset();
    virtual void clear() = 0;

  protected:
    virtual void fromExp(const FlatModelica::Expression &exp) = 0;

  protected:
    FlatModelica::Expression mExp;
    bool mDynamic = false;
};

#endif /* DYNAMICANNOTATION_H */
