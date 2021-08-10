Package["QuiverGeometry`"]


PackageImport["GeneralUtilities`"]


PackageExport["VertexAnnotations"]
PackageExport["EdgeAnnotations"]
PackageExport["ExtendedGraphLayout"]
PackageExport["GraphMetric"]
PackageExport["GraphOrigin"]
PackageExport["Cardinals"]
PackageExport["CustomGraphAnnotation"]

(**************************************************************************************************)

PackageExport["GraphVertexData"]
PackageScope["setupGraphVertexData"]

defineLiteralMacro[setupGraphVertexData,
  setupGraphVertexData[graph_, extra___Rule] := (
    $graphVertexIndex = AssociationRange @ VertexList @ graph;
    $graphVertexData = LookupVertexAnnotations[graph, All];
    AssociateTo[$graphVertexData, {extra}];
  )
];

getPart[list_List, i_Integer] /; 1 <= i <= Length[list] := Part[list, i];
getPart[_, _] := None;

getVertexElem[IndexedVertex[i_], data_] := getPart[data, i];
getVertexElem[vertex_, data_] := getPart[data, Lookup[$graphVertexIndex, vertex, 0]];

GraphVertexData[] := $graphVertexData;

GraphVertexData[vertex_, key_] :=
  getVertexElem[vertex, Lookup[$graphVertexData, key, None]];

(**************************************************************************************************)

PackageExport["GraphEdgeData"]
PackageScope["setupGraphEdgeData"]

defineLiteralMacro[setupGraphEdgeData,
  setupGraphEdgeData[graph_, extra___Rule] := (
    $graphEdgeIndex = AssociationRange @ EdgeList @ graph;
    $graphEdgeData = LookupEdgeAnnotations[graph, All];
    AssociateTo[$graphEdgeData, {extra}];
  )
];

getEdgeElem[IndexedEdge[i_], data_] := getPart[data, i];
getEdgeElem[edge_, data_] := getPart[data, Lookup[$graphEdgeIndex, edge, 0]];

GraphEdgeData[] := $graphEdgeData;

GraphEdgeData[edge_, key_] :=
  getEdgeElem[edge, Lookup[$graphEdgeData, key, None]];

(**************************************************************************************************)

PackageExport["Signed"]

SetUsage @ "
Signed is an option to various graph utility functions.
"

(**************************************************************************************************)

PackageScope["$extendedGraphUsage"]

$extendedGraphUsage = StringTrim @ "
| %GraphLayout | None | the overall layout method to use for vertices and edges |
| %LayoutDimension | Automatic | number of dimensions of the graph layout |
| %VertexLabels | None | how to label vertices |
| %ImageSize | Automatic | size to plot the graph |
| %GraphRegionHighlight | None | regions of the graph to highlight |
| %GraphLegend | Automatic | legend to attach to the entire graph |
| %ArrowheadSize | Automatic | size of arrowheads |
| %ArrowheadStyle | Automatic | style of arrowheads |
| %ArrowheadPosition | Automatic | position of arrowheads along edges |
| %ArrowheadShape | Automatic | shape of arrowheads |
| %EdgeSetback | Automatic | how far to set back edges from vertices |
| %EdgeThickness | Automatic | thickness of edges |
| %LabelCardinals | False | whether to attach labels to arrowheads |
| %VertexShapeFunction | Automatic | how to draw vertices |
| %EdgeShapeFunction | Automatic | how to draw edges |
| %VertexColorFunction | None | function to obtain colors for vertices |
| %EdgeColorFunction | None | function to obtain colors for edges |
| %VertexColorRules | None | color vertices by rules |
| %EdgeColorRules | None | color edges by rules |
| %RegionColorRules | None | color vertices and edges by region |
| %VertexAnnotations | None | association of additional per-vertex data |
| %VertexCoordinateRules | None | list of rules for per-vertex coordinates |
| %VertexCoordinateFunction | None | function for computing per-vertex coordinates |
| %EdgeAnnotations | None | association of additional per-edge data |
| %GraphMetric | Automatic | metric to calculate graph distances |
| %CardinalColors | Automatic | association of cardinal colors |
| %VisibleCardinals | All | which cardinals to draw |
| %ViewOptions | Automatic | how to project 3D coordinates |
| %AdditionalImagePadding | None | additional padding to include unconditionally |
| %ViewRegion | All | region of graph to plot |
| %AspectRatioClipping | True | whether to clip aspect ratio |
| %CoordinateTransformFunction | None | function to remap coordinates before plotting |
| %Frame | False | whether to draw a frame |
| %FrameStyle | Automatic | color of frame |

## Arrowheads

* Any of the specifications below can also be given in the form <|card$1 -> spec$1, $$|>.

* %ArrowheadShape accepts these settings:
| 'Arrow' | solid kinded arrowhead (default) |
| 'Line' | partial triangle formed by two lines |
| 'DoubleLine' | two closely spaced partial triangles |
| 'Triangle' | triangle formed by three lines |
| 'HalfTriangle' | half triangle above the edge |
| 'Disk' | circular disk |
| 'Square' | square |
| 'Diamond' | diamond (rotated square) |
| 'Cone' | thin cone (3D) |
| 'Sphere' | sphere (3D) |
| 'Cardinal' | no arrowhead, use cardinal label |
| 'CrossLine' | a horizontal line |
| 'CrossBar' | a thick horizontal line |
| 'Tube' | a tube |
| None | no arrowheads |

* In addition, %ArrowheadShape supports suboptions via {'shape$', subopts$$}:
| %NegationStyle | 'Flip' | how to plot negated cardinals in %CardinalSet[$$] |
| %TwoWayStyle | 'In' | how to plot negated pairs in %CardinalSet[$$] |
| %PairedDistance | 0 | how far away to plot negated pairs |
| %EdgeThickness | 1 | thickness of line-based arrowheads |

* %TwoWayStyle -> spec$ determines how to plot a cardinal and its negation together:
| 'Out' | arrowheads facing away from each other |
| 'OutClose' | facing out with backs touching |
| 'In' | arrowheads facing towards each other |
| 'InClose' | facing in with tips touching |
| 'spec$' | one of the regular shapes |

* %NegationStyle -> spec$ determines how negated cardinals are drawn:
| 'OverBar' | draw a negation bar above arrowhead |
| 'UnderBar' | drwa a negation bar below arrowhead |

* %PairedDistance -> size$ determines the separation of paired cardinals, in points.

* %ArrowheadSize accepts these settings:
| Automatic | use a safe arrowhead size, depending on layout |
| size$ | size$ in points in the final plot |
| Small, Medium, $$ | symbolic size, with Medium being equivalent to 20 |
| %AbsolutePointSize[size$] | equivalent to size$ |
| %PointSize[f$] | a fraction f$ of the width of the final plot |
| %Scaled[r$] | scale the default safe size by r$ |
| %Max[$$], %Min[$$] | max or min of several specifications |

* %ArrowheadStyle can be set to a color or list of directives.

* %CardinalColors -> <|card$1 -> col$1, $$|> determines the colors for arrowheads.

* %ArrowheadPosition -> r$ sets the position of the arrowhead to the fraction r$ along the \
length of the edge.

* %LabelCardinals -> True will add a label to each arrowhead indicating its cardinal.

## Edges

* %EdgeShapeFunction controls how edges are drawn, indepedently of arrowheads, and accepts:
| Automatic | use %Line or %Arrow as appropriate |
| None | do not draw edges |
| f$ | call f$ to obtain graphical primitives |

If a function f$ is given, it is provided with an association containing the following keys:
| 'Coordinates' | the list of {x$, y$} or {x$, y$, z$} coordinates |
| 'Source' | the source vertex |
| 'Target' | the target vertex |
| 'EdgeIndex' | the index of the edge |
| 'Counter' | an integer counter incremented on access |
| 'Shape' | the symbol %Line or %Arrow |
| 'Cardinal' | the cardinal(s) on the edge |
| 'Arrowheads' | the %Arrowheads[$$] expression (or None) |
| 'LabelStyle' | setting of %EdgeLabelStyle |

* The result can contain the expression %UniqueLabel[$$] inside a %Text[$$] primitive.
This will be renumbered so that all labels are ordered according to x$, y$ screen position.

* %EdgeColorFunction accepts these settings:
| None | color via %EdgeStyle (default) |
| 'Cardinal' | color by cardinal present on edge |
| {e$1, e$2, $$} | use values e$i in same order as %VertexList |
| <|e$1 -> val$1, $$, All -> val$|> | assign values to specific edges |
| {region$1 -> val$1, $$, All -> val$} | assign values to edges within specific regions |
| %Paletted[spec$, colors$] | use a given named or explicit color palette |
* If a spec produces non-color values, edges will colored based on the type of data.
* If %GraphLegend -> Automatic, a color legend will be shown.

* %EdgeSetback controls how far an edge should be set back from its endpoints.

* %EdgeThickness controls the thickness of rendered edges, and is given in points.

## Vertices

* %VertexShapeFunction controls how vertices are drawn and accepts these settings:
| Automatic | choose a method automatically |
| 'Point' | use %Point[$$] |
| 'Disk' | use %Disk[$$] |
| 'Sphere' | use %Sphere[$$] |
| 'Ball' | use 'Disk' for 2D and 'Sphere' for 3D |
| 'Square' | square (designed for 'Square' lattice) |
| 'Hexagon' | hexagon (designed for 'Triangular' lattice) |
| None | do not draw vertices |

* %VertexSize accepts these settings:
| Automatic | use a safe default size, depending on layout |
| size$ | size$ in points in the final plot |
| Small, Medium, $$ | symbolic size, with Medium being equivalent to 5 |
| %AbsolutePointSize[size$] | equivalent to size$ |
| %PointSize[f$] | a fraction f$ of the width of the final plot |
| %Scaled[r$] | fraction r$ of the quantiles of inter-vertex distance |
| {v$1 -> s$1, $$, %%All -> s$} | use specific sizes for specific vertices |
| %Max[$$],% Min[$$] | max or min of several specifications |

