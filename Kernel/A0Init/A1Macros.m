With[{fmv := GeneralUtilities`Control`PackagePrivate`findMutatedVariables},
  If[FreeQ[DownValues[fmv], ApplyTo],
    DownValues[fmv] = Insert[
      DownValues[fmv],
      Unevaluated @ ApplyTo[GeneralUtilities`Control`PackagePrivate`lhs_Symbol, _],
      {1, 2, 1, 1, 2, 1, 1, 2}
    ]
  ];
];

Unprotect[MapColumn]
MapColumn[f_, n_][expr_] := MapColumn[f, n, expr];
Protect[MapColumn];

(**************************************************************************************************)

PublicDebuggingFunction[EchoScope]

DefineMacro[EchoScope,
EchoScope[body_] := mEchoScope[body, {}],
EchoScope[body_, defs__] := mEchoScope[body, {defs}]
];

SetHoldAllComplete[mEchoScope];

mEchoScope[body_, defs_] := Module[{},
  hold = HoldComplete[iLabeledEchoSet[Null, $LHS, body], defs, Block] /. Set -> EchoSet;
  mScopeWithDefs @@ hold
];

(**************************************************************************************************)

PublicFunction[DefinitionHead]

DefinitionHead[(Rule|RuleDelayed|SetDelayed)[lhs_, _]] := PatternHead[lhs];

(**************************************************************************************************)

(* add ability for Scope to take additional arguments, which are local function definitions. if these
use arguments of original function they will still work, via a suitable Block and alias *)

