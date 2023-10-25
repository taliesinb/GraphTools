PublicFunction[LookupOption]

SetRelatedSymbolGroup[LookupOption, JoinOptions, DeleteOptions, TakeOptions, ReplaceOptions, UpdateOptions];

SetUsage @ "
LookupOption[object$, option$] looks up the value of option$ in object$.
LookupOption[object$, option$, default$] returns default$ if no value is associated with option$.
* object$ can be any expression that %Options evaluates on.
* By default, Automatic is returned if there is no value for option$.
"

LookupOption[obj_, opt_, default_:Automatic] :=
  Quiet @ Lookup[Options[obj, opt], opt, default];

(**************************************************************************************************)

PublicFunction[JoinOptions]

SetUsage @ "
JoinOptions[options$1, options$2, $$] joins together the options$i to form a single list of rules.
* The option$i can be a rule, list of rules, or a symbol with defined %Options.
* If multiple values are given for a given option symbol, the first is taken.
"

JoinOptions[opts___] := DeleteDuplicatesBy[
  Flatten @ Replace[Flatten @ {opts}, s_Symbol :> Options[s], {1}],
  First
];

(**************************************************************************************************)

PublicFunction[OptionKeys]

SetUsage @ "
OptionKeys[{key$1 -> val$1, key$2 -> val$2, $$}] gives {key$1, key$2, $$}.
OptionKeys[sym$] gives the keys for %Options[sym$].
"

OptionKeys::headNoOpts = "Symbol `` does not appear to have any options.";

OptionKeys[rules_List] := Keys @ rules;
OptionKeys[sym_Symbol] := OptionKeys[sym] = Replace[Keys @ Options @ sym, {} :> (Message[OptionKeys::headNoOpts, sym]; {})];

(**************************************************************************************************)

PrivateSpecialFunction[declareOptionableHead]

SetInitialValue[$optionableHeadQ, UAssociation[Graphics -> True, Graphics3D -> True]];

declareOptionableHead[sym_Symbol] := AssociateTo[$optionableHeadQ, sym -> True];

(**************************************************************************************************)

applyToObjectRules[g_Graph, fn_, spec_] := ExtendedGraph[g, Sequence @@ fn[ExtractExtendedGraphOptions @ g, spec]];

General::atomNoOpts = "Atom `` is not a valid target for option manipulation.";
applyToObjectRules[obj_ ? AtomQ, fn_, _] := (Message[MessageName[fn, "atomNoOpts"], obj]; obj)

applyToObjectRules[(head_Symbol ? $optionableHeadQ)[Shortest[args___], opts:RepeatedNull[_Rule | RuleDelayed]] ? System`Private`EntryQ, fn_, spec_] :=
  head[args, Sequence @@ fn[{opts}, spec]];

(* we would get to this point if no valid spec argument matched before dispatching here *)
General::invalidOptSpec = "Invalid spec ``.";
applyToObjectRules[expr_List, fn_, spec_] := (Message[MessageName[fn, "invalidOptSpec"], MsgExpr @ spec]; expr)

General::exprNoOpts = "Expression `` is not a valid target for option manipulation.";
applyToObjectRules[expr_, fn_, _] := (Message[MessageName[fn, "exprNoOpts"], MsgExpr @ expr]; expr)

(**************************************************************************************************)

PublicFunction[DeleteOptions]

SetUsage @ "
DeleteOptions[rules$, sym$] drops any rule whose key is sym$.
DeleteOptions[rules$, {sym$, sym$2, $$}] drops rules whose keys are one of the sym$i.
DeleteOptions[keySpec$] is an operator form of DeleteOptions that can be applied to lists of rules.
* DeleteOptions works on %Graph, %Graphics, and some other whitelisted heads.
* use %OptionKeys to obtain keys to use as a second argument.
"

DeleteOptions[obj_, {}] := obj;

DeleteOptions[rules_List, key:(_Symbol | _String)] := DeleteCases[rules, (Rule|RuleDelayed)[key, _]];

DeleteOptions[rules_List, opts_List] := FilterRules[rules, Complement[Keys @ rules, opts]];