* %VertexColorFunction accepts these settings:
| None | color via %VertexStyle (default) |
| 'key$' | color with values from setting of %VertexAnnotations |
| {val$1, val$2, $$} | use values val$i in same order as %VertexList |
| <|v$1 -> val$1, $$, All -> val$|> | assign values to specific vertices |
| {region$1 -> val$1, $$, All -> val$} | assign values to vertices within specific regions |
| f$ | apply f$ to vertices to obtain values |
| spec$ -> f$ | apply f$ to result of spec$ |
| %Paletted[spec$, colors$] | use a given named or explicit color palette |
* If a spec produces non-color values, vertices will colored based on the type of data.
* If %GraphLegend -> Automatic, a color legend will be shown.

## Metrics

* %GraphMetric affects the behavior of %MetricDistance, %MetricDistanceMatrix, and %MetricFindShortestPath.
* The following settings are accepted:
| Automatic | the default graph distance |
| 'Euclidean' | root total square of per-cardinal distances |
| 'Chessboard' | maximum of the per-cardinal distances |
| %QuadraticForm[$$] | use a quadratic form |
| {s$1, s$2, $$} | use a particular signature |
| n$ | use a homogenous form of degree n$ |
| f$ | apply f$ to association of per-cardinal distances |

## Labeling

* %VertexLabels determines how to label vertices, and accepts these settings:
| None | do not label vertices (default) |
| Automatic | label with vertex names |
| 'Index' | label with vertex indices |
| 'key$' | label with values from VertexAnnotation |
| %Tooltip[spec$] | label vertices via a tooltip |

* %EdgeLabels determines how to label edges, and accepts these settings:
| None | do not label edges |
| 'Index' | label with edge index |
| Automatic | label edges with their cardinals |

* %VertexLabelStyle and %EdgeLabelStyle accept these settings:
| Automatic | default |
| styles$ | a list, directive, or individual style |
| {styles$, opt$ -> val$, $$} | provide suboptions |
Supported suboptions are:
| %ItemSize | a symbolic, numeric, or %Scaled[$$] value |
| %Background | additional background to distinguish labels |
| %BaseStyle | extra options to control font, etc. |
| %LabelPosition | one of Above, Below, Left, Right, Center, or Automatic |
| %Spacings | size of offset from the labelled element |
* %VertexLabelStyle -> {%LabelPosition -> Automatic} will maximize the distance to adjacent edges.

## Annotations

* %VertexAnnotations can be set to an association between named properties and lists of values.
* The values should be in the same order and length as given by %VertexList.
* These values are accessible via %VertexColorFunction and %VertexLabels.

* %EdgeAnnotations can be set to an asssocation between named properties and associations of values.
* These associations should have keys that are edge indices.
* Tthese values are accessible via %EdgeLabels.

## Highlights and colors

* %GraphRegionHighlight takes a list of regions to highlight, see %GraphRegion.

* %RegionColorRules can be a list of rules of the following forms:
| region$ -> color$ | set color of vertices and edges within region, see %GraphRegion |
| vertex$ -> color$ | set color of a specific vertex |
| edge$ -> color$ | set color of a specific edge |
| {spec$1, $$} -> color$ | set color of several elements at once |

## Legends

* %GraphLegend accepts these settings:
| None | no legend |
| Automatic | attach legends for cardinals, colors, highlights, etc |
| expr$ | use a custom legend given by expr$ |

## Misc

* %CoordinateTransformFunction can be a function, which will be applied to each coordinates, or one of:
| {'Rotate', n$} | rotate by n$ degrees |
| 'Rotate0' | don't rotate |
| 'Rotate90' | rotate 90\[Degree] |
| 'Rotate180' | rotate 180\[Degree] |
| 'Rotate270' | rotate 270\[Degree] |
| 'ReflectHorizontal' | reflect horizontally |
| 'ReflectVertical' | reflect vertically |
| 'BendVertical' | bend vertical edges for layered digraphs |
| {'Snap', n$} | snap vertices to n$ \[Times] n$ grid |
| 'PolarProjection' | spherical polar projection |

* %Padding, whether in %ImagePadding or %AdditionImagePadding, can be specified in these forms:
| None | no padding |
| n$ | pad by n$ on all sides |
| {h$, v$} | pad by h$ horizontally and v$ vertically |
| {{l$, r$}, {b$, t$}} | explicit padding |
| {Left -> l$, $$} | per-side padding |

* %Frame -> True will draw a frame that encompasses the vertices and edges, plus any additional
padding included by %ImagePadding. The effects of %AdditionalImagePadding will not be included.

* The special expression %GraphicsValue[$$] can be used in %Prolog, %Epilog, or by shape functions.
It will be replaced with computed values after plotting is complete. See %GraphicsValue for more information.
"

(**************************************************************************************************)

$extendedGraphOptionsRules = {
  GraphPlottingFunction -> None,
  GraphRegionHighlight -> None,
  GraphLegend -> None,
  ArrowheadSize -> Automatic,
  ArrowheadStyle -> Automatic,
  ArrowheadShape -> Automatic,
  ArrowheadPosition -> Automatic,
  EdgeSetback -> Automatic,
  VertexColorFunction -> None,
  EdgeColorFunction -> None,
  VertexAnnotations -> None,
  EdgeAnnotations -> None,
  LayoutDimension -> Automatic,
  ExtendedGraphLayout -> Automatic,
  GraphMetric -> Automatic,
  GraphOrigin -> None,
  Cardinals -> Automatic,
  CardinalColors -> Automatic,
  CardinalColorRules -> None,
  CardinalColorFunction -> None,
  VisibleCardinals -> All,
  ViewOptions -> Automatic,
  LabelCardinals -> False,
  CoordinateTransformFunction -> None,
  ViewRegion -> All,
  AdditionalImagePadding -> None,
  AspectRatioClipping -> True,
  EdgeThickness -> Automatic,
  VertexCoordinateRules -> None,
  VertexCoordinateFunction -> None,
  VertexColorRules -> None,
  EdgeColorRules -> None,
  RegionColorRules -> None,
  PrologFunction -> None,
  EpilogFunction -> None,
  UseAbsoluteSizes -> True,
  SelfLoopRadius -> Automatic,
  MultiEdgeDistance -> Automatic,
  CustomGraphAnnotation[_String] -> None,
  VertexLabelPosition -> Top,
  EdgeLabelPosition -> Top,
  VertexLabelSpacing -> 0,
  EdgeLabelSpacing -> 0,
  VertexLabelBaseStyle -> None,
  EdgeLabelBaseStyle -> None
};

$extendedGraphOptionSymbols = Keys @ $extendedGraphOptionsRules;

$extendedGraphOptionSymbolPattern = Alternatives @@ $extendedGraphOptionSymbols;

$extendedGraphOptionRulePattern = Rule[$extendedGraphOptionSymbolPattern, _];

$notIntercepted = True;

Graph;
SyntaxInformation[Graph];
Options[Graph];

$fullGraphOptions = Sort @ JoinOptions[Graph, $extendedGraphOptionsRules];
$extendedGraphSymbolNames = Map[SymbolName, Select[SymbolQ] @ Keys @ $fullGraphOptions];

Unprotect[Graph];
SyntaxInformation[Graph] = ReplaceOptions[SyntaxInformation[Graph], "OptionNames" -> $extendedGraphSymbolNames];
HoldPattern[g:Graph[___]] /; MemberQ[Unevaluated @ g, $extendedGraphOptionRulePattern] && $notIntercepted :=
  Block[{$notIntercepted = False}, interceptedGraphConstructor[g]];
Protect[Graph];

$extendedGraphOptionSymbols2 = Append[$extendedGraphOptionSymbols, AnnotationRules];

splitUserGraphOptions[options___Rule] := Scope[
  options = {options};
  If[!MemberQ[options, ExtendedGraphLayout -> _] && MemberQ[options, GraphLayout -> _], 
    options = Replace[options, Rule[GraphLayout, l_] :> Rule[ExtendedGraphLayout, l], {1}]];
  extOptions = DeleteDuplicatesBy[TakeOptions[options, $extendedGraphOptionSymbols], First];
  options = Map[optionFixup] @ DeleteOptions[options, $extendedGraphOptionSymbols2];
  {options, checkGraphAnnotations @ extOptions}
];

SetHoldAllComplete[interceptedGraphConstructor];

interceptedGraphConstructor[Graph[Shortest[args__], options__Rule]] := Scope[
  {newOptions, extOptions} = splitUserGraphOptions[options];
  result = Graph[args, Sequence @@ newOptions];
  (* todo: forgoe Annotate and just do the combination ourselves *)
  If[!GraphQ[result], result = makeNewGraph[args, newOptions]];
  If[!GraphQ[result], ReturnFailed[]];
  Annotate[result, extOptions]
];

makeNewGraph[graph_Graph ? GraphQ, newOptions_List] :=
  Graph[VertexList @ graph, EdgeList @ graph, Sequence @@ newOptions, Sequence @@ Options @ graph];

makeNewGraph[___] := $Failed;

(* these compensate for a weird extra level of list that Graph adds *)
optionFixup = Case[
  Rule[VertexSize, r:{__Rule}]                    := Rule[VertexSize, Association @ r];
  Rule[sym:(VertexLabels | EdgeLabels), l_List | l_Rule] := If[MatchQ[l, {_Hold}], First @ l, Rule[sym, Hold[l]]];
  Rule[sym:(EdgeStyle|VertexStyle), val_]         := Rule[sym, toDirective[val]];
  Rule[VertexShapeFunction, assoc_Association]    := Rule[VertexShapeFunction, toShape /@ assoc];
  Rule[sym:(GraphHighlightStyle|VertexLabelStyle|EdgeLabelStyle), elem_] := Rule[sym, toDirective[elem]];
  other_                                          := other;
];

