PrivateFunction[boxesToInputText]

boxesToInputText[BoxData @ boxes_] := boxesToInputText @ boxes;

boxesToInputText[boxes_Str] := boxes;

boxesToInputText[boxes_] := Scope[
  expr = ToExpression[boxes, StandardForm, InternalHoldForm];
  str = ToPrettifiedString[expr, ElideAtomicHeads -> True, CompactRealNumbers -> 4];
  str //= StringReplace[$WLSymbolToUnicode];
  str
];


(**************************************************************************************************)

PrivateFunction[textCellToMarkdown]
PrivateVariable[$forbiddenStrings]

(* Todo: introduce simple caching *)

$forbiddenStrings = "XXX" | "XXXX";

ToMarkdownString::msgs = "Messages issued during markdown conversion of cell printed below.";

textCellToMarkdown[e_] := Scope[
  $lastExternalCodeCell ^= None;
  If[ContainsQ[e /. _CompressedData :> Null, s_Str /; StringContainsQ[s, $forbiddenStrings]],
    VPrint["Dropping cell with forbidden content"];
    Return[""]
  ];
  Check[
    text = StringTrim @ textToMarkdown @ e;
  ,
    Message[ToMarkdownString::msgs];
    Print[MsgExpr[text, 6, 50]];
    PrintBadCell[e];
  ];
  If[!StringQ[text], Return["### Markdown generation failed"]];
  If[StringContainsQ[text, $forbiddenStrings], Return[""]];
  (* these are disabled for now because they involve the assumption that $ is the katex delimiter, and they
  have other QG-specific things in them *)
(*text //= StringReplace[$finalStringFixups1];*)
  text //= StringReplace[$finalStringFixups2];
  text //= deblockIndent; (* JS *)
  text
]

$finalStringFixups1 = {
  "  $" -> " $",
  "$  " -> "$ "
};

makeFontSmallCaps[text_] :=
  $rawHTMLTemplate["<span style=\"font-variant: small-caps;\">" <> ToLowerCase[text] <> "</span>"];

$finalStringFixups2 = {
(*
  "$ --" -> "$ --",
  "$ -" -> "$\\-",
  "$ ." -> "$.",
  "$ ," -> "$,",
  "$ ?" -> "$?",
  "$ !" -> "$!",
  "$ :" -> "$:",
  "$ *" -> "\,$ *",
  "\\text{\\,and\\,}" -> "$ and $", (* improves linebreaking *) *)
  "LHS" :> makeFontSmallCaps["LHS"],
  "RHS" :> makeFontSmallCaps["RHS"]
  (* "1'st" | "1st" -> "$1^{\\textrm{st}}$",
  "2'nd" | "2nd" -> "$2^{\\textrm{nd}}$",
  "3'rd" | "3rd" -> "$3^{\\textrm{rd}}$",
  "n-ary" -> "$n$-ary",
  (d:DigitCharacter ~~ "'th") :> StringJoin["$", d, "^{\\textrm{th}}$"],
  "n'th"-> "$n^{\\textrm{th}}$",
  "i'th" -> "$i^{\\textrm{th}}$",
  l:("f"|"p") ~~ "-" ~~ r:("vert"|"edge"|"cardinal"|"quiver") :>
    StringJoin["_", l, "_\\-", r]
 *)
};

WhiteString = _Str ? (StringMatchQ[Whitespace]);

(**************************************************************************************************)

PrivateFunction[textToMarkdown]

(* textToMarkdown yields an entire paragraph worth of text, and can be called from several contexts,
like a cell of a textual table, or the boxes of a Text cell *)
textToMarkdown[e_] := Scope[
  str = iTextToMarkdown @ e;
  str //= StringJoin;
  str //= processInlineCodeBlocks;
  str //= wlCharactersToUnicode;
  str
];

iTextToMarkdown = Case[

  BoxData[t:TagBox[_, "ClassTaggedForm"[_]]]                              := % @ t;
  TagBox[box_, "ClassTaggedForm"[tag_]]                                   := $classAttributeTemplate[{tag}] @ % @ box;

  BoxData[box_ ? pureTextBoxesQ]                                          := textBoxesToMarkdown @ box;
  BoxData[box_]                                                           := toMultilineMath @ box;

  TextData @ Cell[BoxData[box_FormBox], ___]                              := toMultilineMath @ box;
  TextData @ Cell[BoxData[boxes:{Repeated[_FormBox | WhiteString]}], ___] := toMultilineMath @ RowBox @ replaceIndentingNewlines @ boxes;

  other_ := Block[{$lastSpace = True, $backtickCount = 0}, textBoxesToMarkdown @ other];
];

replaceIndentingNewlines[boxes_] :=
  VectorReplace[boxes, s_Str :> StringReplace[s, "\[IndentingNewLine]"|"\n" -> "\\\\\n"]];

(**************************************************************************************************)

deblockIndent[str_Str] := Scope[
  blocks = StringSplit[str, "\n" ~~ (" " | "\t")... ~~ "\n"];
  StringRiffle[Map[deblockIndent0, blocks], "\n\n"]
];

(* JS: color wrapped around blocks doesn't work *)
deblockIndent0[str_Str] /; StringMatchQ[str, "<span style=" ~~ Except[">"].. ~~ ">" ~~ inner___ ~~ "</span>"] && StringCount[str, "</span>"] == 1 :=
  StringReplace[str, StartOfString ~~ style:("<span style=" ~~ Except[">"].. ~~ ">") ~~ inner___ ~~ "</span>" ~~ EndOfString :>
    deblockIndent0[inner]];

deblockIndent0[str_Str] := Scope[
  tabSizes = StringCases[str, StartOfLine ~~ Repeated[" ", {0, 4}] ~~ t:"\t"... :> StringLength[t]];
  {min, max} = MinMax[tabSizes];
  If[min > 0 && min == max, str = StringDelete[str, StartOfLine ~~ Repeated[" ", {0, 4}] ~~ StringRepeat["\t", min]]];
  StringReplace[str, StartOfLine ~~ "\[SmallCircle] " ~~ line:Except["\n"].. ~~ EndOfLine :> "  * " <> line]
];

(**************************************************************************************************)

PrivateFunction[mathCellToMarkdown]

mathCellToMarkdown = Case[
  BoxData[b_]   := % @ b;
  FormBox[b_]   := % @ b;
  b_            := toMultilineMath @ b
]

toMultilineMath[boxes_] := $multilineMathTemplate @ toProcessedKatexString @ procTextualNewlines @ boxes;

(* this ensures that manual linebreaks inside e.g. Equation cells produce katex line breaks *)
$katexNewline = "\\\\\n";
procTextualNewlines = Case[
  RowBox[a_]                  := RowBox @ % @ a;
  a_List                      := Map[%, a];
  StyleBox[a_, opts___]       := StyleBox[% @ a, opts];
  TextData[a_]                := TextData @ % @ a;
  str_Str                     := StringReplace[str, "\n" -> $katexNewline];
  other_                      := other;
];

(**************************************************************************************************)

PrivateFunction[textBoxesToMarkdown]

PrivateVariable[$textPostProcessor]

PrivateVariable[$allowMDemph]

$textPostProcessor = Id;

(* TODO: just wrap inline math with a symbolic wrapper, then replace that with inlineMathTemplate later.
this will allow us to interpret $ as coming soley from user and not a result of inlineMathTemplate *)

$backtickCount = 0;
$lastSpace = $allowMDemph = True;
ClearAll[textBoxesToMarkdown];
textBoxesToMarkdown = Case[
  str_Str :=
    $textPostProcessor @ StringJoin @ checkLastSpace @ str;

  list_List :=
    Map[%, list];

  TextData[e_] :=
    % @ e;

  RowBox[e_List] :=
    % @ e;

  Cell[BoxData[b_], ___] :=
    inlineCellToMarkdown[b, True];

  Cell[TextData[text_, ___], ___] :=
    % @ text;

  Cell[boxes_, "Text"] := % @ boxes;

  StyleBox[str_Str /; StringMatchQ[str, Whitespace], style___] /; FreeQ[{style}, Background | "StrikeThrough"] :=
    ($lastSpace = True; " ");

  FormBox[b_ButtonBox, _] := % @ b;

  ButtonBox[title_, BaseStyle -> "Hyperlink"|Hyperlink, ButtonData -> {URL[url_Str], _}, ___] := Scope[
    linkText = StringJoin @ % @ title; If[StringTrim[linkText] === "", Return @ ""];
    numNewlines = StringLength[linkText] - StringLength[linkText = StringTrimRight[linkText, "\n"..]];
    StringJoin["[", linkText, "](", url, ")", StringRepeat["\n", numNewlines]]
  ];

  StyleBox[boxes_, opts___] :=
    $textPostProcessor @ StringJoin @ styleBoxToMarkdown @ StyleBox[boxes, Apply[Sequence] @ Sort @ List @ FilterOptions[styleBoxToMarkdown, opts]];

  other_ := complainBoxes[other];
];

checkLastSpace[list_List] := Map[checkLastSpace, list];
checkLastSpace[s_Str] := ($lastSpace = StringEndsQ[s, " "|"\t"]; $backtickCount += StringCount[s, "`"]; s);
checkLastSpace[other_] := ($lastSpace = False; other);

Options[styleBoxToMarkdown] = {
  FontWeight -> "Plain",
  FontSlant -> "Plain",
  FontColor -> None,
  Background -> None,
  FontVariations -> {}
};

wordQ[e_] := StringQ[e] && StringMatchQ[e, WordCharacter..];
canEmphWrapQ[e_] := TrueQ[$lastSpace] && TrueQ[$allowMDemph] && TrueQ[EvenQ @ $backtickCount] && wordQ[e];

$boldP = Bold | "Bold";
$italicP = Italic | "Italic";
$plainP = Plain | "Plain";

styleBoxToMarkdown = Case[ 
  StyleBox[e_Str, "PreformattedCode"] := "<code>" <> e <> "</code>";
  StyleBox[e_Str, FontSlant -> $italicP] /; canEmphWrapQ[e]                        := wrapWith[e, "*"];
  StyleBox[e_Str, FontWeight -> $boldP] /; canEmphWrapQ[e]                         := wrapWith[e, "**"];
  StyleBox[e_Str, FontSlant  -> $italicP, FontWeight -> $boldP] /; canEmphWrapQ[e] := wrapWith[e, "***"];
  StyleBox[e_Str, FontVariations -> {"Underline" -> True}] /; canEmphWrapQ[e]      := wrapWith[e, "_"];
  StyleBox[e_, rules___] := htmlStyledString[textBoxesToMarkdown @ e, {rules}];
]

(**************************************************************************************************)

PrivateFunction[complainBoxes]

complainBoxes[other_] := Scope[
  Message[ToMarkdownString::badmdbox, MsgExpr @ other];
  headStr = ToPrettifiedString @ H @ other;
  PrintQGStackSymbols[];
  "**CANNOT CONVERT TEXTUAL BOXES TO MARKDOWN**\n```\n" <> ToPrettifiedString[other, MaxDepth -> 3, MaxLength -> 10, MaxIndent -> 3] <> "\n```\n"
];

ToMarkdownString::badmdbox = "Cannot form markdown for boxes that appeared within a textual context: ``."

(**************************************************************************************************)

PrivateFunction[htmlStyledString, toStylePropVal]

htmlStyledString[str_Str, {currentStyleSetting[opt:FontColor|Background, name_]}] :=
  htmlStyledString[str, {opt -> name}];

htmlStyledString[str_Str, {l___, FontVariations -> {"StrikeThrough" -> True}, r___}] :=
  "<sub>" <> htmlStyledString[str, {l, r}] <> "</sub>";

htmlStyledString[str_Str, {}] := str;

htmlStyledString[str_Str, {FontColor|Background -> name_Str}] :=
  $classSpanTemplate[str, name];

$classSpanTemplate = StringFunction @ "<span class='#2'>#1</span>";

htmlStyledString[str_Str, rules_List] := Scope[
  styleStr = StringRiffle[toStylePropVal /@ rules, ";"];
  If[styleStr === "", str, $styledSpanTemplate[str, styleStr]]
];

toStylePropVal = Case[
  color_? ColorQ                           := %[FontColor -> color];
  Bold                                     := %[FontWeight -> Bold];
  Italic                                   := %[FontSlant -> Italic];
  FontVariations -> {"Underline" -> True}  := %[Underlined];
  FontVariations -> {"Underline" -> False} := "text-decoration: none";
  Underlined                               := "text-decoration: underline";
  FontColor -> (color_? ColorQ)            := "color:" <> HTMLColorString[color];
  Background -> (color_? ColorQ)           := "background-color:" <> HTMLColorString[color];
  FontWeight -> $boldP                     := "font-weight:bold";
  FontWeight -> $plainP                    := "font-weight:normal";
  FontSlant -> $italicP                    := "font-style:italic";
  FontSlant -> $plainP                     := "font-style:normal";
  _                                        := Nothing
]

$styledSpanTemplate = StringFunction @ "<span style='#2'>#1</span>"

styledMD[e___] := Print["Can't handle: ", e];

wrapWith[e_, wrap_] := Scope[
  e = StringJoin @ e;
  p1 = StringStartsQ[e, Whitespace];
  p2 = StringEndsQ[e, Whitespace];
  {If[p1, " ", {}], wrap, StringTrim @ e, wrap, If[p2, " ", {}]}
];

(**************************************************************************************************)

$shortcodeP := $shortcodeP = RegularExpression @ ToRegularExpression @ Alternatives[
  "</span>", "\n", "B{", "B:", "F{", "F:", "\\n", "^{", "_{", ("_" | "^") ~~ DigitCharacter,
  DoubleStruckCharacter,
  P1 @ $WLSymbolToUnicode
];

processInlineCodeBlocks[str_Str] := StringReplace[str, {
  code:("`" ~~ body:Shortest[___] ~~ "`") :> If[StringFreeQ[body, $shortcodeP], code, toCodeMarkdown[body, False]],
  code:("```" ~~ body:Shortest[___] ~~ "```") :> If[StringFreeQ[body, $shortcodeP], code, toCodeMarkdown[body, True]]
}]
