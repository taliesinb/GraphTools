PublicFunction[ReapGraphics]

$dbEnabled = False;

SetHoldFirst[ReapGraphics];

ReapGraphics[body_, opts___Rule] := Scope[
  $dgBag = Bag[]; $extraDg = {};
  $dbEnabled = True;
  result = body;
  debugPrims = BagPart[$dgBag, All];
  Print @ Row @ Prepend[$extraDg, Graphics[
    {FaceForm[None], EdgeForm[Opacity[0.5]], debugPrims},
    opts,
    PlotRangePadding -> Scaled[0.15],
    Frame -> True, FrameTicks -> False,
    ImageSize -> 200
  ]];
  result
];

(**************************************************************************************************)

PublicTypesettingForm[BoxesDebugForm]

DefineStandardTraditionalForm[f_BoxesDebugForm :> boxesDebugFormBoxes[f]];

boxesDebugFormBoxes[BoxesDebugForm[g_]] := Scope[
  contentBoxes = MakeBoxes @ g;
  framedContentBoxes = FrameBox[contentBoxes, FrameStyle -> GrayLevel[0.9]];
  framedContentBoxes = PaneBox[framedContentBoxes, ImageSize -> {{250, 800}, Full}];
  codeBoxes = ToBoxes @ PrettyCodeForm @ contentBoxes;
  framedCodeBoxes = FrameBox[
    StyleBox[codeBoxes, "Input", 10],
    Background -> GrayLevel[0.95], FrameStyle -> GrayLevel[0.9]
  ];
  GridBox[{{framedContentBoxes, "     ", framedCodeBoxes}}, RowAlignments -> Center]
];

(**************************************************************************************************)

PublicTypesettingForm[PrettyCodeForm]

DefineStandardTraditionalForm[f_PrettyCodeForm :> prettyCodeBoxes[f]];

prettyCodeBoxes[PrettyCodeForm[e_, opts___Rule]] := Scope[
  codeBoxes = MakeBoxes @ CompactPrettyFullForm[e, opts, CompactingWidth -> 100];
  FrameBox[
    StyleBox[codeBoxes, "Code", 10],
    Background -> GrayLevel[0.95], FrameStyle -> GrayLevel[0.9]
  ]
];

(**************************************************************************************************)

PublicFunction[SowGraphics, EchoDebugGraphics]

SetHoldAll[SowGraphics];

SowGraphics[e__] /; TrueQ[$dbEnabled] := sowDGexpr[e];
SowGraphics[__] := Null;

EchoDebugGraphics[e_] /; TrueQ[$dbEnabled] := (SowGraphics[e]; e)
EchoDebugGraphics[e_] := e;

$graphicsHead = Point | Polygon | Circle | Disk | Rectangle;
sowDGexpr = Case[
  g_Graphics                := AppendTo[$extraDg, ReplaceOptions[g, {ImageSize -> 200, Frame -> True, FrameTicks -> False}]];
  Seq[c:($ColorPattern|_Integer), p_] := % @ Style[p, EdgeForm @ ToRainbowColor @ c];
  p:$Coord2P                := % @ Point @ p;
  p:$CoordMat2P             := % @ Point @ p;
  p_                        := StuffBag[$dgBag, p];
];

(**************************************************************************************************)

PrivateSpecialFunction[VPrint]

SetHoldAllComplete[VPrint];
VPrint[args___] :=
  If[TrueQ[$verbose], Print[If[TrueQ[$dryRun], Style["> ", LightGray], ""], args]];


(**************************************************************************************************)

PrivateSpecialFunction[VMessage]

SetHoldFirst[VMessage];

(* TODO: fix case where message starts with a ``. *)
VMessage[msg_, args___] := If[TrueQ[$verbose],
  Print @@ Map[msgStyle, Riffle[StringSplit[msg, "``"], {args}]],
  Message[msg, args]
];

msgStyle[e_String | e_Integer] := Style[e, $DarkRed, Bold];
msgStyle[e_] := e;

(**************************************************************************************************)

PublicFunction[Verbosely]

SetHoldAllComplete[Verbosely]

Verbosely[e_] := Block[{$verbose = True}, e];

(**************************************************************************************************)

PublicFunction[EchoEdgeList]

EchoEdgeList = EchoFunction[EdgeList]

(**************************************************************************************************)

