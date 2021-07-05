PackageExport["Quiver"]

SetUsage @ "
Quiver[graph$] constructs a cardinal quiver from a graph.
Quiver[edges$] constructs a cardinal quiver from a list of edges.
Quiver[vertices$, edges$] constructs a cardinal quiver from a list of vertices and edges.
* The edges of graph$ should be tagged with cardinals.
* The edges incident to one vertex should not be tagged with a cardinal more than once.
* The resulting graph will display with a legend showing the cardinals associated with each edge.
"

DeclareArgumentCount[Quiver, {1, 2}];

Options[Quiver] = $simpleGraphOptionRules;

declareSyntaxInfo[Quiver, {_, _., OptionsPattern[]}];

Quiver[edges_, opts:OptionsPattern[]] :=
  Quiver[Automatic, edges, opts];

Quiver[graph_Graph, opts:OptionsPattern[]] :=
  ExtendedGraph[graph, opts, GraphLegend -> Automatic]

Quiver[vertices_, edges_, opts:OptionsPattern[]] :=
  makeQuiver[vertices, edges, {opts}];

Quiver::invedge = "The edge specification `` is not valid."

processEdge[edge_, _] :=
  (Message[Quiver::invedge, edge]; $Failed);

Quiver::nakededge = "The edge `` is not labeled with a cardinal.";

processEdge[edge:(_Rule | _TwoWayRule | DirectedEdge[_, _] | UndirectedEdge[_, _]), None] :=
  (Message[Quiver::nakededge, edge]; $Failed);

