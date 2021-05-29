PackageExport["RegionSubgraph"]

SetUsage @ "
RegionSubgraph[graph$, region$] gives a subgraph of graph$ described by region$, which can be one or more of the following:
<*$graphRegionTable*>
"

RegionSubgraph::empty = "The specified region is empty."

DeclareArgumentCount[RegionSubgraph, 2];

declareSyntaxInfo[RegionSubgraph, {_, _, OptionsPattern[]}];

RegionSubgraph[graph_, region_] := Scope[
  graph = CoerceToGraph[1];
  regionData = GraphScope[graph, RegionDataUnion @ processRegionSpec @ region];
  If[FailureQ[result], ReturnFailed[]];
  vertices = Part[regionData, 1];
  edges = Part[regionData, 2];
  If[vertices === edges === {}, ReturnFailed["empty"]];
  vertices = DeleteDuplicates @ Join[vertices, AllVertices @ edges];
  ExtendedSubgraph[graph, vertices, edges]
];

(**************************************************************************************************)

PackageExport["GraphRegion"]

SetUsage @ "
GraphRegion[graph$, region$] returns a list of %GraphRegionData and %GraphPathData objects, representing \
the computed regions of graph$.
<*$graphRegionTable*>
"

GraphRegion[graph_, region_] := Scope[
  graph = CoerceToGraph[1];
  GraphScope[graph, processRegionSpec @ region]
]

(**************************************************************************************************)

PackageExport["GraphRegionCollection"]

SetUsage @ "
GraphRegionCollection[<|name$1 -> region$1, $$|>] represents a collection of named regions.
"

PackageExport["GraphRegionData"]

SetUsage @ "
GraphRegionData[vertices$, edges$] represents a region in a graph with vertex indices vertices$ \
and edge indices edges$.
"

PackageExport["GraphPathData"]

SetUsage @ "
GraphPathData[vertices$, edges$, negations$] represents a path in a graph with vertex indices \
vertices$, edge indices edges$, and a list of indices into edges$ of which edges were traversed \
in their reverse direction.
"

PackageExport["GraphRegionAnnotation"]

SetUsage @ "
GraphRegionAnnotation[data$, anno$] is a wrapper around %GraphPathData and %GraphRegionData \
that attaches additional annotations anno$ for interpretation by GraphRegionHighlights etc.
"

$boxColor = GrayLevel[0.9];
declareBoxFormatting[
  g:GraphRegionData[v:{___Integer}, e:{___Integer}] :>
    Construct[InterpretationBox, skeletonBox["GraphRegionData", $boxColor, Length /@ {v, e}], g],
  GraphPathData[v:{__Integer}, e:{___Integer}, c:{___Integer}] :>
    Construct[InterpretationBox, skeletonBox["GraphPathData", $boxColor, Length /@ {v, e, c}], g]
];

colorBox[box_, color_] := StyleBox[box, Background -> color];

PackageScope["skeletonBox"]

