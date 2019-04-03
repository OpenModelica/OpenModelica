package Types "Types in MetaModelica"

/*
 *
 * Types and constants in MetaModelica
 *
 */

// an alias for the Real type
type Alias = Real;
constant Alias aliasConstant = 1.0;

// an option type which can be SOME(Alias) or NONE()
type OptionType = Option<Alias>;
constant OptionType optionAliasConstant = SOME(aliasConstant);
constant OptionType optionAliasConstantNone = NONE();

// a tuple type with 3 elements
type TupleType = tuple<String, Alias, OptionType>;
constant TupleType tupleConstant = ("a tuple element", aliasConstant, optionAliasConstant);

// a list type
type ListType = list<TupleType>;
constant ListType listConstant = {tupleConstant, ("another element", 2.0, NONE())};

// complex record types
record OneRecord
  String k;
  Alias z;
end OneRecord;
constant OneRecord oneRecord = OneRecord("first element", 3.0);

// complex uniontypes
uniontype Select

  record FirstAlternative
    String x1;
    String x2;
  end FirstAlternative;

  record SecondAlternative
    Select x1;
    Select x2;
  end SecondAlternative;

  record ThirdAlternative
    Select next;
  end ThirdAlternative;
end Select;

constant Select select =
  ThirdAlternative(
    SecondAlternative(
      FirstAlternative("one", "First"),
      FirstAlternative("two", "Second")));

end Types;