processEdge[Labeled[edges:{__Rule}, labels_List], _] /; Length[edges] === Length[labels] :=
  MapThread[DirectedEdge[#1, #2, #3]&, {Keys @ edges, Values @ edges, SimplifyCardinalSet /@ labels}];

processEdge[Labeled[edges_, label_], _] :=
  processEdge[edges, label];

processEdge[e_, Verbatim[Alternatives][args__]] :=
  Map[processEdge[e, #]&, {args}];

processEdge[l_ <-> r_, label_] := {
  DirectedEdge[l, r, label],
  DirectedEdge[r, l, label]
};

processEdge[l_ -> r_, label_] :=
  DirectedEdge[l, r, label];

processEdge[DirectedEdge[l_, r_, Verbatim[Alternatives][args__]], z_] :=
  processEdge[DirectedEdge[l, r, #], z]& /@ {args};

processEdge[DirectedEdge[l_, r_], c_] :=
  DirectedEdge[l, r, c];

processEdge[UndirectedEdge[a_, b_], c_] :=
  {DirectedEdge[a, b, c], DirectedEdge[b, a, c]};

processEdge[UndirectedEdge[a_, b_, c_], _] :=
  {DirectedEdge[a, b, c], DirectedEdge[b, a, c]};

processEdge[de:DirectedEdge[_, _, _], _] := de;

processEdge[assoc_Association, _] := KeyValueMap[processEdge[#2, #1]&, assoc];
processEdge[Labeled[e_, label_], _] := processEdge[e, label];

processEdge[list_List, label_] := Map[processEdge[#, label]&, list];


$maxVertexCount = 150;
makeQuiver[vertices_, edges_, newOpts_] := Scope[

  If[!MatchQ[edges, {DirectedEdge[_, _, Except[_Alternatives]]..}],
    edges = Flatten @ List @ processEdge[edges, None];
    If[ContainsQ[edges, $Failed], ReturnFailed[]];
  ];

  If[!validCardinalEdgesQ[edges],
    reportDuplicateCardinals[edges];
    ReturnFailed[];
  ];

  If[vertices === Automatic, vertices = Union[InVertices @ edges, OutVertices @ edges]];

  ExtendedGraph[
    vertices, edges,
    Sequence @@ newOpts,
    GraphLegend -> Automatic
  ]
]

reportDuplicateCardinals[edges_] := (
  KeyValueScan[checkEdgeGroup, GroupBy[edges, Last]];
)

Quiver::dupcardinal = "The cardinal `` is present on the following incident edges: ``."
checkEdgeGroup[tag_, edges_] /; !checkForDuplicateCardinals[edges] := Scope[
  {srcDup, dstDup} = Apply[Alternatives, FindDuplicates[#]]& /@ {InVertices[edges], OutVertices[edges]};
  dupEdges = Cases[edges, DirectedEdge[srcDup, _, _]];
  If[dupEdges === {}, dupEdges = Cases[edges, DirectedEdge[_, dstDup, _]]];
  Message[Quiver::dupcardinal, tag, Take[dupEdges, All, 2]];
];

(**************************************************************************************************)

PackageExport["ToQuiver"]

SetUsage @ "
ToQuiver[obj$] attempts to convert obj$ to a quiver Graph[$$] object.
* If obj$ is already a quiver graph, it is returned unchanged.
* If obj$ is a list of rules, it is converted to a quiver graph.
* Otherwise, $Failed is returned.
"

ToQuiver = MatchValues[
  graph_Graph := If[QuiverQ @ graph, graph, Quiet @ Quiver @ graph];
  edges_List := Quiet @ Quiver @ edges;
  str_String := BouquetQuiver @ str;
  _ := $Failed;
];

(**************************************************************************************************)

PackageExport["BouquetQuiver"]

SetUsage @ "
BouquetQuiver[cardinals$] creates a Bouquet cardinal quiver graph with the given cardinal edges.
BouquetQuiver['string$'] uses the characters of 'string$' as cardinals.
"

DeclareArgumentCount[BouquetQuiver, 1];

Options[BouquetQuiver] = $simpleGraphOptionRules;

declareSyntaxInfo[BouquetQuiver, {_, OptionsPattern[]}];

BouquetQuiver[str_String, opts:OptionsPattern[]] := BouquetQuiver[Characters[str], opts];

BouquetQuiver[cardinals_List, opts:OptionsPattern[]] :=
  Quiver[Map[c |-> Labeled[1 -> 1, c], cardinals], Cardinals -> cardinals, opts]

(**************************************************************************************************)

PackageExport["QuiverQ"]

SetUsage @ "
QuiverQ[graph$] returns True if graph$ represents a cardinal quiver.
* A cardinal quiver must have a cardinal associated with every edge.
* A cardinal quiver should contain only directed edges.
* A cardinal should not be present on more than one edge incident to a vertex.
"

QuiverQ[g_] := EdgeTaggedGraphQ[g] && validCardinalEdgesQ[EdgeList[g]];

validCardinalEdgesQ[edges_] := And[
  MatchQ[edges, {DirectedEdge[_, _, _]..}],
  AllTrue[GroupBy[edges // SpliceCardinalSetEdges, Last], checkForDuplicateCardinals]
];

checkForDuplicateCardinals[edges_] :=
  DuplicateFreeQ[InVertices @ edges] && DuplicateFreeQ[OutVertices @ edges];

(**************************************************************************************************)

PackageExport["FreeQuiver"]

SetUsage @ "
FreeQuiver[graph$] returns a cardinal quiver for graph$, assigning a unique formal symbol \
to each edge in the graph$.
* Undirected edges are transformed into pairs of opposite directed edges.
"

$formalSymbols = Map[letter |-> Symbol["\\" <> "[Formal" <> letter <> "]"], CharacterRange["A", "Z"]];

toFreeQuiverEdge[head_[a_, b_]] :=
  head[a, b, $formalSymbols[[$count++]]];

DeclareArgumentCount[FreeQuiver, 1];

declareSyntaxInfo[FreeQuiver, {_}];

Options[FreeQuiver] = $simpleGraphOptionRules;

FreeQuiver[graph_, opts:OptionsPattern[]] := Scope[
  $count = 1;
  makeQuiver[VertexList @ graph, Map[toFreeQuiverEdge, EdgeList @ graph], {opts}]
];

(**************************************************************************************************)

PackageExport["CardinalList"]

SetUsage @ "
CardinalList[quiver$] returns the list of cardinals in a quiver.
* The cardinals are returned in sorted order.
* If the graph has no tagged edges, None is returned.
"

CardinalList[graph_Graph] := None;

CardinalList[graph_Graph ? EdgeTaggedGraphQ] := Replace[
  AnnotationValue[graph, Cardinals],
  ($Failed | Automatic) :> extractCardinals[graph]
];

CardinalList[edges_List] :=
  SpliceCardinalSets @ UniqueCases[edges, DirectedEdge[_, _, c_] :> c];

extractCardinals[graph_] := DeleteCases[Union @ SpliceCardinalSets @ EdgeTags @ graph, Null];

(**************************************************************************************************)

PackageExport["LookupCardinalColors"]

SetUsage @ "
LookupCardinalColors[quiver$] returns the association of cardinals to colors for quiver$.
LookupCardinalColors[quiver$, c$] returns the color for cardinal c$.
* The annotation CardinalColors is returned if present.
* The cardinals are given in sorted order.
* If the graph has no tagged edges, <||> is returned.
* If c$ is an CardinalSet, the corresponding colors will be blended.
"

LookupCardinalColors[graph_Graph] :=
  Replace[
    AnnotationValue[graph, CardinalColors], {
      ($Failed | Automatic | None) :> ChooseCardinalColors @ CardinalList @ graph,
      palette:(_String | {_, _String} | _Offset) :> ChooseCardinalColors[CardinalList @ graph, palette]
    }
  ];

LookupCardinalColors[graph_Graph, card_] :=
  Lookup[LookupCardinalColors @ graph, card, Gray];

LookupCardinalColors[graph_Graph, CardinalSet[cards_List]] :=
  HumanBlend @ Sort @ Lookup[LookupCardinalColors @ graph, cards, Gray];

LookupCardinalColors[_] := $Failed;

(**************************************************************************************************)

PackageExport["ChooseCardinalColors"]

ChooseCardinalColors[None, ___] := <||>;

ChooseCardinalColors[cardinals_List, palette_:Automatic] := Switch[Sort @ cardinals,
  {"b", "g", "r"},
    <|"r" -> $Red, "g" -> $Green, "b" -> $Blue|>,
  _,
    AssociationThread[cardinals, ToColorPalette[palette, Length @ cardinals]]
];

(**************************************************************************************************)

PackageExport["RenameCardinals"]

RenameCardinals[graph_Graph, renaming:{__String}] :=
  RenameCardinals[graph, RuleThread[CardinalList @ graph, renaming]]

RenameCardinals[graph_Graph, {}] := graph;

RenameCardinals[graph_Graph, renaming:{__Rule}] := Scope[
  {vertices, edges} = VertexEdgeList @ graph;
  replacer = ReplaceAll @ Dispatch @ renaming;
  edges = MapAt[replacer, edges, {All, 3}];
  opts = DeleteOptions[AnnotationRules] @ Options @ graph;
  annos = Replace[
    ExtendedGraphAnnotations @ graph,
    opt:Rule[(VisibleCardinals | Cardinals | CardinalColors), _] :> replacer[opt],
    {1}
  ];
  Graph[
    vertices, edges,
    Sequence @@ opts,
    AnnotationRules -> {"GraphProperties" -> annos}
  ]
];

RenameCardinals[renaming_][graph_] :=
  RenameCardinals[graph, renaming];

(**************************************************************************************************)

PackageExport["TruncateQuiver"]
PackageExport["TruncatedVertex"]

declareFormatting[
  TruncatedVertex[v_, a_] :> Superscript[v, a]
];

SetUsage @ "
TruncatedVertex[vertex$, card$] represents a vertex that has been truncated in the direction card$.
";

Options[TruncateQuiver] = Prepend["AllowSkips" -> True] @ $simpleGraphOptionRules;

TruncateQuiver[quiver_, opts:OptionsPattern[]] :=
  TruncateQuiver[quiver, Automatic, opts];

TruncateQuiver[quiver_, cardinals:Except[_Rule], userOpts:OptionsPattern[]] := Scope[
  UnpackOptions[allowSkips];
  {vertices, edges} = VertexEdgeList @ quiver;
  SetAutomatic[cardinals, t = CardinalList[quiver]; Join[t, Negated /@ t]];
  If[StringQ[cardinals], cardinals //= ParseCardinalWord];
  ordering = AssociationRange[cardinals]; $n = Length @ cardinals;
  tagTable = Map[SortBy[cardOrder[ordering]], VertexTagTable[quiver, False]];
  tagOutTable = TagVertexOutTable @ quiver;
  vertexCoords = GraphVertexCoordinates @ quiver;
  CollectTo[{truncEdges, truncVertices, truncCoords},
  ScanThread[{v, tags, coord, tagOut} |-> (
    cornerVerts = Map[TruncatedVertex[v, #]&, tags];
    cornerEdges = If[allowSkips, cornerEdge, noskipCornerEdge[ordering]] /@ Partition[cornerVerts, 2, 1, 1];
    cornerCoords = Map[
      PointAlongLine[
        {coord, Part[vertexCoords, Lookup[tagOut, Replace[#, CardinalSet[s_] :> First[s]]]]},
        Scaled[0.25]]&,
      tags
    ];
    BagInsert[truncEdges, cornerEdges, 1];
    BagInsert[truncVertices, cornerVerts, 1];
    BagInsert[truncCoords, cornerCoords, 1])
  ,
    {vertices, tagTable, vertexCoords, AssociationTranspose @ tagOutTable}
  ]];
  truncEdges = Flatten @ {
    truncEdges, truncatedEdge /@ edges
  };
  opts = Options @ quiver;
  opts = Replace[opts, (AnnotationRules -> annos_) :>
    AnnotationRules -> DeleteOptions[annos, VertexAnnotations]];
  Graph[
    truncVertices,
    truncEdges,
    VertexCoordinates -> truncCoords,
    Cardinals -> {"f", "r"},
    Sequence @@ opts, FilterOptions @ userOpts
  ]
];

cardOrder[ordering_][CardinalSet[list_]] := Min @ Lookup[ordering, list];
cardOrder[ordering_][e_] := ordering[e];

tqSuccQ[a_, b_] := MatchQ[b - a, 1 | (1 + $n) | (1 - $n)];

noskipCornerEdge[ordering_][{a:TruncatedVertex[v1_, c1_], b:TruncatedVertex[v2_, c2_]}] :=
  If[tqSuccQ[ordering @ c1, ordering @ c2], DirectedEdge[a, b, "r"], Nothing];

cornerEdge[{a_, b_}] := DirectedEdge[a, b, "r"]

truncatedEdge[DirectedEdge[a_, b_, c_]] :=
  DirectedEdge[TruncatedVertex[a, c], TruncatedVertex[b, Negated @ c], CardinalSet[{"f", Negated @ "f"}]];