DeleteOptions[obj_, spec_] := applyToObjectRules[obj, DeleteOptions, spec];

DeleteOptions[deleteSpec_][obj_] := DeleteOptions[obj, deleteSpec];

(**************************************************************************************************)

PublicFunction[TakeOptions]

SetUsage @ "
TakeOptions[rules$, {sym$, sym$2, $$}] selects rules whese keys are one of the sym$i.
TakeOptions[keySpec$] is an operator form of TakeOptions that can be applied to lists of rules.
* TakeOptions works on %Graph, %Graphics, and some other whitelisted heads.
* use %OptionKeys to obtain keys to use as a second argument.
"

TakeOptions[rules_List, keys_List] := FilterRules[rules, keys];

TakeOptions[obj_, spec_] := applyToObjectRules[obj, TakeOptions, spec];

TakeOptions[takeSpec_][obj_] := TakeOptions[obj, takeSpec];

(**************************************************************************************************)

PublicFunction[ReplaceOptions]

SetUsage @ "
ReplaceOptions[object$, symbol$ -> value$] gives a new version of object$ in which the option replacement has been applied.
ReplaceOptions[object$, {rule$1, rule$2, $$}] applies multiple rule changes.
ReplaceOptions[replacements$] is the operator form of ReplaceOptions that can be applied to an object or rulelist.
* ReplaceOptions can take a list of rules as an object, returning a new list of rules.
* ReplaceOptions works on %Graph, %Graphics, and some other whitelisted heads.
"

ReplaceOptions[obj_, {}] := obj;

ReplaceOptions[g_Graph, rule_Rule | {rules__Rule}] :=
  ExtendedGraph[g, rule];

ReplaceOptions[obj_ ? AtomQ, _] := (Message[ReplaceOptions::atomNoOpts, obj]; obj)

ReplaceOptions[obj_, kv:((Rule|RuleDelayed)[key_, _])] :=
  If[MemberQ[obj, (Rule|RuleDelayed)[key, _]],
    VectorReplace[obj, (Rule|RuleDelayed)[key, _] :> kv],
    Append[obj, kv]
  ];

ReplaceOptions[obj_, rules_List] :=
  Fold[ReplaceOptions, obj, rules];

ReplaceOptions[replacementSpec_][obj_] := ReplaceOptions[obj, replacementSpec];

ReplaceOptions[_, _] := BadArguments[];

(**************************************************************************************************)

PublicFunction[UpdateOptions]

SetUsage @ "
UpdateOptions[object$, option$, f$] returns a new object with the old value of option$ replaced with f$[value$].
* If the option was not present initially, the value %Automatic is supplied to f$.
"

UpdateOptions[obj_, option_, func_] :=
  ReplaceOptions[obj, option -> func[LookupOption[obj, option]]];

_UpdateOptions := BadArguments[];

(**************************************************************************************************)

PublicFunction[SeqReplaceOptions, SeqTakeOptions, SeqDeleteOptions]

SetUsage @ "
SeqReplaceOptions[$$][$$] is like %ReplaceOptions but operates on and returns sequences of rules.
* it only has an operator form."

SeqReplaceOptions[spec_][rules___] := Sequence @@ ReplaceOptions[{rules}, spec];

SetUsage @ "
SeqTakeOptions[$$][$$] is like %TakeOptions but operates on and returns sequences of rules.
* it only has an operator form."

SeqTakeOptions[spec_][rules___] := Sequence @@ TakeOptions[{rules}, spec];

SetUsage @ "
SeqDeleteOptions[$$][$$] is like %DeleteOptions but operates on and returns sequences of rules.
* it only has an operator form."

SeqDeleteOptions[spec_][rules___] := Sequence @@ DeleteOptions[{rules}, spec];

(**************************************************************************************************)

PublicOption[HighlightStyle, HighlightColor, HighlightOpacity]

PublicOption[ZOrder]

PublicOption[LabelPosition, LabelOrientation, LabelRectification]

PublicOption[ArrowheadShape, ArrowheadSize, ArrowheadStyle, ArrowheadPosition]

PublicOption[ArrowPathSetback, Setback]
