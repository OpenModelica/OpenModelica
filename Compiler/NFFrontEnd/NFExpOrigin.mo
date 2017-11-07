
encapsulated uniontype NFExpOrigin
  "This uniontype is used to mark where an expression comes from in typeExp, so
   that it can check things like 'end' only being used in subscripts."

protected
  import Dimension = NFDimension;
  import ExpOrigin = NFExpOrigin;

public
  record DIMENSION end DIMENSION;

  record SUBSCRIPT
    Dimension dimension;
  end SUBSCRIPT;

  record LHS "lhs of equation/assignment" end LHS;
  record RHS "rhs of equation/assignment" end RHS;
  record ITERATION_RANGE end ITERATION_RANGE;
  record BINDING end BINDING;
  record CONDITION end CONDITION;
  record NO_ORIGIN end NO_ORIGIN;

  function next
    "Some origins only apply to the whole expression. Tuples can for example only
     be used on the lhs of an equation/assignment, but only if it's alone on the
     lhs and not part of a larger expression. This function returns the next
     appropriate origin when moving into an expression."
    input ExpOrigin origin;
    output ExpOrigin nextOrigin;
  algorithm
    nextOrigin := match origin
      case LHS() then NO_ORIGIN();
      case RHS() then NO_ORIGIN();
      case ITERATION_RANGE() then NO_ORIGIN();
      else origin;
    end match;
  end next;

annotation(__OpenModelica_Interface="frontend");
end NFExpOrigin;

