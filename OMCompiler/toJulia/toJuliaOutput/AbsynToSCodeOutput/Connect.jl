  module Connect


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

    @UniontypeDecl Face
    @UniontypeDecl ConnectorType
    @UniontypeDecl ConnectorElement
    @UniontypeDecl SetTrieNode
    @UniontypeDecl OuterConnect
    @UniontypeDecl Sets
    @UniontypeDecl Set

         #= /*
         * This file is part of OpenModelica.
         *
         * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
         * c/o Linköpings universitet, Department of Computer and Information Science,
         * SE-58183 Linköping, Sweden.
         *
         * All rights reserved.
         *
         * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
         * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
         * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
         * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
         * ACCORDING TO RECIPIENTS CHOICE.
         *
         * The OpenModelica software and the Open Source Modelica
         * Consortium (OSMC) Public License (OSMC-PL) are obtained
         * from OSMC, either from the above address,
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        import DAE

        import Prefix

        import Absyn

         NEW_SET::ModelicaInteger = -1

          #= This type indicates whether a connector is an inside or an outside connector.
            Note: this is not the same as inner and outer references.
            A connector is inside if it connects from the outside into a component and it
            is outside if it connects out from the component.  This is important when
            generating equations for flow variables, where outside connectors are
            multiplied with -1 (since flow is always into a component). =#
         @Uniontype Face begin
              @Record INSIDE begin

              end

              @Record OUTSIDE begin

              end

              @Record NO_FACE begin

              end
         end

          #= The type of a connector element. =#
         @Uniontype ConnectorType begin
              @Record EQU begin

              end

              @Record FLOW begin

              end

              @Record STREAM begin

                       associatedFlow::Option
              end

              @Record NO_TYPE begin

              end
         end

         @Uniontype ConnectorElement begin
              @Record CONNECTOR_ELEMENT begin

                       name::DAE.ComponentRef
                       face::Face
                       ty::ConnectorType
                       source::DAE.ElementSource
                       set #= Which set this element belongs to. =#::ModelicaInteger
              end
         end

         @Uniontype SetTrieNode begin
              @Record SET_TRIE_NODE begin

                       name::String
                       cref::DAE.ComponentRef
                       nodes::IList
                       connectCount::ModelicaInteger
              end

              @Record SET_TRIE_LEAF begin

                       name::String
                       insideElement #= The inside element. =#::Option
                       outsideElement #= The outside element. =#::Option
                       flowAssociation #= The name of the associated flow
                             variable, if the leaf represents a stream variable. =#::Option
                       connectCount #= How many times this connector has been connected. =#::ModelicaInteger
              end
         end

        SetTrie = SetTrieNode  #= A trie, a.k.a. prefix tree, that maps crefs to sets. =#

        SetConnection = Tuple  #= A connection between two sets. =#

         @Uniontype OuterConnect begin
              @Record OUTERCONNECT begin

                       scope #= the scope where this connect was created =#::Prefix.Prefix
                       cr1 #= the lhs component reference =#::DAE.ComponentRef
                       io1 #= inner/outer attribute for cr1 component =#::Absyn.InnerOuter
                       f1 #= the face of the lhs component =#::Face
                       cr2 #= the rhs component reference =#::DAE.ComponentRef
                       io2 #= inner/outer attribute for cr2 component =#::Absyn.InnerOuter
                       f2 #= the face of the rhs component =#::Face
                       source #= the element origin =#::DAE.ElementSource
              end
         end

         @Uniontype Sets begin
              @Record SETS begin

                       sets::SetTrie
                       setCount #= How many sets the trie contains. =#::ModelicaInteger
                       connections::IList
                       outerConnects #= Connect statements to propagate upwards. =#::IList
              end
         end

          #= A set of connection elements. =#
         @Uniontype Set begin
              @Record SET begin

                       ty::ConnectorType
                       elements::IList
              end

              @Record SET_POINTER begin

                       index::ModelicaInteger
              end
         end

         emptySet = SETS(SET_TRIE_NODE("", DAE.WILD(), list(), 0), 0, list(), list())::Sets

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end