Unprotect[Scope];
DefineMacro[Scope,
Scope[body_] := GeneralUtilities`Control`PackagePrivate`mScope[body, Block],
Scope[body_, defs__] := mScopeWithDefs[body, {defs}, Block]
];
Protect[Scope];

SetHoldAllComplete[mScopeWithDefs, procScopeDef, quotedSetDelayed, nocontextName];

$privScope = "QuiverGeometry`Private`";

mScopeWithDefs[body_, {}, type_] :=
  GeneralUtilities`Control`PackagePrivate`mScope[body, type];

mScopeWithDefs[body2_, defs2_, type_] := Module[
  {lhsHeadPrefix, lhsSymbolP, aliasSymbols, held, aliasRules, body, defs},
  lhsHeadPrefix = StringJoin[$privScope, Replace[$LHSHead, Quoted[s_] :> SymbolName[Unevaluated @ s]], "$"];
  body = Quoted[body2]; defs = Hold[defs2];
  lhsSymbolP = Compose[HoldPattern, Alternatives @@ $LHSPatternSymbols] /. Quoted[q_] :> q;
  aliasRules = DeleteDuplicates @ DeepCases[defs, s:lhsSymbolP :> HoldPattern[s]];
  aliasRules = # -> Apply[GeneralUtilities`Control`PackagePrivate`toAliasedSymbol, #]& /@ aliasRules;
  body = body /. aliasRules;
  defs = defs /. aliasRules;
  Block[{$lhsHeadPrefix = lhsHeadPrefix, $bodyRules = {}},
    defs = Apply[procScopeDef, defs //. Quoted[q_] :> q];
    body = body /. $bodyRules;
    evalSecondaryDefs @ defs;
  ];
  If[aliasRules =!= {}, body = ToQuoted[Block, toAliasSet /@ aliasRules, body]];
  GeneralUtilities`Control`PackagePrivate`mScope @@ Append[body, type]
];

toAliasSet[_[s_]-> a_] := Quoted @ Set[a, s];

procScopeDef[list_List] := Map[procScopeDef, Unevaluated @ list];

procScopeDef[r_RuleDelayed | r_Rule] := AppendTo[$bodyRules, r];

procScopeDef[SetDelayed[lhs:(head_Symbol | (head_Symbol[___]) | ((head_Symbol)[___][___])), rhs_]] := With[
  {head2 = Symbol @ StringJoin[$lhsHeadPrefix, SymbolName @ Unevaluated @ head]},
  {rule = HoldPattern[head] -> head2},
  AppendTo[$bodyRules, rule];
  ReplaceAll[Hold[lhs, rhs], rule]
];

procScopeDef[e_] := Print["Invalid secondary definition: ", Hold[e]];

evalSecondaryDefs[Null] := Null;
evalSecondaryDefs[e_List] := Map[evalSecondaryDefs, e];
evalSecondaryDefs[h_Hold] := SetDelayed @@ ReplaceAll[h, $bodyRules];

(**************************************************************************************************)

(* fix a bug in IndexOf, which accidentally didn't limit itself to level one *)
With[{io := GeneralUtilities`IndexOf},
  Unprotect[io];
  If[FreeQ[DownValues[io], {1}],
    DownValues[io] = ReplaceAll[
      DownValues[io],
      HoldPattern[FirstPosition][a_, b_, c_, Heads -> False] :>
        FirstPosition[a, b, c, {1}, Heads -> False]
    ];
  ];
  Protect[io];
];

With[{mdn := GeneralUtilities`Debugging`PackagePrivate`makeDefinitionNotebook},
  DownValues[mdn] = ReplaceAll[DownValues[mdn], {
    Rule[WindowSize, {600, Automatic}] -> Rule[WindowSize, {1200, Automatic}]
  }];
];

(**************************************************************************************************)

GeneralUtilities`Control`PackagePrivate`upperCaseString[s_Str] /; StringStartsQ[s, "$"] :=
  GeneralUtilities`Control`PackagePrivate`upperCaseString[StringDrop[s, 1]];

(**************************************************************************************************)

Module[{desugaringRules = Normal @ GeneralUtilities`Control`PackagePrivate`$DesugaringRules},
  If[FreeQ[desugaringRules, rewriteDestructuringFunction],
    AppendTo[desugaringRules, HoldPattern[GeneralUtilities`Control`PackagePrivate`e:Fn[{___, _List, ___}, _]] :>
      RuleCondition[rewriteDestructuringFunction[GeneralUtilities`Control`PackagePrivate`e]]];
    GeneralUtilities`Control`PackagePrivate`$DesugaringRules = Dispatch @ desugaringRules;
  ];
];

SetHoldAllComplete[rewriteDestructuringFunction, procDestructArg];

rewriteDestructuringFunction[Fn[args_, body_]] := Block[
  {$destructAliases = {}, $i = 1},
  ToQuoted[Fn,
    Map[procDestructArg, Unevaluated @ args],
    Quoted[body] /. Flatten[$destructAliases]
  ]
];

rewriteDestructuringFunction[e_] := Quoted[e];
 
procDestructArg[e_Symbol] := Quoted[e];

procDestructArg[argSpec_] := With[
  {symbolPos = Position[Unevaluated @ argSpec, _Symbol, {0, Infinity}, Heads -> False]},
  If[symbolPos === {},
    Symbol["QuiverGeometry`Private`$$" <> IntegerString[$i++]]
  ,
    With[{parentSym = Symbol[Extract[Unevaluated @ argSpec, P1 @ symbolPos, HoldSymbolName] <> "$$"]},
      AppendTo[$destructAliases, Map[
        pos |-> If[Len[pos] === 1,
          With[{p1 = P1 @ pos}, Extract[Unevaluated @ argSpec, pos, HoldPattern] :> Part[parentSym, p1]],
          Extract[Unevaluated @ argSpec, pos, HoldPattern] :> Extract[parentSym, pos]
        ],
        symbolPos
      ]];
      parentSym
    ]
  ]
]

(**************************************************************************************************)

PublicDebuggingFunction[Echoing]

Echoing /: (lhs_ := Echoing[rhs_]) := EchoSetDelayed[lhs, rhs];

(**************************************************************************************************)

PublicDebuggingFunction[LabeledEchoSet]

Attributes[LabeledEchoSet] = {HoldAll, SequenceHold};

LabeledEchoSet[label_, esLhs_, esRhs_] := Set[esLhs, iLabeledEchoSet[label, esLhs, esRhs]];

Unprotect[EchoSet];
ClearAll[EchoSet];
Attributes[EchoSet] = {HoldAll, SequenceHold};
EchoSet[var_, rhs_] := Set[var, iLabeledEchoSet[Null, $multiES[var], rhs]];
EchoSet[var1_, EchoSet[var2_, rhs_]] := Set[var1, Set[var2, iLabeledEchoSet[Null, $multiES[var1, var2], rhs]]];
EchoSet[var1_, EchoSet[var2_, EchoSet[var3_, rhs_]]] := Set[var1, Set[var2, Set[var3, iLabeledEchoSet[Null, $multiES[var1, var2, var3], rhs]]]];
EchoSet[var1_, EchoSet[var2_, EchoSet[var3_, EchoSet[var4_, rhs_]]]] := Set[var1, Set[var2, Set[var3, Set[var4, iLabeledEchoSet[Null, $multiES[var1, var2, var3, var4], rhs]]]]];
EchoSet[var1_, EchoSet[var2_, EchoSet[var3_, EchoSet[var4_, EchoSet[var5_, rhs_]]]]] := Set[var1, Set[var2, Set[var3, Set[var4, Set[var5, iLabeledEchoSet[Null, $multiES[var1, var2, var3, var5], rhs]]]]]];
Protect[EchoSet];

(**************************************************************************************************)

PublicDebuggingFunction[EchoSetDelayed, LabeledEchoSetDelayed]

Attributes[EchoSetDelayed] = {HoldAll, SequenceHold};
Attributes[LabeledEchoSetDelayed] = {HoldRest, SequenceHold};

EchoSetDelayed[lhs_, rhs_] := LabeledEchoSetDelayed[Null, lhs, rhs];

LabeledEchoSetDelayed[label_, esdLhs_, esdRhs_] := SetDelayed[(esdLhsVar:esdLhs), iLabeledEchoSet[label, esdLhsVar, esdRhs]];

(**************************************************************************************************)

$esdTab = 0;
$pendingEchoPrint = None;
$callStack = Repeat[Null, 512];

Attributes[iLabeledEchoSet] = {HoldAllComplete};

iLabeledEchoSet[label_, esdLhsVar_, esdRhs_] := Module[
  {esdLhsStr, esdLhsBoxes, esdResult = $UNSET, esdRhsStr, esdRhsBoxes, arrowStr},
  WithLocalSettings[
    esdLhsStr = lhsEchoStr @ esdLhsVar;
    arrowStr = If[MatchQ[Unevaluated @ esdLhsVar, _$multiES], " = ", "\[Function]"];
    If[$pendingEchoPrint =!= None,
      Apply[printEchoCell, $pendingEchoPrint];
      $pendingEchoPrint = None;
    ];
    Part[$callStack, Max[$esdTab + 1, 1]] = Replace[Apply[HoldForm, PatternHead @ esdLhsVar], HoldForm[$multiES] -> Set];
    esdLhsBoxes = clickCopyBox[esdLhsStr, Unevaluated @ esdLhsVar];
    (* If[label =!= Null, esdLhsStr = TextString[label] <> ": " <> esdLhsStr]; *)
    $pendingEchoPrint = {RowBox[{esdLhsBoxes, arrowStr}], $openColor, $esdTab, label};
    $esdTab++;
  ,
    esdResult = If[$esdTab < 16, esdRhs, esDepthExceeded[]]
  ,
    $esdTab--;
    esdRhsStr = rhsEchoStr @ esdResult;
    esdRhsBoxes = clickCopyBox[esdRhsStr, esdResult];
    If[$pendingEchoPrint === None,
      printEchoCell[RowBox[{arrowStr, esdRhsBoxes}], $closeColor, $esdTab, label];
    ,
      esdRhsBoxes = RowBox[{esdLhsBoxes, StyleBox[arrowStr, Bold], esdRhsBoxes}];
      printEchoCell[esdRhsBoxes, $openCloseColor, $esdTab, label];
    ];
    $pendingEchoPrint = None;
  ]
];

General::callDepthExceeded = "Depth exceeded, aborting. Call stack: ``.";
General::tooManyEchos = "Too many echos, aborting. Call stack: ``.";

esDepthExceeded[] := (
  Message[General::callDepthExceeded, callStackString[]];
  Abort[];
)

tooManyEchos[] := (
  Message[General::tooManyEchos, callStackString[]];
  $totalEchos = 0;
  Abort[];
);

callStackString[] := TextString @ Row[
  Replace[
    If[$esdTab < 10,
      Take[$callStack, $esdTab],
      Join[Take[$callStack, 6], {"\[Ellipsis]"}, Part[$callStack, {$esdTab-2, $esdTab}]]
    ],
    HoldForm[sym_] :> SymbolName[Unevaluated @ sym],
    {1}
  ],
  ", "
];

(**************************************************************************************************)

PrivateFunction[lhsEchoStr, clickCopyBox]

clickCopyBox[str_, expr_] := ClickBox[str, CopyToClipboard[Unevaluated @ ExpressionCell[expr, "Input"]]];

$word = RegularExpression["[a-zA-Z`$0-9]+"];

Attributes[lhsEchoStr] = {HoldAllComplete};
Attributes[symbolStr] = {HoldAllComplete};

symbolStr[a_Symbol] := HoldSymbolName[a];
symbolStr[other_] := ToPrettifiedString[Unevaluated @ other, MaxDepth -> 4, MaxLength -> 24, MaxIndent -> 3, FullSymbolContext -> False];

lhsEchoStr[$multiES[a_]] := symbolStr[a];
lhsEchoStr[$multiES[a_, b__]] := StringJoin[symbolStr[a], " = ", lhsEchoStr[$multiES[b]]];

lhsEchoStr[lhs_] := Block[{res},
  res = ToPrettifiedString[Unevaluated @ lhs, MaxDepth -> 4, MaxLength -> 24, MaxIndent -> 3, FullSymbolContext -> False];
  If[StringMatchQ[res, $word ~~ "[" ~~ ___ ~~ "]"],
    {head, rest} = StringSplit[res, "[", 2];
    If[StringContainsQ[head, "`"], head = PN @ StringSplit[head, "`"]];
    RowBox[{StyleBox[head, Bold], "[", StringDrop[rest, -1], "]"}]
  ,
    res
  ]
];

$openColor := $openColor = Lighter[$Green, 0.95];
$closeColor := $closeColor = Lighter[$Orange, 0.95];
$openCloseColor := $openCloseColor = Lighter[$Purple, 0.95];

(**************************************************************************************************)

rhsEchoStr[$UNSET] := "?";
rhsEchoStr[$DEPTHEXCEEDED] = "!";
rhsEchoStr[rhs_] := ToPrettifiedString[Unevaluated @ rhs, MaxDepth -> 4, MaxLength -> 64, MaxIndent -> 3, FullSymbolContext -> False];

(**************************************************************************************************)

PrivateFunction[printEchoCell]

$currentEchoWindow = None;
$currentEchoLine = 0;
$totalEchos = 0;

printEchoCell[boxes_, color_,  tab_, label_] := Module[{cell, label2},
  If[$totalEchos++ > 256, tooManyEchos[]];
  If[tab > 10, Return[]];
  label2 = If[label =!= Null && label =!= None, TextString[label], None];
  cell = Cell[BoxData @ boxes, "Echo",
    Background -> color, FontColor -> Black,
    CellMargins -> {{65 + tab * 40, Inherited}, {Inherited, Inherited}},
    CellFrameLabels -> {{None, label2}, {None, None}},
  ShowCellLabel -> False,
    ShowStringCharacters -> True,
    CellGroupingRules -> {"ItemGrouping", 100 + If[color === $closeColor, 10 * tab + 1, 10 * tab]},
    CellDingbat -> None,
    ShowGroupOpener -> True,
    CellLabelAutoDelete -> False
  ];
  EchoCellPrint @ cell
];

(**************************************************************************************************)

PublicDebuggingFunction[EchoCellPrint]

EchoCellPrint[cells2_] := Module[{cells},
  cells = ToList[cells2];
  needsNewWindow = !ValidNotebookObjectQ[$currentEchoWindow];
  If[$Line =!= $currentEchoLine || needsNewWindow,
    $currentEchoLine = $Line; $totalEchos = 0;
    If[needsNewWindow,
      $currentEchoWindow = CreateDebuggingWindow[cells, 1000, CellMargins -> 0]
    ,
      NotebookPut[Notebook[cells], $currentEchoWindow]
    ];
    SelectionMove[$currentEchoWindow, After, Notebook];
  ,
    NotebookWrite[$currentEchoWindow, cells, After]
  ];
];



(**************************************************************************************************)

PublicSpecialFunction[CreateDebuggingWindow]

CreateDebuggingWindow[cells_, w:_Int:1000, opts___Rule] := CreateDocument[cells,
  Saveable -> False, WindowTitle -> "Debugging",
  WindowSize -> {w, Scaled[1]},
  WindowMargins -> {{Automatic, 50}, {Automatic, Automatic}},
  StyleDefinitions -> $LightStylesheetPath,
  opts
]

(* TODO: fully hijack Echo, Print, Message, etc *)

(**************************************************************************************************)

PublicSpecialFunction[BadArguments]

Clear[BadArguments];
General::badarguments = "Bad arguments: ``.";

BadArguments /: (Set|SetDelayed)[lhsHead_Symbol[lhs___], BadArguments[]] :=
  SetDelayed[$LHS:lhsHead[lhs], Message[MessageName[lhsHead, "badarguments"], MsgExpr @ Unevaluated @ $LHS]; $Failed];

BadArguments /: (Set|SetDelayed)[Verbatim[Blank][lhsHead_Symbol], BadArguments[]] :=
  SetDelayed[$LHS_lhsHead, Message[MessageName[lhsHead, "badarguments"], MsgExpr @ Unevaluated @ $LHS]; $Failed];

DefineMacro[BadArguments, BadArguments[] := Quoted[Message[MessageName[$LHSHead, "badarguments"]]; Return[$Failed]]];

(**************************************************************************************************)

(* This is for the benefit of existing code that uses UnmatchedCase *)
Unprotect[UnmatchedCase];
Clear[UnmatchedCase];
UnmatchedCase[] := Panic["UnmatchedCase"];
UnmatchedCase[head_, case_] := Panic["UnmatchedCase[" <> SymbolName[head] <> "]", "``", MsgExpr @ Unevaluated @ case];

PrivateFunction[UnmatchedCase2]

General::unmatchedcase = "Case unmatched: ``";
UnmatchedCase2[head_Symbol, case_] := (
  Message[MessageName[head, "unmatchedcase"], MsgExpr @ Unevaluated @ case];
  UnmatchedCase[head, case];
);

UnmatchedCase2[head_Symbol, case___] := (
  Message[MessageName[head, "unmatchedcase"], MsgExpr @ InternalHoldForm[case]];
  UnmatchedCase[head, HoldForm[case]];
);

(**************************************************************************************************)

(* this takes the place of MatchValues in GU *)

PublicScopingFunction[Case]
PublicDebuggingFunction[EchoCase]
PublicSymbol[$]

$::usage = "$ stands for the function currently being defined."

SetHoldAll[Case, EchoCase, setupCases, setupPrefixCases];

(* TODO: fix this not working:

foo = Case[
  Seq[a_, b_] /; cond[a] := ...
]
*)

Case     /: SetDelayed[sym_Symbol[pre___],     Case[args___]] := setupCases[sym, False, Hold[pre], args];
EchoCase /: SetDelayed[sym_Symbol[pre___], EchoCase[args___]] := setupCases[sym, True,  Hold[pre], args];
Case     /: (Set|SetDelayed)[sym_Symbol,     Case[args___]]   := setupCases[sym, False, Hold[], args];
EchoCase /: (Set|SetDelayed)[sym_Symbol, EchoCase[args___]]   := setupCases[sym, True,  Hold[], args];

setupCases[a1_, a2_, a3_, arg_SetDelayed]                := setupCases[a1, a2, a3, CompoundExpression[arg], {}];
setupCases[a1_, a2_, a3_, arg_SetDelayed, rewrites_List] := setupCases[a1, a2, a3, CompoundExpression[arg], rewrites];

setupCases[a1_, a2_, a3_, CompoundExpression[args__SetDelayed, rewrites_List]] :=
  setupCases[a1, a2, a3, CompoundExpression[args], rewrites];

setupCases[sym_Symbol, echo_, pre_, CompoundExpression[args__SetDelayed, Null...], rewrites_:{}] := Module[
  {holds, counter = 0},
  holds = Hold @@@ Hold[args];
  If[pre =!= Hold[], holds //= Map[Join[pre, #]&]];
  holds = ReplaceAll[holds, procRewrites @ rewrites];
  PrependTo[holds, Hold[case___, UnmatchedCase2[sym, case]]];
  holds = ReplaceAll[holds, HoldPattern[Out[] | $]  :> sym];
  If[echo,
    Replace[List @@ holds, Hold[a___, b_] :> LabeledEchoSetDelayed[counter++, sym[a], b], {1}];
  ,
    Replace[List @@ holds, Hold[a___, b_] :> SetDelayed[sym[a], b], {1}];
  ]
];

Case::baddef = "Bad Case definition for ``."

setupCases[sym_, ___] := Message[Case::baddef, sym];

SetHoldAllComplete[procRewrites];
procRewrites[s_Symbol ? HasImmediateValueQ] := HoldPattern[s] -> s;
procRewrites[l_List] := Map[procRewrites, Unevaluated @ l];
procRewrites[a_ -> b_] := HoldPattern[a] -> b;
procRewrites[a_ :> b_] := HoldPattern[a] :> b;

SetUsage @ "
Case[rules$$] is a macro for defining functions of one variable, specifying LHS and RHS rules for the argument.
Case[rules$$, {alias$1, alias$2, $$}] applies temporary aliases to the rules$ before evaluation.
* Use the form func$ = Case[$$] to attach the rules to the function func$.
* Each of the rules should be of the form patt$ :> body$, and should be seperated by semicolons.
* The aliases can be used to transform the rules before they attached used as definitions.
* Use \[Rule] in an alias to have the RHS of the alias evaluate, and \[RuleDelayed] to perform a literal replacement.
* Aliases can be thought of as 'local macros' that make a particular function definition cleaner or more concise.
"

(**************************************************************************************************)

PublicScopingFunction[StringCase]

SetUsage @ "
StringCase[rules$$] is a macro similar to %Case but for strings."

SetHoldAll[StringCase, setupStringCases]

StringCase /: (Set|SetDelayed)[sym_Symbol[pre___], StringCase[args___]] := setupStringCases[sym, False, Hold[pre], args];
StringCase /: (Set|SetDelayed)[sym_Symbol,         StringCase[args___]] := setupStringCases[sym, False, Hold[], args];

(**************************************************************************************************)

setupStringCases[a1_, a2_, a3_, arg_SetDelayed]                := setupStringCases[a1, a2, a3, CompoundExpression[arg], {}];
setupStringCases[a1_, a2_, a3_, arg_SetDelayed, rewrites_List] := setupStringCases[a1, a2, a3, CompoundExpression[arg], rewrites];

setupStringCases[a1_, a2_, a3_, CompoundExpression[args__SetDelayed, rewrites_List]] :=
  setupStringCases[a1, a2, a3, CompoundExpression[args], rewrites];

setupStringCases[sym_Symbol, echo_, pre:Hold[preseq___], CompoundExpression[args__SetDelayed, Null...], rewrites_:{}] := Module[
  {holds, counter = 0, lhs}, With[{strVar = Symbol[QualifiedSymbolName[sym] <> "$str"]}, {strVarPatt = strVar_Str},
  holds = Hold @@@ Hold[args];
  lhs = If[pre === Hold[], Hold[sym[strVarPatt]], Hold[sym[preseq][strVarPatt]]];
  holds = ReplaceAll[holds, procRewrites @ rewrites];
  holds = ReplaceAll[holds, HoldPattern[Out[] | $]  :> sym];
  If[echo, Print["StringCase Echo not supported yet."]];
  toStringCasesReplaceExpr[lhs, strVar, Map[toStringCasesRule, List @@ holds] /. $globalSCVar -> strVar]
]];

StringCase::baddef = "Bad StringCase definition for ``."

setupStringCases[sym_, ___] := Message[StringCase::baddef, sym];

(**************************************************************************************************)

toStringCasesReplaceExpr[lhs_, var_, {rule_}] :=
  toStringCasesReplaceExpr[lhs, var, rule];

toStringCasesReplaceExpr[Hold[lhs_], var_, rules_] :=
  SetDelayed[lhs, Block[{}, StringReplace[var, rules]; None]];

(**************************************************************************************************)

toStringCasesRule[Hold[Verbatim[Pattern][globalVar_Symbol, lhs_], rhs_]] :=
  toStringCasesRule[Hold[lhs, rhs]] /. globalVar :> $globalSCVar;

toStringCasesRule[Hold[List[pattElems___], rhs_]] :=
  StringExpression[StartOfString, pattElems, EndOfString] :> Return[rhs, Block];

toStringCasesRule[Hold[StringExpression[pattElems___], rhs_]] :=
  StringExpression[StartOfString, pattElems, EndOfString] :> Return[rhs, Block];

toStringCasesRule[Hold[patt_, rhs_]] :=
  StartOfString ~~ patt ~~ EndOfString :> Return[rhs, Block];

StringCase::badrule = "Bad StringCase rule ``."

toStringCasesRule[h_Hold] := (Message[StringCase::badrule, MsgExpr[RuleDelayed @@ h]]; Nothing);

(**************************************************************************************************)

$numNames = <|1 -> "first", 2 -> "second", 3 -> "third", 4 -> "fourth"|>;

defineCheckArgMacro[checkMacro_Symbol, checker_, msgName_Str] := DefineMacro[coerceMacro,
  coerceMacro[n_] := With[
    {nthArg = Part[$LHSPatternSymbols, n], numStr = $numNames[n]},
    Quoted @ Replace[coercer[nthArg], $Failed :> ReturnFailed[MessageName[$LHSHead, msgName], numStr]]
  ]
];

defineCoerceArgMacro[coerceMacro_Symbol, coercer_, msgName_Str] := DefineMacro[coerceMacro,
  coerceMacro[n_] := With[
    {nthArg = Part[$LHSPatternSymbols, n], numStr = $numNames[n]},
    Quoted @ Replace[coercer[nthArg], $Failed :> ReturnFailed[MessageName[$LHSHead, msgName], numStr]]
  ]
];

_defineCheckArgMacro := Panic["BadArgMacro"];
_defineCoerceArgMacro := Panic["BadArgMacro"];

(**************************************************************************************************)

PrivateMacro[CheckIsQuiver, CoerceToQuiver]

General::notquiver = "The `` argument should be a quiver.";
General::notquiverc = "The `` argument should be a quiver or list of quiver edges.";
defineCheckArgMacro[CheckIsQuiver, QuiverQ, "notquiver"];
defineCoerceArgMacro[CoerceToQuiver, ToQuiver, "notquiverc"];


PrivateMacro[CheckIsGraph, CoerceToGraph]

General::notgraph = "The `` argument should be a Graph.";
General::notgraphc = "The `` argument should be a Graph or list of edges.";
defineCheckArgMacro[CheckIsGraph, GraphQ, "notgraph"];
defineCoerceArgMacro[CoerceToGraph, ToGraph, "notgraphc"];


PrivateMacro[CheckIsRep, CoerceToRep]

General::notrep = "The `` argument should be a LinearRepresentationObject.";
General::notrepc = "The `` argument should be a group, groupoid, LinearRepresentationObject, PathRepresentationObject, or RootSystem.";
defineCheckArgMacro[CheckIsRep, RepresentationObjectQ, "notrep"];
defineCoerceArgMacro[CoerceToRep, ToLinearRepresentation, "notrepc"];


PrivateMacro[CheckIsGroup]

General::notgroup = "`` is not a valid group.";
defineCheckArgMacro[CheckIsGroup, GroupQ, "notgroup"];


PrivateMacro[CheckIsGraphics]

General::notgraphics = "The `` argument should be a Graphics or Graphics3D expression."
defineCheckArgMacro[CheckIsGraphics, GraphicsQ, "notgraphics"];

(**************************************************************************************************)

PublicMacro[PackAssociation]

PackAssociation::usage = "PackAssociation[sym1, sym2, ...] creates an association whose keys are the title-cased names of sym_i \
and values are their values.";

DefineMacro[PackAssociation, PackAssociation[syms__Symbol] := mPackAssociation[syms]];

SetHoldAllComplete[mPackAssociation, packAssocRule];

mPackAssociation[sym__] := ToQuoted[Assoc, Seq @@ MapUnevaluated[packAssocRule, {sym}]];
packAssocRule[s_] := ToTitleCase[HoldSymbolName[s]] -> Quoted[s];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackTuple]

General::badtuple = "Argument `` should be a single value or a list of `` values."

DefineMacro[UnpackTuple, UnpackTuple[val_, syms__Symbol] := mUnpackTuple[val, syms]];

SetHoldAllComplete[mUnpackTuple];
mUnpackTuple[val_, s1_Symbol, s2_Symbol] :=
  Quoted @ If[ListQ[val],
    If[Len[val] != 2, ThrowMessage["badtuple", val, 2]]; {s1, s2} = val,
    s1 = s2 = val
  ];

mUnpackTuple[val_, s1_Symbol, s2_Symbol, s3_Symbol] :=
  Quoted @ If[ListQ[val],
    If[Len[val] != 3, ThrowMessage["badtuple", val, 3]]; {s1, s2, s3} = val,
    s1 = s2 = s3 = val
  ];

mUnpackTuple[val_, s1_Symbol, s2_Symbol, s3_Symbol, s4_Symbol] :=
  Quoted @ If[ListQ[val],
    If[Len[val] != 4, ThrowMessage["badtuple", val, 4]]; {s1, s2, s3, s4} = val,
    s1 = s2 = s3 = s4 = val
  ];

mUnpackTuple[val_, s1_Symbol, s2_Symbol, s3_Symbol, s4_Symbol, s5_Symbol] :=
  Quoted @ If[ListQ[val],
    If[Len[val] != 5, ThrowMessage["badtuple", val, 5]]; {s1, s2, s3, s4, s5} = val,
    s1 = s2 = s3 = s4 = s5 = val
  ];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackOptionsAs]

