PublicTypesettingForm[ExistsForm, ForAllForm]

existsBox[a_] := RBox["\[Exists]", "\[MediumSpace]", a];
forAllBox[a_] := RBox["\[ForAll]", "\[MediumSpace]", a];

(* TODO: replace part of this with DefineRestCommaForm *)

DefineStandardTraditionalForm[{
  ExistsForm[a_, rest__] :> TBox[MakeMathBoxes @ a, CommaRowBox @ MakeMathBoxSequence[rest], "ExistsForm"],
  ExistsForm[a_] :> TBox[MakeMathBoxes @ a, "UnconditionalExistsForm"],
  ExistsForm :> "\[Exists]",
  ForAllForm[{a__}, rest__] :> TBox[CommaRowBox @ MakeMathBoxSequence[a], CommaRowBox @ MakeMathBoxSequence[rest], "WideForAllForm"],
  ForAllForm[a_, rest__] :> TBox[MakeMathBoxes @ a, CommaRowBox @ MakeMathBoxSequence[rest], "ForAllForm"],
  ForAllForm[a_] :> TBox[MakeMathBoxes @ a, "UnconditionalForAllForm"],
  ForAllForm :> "\[ForAll]"
}];

DefineTemplateBox[ExistsForm, "UnconditionalExistsForm", existsBox[$1], None];
DefineTemplateBox[ForAllForm, "UnconditionalForAllForm", forAllBox[$1], None];
DefineTemplateBox[ExistsForm, "ExistsForm", RBox[existsBox @ $1, WideOpBox @ ":", $2], None]
DefineTemplateBox[ForAllForm, "ForAllForm", RBox[forAllBox @ $1, WideOpBox @ ":", $2], None]
DefineTemplateBox[ForAllForm, "WideForAllForm", RBox[forAllBox @ $1, VeryWideOpBox @ ":", $2], None]

(**************************************************************************************************)

PublicTypesettingForm[AndForm, OrForm, XorForm, NandForm]

DefineInfixForm[AndForm,  OpBox @ "\[And]"];
DefineInfixForm[OrForm,   OpBox @ "\[Or]"];
DefineInfixForm[XorForm,  OpBox @ "\[Xor]"];
DefineInfixForm[NandForm, OpBox @ "\[Nand]"];

(**************************************************************************************************)

PublicTypesettingForm[NotForm]

DefineUnaryForm[NotForm, RBox["\[Not]", $1], HeadBoxes -> "\[Not]"];

(**************************************************************************************************)

PublicTypesettingForm[ImpliesForm, ImpliedByForm, EquivalentForm]

DefineInfixBinaryForm[ImpliesForm, WideOpBox @ "⟹"]
DefineInfixBinaryForm[ImpliedByForm, WideOpBox @ "⟸"];
DefineInfixBinaryForm[EquivalentForm, WideOpBox @ "⟺"]

(**************************************************************************************************)

PublicTypesettingForm[SuchThatForm]

DefineInfixBinaryForm[SuchThatForm, KBox[StyleBox["\[ThinSpace]\[VerticalSeparator]\[ThickSpace]", FontSize -> 20], KBin["\\vert"]]]
