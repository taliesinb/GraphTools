PackageExport["HighlightGraphRegion"]

SetUsage @ "
HighlightGraphRegion[graph$, highlights$] highlights regions of graph$ according to highlights$.
* HighlightGraphRegion returns a %Graph in which the option %GraphRegionHighlight has been set to \
highlights$.
* Any existing highlights are preserved.
<*$GraphRegionHighlightUsage*>
"

DeclareArgumentCount[HighlightGraphRegion, {2, 3}];

Options[HighlightGraphRegion] = $simpleGraphOptionRules;

declareSyntaxInfo[HighlightGraphRegion, {_, _, OptionsPattern[]}];

HighlightGraphRegion[graph_, highlights_, style:(_List | _String | $ColorPattern), opts:OptionsPattern[]] :=
  HighlightGraphRegion[graph, highlights, GraphHighlightStyle -> style, opts];

HighlightGraphRegion[graph_, highlights_, opts:OptionsPattern[]] := Scope[
  oldHighlights = AnnotationValue[graph, GraphRegionHighlight];
  oldHighlights = If[FailureQ[oldHighlights], {}, ToList @ oldHighlights];
  ExtendedGraph[
    graph,
    GraphRegionHighlight -> Join[oldHighlights, ToList @ highlights],
    opts
  ]
];

(**************************************************************************************************)

PackageExport["GraphRegionGraphics"]

GraphRegionGraphics[graph_, regionSpec_] := Scope[

  graph = CoerceToGraph[1];

  GraphPlotScope[graph,
    {graphics, padding} = resolveGraphRegionHighlightGraphics @ regionSpec;
    graphics = Part[graphics, All, 2];
    plotRange = $GraphPlotRange
  ];

  If[FailureQ[graphics], ReturnFailed[]];

  Graphics[graphics, PlotRange -> plotRange, Framed -> False]
];

(**************************************************************************************************)

(********************************************)
(** highlight processing code              **)
(********************************************)

PackageScope["resolveGraphRegionHighlightGraphics"]

resolveGraphRegionHighlightGraphics[None | {} | <||>] :=
  {{}, None, 0};

resolveGraphRegionHighlightGraphics[spec_] := Scope[

  $highlightStyle = $GraphHighlightStyle /. cc_CardinalColor :> evalCardinalColor[cc];

  If[MatchQ[spec, {__Association}], spec = Join @@ spec];
  If[Head[$highlightStyle] === Directive, $highlightStyle = List @@ $highlightStyle];

  (* strip off style rules and apply them in the standard way *)
  Which[
    ListQ[$highlightStyle] && MemberQ[$highlightStyle, $highlightStylePattern],
      {styleRules, $highlightStyle} = SelectDiscard[$highlightStyle, MatchQ @ $highlightStylePattern];
      If[$highlightStyle === {}, $highlightStyle = Automatic];
      spec = Style[spec, Sequence @@ styleRules],
    MatchQ[$highlightStyle, $highlightStylePattern],
      spec = Style[spec, $highlightStyle];
      $highlightStyle = Automatic,
    True,
      Null
  ];

  (* GraphHighlightStyle -> Opacity[o] will still use the default color palette but control it's opacity *)
  $defaultOpacity = If[!MatchQ[$highlightStyle, $opacityPattern | Style[$opacityPattern, ___]], 0.5,
    $highlightStyle = Automatic; ExtractFirstOpacity[$highlightStyle]];

  (* toMultiDirective will interpret palette specs passed to GraphHighlightStyle, which will
  turn into lists. it will also map over lists and associations to control lists or associations of regions *)
  defaultPalette = If[FreeQ[spec, "Foreground" | "Background" | Opaque | "Replace" | "ReplaceEdges"], "Dark", "Medium"];
  $highlightStyle = toMultiDirective @ Replace[$highlightStyle, Automatic -> Offset[defaultPalette, 2]];

  (* if no opacity was specified, use the default opacity *)
  $highlightOpacity = ExtractFirstOpacity[$highlightStyle];
  SetNone[$highlightOpacity,
    $highlightStyle = SetColorOpacity[$highlightStyle, $defaultOpacity]; $defaultOpacity];

  $highlightRadius = $GraphMaxSafeVertexSize;

  (* todo: use the same conversion functions as I use in GraphPlotting *)
  $pathRadius = Automatic; $diskRadius = Automatic;
  $graphPlotWidth = First @ $GraphPlotSize;
  $radiusScaling = If[$GraphIs3D, 0.25, 1];
  $edgeBaseStyle := $edgeBaseStyle = FirstCase[
    $GraphPlotGraphics,
    Annotation[Style[_, style___], _, "EdgePrimitivesRoot"] :> toDirective[{style}],
    {}, {0, Infinity}
  ];

  $cardinalFilter = All;
  $zorder = 1;
  $requiredPadding = 0;
  $pathStyle = "Line";
  $regionStyle = "Highlight";
  $arrowheadPosition = 1.0;
  $arrowheadSize = Automatic;
  $edgeSetback = 1;
  $outline = False;
  $simplifyRegions = False;

  $colorPalette = ToColorPalette[Automatic];
  CollectTo[{$highlightsBag, $legendsBag}, processOuterSpec[spec]];
  legend = If[$legendsBag === {}, None, DiscreteColorLegend @ Association @ $legendsBag];

  $highlightsBag = Sort[$highlightsBag];
  {Part[$highlightsBag, All, {1, 3}], legend, $requiredPadding}
];

requirePadding[p_] := $requiredPadding = Max[$requiredPadding, p];

sowHighlight[g_] := Internal`StuffBag[$highlightsBag, {$zorder, Internal`BagLength[$highlightsBag], g}];

