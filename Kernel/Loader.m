Begin["GraphToolsPackageLoader`Private`"];

(*************************************************************************************************)

(* we will immediately resolve these system symbols, which will take care of the vast majority of Package`PackageSymbol cases *)
$coreSymbols = {
  (* package symbols: *) Package`Package, Package`PackageExport, Package`PackageScope, Package`PackageImport,
  (* system symbols: *) True, False, None, Automatic, Inherited, All, Full, Indeterminate, Null, $Failed, Span, UpTo,
  (* object heads: *)
    Symbol, Integer, String, Complex, Real, Rational,
    List, Association, Image, SparseArray, Rasterize,
    Graph, Rule, RuleDelayed, TwoWayRule, DirectedEdge, UndirectedEdge,
  (* system function: *)
    Map, Scan, MapAt, MapIndexed, MapThread, Apply, Fold, FoldList, FixedPoint, Riffle,
    Composition, Function, Identity, Construct, Slot,
    Tuples, Subsets, Permutations,
    AppendTo, PrependTo, AssociateTo, ApplyTo, Normal,
    Sort, Reverse, SortBy, GroupBy, GatherBy, Ordering, Count, Counts, CountsBy, DeleteDuplicates, DeleteDuplicatesBy,
    Head, First, Last, Rest, Most, Part, Extract, Select, SelectFirst, Cases, FirstCase, Pick, Gather, Split, Partition, DeleteCases, Transpose, RotateLeft, RotateRight,
    Position, FirstPosition,
    Length, Dimensions, Prepend, Append, Take, Drop, Join, Catenate, Flatten, Union, Intersection, Complement, Range, Insert, Delete,
    Replace, ReplacePart, ReplaceAll, ReplaceRepeated,
    StringJoin, StringTake, StringDrop, StringCases, StringLength, TextString, StringTrim, StringReplace, StringRiffle, Characters, StringSplit, StringInsert, StringDelete, StringPadLeft, StringPadRight,
    RegularExpression, StringExpression, StartOfString, EndOfString, NumberString,
    Keys, KeyTake, KeyDrop, KeySort, Values, Key, AssociationMap, AssociationThread, AssociationQ, Lookup, KeyMap, KeyValueMap, Thread, Dispatch,
    PositionIndex, Merge,
    Options, OptionsPattern, OptionValue, SetOptions,
    AllTrue, AnyTrue, NoneTrue,
    StringQ, AssociationQ, ListQ, IntegerQ, FailureQ, VectorQ, MatrixQ, ArrayQ, NumberQ, GraphQ, NumericQ, BooleanQ,
    FreeQ, MemberQ, MatchQ, SameQ, UnsameQ, Equal, TrueQ, MissingQ,
    StringMatchQ, StringFreeQ, StringContainsQ, StringStartsQ, StringEndsQ, DuplicateFreeQ,
    And, Or, Not, EqualTo, Greater, GreaterThan, Less, LessThan, LessEqual, LessEqualThan, GreaterEqual, GreaterEqualThan, Between, Positive, Negative, NonNegative,
    If, While, Which, Do, Switch, Return, Throw, Catch, Break, Continue, Table, ConstantArray,
    IdentityMatrix, UnitVector, Transpose, ArrayFlatten, ArrayReduce, ArrayReshape, Inverse, RotationMatrix,
    Repeated, Verbatim, HoldPattern, Condition, RuleCondition, Except, PatternTest, Alternatives,
    Hold, HoldComplete, Sequence, Splice,
    Message, MessageName, Echo, EchoTiming, EchoFunction, Quiet, Check, General, Print, Assert,
    Sqrt, Power, Abs, Dot, Cross, Times, Plus, Minus, Subtract, Divide, Min, Max, Mod, MinMax, Floor, Ceiling, Round,
    N, Pi, Sin, Cos, Tan, Tanh, ArcTan, Re, Im, Exp, Log, Log10,
    Total, Mean, Median, Norm, Normalize, Clip, EuclideanDistance,
    Interpolation, InterpolationOrder,
    TranslationTransform, ScalingTransform, RotationTransform, TransformationMatrix, AffineTransform, GeometricTransformation,
    ImageSize, ImagePadding, ImageMargins, ContentPadding, FrameMargins, PlotRange, PlotRangePadding, PlotRangeClipping, BaseStyle, ColorFunction, ColorFunctionScaling,
    Frame, FrameTicks, Ticks, FrameStyle, FontFamily, FontWeight, FontSize, ItemSize,
    EdgeStyle, VertexStyle, EdgeShapeFunction, VertexShapeFunction, GraphLayout, DirectedEdges,
    EdgeList, VertexList, IndexGraph, VertexCount, EdgeCount, AdjacencyMatrix, Subgraph, PathGraph, GraphPlot, Graph3D,
    Style, Labeled, Tooltip, Framed, Legended, Placed,
    StyleBox, TooltipBox, FrameBox,
    Row, Column, Grid, SpanFromLeft, SpanFromAbove, SpanFromBoth, TextAlignment, Baseline, BaselinePosition, Alignment, AlignmentPoint, Spacings, Dividers,
    RowBox, GridBox,
    Graphics, Graphics3D, GraphicsGroup, GraphicsComplex, Raster,
    GraphicsBox, Graphics3DBox, GraphicsGroupBox, GraphicsComplexBox, RasterBox,
    Subscript, Superscript, Subsuperscript, UnderBar, OverBar,
    SubscriptBox, Superscript, SubsuperscriptBox,
    RGBColor, GrayLevel, Hue, CMYKColor, XYZColor, LABColor, LCHColor, LUVColor, ColorConvert, Lighter, Darker,
    (* Red, Green, Blue, Yellow, Orange, Brown, Purple, Pink, Cyan, Magenta, Black, White, LightGray, Gray,
    LightRed, LightGreen, LightBlue, LightYellow, LightOrange, LightBrown, LightPurple, LightPink, LightCyan, LightMagenta, *)
    Opacity, Directive, Thickness, AbsoluteThickness, PointSize, AbsolutePointSize, Offset, Scaled, EdgeForm, FaceForm,
    AspectRatio,
    Inset, Translate, Rotate, Annotate, Annotation, Text,
    InsetBox, RotationBox, GeometricTransformationBox, GeometricTransformation3DBox, TextBox, Text3DBox,
    Left, Right, Above, Below, Before, After, Center, Top, Bottom,
    Tiny, Small, Medium, Large,
    Line, Circle, Rectangle, Triangle, Disk, Point, Polygon, Arrow, Arrowheads, BezierCurve, BSplineCurve, JoinedCurve, FilledCurve,
    LineBox, CircleBox, RectangleBox, DiskBox, PointBox, PolygonBox, ArrowBox, BezierCurveBox, BSplineCurveBox, JoinedCurveBox, FilledCurveBox,
    HalfLine, InfiniteLine, InfinitePlane,
    Sphere, Tube, Cuboid, Cylinder, Cone, Polyhedron,
    SphereBox, TubeBox, CuboidBox, CylinderBox, ConeBox,
    ViewCenter, ViewVector, ViewPoint, ViewMatrix, ViewProjection, ViewAngle,
    MakeBoxes, ToBoxes, Format, TraditionalForm, StandardForm, RawBoxes, NumberForm, EngineeringForm, InputForm,
    SymbolName, Names,
    Attributes, SetAttributes, Protect, Unprotect, Clear, ClearAll,
    DownValues, UpValues, SubValues, Set, SetDelayed,
    Flat, OneIdentity, HoldFirst, HoldRest, HoldAll, HoldAllComplete,
  (* system scopes: *) With, Block, Module,
  (* general utilities; *)
  GeneralUtilities`Scope, GeneralUtilities`ContainsQ, GeneralUtilities`ScanIndexed,
  GeneralUtilities`DeclareArgumentCount, GeneralUtilities`Match, GeneralUtilities`MatchValues,
  GeneralUtilities`ReturnFailed, GeneralUtilities`UnpackOptions
};

$coreSymbols = Sort @ DeleteDuplicates @ $coreSymbols;

$coreSymbolNames = SymbolName /@ $coreSymbols;

toRegexPattern["$Failed"] := "(\\$Failed)";
toRegexPattern[str_] := "(" <> str <> ")";
$coreSymbolRegex = RegularExpression @ StringJoin @ Riffle[Map[toRegexPattern, Sort @ $coreSymbolNames], "|"];

$coreSymbolAssociation = AssociationThread[$coreSymbolNames, $coreSymbols];

(*************************************************************************************************)

SetAttributes[ResolvedSymbol, HoldAllComplete];
makeResolvedSymbol[name_String] := ToExpression[name, InputForm, ResolvedSymbol];

$lowerCaseSymbolRegex = RegularExpression["[$]?[a-z]"];

$initialSymbolResolutionDispatch = Dispatch[{
  (* Package`PackageSymbol[name_String] /; StringStartsQ[name, $lowerCaseSymbolRegex] :> RuleCondition[makeResolvedSymbol[name]], *)
  Package`PackageSymbol["SetUsage"][usageString_String] :> RuleCondition[rewriteSetUsage[usageString]],
  Package`PackageSymbol[name_String] /; StringMatchQ[name, $coreSymbolRegex] :> RuleCondition[$coreSymbolAssociation[name]],
  Package`PackageSymbol[name_String] /; StringContainsQ[name, "`"] :> RuleCondition[makeResolvedSymbol[name]]
}];

