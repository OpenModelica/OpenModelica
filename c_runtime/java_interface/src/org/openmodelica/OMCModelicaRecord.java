package org.openmodelica;

import java.util.Map;

/** This class is used by the OMC c_runtime/java_interface.o.
 * The class prevents warnings from being displayed if this class
 * is returned back to OMC (the field names, etc should be correct
 * since they came from OMC).
 */
class OMCModelicaRecord extends ModelicaRecord {
  private static final long serialVersionUID = 6568271462248961532L;
  private int ctor_index;

  public OMCModelicaRecord(int ctor_index, String recordName, Map<String, ModelicaObject> map) throws ModelicaRecordException {
    super(recordName, map);
    this.ctor_index = ctor_index;
  }

  @Override
  public int get_ctor_index() {
    return ctor_index;
  }
  
  @Override
  public void setObject(ModelicaObject o) {
    if (o instanceof ModelicaRecord) {
      ModelicaRecord rec = (ModelicaRecord) o;
      if (this.get_ctor_index() == -1) {
        super.setObject(o);
        return;
      } else if (rec.get_ctor_index() == -2) {
        throw new RuntimeException("The ModelicaRecord does not specify the ctor_index. It cannot be used to compare values in OMC.");
      }
      this.clear();
      this.setRecordName(rec.getRecordName());
      for (String key : rec.keySet()) {
        put(key, rec.get(key));
      }
      this.ctor_index = rec.get_ctor_index();
    }
  }
}
