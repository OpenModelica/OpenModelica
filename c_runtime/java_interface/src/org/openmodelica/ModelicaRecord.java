package org.openmodelica;

import java.io.IOException;
import java.io.Reader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.openmodelica.corba.parser.ParseException;

public class ModelicaRecord implements IModelicaRecord {

  private static final long serialVersionUID = 4879640187801031110L;
  private static HashMap<String,LinkedHashMap<String,FieldSpec>> allRecords;

  private class FieldSpec {
    public final Class<? extends ModelicaObject> fieldType;
    public final int index;
    public FieldSpec(Class<? extends ModelicaObject> fieldType,int index) {
      this.fieldType = fieldType;
      this.index = index;
    }
  }

  static {
    allRecords = new HashMap<String, LinkedHashMap<String,FieldSpec>>();
  }

  private String recordName;
  private LinkedHashMap<String,FieldSpec> spec;
  protected ModelicaObject[] fields;

  private String nameToPath(String s) {
    return s.replace("_", "__").replace('.', '_');
  }

  public ModelicaRecord(ModelicaObject o) throws ModelicaRecordException {
    ModelicaRecord rec = (ModelicaRecord)o;
    this.recordName = rec.getRecordName();
    spec = allRecords.get(recordName);
    if (spec == null) {
      throw new ModelicaRecordException("Tried to copy existing record but record definition does not exist");
    }
    fields = new ModelicaObject[spec.keySet().size()];
    for (String key : rec.keySet()) {
      put(key, rec.get(key));
    }
  }

  public ModelicaRecord(String recordName, String[] fieldNames, ModelicaObject... values) throws ModelicaRecordException {
    init(recordName,fieldNames,values);
  }

  private void init(String recordName, String[] fieldNames, ModelicaObject[] values) throws ModelicaRecordException {
    this.recordName = recordName;

    if (fieldNames.length != values.length) {
      throw new ModelicaRecordException("Failed to initialize Record - number of field names and values differ");
    }

    spec = allRecords.get(recordName);

    if (spec == null) {
      spec = new LinkedHashMap<String,FieldSpec>();
      for (int i=0; i<values.length; i++) {
        spec.put(fieldNames[i],new FieldSpec(values[i].getClass(),i));
      }
      allRecords.put(recordName, spec);
    } else if (values.length != spec.size()) {
      throw new ModelicaRecordException("Tried to initialize record with wrong number of values " + recordName + " expected " + spec.keySet() + " got " + Arrays.asList(fieldNames));
    }

    fields = values;
  }

  // Note: The order will be the same as for the given map; if it's a TreeMap,
  // it will be sorted. HashMap random, and so on. It's the same as the one used.
  public ModelicaRecord(String recordName, Map<String,ModelicaObject> map) throws ModelicaRecordException {
    // Do not use super(map) - GCJ will use our overloaded operation while OpenJDK works fine
    String[] names = new String[map.size()];
    ModelicaObject[] values = new ModelicaObject[map.size()];
    init(recordName,map.keySet().toArray(names),map.values().toArray(values));
  }

  // In case uniontypes are used
  public ModelicaRecord(String recordName,
      String[] fieldNames,
      Class<? extends ModelicaObject>[] fieldTypes,
      ModelicaObject... values) throws ModelicaRecordException {
    if (fieldNames.length != fieldTypes.length)
      throw new ModelicaRecordException("Length of field names and types differ");
    if (fieldNames.length != values.length)
      throw new ModelicaRecordException("Length of field names and source record differ");

    this.recordName = recordName;
    spec = allRecords.get(recordName);

    if (spec == null) {
      spec = new LinkedHashMap<String,FieldSpec>();
      for (int i=0; i<values.length; i++) {
        spec.put(fieldNames[i],new FieldSpec(fieldTypes[i],i));
      }
      allRecords.put(recordName, spec);
    }

    fields = new ModelicaObject[fieldNames.length];
    for (int i=0; i<fieldNames.length; i++) {
      put(fieldNames[i], values[i]);
    }
  }

  @SuppressWarnings("unchecked")
  protected static <T> T[] appendArrays(T[] a, T[] b) {
    List<T> res = new ArrayList<T>(a.length + b.length);
    res.addAll(Arrays.asList(a));
    res.addAll(Arrays.asList(b));
    return (T[]) res.toArray();
  }

  @Override
  public ModelicaObject put(String key, ModelicaObject value) {
    FieldSpec fspec = spec.get(key);
    if (fspec == null) {
      throw new RuntimeException("Record "+toString()+" does not contain the field " + key + "; its fields are " + spec);
    }
    try {
      value = ModelicaAny.cast(value, fspec.fieldType);
    } catch (Exception ex) {
      throw new RuntimeException("Record field type mismatch between " + fspec.fieldType + " and " + value.getClass());
    }
    ModelicaObject res = fields[fspec.index];
    fields[fspec.index] = value;
    return res;
  }

  @Override
  public ModelicaObject get(Object key) {
    FieldSpec fspec = spec.get(key);
    if (fspec == null) {
      throw new RuntimeException("Record "+toString()+" does not contain the key " + key);
    }
    return fields[fspec.index];
  }