(* TODO: compute sizes here so that graph layout knows about them *)
toShape[g_Graph] := ExtendedGraphPlot @ g;
toShape[other_] := other;

interceptedGraphConstructor[e_] := e;

(**************************************************************************************************)

$arrowheadSizePattern = Alternatives[
  _ ? NumericQ,
  $SymbolicSizePattern,
  Scaled[(_ ? NumericQ) | $SymbolicSizePattern],
  PointSize[_ ? NumericQ],
  _Association,
  Automatic | None
];

$vertexAnnotationsPattern = Alternatives[
  Association[RepeatedNull[_String -> _List]],
  None
];

$edgeAnnotationsPattern = Alternatives[
  Association[RepeatedNull[_String -> _Association]],
  None
];
$layoutDimensionPattern = Alternatives[
  Automatic, None, 2, 3
];

$graphMetricPattern = Alternatives[
  Automatic, "Euclidean", _QuadraticFormObject, _List, _Integer, _ ? System`Private`MightEvaluateWhenAppliedQ
];

$viewOptionKeysPattern = Alternatives[
  ViewPoint, ViewCenter, ViewVertical, ViewVector, ViewMatrix, ViewProjection, ViewAngle
];

$viewOptionsRulePattern = Automatic | {RepeatedNull[$viewOptionKeysPattern -> _]};

$extendedGraphOptionPatterns = <|
  ArrowheadSize -> $arrowheadSizePattern,
  VertexAnnotations -> $vertexAnnotationsPattern,
  EdgeAnnotations -> $edgeAnnotationsPattern,
  LayoutDimension -> $layoutDimensionPattern,
  GraphMetric -> $graphMetricPattern,
  ViewOptions -> $viewOptionsRulePattern
|>;

checkGraphAnnotations[rules_List] := Map[checkGraphAnnotationRule, rules];

General::badextopt = "The extended option `` -> `` is invalid and will be ignored."

checkGraphAnnotationRule[key_ -> value_] /; And[
  KeyExistsQ[$extendedGraphOptionPatterns, key],
  !MatchQ[value, $extendedGraphOptionPatterns @ key]] := (
    Message[Graph::badextopt, key, value];
    Nothing
  );

checkGraphAnnotationRule[rule_] := rule;

(**************************************************************************************************)

PackageExport["AttachGraphOptions"]

AttachGraphOptions[graph_Graph ? GraphQ, opts___] := Scope[
  result = Graph[graph, opts];
  If[GraphQ[result], result, makeNewGraph[graph, {opts}]]
];

(**************************************************************************************************)

PackageExport["ExtendedGraphQ"]

ExtendedGraphQ[g_Graph ? GraphQ] :=
  Count[AnnotationValue[g, $extendedGraphOptionSymbols], $Failed] =!= Length[$extendedGraphOptionSymbols];

ExtendedGraphQ[_] := False;

(**************************************************************************************************)

PackageExport["LookupExtendedOption"]

