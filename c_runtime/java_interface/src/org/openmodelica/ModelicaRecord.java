package org.openmodelica;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ModelicaRecord extends LinkedHashMap<String, ModelicaObject> implements IModelicaRecord {

  private static final long serialVersionUID = 4879640187801031110L;

  private String recordName;
  private String recordPath;
  
  private String nameToPath(String s) {
    return s.replace("_", "__").replace('.', '_');
  }
  
  public ModelicaRecord(ModelicaObject o) {
    ModelicaRecord rec = (ModelicaRecord)o;
    this.setRecordName(rec.getRecordName());
    this.setRecordPath(nameToPath(this.getRecordName()));
    this.clear();
    for (String key : rec.keySet()) {
      super.put(key, rec.get(key));
    }
  }
  public ModelicaRecord(String recordName, String[] fieldNames) {
    this.setRecordName(recordName);
    this.setRecordPath(nameToPath(this.getRecordName()));
    
    for (String s : fieldNames) {
      super.put(s,null);
    }
  }

  public ModelicaRecord(String recordName, String[] fieldNames, ModelicaObject... values) throws ModelicaRecordException {
    this.setRecordName(recordName);
    this.setRecordPath(nameToPath(this.getRecordName()));
    
    if (fieldNames.length != values.length) {
      throw new ModelicaRecordException("Failed to initialize Record - number of field names and values differ");
    }
    
    for (int i=0; i<values.length; i++) {
      super.put(fieldNames[i], values[i]);
    }
  }
  
  // Note: The order will be the same as for the given map; if it's a TreeMap,
  // it will be sorted. HashMap random, and so on. It's the same as the one used.
  public ModelicaRecord(String recordName, Map<String,ModelicaObject> map) {
    // Do not use super(map) - GCJ will use our overloaded operation while OpenJDK works fine
    for (String key : map.keySet())
      super.put(key, map.get(key));
    this.setRecordName(recordName);
    this.setRecordPath(nameToPath(this.getRecordName()));
  }
  
  // Verify that the ModelicaRecord has the same signature as the one we want...
  @SuppressWarnings("unchecked")
  protected ModelicaRecord(String recordName,
                           String[] fieldNames,
                           Class[] fieldTypes,
                           ModelicaRecord rec) {
    if (!recordName.equals(rec.getRecordName()))
      throw new RuntimeException("Record names differ: " + recordName + "," + rec.getRecordName());
    Object[] recFieldNames = rec.keySet().toArray();
    if (fieldNames.length != fieldTypes.length)
      throw new RuntimeException("Length of field names and types differ");
    if (fieldNames.length != rec.size())
      throw new RuntimeException("Length of field names and source record differ");
    
    for (int i=0; i<fieldNames.length; i++) {
      if (!recFieldNames[i].equals(fieldNames[i]))
        throw new RuntimeException("Fields differ: "+fieldNames[i]+" != "+recFieldNames[i]);
      
      try {
        super.put(fieldNames[i], ModelicaAny.cast(rec.get(fieldNames[i]), fieldTypes[i]));
      } catch (Throwable t) {
        throw new RuntimeException(t);
      }
    }
    this.setRecordName(recordName);
    this.setRecordPath(nameToPath(this.getRecordName()));
  }
  
  @SuppressWarnings("unchecked")
  protected static <T> T[] appendArrays(T[] a, T[] b) {
    List<T> res = new ArrayList<T>(a.length + b.length);
    res.addAll(Arrays.asList(a));
    res.addAll(Arrays.asList(b));
    return (T[]) res.toArray();
  }
  
  @Override
  public String toString() {
    Object[] fieldNames = this.keySet().toArray();
    String res = getRecordName()+"(";
    for (int i=0; i<fieldNames.length; i++) {
      if (i != 0)
        res += ",";
      res += fieldNames[i] +"="+ get(fieldNames[i]).toString();
    }
    res += ")";
    return res;
  }

  @Override
  public ModelicaObject put(String key, ModelicaObject value) {
    if (!this.keySet().contains(key)) {
      throw new RuntimeException("Record "+toString()+"does not contain the key " + key);
    }
    return super.put(key, value);
  }

  @Override
  public ModelicaObject get(Object key) {
    return super.get(key);
  }

  public <T extends ModelicaObject> T get(String key, Class<T> c) {
    return c.cast(get(key));
  }
  
  @Override
  public boolean equals(Object o) {
    try {
      if (!((ModelicaRecord) o).getRecordName().equals(this.getRecordName()))
        return false;
    } catch (Throwable t) {
      return false;
    }
    return super.equals(o);
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
  
  protected ModelicaObject put_prot(String key, ModelicaObject value) {
    return super.put(key, value);
  }

  @Override
  public int get_ctor_index() {
    return -2; // Will give a warning when returned to OMC
  }

  protected void setRecordName(String recordName) {
    this.recordName = recordName;
  }

  public String getRecordName() {
    return recordName;
  }

  protected void setRecordPath(String recordPath) {
    this.recordPath = recordPath;
  }

  protected String getRecordPath() {
    return recordPath;
  }
}