DefineMacro[UnpackOptionsAs,
UnpackOptionsAs[head_Symbol, opts_, syms__Symbol] :=
  mUnpackOptionsAs[head, opts, {syms}]
];

SetHoldAllComplete[mUnpackOptionsAs];
mUnpackOptionsAs[head_, opts_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[OptionValue, head, List @ opts, symbolsToCapitalizedStrings @ syms]
  ];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackAssociationSymbols]

DefineMacro[UnpackAssociationSymbols,
UnpackAssociationSymbols[assoc_, syms__Symbol] :=
  mUnpackAssociationSymbols[assoc, {syms}]
];

SetHoldAllComplete[mUnpackAssociationSymbols];
mUnpackAssociationSymbols[assoc_, syms_] :=
  ToQuoted[Set, Quoted[syms], With[{syms2 = Map[Symbol, symbolsToCapitalizedStrings @ syms]}, Quoted[Lookup[assoc, syms2]]]];

mUnpackAssociationSymbols[chain_Rule, syms_] :=
  ToQuoted[Set, Quoted[syms], With[{syms2 = Map[Symbol, symbolsToCapitalizedStrings @ syms]}, Quoted[LookupChain[chain, syms2]]]];

(**************************************************************************************************)

SetHoldAllComplete[symbolsToCapitalizedStrings];