LookupExtendedOption[graph_, keys_List] :=
  MapThread[
    If[#1 === $Failed, #2, #1]&,
    {AnnotationValue[graph, keys], Lookup[$extendedGraphOptionsRules, keys]}
  ];

LookupExtendedOption[graph_, key_Symbol | key_CustomGraphAnnotation] :=
  LookupAnnotation[graph, key, Lookup[$extendedGraphOptionsRules, key]];

(**************************************************************************************************)

PackageScope["ExtendedGraphAnnotations"]

ExtendedGraphAnnotations[graph_] :=
  Normal @ DeleteCases[$Failed] @ AssociationThread[
    $extendedGraphOptionSymbols,
    AnnotationValue[graph, $extendedGraphOptionSymbols]
  ];

(**************************************************************************************************)

PackageScope["$simpleGraphOptions"]
PackageScope["$simpleGraphOptionRules"]

$simpleGraphOptionRules = JoinOptions[
  EdgeLabels -> None, GraphLayout -> Automatic, ImagePadding -> None,
  ImageSize -> Automatic, VertexCoordinates -> Automatic,
  VertexLabels -> None, VertexSize -> Automatic,
  VertexStyle -> Automatic, EdgeStyle -> Automatic,
  VertexShapeFunction -> Automatic, EdgeShapeFunction -> Automatic, PlotLabel -> None,
  GraphHighlightStyle -> Automatic, VertexLabelStyle -> Automatic, EdgeLabelStyle -> Automatic,
  Epilog -> {}, Prolog -> {}, Frame -> None, FrameStyle -> Automatic, BaselinePosition -> Automatic,
  FrameLabel -> None, PlotRange -> Automatic,
  Rest @ $extendedGraphOptionsRules
]

$simpleGraphOptions = Keys @ $simpleGraphOptionRules;

(**************************************************************************************************)

PackageExport["ExtendedGraph"]

SetUsage @ "
ExtendedGraph[args$$] acts like Graph but accepts additional options and overrides how graphs are \
displayed.
* The following options and additional options are supported:
<*$extendedGraphUsage*>
"

Options[ExtendedGraph] = $simpleGraphOptionRules;
ExtendedGraph[args___] :=
  interceptedGraphConstructor[Graph[args, GraphPlottingFunction -> ExtendedGraphPlottingFunction]];

(**************************************************************************************************)

PackageExport["GraphCache"]

SetUsage @ "
GraphCache[sym$] represents a cache of computed properties of a graph that stores cached properties \
in sym$.
";

SetHoldAllComplete[GraphCache];


PackageScope["declareGraphCacheFriendly"]

declareGraphCacheFriendly[sym_] := (
  System`Private`SetValid[sym];
  System`Private`SetNoEntry[sym];
);
declareGraphCacheFriendly[syms__] := Scan[declareGraphCacheFriendly, {syms}];

MakeBoxes[GraphCache[_, sym_Symbol], StandardForm] :=
  RowBox[{"GraphCache", "[", "{", RowBox @ Flatten @ Riffle[ToBoxes /@ Keys @ sym, ","], "}", "]"}];

SetHoldRest[CreateGraphCache];
CreateGraphCache[graph_Graph, symbol_Symbol] := (
  symbol = Data`UnorderedAssociation[];
  GraphCache[graph, symbol]
);

GraphCache /: Print[GraphCache[graph_, sym_]] := Print[Keys @ sym];

(* for ordinary functions, evaluate them on the raw graph *)
GraphCache /: f_Symbol[GraphCache[graph_, sym_], args___] /; System`Private`HasDownEvaluationsQ[f] && System`Private`NotValidQ[f] :=
  f[graph, args];

(* for cache-friendly functions, which have the entryq flag set if they are not in the process of evaluating,
first check the cache, and if not present, mark them as being evaluated, compute the result by passing in the GraphCache,
then cache the result *)
GraphCache /: f_Symbol[gc:GraphCache[_, sym_], args___] /; System`Private`ValidQ[f] && System`Private`NoEntryQ[f] :=
  Lookup[sym, Key @ {f, args}, evaluateWithoutRecursion[sym, f, gc, args]];

SetHoldFirst[evaluateWithoutRecursion];
evaluateWithoutRecursion[sym_, f_, gc_, args___] := Block[{res},
  System`Private`SetNoEntry[f, False];
  sym[{f, args}] = res = f[gc, args];
  System`Private`SetNoEntry[f];
  res
];

$graphCacheEnabled = True;

(**************************************************************************************************)

PackageExport["VertexEdgeList"]

SetUsage @ "
VertexEdgeList[graph$] returns {vertices$, edges$}.
"

VertexEdgeList[graph_] := {VertexList @ graph, EdgeList @ graph};

(**************************************************************************************************)

PackageExport["ToIndexGraph"]

ToIndexGraph[graph_ ? IndexGraphQ] := graph;
ToIndexGraph[graph_] := IndexGraph @ graph;


(**************************************************************************************************)

PackageExport["PermuteVertices"]

SetUsage @ "
PermuteVertices[graph$] permutes the %VertexList order of vertices in graph$.
* The option %RandomSeeding controls the pseudorandom permutation.
"

Options[PermuteVertices] = {RandomSeeding -> Automatic};

PermuteVertices[graph_, OptionsPattern[]] := Scope @ RandomSeeded[
  indices = RandomSample @ Range @ VertexCount @ graph;
  scrambler = PartOperator[indices];

  options = Options @ graph;
  coords = LookupOption[options, VertexCoordinates];
  If[ListQ[coords], options //= ReplaceOptions[VertexCoordinates -> scrambler[coords]]];

  vertexAnnos = LookupExtendedOption[graph, VertexAnnotations];
  If[AssociationQ[vertexAnnos], vertexAnnos //= Map[scrambler]];

  result = Graph[scrambler @ VertexList @ graph, EdgeList @ graph, Sequence @@ options];
  If[AssociationQ[vertexAnnos], result = Annotate[result, VertexAnnotations -> vertexAnnos]];

  result
,
  OptionValue[RandomSeeding]
];

(**************************************************************************************************)

PackageExport["ExpandCardinalSetEdges"]

SetUsage @ "
ExpandCardinalSetEdges[graph$] expands any edges tagged with CardinalSet into multiple edges with \
one cardinal each.
* CombineMultiedges is the inverse of ExpandCardinalSetEdges.
"

ExpandCardinalSetEdges[graph_] := If[
  FreeQ[EdgeTags @ graph, CardinalSet], graph,
  Graph[
    VertexList @ graph,
    SpliceCardinalSetEdges @ EdgeList @ graph,
    Options @ graph
  ]
];

(**************************************************************************************************)

PackageExport["RemoveEdgeTags"]

SetUsage @ "
RemoveEdgeTags[graph$] removes edge tags from edges of graph$, returning a new graph.
RemoveEdgeTags[{edge$1, edge$2, $$}] removes edge tags from edge$i, returning a new list.
* This turns a cardinal quiver into an unlabelled quiver.
"

RemoveEdgeTags = Case[
  list_ ? EdgeListQ              := Take[list, All, 2];
  graph_Graph ? EdgeTaggedGraphQ := Graph[
    VertexList @ graph,
    RemoveEdgeTags @ EdgeList @ graph,
    Options @ graph
  ];
  graph_Graph                    := graph;
  _ := $Failed
];

(**************************************************************************************************)

PackageExport["MapEdgeTags"]

SetUsage @ "
MapEdgeTags[f$, graph$] applies the function f$ to the edge tags of edges of graph$.
MapEdgeTags[{edge$1, edge$2, $$}, f$] applies f$ to tags of a list of edges.
"

MapEdgeTags[f_, list_ ? EdgeListQ] :=
  MapAt[f, list, {All, 2}];

MapEdgeTags[f_, graph_Graph ? EdgeTaggedGraphQ] := Graph[
  VertexList @ graph,
  MapEdgeTags[f, EdgeList @ graph],
  Options @ graph
];

MapEdgeTags[_, graph_Graph] := graph;

MapEdgeTags[_, _] := $Failed

MapEdgeTags[f_][graph_] := MapEdgeTags[f, graph];

(**************************************************************************************************)

PackageExport["MapEdges"]

SetUsage @ "
MapEdges[f$, graph$] applies the function f$ to the edges of f$.
"

MapEdges[f_, graph_Graph] := Graph[
  VertexList @ graph,
  Map[f, EdgeList @ graph],
  Options @ graph
];

MapEdges[f_, _] := $Failed;

MapEdges[f_][g_] := MapEdges[f, g];

(**************************************************************************************************)

PackageExport["EdgeListQ"]

SetUsage @ "
EdgeListQ[e$] returns True if e$ is a list of edges (%UndirectedEdge or %DirectedEdge).
"

EdgeListQ = Case[
  {RepeatedNull[_DirectedEdge | UndirectedEdge]} := True;
  _ := False
];

(**************************************************************************************************)

PackageExport["CombineMultiedges"]

SetUsage @ "
CombineMultiedges[graph$] combines edges that share the same endpoints into \
single edges, combining any cardinals they have.
* ExpandCardinalSetEdges is the inverse of CombineMultiedges.
"

CombineMultiedges[graph_Graph] := iCombineMultiedges[graph];

iCombineMultiedges[graph_] := Scope[
  If[EdgeCount[graph] === 0, Return @ graph];
  {vertices, edges} = VertexEdgeList[graph];
  {edges, tags} = Transpose @ Map[separateTag, edges];
  edgeGroups = PositionIndex[edges];
  If[Length[edgeGroups] === Length[edges], Return @ graph];
  edges = KeyValueMap[
    {edge, indices} |-> reattachTag[edge, DeleteNone @ Part[tags, indices]],
    edgeGroups
  ];
  opts = Options[graph];
  Graph[vertices, edges, opts]
];

separateTag = Case[
  DirectedEdge[a_, b_, t_] /; Order[a, b] == -1 := {DirectedEdge[b, a], Negated @ t};
  DirectedEdge[a_, b_, t_]                      := {DirectedEdge[a, b], t};
  UndirectedEdge[a_, b_, t_]                    := {Sort @ UndirectedEdge[a, b], t};
  edge_                                         := {Sort @ edge, None}
];

reattachTag[edge_, {}] := edge;
reattachTag[edge_, {tag_}] := Append[edge, tag];
reattachTag[edge_, tags_List] := Append[edge, SimplifyCardinalSet @ CardinalSet @ tags];

(**************************************************************************************************)

PackageExport["CardinalSet"]

SetUsage @ "
CardinalSet[cardinals$] represents a set of cardinals that is simultaneously present on an edge.
"

MakeBoxes[CardinalSet[set_List], TraditionalForm] :=
  RowBox @ Riffle[MakeBoxes[#, TraditionalForm]& /@ set, " "];

PackageExport["SimplifyCardinalSet"]

SimplifyCardinalSet = Case[
  CardinalSet[{a_}]                               := % @ a;
  CardinalSet[{l___, CardinalSet[{m___}], r___}]  := % @ CardinalSet[{l, m, r}];
  other_                                          := other;
];

(**************************************************************************************************)

PackageScope["SpliceCardinalSets"]

SpliceCardinalSets[e_] := ReplaceAll[ReplaceAll[e, CardinalSet -> Splice], Negated[z_] :> z];

(**************************************************************************************************)

PackageScope["SpliceCardinalSetEdges"]

SpliceCardinalSetEdges[e_] := ReplaceAll[e, DirectedEdge[a_, b_, CardinalSet[s_]] :> Splice[DirectedEdge[a, b, #]& /@ s]];

(**************************************************************************************************)

PackageExport["VertexRange"]

SetUsage @ "
VertexRange[graph$] returns {1, 2, $$, n$} where n$ is the number of vertices in graph.
"

VertexRange[graph_] := Range @ VertexCount @ graph;

(**************************************************************************************************)

PackageExport["AdjacentPairs"]

SetUsage @ "
AdjacentPairs[graph$] gives the list of {{u$1, v$1}, {u$2, v$2}, $$} such that \
vertex with index u$i is adjacent to vertex with index v$i.
* Note that AdjacentPairs is not given in the same order as %EdgeList[graph$], and \
in general might have fewer values when there are multiple edges between the same \
pair of vertices.
* The relation is undirected, so that a$ \[DirectedEdge] b$ generates both {a$, b$} and {b$, a$}.
* Use AdjacentPairs[graph, 'Directed'] to obtain the directed form.
"

AdjacentPairs[graph_] := AdjacencyMatrix[graph]["NonzeroPositions"];

AdjacentPairs[graph_ ? DirectedGraphQ] := Scope[
  adj = AdjacencyMatrix[graph];
  (adj + Transpose[adj])["NonzeroPositions"]
];

AdjacentPairs[graph_, "Undirected"] := AdjacentPairs[graph];
AdjacentPairs[graph_, "Directed"] := AdjacencyMatrix[graph]["NonzeroPositions"];

(**************************************************************************************************)

PackageExport["EdgePairs"]

SetUsage @ "
EdgePairs[graph$] gives the list of {{u$1, v$1}, {u$2, v$2}, $$}} such that \
these is an vertex with index u$i is connected to vertex with index v$i.
* EdgePairs[graph$] has the same length and order as EdgeList[graph$].
* If the correspondence with EdgeList does not matter, consider using AdjacentPairs,
which is faster.
"

(* todo: find a better way of obtaining these than via indexgraph! it seems like
vertex renaming might be expensive, and there is all the option processing that goes along with it.
unfortunately i can't find a way of extracting the list of edges in indexed form directly. *)
EdgePairs[graph_ ? EdgeTaggedGraphQ] := {#1, #2}& @@@ EdgeList @ ToIndexGraph @ graph;
EdgePairs[graph_] := List @@@ EdgeList @ ToIndexGraph @ graph;

(**************************************************************************************************)

PackageExport["VertexOutTable"]
PackageExport["VertexInTable"]

SetUsage @ "
VertexOutTable[graph$] returns a list of lists {out$1, out$2, $$} where out$i is a list of the \
indices of the vertices that are have a connection from vertex v$i.
"

SetUsage @ "
VertexInTable[graph$] returns a list of lists {in$1, in$2, $$} where in$i consists of the \
indices of the vertices that are have a connection to vertex v$i.
"

VertexOutTable[graph_] := AdjacencyMatrix[graph]["AdjacencyLists"];
VertexInTable[graph_] := Transpose[AdjacencyMatrix[graph]]["AdjacencyLists"];

(**************************************************************************************************)

PackageExport["VertexInOutTable"]

SetUsage @ "
VertexInOutTable[graph$] returns a list of pairs of lists {{in$1, out$1}, {in$2, out$2}, $$} where in$i \
is the list of indices of vertices that are have an edge to vertex v$i, and out$i is the \
list of indices of vertices that have a edge from vertex v$i.
"

VertexInOutTable[graph_] := Scope[
  adj = AdjacencyMatrix[graph];
  Transpose[{adj["AdjacencyLists"], Transpose[adj]["AdjacencyLists"]}]
];

(**************************************************************************************************)

PackageExport["VertexAdjacencyTable"]

SetUsage @ "
VertexAdjacencyTable[graph$] returns a list of lists {adj$1, adj$2, $$} where adj$i \
is the list of indices of vertices that are have a connection to vertex v$i.
"

VertexAdjacencyTable[graph_] := Scope[
  adj = AdjacencyMatrix[graph];
  MapThread[Union, {adj["AdjacencyLists"], Transpose[adj]["AdjacencyLists"]}]
];

(**************************************************************************************************)

PackageExport["VertexOutEdgeTable"]
PackageExport["VertexInEdgeTable"]

SetUsage @ "
VertexOutEdgeTable[graph$] returns a list of lists {out$1, out$2, $$} where out$i is a list of the \
indices of edges whose origin is the vertex v$i.
"

SetUsage @ "
VertexInEdgeTable[graph$] returns a list of lists {in$1, in$2, $$} where in$i is a list of the \
indices of edges whose destination is the vertex v$i.
"

VertexOutEdgeTable[graph_] :=
  Lookup[PositionIndex @ FirstColumn @ EdgePairs @ graph, VertexRange @ graph, {}];

VertexInEdgeTable[graph_] :=
  Lookup[PositionIndex @ LastColumn @ EdgePairs @ graph, VertexRange @ graph, {}];

(**************************************************************************************************)

PackageExport["VertexInOutEdgeTable"]

SetUsage @ "
VertexInOutEdgeTable[graph$] returns a list of lists {{in$1, out$1}, {in$2, out$2}, $$}  where in$i \
is a list of the indices of edges whose destination is the vertex v$i, and out$i is a list of the \
indices of edges whose origin is the vertex v$i.
"

VertexInOutEdgeTable[graph_] := Scope[
  pairs = EdgePairs @ graph;
  vertices = VertexRange @ graph;
  Transpose[{
    Lookup[PositionIndex @ LastColumn @ pairs, vertices, {}],
    Lookup[PositionIndex @ FirstColumn @ pairs, vertices, {}]
  }]
];

(**************************************************************************************************)

PackageExport["VertexAdjacentEdgeTable"]

SetUsage @ "
VertexAdjacentEdgeTable[graph$] returns a list of lists {adj$1, adj$2, $$}  where adj$i \
is a list of the indices of edges which begin or end at vertex v$i.
* If the option %Signed -> True is provided, edges will be wrapped in Negated if they are traversed in the \
reversed direction.
"

Options[VertexAdjacentEdgeTable] = {Signed -> False};

VertexAdjacentEdgeTable[graph_, OptionsPattern[]] := Scope[
  pairs = EdgePairs @ graph;
  vertices = VertexRange @ graph;
  negator = If[OptionValue[Signed], Map[Negated, #, {2}]&, Identity];
  MapThread[Union, {
    Lookup[PositionIndex @ FirstColumn @ EdgePairs @ graph, vertices, {}],
    Lookup[negator @ PositionIndex @ LastColumn @ EdgePairs @ graph, vertices, {}]
  }]
];

(**************************************************************************************************)

PackageExport["TagIndices"]

SetUsage @ "
TagIndices[graph$] returns an association from cardinals to the indices of edges on which they are present.
"

TagIndices[graph_] := Scope[
  $tagAssoc = <||>;
  ScanIndexed[processTagEntry, EdgeTags @ graph];
  $tagAssoc
];

processTagEntry[tag_, {part_}] :=
  KeyAppendTo[$tagAssoc, tag, part];

processTagEntry[CardinalSet[tags_], {part_}] :=
  Scan[KeyAppendTo[$tagAssoc, StripNegated @ #1, part]&, tags];

(**************************************************************************************************)

PackageExport["TagVertexOutTable"]

SetUsage @ "
TagVertexOutTable[graph$] returns an association from each cardinal to its VertexOutTable.
TagVertexOutTable[graph$, invalid$] uses invalid$ instead of None.
* If a cardinal is not incident to a given vertex, the corresponding entry is None.
* Keys are included for negations of cardinals.
* As there is a maximum of edge for a given vertex and cardinal, table entries are single integers or None.
"

TagVertexOutTable[graph_, invalid_:None] := Scope[
  cardinals = CardinalList @ graph;
  igraph = ToIndexGraph @ graph;
  cardinals = Join[cardinals, Negated /@ cardinals];
  outTables = ConstantAssociation[cardinals, ConstantArray[invalid, VertexCount @ igraph]];
  ({src, dst, tag} |-> (
      Part[outTables, Key @ tag, src] = dst;
      Part[outTables, Key @ Negated @ tag, dst] = src;
  )) @@@ SpliceCardinalSetEdges @ EdgeList[igraph];
  outTables
];

(**************************************************************************************************)

PackageExport["VertexTagTable"]

SetUsage @ "
VertexTagTable[graph$] returns a list of lists {tags$1, tags$2, $$} where tag$i is the list of tags \
present on vertex v$i.
"

VertexTagTable[graph_, splice_:True] := Scope[
  rules = {#1 -> #3, #2 -> Negated[#3]}& @@@ If[splice, SpliceCardinalSetEdges, Identity] @ EdgeList[graph];
  Lookup[Merge[Flatten @ rules, Identity], VertexList @ graph, {}]
]

(**************************************************************************************************)

PackageExport["VertexOutTagTable"]

SetUsage @ "
VertexOutTagTable[graph$] returns a list of lists {tags$1, tags$2, $$} where tag$i is the list of tags \
present on vertex v$i in the outgoing direction.
"

VertexOutTagTable[graph_, splice_:True] := Scope[
  rules = #1 -> #3& @@@ If[splice, SpliceCardinalSetEdges, Identity] @ EdgeList[graph];
  Lookup[Merge[rules, Identity], VertexList @ graph, {}]
]


(**************************************************************************************************)

PackageExport["TagVertexAdjacentEdgeTable"]

SetUsage @ "
TagVertexAdjacentEdgeTable[graph$] returns an association from each cardinal to its VertexAdjacentEdgeTable.
TagVertexAdjacentEdgeTable[graph$, invalid$] uses invalid$ instead of None.
* If a cardinal is not incident to a given vertex, the corresponding entry is None.
* Keys are included for negations of cardinals.
* As there is a maximum of edge for a given vertex and cardinal, table entries are single integers or None.
* If the option %Signed -> True is provided, edges will be wrapped in Negated if they are traversed in the \
reversed direction.
"

Options[TagVertexAdjacentEdgeTable] = {Signed -> False};

TagVertexAdjacentEdgeTable[graph_, opts:OptionsPattern[]] :=
  TagVertexAdjacentEdgeTable[graph, None, opts];

TagVertexAdjacentEdgeTable[graph_, invalid_, OptionsPattern[]] := Scope[
  outTable = VertexOutEdgeTable @ graph;
  inTable = VertexInEdgeTable @ graph; $invalid = invalid;
  negator = If[OptionValue[Signed], mapNegated, Identity];
  Merge[mergeNone] @ KeyValueMap[
    {key, edgeIndices} |-> {
      key ->          Map[First[Intersection[#, edgeIndices], invalid]&, outTable],
      Negated[key] -> negator @ Map[First[Intersection[#, edgeIndices], invalid]&, inTable]
    },
    TagIndices @ graph
  ]
];

mapNegated[e_] := Map[If[# === $invalid, #, Negated[#]]&, e];

mergeNone[{a_}] := a;
mergeNone[{a_, b_}] := MapThread[If[#1 === $invalid, #2, #1]&, {a, b}];

(**************************************************************************************************)

PackageExport["VertexIndexAssociation"]

VertexIndexAssociation[graph_] := AssociationRange @ VertexList @ graph;

(**************************************************************************************************)

PackageExport["EdgeIndexAssociation"]

EdgeIndexAssociation[graph_] := AssociationRange @ EdgeList @ graph;

(**************************************************************************************************)

PackageExport["VertexOrientedOutTable"]

SetUsage @ "
VertexOrientedOutTable[graph$] returns a list of pairs of lists {{dout$1, uout$1}, {dout$2, uout$2}, $$} \
where dout$i is the list of indices of vertices that are have a directed edge from vertex i$, and uout$i is \
the list of indices of vertices that have a undirected edge from vertex i$.
"

toOutTable[count_, edges_] := Lookup[GroupBy[edges, First -> Last], Range[count], {}];

VertexOrientedOutTable[graph_] := Scope[
  edges = EdgeList @ IndexGraph @ graph; count = VertexCount[graph];
  dir = Cases[edges, _DirectedEdge];
  undir = Cases[edges, _UndirectedEdge];
  Transpose @ {
    toOutTable[count, dir],
    toOutTable[count, Join[undir, Reverse[undir, 2]], 1]
  }
];

(**************************************************************************************************)

PackageExport["VertexOutAssociation"]
PackageExport["VertexInAssociation"]

SetUsage @ "
VertexOutAssociation[graph$] returns an association of lists <|v$1 -> out$1, v$2 -> out$2, $$|> \
where out$i is a list of the vertices that have a connection from v$i.
"

SetUsage @ "
VertexInAssociation[graph$] returns an association of lists <|v$1 -> in$1, v$2 -> in$2, $$|> \
where in$i is a list of the vertices that have a connection to v$i.
"

tableToAssoc[vertices_, table_] := Association @ MapIndexed[
  Part[vertices, First @ #2] -> Part[vertices, #1]&,
  table
];

VertexOutAssociation[graph_] :=
  tableToAssoc[VertexList @ graph, VertexOutTable @ vertices];

VertexInAssociation[graph_] :=
  tableToAssoc[VertexList @ graph, VertexInTable @ vertices];

(**************************************************************************************************)

PackageExport["VertexInOutAssociation"]

SetUsage @ "
VertexInOutAssociation[graph$] returns an association of lists <|v$1 -> {in$1, out$1}, v$2 -> {in$2, out$2}, $$|> \
where in$i is the list of indices of vertices that are have a connection to vertex i$, and out$i is the \
list of indices of vertices that have a connection from vertex i$.
"

VertexInOutAssociation[graph_] := Scope[
  vertices = VertexList[graph];
  Association @ MapIndexed[
    Part[vertices, First @ #2] -> {Part[vertices, First[#1]], Part[vertices, Last[#1]]}&,
    VertexInOutTable[graph]
  ]
];

(**************************************************************************************************)

PackageExport["InVertices"]
PackageExport["OutVertices"]
PackageExport["AllVertices"]
PackageExport["AllUniqueVertices"]

InVertices[edges_] := edges[[All, 1]];
OutVertices[edges_] := edges[[All, 2]];
AllVertices[edges_] := Join[InVertices @ edges, OutVertices @ edges];
AllUniqueVertices[edges_] := DeleteDuplicates @ AllVertices[edges];

(**************************************************************************************************)

PackageExport["GraphCorners"]

GraphCorners[graph_] := Scope[
  degree = DegreeCentrality[graph];
  vertices = Pick[VertexList[graph], degree, Min[degree]];
  SortBy[vertices, LatticeVertexAngle]
];

(**************************************************************************************************)

PackageExport["GraphVertexCoordinates"]

GraphVertexCoordinates[graph_Graph] :=
  GraphEmbedding[graph];

(**************************************************************************************************)

PackageScope["integersToVertices"]

integersToVertices[graph_Graph, expr_] :=
  integersToVertices[VertexList[graph], expr];

integersToVertices[vertices_List, expr_] :=
  expr /. {i:{__Integer} :> Part[vertices, i], i_Integer :> Part[vertices, i]};

(**************************************************************************************************)

PackageExport["ToGraph"]

SetUsage @ "
ToGraph[obj$] attempts to convert obj$ to a Graph[$$] object.
* If obj$ is already a Graph, it is returned unchanged.
* If obj$ is a list of rules, it is converted to a Graph object.
* Otherwise, $Failed is returned.
"

$edgeP = _DirectedEdge | _UndirectedEdge | _Rule | _TwoWayRule;

ToGraph = Case[
  g_Graph                 := g;
  list:{Repeated[$edgeP]} := Graph[list];
  _                       := $Failed
];

(**************************************************************************************************)

PackageExport["DeleteVertexAnnotations"]

DeleteVertexAnnotations[graph_Graph] :=
  AnnotationDelete[graph, VertexAnnotations];

DeleteVertexAnnotations[other_] := other;

(**************************************************************************************************)

PackageExport["LookupVertexAnnotations"]

LookupVertexAnnotations[graph_, key_, part_] :=
  Part[LookupVertexAnnotations[graph, key], part];

LookupVertexAnnotations[graph_, key_] :=
  Lookup[Replace[LookupAnnotation[graph, VertexAnnotations, None], None -> <||>], key, None];

LookupVertexAnnotations[graph_, All] :=
  Replace[LookupAnnotation[graph, VertexAnnotations, None], None -> <||>];

(**************************************************************************************************)

PackageExport["AttachVertexAnnotations"]

AttachVertexAnnotations[graph_, annotations_] := Scope[
  CheckIsGraph[1];
  joinAnnotation[graph, VertexAnnotations, annotations]
];

(**************************************************************************************************)

PackageExport["VertexAnnotationPresentQ"]

VertexAnnotationPresentQ[graph_, key_] :=
  KeyExistsQ[Replace[LookupAnnotation[graph, VertexAnnotations, None], None -> <||>], key]

(**************************************************************************************************)

PackageExport["DeleteEdgeAnnotations"]

DeleteEdgeAnnotations[graph_Graph] :=
  AnnotationDelete[graph, EdgeAnnotations];

DeleteEdgeAnnotations[other_] := other;

(**************************************************************************************************)

PackageExport["LookupEdgeAnnotations"]

LookupEdgeAnnotations[graph_, key_] :=
  Lookup[Replace[LookupAnnotation[graph, EdgeAnnotations, None], None -> <||>], key, None];

LookupEdgeAnnotations[graph_, All] :=
  Replace[LookupAnnotation[graph, EdgeAnnotations, None], None -> <||>];

(**************************************************************************************************)

PackageExport["AttachEdgeAnnotations"]

AttachEdgeAnnotations[graph_, annotations_] := Scope[
  CheckIsGraph[1];
  joinAnnotation[graph, EdgeAnnotations, annotations]
];

(**************************************************************************************************)

PackageExport["EdgeAnnotationPresentQ"]

EdgeAnnotationPresentQ[graph_, key_] :=
  KeyExistsQ[Replace[LookupAnnotation[graph, EdgeAnnotations, None], None -> <||>], key]

(**************************************************************************************************)

joinAnnotation[graph_, key_, newAnnotations_] := Scope[
  oldAnnotations = LookupAnnotation[graph, key, None];
  SetNone[oldAnnotations, <||>];
  Annotate[graph, key -> Join[oldAnnotations, newAnnotations]]
];

(**************************************************************************************************)

PackageExport["IndexGraphQ"]

IndexGraphQ[g_Graph ? GraphQ] :=
  RangeQ @ VertexList @ g;

IndexGraphQ[_] := False;

(**************************************************************************************************)

PackageExport["CanonicalizeEdges"]

CanonicalizeEdges[edges_] := Map[sortUE, edges];
sortUE[UndirectedEdge[a_, b_, tag___]] /; Order[a, b] === 1 := UndirectedEdge[b, a, tag];
sortUE[other_] := other;

(**************************************************************************************************)

PackageExport["ExtractGraphPrimitiveCoordinates"]

SetUsage @ "
ExtractGraphPrimitiveCoordinates[graph$] returns the pair {vcoords$, ecoords$}, where \
vcoords$ is a list of coordinate tuples in the same order as VertexList[graph$], and \
ecoords$ is a list of coordinate matrices in the same order as EdgeList[graph$].
"

ExtractGraphPrimitiveCoordinates::badvcoordrules = "VertexCoordinateRules is not a list of rules.";
ExtractGraphPrimitiveCoordinates::badvcoords = "Initial setting of VertexCoordinates is not a matrix of coordinates.";
ExtractGraphPrimitiveCoordinates::glayoutfail = "Failed to layout graph, using circle.";
ExtractGraphPrimitiveCoordinates::badctrans = "CoordinateTransformFunction produced invalid values, using circle.";

ExtractGraphPrimitiveCoordinates[graph_] := (*GraphCachedScope[graph, *) Scope[

  If[!GraphQ[graph], ReturnFailed[]];
  igraph = IndexEdgeTaggedGraph @ ToIndexGraph @ graph;
  If[!GraphQ[igraph], ReturnFailed[]];

  $Graph = graph;

  {graphLayout, vertexCoordinates} =
    LookupOption[igraph, {GraphLayout, VertexCoordinates}];

  UnpackExtendedOptions[graph,
    layoutDimension, extendedGraphLayout, viewOptions, coordinateTransformFunction,
    vertexCoordinateRules, vertexCoordinateFunction, selfLoopRadius, multiEdgeDistance
  ];
    
  actualDimension = Which[
    ContainsQ[graphLayout, "Dimension" -> 3] || CoordinateMatrixQ[vertexCoordinates, 3], 3,
    ContainsQ[graphLayout, "Dimension" -> 2] || CoordinateMatrixQ[vertexCoordinates, 2], 2,
    True, Automatic
  ];
  Which[
    actualDimension === layoutDimension === Automatic,
      actualDimension = 2,
    actualDimension === Automatic,
      actualDimension = layoutDimension,
    True,
      Null
  ];

  If[extendedGraphLayout =!= Automatic, graphLayout = extendedGraphLayout];
  SetAutomatic[graphLayout, {}];

  vertexList = VertexList @ graph;
  vertexCount = Length @ vertexList;
  vertexCoordinates = ConstantArray[0., {vertexCount, actualDimension}];

  edgeList = EdgeList @ igraph;
  edgeCount = Length @ edgeList;
  edgeCoordinateLists = ConstantArray[{}, edgeCount];

  If[UndirectedGraphQ[igraph] || MixedGraphQ[igraph],
    edgeList //= CanonicalizeEdges];

  isMulti = MultigraphQ[igraph];

  If[(isMulti || !DuplicateFreeQ[Sort /@ Take[edgeList, All, 2]]) && FreeQ[graphLayout, "MultiEdgeDistance" | "SpringElectricalEmbedding"],
    graphLayout = ToList[graphLayout, "MultiEdgeDistance" -> 2*multiEdgeDistance];
  ];

  initialVertexCoordinates = LookupOption[igraph, VertexCoordinates];

  method = Match[graphLayout, s_String | {s_String, ___} :> s, Automatic];
  autoLayout = Match[graphLayout, {s_String, opts___} :> {opts}, {___String, opts___} :> opts, Automatic];

  If[method === "Linear", method = If[AcyclicGraphQ[UndirectedGraph @ graph], "Line", "Circle"]];
  Switch[method,
    "Line",
      graphLayout = autoLayout;
      SetAutomatic[initialVertexCoordinates, N[{# - 1, 0}& /@ Range[vertexCount]]],
    "Circle",
      graphLayout = autoLayout;
      SetAutomatic[initialVertexCoordinates, N @ RotateRight[CirclePoints @ vertexCount, 1]],
    "LayeredDigraphEmbedding",
      graphLayout //= ReplaceAll[
        Rule["RootVertex", v_] :> Rule["RootVertex", IndexOf[vertexList, v]]
      ],
    "Random",
      graphLayout = autoLayout;
      SetAutomatic[initialVertexCoordinates, RandomReal[{-1, 1}, {vertexCount, actualDimension}]],
    "Tree" | "CenteredTree",
      graphLayout = {"LayeredDigraphEmbedding"};
      root = LookupExtendedOption[graph, GraphOrigin];
      If[root =!= None, AppendTo[graphLayout, "RootVertex" -> IndexOf[vertexList, root]]];
      If[method === "CenteredTree", coordinateTransformFunction = "CenterTree"];,
    s_String /; !StringEndsQ[s, "Embedding"],
      graphLayout //= ReplaceAll[method -> (method <> "Embedding")],
    True,
      Null
  ];

  Which[
    vertexCoordinateFunction =!= None,
      initialVertexCoordinates = Map[vertexCoordinateFunction, vertexList];
    ,
    vertexCoordinateRules === None,
      Null
    ,
    RuleListQ @ vertexCoordinateRules,
      AppendTo[vertexCoordinateRules, _ -> None];
      initialVertexCoordinates = Replace[vertexList, vertexCoordinateRules, {1}];
    ,
    True,
      Message[ExtractGraphPrimitiveCoordinates::badvcoordrules];
  ];

  If[ListQ @ initialVertexCoordinates,
    If[!CoordinateMatrixQ[initialVertexCoordinates],
      Message[ExtractGraphPrimitiveCoordinates::badvcoords];
      initialVertexCoordinates = Automatic;
    ,
      initialVertexCoordinates = nudgeOverlappingVertices[initialVertexCoordinates, LookupOption[graph, PlotRange]];
    ];
  ];

  newGraph = If[actualDimension == 3, Graph3D, Graph][
    Range @ vertexCount, edgeList,
    VertexShapeFunction -> captureVertexCoordinates,
    EdgeShapeFunction -> captureEdgeCoordinates,
    GraphLayout -> graphLayout,
    VertexCoordinates -> initialVertexCoordinates
  ];

  gdResult = Check[GraphComputation`GraphDrawing @ newGraph, $Failed];

  If[FailureQ[gdResult] || !MatrixQ[vertexCoordinates] || !VectorQ[edgeCoordinateLists, MatrixQ],
    Message[ExtractGraphPrimitiveCoordinates::glayoutfail];
    useFallbackLayout[];
    Goto[end];
  ];

  vertexCoordinates = ToPackedReal @ vertexCoordinates;
  correctSelfLoops[];

  If[UndirectedGraphQ[graph],
    edgeCoordinateLists = MapThread[orientEdgeCoords, {edgeCoordinateLists, edgeList}];
  ];

  applyCoordinateTransform[coordinateTransformFunction];
  If[!CoordinateMatrixQ[vertexCoordinates],
    Message[ExtractGraphPrimitiveCoordinates::badctrans];
    useFallbackLayout[];
    Goto[end];
  ];

  If[CoordinateMatrixQ[vertexCoordinates, 3] && layoutDimension == 2,
    SetAutomatic[viewOptions, $automaticViewOptions];
    viewOptions = Association[PlotRange -> CoordinateBounds[vertexCoordinates], viewOptions];
    viewTransform = ConstructGraphicsViewTransform[viewOptions];
    vertexCoordinates //= viewTransform;
    edgeCoordinateLists //= Map[viewTransform];
  ];

  Label[end];
  {ToPackedReal @ vertexCoordinates, ToPackedRealArrays @ edgeCoordinateLists}
];

