/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated uniontype NFAttributes

  import InstContext = NFInstContext;
  import NFInstNode.InstNode;
  import NFPrefixes.*;
  import SCode;
  import Restriction = NFRestriction;

protected
  import Class = NFClass;
  import IOStream;
  import Prefixes = NFPrefixes;
  import SCodeUtil;

  import Attributes = NFAttributes;

public
  constant Attributes DEFAULT_ATTR =
    ATTRIBUTES(
      ConnectorType.NON_CONNECTOR,
      Parallelism.NON_PARALLEL,
      Variability.CONTINUOUS,
      Direction.NONE,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );

  constant Attributes INPUT_ATTR =
    ATTRIBUTES(
      ConnectorType.NON_CONNECTOR,
      Parallelism.NON_PARALLEL,
      Variability.CONTINUOUS,
      Direction.INPUT,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );

  constant Attributes OUTPUT_ATTR =
    ATTRIBUTES(
      ConnectorType.NON_CONNECTOR,
      Parallelism.NON_PARALLEL,
      Variability.CONTINUOUS,
      Direction.OUTPUT,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );

  constant Attributes CONSTANT_ATTR =
    ATTRIBUTES(
      ConnectorType.NON_CONNECTOR,
      Parallelism.NON_PARALLEL,
      Variability.CONSTANT,
      Direction.NONE,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );

  constant Attributes IMPL_DISCRETE_ATTR =
    ATTRIBUTES(
      ConnectorType.NON_CONNECTOR,
      Parallelism.NON_PARALLEL,
      Variability.IMPLICITLY_DISCRETE,
      Direction.NONE,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );

  constant Attributes AUGMENTED_ATTR =
    ATTRIBUTES(
      ConnectorType.AUGMENTED,
      Parallelism.NON_PARALLEL,
      Variability.CONTINUOUS,
      Direction.NONE,
      InnerOuter.NOT_INNER_OUTER,
      false,
      false,
      Replaceable.NOT_REPLACEABLE(),
      false
    );


  record ATTRIBUTES
    ConnectorType.Type connectorType;
    Parallelism parallelism;
    Variability variability;
    Direction direction;
    InnerOuter innerOuter;
    Boolean isFinal;
    Boolean isRedeclare;
    Replaceable isReplaceable;
    Boolean isResizable;
  end ATTRIBUTES;

  function fromSCode
    input SCode.Attributes compAttr;
    input SCode.Prefixes compPrefs;
    output Attributes attributes;
  protected
    ConnectorType.Type cty;
    Parallelism par;
    Variability var;
    Direction dir;
    InnerOuter io;
    Boolean fin, redecl;
    Replaceable repl;
  algorithm
    attributes := match (compAttr, compPrefs)
      case (SCode.Attributes.ATTR(
              connectorType = SCode.ConnectorType.POTENTIAL(),
              parallelism = SCode.Parallelism.NON_PARALLEL(),
              variability = SCode.Variability.VAR(),
              direction = Absyn.Direction.BIDIR()),
            SCode.Prefixes.PREFIXES(
              redeclarePrefix = SCode.Redeclare.NOT_REDECLARE(),
              finalPrefix = SCode.Final.NOT_FINAL(),
              innerOuter = Absyn.InnerOuter.NOT_INNER_OUTER(),
              replaceablePrefix = SCode.Replaceable.NOT_REPLACEABLE()))
        then DEFAULT_ATTR;

      else
        algorithm
          cty := ConnectorType.fromSCode(compAttr.connectorType);
          par := Prefixes.parallelismFromSCode(compAttr.parallelism);
          var := Prefixes.variabilityFromSCode(compAttr.variability);
          dir := Prefixes.directionFromSCode(compAttr.direction);
          io  := Prefixes.innerOuterFromSCode(compPrefs.innerOuter);
          fin := SCodeUtil.finalBool(compPrefs.finalPrefix);
          redecl := SCodeUtil.redeclareBool(compPrefs.redeclarePrefix);
          repl := Replaceable.NOT_REPLACEABLE();
        then
          Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl, false);
    end match;
  end fromSCode;

  function fromDerivedSCode
    input SCode.Attributes scodeAttr;
    output Attributes attributes;
  protected
    ConnectorType.Type cty;
    Variability var;
    Direction dir;
  algorithm
    attributes := match scodeAttr
      case SCode.Attributes.ATTR(
             connectorType = SCode.ConnectorType.POTENTIAL(),
             variability = SCode.Variability.VAR(),
             direction = Absyn.Direction.BIDIR())
        then DEFAULT_ATTR;

      else
        algorithm
          cty := ConnectorType.fromSCode(scodeAttr.connectorType);
          var := Prefixes.variabilityFromSCode(scodeAttr.variability);
          dir := Prefixes.directionFromSCode(scodeAttr.direction);
        then
          ATTRIBUTES(cty, Parallelism.NON_PARALLEL,
            var, dir, InnerOuter.NOT_INNER_OUTER, false, false, Replaceable.NOT_REPLACEABLE(), false);

    end match;
  end fromDerivedSCode;

  function mergeComponentAttributes
    input Attributes outerAttr;
    input Attributes innerAttr;
    input InstNode node;
    input Restriction parentRestriction;
    output Attributes attr;
  protected
    ConnectorType.Type cty;
    Parallelism par;
    Variability var;
    Direction dir;
    Boolean fin, redecl, resize;
    Replaceable repl;
  algorithm
    if referenceEq(outerAttr, DEFAULT_ATTR) and innerAttr.connectorType == 0 then
      attr := innerAttr;
    elseif referenceEq(innerAttr, DEFAULT_ATTR) then
      cty := ConnectorType.merge(outerAttr.connectorType, innerAttr.connectorType, node);
      attr := Attributes.ATTRIBUTES(cty, outerAttr.parallelism,
        outerAttr.variability, outerAttr.direction, innerAttr.innerOuter, outerAttr.isFinal,
        innerAttr.isRedeclare, innerAttr.isReplaceable, innerAttr.isResizable);
    else
      cty := ConnectorType.merge(outerAttr.connectorType, innerAttr.connectorType, node);
      par := Prefixes.mergeParallelism(outerAttr.parallelism, innerAttr.parallelism, node);
      var := Prefixes.variabilityMin(outerAttr.variability, innerAttr.variability);

      if Restriction.isFunction(parentRestriction) then
        dir := innerAttr.direction;
      else
        dir := Prefixes.mergeDirection(outerAttr.direction, innerAttr.direction, node);
      end if;

      fin := outerAttr.isFinal or innerAttr.isFinal;
      redecl := innerAttr.isRedeclare;
      repl := innerAttr.isReplaceable;
      resize := innerAttr.isResizable;
      attr := Attributes.ATTRIBUTES(cty, par, var, dir, innerAttr.innerOuter, fin, redecl, repl, resize);
    end if;
  end mergeComponentAttributes;

  function mergeDerivedAttributes
    input Attributes outerAttr;
    input Attributes innerAttr;
    input InstNode node;
    output Attributes attr;
  protected
    ConnectorType.Type cty;
    Parallelism par;
    Variability var;
    Direction dir;
    InnerOuter io;
    Boolean fin, redecl, resize;
    Replaceable repl;
  algorithm
    if referenceEq(innerAttr, DEFAULT_ATTR) and outerAttr.connectorType == 0 then
      attr := outerAttr;
    elseif referenceEq(outerAttr, DEFAULT_ATTR) and innerAttr.connectorType == 0 then
      attr := innerAttr;
    else
      Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl, resize) := outerAttr;
      cty := ConnectorType.merge(cty, innerAttr.connectorType, node, isClass = true);
      var := Prefixes.variabilityMin(var, innerAttr.variability);
      dir := Prefixes.mergeDirection(dir, innerAttr.direction, node, allowSame = true);
      attr := Attributes.ATTRIBUTES(cty, par, var, dir, innerAttr.innerOuter, fin, redecl, repl, resize);
    end if;
  end mergeDerivedAttributes;

  function mergeRedeclaredComponentAttributes
    input Attributes origAttr;
    input Attributes redeclAttr;
    input InstNode node;
    output Attributes attr;
  protected
    ConnectorType.Type cty, rcty, cty_fs, rcty_fs;
    Parallelism par, rpar;
    Variability var, rvar;
    Direction dir, rdir;
    InnerOuter io, rio;
    Boolean fin, redecl, resize;
    Replaceable repl;
  algorithm
    if referenceEq(origAttr, DEFAULT_ATTR) then
      attr := redeclAttr;
    elseif referenceEq(redeclAttr, DEFAULT_ATTR) then
      attr := origAttr;
    else
      Attributes.ATTRIBUTES(cty, par, var, dir, io, _, _, _, _) := origAttr;
      Attributes.ATTRIBUTES(rcty, rpar, rvar, rdir, rio, fin, redecl, repl, resize) := redeclAttr;

      // If no prefix is given for one of these attributes in the redeclaration,
      // then the one from the original declaration is used. The redeclare is not
      // allowed to change an existing prefix on the original declaration, except
      // for the variability which can be lowered (e.g. parameter -> constant) and
      // final which is always taken from the redeclare (since redeclaring a final
      // element isn't allowed).

      rcty_fs := intBitAnd(rcty, ConnectorType.FLOW_STREAM_MASK);
      cty_fs := intBitAnd(cty, ConnectorType.FLOW_STREAM_MASK);
      if rcty_fs > 0 then
        if cty_fs > 0 and rcty_fs <> cty_fs then
          printRedeclarePrefixError(node, ConnectorType.toString(rcty), ConnectorType.toString(cty));
        end if;
      end if;

      cty := intBitOr(rcty, cty_fs);

      if rpar <> Parallelism.NON_PARALLEL then
        if par <> Parallelism.NON_PARALLEL and par <> rpar then
          printRedeclarePrefixError(node, Prefixes.parallelismString(rpar), Prefixes.parallelismString(par));
        end if;

        par := rpar;
      end if;

      if rvar <> Variability.CONTINUOUS then
        if rvar > var then
          printRedeclarePrefixError(node, Prefixes.variabilityString(rvar), Prefixes.variabilityString(var));
        end if;

        var := rvar;
      end if;

      if rdir <> Direction.NONE then
      if dir <> Direction.NONE and rdir <> dir then
          printRedeclarePrefixError(node, Prefixes.directionString(rdir), Prefixes.directionString(dir));
        end if;

        dir := rdir;
      end if;

      if rio <> InnerOuter.NOT_INNER_OUTER then
        if io <> InnerOuter.NOT_INNER_OUTER and rio <> io then
          printRedeclarePrefixError(node, Prefixes.innerOuterString(rio), Prefixes.innerOuterString(io));
        end if;

        io := rio;
      end if;

      attr := Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl, resize);
    end if;
  end mergeRedeclaredComponentAttributes;

  function mergeRedeclaredClassPrefixes
    input Class.Prefixes origPrefs;
    input Class.Prefixes redeclPrefs;
    input InstNode node;
    output Class.Prefixes prefs;
  protected
    SCode.Encapsulated enc;
    SCode.Partial par;
    SCode.Final fin;
    Absyn.InnerOuter io, rio;
    SCode.Replaceable repl;
  algorithm
    if referenceEq(origPrefs, NFClass.DEFAULT_PREFIXES) then
      prefs := redeclPrefs;
    else
      Class.Prefixes.PREFIXES(innerOuter = io) := origPrefs;
      Class.Prefixes.PREFIXES(enc, par, fin, rio, repl) := redeclPrefs;

      io := match (io, rio)
        case (Absyn.InnerOuter.NOT_INNER_OUTER(), _) then rio;
        case (_, Absyn.InnerOuter.NOT_INNER_OUTER()) then io;
        case (Absyn.InnerOuter.INNER(), Absyn.InnerOuter.INNER()) then io;
        case (Absyn.InnerOuter.OUTER(), Absyn.InnerOuter.OUTER()) then io;
        case (Absyn.InnerOuter.INNER_OUTER(), Absyn.InnerOuter.INNER_OUTER()) then io;
        else
          algorithm
            printRedeclarePrefixError(node,
              Prefixes.innerOuterString(Prefixes.innerOuterFromSCode(rio)),
              Prefixes.innerOuterString(Prefixes.innerOuterFromSCode(io)));
          then
            fail();
      end match;

      prefs := Class.Prefixes.PREFIXES(enc, par, fin, io, repl);
    end if;
  end mergeRedeclaredClassPrefixes;

  function printRedeclarePrefixError
    input InstNode node;
    input String prefix1;
    input String prefix2;
  algorithm
    Error.addSourceMessageAndFail(Error.REDECLARE_MISMATCHED_PREFIX,
      {prefix1, InstNode.name(node), prefix2}, InstNode.info(node));
  end printRedeclarePrefixError;

  function checkDeclaredComponentAttributes
    input output Attributes attr;
    input Restriction parentRestriction;
    input InstNode component;
  algorithm
    () := match parentRestriction
      case Restriction.CONNECTOR()
        algorithm
          // Components of a connector may not have prefixes 'inner' or 'outer'.
          assertNotInnerOuter(attr.innerOuter, component, parentRestriction);

          if parentRestriction.isExpandable then
            // Components of an expandable connector may not have the prefix 'flow'.
            assertNotFlowStream(attr.connectorType, component, parentRestriction);

            // Mark components in expandable connectors as potentially present.
            attr.connectorType := intBitOr(attr.connectorType, ConnectorType.POTENTIALLY_PRESENT);
          end if;
        then
          ();

      case Restriction.RECORD()
        algorithm
          // Elements of a record may not have prefixes 'input', 'output', 'inner', 'outer', 'stream', or 'flow'.
          assertNotInputOutput(attr.direction, component, parentRestriction);
          assertNotInnerOuter(attr.innerOuter, component, parentRestriction);
          assertNotFlowStream(attr.connectorType, component, parentRestriction);
        then
          ();

      else ();
    end match;
  end checkDeclaredComponentAttributes;

  function invalidComponentPrefixError
    input String prefix;
    input InstNode node;
    input Restriction restriction;
  algorithm
    Error.addSourceMessage(Error.INVALID_COMPONENT_PREFIX,
      {prefix, InstNode.name(node), Restriction.toString(restriction)}, InstNode.info(node));
  end invalidComponentPrefixError;

  function assertNotInputOutput
    input Direction dir;
    input InstNode node;
    input Restriction restriction;
  algorithm
    if dir <> Direction.NONE then
      invalidComponentPrefixError(Prefixes.directionString(dir), node, restriction);
      fail();
    end if;
  end assertNotInputOutput;

  function assertNotInnerOuter
    input InnerOuter io;
    input InstNode node;
    input Restriction restriction;
  algorithm
    if io <> InnerOuter.NOT_INNER_OUTER then
      invalidComponentPrefixError(Prefixes.innerOuterString(io), node, restriction);
      fail();
    end if;
  end assertNotInnerOuter;

  function assertNotFlowStream
    input ConnectorType.Type cty;
    input InstNode node;
    input Restriction restriction;
  algorithm
    if ConnectorType.isFlowOrStream(cty) then
      invalidComponentPrefixError(ConnectorType.toString(cty), node, restriction);
      fail();
    end if;
  end assertNotFlowStream;

  function updateComponentConnectorType
    input output Attributes attributes;
    input Restriction restriction;
    input InstContext.Type context;
    input InstNode component;
  protected
    ConnectorType.Type cty = attributes.connectorType;
  algorithm
    if ConnectorType.isConnectorType(cty) then
      if Restriction.isConnector(restriction) then
        if Restriction.isExpandableConnector(restriction) then
          cty := ConnectorType.setPresent(cty);
        else
          cty := intBitAnd(cty, intBitNot(ConnectorType.EXPANDABLE));
        end if;
      else
        // The connector type might have the connector or expandable bits set
        // because of a parent node, but they should be unset if the component
        // itself isn't a connector.
        cty := intBitAnd(cty,
          intBitNot(intBitOr(ConnectorType.CONNECTOR, ConnectorType.EXPANDABLE)));
      end if;

      // Connector elements that are not flow/stream are potentials.
      if not ConnectorType.isFlowOrStream(cty) then
        cty := ConnectorType.setPotential(cty);
      end if;

      if cty <> attributes.connectorType then
        attributes.connectorType := cty;
      end if;
    elseif ConnectorType.isFlowOrStream(cty) and not InstContext.inRedeclared(context) then
      // The Modelica specification forbids using stream outside connector
      // declarations, but has no such restriction for flow. To compromise we
      // print a warning for both flow and stream.
      Error.addStrictMessage(Error.CONNECTOR_PREFIX_OUTSIDE_CONNECTOR,
        {ConnectorType.toString(cty)}, InstNode.info(component));

      // Remove the erroneous flow/stream prefix and keep going.
      attributes.connectorType := ConnectorType.unsetFlowStream(cty);
    end if;
  end updateComponentConnectorType;

  function updateClassConnectorType
    input Restriction res;
    input output Attributes attrs;
  algorithm
    if Restriction.isExpandableConnector(res) then
      attrs.connectorType := ConnectorType.setExpandable(attrs.connectorType);
    elseif Restriction.isConnector(res) then
      attrs.connectorType := ConnectorType.setConnector(attrs.connectorType);
    end if;
  end updateClassConnectorType;

  function updateVariability
    "Updates the variability based on the type of the attributes' owner (e.g.
     Integer is implicitly discrete)."
    input output Attributes attr;
    input Class cls;
    input InstNode clsNode;
    input InstNode compNode;
    input InstContext.Type context;
  protected
    Variability var = attr.variability;
  algorithm
    if referenceEq(attr, DEFAULT_ATTR) and InstNode.isDiscreteClass(clsNode) then
      attr := NFAttributes.IMPL_DISCRETE_ATTR;
    elseif var == Variability.CONTINUOUS and InstNode.isDiscreteClass(clsNode) then
      attr.variability := Variability.IMPLICITLY_DISCRETE;
    elseif var < Variability.CONTINUOUS and InstContext.inFunction(context) and
           attr.direction <> Direction.NONE and
           SCodeUtil.isEmptyMod(InstNode.getAnnotation("__OpenModelica_functionVariability", compNode)) then
      // Variability prefixes on function parameters has no semantic meaning,
      // remove them so we don't have to worry about accidentally evaluating
      // e.g. an input declared as constant/parameter.
      attr.variability := Variability.CONTINUOUS;
    elseif var == Variability.PARAMETER and not Flags.isSet(Flags.NF_SCALARIZE)
      and Util.getOptionOrDefault(SCodeUtil.lookupBooleanAnnotationMod(InstNode.getAnnotation("__OpenModelica_resizable", compNode)), false) then
      attr.variability := Variability.NON_STRUCTURAL_PARAMETER;
      attr.isResizable := true;
    end if;
  end updateVariability;

  function setConnectorType
    input ConnectorType.Type cty;
    input output Attributes attr;
  algorithm
    attr.connectorType := cty;
  end setConnectorType;

  function setVariability
    input Variability var;
    input output Attributes attr;
  algorithm
    attr.variability := var;
  end setVariability;

  function setDirection
    input Direction dir;
    input output Attributes attr;
  algorithm
    attr.direction := dir;
  end setDirection;

  function setInnerOuter
    input InnerOuter io;
    input output Attributes attr;
  algorithm
    attr.innerOuter := io;
  end setInnerOuter;

  function setFinal
    input Boolean fin;
    input output Attributes attr;
  algorithm
    attr.isFinal := fin;
  end setFinal;

  function setRedeclare
    input Boolean redecl;
    input output Attributes attr;
  algorithm
    attr.isRedeclare := redecl;
  end setRedeclare;

  function setReplaceable
    input Replaceable repl;
    input output Attributes attr;
  algorithm
    attr.isReplaceable := repl;
  end setReplaceable;

  function toDAE
    input Attributes ina;
    input Visibility vis;
    output DAE.Attributes outa;
  algorithm
    outa := DAE.ATTR(
      ConnectorType.toDAE(ina.connectorType),
      parallelismToSCode(ina.parallelism),
      variabilityToSCode(ina.variability),
      directionToAbsyn(ina.direction),
      innerOuterToAbsyn(ina.innerOuter),
      visibilityToSCode(vis)
    );
  end toDAE;

  function toString
    input Attributes attr;
    input Type ty;
    output String str;
  algorithm
    str := (if attr.isRedeclare then "redeclare " else "") +
           (if attr.isFinal then "final " else "") +
           Prefixes.unparseInnerOuter(attr.innerOuter) +
           Prefixes.unparseReplaceable(attr.isReplaceable) +
           Prefixes.unparseParallelism(attr.parallelism) +
           ConnectorType.unparse(attr.connectorType) +
           Prefixes.unparseVariability(attr.variability, ty) +
           Prefixes.unparseDirection(attr.direction);
  end toString;

  function toFlatStream
    input Attributes attr;
    input Type ty;
    input output IOStream.IOStream s;
    input Boolean isTopLevel = true;
  algorithm
    if attr.isFinal then
      s := IOStream.append(s, "final ");
    end if;

    s := IOStream.append(s, Prefixes.unparseVariability(attr.variability, ty));

    if isTopLevel then
      s := IOStream.append(s, Prefixes.unparseDirection(attr.direction));
    end if;
  end toFlatStream;

annotation(__OpenModelica_Interface="frontend");
end NFAttributes;