symbolsToCapitalizedStrings[syms_] := Map[
  Fn[sym, capitalizeFirstLetter @ HoldSymbolName @ sym, HoldAllComplete],
  Unevaluated @ syms
];

capitalizeFirstLetter[str_Str] := capitalizeFirstLetter[str] =
  If[StringStartsQ[str, "$"], capitalizeFirstLetter @ StringDrop[str, 1],
    ToUpperCase[StringTake[str, 1]] <> StringDrop[str, 1]];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackStringOptions]

DefineMacro[UnpackStringOptions,
UnpackStringOptions[options_, default_, syms__Symbol] :=
  mUnpackStringOptions[options, default, {syms}]
];

SetHoldAllComplete[mUnpackStringOptions, uppercaseSymbolName];
mUnpackStringOptions[options_, default_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[Lookup,
      options,
      symbolsToCapitalizedStrings @ syms,
      Quoted[default]
    ]
  ];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackAnonymousOptions]

DefineMacro[UnpackAnonymousOptions,
UnpackAnonymousOptions[object_, default_, syms__Symbol] :=
  mUnpackAnonymousOptions[object, default, {syms}]
];

SetHoldAllComplete[mUnpackAnonymousOptions];
mUnpackAnonymousOptions[object_, default_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[LookupOption,
      Quoted[object],
      findMatchingSymbols[syms],
      Quoted[default]
    ]
  ];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackAnonymousThemedOptions]

