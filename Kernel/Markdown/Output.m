PrivateFunction[outputCellToMarkdown]

outputCellToMarkdown = Case[

  b:BoxData[TemplateBox[_, _ ? textTagQ]]                     := textCellToMarkdown @ b;

  BoxData[t:TemplateBox[_, "VideoBox1" | "VideoBox2", ___]]   := videoBoxToMarkdown @ t;

  BoxData[t:TagBox[_, Manipulate`InterpretManipulate[1]]]     := manipulateBoxesToMarkdown @ t;

  BoxData[b_String | b_RowBox ? pureTextBoxesQ]               := plaintextCodeToMarkdown @ b;

  boxes_                                                      := cellToRasterMarkdown @ Cell[boxes, "Output"];

];

(* recognizes tags generated by StylesheetForms *)
textTagQ[tag_String] := StringEndsQ[tag, "Form" | "Symbol"] || TemplateBoxNameQ[tag];
textTagQ[_] := False;

PrivateFunction[pureTextBoxesQ]

(* pureTextBoxesQ answers is this markdown-only plain text? used in various places to redirect
execution to pure text output when it would otherwise involve rasterization or Katex
TODO: support italic, bold, etc. *)

pureTextBoxesQ = Case[
  RowBox[e_List]                               := VectorQ[e, pureTextBoxesQ];
  e_List                                       := VectorQ[e, pureTextBoxesQ];
  FormBox[_ButtonBox ? pureTextBoxesQ, _]      := True;
  StyleBox[b_, ___]                            := pureTextBoxesQ[b];
  ButtonBox[b_, BaseStyle -> "Hyperlink", ___] := pureTextBoxesQ[b];
  _String                                      := True;
  _                                            := False;
]

(**************************************************************************************************)

PrivateFunction[plaintextCodeToMarkdown]

(* TODO: Make this into a flavor template. also replace this whole last XXX business with a generic
$lastCell mechanism. *)

plaintextCodeToMarkdown[boxes_] := Scope[

  (* does the same as Copy As > Input Text *)
  text = boxesToInputText @ boxes;

  If[$lastExternalCodeCell =!= None, (* we have a custom Python intepreter that returns stringified output so that we can display it verbatim *)
    If[text === "\"None\"", Return @ Nothing]; (* <- if Python returns "None", we should suppress that output *)
    StringJoin["```\n", StringTrim[text, "\""], "\n```"]
  ,
    StringJoin["```\n", StringTrim @ text, "\n```"]
  ]

];