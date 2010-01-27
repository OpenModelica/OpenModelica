$header()$
import java.io.IOException;
import java.io.Reader;
import java.util.Map;

/* Record $record.name$ */
@SuppressWarnings({ "unchecked", "serial" })
public class $record.name$ $record.generics$ extends ModelicaRecord $record.uniontype:{implements $it$_UT}$ {

  private static final java.lang.Class[] fieldTypes = new java.lang.Class[] {$record.fields:{$it.TypeClass$};separator=","$};
  private static org.openmodelica.TypeSpec[] fieldTypeSpecs;
  private static final java.lang.String[] fieldNames = new java.lang.String[]{$record.fields:{"$it.varName$"};separator=","$};
  private static final java.lang.String recordName = "$myFQName(var = record.name)$";  
  
  static {
    fieldTypeSpecs = new org.openmodelica.TypeSpec[] {
      $record.fields:{$it.TypeSpec$};separator=",\n"$
    };
  };

  public $record.generics$ $record.name$($record.fields:{$it.TypeName$ __$it.varName$}; separator = ","$) throws ModelicaRecordException {
    super(recordName, fieldNames, fieldTypes$if(record.fields)$, $endif$ $record.fields:{__$it.varName$}; separator = ","$);
  }
  
  public $record.name$(ModelicaObject o) throws ModelicaRecordException {
    super(o);
    if (!getRecordName().equals(recordName))
      throw new ModelicaRecordException("Record name mismatch");
  }
  
  public $record.name$(String recordName, Map map) throws ModelicaRecordException {
    super($record.name$.recordName,fieldNames,fieldTypes,map);
    if (!getRecordName().equals($record.name$.recordName))
      throw new ModelicaRecordException("Record name mismatch");
  }
  
  $record.fields:{public $record.generics$ $it.TypeName$ get_$it.varName$() {return get("$it.varName$", $it.TypeClass$);}
public $record.generics$ void set_$it.varName$($it.TypeName$ new__$it.varName$) {put("$it.varName$", new__$it.varName$);}
  
}$

  public static $record.name$ parse(Reader r) throws ParseException, IOException {
    return ModelicaRecord.parse(r,$record.name$.class,fieldTypeSpecs);
  }

  @Override
  public int get_ctor_index() {
    return $record.ctor_index$;
  }
}