DefineMacro[UnpackAnonymousThemedOptions,
UnpackAnonymousThemedOptions[object_, default_, syms__Symbol] :=
  mUnpackAnonymousThemedOptions[object, default, {syms}]
];

SetHoldAllComplete[mUnpackAnonymousThemedOptions];
mUnpackAnonymousThemedOptions[object_, default_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[LookupThemedOption,
      Quoted[object],
      findMatchingSymbols[syms],
      Quoted[default]
    ]
  ];
(**************************************************************************************************)

PrivateMutatingFunction[UnpackExtendedThemedOptions]

DefineMacro[UnpackExtendedThemedOptions,
UnpackExtendedThemedOptions[graph_, syms___Symbol] :=
  mUnpackExtendedThemedOptions[graph, {syms}]
];

SetHoldAllComplete[mUnpackExtendedThemedOptions];
mUnpackExtendedThemedOptions[graph_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[LookupExtendedThemedOption,
      Quoted[graph],
      findMatchingSymbols[syms]
    ]
  ];

(**************************************************************************************************)

PrivateMutatingFunction[UnpackExtendedOptions]

DefineMacro[UnpackExtendedOptions,
UnpackExtendedOptions[graph_, syms___Symbol] :=
  mUnpackExtendedOptions[graph, {syms}]
];