  public <T extends ModelicaObject> T get(String key, Class<T> c) {
    try {
      return ModelicaAny.cast(get(key),c);
    } catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  public boolean equals(Object o) {
    try {
      ModelicaRecord o_ = (ModelicaRecord) o;
      if (!((o_).getRecordName().equals(this.getRecordName())))
        return false;
      for (int i=0; i<fields.length; i++)
        if (!fields[i].equals(o_.fields[i]))
          return false;
      return true;
    } catch (Throwable t) {
      return false;
    }
  }

  @Override
  public void setObject(ModelicaObject o) {
    ModelicaRecord rec = (ModelicaRecord) o;
    if (!rec.getRecordName().equals(this.getRecordName()))
      throw new RuntimeException(String.format("Couldn't update record %s using %s (Record Names differ)", this.toString(), o.toString()));
    if (!rec.keySet().equals(this.keySet()))
      throw new RuntimeException(String.format("Couldn't update record %s using %s (Key Sets differ)", this.toString(), o.toString()));
    for (String key : rec.keySet()) {
      put(key, rec.get(key));
    }
  }

  @Override
  public int get_ctor_index() {
    return -2; // Will give a warning when returned to OMC
  }

  protected void setRecordName(String recordName) {
    this.recordName = recordName;
    spec = allRecords.get(recordName);
    if (spec == null)
      throw new RuntimeException("Tried to set a record name that does not exist");
    fields = new ModelicaObject[spec.size()];
  }

  public String getRecordName() {
    return recordName;
  }

  protected String getRecordPath() {
    return nameToPath(recordName);
  }

  @Override
  public String toString() {
    StringBuffer buf = new StringBuffer();
    printToBuffer(buf);
    return buf.toString();
  }

  @Override
  public void printToBuffer(StringBuffer buffer) {
    Set<String> fieldNames = keySet();
    Iterator<String> iter = fieldNames.iterator();

    buffer.append(getRecordName());
    buffer.append("(");
    while (iter.hasNext()) {
      String field = iter.next();
      buffer.append(field);
      buffer.append("=");
      get(field).printToBuffer(buffer);
      if (iter.hasNext())
        buffer.append(",");
    }
    buffer.append(")");
  }

  @Override
  public void clear() {
    fields = new ModelicaObject[fields.length];
  }

  @Override
  public boolean containsKey(Object key) {
    return spec.containsKey(key);
  }

  @Override
  public boolean containsValue(Object value) {
    for (ModelicaObject o : fields)
      if (o.equals(value))
        return true;
    return false;
  }

  @Override
  public Set<java.util.Map.Entry<String, ModelicaObject>> entrySet() {
    return null;
  }

  @Override
  public boolean isEmpty() {
    return false;
  }

  @Override
  public Set<String> keySet() {
    return spec.keySet();
  }

  @Override
  public void putAll(Map<? extends String, ? extends ModelicaObject> m) {
    for (String s : m.keySet()) {
      put(s,m.get(s));
    }
  }

  @Override
  public ModelicaObject remove(Object key) {
    FieldSpec fspec = spec.get(key);
    ModelicaObject res = fields[fspec.index];
    fields[fspec.index] = null;
    return res;
  }

  @Override
  public int size() {
    return spec.size();
  }

  @Override
  public Collection<ModelicaObject> values() {
    return Arrays.asList(fields);
  }

  private static void skipEquals(Reader r) throws IOException, ParseException {
    ModelicaAny.skipWhiteSpace(r);
    int i;
    char ch;
    i = r.read();
    if (i == -1)
      throw new ParseException("EOF, expected '='");
    ch = (char) i;
    if (ch != '=')
      throw new ParseException("Expected '='");
    ModelicaAny.skipWhiteSpace(r);
  }

  private static boolean recordEnd(Reader r, String id) throws IOException, ParseException {
    ModelicaAny.skipWhiteSpace(r);
    r.mark(1);
    int i;
    char ch;
    i = r.read();
    if (i == -1) throw new ParseException("EOF, expected comma or end " + id);
    ch = (char) i;
    if (ch == ',') return false;
    r.reset();
    if (ModelicaAny.lexIdent(r).equals("end")) {
      String id2 = ModelicaAny.lexIdent(r);
      if (id2.equals(id))
        return true;
      throw new ParseException("Mismatched end identifier, got " + id2 + ", expected " + id);
    }
    throw new ParseException("Expected comma or end");
  }

  protected static ModelicaObject parse(Reader r) throws ParseException, IOException {
    return parse(r,ModelicaRecord.class,null);
  }

  protected static <T extends ModelicaRecord> T parse(Reader r, Class<T> cl, TypeSpec<?>[] fieldTypeSpecs) throws ParseException, IOException {
    String rec = ModelicaAny.lexIdent(r);
    if (!rec.equals("record"))
      throw new ParseException("Expected 'record' got " + rec);
    String recordName = ModelicaAny.lexIdent(r);
    Map<String, ModelicaObject> map = new LinkedHashMap<String, ModelicaObject>();
    int i = 0;
    do {
      String fieldName = ModelicaAny.lexIdent(r);
      if (fieldName.equals("end") && map.size() == 0) {
        String endId = ModelicaAny.lexIdent(r);
        if (!endId.equals(recordName))
          throw new ParseException("Mismatched end identifier, got " + endId + ", expected " + recordName);
        else break;
      }
      skipEquals(r);
      ModelicaObject fieldValue;
      if (fieldTypeSpecs == null)
        fieldValue = ModelicaAny.parse(r);
      else
        fieldValue = ModelicaAny.parse(r,fieldTypeSpecs[i++]);
      map.put(fieldName,fieldValue);
    } while (!recordEnd(r,recordName));
    i = r.read();
    if (i == -1) throw new ParseException("EOF, expected ;");
    if ((char) i != ';') throw new ParseException("Expected ;");
    try {
      return cl.getConstructor(String.class,Map.class).newInstance(recordName,map);
    } catch (Throwable t) {
      throw new ParseException(t);
    }
  }
}
