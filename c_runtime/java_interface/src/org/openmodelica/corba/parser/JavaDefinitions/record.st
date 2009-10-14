$header()$

/* Record $record.name$ */
@SuppressWarnings({ "unchecked", "serial" })
public class $record.name$ $record.generics$ extends ModelicaRecord $record.uniontype:{implements $it$}$ {

  public $record.generics$ $record.name$($record.fields:{$it.TypeName$ __$it.varName$}; separator = ","$) {
    super(new ModelicaRecord("$myFQName(var = record.name)$", new String[]{$record.fields:{"$it.varName$"};separator=","$}));
    $record.fields:{put("$it.varName$", __$it.varName$);}; separator = "\n"$
  }
  
  public $record.name$(ModelicaObject o) {
    super("$myFQName(var = record.name)$",
          new String[]{$record.fields:{"$it.varName$"};separator=","$},
          new java.lang.Class[] {$record.fields:{$it.TypeClass$};separator=","$}, (ModelicaRecord) o);
  }
  
  $record.fields:{public $record.generics$ $it.TypeName$ get_$it.varName$() {return get("$it.varName$", $it.TypeClass$);}
public $record.generics$ void set_$it.varName$($it.TypeName$ new__$it.varName$) {put("$it.varName$", new__$it.varName$);}
  
}$

  @Override
  public int get_ctor_index() {
    return $record.ctor_index$;
  }
}

