$header()$

@SuppressWarnings("unchecked")
public class $function.name$ extends ModelicaFunction {
  public $function.name$ (SmartProxy proxy) {
    super("$myFQName(var = function.name)$", proxy);
  }
  
  $if(rest(function.output))$
  public $function.generics$ ModelicaTuple call ($function.input:{$it.TypeName$ input__$it.varName$}; separator = ", "$) throws ParseException,ConnectException
  {
    return super.call(ModelicaTuple.class$if(function.input)$, $endif$$function.input:{input__$it.varName$}; separator=","$);
  }

  public $function.generics$ void call ($function.input:{$it.TypeName$ input__$it.varName$}; separator = ", "$$if(function.input)$, $endif$$function.output:{$it.TypeName$ output__$it.varName$}; separator = ", "$) throws ParseException,ConnectException
  {
    ModelicaTuple __tuple = super.call(ModelicaTuple.class$if(function.input)$, $endif$$function.input:{input__$it.varName$}; separator=","$);
    java.util.Iterator<ModelicaObject> __i = __tuple.iterator();
    $function.output:{if (output__$it.varName$ != null) output__$it.varName$.setObject(__i.next()); else __i.next();}; separator = "\n"$
  }

$elseif(function.output)$
  public $function.generics$ $first(function.output).TypeName$ call ($function.input:{$it.TypeName$ input__$it.varName$}; separator = ", "$$if(first(function.output).GenericReference)$$if(function.input)$, $endif$Class<$first(function.output).TypeName$> __outClass$endif$) throws ParseException,ConnectException
  {
    return super.call($first(function.output).TypeClass$$if(function.input)$, $endif$$function.input:{input__$it.varName$}; separator=", "$);
  }

$else$
  public $function.generics$ ModelicaVoid call ($function.input:{$it.TypeName$ input__$it.varName$}; separator = ","$) throws ParseException,ConnectException
  {
    return super.call(ModelicaVoid.class$if(function.input)$, $endif$$function.input:{input__$it.varName$}; separator=", "$);
  }

$endif$
}