sowLegend[name_, color_] := Internal`StuffBag[$legendsBag, name -> color];

debugGraphic[g_] := (Internal`StuffBag[$highlightsBag, {100, 100, {Black, g}}]; g);

echoGraphic[g_] := (Echo[Graphics[g, ImageSize -> {200, 200}]]; g);

(**************************************************************************************************)

processOuterSpec = MatchValues[
  spec_ ? ListOrAssociationQ := Block[
    {$i = 1, $highlightStyle = $highlightStyle},
    MapIndexed[processIndexedStyleSpec[#1, First @ #2, $i++]&, spec];
  ];
  s_Style :=
    (* this applies styles before iterating over a list or associations *)
    processStyleSpec[s, processOuterSpec];
  other_ := Block[
    {$highlightStyle = $highlightStyle},
    If[ListOrAssociationQ[$highlightStyle], $highlightStyle //= First];
    processGeneralSpec[other];
  ];
];

GraphRegionHighlight::missspecstyle = "Cannot find a style to use for spec part ``.";

processIndexedStyleSpec[spec_, key_, index_] := Block[
  {part},
  part = Which[
    AssociationQ @ $highlightStyle, key,
    ListQ @ $highlightStyle,        index,
    True,                           All
  ];
  If[IntegerQ @ part, part = Min[part, Length @ $highlightStyle]];
  Block[{$highlightStyle = If[part === All, $highlightStyle, Part[$highlightStyle, part]]},
    If[MissingQ[$highlightStyle],
      Message[GraphRegionHighlight::missspecstyle, part],
      processGeneralSpec @ If[Head[key] === Key, Legended[spec, First @ key], spec];
    ];
  ];
];

(**************************************************************************************************)

PackageExport["ZOrder"]

SetUsage @ "
ZOrder is an option that controls how graphical elements are sorted from back to front.
"

(**************************************************************************************************)

PackageExport["PathStyle"]

SetUsage @ "
PathStyle is an option that controls how paths are rendered in highlights.
"

(**************************************************************************************************)

PackageExport["RegionStyle"]

SetUsage @ "
RegionStyle is an option that controls how regions are rendered in highlights.
"

(**************************************************************************************************)

GraphRegionHighlight::badelem = "Unknown highlight element ``.";

PackageExport["HighlightRadius"]

SetUsage @ "
HighlightRadius is an option that controls the radius of highlighted regions.
"

PackageExport["PathRadius"]

SetUsage @ "
PathRadius is an option that controls the radius of highlighted paths.
"

PackageExport["DiskRadius"]

SetUsage @ "
DiskRadius is an option that controls the radius of highlighted vertices.
"

PackageExport["EdgeSetback"]

SetUsage @ "
EdgeSetback is an option that controls how far an edge should be set back from final vertex.
"


processGeneralSpec = MatchValues[
  Legended[Style[spec_, opts__], label_] :=
    % @ Style[Legended[spec, label], opts];
  Legended[spec_, label_] := (
    % @ spec;
    sowLegend[label, $highlightStyle];
  );
  Axes -> spec_ :=
    processAxesSpec @ spec;
  spec_Style :=
    processStyleSpec[spec, %];
  Labeled[spec_, _] :=
    % @ spec;
  region_ ? GraphRegionElementQ :=
    resolveHighlightSpec @ region;
  Arrow[spec_List] /; VectorQ[spec, validVertexQ] :=
    % @ Arrow @ Line @ spec;
  Arrow[spec_] := Block[{$pathStyle = Replace[$pathStyle, "Line" -> "Arrow"]},
    % @ spec;
  ];
  Null := Null;
  list_List :=
    Scan[processGeneralSpec, list];
  other_ :=
    Message[GraphRegionHighlight::badelem, Shallow[other]];
];

(* Offset needs processRegionSpec to be resolved, which is not available yet, so assume it's correct *)
validVertexQ[v_] := If[ContainsQ[v, Offset], True, !FailureQ[findVertexIndex @ v]];

(**************************************************************************************************)

processAxesSpec[spec:(All|_Integer|{__Integer})] := Scope[
  colors = LookupCardinalColors[$Graph];
  KeyValueMap[axisHighlight, Part[colors, If[IntegerQ[spec], {spec}, spec]]]
];

processAxesSpec[spec_] := Scope[
  colors = LookupCardinalColors[$Graph];
  words = Map[ParseCardinalWord, ToList @ spec];
  colors = AssociationMap[LookupCardinalColors[$Graph, #]&, words];
  KeyValueMap[axisHighlight, colors]
];

axisHighlight[word_, color_] := Scope[
  path = First @ processRegionSpec @ InfiniteLine[GraphOrigin, word];
  If[Length @ DeleteDuplicates @ First @ path <= 2, Return[]];
  processGeneralSpec @ Style[path, color, HighlightRadius -> 2];
];

(**************************************************************************************************)

GraphRegionHighlight::badstylespec = "Unknown style specification ``.";

processStyleSpec[spec_, f_] := Scope[
  $innerFunc =f ;
  iProcessStyleSpec @ spec
];


Style;
SyntaxInformation[Style];
Options[Style];

$additionalStyleOptions = {
  PerformanceGoal, PathStyle, RegionStyle, ArrowheadPosition, ArrowheadSize, PointSize, HighlightRadius,
  PathRadius, EdgeSetback, SimplifyRegions, ZOrder, Cardinals
};

Unprotect[Style];
SyntaxInformation[Style] = ReplaceOptions[
  SyntaxInformation[Style],
  "OptionNames" -> Union[Keys @ Options @ Style, SymbolName /@ $additionalStyleOptions]
];
Protect[Style];

PackageExport["PathOutline"]
PackageExport["SimplifyRegions"]

$namedTransformsPattern = "Opaque" | "FadeGraph" | "FadeEdges" | "FadeVertices" | "HideArrowheads" | "HideEdges" | "HideVertices";
$namedStyles = "Background" | "Foreground" | "Replace" | "ReplaceEdges" | $namedTransformsPattern;
$highlightStylePattern = Rule[Alternatives @@ $additionalStyleOptions, _] | $namedStyles;

iProcessStyleSpec = MatchValues[
  Style[most__, style:$ColorPattern] := Block[
    {$highlightStyle = SetColorOpacity[RemoveColorOpacity @ style, $highlightOpacity]},
    % @ Style @ most
  ];
  Style[most__, SimplifyRegions -> boole_] := Scope[
    $simplifyRegions = boole;
    % @ Style @ most
  ];
  Style[most__, PerformanceGoal -> goal_] := Scope[
    $perfGoal = goal;
    % @ Style @ most
  ];
  Style[most__, PathStyle -> style_] := Scope[
    $pathStyle = style;
    % @ Style @ most
  ];
  Style[most__, RegionStyle -> style_] := Scope[
    $regionStyle = style;
    % @ Style @ most
  ];
  Style[most__, ArrowheadPosition -> pos_] := Scope[
    $arrowheadPosition = N[pos];
    % @ Style @ most
  ];
  Style[most__, DiskRadius -> sz_] := Scope[
    $diskRadius = sz; (* this is measured in points, not in fraction of image width *)
    % @ Style @ most
  ];
  Style[most__, ArrowheadSize -> sz_] := Scope[
    $arrowheadSize = sz;
    % @ Style @ most
  ];
  Style[most__, HighlightRadius -> r_] := Scope[
    $radiusScaling = r;
    % @ Style @ most
  ];
  Style[most__, PathRadius -> r_] := Scope[
    $pathRadius = r;
    % @ Style @ most
  ];
  Style[most__, PathOutline -> out_] := Scope[
    $outline = out;
    % @ Style @ most
  ];
  Style[most__, EdgeSetback -> r_] := Scope[
    $edgeSetback = r;
    % @ Style @ most
  ];
  Style[most__, Cardinals -> cards_] := Scope[
    $cardinalFilter = ToList @ cards;
    % @ Style @ most
  ];
  Style[most__, n:$namedTransformsPattern] := (
    AttachGraphPlotAnnotation[n];
    % @ Style[most];
  );
  Style[most__, "Background"] := % @ Style[most, Opaque, ZOrder -> -10];
  Style[most__, "Foreground"] := % @ Style[most, Opaque, ZOrder -> 10];
  Style[most__, "Replace"] := % @ Style[most, Opaque, ZOrder -> 10, PathStyle -> "Replace", RegionStyle -> "Replace"];
  Style[most__, "ReplaceEdges"] := % @ Style[most, Opaque, ZOrder -> 10, PathStyle -> "ReplaceEdges", RegionStyle -> "ReplaceEdges"];
  Style[most__, ZOrder -> z_Integer] := Scope[
    $zorder = z;
    % @ Style @ most
  ];
  Style[most__, "Opaque"] := % @ Style[most, Opaque];
  Style[most__, o:$opacityPattern] := Block[
    {$highlightOpacity = ExtractFirstOpacity @ o}, Block[
    {$highlightStyle = SetColorOpacity[RemoveColorOpacity @ $highlightStyle, $highlightOpacity]},
    % @ Style @ most
  ]];
  Style[elem_] :=
    $innerFunc[elem];
  Style[__, remaining_] :=
    Message[GraphRegionHighlight::badstylespec, remaining];
];

(**************************************************************************************************)

resolveHighlightSpec[region_] := Scope[
  results = ToList @ processRegionSpec @ region;
  Scan[highlightRegion, results]
];

GraphRegionHighlight::interror = "Internal error: couldn't highlight `` data.";

highlightRegion[other_] := (
  Message[GraphRegionHighlight::interror, other];
);

highlightRegion[GraphRegionData[vertices_, edges_]] /; StringStartsQ[$regionStyle, "Replace"] := Scope[
  $newVertices = {}; $newEdges = {};
  TransformGraphPlotPrimitives[removeHighlightedPathEdges, edges, "EdgePrimitives"];
  TransformGraphPlotPrimitives[removeHighlightedPathVertices, vertices, "VertexPrimitives"];
  pathPrimitives = {simplifyPrimitives @ $newEdges, simplifyPrimitives @ $newVertices};
  sowHighlight @ Style[
    replaceWithColor[pathPrimitives, $highlightStyle, $regionStyle === "ReplaceEdges"],
    $edgeBaseStyle, $highlightStyle
  ];
];

highlightRegion[GraphRegionData[vertices_, edges_]] /; $regionStyle === "Highlight" := Scope[
  If[$perfGoal === "Speed",
    Return @ highlightRegion @ GraphRegionData[vertices, {}]];
  graphics = subgraphCoveringGraphics[
    $highlightRadius * $radiusScaling, vertices, edges,
    $IndexGraphEdgeList, $VertexCoordinates, $EdgeCoordinateLists
  ];
  sowHighlight @ Style[graphics, $highlightStyle];
];

highlightRegion[GraphRegionData[vertices_, {}]] /; $regionStyle === "Highlight" :=
  sowVertexPoints @ vertices;

sowVertexPoints[vertices_] := Scope[
  SetAutomatic[$diskRadius, 5];
  requirePadding @ $diskRadius;
  coords = Part[$VertexCoordinates, DeleteDuplicates @ vertices];
  highlights = If[$GraphIs3D,
    Style[
      Sphere[coords, $diskRadius / $GraphPlotImageWidth * $graphPlotWidth],
      Directive[Glow[$highlightStyle], GrayLevel[0, 1], Specularity[0]]
    ]
  ,
    Style[
      Point @ coords,
      PointSize @ $diskRadius, $highlightStyle
    ];
  ];
  sowHighlight @ highlights
];

$currentRegionAnnotations = <||>;
highlightRegion[GraphRegionAnnotation[data_, anno_]] := Scope[
  $currentRegionAnnotations = anno;
  highlightRegion @ data;
]

highlightRegion[GraphPathData[vertices_, edges_, negations_]] := Scope[

  segments = Part[$EdgeCoordinateLists, edges];
  If[negations =!= {},
    segments //= MapAt[Reverse, List /@ negations]];
  numSegments = Length @ segments;

  pathRadius = $pathRadius;
  SetAutomatic[pathRadius, Switch[$pathStyle,
    "Replace" | "ReplaceEdges",           First @ evalGraphicsValue @ GraphicsValue["EdgeThickness"],
    s_ /; StringContainsQ[s, "Arrow"],    4.0,
    "Line",                               6.0
  ]];

  thickness = pathRadius / $GraphPlotImageWidth;
  thicknessRange = thickness * $graphPlotWidth * 1.5;
  bendRange = Max[thicknessRange/2, 5 / $GraphPlotImageWidth * $graphPlotWidth];

  adjustments = parseAdjustments /@ Lookup[$currentRegionAnnotations, PathAdjustments, {}];

  lastIsModified = !MatchQ[Lookup[adjustments, numSegments], _Missing | _String | {"Arrowhead", _}];
  $extraArrowheads = {};
  segments = joinSegments[segments, adjustments, $pathStyle =!= "Replace"];

  doArrow = StringContainsQ[$pathStyle, "Arrow"];

  color = FirstCase[$highlightStyle, $ColorPattern, Gray, {0, Infinity}];
  darkerColor := OklabDarker[RemoveColorOpacity @ color, .05];
  arrowheadColor = If[$highlightOpacity == 1, darkerColor, color];

  vertexSizePR = evalGraphicsValue @ GraphicsValue["VertexSize", "PlotRange"] * 1.2;
  setbackDistance = If[lastIsModified || !doArrow || Max[$arrowheadPosition] != 1, 0, Max[$edgeSetback * thicknessRange/2, vertexSizePR]];
  If[$edgeSetback == 0, setbackDistance = 0];
  isEdgeBased = True;

  pathPrimitives = If[$GraphIs3D && $pathStyle === "Line",
    isEdgeBased = False;
    Tube[segments, thicknessRange / 3]
  ,
    Switch[$pathStyle,
     "Arrow" | "DiskArrow" | "DiskArrowDisk" | "ArrowDisk",
        arrowheadSize = $arrowheadSize;
        If[NumericQ[arrowheadSize],
          arrowheadSize = N[arrowheadSize] / $GraphPlotImageWidth];
        SetAutomatic[arrowheadSize, thickness];
        baseArrowheads = List[
          arrowheadSize, $apos,
          makeHighlightArrowheadShape[arrowheadColor, 5, $GraphIs3D]
        ];
        arrowheads = Arrowheads @ If[ListQ[$arrowheadPosition],
          Map[ReplaceAll[baseArrowheads, $apos -> #]&, $arrowheadPosition],
          List @ ReplaceAll[baseArrowheads, $apos -> $arrowheadPosition]
        ];
        diskRadius = $diskRadius;
        SetAutomatic[diskRadius, pathRadius * 1.5];
        diskRadius = diskRadius / $GraphPlotImageWidth * $graphPlotWidth;
        disk1 = If[!StringStartsQ[$pathStyle, "Disk"], Nothing, Disk[Part[$VertexCoordinates, First @ vertices], diskRadius]];
        disk2 = If[!StringEndsQ[$pathStyle, "Disk"], Nothing, Disk[Part[$VertexCoordinates, Last @ vertices], diskRadius]];
        arrow = setbackArrow[segments, setbackDistance];
        extraArrowheads = If[$extraArrowheads === {}, Nothing,
          Style[Arrow[#1], Transparent, Arrowheads @ List @ ReplaceAll[baseArrowheads, $apos -> #2]]& @@@ $extraArrowheads
        ];
        {disk1, arrowheads, arrow, disk2, extraArrowheads}
      ,
      "Replace" | "ReplaceEdges",
        $cardinalFilter = If[$pathStyle === "ReplaceEdges", {}, All];
        $newVertices = $newEdges = {}; $firstRemovedArrowheads = None;
        TransformGraphPlotPrimitives[removeHighlightedPathEdges, edges, "EdgePrimitives"];
        TransformGraphPlotPrimitives[removeHighlightedPathVertices, vertices, "VertexPrimitives"];
        $newEdges = Which[
          edges === {}, {},
          adjustments === {}, $newEdges,
          True, Style[Arrow @ segments, $firstRemovedArrowheads, CapForm @ "Round"]
        ];
        pathPrimitives = {Style[$newEdges, $edgeBaseStyle], $newVertices};
        replaceWithColor[pathPrimitives, $highlightStyle]
      ,
      _,
        setbackLine[segments, setbackDistance]
    ]
  ];

  If[$GraphIs3D && $pathStyle =!= "Replace",
    pathPrimitives = pathPrimitives /. {
      Disk[p_, r_] :> Sphere[p, r],
      Arrow[a___] :> Arrow[Tube[a, diskRadius / 1.5]]
    };
    color = color /. c:$ColorPattern :> Color3D[c]
  ];

  pathStyle = If[$GraphIs3D && $highlightOpacity < 0.9 && !isEdgeBased,
    FaceForm[color, None], color];

  If[$outline === True,
    outlineColor = If[$outline === True, darkerColor, $outline];
    sowHighlight @ Style[
      Line @ segments,
      JoinForm @ "Round", CapForm @ "Round",
      outlineColor, Thickness[thickness * 1.5]
    ];
  ];


  (* unfortunately CapForm doesn't do anything for Arrow *)
  requirePadding[If[doArrow, 1.2, 1] * thicknessRange / $graphPlotWidth * $GraphPlotImageWidth];
  sowHighlight @ Style[
    pathPrimitives,
    JoinForm @ "Round", CapForm @ "Round",
    pathStyle, Thickness @ thickness
  ];
];

replaceWithColor[g_, c_, preserveArrowheads_:False] :=
  ReplaceAll[g, {
    t_Text :> t,
    If[preserveArrowheads, a_Arrowheads :> a, Nothing],
    Directive[Glow[_], rest___] :> Directive[Glow[c], rest], (* <- 3d color *)
    Inset[z_Graphics, args__] :> Inset[SetFrameColor[z, c], args],
    $ColorPattern -> c
  }];

(* we simply delete matching edges, because we will redraw them possibly with adjustments *)
removeHighlightedPathEdges[{old_, new_}] := Scope[
  $firstRemovedArrowheads ^= FirstCase[old, _Arrowheads, None, Infinity];
  If[$cardinalFilter =!= All,
    $filteredEdges = {}; new //= saveAndTrimFilteredEdges;
    old = {old, $filteredEdges};
  ];
  AppendTo[$newEdges, new];
  old
];

(* we will delete matching vertices, but save them to be redrawn with the highlight color *)
removeHighlightedPathVertices[{old_, new_}] := (
  AppendTo[$newVertices, new];
  old
);

filteredArrowheadsQ[Arrowheads[list_List]] :=
  AnyTrue[list, filteredArrowheadSpecQ];

filteredArrowheadSpecQ[{_, _, Graphics[Annotation[_, card_, "Cardinal"], ___]}] /;
  !MemberQ[$cardinalFilter, card | Negated[card]] := True;

saveAndTrimFilteredEdges[edges_] := Scope[
  edges /. Style[p_, l___, a_Arrowheads ? filteredArrowheadsQ, r___] :> {
    {aNonvis, aVis} = SelectDiscard[First @ a, filteredArrowheadSpecQ];
    AppendTo[$filteredEdges, Style[p, Transparent, l, Arrowheads @ aNonvis, r]];
    Style[p, l, Arrowheads @ aVis, r]
  }
];

(**************************************************************************************************)

setbackArrow[{}, _] := {};

setbackArrow[curve_, 0|0.] := Arrow @ curve;

setbackArrow[curve_, d_] := Scope[
  target = Last @ curve;
  curve = SetbackCoordinates[curve, {0, d}];
  If[curve === {}, Return @ {}];
  last = Last @ curve;
  Arrow @ Append[curve, last + Normalize[target - last] * 1*^-3]
];

setbackLine[curve_, 0|0.] := Line @ curve;

setbackLine[curve_, d_] := Line @ SetbackCoordinates[curve, {0, d}];

joinSegments[{}, _, _] := {};

joinSegments[segments_, adjustments_, shouldJoin_] := Scope[
  numSegments = Length @ segments;
  $offsetVector = 0; isLast = False;
  segments = segments;
  lineBag = Internal`Bag[];
  Replace[adjustments, {
    Rule[{z_, _}, {"Shrink", n_}] :> (Part[segments, z] //= shrinkSegment[n * bendRange]),
    Rule[{z_, _}, {"Short", n_}] :> (Part[segments, {z, z + 1}] //= shortSegment[n * bendRange])
  }, {1}];
  Do[
    isLast = i == numSegments;
    segment = PlusVector[$offsetVector] @ Part[segments, i];
    mod = Lookup[adjustments, i, 0];
    Switch[mod,
      0,
        Null,
      {"Arrowhead", _},
        $extraArrowheads ^= Append[$extraArrowheads, {segment, Last @ mod}],
      {"Bend", _} /; !isLast,
        nextSegment = Part[segments, i + 1];
        {segment, nextSegment} = applyBendBetween[segment, nextSegment, 1.5 * Last[mod]];
        Part[segments, i + 1] = nextSegment,
      {"Extend", _ ? Positive},
        {delta, segment} = extendSegment[segment, Last @ mod];
        $offsetVector += delta,
      {"Extend", _ ? Negative},
        {delta, segment} = truncateSegment[segment, Abs @ Last @ mod];
        If[doArrow && isLast,
          (* this makes sure the arrowhead points at the original target *)
          AppendTo[segment, PointAlongLine[{Last[segment], Part[segments, -1, -1]}, 1*^-3]]];
        $offsetVector += delta
    ];
    If[shouldJoin,
      Internal`StuffBag[lineBag, If[i === 1, Identity, Rest] @ segment, 1],
      Internal`StuffBag[lineBag, segment]
    ];
  ,
    {i, 1, numSegments}
  ];
  Internal`BagPart[lineBag, All]
];

shrinkSegment[d_][segment_] := Scope[
  {a, b} = FirstLast @ segment;
  mid = Mean[{a, b}];
  a2 = PointAlongLine[{a, mid}, d];
  b2 = PointAlongLine[{b, mid}, d];
  scaling = EuclideanDistance[mid, a2] / EuclideanDistance[mid, a];
  translated = PlusVector[segment, -mid];
  segment = PlusVector[translated * scaling, mid];
  Join[{a, a2}, segment, {b2, b}]
];

shrinkSegment[{d1_, d2_}][segment_] := Scope[
  {a, b} = FirstLast @ segment;
  mid = Mean @ segment;
  a2 = PointAlongLine[{a, mid}, d1];
  b2 = PointAlongLine[{b, mid}, d2];
  scaling1 = EuclideanDistance[mid, a2] / EuclideanDistance[mid, a];
  scaling2 = EuclideanDistance[mid, b2] / EuclideanDistance[mid, b];
  translated = PlusVector[segment, -mid];
  segment = MapThread[{t, p} |-> t * p + mid, {
    translated,
    Interpolated[scaling1, scaling2, Length @ translated]
  }];
  Join[{a, a2}, segment, {b2, b}]
];

shortSegment[d_][{segmentA_, segmentB_}] := Scope[
  If[ListQ[d], {d1, d2} = d, d1 = d2 = d];
  segmentA = SetbackCoordinates[segmentA, {0, d1}];
  segmentB = SetbackCoordinates[segmentB, {d2, 0}];
  AppendTo[segmentA, First @ segmentB];
  {segmentA, segmentB}
];

GraphRegionHighlight::badpadj = "PathAdjustments element `` is invalid.";

parseAdjustments = MatchValues[
  z_Integer ? Negative -> other_                          := %[modLen[z] -> other];
  z_Integer -> "Arrowhead"                                := z -> {"Arrowhead", .5};
  z_Integer -> {"Arrowhead", pos_}                        := z -> {"Arrowhead", pos};
  z_Integer -> spec:{"Bend" | "Extend", ___}              := z -> spec;
  z:{__Integer} -> spec:{"Shrink" | "Short", ___}         := modLen[z] -> spec;
  z_ -> {"Expand", n_}                                    := %[z -> {"Shrink", -n}];
  z_ -> {"Shorten", n_}                                   := %[z -> {"Extend", -n}];
  z_ -> spec_String                                       := %[z -> {spec, 1}];
  other_ := (Message[GraphRegionHighlight::badpadj, other]; {})
];

modLen[z_] := Mod[z, numSegments + 1, 1];

(**************************************************************************************************)

applyBendBetween[segment1_, segment2_, d_] := Scope[
  {delta, truncated1} = truncateSegment[segment1, d];
  {delta, truncated2} = truncateSegment[Reverse @ segment2, d];
  bendStart = Last @ truncated1;
  bendEnd = Last @ truncated2;
  circlePoints = circleAround[bendStart, bendEnd, Last @ segment1];
  {
    Join[truncated1, circlePoints],
    Join[Take[circlePoints, -2], Reverse @ truncated2]
  }
];

circleAround[p1_, p2_, q_] := Scope[
  d1 = p1 - q; d2 = p2 - q;
  r = Mean[{Norm @ d1, Norm @ d2}];
  a1 = ArcTan @@ d1; a2 = ArcTan @@ d2;
  an = p + a0; bn = p + b0;
  While[a2 < a1, a2 += Tau]; as1 = DeleteDuplicates @ Append[a2] @ Range[a1, a2, Tau / 16];
  While[a1 < a2, a1 += Tau]; as2 = Reverse @ DeleteDuplicates @ Append[a1] @ Range[a2, a1, Tau / 16];
  as = MinimumBy[{as1, as2}, Length];
  AngleVector[q, {r, #}]& /@ as
];

scaleSegment[coords_, n_] := Scope[
  {first, last} = FirstLast @ segment;
  translated = PlusVector[segment, -first];
  dist = EuclideanDistance[first, last];
  margin = n * bendRange * If[isLast, 2, 1.5];
  scaling = (dist + margin) / dist;
  PlusVector[translated * scaling, first]
];

finalDelta[coords_, n_] := Normalize[Part[coords, -1] - Part[coords, -2]] * bendRange * n;

extendSegment[coords_, n_] := Scope[
  delta = finalDelta[coords, n];
  {delta, MapAt[PlusOperator[delta], coords, -1]}
];

truncateSegment[coords_, n_] := Scope[
  delta = finalDelta[coords, -n];
  coords = SetbackCoordinates[coords, {0, bendRange * n}];
  {delta, coords}
];

(**************************************************************************************************)

subgraphCoveringGraphics[r_, vertices_, edgeIndices_, edgeList_, vertexCoords_, edgeCoordsLists_] := Scope[
  vertexPoints = Part[vertexCoords, vertices];
  center = Mean[vertexPoints];
  radius = Max[SquaredDistanceMatrix[vertexPoints, {center}]];
  externalCoords = Part[vertexCoords, Complement[Range @ Length @ vertexCoords, vertices]];
  If[$simplifyRegions && externalCoords =!= {} && (other = Min[SquaredDistanceMatrix[externalCoords, {center}]]) > radius,
    dr = (other - radius) / If[$GraphIs3D, 32, 3];
    Return @ If[$GraphIs3D, Sphere, Disk][center, Sqrt[radius + dr]];
  ];
  edgePoints = DeleteDuplicates @ Flatten[edgeSpaced /@ Part[edgeCoordsLists, edgeIndices], 1];
  points = ToPacked @ Join[vertexPoints, edgePoints];
  primitives = PointDilationGraphics[points, r];
  If[ContainsQ[primitives, Polygon[_Rule]],
    primitives = primitives /. p:Polygon[_Rule] :> removeTrivialHoles[p, externalCoords];
  ];
  Style[primitives, EdgeForm[None]]
];

containsAnyPointsQ[coords_, points_] := Scope[
  bbox = CoordinateBounds[coords];
  points = Select[points, VectorBetween[bbox]];
  If[points === {}, False,
    memberFunc = RegionMember @ ConvexHullMesh @ coords;
    AnyTrue[points, memberFunc]
  ]
];

removeTrivialHoles[Polygon[coords_ -> holes_], ext2_] := Scope[
  bbox = CoordinateBounds[coords];
  ext = Select[ext2, VectorBetween[bbox]];
  makePolygon[coords, Select[holes, hole |-> containsAnyPointsQ[hole, ext]]]
];

makePolygon[coords_, {}] := Polygon[coords];
makePolygon[coords_, holes_] := Polygon[coords -> holes];

edgeSpaced[{a_, b_}] := Table[i * a + (1-i) * b, {i, .125, .875, .125}];
edgeSpaced[list_List] := Mean[list];