(* this means SetUsage doesn't have to resolve the symbol later, which is expensive. *)
rewriteSetUsage[usageString_String] := Scope[
  symbolName = StringCases[usageString, StartOfString ~~ WhitespaceCharacter... ~~ name:(Repeated["$", {0, 1}] ~~ WordCharacter..) :> name, 1];
  symbolName = First[symbolName, None];
  If[symbolName === None,
    Package`PackageSymbol["SetUsage"][usageString],
    Package`PackageSymbol["SetUsage"][Package`PackageSymbol[symbolName], usageString]
  ]
];

fileStringUTF8[path_] := ByteArrayToString @ ReadByteArray @ path;

failRead[] := Throw[$Failed, failRead];

$fileContentCache = Data`UnorderedAssociation[];

readPackageFile[path_, context_] := Module[{cacheEntry, fileModTime, contents},
  {cachedModTime, cachedContents} = Lookup[$fileContentCache, path, {$Failed, $Failed}];
  fileModTime = UnixTime @ FileDate[path, "Modification"];
  If[FailureQ[cachedContents] || cachedModTime =!= fileModTime,
    contents = loadFileContents[path, context];
    $fileContentCache[path] = {fileModTime, contents};
  ,
    contents = cachedContents;
  ];
  contents
];

loadFileContents[path_, context_] := Module[{str, contents},
  str = fileStringUTF8 @ path;
  contents = Quiet @ Check[Package`ToPackageExpression @ str, $Failed];
  If[FailureQ[contents], handleSyntaxError[path]];
  Block[{$Context = context}, contents = contents /. $initialSymbolResolutionDispatch /. ResolvedSymbol[sym_] :> sym];
  contents
];

handleSyntaxError[path_] := Scope[
  errors = GeneralUtilities`FindSyntaxErrors[path];
  Beep[];
  If[errors =!= {},
    Print["Aborting; syntax errors:"];
    Scan[Print, Take[errors, UpTo[5]];
    SystemOpen @ Part[errors, 1, 1]];
  ];
  failRead[];
];

filePathToContext[path_] := Block[{str, subContext, contextList},
  str = StringTrim[StringDrop[path, $mainPathLength], ".m" | ".wl"];
  str = StringTrim[str, $PathnameSeparator];
  If[StringEndsQ[str, "Main"], str = StringDrop[str, -4]];
  contextList = Developer`ToList[$trimmedMainContext, FileNameSplit @ str];
  StringJoin[{#, "`"}& /@ contextList]
];

toSymbolReplacementRule[name_, ResolvedSymbol[sym_]] :=
  Package`PackageSymbol[name] :> sym;

createSymbolsInContextAndDispatchTable[names_, context_, contextPath_] := Block[
  {$Context = context, $ContextPath = contextPath, rules},
  Dispatch @ MapThread[toSymbolReplacementRule, {names, ToExpression[names, InputForm, ResolvedSymbol]}]
];

addPackageCasesToBag[bag_, expr_, rule_] :=
  Internal`StuffBag[bag, Cases[expr, rule, {2}], 1];

resolveRemainingSymbols[{path_, context_, packageData_Package`PackageData}] := Scope[
  unresolvedNames = DeepUniqueCases[packageData, Package`PackageSymbol[name_] :> name];
  dispatch = createSymbolsInContextAndDispatchTable[unresolvedNames, context, $globalImports];
  {path, context, packageData /. dispatch}
];

GraphToolsPackageLoader`ReadPackages[mainContext_, mainPath_] := Block[
  {$directory, $files, $packageScopes, $packageExports, $packageExpressions, $packageRules,
   $mainContext, $trimmedMainContext, $mainPathLength, $exportRules, $scopeRules, result
  },

  Construct[ClearAll, mainContext <> "*", mainContext <> "**`*"];

  $directory = AbsoluteFileName @ ExpandFileName @ mainPath;
  $mainContext = mainContext;
  $mainPathLength = StringLength[$directory];
  $trimmedMainContext = StringTrim[mainContext, "`"];

  $filesToSkip = FileNames[{"Loader.m", "init.m"}, $directory];
  $files = Sort @ Complement[FileNames["*.m", $directory], $filesToSkip];

  $globalImports = {"System`", "GeneralUtilities`"};

  $packageExports = Internal`Bag[];
  $packageScopes = Internal`Bag[];

  result = Catch[
    $packageExpressions = Map[
      path |-> Block[{expr, context},
        context = filePathToContext @ path;
        expr = readPackageFile[path, context];
        addPackageCasesToBag[$packageExports, expr, Package`PackageExport[name_String] :> name];
        addPackageCasesToBag[$packageScopes, expr, Package`PackageScope[name_String] :> name];
        {path, context, expr}
      ],
      $files
    ];
  ,
    failRead
  ];
  If[result === $Failed, Return[$Failed]];

  $packageExports = DeleteDuplicates @ Internal`BagPart[$packageExports, All];
  $packageScopes = DeleteDuplicates @ Internal`BagPart[$packageScopes, All];

  $exportDispatch = createSymbolsInContextAndDispatchTable[$packageExports, $mainContext, {}];
  $scopeDispatch = createSymbolsInContextAndDispatchTable[$packageScopes, $mainContext <> "PackageScope`", {}];

  $packageExpressions = $packageExpressions /. $exportDispatch /. $scopeDispatch;

  $packageExpressions //= Map[resolveRemainingSymbols];

  $packageExpressions
];

failEval[] := Throw[$Failed, failEval];

GraphToolsPackageLoader`EvaluatePackages[packagesList_List] := Block[
  {$currentPath, $currentLineNumber, result},
  $currentPath = ""; $currentLineNumber = 0;
  GraphToolsPackageLoader`$FileTimings = <||>;
  GraphToolsPackageLoader`$FileLineTimings  = <||>;
  result = Quiet @ Catch[
    GeneralUtilities`WithMessageHandler[
      Scan[evaluatePackage, packagesList],
      handleMessage
    ]
  ,
    failEval
  ];
  result
];

SetAttributes[evaluateExpression, HoldAllComplete];

MakeBoxes[pd_Package`PackageData, StandardForm] :=
  RowBox[{"PackageData", StyleBox[RowBox[{"[", Length[pd], "]"}], Background -> LightRed]}];

evaluatePackage[{path_, context_, packageData_Package`PackageData}] := (
  $currentPath = path; $currentFileLineTimings = <||>;
  GraphToolsPackageLoader`$FileTimings[path] = First @ AbsoluteTiming[
    Scan[evaluateExpression, packageData];
  ];
  GraphToolsPackageLoader`$FileLineTimings[path] = $currentFileLineTimings;
);

evaluateExpression[{lineNumber_, expr_}] := (
  $currentLineNumber = lineNumber;
  $currentFileLineTimings[lineNumber] = First @ AbsoluteTiming[{expr}];
);

handleMessage[f_Failure] := Scope[
  Beep[];
  fileLine = GeneralUtilities`FileLine[$currentPath, $currentLineNumber];
  Print["Aborting; message ", HoldForm @@ f["HeldMessageTemplate"], " occurred at ", fileLine];
  Print[FailureString @ f];
  SystemOpen[fileLine];
  failEval[]
];

(*************************************************************************************************)

$directory = DirectoryName[$InputFileName];

GraphToolsPackageLoader`Read[] :=
  GraphToolsPackageLoader`ReadPackages["GraphTools`", $directory];

GraphToolsPackageLoader`Load[] := Scope[
  packages = GraphToolsPackageLoader`Read[];
  If[FailureQ[packages], ReturnFailed[]];
  GraphToolsPackageLoader`$LoadCount++;
  GraphToolsPackageLoader`EvaluatePackages @ packages
];

GraphToolsPackageLoader`$LoadCount = 0;

End[];
