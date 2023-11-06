PublicFunction[StringDiagram]

PublicOption[WireThickness, NodeEdgeThickness, LabelOffset, DiagramSize, TextModifiers, HalfFrame, BaseThickness, CurveFunction]

PublicOption[NodeSize, NodeLabelPosition, NodeLabelFontWeight, NodeLabelFontFamily, NodeLabelFontSize, NodeLabelSpacing, NodeLabelOffset, NodeLabelBackground, NodeLabelFontColor, NodeFrameColor, NodeBackground, NodeShape]

PublicOption[WireLabelFontSize, WireLabelFontWeight, WireLabelFontFamily, WireLabelPosition, WireLabelSpacing, WireLabelOffset, WireLabelBackground, WireLabelFontColor, WireColor]

PublicOption[RegionLabelFontSize, RegionLabelFontWeight, RegionLabelFontFamily]

PublicOption[TickLabelFontSize, TickLabelFontWeight, TickLabelFontFamily, TickLabelSpacing, TickLabelFontColor, TickLength, RegionFilling]


Options[StringDiagram] = {
  ImageSize             -> Automatic,
  ImagePadding          -> Automatic,
  Epilog                -> {},

  FontSize              -> 16,
  FontWeight            -> Plain,
  FontFamily            :> $MathFont,

  BaseThickness         -> Automatic,
  WireThickness         -> Automatic,
  NodeEdgeThickness     -> Automatic,

  HalfFrame             -> False,
  FrameThickness        -> Automatic,
  FrameColor            -> Automatic,
  Background            -> None,

  FlipX                 -> False,
  FlipY                 -> False,
  DiagramSize           -> {12, 12},
  GraphicsScale         -> 5,

  TextModifiers         -> {},
  CurveFunction         -> Automatic,
  SplitPosition         -> "Start",
  "SplitOrientation"    -> Horizontal,

  NodeSize              -> 25,
  NodeShape             -> NodeDisk,
  NodeLabelFontSize     -> Automatic,
  NodeLabelFontWeight   -> Bold,
  NodeLabelFontFamily   -> Automatic,
  NodeLabelFontColor    -> Black,
  NodeLabelPosition     -> Center,
  NodeLabelSpacing      -> {5, 0},
  NodeLabelOffset       -> {0, 0},
  NodeLabelBackground   -> None,
  NodeFrameColor        -> None,
  NodeBackground        -> White,

  WireLabelFontSize     -> Automatic,
  WireLabelFontWeight   -> Automatic,
  WireLabelFontFamily   -> Automatic,
  WireLabelFontColor    -> Black,
  WireLabelPosition     -> Vertical,
  WireLabelSpacing      -> {5, 0},
  WireLabelOffset       -> {0, 0},
  WireLabelBackground   -> None,
  WireColor             -> Automatic,

  RegionLabelFontSize   -> Automatic,
  RegionLabelFontWeight -> Automatic,
  RegionLabelFontFamily -> Automatic,

  FrameTicks            -> {},
  TickLength            -> 5,
  TickLabelFontSize     -> Automatic,
  TickLabelFontWeight   -> Plain,
  TickLabelFontFamily   -> Automatic,
  TickLabelSpacing      -> 3,
  TickLabelFontColor    -> Black,

  RegionFilling         -> "Explicit",
  ColorRules            -> None,
  GradientSymbolOptions -> {Method -> "Raster"}
}

SetUsage @ "
RegionFilling is an option to %StringDiagram that determines how regions should be filled:
| 'Explicit' | do not fill regions unless explicitly passed a color |
| 'Labeled'  | fill regions if a colored region label is used, retaining the label |
| 'Unlabeled' | fill regions but elide the label |
"

(**************************************************************************************************)

$colorOrInt = $ColorPattern | _Int;

StringDiagram[boxes_List, wires_List, opts___Rule] :=
  StringDiagram[boxes, wires, {}, opts];