skeletonBox[head_, color_, args_] :=
  RowBox @ Flatten @ {head, "[", Riffle[colorBox[skeletonString @ #, color]& /@ args, ","], "]"};

skeletonString[e_] := StringJoin["\[LeftAngleBracket]", TextString @ e, "\[RightAngleBracket]"];

regionDataListVertices[regionDataElements_] :=
  regionDataElements[[All, 1]];

regionDataListEdges[regionDataElements_] :=
  regionDataElements[[All, 2]];

pathToRegion[GraphPathData[a_, b_, c_]] :=
  GraphRegionData[a, b];

(**************************************************************************************************)

PackageExport["TakePath"]

TakePath[GraphPathData[v_, e_, c_], n_] := Scope[
  v2 = Take[v, n]; e2 = Take[e, n];
  c2 = Take[SparseArray[Thread[c -> 1], Length @ e], n]["NonzeroPositions"] // Flatten;
  GraphPathData[v2, e2, c2]
];

(**************************************************************************************************)

PackageExport["GraphRegionElementQ"]

SetUsage @ "
GraphRegionElementQ[elem$] returns True if elem$ is an expression describing a graph region.
"

(**************************************************************************************************)

PackageExport["VertexPattern"]
PackageExport["EdgePattern"]

SetUsage @ "
VertexPattern[pattern$] represent a vertex that matches pattern$.
"

SetUsage @ "
EdgePattern[src$, dst$] represents an edge that matches src$ \[DirectedEdge] dst$.
"

(* zSetUsage @ "
Path[src$, {c$1, $$, c$n}] represents a path starting at src$ and taking cardinals c$i in tern.
Path[src$, 'cards$'] interpreted the characters of 'cards$' as cardinals.
"
 *)
(**************************************************************************************************)

PackageScope["processRegionSpec"]

processRegionSpec[region_] := Scope[
  $VertexInEdgeTable := $VertexInEdgeTable = VertexInEdgeTable[$Graph];
  $VertexOutEdgeTable := $VertexOutEdgeTable = VertexOutEdgeTable[$Graph];
  $VertexAdjacencyTable := $VertexAdjacencyTable = VertexAdjacencyTable[$Graph];
  $TagVertexAdjacentEdgeTable := $TagVertexAdjacentEdgeTable = TagVertexAdjacentEdgeTable[$Graph];
  $EdgePairs := $EdgePairs = EdgePairs[$Graph];
  $Cardinals := $Cardinals = CardinalList[$Graph];
  Map[outerProcessRegion, ToList @ region]
]

outerProcessRegion[region_] := Scope[
  $currentRegionHead = Head[region];
  Catch[processRegion[region], outerProcessRegion]
];

(********************************************)
(** framework code                         **)
(********************************************)

failAuto[msgName_, args___] := (
  Message[MessageName[GraphRegion, msgName], $currentRegionHead, args];
  Throw[Nothing, outerProcessRegion]
);

fail[msgName_, args___] := (
  Message[MessageName[GraphRegion, msgName], args];
  Throw[Nothing, outerProcessRegion]
);

(********************************************)

SetHoldFirst[collectRegionData, collectPathData];

collectPathData[body_] := Scope[
  CollectTo[{$vertexBag, $edgeBag, $negationBag}, body];
  GraphPathData[$vertexBag, $edgeBag, $negationBag]
];

(********************************************)

sowVertex[v_] := Internal`StuffBag[$vertexBag, v];

sowVertexList[v_] := Internal`StuffBag[$vertexBag, v, 1];

sowEdge[i_Integer] := (Internal`StuffBag[$edgeBag, i]; True);

sowEdge[Negated[i_Integer]] := (
  Internal`StuffBag[$edgeBag, i];
  Internal`StuffBag[$negationBag, Internal`BagLength[$edgeBag]];
  True
);

sowEdge[_] := False;

sowEdgeList[i_List] := Internal`StuffBag[$edgeBag, i, 1];

(********************************************)

SetHoldRest[findStrictEdge];
findStrictEdge[v1_, v2_, else_:None] := First[
  Intersection[
    Part[$VertexInEdgeTable, v2],
    Part[$VertexOutEdgeTable, v1]
  ],
  else
];

(********************************************)

findEdge[v1_, v2_] := findStrictEdge[v1, v2, Negated @ findStrictEdge[v2, v1]]

findAndSowEdge[v1_, v2_] := sowEdge @ findEdge[v1, v2];

(********************************************)

GraphRegion::nfvertex = "No vertex matching `` was found in the graph."
GraphRegion::nfedge = "No edge matching `` was found in the graph.";
GraphRegion::malformedrspec = "The region specification `` was malformed.";


(********************************************)
(** literal vertices and edges             **)

$regionHeads = Alternatives[
  Disk, Circle, Annulus, Line, HalfLine, InfiniteLine, Path, StarPolygon, Polygon,
  EdgePattern, VertexPattern,
  RegionComplement, RegionUnion, RegionIntersection
];

processRegion[spec_] := If[MatchQ[Head @ spec, $regionHeads],
  fail["malformedrspec", spec],
  GraphRegionData[{findVertex @ spec}, {}]
];

(********************************************)
(** edge pattern                           **)

processRegion[assoc_Association] :=
  NamedGraphRegionData @ Map[processRegion, assoc];

(********************************************)

GraphRegionElementQ[e:_[___, GraphMetric -> _]] := GraphRegionElementQ @ Most @ e;
GraphRegionElementQ[_Rule | _TwoWayRule | _DirectedEdge | _UndirectedEdge] := True;

processRegion[spec:((Rule|TwoWayRule|DirectedEdge|UndirectedEdge)[l_, r_])] := Scope[
  e = findEdge[findVertex @ l, findVertex @ r];
  If[!IntegerQ[e], fail["nfedge", spec]];
  edgeIndicesToPathData @ {e}
];

processRegion[DirectedEdge[a_, b_, c_]] :=
  edgeIndicesToPathData @ findEdgeIndices @ verbatimEdgePattern[a, b, c]

processRegion[UndirectedEdge[a_, b_, c_]] :=
  edgeIndicesToPathData @ StripNegated @ findEdgeIndices @ verbatimEdgePattern[a, b, c]

verbatimEdgePattern[a_, b_, c_] :=
  Verbatim /@ EdgePattern[a, b, c];

(********************************************)
(** edge pattern                           **)

GraphRegionElementQ[EdgePattern[_, __]] := True;

processRegion[p:EdgePattern[___]] :=
  edgeIndicesToPathData @ findEdgeIndices[p]

processRegion[EdgePattern[a_, b_, Negated[c_]]] :=
  edgeIndicesToPathData @ findEdgeIndices @ Map[Negated, EdgePattern[a, b, c]];

findEdgeIndices[p:EdgePattern[a_, b_, c___]] := Scope[
  Which[
    NotEmptyQ[i = MatchIndices[$EdgeList, DirectedEdge[a, b, c]]],
      i,
    NotEmptyQ[i = MatchIndices[$EdgeList, DirectedEdge[b, a, c]]],
      Negated /@ i,
    NotEmptyQ[i = MatchIndices[$EdgeList, UndirectedEdge[a, b, c] | UndirectedEdge[b, a, c]]],
      i,
    True,
      fail["nfedge", p]
  ]
];

edgeIndicesToPathData[indices_] :=
  GraphPathData[
    Union @ AllVertices @ Part[$IndexGraphEdgeList, indices],
    StripNegated /@ indices,
    MatchIndices[indices, _Negated]
  ]


(********************************************)
(** Point                                  **)

GraphRegionElementQ[Point[_]] := True;

processRegion[Point[v_]] :=
  GraphRegionData[List @ findVertex @ v, {}];


(********************************************)
(** vertex pattern                         **)

GraphRegionElementQ[VertexPattern[_]] := True;

vertexPatternQ[v_] := ContainsQ[v, Pattern | Alternatives | Blank];

processRegion[lv_LatticeVertex ? vertexPatternQ] :=
  processRegion @ VertexPattern @ lv;

processRegion[p:VertexPattern[v_]] := Scope[
  indices = MatchIndices[$VertexList, v];
  If[indices === {}, fail["nfvertex", p]];
  GraphRegionData[indices, {}]
];


(********************************************)
(** complex region specifications          **)
(********************************************)

processRegion[list_List /; VectorQ[list, GraphRegionElementQ]] :=
  RegionDataUnion @ Map[processRegion, list];

(********************************************)

GraphRegion::invv = "The region ``[...] contained an invalid vertex specification ``.";

findVertex[GraphOrigin] := 1;

findVertex[RandomPoint] := RandomInteger[{1, $VertexCount}];

findVertex[Offset[v_, path_]] := offsetWalk[findVertex[v], path];

findVertex[spec_] := Lookup[$VertexIndex, Key[spec],
  failAuto["invv", spec]];

findVertex[lv_LatticeVertex ? vertexPatternQ] :=
  findVertex @ VertexPattern @ lv;

findVertex[p:VertexPattern[v_]] :=
  FirstIndex[$VertexList, v, failAuto["invv", p]];

GraphRegion::notlist = "The region ``[...] required a list of vertices, but got `` instead."

findVertices[spec_] := Scope[
  res = Lookup[$VertexIndex, spec, $Failed];
  If[FreeQ[res, $Failed], res, resolveComplexVertexList @ spec]
];

resolveComplexVertexList[spec_] := Which[
  vertexPatternQ[spec], MatchIndices[$VertexList, spec],
  ListQ[spec] && !EmptyQ[spec], Map[findVertex, spec],
  True, failAuto["notlist", spec]
];

(********************************************)
(** GraphRegionData|GraphPathData[...]     **)

GraphRegionElementQ[GraphRegionData[_List, _List]] := True;
GraphRegionElementQ[GraphPathData[_List, _List, _List]] := True;

processRegion[g_GraphRegionData] := g;
processRegion[g_GraphPathData] := g;

(********************************************)

$metricRegionHeads = Alternatives[
  Line, Disk, Annulus, Circle, HalfLine, InfiniteLine, Polygon, StarPolygon, Path
];

processRegion[spec:$metricRegionHeads[__, GraphMetric -> metric_]] := Scope[
  $GraphMetric = metric;
  processRegion @ Most @ spec
];

(********************************************)
(** Path[...]                              **)

GraphRegionElementQ[Path[_, _]] := True;
GraphRegionElementQ[Path[_, _, PathAdjustments -> _]] := True;

processRegion[Path[start_, path_]] :=
  collectPathData @ sowPath[start, path, False];

processRegion[Path[args__, ps:Rule[PathAdjustments, _]]] :=
  GraphRegionAnnotation[processRegion @ Path @ args, Association @ ps];

PackageExport["PathAdjustments"]

SetUsage @ "
PathAdjustments is an option to Path that specifies which steps to foreshorten.
"

(********************************************)

sowPath[start_, path_, repeating_] := Scope[
  startId = findVertex @ start;
  pathWord = ParseCardinalWord[path];
  sowVertex[startId];
  doWalk[
    startId, pathWord, repeating,
    {vertex, edge} |-> (
      sowVertex[vertex];
      sowEdge[edge];
    )
  ];
];

(********************************************)

PackageExport["FormatCardinalWord"]

FormatCardinalWord[w_] :=
  Style[Row @ ParseCardinalWord[w], $LegendLabelStyle];

(********************************************)

PackageExport["ParseCardinalWord"]

ParseCardinalWord[path_String] /; StringLength[path] > 1 := Scope[
  chars = Characters[path];
  str = StringReplace[StringRiffle[chars, " "], " '" -> "'"];
  Map[
    If[StringMatchQ[#, _ ~~ "'"], Negated @ StringTake[#, 1], #]&,
    StringSplit[str]
  ] // checkCardinals
];

ParseCardinalWord[elem_] := checkCardinals @ List @ elem;

ParseCardinalWord[list_List] := checkCardinals @ list;

GraphRegion::badcardinals = "The region ``[...] includes a path `` with invalid cardinals."
checkCardinals[list_List] :=
  If[!ListQ[$Cardinals] || SubsetQ[$Cardinals, StripNegated /@ list], list,
    failAuto["badcardinals", list]];

(********************************************)

GraphRegion::notdir = "The region ``[...] includes a path ``, but paths cannot be defined on undirected graphs."

GraphRegion::nocard = "The region ``[...] specified a cardinal '``' path step at vertex ``, but the only available \
cardinals are: ``"

doWalk[startId_, pathWord_, shouldRepeat_, func_] := Scope[
  If[!DirectedGraphQ[$Graph], failAuto["notdir", path]];
  wordLen = Length @ pathWord;
  vertexId = startId;
  totalLen = If[shouldRepeat, 10^6, wordLen];
  Do[
    cardinal = Part[pathWord, Mod[i, wordLen, 1]];
    negatedQ = NegatedQ[cardinal];
    edgeId = Part[$TagVertexAdjacentEdgeTable, Key @ cardinal, vertexId];
    If[edgeId === None,
      If[shouldRepeat, Break[]];
      failWalk[cardinal, vertexId]];
    vertexId = Part[$EdgePairs, edgeId, If[negatedQ, 1, 2]];
    func[vertexId, If[negatedQ, Negated @ edgeId, edgeId]];
    If[vertexId == startId && shouldRepeat, Break[]];
  ,
    {i, 1, totalLen}
  ];
  vertexId
];

failWalk[cardinal_, vertexId_] := Scope[
  available = Join[
    Part[$EdgeTags, Part[$VertexOutEdgeTable, vertexId]],
    Negated /@ Part[$EdgeTags, Part[$VertexInEdgeTable, vertexId]]
  ];
  failAuto["nocard", cardinal, Part[$VertexList, vertexId], available];
];

(********************************************)

offsetWalk[start_, path_] := Scope[
  cardList = ParseCardinalWord[path];
  doWalk[startId, pathWord, False, Null&]
];

(********************************************)
(** Line[...]                              **)

GraphRegionElementQ[Line[_]] := True;

processRegion[Line[{vertex_}]] :=
  collectPathData @ sowVertex @ findVertex @ vertex;

processRegion[Line[vertices_]] :=
  collectPathData @ MapStaggered[findAndSowGeodesic, findVertices @ vertices]

findAndSowGeodesic[v1_, v2_] := Scope[
  geodesicVertices = MetricFindShortestPath[$MetricGraphCache, v1, v2, GraphMetric -> $GraphMetric];
  sowVertexList[geodesicVertices];
  MapStaggered[findAndSowEdge, geodesicVertices]
];


(********************************************)
(** HalfLine[...]                              **)

GraphRegionElementQ[HalfLine[{_, _}] | HalfLine[_, _]] := True;

(* we must work around an automatic rewriting that HalfLine does here *)
processRegion[HalfLine[{v1_, v2_}] | HalfLine[{0, 0}, {v1_, v2_}]] := Scope[
  v1 //= findVertex; v2 //= findVertex;
  word = findWordBetween[v1, v2];
  processRegion @ HalfLine[v1, word]
];

processRegion[HalfLine[v_, dir_]] :=
  collectPathData @ sowPath[v, dir, True];

processRegion[hf_HalfLine] := Print[hf];

findWordBetween[v1_, v2_] := Scope[
  geodesicVertices = MetricFindShortestPath[$MetricGraphCache, v1, v2, GraphMetric -> $GraphMetric];
  MapStaggered[findCardinalBetween, geodesicVertices]
];

GraphRegion::grinterror = "An internal error occurred while procession region ``[...].";

findCardinalBetween[v1_, v2_] := Scope[
  edgeIndex = findEdge[v1, v2];
  If[edgeIndex === None, failAuto["grinterror"]];
  If[NegatedQ[edgeIndex],
    Negated @ Part[$EdgeTags, StripNegated @ edgeIndex],
    Part[$EdgeTags, edgeIndex]
  ]
];

(********************************************)
(** InfiniteLine[...]                      **)

GraphRegionElementQ[InfiniteLine[{_, _}] | InfiniteLine[_, _]] := True;

processRegion[InfiniteLine[v_, dir_]] := Scope[
  cardinalWord = ParseCardinalWord[dir];
  {posVerts, posEdges, posNegations} = List @@ processRegion @ HalfLine[v, cardinalWord];
  {negVerts, negEdges, negNegations} = List @@ processRegion @ HalfLine[v, Negated /@ Reverse @ cardinalWord];
  negEdgeLen = Length[negEdges];
  GraphPathData[
    Join[Reverse @ Rest @ negVerts, posVerts],
    Join[Reverse @ negEdges, posEdges],
    Join[Complement[Range @ negEdgeLen, negEdgeLen + 1 - negNegations], negEdgeLen + posNegations]
  ]
];

(********************************************)
(** Polygon[...]                           **)

GraphRegionElementQ[Polygon[_List]] := True;

processRegion[Polygon[vertices_]] := Scope[
  vertices = findVertices @ vertices;
  collectPathData[
    findAndSowGeodesic @@@ Partition[vertices, 2, 1, 1]
  ]
];


(********************************************)
(** StarPolygon[...]                       **)

PackageExport["StarPolygon"]

SetUsage @ "
StarPolygon[vertices$] represents a polygon that connects all vertices$ \
with geodesics.
"

GraphRegionElementQ[StarPolygon[_List]] := True;

(* this needs to find *all* paths of equal length between the vertices *)
processRegion[StarPolygon[vertices_]] := Scope[
  vertices = findVertices @ vertices;
  collectPathData[
    findAndSowGeodesic @@@ Tuples[vertices, {2}]
  ]
];


(********************************************)
(** Locus[...]                             **)

PackageExport["Locus"]

SetUsage @ "
Locus[r$1, r$2] represents the locus of points that are equally distance from \
regions r$1 and r$2.
Locus[r$1, r$2, \[CapitalDelta]] represents a 'thickened' locus that allows the \
two distances to differ by up to \[CapitalDelta].
"

GraphRegionElementQ[Locus[_ ? GraphRegionElementQ, _ ? GraphRegionElementQ]] := True;
GraphRegionElementQ[Locus[_ ? GraphRegionElementQ, _ ? GraphRegionElementQ, (_ ? NumericQ) | "Polar"]] := True;

processRegion[Locus[r1_, r2_, "Polar"]] :=
  processRegion[Locus[r1, r2, -1]];

processRegion[l:Locus[r1_, r2_, d_:0 ? NumericQ]] := Scope[
  r1 = First @ processRegion @ r1;
  r2 = First @ processRegion @ r2;
  If[r1 === {} || r2 === {}, fail["emptyarea", l]];
  d1 = extractDistanceToRegion @ r1;
  d2 = extractDistanceToRegion @ r2;
  isPolar = d === -1; d = Max[d, 0];
  indices = SelectIndices[
    Transpose @ {d1, d2},
    Apply[Abs[#1 - #2] <= d&]
  ];
  If[isPolar,
    d3 = d1 - d2;
    indices1 = SelectIndices[d3, Positive];
    indices2 = SelectIndices[d3, Negative];
    indices = Union[
      indices,
      Select[indices1, IntersectingQ[Part[$VertexAdjacencyTable, #], indices2]&]
    ];
(*     subgraphRegionData[indices];
    Return[GraphRegionData[indices, {}]];
 *)  ];
  If[indices === {}, fail["emptyarea", l]];
  subgraphRegionData[indices]
];

(*
(* this appears to be slower! *)
extractDistanceToRegion[{v_}] :=
  MetricDistance[$MetricGraphCache, v, All, GraphMetric -> $GraphMetric];
*)
extractDistanceToRegion[v_List] :=
  Min /@ Part[MetricDistanceMatrix[$MetricGraphCache, GraphMetric -> $GraphMetric], All, v];

(********************************************)
(** Disk[...]                              **)

GraphRegionElementQ[Disk[_, _ ? NumericQ]] := True;

processRegion[d:Disk[center_, r_ ? NumericQ]] :=
  circularRegionData[d, center, LessEqualThan[r]];


(********************************************)
(** Annulus[...]                           **)

GraphRegionElementQ[Annulus[_, {_ ? NumericQ, _ ? NumericQ}]] := True;

processRegion[a:Annulus[center_, {r1_ ? NumericQ, r2_ ? NumericQ}]] :=
  circularRegionData[a, center, Between[{r1, r2}]];


(********************************************)
(** Circle[...]                            **)

GraphRegionElementQ[Circle[_, _ ? NumericQ]] := True;

processRegion[c:Circle[center_, r_ ? NumericQ]] :=
  circularRegionData[c, center, ApproxEqualTo[r]];

ApproxEqualTo[e_][r_] := Abs[e - r] < 0.5;

(********************************************)

GraphRegion::emptyarea = "The area defined by `` contains no points."

extendedConditionQ[cond_] := ContainsComplexQ[cond] || ContainsNegativeQ[cond];

complexToVector[z_] := AngleVector @ AbsArg @ z;

leftOf[z_][e_] := Dot[z - e, z] >= 0;
rightOf[z_][e_] := Dot[z - e, z] <= 0;
andOperator[f_, g_][e_] := f[e] && g[e];

toComplexCond = MatchValues[
  LessEqualThan[n_] := leftOf @ complexToVector @ n;
  ApproxEqualTo[n_] := ApproxEqualTo[complexToVector @ n];
  Between[{a_, b_}] := andOperator[leftOf @ complexToVector @ a, rightOf @ complexToVector @ b];
];

circularRegionData[spec_, center_, condition_] := Scope[
  centerInd = findVertex @ center;
  distances = MetricDistance[$MetricGraphCache, centerInd, All, GraphMetric -> $GraphMetric];
  cond = condition;
  Which[
    ContainsComplexQ[distances] && !extendedConditionQ[cond],
      distances //= Re,
    extendedConditionQ[cond],
      cond //= toComplexCond;
      distances //=  Map[complexToVector],
    True,
      Null
  ];
  vertices = SelectIndices[distances, cond];
  If[vertices === {}, fail["emptyarea", spec]];
  subgraphRegionData @ vertices
];

subgraphRegionData[vertices_] := Scope[
  forward = Flatten @ Part[$VertexOutEdgeTable, vertices];
  backward = Flatten @ Part[$VertexInEdgeTable, vertices];
  candidates = Intersection[forward, backward];
  vertexAssoc = ConstantAssociation[vertices, True];
  edges = Select[candidates, Apply[And, Lookup[vertexAssoc, Part[$EdgePairs, #]]]&];
  GraphRegionData[
    vertices,
    edges
  ]
];

(********************************************)
(** RegionBoundary[...]                    **)

GraphRegionElementQ[RegionBoundary[_]] := True;

processRegion[RegionBoundary[region_]] := Scope[
  vertices = First @ processRegion @ region;
  complement = Complement[Range @ $VertexCount, vertices];
  edgeVertices = Select[vertices, IntersectingQ[Part[$VertexAdjacencyTable, #], complement]&];
  subgraphRegionData @ edgeVertices
];


(********************************************)
(** RegionComplement[...]                  **)

PackageExport["RegionComplement"]

GraphRegionElementQ[RegionComplement[_, ___]] := True;

processRegion[RegionComplement[regions__]] :=
  RegionDataComplement @ Map[processRegion, {regions}];

(********************************************)

RegionDataComplement[{a_}] := a;

RegionDataComplement[{a_, b_, c__}] :=
  RegionDataComplement @ {a, RegionDataUnion[{b, c}]};

RegionDataComplement[e:{_, _}] := Scope[
  {va, vb} = regionDataListVertices /@ e;
  {ea, eb} = regionDataListEdges /@ e;
  danglingEdges = Pick[ea, MemberQ[vb, #1 | #2]& @@@ Part[$IndexGraphEdgeList, ea]];
  GraphRegionData[
    Complement[va, vb],
    Complement[ea, eb, danglingEdges]
  ]
]


(********************************************)
(** RegionIntersection[...]                **)

GraphRegionElementQ[RegionIntersection[___]] := True;

processRegion[RegionIntersection[regions__]] :=
  RegionDataIntersection @ Map[processRegion, {regions}];

(********************************************)

RegionDataIntersection[{a_}] := a;

RegionDataIntersection[list_List] :=
  GraphRegionData[
    Intersection @@ regionDataListVertices @ list,
    Intersection @@ regionDataListEdges @ list
  ]


(********************************************)
(** RegionUnion[...]                       **)

GraphRegionElementQ[RegionUnion[___]] := True;

processRegion[RegionUnion[regions__]] :=
  RegionDataUnion @ Map[processRegion, {regions}];

(********************************************)

PackageScope["RegionDataUnion"]

RegionDataUnion[{a_}] := a;

RegionDataUnion[assoc_Association] :=
  RegionDataUnion @ Values @ assoc;

RegionDataUnion[list_List] :=
  GraphRegionData[
    Union @@ regionDataListVertices @ list,
    Union @@ regionDataListEdges @ list
  ]