SetHoldAllComplete[mUnpackExtendedOptions];
mUnpackExtendedOptions[graph_, syms_] :=
  ToQuoted[Set, Quoted[syms],
    ToQuoted[LookupExtendedOption,
      Quoted[graph],
      findMatchingSymbols[syms]
    ]
  ];

SetHoldAllComplete[findMatchingSymbols];
$lowerCaseSymbolRegExp = RegularExpression["\\b([a-z])(\\w+)\\b"];
findMatchingSymbols[syms_List] := findMatchingSymbols[syms] = Block[
  {$Context = "QuiverGeometry`Private`Dummy`", $ContextPath = {"System`", "QuiverGeometry`", $Context}, str},
  str = ToString[Unevaluated @ syms, InputForm];
  str = StringReplace[str, $lowerCaseSymbolRegExp :> StringJoin[ToUpperCase["$1"], "$2"]];
  ToExpression[str, InputForm, Quoted]
];

(**************************************************************************************************)

PrivateMacro[GraphCachedScope]
PublicVariable[$GraphCacheStore]

$GraphCacheStore = Language`NewExpressionStore["GraphCache"];

DefineMacro[GraphCachedScope,
GraphCachedScope[graph_, args___, body_] := mGraphCachedScope[graph, {$LHSHead, args}, body]
];

SetHoldAllComplete[mGraphCachedScope];

mGraphCachedScope[graph_, key_, body_] := With[{body2 = MacroExpand @ Scope @ body},
  Quoted @ Module[
    {$cacheTemp$ = $GraphCacheStore["get"[graph, key]]},
    If[$cacheTemp$ === Null,
      $cacheTemp$ = body2;
      If[!FailureQ[$cacheTemp$], $GraphCacheStore["put"[graph, key, $cacheTemp$]]];
    ];
    $cacheTemp$
  ]
];

(**************************************************************************************************)

PublicSpecialFunction[CatchMessage]

DefineMacro[CatchMessage,
CatchMessage[body_] := Quoted[Catch[body, ThrownMessage[_], ThrownMessageHandler[$LHSHead]]],
CatchMessage[head_, body_] := Quoted[Catch[body, ThrownMessage[_], ThrownMessageHandler[head]]]
];

ThrownMessageHandler[msgHead_Symbol][{args___}, ThrownMessage[msgName_Str]] :=
  (Message[MessageName[msgHead, msgName], args]; $Failed);

(**************************************************************************************************)

PublicSpecialFunction[ThrowMessage]

ThrowMessage[msgName_Str, msgArgs___] :=
  Throw[{msgArgs}, ThrownMessage[msgName]];

(**************************************************************************************************)

PrivateMacro[FunctionSection]

DefineMacro[FunctionSection,
FunctionSection[expr_] := Quoted[expr]
];

(**************************************************************************************************)

(* some of these are already defined in GU, but aren't macros, so have our own versions here *)
PrivateMutatingFunction[SetAutomatic, SetMissing, SetNone, SetAll, SetInherited]

defineSetter[symbol_, value_] := (
  DefineLiteralMacro[symbol, symbol[lhs_, rhs_] := If[lhs === value, lhs = rhs, lhs]];
  SetHoldAll @ symbol;
);

defineSetter[SetAutomatic, Automatic];
defineSetter[SetNone, None];
defineSetter[SetAll, All];
defineSetter[SetInherited, Inherited];

DefineLiteralMacro[SetMissing, SetMissing[lhs_, rhs_] := If[MissingQ[lhs], lhs = rhs, lhs]];
SetHoldAll[SetMissing];

(**************************************************************************************************)

PublicMutatingFunction[SetScaledFactor]

DefineLiteralMacro[SetScaledFactor, SetScaledFactor[lhs_, scale_] := If[MatchQ[lhs, Scaled[_ ? NumericQ]], lhs //= P1 /* N; lhs *= scale]];

(**************************************************************************************************)

PrivateFunction[currentStyleSetting]

currentStyleSetting[option_, stylename_] := option :> CurrentValue[{StyleDefinitions, stylename, option}];

(**************************************************************************************************)

PrivateFunction[ReplaceNone, ReplaceMissing, ReplaceAutomatic, ReplaceInherited]

defineReplacer[symbol_, pattern_] := (
  DefineLiteralMacro[symbol,
    symbol[lhs_, rhs_] := Replace[lhs, pattern :> rhs],
    symbol[rhs_]       := Replace[pattern :> rhs]
  ];
  SetHoldAll @ symbol;
);

defineReplacer[ReplaceNone, None];
defineReplacer[ReplaceMissing, _Missing];
defineReplacer[ReplaceAutomatic, Automatic];
defineReplacer[ReplaceInherited, Inherited];

(**************************************************************************************************)

PrivateSpecialFunction[$NotImplemented]

$NotImplemented := Panic["NotImplemented"];

(**************************************************************************************************)

PrivateSpecialFunction[OnFailed]

SetUsage @ "
OnFailed[expr$, body$] evaluates and returns body$ if expr$ is $Failed, otherwise returns expr$.
"

SetHoldRest[OnFailed];

OnFailed[$Failed, e_] := e;
OnFailed[e_, _] := e;

OnFailed[$Failed, e_, _] := e;
OnFailed[e_, _, s_] := s;

(**************************************************************************************************)

PublicFunction[PathJoin]

PathJoin[args___Str] := FileNameJoin[{args}];

_PathJoin := BadArguments[];

(**************************************************************************************************)

PublicVariable[$TemporaryQGDirectory]

$TemporaryQGDirectory := $TemporaryQGDirectory = EnsureDirectory[PathJoin[$TemporaryDirectory, "qg"]];

(**************************************************************************************************)

PublicFunction[TemporaryPath]

TemporaryPath[file_Str] := PathJoin[$TemporaryQGDirectory, file];
TemporaryPath[args__Str, file_Str] := PathJoin[EnsureDirectory @ PathJoin[$TemporaryQGDirectory, args], file];

(**************************************************************************************************)

PublicSpecialFunction[MakeTemporaryFile]

SetInitialValue[$tempFileCounter, 0];

MakeTemporaryFile[args___Str, name_Str] := Scope[
  fileName = StringReplace[name, "#" :> StringJoin[IntegerString[$ProcessID], "_", IntegerString[$tempFileCounter++, 10, 5]]];
  TemporaryPath[args, fileName]
];

(**************************************************************************************************)

PublicFunction[PatchDatasetCodebase]

PatchDatasetCodebase[] := (
  Dataset;
  TypeSystem`$TypeStandardFormsEnabled = True;
  GeneralUtilities`Formatting`PackagePrivate`fullbox[DirectedInfinity[1]] := "\[Infinity]"
  Dataset`DisplayWithType[data_] := Column[{data,  Dataset`GetType[data]}, Alignment -> Center];
  Dataset`DisplayShapeFunction[ds_, size_:{8,8}] := Block[{type},
    type = Dataset`GetType[ds];
    PrettyForm @ TypeSystem`PackageScope`chooseShape[Normal @ ds, type, type, size, {}]
  ];
  Unprotect[TypeSystem`NestedGrid`PackagePrivate`formatAtom];
  TypeSystem`NestedGrid`PackagePrivate`formatAtom[d:DateObject[_, "Instant", "Gregorian", ___]] := DateString[d, {"Day", "/","Month","/","YearShort"," ","Time"}];
  ToExpression @ """
    Begin["TypeSystem`Summary`PackagePrivate`"];
    assocBox[t_List] := bracket["Assoc", RowBox @ Riffle[MapApply[ruleBox, t], $comma]];
    bracket[head_, args___] := RowBox[{head, "[", args, "]"}]
    $framestyle = LightGray;
    lengthBox[b_, n_] := SubscriptBox[b, RowBox[{" ", lengthFieldBox @ n}]];
    bracket[head_, args___] := RowBox[{head, GridBox[{{ItemBox["", Frame -> {{True, None}, {True, True}}], args, ItemBox["", Frame -> {{False, True}, {True, True}}]}},
      ColumnSpacings -> {0, 0, 0}, GridFrameMargins->{{0.1,.1},{.1,0.1}}]}];
    tbox[TypeSystem`Tuple[t_List]] := bracket["Tuple", dividedColumnBox[Map[typeBox, t], {Left}]];
    dividedColumnBox[list_, align_] := GridBox[ToList /@ list, ColumnSpacings -> {1, 1, 0}, ColumnAlignments -> align, FrameStyle -> $LightGray, GridBoxDividers->{"Columns"->False,"Rows"->{False,{True},False}}];
    tbox[TypeSystem`Vector[t_, n_]] := lengthBox[bracket["List", typeBox @ t], n];
    tbox[TypeSystem`Struct[k_List, v_List]] := bracket["Record", structEntries @ MapThread[fieldBox, Unevaluated @ {k, v}]];
    structEntries[list_List] := dividedColumnBox[Riffle[#, deemph @ "\[Rule]"]& /@ list, {Right, Center, Left}];
    stringBox[s_String] := StyleBox[ToString[s, InputForm], FontColor -> Gray, FontFamily -> "Verdana", FontWeight -> Normal]
    tbox[TypeSystem`Atom[TypeSystem`Enumeration[fields__String]]] := RowBox[{"Either", "[", " ", RowBox @ Riffle[Map[stringBox] @ List @ fields, $comma]," ", "]"}];
    tbox[TypeSystem`Atom[q:Quantity[1, unit_]]] := RowBox[{letterBox @ "Quant", "[", stringBox @ quantString[q], "]"}];
    quantString[q_System`Quantity] := StringTrim[ToString @ QuantityForm[q,"Abbreviation"], "1\[InvisibleSpace] "];
    End[];
  """
);

(**************************************************************************************************)

PrivateFunction[LengthEqualOrMessage]

SetHoldFirst[LengthEqualOrMessage];
LengthEqualOrMessage[msg_MessageName, list1_, list2_] := With[
  {l1 = Len[list1], l2 = Len[list2]},
  If[l1 =!= l2, Message[msg, l1, l2]; False, True]
];

(**************************************************************************************************)

PublicSpecialFunction[WithInternet]

SetAttributes[WithInternet, HoldAll];

WithInternet[body_] := Block[{$AllowInternet = True}, body];

(**************************************************************************************************)

PublicFunction[VectorListableQ]

VectorListableQ[sym_Symbol] := MemberQ[Attributes @ sym, Listable];
VectorListableQ[HoldPattern[Fn[___, Listable | {___, Listable, ___}]]] := True;
VectorListableQ[_] := False;

PrivateMutatingFunction[setVectorListableOperator]

setVectorListableOperator[syms__Symbol] := Scan[setVectorListableOperator, {syms}];
setVectorListableOperator[sym_Symbol] := (VectorListableQ[_sym] := True;)
_setVectorListableOperator := BadArguments[];