StringDiagram[boxes_List, wires_List, regions_List, opts:OptionsPattern[]] := Scope[
  $boxAliases = $wireAliases = UAssoc[];
  $fillRegions = {};

  UnpackOptions[
    flipX, flipY, wireThickness, nodeEdgeThickness, nodeBackground, frameThickness, frameColor, curveFunction,
    splitPosition, splitOrientation, background, baseThickness, halfFrame, imagePadding, epilog, fontSize, fontWeight, fontFamily,
    diagramSize, imageSize, graphicsScale, textModifiers, frameTicks, colorRules, regionFilling, gradientSymbolOptions
  ];

  $lastInnerLabel = None;
  {$w, $h} = diagramSize;
  SetAutomatic[imageSize, 2 * graphicsScale * diagramSize];

  SetAutomatic[baseThickness, 2];
  SetAutomatic[wireThickness, baseThickness];
  SetAutomatic[nodeEdgeThickness, baseThickness];

  $colorModifierFn = parseDiagramColorRules[colorRules, gradientSymbolOptions];
  {boxTextModifierFn, wireTextModifierFn, regionTextModifierFn} = Map[
    toModifierFunction,
    If[AssocQ[textModifiers],
      Lookup[textModifiers, {"Boxes", "Wires", "Regions"}, {}],
      {textModifiers, textModifiers, textModifiers}
    ]
  ];

  backgroundColor = If[background === None, None,
    If[ColorQ[background], ToRainbowColor @ background, extractColorFromLabel @ $colorModifierFn @ background]
  ];
  defaultWireColor = If[backgroundColor === None, Black, OklabDarker @ backgroundColor];

  UnpackOptions[nodeFrameColor, nodeSize, $nodeShape, nodeLabelFontColor, nodeLabelPosition, nodeLabelSpacing, nodeLabelOffset, nodeLabelBackground, nodeLabelFontSize, nodeLabelFontWeight, nodeLabelFontFamily];
  $fontColor = nodeLabelFontColor;
  $currentDiagramFontSize = $fontSize = ReplaceAutomatic[nodeLabelFontSize, fontSize];
  $fontWeight = ReplaceAutomatic[nodeLabelFontWeight, fontWeight];
  $fontFamily = ReplaceAutomatic[nodeLabelFontFamily, fontFamily];
  labelSpacing = nodeLabelSpacing; labelPosition = nodeLabelPosition; labelOffset = nodeLabelOffset; labelBackground = nodeLabelBackground;
  boxColor = None; hasBottomLabels = hasTopLabels = hasLeftLabels = hasRightLabels = False;
  $textModifierFn = boxTextModifierFn;
  boxPrims = MapIndex1[$keyOff = 0; parseBox, boxes];

  UnpackOptions[wireColor, wireLabelPosition, wireLabelFontColor, wireLabelSpacing, wireLabelOffset, wireLabelBackground, wireLabelFontSize, wireLabelFontWeight, wireLabelFontFamily];
  SetAutomatic[wireColor, defaultWireColor];
  $fontColor = wireLabelFontColor;
  $currentDiagramFontSize = $fontSize = ReplaceAutomatic[wireLabelFontSize, fontSize];
  $fontWeight = ReplaceAutomatic[wireLabelFontWeight, fontWeight];
  $fontFamily = ReplaceAutomatic[wireLabelFontFamily, fontFamily];
  labelPosition = wireLabelPosition; labelSpacing = wireLabelSpacing; labelOffset = wireLabelOffset; labelBackground = wireLabelBackground;
  SetAutomatic[curveFunction, CircuitCurve[#, SetbackDistance -> None, SplitPosition -> splitPosition, Orientation -> splitOrientation]&];
  $textModifierFn = wireTextModifierFn;
  wirePrims = MapIndex1[$keyOff = 0; parseWire, wires];

  UnpackOptions[tickLabelFontColor, tickLabelSpacing, tickLabelFontSize, tickLabelFontWeight, tickLabelFontFamily, tickLength];
  $fontColor = tickLabelFontColor;
  $currentDiagramFontSize = $fontSize = ReplaceAutomatic[tickLabelFontSize, fontSize];
  $fontWeight = ReplaceAutomatic[tickLabelFontWeight, fontWeight];
  $fontFamily = ReplaceAutomatic[tickLabelFontFamily, fontFamily];
  labelPosition = Left; labelSpacing = tickLabelSpacing;
  tickPrims = Map[parseFrameTick, frameTicks];

  UnpackOptions[regionLabelFontSize, regionLabelFontWeight, regionLabelFontFamily];
  $currentDiagramFontSize = $fontSize = ReplaceAutomatic[regionLabelFontSize, fontSize];
  $fontWeight = ReplaceAutomatic[regionLabelFontWeight, fontWeight];
  $fontFamily = ReplaceAutomatic[regionLabelFontFamily, fontFamily];
  labelPosition = Center; labelSpacing = 10;
  $textModifierFn = regionTextModifierFn;
  regPrims = Map[parseReg, regions];

  noneFrame = If[$fillRegions =!= {}, GrayLevel[0.99], None];
  SetAutomatic[frameColor, noneFrame];
  SetAutomatic[frameThickness, baseThickness];

  rect = Rectangle[Offset[{0, -1}, {-$w, -$h}], Offset[{0, 0}, {$w, $h}]];

  framePrims = If[halfFrame,
    nw =                 {-$w,  $h};  ne =                 {$w,  $h};
    sw = Offset[{0, -1}, {-$w, -$h}]; se = Offset[{0, -1}, {$w, -$h}];
    Style[Line[{ne, nw, sw, se}], frameColor, AbsoluteThickness @ frameThickness]
  ,
    Style[rect, FaceForm @ None, EdgeForm @ {frameColor, AbsoluteThickness @ frameThickness}]
  ];
  If[frameColor === None, framePrims = Nothing];

  background = If[backgroundColor === None, Nothing,
    Style[rect, FaceForm @ toRegionColor @ backgroundColor, EdgeForm @ None]
  ];

  hasVerticalLabels = hasBottomLabels || hasTopLabels;
  SetAutomatic[imagePadding, 2];

  imagePadding //= StandardizePadding;
  {{padl, padr}, {padb, padt}} = imagePadding;
  If[hasVerticalLabels, padb = Max[padb, 22]; padt = Max[padt, 22]];
  If[hasLeftLabels, padl = Max[padl, 25]];
  If[hasRightLabels, padr = Max[padr, 25]];
  imagePadding = {{padl, padr}, {padb, padt}};

  totalPadding = Map[Total, imagePadding];
  If[NumericQ[imageSize], imageSize *= {1, $h/$w}];
  origHeight = PN @ imageSize;
  imageSize += totalPadding;
  {imageWidth, imageHeight} = imageSize;
  bottomPadding = Part[imagePadding, 2, 1];
  baselinePosition = Scaled[(bottomPadding + origHeight/2 - 8) / imageHeight];

  inlineOptions = SeqDropOptions[{Background, ColorRules}][opts];
  graphics = Graphics[
    {AbsolutePointSize[5 + nodeEdgeThickness],
     inlineOptions, background,
     {AbsoluteThickness[wireThickness], wirePrims}, regPrims,
     framePrims, boxPrims, tickPrims},
    If[epilog =!= {}, Epilog -> epilog, Seq[]],
    ImageSize -> imageSize,
    PlotRange -> {{-$w, $w}, {-$h, $h}},
    PlotRangeClipping -> False,
    PlotRangePadding -> 0,
    ImagePadding -> imagePadding,
    BaselinePosition -> baselinePosition
  ];

  If[$fillRegions =!= {},
    graphics = FloodFill[(graphics /. t_Text :> {}) -> graphics, $fillRegions];
    graphics = Image[graphics, ImageSize -> ImageDimensions[graphics]/2];
  ];

  graphics
];

(**************************************************************************************************)

doFlip[pos_] := ApplyFlip[pos, {flipX, flipY}];

(**************************************************************************************************)

parseFrameTick = Case[
  pos:$NumberP -> label_ := Scope[
    p1 = {-$w, pos}; p0 = Offset[{-tickLength, 0}, p1];
    {makeLabel[label, {p0}], Line[{p0, p1}]}
  ];
  Interval[{pos1_, pos2_}] -> label_ := Scope[
    foo;
  ]
]

(**************************************************************************************************)

parseBox = Case[
  Seq[pos_, key_] := %[pos -> None, key];

  Seq[c_Customized, key_] :=
    customizedBlock[c, $wireCustomizations, %[#, key]&];

  Seq[rule:(opt:(_Symbol | _Str) -> value_) /; MatchQ[opt, $boxCustomizationKeyP], key_] := (
    $keyOff += 1;
    setGlobalsFromRules[rule, $boxCustomizations];
    Nothing
  );

  Seq[pos_ -> label_, key_] := Scope[
    $pos = ReplaceAll[maybe[p_] :> p] @ toPos @ pos;
    AssociateTo[$boxAliases, (key - $keyOff) -> $pos];
    $lastInnerLabel = None;
    res = makeBox @ label;
    If[Quiet @ StringQ[label = FormToPlainString[$lastInnerLabel]],
      AssociateTo[$boxAliases, label -> $pos]];
    res
  ];
];

(**************************************************************************************************)

$boxCustomizations = RuleDelayed[
  {NodeFrameColor | FrameColor, NodeLabelFontColor | FontColor, NodeLabelFontWeight | FontWeight,  FontSize, LabelSpacing, NodeLabelOffset | LabelOffset, NodeLabelPosition | LabelPosition, LabelBackground, NodeEdgeThickness, NodeBackground | Background, NodeSize},
  {nodeFrameColor,                                  $fontColor,                      $fontWeight, $fontSize, labelSpacing,                   labelOffset,                     labelPosition, labelBackground, nodeEdgeThickness, nodeBackground,              nodeSize}
];

$boxCustomizationKeyP = Flatten[Alternatives @@ (P1 @ $boxCustomizations)];

fsToRel[sz_] := sz / graphicsScale;

makeBox = Case[

  "WhiteDisk" := Style[Disk[$pos, 1/2], FaceEdgeForm[White, Black], EdgeForm[AbsoluteThickness[nodeEdgeThickness]]];
  "BlackDisk" := Style[Disk[$pos, 1/2], FaceEdgeForm[Black], EdgeForm[AbsoluteThickness[nodeEdgeThickness]]];

  (h:"Disk"|NodeDisk|"Box"|NodeBox)[label_, r_:Automatic, opts___Rule] := Scope[
    SetAutomatic[r, nodeSize];
    label //= $colorModifierFn;
    labelColor = extractColorFromLabel @ label;
    fc = Lookup[{opts}, FrameColor, If[ColorQ @ labelColor, OklabDarker[labelColor], ReplaceNone[boxColor, ReplaceNone[nodeFrameColor, defaultWireColor]]]];
    ef = {AbsoluteThickness[nodeEdgeThickness], fc};
    ff = Lookup[{opts}, Background, If[ColorQ @ labelColor, Lighter[labelColor, 0.9], nodeBackground]];
    List[
      Style[
        If[h ~~~ "Disk" | NodeDisk,
          Disk[$pos, fsToRel[r]/2],
          CenteredRectangle[$pos, fsToRel @ r, FilterOptions @ opts, RoundingRadius -> fsToRel[5]]
        ],
        FaceForm[ff], EdgeForm[ef]
      ],
      makeLabel[label, List @ $pos]
    ]
  ];

  c_Customized := customizedBlock[c, $boxCustomizations, %];

  ("Point"|Point)[label_]  := Scope[
    labelPosition = Which[P1[$pos] <= $w, Right, P1[$pos] >= $w, Left, True, Above];
    label //= $colorModifierFn;
    labelColor = extractColorFromLabel @ label;
    List[
      Style[Point[$pos], If[ColorQ @ labelColor, OklabDarker @ labelColor, boxColor]],
      makeLabel[label, List @ $pos]
    ]
  ];

  None := Point[$pos];

  label_ := %[$nodeShape[label]];
];


(**************************************************************************************************)

StringDiagram::badwire = "Wire specification `` is invalid."

$wireCustomizations = RuleDelayed[
  {CurveFunction, WireColor, SplitPosition, "SplitOrientation", LabelPosition, LabelSpacing, LabelOffset, LabelBackground, FontColor,   FontWeight,  FontSize},
  {curveFunction, wireColor, splitPosition,  splitOrientation,  labelPosition, labelSpacing, labelOffset, labelBackground, $fontColor, $fontWeight, $fontSize}
];

parseWire = Case[
  Seq[ue:UndirectedEdge[_, UndirectedEdge[_, _UndirectedEdge]], key_] :=
    %[ue -> {None, None, None}];

  Seq[ue:UndirectedEdge[_, UndirectedEdge[_, _]], key_] :=
    %[ue -> {None, None}, key];

  Seq[ue_UndirectedEdge, key_] :=
    %[ue -> None, key];

  Seq[UndirectedEdge[a_, UndirectedEdge[b_, c_]] -> {lbl1_, lbl2_}, key_] := Splice[{
    %[UndirectedEdge[a, b] -> lbl1, key],
    %[UndirectedEdge[b, c] -> lbl2, $keyOff -= 1; key]
  }];

  Seq[UndirectedEdge[a_, UndirectedEdge[b_, UndirectedEdge[c_, d_]]] -> {lbl1_, lbl2_, lbl3_}, key_] := Splice[{
    %[UndirectedEdge[a, b] -> lbl1, key],
    %[UndirectedEdge[b, c] -> lbl2, $keyOff -= 1; key],
    %[UndirectedEdge[c, d] -> lbl3, $keyOff -= 1; key]
  }];

  (* this 'outer' form of coloring is maybe not all that useful? will color the wire but not the label *)
  Seq[(cf:$colorFormP)[spec_], key_] := Scope[
    wireColor = StyleFormData @ cf;
    %[spec, key]
  ];

  Seq[c_Customized, key_] :=
    customizedBlock[c, $wireCustomizations, %[#, key]&];

  Seq[r:Rule[_Str | _Symbol, _], key_] := (
    $keyOff += 1;
    setGlobalsFromRules[r, $wireCustomizations];
    Nothing
  );

  Seq[UndirectedEdge[a_, b_] -> label_, key_] := Scope[
    label //= $colorModifierFn;
    sc = extractColorFromLabel @ label;
    SetNone[sc, wireColor];
    pos = toPos /@ {a, b};
    x = First[DeleteCases[_maybe] @ pos[[All, 1]], None];
    pos = pos /. maybe[0] :> ReplaceNone[x, 0];
    curve = curveFunction[pos];
    points = DiscretizeCurve @ curve;
    AssociateTo[$wireAliases, (key - $keyOff) -> points];
    StyleOperator[sc] @ {curve, makeLabel[label, points]}
  ];

  Seq[spec_, key_] := (Message[StringDiagram::badwire, spec]; {})
];

(**************************************************************************************************)

extractColorFromLabel = Case[
  Customized[c_, ___]              := % @ c;
  (h:$colorFormP)[_]               := StyleFormData @ h;
  GradientSymbol[_, cspec_, ___]   := OklabDarker @ HumanBlend[getGradColors @ cspec];
  e_                               := findInteriorColor[e];
];

getGradColors = Case[
  c:{_, _}               := c;
  c:{_, _} -> _          := c;
  ColorGradient[c_, ___] := c;
];

(**************************************************************************************************)

StringDiagram::nobox = "Could not find box location for ``, available names include ``, using center coordinate."
toPos = Case[
  Center                   := {0, 0};
  BottomRight              := doFlip @ {$w, -$h};
  TopRight                 := doFlip @ {$w, $h};
  side:Top|Bottom          := %[{side, maybe[0]}];
  side:Left|Right          := %[{side, 0}];
  {Bottom, i_}             := doFlip @ {i, -$h};
  {Top, i_}                := doFlip @ {i, $h};
  {Right, i_}              := doFlip @ {$w, i};
  {Left, i_}               := doFlip @ {-$w, i};
  key:(_Int | _Str) := Lookup[$boxAliases, key, Message[StringDiagram::nobox, key, Keys @ $boxAliases]; {0, 0}];
  Translate[pos_, off_]    := doFlip[off] + % @ pos;
  other_                   := doFlip @ other;
]

(**************************************************************************************************)

StringDiagram::badregion = "Region specification `` is invalid."

parseReg = Case[

  UndirectedEdge[a_, b_] -> label_ := Scope[
    wirePos = toRegPos /@ {a, b};
    meanPos = Mean[DeleteNone[#]]& /@ Transpose[wirePos];
    %[meanPos -> label]
  ];

  pos_ -> Placed[c:$colorOrInt, side:($sideP | $Coord2P)] :=
    %[(pos + Lookup[$SideToCoords, Key @ side, side]) -> c];

  pos_List -> c:$colorOrInt :=
    (addFill[pos, c]; Nothing);

  pos_List -> Placed[label_, side_] := Scope[
    label //= $colorModifierFn;
    off = Lookup[$SideToCoords, Key @ side, side];
    labelColor = extractColorFromLabel @ label;
    If[ColorQ @ labelColor, Switch[regionFilling,
      "Explicit", Null,
      "Labeled", addFill[pos + off, labelColor],
      "Unlabeled", addFill[pos + off, labelColor]; Return @ Nothing;
    ]];
    makeLabel[Placed[label, side], {pos}]
  ];

  pos_List -> label_ :=
    %[pos -> Placed[label, Center]];

  side:$sideP -> label_ :=
    With[{coords = $SideToCoords[side]},
      %[doFlip[{$w, $h} * coords] -> Placed[label, doFlip @ Replace[side, $FlipSideRules]]]
    ];

  i_Int -> label_ :=
    %[doFlip[{i, -$h}] -> Placed[label, doFlip @ Above]];

  spec_ :=
    (Message[StringDiagram::badregion, spec]; Nothing)

,
  {$sideP -> ($SidePattern|Above|Below|Center)}
]

(**************************************************************************************************)

addFill[pos_, color_] := AppendTo[$fillRegions, pos -> toRegionColor[color]];

toRegionColor[c_] := OklabLighter[ToRainbowColor @ c, .4];

(**************************************************************************************************)

StringDiagram::badregionpos = "Region position specification `` is invalid. Should be wire name or box name."

toRegPos = Case[
  Left    := doFlip @ {-$w, None};
  Right   := doFlip @ { $w, None};
  Top     := doFlip @ {None,  $h};
  Bottom  := doFlip @ {None, -$h};
  side:BottomLeft|BottomRight|TopLeft|TopRight := doFlip[{$w, $h} * Lookup[$SideToCoords, side]];
  k_ /; KeyExistsQ[$wireAliases, k] := Mean @ $wireAliases @ k;
  k_ /; KeyExistsQ[$boxAliases, k] := $boxAliases @ k;
  k_      := (Message[StringDiagram::badregionpos, k]; {0, 0});
];

(**************************************************************************************************)

$labelCustomizations = RuleDelayed[
  {LabelPosition, LabelSpacing, LabelOffset, LabelBackground, FontColor,   FontWeight,  FontSize,  FontFamily},
  {labelPosition, labelSpacing, labelOffset, labelBackground, $fontColor, $fontWeight, $fontSize, $fontFamily}
];

makeLabel[c_Customized, pos_] :=
  customizedBlock[c,$labelCustomizations, makeLabel[#, pos]&];

makeLabel[Placed[label_, side_], pos_] :=
  Scope[labelPosition = side; makeLabel[label, pos]];

makeLabel[label_, pos_] /; labelPosition === Vertical :=
  Scope[
    {miny, maxy} = MinMax @ Part[pos, All, 2];
    labelPosition = {If[miny < -$h+0.5, Bottom, Nothing], If[maxy > $h-0.5, Top, Nothing]};
    If[labelPosition === {}, labelPosition = Right];
    makeLabel[label, pos]
  ];

makeLabel[None, _] := {};

makeLabel[label_, pos_] /; labelPosition === Bottom :=
  Scope[labelPosition = Below; makeLabel[label, MinimalBy[pos, PN]]];

makeLabel[label_, pos_] /; labelPosition === Top :=
  Scope[labelPosition = Above; makeLabel[label, MaximalBy[pos, PN]]];

makeLabel[label_, pos_] /; MatchQ[labelPosition, {__Symbol}] := Block[
  {posList = labelPosition, labelPosition = None},
  makeLabel[labelPosition = #; label, pos]& /@ posList
];

makeLabel[label_, pos_] := With[{pos2 = Mean @ pos}, CenterTextVertical @ Text[
  $lastInnerLabel = label;
  $textModifierFn @ label,
  SimplifyOffsets @ Offset[
    Plus[
      labelSpacing * Replace[labelPosition, $SideToCoords],
      If[MatchQ[labelPosition, _Offset], P1 @ labelPosition, 0],
      labelOffset
    ],
    pos2
  ],
  With[{labelPos = RemoveOffsets @ labelPosition, pos3 = RemoveOffsets @ pos2},
    Switch[labelPosition,
      Right /; (P1[pos3] >=  $w), hasRightLabels = True,
      Left  /; (P1[pos3] <= -$w), hasLeftLabels = True,
      Above /; (PN[pos3]  >=  $h), hasTopLabels = True,
      Below /; (PN[pos3]  <= -$h), hasBottomLabels = True,
      True, Null
    ];
    If[ListQ[labelPos], labelPos, -Lookup[$SideToCoords, labelPosition]]
  ],
  Background -> labelBackground,
  BaseStyle -> {FontWeight -> $fontWeight, FontSize -> $fontSize, FontColor -> $fontColor, FontFamily -> $fontFamily}
]];

(**************************************************************************************************)

PublicFunction[FunctorialStringDiagram]

FunctorialStringDiagram[boxes_List, wires_List, rhsSpec_List, opts___Rule] :=
  FunctorialStringDiagram[boxes, wires, rhsSpec, {}, opts];

FunctorialStringDiagram[boxes_List, wires_List, rhsSpec_List, regions_List, opts___Rule] := Scope[
  $boxes = Append[boxes, Splice[{LabelPosition -> Right, FontWeight -> Plain}]];
  $wires = Append[wires, LabelPosition -> Right];
  $nboxes = Count[boxes, Except[$boxCustomizationKeyP -> _]];
  $rhsLen = Len[rhsSpec];
  ScanIndex1[procRhsSpec, rhsSpec];
  StringDiagram[$boxes, $wires, regions, HalfFrame -> True, opts]
];

procRhsSpec[arr_, i_] := Block[{a, b, sideArr},
  $head = Id;
  a = If[i == 1, BottomRight, $nboxes];
  b = If[i == $rhsLen, TopRight, $nboxes + 1];
  AppendTo[$wires, UndirectedEdge[a, b] -> toArr[arr]];
];

toArr = Case[
  s_Str := % @ CategoryArrowSymbol[s];
  e_       := e;
];

procRhsSpec[pos_ -> obj_, i_] := Block[
  {$head = Id},
  AppendTo[$boxes, {Right, pos} -> toObj[obj]];
  $nboxes++;
];

toObj = Case[
  (h_Symbol ? $styleFormHeadQ)[e_] := Block[{$head = h}, % @ e];
  "f"      := % @ Padded[CategoryObjectSymbol["f"], Left -> 0.12];
  s_Str := % @ CategoryObjectSymbol[s];
  e_       := "Point"[$head[e]];
]