orientEdgeCoords[coords_, _DirectedEdge] := coords;
orientEdgeCoords[coords_, UndirectedEdge[a_, b_, tag_]] := If[
  EuclideanDistance[
    First @ coords,
    Part[vertexCoordinates, Part[edgeList, tag, 1]]
  ] < 0.001,
  coords, Reverse @ coords
];

captureVertexCoordinates[coords_, vertex_, _] :=
  Part[vertexCoordinates, vertex] = coords;

captureEdgeCoordinates[coords_, edge_] :=
  Part[edgeCoordinateLists, Last @ edge] = coords;

useFallbackLayout[] := (
  vertexCoordinates = CirclePoints @ vertexCount;
  If[actualDimension === 3, vertexCoordinates //= AppendColumn @ Zeros @ vertexCount];
  edgeCoordinateLists = Part[vertexCoordinates, #]& /@ EdgePairs @ igraph;
)

correctSelfLoops[] := Scope[
  selfLoopIndices = SelectIndices[edgeCoordinateLists, selfLoopQ];
  If[selfLoopIndices === {}, Return[]];
  edgeCoordinateLists ^= MapIndices[fixSelfLoop, selfLoopIndices, edgeCoordinateLists];
];

selfLoopQ[coords_] := First[coords] == Last[coords];

(* fixSelfLoop[coords_] := Scope[
  terminus = First @ coords;
  mean = Mean @ coords;
  If[selfLoopRadius === Automatic,
    selfLoopRadius ^= EdgeLengthScale[edgeCoordinateLists, .5] / 4.0];
  radialVector = selfLoopRadius * Normalize[mean - terminus];
  center = terminus + radialVector;
  circlePoints = CirclePoints[center, {selfLoopRadius, ArcTan @@ (-radialVector)}, 16];
  AppendTo[circlePoints, First @ circlePoints];
  ToPackedReal @ Reverse @ circlePoints
]
 *)
fixSelfLoop[coords_] := Scope[
  terminus = First @ coords;
  If[selfLoopRadius === Automatic,
    selfLoopRadius ^= EdgeLengthScale[edgeCoordinateLists, .5] / 4.0];
  radialVector = selfLoopRadius * Normalize[mean - terminus];
  centeredCoords = PlusVector[coords, -terminus];
  scale = Norm @ Part[centeredCoords, Ceiling[Length[centeredCoords] / 2]];
  centeredCoords *= selfLoopRadius / (scale / 2);
  ToPackedReal @ PlusVector[centeredCoords, terminus]
]

(**************************************************************************************************)

PackageExport["LookupVertexCoordinates"]

LookupVertexCoordinates[graph_Graph, vertexList_:All] := Scope[
  UnpackExtendedOptions[graph,
    coordinateTransformFunction,
    vertexCoordinateRules, vertexCoordinateFunction
  ];

  $Graph = graph;
  SetAll[vertexList, VertexList @ graph];
  If[!ListQ[vertexList], ReturnFailed[]];

  coords = Which[
    coordinateTransformFunction =!= None || (vertexCoordinateRules === None && vertexCoordinateFunction === None),
      First @ ExtractGraphPrimitiveCoordinates @ graph
    ,
    RuleListQ @ vertexCoordinateRules,
      AppendTo[vertexCoordinateRules, _ -> None];
      Replace[vertexList, vertexCoordinateRules, {1}]
    ,
    vertexCoordinateFunction =!= None,
      Map[vertexCoordinateFunction, vertexList]
    ,
    True,
      ReturnFailed[];
  ];

  AssociationThread[vertexList, coords]
]

(**************************************************************************************************)

nudgeOverlappingVertices[coords_, plotRange_] := Scope[
  nudgedCoords = coords; num = Length[coords];
  nudgeScale = ChessboardDistance @@ If[
    CoordinateMatrixQ @ plotRange,
    Transpose @ plotRange,
    CoordinateBoundingBox @ coords
  ];
  nudgeScale = If[nudgeScale === 0, 1, Max[nudgeScale, 0.1]];
  dupPos = Select[Length[#] > 1&] @ PositionIndex[Round[coords, nudgeScale / 40]];
  If[Length[dupPos] === 0, Return @ coords];
  If[Length[dupPos] === 1 && num > 1,
    Return @ PlusVector[CirclePoints[{nudgeScale/5, Tau * .25/num}, num], Mean @ coords]];
  Scan[nudge, dupPos];
  nudgedCoords
];

nudge[{_}] := Null;
nudge[indices_] := 
  Part[nudgedCoords, indices] = Plus[
    Part[nudgedCoords, indices],
    nudgeScale/5 * CirclePoints[Length @ indices]
  ];

(**************************************************************************************************)

ExtendedGraphPlot::badwrappedshape = "CoordinateTransformFunction -> ProjectionOnto[...] contains an invalid shape.";
ExtendedGraphPlot::badcoordtrans = "CoordinateTransformFunction -> `` issued messages on application.";
ExtendedGraphPlot::badcoordtransname = "CoordinateTransformFunction -> `` is not one of ``."

applyCoordinateTransform[Automatic|None] :=
  Null

applyCoordinateTransform[list_List] :=
  Scan[applyCoordinateTransform, list];

applyCoordinateTransform[f_] := Block[{res},
  res = Check[
    vertexCoordinates = Map[f, vertexCoordinates];
    edgeCoordinateLists = Map[f, edgeCoordinateLists, {-2}];,
    $Failed
  ];
  If[FailureQ[res], Message[ExtendedGraphPlot::badcoordtrans, f]];
];

applyCoordinateTransform["CenterMean"] := Scope[
  center = Mean @ vertexCoordinates;
  applyCoordinateTransform[TranslationTransform[-center]];
];

applyCoordinateTransform["CenterBounds"] := Scope[
  center = Mean @ CoordinateBoundingBox @ {vertexCoordinates, edgeCoordinateLists};
  applyCoordinateTransform[TranslationTransform[-center]];
];

applyCoordinateTransform["Snap"] :=
  applyCoordinateTransform[{"Snap", 10}];

applyCoordinateTransform[{"Snap", m_, nudge_:0.1}] := Scope[
  applyCoordinateTransform["CenterMean"];
  bounds = CoordinateBounds[edgeCoordinateLists];
  step = (EuclideanDistance @@@ bounds) / m;
  grid = Flatten[CoordinateBoundsArray[bounds, step], 1];
  nearest = Nearest @ grid;
  applyCoordinateTransform[nearest /* First];
  duplicateIndices = DuplicateIndices @ vertexCoordinates;
  newVertexCoordinates = vertexCoordinates;
  adjacencyTable = VertexAdjacencyTable @ $Graph;
  $nudge = nudge;
  Scan[index |-> (
    center = Mean @ Part[vertexCoordinates, Part[adjacencyTable, index]];
    Part[newVertexCoordinates, index] //= nudgeDuplicate[center]),
    duplicateIndices, {2}];
  vertexCoordinates ^= newVertexCoordinates;
  edgeCoordinateLists ^= Part[vertexCoordinates, #]& /@ EdgePairs[$Graph];
];

nudgeDuplicate[z_][p_] := p + Normalize[Cross[z - p]] * Im[$nudge] + Normalize[z - p] * Re[$nudge];

DuplicateIndices[list_] :=
  Select[Length[#] > 1&] @ Values @ PositionIndex @ vertexCoordinates;

applyCoordinateTransform["CenterTree"] := Scope[
  horizontalGroups = GroupBy[vertexCoordinates, Round[Last @ #,.01]& -> First];
  left = Min @ horizontalGroups;
  horizontalOffsets = KeyValueMap[{#1, Mean[MinMax[#2]] - left}&, horizontalGroups];
  offsetFn = Interpolation[horizontalOffsets, InterpolationOrder -> 1];
  applyCoordinateTransform[{"HorizontalWarp", offsetFn}];
];

applyCoordinateTransform[{"HorizontalWarp", offsetFn_}] := (
  transFn = {x, y} |-> {x - offsetFn[y], y};
  vertexCoordinates = Apply[transFn, vertexCoordinates, {1}];
  edgeCoordinateLists = Apply[transFn, edgeCoordinateLists, {2}];
);

applyCoordinateTransform[{"Rotate", n_}] := (
  applyCoordinateTransform["CenterMean"];
  applyCoordinateTransform[RotationTransform[n * Degree]];
);

applyCoordinateTransform[{"Rotate", n_, p_}] :=
  applyCoordinateTransform[RotationTransform[n * Degree, p]];

applyCoordinateTransform[{"Radial", f_}] := Scope[
  applyCoordinateTransform["CenterMean"];
  applyCoordinateTransform[Normalize[#] * f[Norm[#]]&];
];

applyCoordinateTransform["PolarProjection"] :=
  applyCoordinateTransform[{"PolarProjection", 1}];

applyCoordinateTransform[{"PolarProjection", h_}] := Scope[
  applyCoordinateTransform["CenterMean"];
  applyCoordinateTransform[Apply[{x, y, z} |-> {x / (h-z), y/(h-z)}]];
];

$namedTransforms = <|
  "Rotate0" -> Identity,
  "Rotate90" -> RotationTransform[90 * Degree],
  "Rotate180" -> RotationTransform[180 * Degree],
  "Rotate270" -> RotationTransform[270 * Degree],
  "ReflectHorizontal" -> ReflectionTransform[{1, 0}],
  "ReflectVertical" -> ReflectionTransform[{0, 1}],
  "ShrinkHorizontal" -> ScalingTransform[{0.75, 1}],
  "ShrinkVertical" -> ScalingTransform[{1, 0.75}],
  "ExpandHorizontal" -> ScalingTransform[{1.25, 1}],
  "ExpandVertical" -> ScalingTransform[{1, 1.25}]
|>;

applyCoordinateTransform["BendVertical"] :=
  edgeCoordinateLists //= Map[bendVertical];

bendVertical[{a:{ax_, ay_}, b:{bx_, by_}}] := Scope[
  If[Min[Abs[ax - bx], Abs[ay - by]] < 0.001, Return @ {a, b}];
  c = {bx, ay};
  ca = along[c, a, .25];
  cb = along[c, b, .25];
  Join[{a}, DiscretizeCurve[{ca, c, cb}], {b}]
];

bendVertical[line_] := line;

applyCoordinateTransform["SquareSelfLoops"] :=
  edgeCoordinateLists //= Map[squareSelfLoop];

squareSelfLoop[list:{a_, Repeated[_, {3, Infinity}], b_}] /; EuclideanDistance[a, b] < 0.01 := Scope[
  c = Mean @ list;
  {p1, p3} = {{xl, yl}, {xh, yh}} = CoordinateBoundingBox @ list;
  p2 = {xh, yl}; p4 = {xl, yh};
  ang = ArcTan @@ (a - c); ang *= 2/Pi;
  (* p4 p3
     p1 p2 *)
  {u, v, w, x} = Which[
    -0.5 <= ang < +0.5, (* E *) {p3, p4, p1, p2},
    +0.5 <= ang < +1.5, (* N *) {p4, p1, p2, p3},
    -1.5 <= ang < -0.5, (* S *) {p2, p3, p4, p1},
    True,               (* W *) {p1, p2, p3, p4}
  ];
  trunc = 0.5;
  v = (v * trunc + u * (1 - trunc));
  w = (w * trunc + x * (1 - trunc));
  DiscretizeCurve[{corner[a, u, v], corner[u, v, w], corner[v, w, x], corner[w, x, a], a}, BSplineCurve]
];

$cr = .1;
corner[a_, b_, c_] :=
  Splice @ {a, along[b, a, $cr], along[b, a, 0.8*$cr], b, along[b, c, 0.8*$cr], along[b, c, $cr]};

along[a_, b_, d_] := PointAlongLine[{a, b}, d];

squareSelfLoop[line_] := line;

applyCoordinateTransform[name_String] := Scope[
  trans = Lookup[$namedTransforms, name,
    Message[ExtendedGraphPlot::badcoordtransname, name, commaString @ Keys @ $namedTransforms];
    $Failed
  ];
  If[FailureQ[trans], ReturnFailed[]];
  applyCoordinateTransform @ trans
];

applyCoordinateTransform[ProjectionOnto[shape_]] := Block[{$rnf},
  $rnf = BoundaryProjection @ shape;
  If[FailureQ[$rnf], Message[ExtendedGraphPlot::badwrappedshape]; Return @ $Failed];
  vertexCoordinates //= $rnf;
  edgeCoordinateLists //= Map[projectLineOntoRNF];
];

projectLineOntoRNF = Case[
  {a_, b_} ? CoordinateMatrixQ /; (Head[$rnf] === RegionNearestFunction) :=
    $rnf @ Interpolated[a, b, 6];
  points_List ? CoordinateMatrixQ :=
    $rnf @ points;
  points_List := Print[points]; (* projectLineOntoRNF /@ points; *)
];


(**************************************************************************************************)

PackageExport["ToSymmetricGraph"]

ToSymmetricGraph[graph_ ? DirectedGraphQ] :=
  Graph[VertexList @ graph, EdgeList[graph] /. DirectedEdge -> UndirectedEdge];

ToSymmetricGraph[graph_] := graph;

(**************************************************************************************************)

PackageScope["GraphScope"]

PackageScope["NotInGraphScopeOfQ"]

NotInGraphScopeOfQ[graph_] := !GraphQ[$Graph] || (graph =!= $Graph)

PackageScope["$Graph"]
PackageScope["$GraphOrigin"]
PackageScope["$VertexList"]
PackageScope["$EdgeList"]
PackageScope["$EdgeTags"]
PackageScope["$VertexIndex"]
PackageScope["$VertexCount"]
PackageScope["$EdgeCount"]

PackageScope["$IndexGraph"]
PackageScope["$IndexGraphEdgeList"]

PackageScope["$MetricGraphCache"]
PackageScope["$GraphMetric"]

SetAttributes[GraphScope, HoldRest];

SetUsage @ "
GraphScope[graph$, body$] sets up some dynamically scoped variables that make it easy to
access properties and computed results from a single graph.
The following variables are blocked during the execution of GraphScope:
| $Graph | graph$ |
| $VertexList | VertexList[graph$] |
| $EdgeList | EdgeList[graph$] |
| $EdgeTags | EdgeTags[graph$] |
| $VertexIndex | VertexIndexAssociation[graph$] |
| $VertexCount | VertexCount[$graph] |
| $EdgeCount | EdgeCount[$graph] |
| $IndexGraph | IndexGraph[graph$] |
| $IndexGraphEdgeList | EdgeList[$IndexGraph] |
| $MetricGraphCache | GraphCache[$$] object for a symmetric version of the index graph |
| $GraphMetric | the current graph metric |
* All of the expensive properties are computed (and then cached) on first use.
"

GraphScope[graph_, body_] := Block[
  {
    $Graph = graph,
    $GraphOrigin := $GraphOrigin = LookupExtendedOption[$Graph, GraphOrigin],
    $VertexList := $VertexList = VertexList @ $Graph,
    $EdgeList := $EdgeList = EdgeList @ $Graph,
    $EdgeTags := $EdgeTags = Replace[EdgeTags @ $Graph, {} -> None],
    $VertexIndex := $VertexIndex = VertexIndexAssociation @ $Graph,
    $VertexCount = VertexCount @ $Graph,
    $EdgeCount = EdgeCount @ $Graph,

    $IndexGraph := $IndexGraph = ToIndexGraph @ $Graph,
    $IndexGraphEdgeList := $IndexGraphEdgeList = EdgeList @ $IndexGraph,

    $metricGraphCacheSymbol = Null,
    $MetricGraphCache := $MetricGraphCache = createMetricGraphCache[],
    $GraphMetric = Inherited
  },
  body
];

createMetricGraphCache[] := CreateGraphCache[
  Annotate[ToSymmetricGraph @ $IndexGraph, GraphMetric -> LookupAnnotation[$Graph, GraphMetric, Automatic]],
  $metricGraphCacheSymbol
];

(**************************************************************************************************)

PackageExport["DeleteCardinal"]

DeleteCardinal[graph_, card_] := Scope[
  opts = Options[graph];
  {vertices, edges} = VertexEdgeList[graph];
  edges //= Map[deleteCard[card | Negated[card]]];
  cardinals = AnnotationValue[graph, Cardinals];
  res = Graph[vertices, edges, opts];
  If[ListQ[cardinals], res = Annotate[res, Cardinals -> DeleteCases[cardinals, card]]];
  res
];

deleteCard[c_][head_[a_, b_, t_]] /; MatchQ[t, c] := Nothing;

deleteCard[c_][head_[a_, b_, CardinalSet[l_List /; MemberQ[l, c]]]] :=
  head[a, b, SimplifyCardinalSet @ CardinalSet @ DeleteCases[l, c]];

deleteCard[c_][other_] := other;

(**************************************************************************************************)

PackageExport["FindAllUndirectedSpanningEdgeSets"]

(* this is O(n!) in the number of vertices, so not practical for all but small graphs,
but at least we don't have to rewrite FindSpanningTree *)

FindAllUndirectedSpanningEdgeSets[graph_] := Scope[
  {vertices, edges} = VertexEdgeList @ graph;
  vertices = VertexList @ graph;
  igraph = ToUndirectedEdgeIndexGraph @ graph;
  {ivertices, iedges} = VertexEdgeList @ igraph;
  perms = Permutations @ ivertices;
  spanningEdgeSets = DeleteDuplicates @ Map[
    Sort[findSpanningEdgeTags[#, iedges]]&,
    perms
  ]
];

(*
  Graph[vertices, Part[edges, #], opts]& /@ skeletonIndices
]
*)
ToUndirectedEdgeIndexGraph[graph_] := Scope[
  {vertices, edges} = VertexEdgeList @ IndexGraph[graph];
  i = 1; Graph[vertices, UndirectedEdge[#1, #2, i++]& @@@ edges]
];

findSpanningEdgeTags[vertices_, edgeList_] :=
  Part[EdgeList[FindSpanningTree[Graph[vertices, edgeList]]], All, 3];

(**************************************************************************************************)

FindAllDirectedTrees[graph_] := Scope[
  {vertices, edges} = VertexEdgeList @ graph;
];

(**************************************************************************************************)

PackageExport["ExtractExtendedGraphOptions"]

ExtractExtendedGraphOptions[graph_Graph] := Scope[
  opts = Options @ graph;
  annoRules = Lookup[opts, AnnotationRules, {}];
  graphProps = Lookup[annoRules, "GraphProperties", {}];
  Join[DeleteOptions[opts, AnnotationRules], graphProps]
]