PublicFunction[EchoGraphicsScope, EchoGraphics]

SetHoldAllComplete[EchoGraphicsScope];
EchoGraphicsScope[e_] := Scope[
  $prims = {};
  res = e;
  n = Length[$prims]; $i = 1;
  Graphics[
    Map[{Opacity[$i++ / n], #}&, $prims],
    Frame -> True, PlotRangePadding -> Scaled[0.1]
  ];
  res
];

(**************************************************************************************************)

PrivateTypesettingBoxFunction[ToGraphicsBoxes, ToGraphics3DBoxes]

ToGraphicsBoxes[{}] := {};
ToGraphicsBoxes[e_] := Typeset`MakeBoxes[e, StandardForm, Graphics] //. $gboxSimpRules;
ToGraphics3DBoxes[e_] := Typeset`MakeBoxes[e, StandardForm, Graphics3D] //. $gboxSimpRules;

$gboxSimpRules = {InterpretationBox[b_, _] :> b, Typeset`Hold[h_] :> h};

(**************************************************************************************************)

PublicDebuggingFunction[DynamicPointGraphics]

circlePoints[2] := {{-1, 0}, {1, 0}};
circlePoints[n_] := Reverse @ CirclePoints[n];

DynamicPointGraphics[n_Integer, fn_] := Replace[
  ConstructHoldComplete[fn, \[FormalX]],
  HoldComplete[body_] :>
    DynamicModule @@ Hold[
      {\[FormalX] = circlePoints[n]},
      LocatorPane[Dynamic[\[FormalX]], Graphics[Dynamic @ body, PlotRange -> 1.1, Frame -> True, FrameTicks -> None, Axes -> None]],
      Initialization :> $PackageInitializer
    ]
];

DynamicPointGraphics[{n_Integer, specSeq__}, fn_] := With[
  {specList = {specSeq}},
  {specData = MapThread[toDynSpec, {{specSeq}, Take[$formals, Length @ specList]}]},
  {specVars = Prepend[\[FormalX]] @ Part[specData, All, 1],
   initList = Prepend[circlePoints[n]] @ Part[specData, All, 2],
   controls = Part[specData, All, 3]},
  {specSets = MapThread[SET, {specVars, initList}]},
  Replace[
    ConstructHoldComplete[fn, Sequence @@ specVars],
    HoldComplete[body_] :>
      Apply[DynamicModule, Hold[
        specSets,
        Labeled[
          LocatorPane[Dynamic[\[FormalX]], Graphics[
            Dynamic[body, TrackedSymbols :> specVars],
            PlotRange -> 1.1, Frame -> True, FrameTicks -> None, Axes -> None
          ]],
          Column[controls]
        ],
        Initialization :> $PackageInitializer
      ] /. SET -> Set]
  ]
];

$formals = {\[FormalA], \[FormalB], \[FormalC], \[FormalD], \[FormalE], \[FormalF], \[FormalD]}

toDynSpec[{min_ ? NumericQ, max_ ? NumericQ}, sym_] := {sym, Avg[min, max], Slider[Dynamic @ sym, {min, max}]};
toDynSpec[max_ ? NumericQ, sym_] := toDynSpec[{0, max}, sym];
toDynSpec[list_List, sym_] := {sym, First @ list, RadioButtonBar[Dynamic @ sym, list]};

(* DynamicPointGraphics[3, {Red, Map[Disk[#, .1] &, #]} &] *)

(**************************************************************************************************)

PublicDebuggingFunction[PrintQGStack]

$stackFile := $stackFile = TemporaryPath["stack.m"];

PrintQGStack[label_:None] := StackInhibit @ Block[
  {stack, cells},
  stack = Stack[_];
  Beep[];
  $isFirst = True;
  cells = toStackCell /@ stack;
  CreateDocument[cells, Background -> Lighter[$Blue, 0.95]];
];

(**************************************************************************************************)

SetHoldAllComplete[toStackCell];

toStackCell[HoldForm[e_]] := toStackCell @ e;

toStackCell[tssRhs:(head_Symbol[___])] /; QGSymbolQ[head] := Module[{boxes},
  boxes = clickCopyBox[lhsEchoStr @ tssRhs, Unevaluated @ tssRhs];
  Cell[
    BoxData @ boxes, "Output",
    ShowCellLabel -> False, ShowStringCharacters -> True,
    CellGroupingRules -> {"ItemGrouping", If[$isFirst, $isFirst = False; 180, 200]}, CellDingbat -> None
  ]
];

toStackCell[_] := Nothing;

(**************************************************************************************************)

SetHoldAllComplete[extractHead];

extractHead[HoldForm[e_]] := extractHead @ e;
extractHead[Catch[_, _, QuiverGeometry`Init`Macros`ThrownMessageHandler[func_Symbol]]] := HoldForm[func];
extractHead[CompoundExpression[first_, Null]] := extractHead @ first;
extractHead[head_Symbol[___]] := If[QGSymbolQ[head], HoldForm[head], Nothing];
extractHead[head_[___]] := extractHead[head];
extractHead[_] := Nothing;

QGSymbolQ[s_Symbol ? HoldAtomQ] := StringStartsQ[Context @ Unevaluated @ s, "QuiverGeometry`"] && System`Private`HasAnyEvaluationsQ[s];
QGSymbolQ[_] := False;

(**************************************************************************************************)

SetHoldAllComplete[debugStr];

debugStr[lhs_] := ToPrettifiedString[Unevaluated @ lhs, MaxDepth -> 4, MaxLength -> 24, MaxIndent -> 3]

(**************************************************************************************************)

PublicDebuggingFunction[FindDefinitionsContaining]

FindDefinitionsContaining[context_, pattern_] := Scope[
  symbols = Names[{context <> "*", context <> "**`*"}];
  Select[ContainsQ[pattern]] @ Catenate @ Map[Definitions, symbols]
]

(**************************************************************************************************)

PublicDebuggingFunction[FindMatchingDownValue]

SetHoldAllComplete[FindMatchingDownValue]

FindMatchingDownValue[head_Symbol[args___]] := Block[
  {dvs = DownValues[head], head, res},
  DownValues[head] = Append[MapIndexed[{rule, ind} |-> replaceRHS[rule, First[ind]], dvs], HoldPattern[_head] -> None];
  res = head[args];
  If[res === None, Return @ None];
  If[!IntegerQ[res], Return[$Failed]];
  Part[dvs, res]
];

replaceRHS[lhs_ :> rhs_, num_] := lhs :> num;
replaceRHS[lhs_ :> (Verbatim[Condition][rhs_, cond_]), num_] := lhs :> Condition[num, cond];
replaceRHS[_] := Nothing;

(**************************************************************************************************)

PublicDebuggingFunction[EchoGraphics]

EchoGraphics[e_] := (AppendTo[$prims, e]; e);
EchoGraphics[{x_ ? RealVectorQ, y_ ? RealVectorQ}] := (EchoGraphics @ Trans[x, y]; {x, y});
EchoGraphics[points_ ? RealMatrixQ] := (AppendTo[$prims, Point @ points]; points);

(**************************************************************************************************)

PublicDebuggingFunction[EchoDimensions]

EchoDimensions[e_] := (Echo[Row[Dimensions @ e, "\[Times]", BaseStyle -> $DarkBlue]]; e);

(**************************************************************************************************)

PublicTypesettingForm[MsgExpr]

MsgExpr[p_MsgPath] := p;
MsgExpr[e_] := ToPrettifiedString[Unevaluated @ e, MaxDepth -> 3, MaxLength -> 4, MaxIndent -> 0, FullSymbolContext -> False, CompressLargeSubexpressions -> False];
MsgExpr[e_, n_] := ToPrettifiedString[Unevaluated @ e, MaxDepth -> n, MaxLength -> 4, MaxIndent -> 0, FullSymbolContext -> False, CompressLargeSubexpressions -> False];
MsgExpr[e_, n_, m_] := ToPrettifiedString[Unevaluated @ e, MaxDepth -> n, MaxLength -> m, MaxIndent -> 0, FullSymbolContext -> False, CompressLargeSubexpressions -> False];

(**************************************************************************************************)

PublicTypesettingForm[MsgPath]

MsgPath[p_MsgFile] := p;
MsgPath[File[p_]] := MsgPath[p];
MsgPath[l_List] := Map[MsgPath, l];

MsgPath /: SystemOpen[MsgPath[s_, n_:None]] := openMsgPath[s, n];

Format[MsgPath[s_String], OutputForm] := StringJoin["\"", s, "\""];
Format[MsgPath[s_String, n_Integer], OutputForm] := StringJoin["\"", s, ":", IntegerString @ n, "\""];
MakeBoxes[MsgPath[s_String], StandardForm] := msgPathBoxes[s];
MakeBoxes[MsgPath[s_String], TraditionalForm] := msgPathBoxes[s];

MakeBoxes[MsgPath[s_String, n_Integer], StandardForm] := msgPathBoxes[s, n];
MakeBoxes[MsgPath[s_String, n_Integer], TraditionalForm] := msgPathBoxes[s, n];

msgPathBoxes[path_String, line_:None] := With[
  {type = If[StringStartsQ[path, ("http" | "https" | "git" | "file" | "ssh") ~~ ":"], "URL", Quiet @ FileType @ path]},
  {color = Switch[type, None, $LightRed, Directory, $LightBlue, File, $LightGray, "URL", $LightPurple, _, $LightRed]},
  ToBoxes @ ClickForm[
    tightColoredBoxes[If[IntegerQ[line], StringJoin[path, ":", IntegerString @ line], path], color],
    openMsgPath[path, line]
  ]
];

(**************************************************************************************************)

PrivateFunction[openMsgPath]

openMsgPath[path_String, None] := If[
  ModifierKeysPressedQ[],
  trySystemOpen @ path,
  Beep[]; CopyToClipboard @ ToString[path, InputForm]
];

openMsgPath[path_String, line_Integer] :=
  SystemOpen @ FileLine[path, line];

trySystemOpen[s_String] := Scope[
  If[StringStartsQ[s, "http://" | "https://"], Return @ SystemOpen @ s];
  If[FileExistsQ[s],                           Return @ sysOpen @ s];
  If[FileExistsQ[s = FileNameDrop @ s],        Return @ sysOpen @ s];
  If[FileExistsQ[s = FileNameDrop @ s],        Return @ sysOpen @ s];
  If[FileExistsQ[s = FileNameDrop @ s],        Return @ sysOpen @ s];
];

sysOpen[s_String] := Switch[
  FileExtension[s],
  "nb" | "m" | "wl", SystemOpen @ FileLine[s, 1],
  "mx",              SetSelectedNotebook @ CreateDocument @ TextCell[ImportMX @ s, "Input"],
  _,                 SystemOpen @ NormalizePath @ s
];

(**************************************************************************************************)

PrivateFunction[tightColoredBoxes]

tightColoredBoxes[str_String, color_] := Framed[
  Style[str, FontFamily -> "Source Code Pro", FontSize -> 10, Bold, FontColor -> Black],
  Background -> color, FrameStyle -> Darker[color, .2],
  ContentPadding -> False, RoundingRadius -> 2,
  ImageSize -> {Automatic, 16}, FrameMargins -> {{5, 5}, {0, 0}},
  BaselinePosition -> Baseline
];

(**************************************************************************************************)

PublicFunction[GoodBeep, BadBeep]

If[$OperatingSystem === "MacOSX",
GoodBeep[] := Beep[];
BadBeep[] := Run["afplay /System/Library/Sounds/Sosumi.aiff&"];
,
GoodBeep[] := Beep[];
BadBeep[] := (Beep[]; Pause[0.1]; Beep[]);
];

(**************************************************************************************************)

PrivateFunction[ModifierKeysPressedQ]

ModifierKeysPressedQ[] := $Notebooks && (CurrentValue["ModifierKeys"] =!= {});

PublicDebuggingFunction[PerformSelfLinting]

PerformSelfLinting[] := Scope[
  DeleteCases[{} | <||>] @ Association[
    "MissingPackageScopes" -> findMissingPackageScopes[],
    "SuspiciousPackageLines" -> QuiverGeometryLoader`$SuspiciousPackageLines
  ]
];

findMissingPackageScopes[] := Scope[
  privateSymbols = Names["QuiverGeometry`**`*"];
  privateSymbolNames = Last /@ StringSplit[privateSymbols, "`"];
  moduleSymbols = Select[DeleteDuplicates @ privateSymbolNames, StringEndsQ["$"]];
  moduleSymbols = Join[moduleSymbols, StringDrop[moduleSymbols, -1]];
  privateSymbolAssoc = AssociationThread[privateSymbols, privateSymbolNames];
  privateSymbolAssoc //= Select[StringLength[#] >= 4&];
  privateSymbolAssoc //= Discard[ElementQ[moduleSymbols]];
  collisionsAssoc = Select[PositionIndex[privateSymbolAssoc], Length[#] > 1&];
  collisionsAssoc //= Select[possibleMissingPackageScope];
  collisionsAssoc
]

possibleMissingPackageScope[names_] :=
  CountDistinct[ToExpression[names, InputForm, System`Private`HasAnyEvaluationsQ]] > 1;

(**************************************************************************************************)

PublicVariable[$XMLElementFormatting]

SetInitialValue[$XMLElementFormatting, True];

Unprotect[XMLElement];
MakeBoxes[el:XMLElement[_String, _List, _List], StandardForm] /; TrueQ[$XMLElementFormatting] := xmlElementBoxes[el];
Protect[XMLElement];

xmlStyleBox[b_, c1_, c2_, f_:Bold] :=
  FrameBox[StyleBox[DeployBox @ b, f], Background -> c1, FrameStyle -> c2, Alignment -> Baseline, FrameMargins -> {{5, 5}, {2, 0}}];

xmlLeafCount = Case[
  _ := 1;
  XMLElement[_, _, list_List] := 1 + Total[% /@ list];
];

xmlElementHeadBox[xml:XMLElement[str_String, attrs_List, content_], showCount_:True] := With[
  {ci = Mod[Hash @ str, 9]},
  {c1 = Part[$LightColorPalette, ci], c2 = Part[$ColorPalette, ci]},
  {lc = xmlLeafCount[xml], ec = Length @ ToList @ content},
  {ls = Which[!showCount, "", lc <= 1, "", ec == lc, lc, True, {ec, "/", lc}]},
  {b1 = xmlStyleBox[str, c1, c2]},
  {b1 = If[ls === "", b1, RowBox[{b1, " ", StyleBox[TextString[Row @ Flatten @ {"\"(", ls, ")\""}], Plain, Smaller, c2]}]]},
  If[attrs === {}, b1,
    NiceTooltipBoxes[b1, ToBoxes[Grid[Transpose[MapFirst[Map[Style[#, Bold]&], KeysValues @ attrs]], Alignment -> Left, Spacings -> {1, .5}]], 1000]
  ]
];

printXML[xml_] := Block[{$XMLElementFormatting = False}, CellPrint @ TextCell[xml, "Input"]];

xmlOpenerBox[xml_, a_, b_List] := With[
  {a1 = ClickBox[a, If[CurrentValue["ShiftKey"], printXML[xml], open$$ = !TrueQ[open$$]]]},
  {a1b = TightColumnGridBox[Prepend[b, a1]]},
  DynamicModuleBox[
    {open$$ = 1},
    DynamicBox[
      If[TrueQ @ open$$, a1b, a1],
      TrackedSymbols :> {open$$}
    ],
    DynamicModuleValues -> {open$$}
  ]
];

ClearAll[xmlElementBoxes];

xmlElementBoxes[xml:XMLElement[str_String, attrs_List, {content_} | content_String]] := With[
  {b1 = ClickBox[xmlElementHeadBox[xml, False], If[CurrentValue["ShiftKey"], printXML @ xml]]},
  TightRowGridBox[{b1, xmlElementBoxes[content]}]
];

xmlElementBoxes[xml:XMLElement[str_String, attrs_List, {}]] :=
  ClickBox[xmlElementHeadBox[xml], If[CurrentValue["ShiftKey"], printXML @ xml]];

xmlElementBoxes[xml:XMLElement[str_String, attrs_List, content_List]] := With[
  {b1 = xmlElementHeadBox[xml]},
  xmlOpenerBox[xml,
    b1,
    Map[TightRowGridBox[{TemplateBox[{5}, "Spacer1"], xmlElementBoxes[#]}]&, content]
  ]
];

xmlElementBoxes[s2_String] := With[{s = StringTrim @ s2}, ClickBox[
  xmlStyleBox[ToBoxes @ If[StringLength[s] > 20, StringTake[s, 20] <> "\[Ellipsis]", s], GrayLevel[0.9], $Gray, Plain],
  If[CurrentValue["ShiftKey"], printXML[s]]
]];

xmlElementBoxes[o_] := "?";