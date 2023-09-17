PrivateVariable[$RulePattern]

$RulePattern = _Rule | _RuleDelayed;

(**************************************************************************************************)

PrivateVariable[$RuleListPattern]

$RuleListPattern = {RepeatedNull[_Rule | _RuleDelayed]};

(**************************************************************************************************)

PrivateVariable[$SymbolicSizePattern]

$SymbolicSizePattern = Tiny | Small | MediumSmall | Medium | MediumLarge | Large | Huge;

SetUsage @ "
$SymbolicSizePattern is a pattern that matches a symbolic size like Small, Medium, etc.
"

(**************************************************************************************************)

PrivateVariable[$SizePattern]

$SizePattern = Tiny | Small | MediumSmall | Medium | MediumLarge | Large | Huge | Scaled[_?NumericQ];

SetUsage @ "
$SizePattern is a pattern that matches a numeric or symbolic size like Small, Medium, Scaled[n$], etc.
"

(**************************************************************************************************)

PrivateVariable[$SidePattern]

$SidePattern = Left | Right | Bottom | Top | BottomLeft | BottomRight | TopLeft | TopRight;

SetUsage @ "
$SizePattern is a pattern that matches a (potentially compound) symbol side, like Left, Top, or TopLeft.
"

PrivateVariable[$SideToCoords]

$SideToCoords = <|
  Left        -> {-1,  0},
  Right       -> { 1,  0},
  Top         -> { 0,  1},
  Above       -> { 0,  1},
  Bottom      -> { 0, -1},
  Below       -> { 0, -1},
  BottomLeft  -> {-1, -1},
  BottomRight -> { 1, -1},
  TopLeft     -> {-1,  1},
  TopRight    -> { 1,  1},
  Center      -> { 0,  0}
|>

(**************************************************************************************************)

PrivateVariable[$ColorPattern]

$ColorPattern = _RGBColor | _GrayLevel | _CMYKColor | _Hue | _XYZColor | _LABColor | _LCHColor | _LUVColor | Opacity[_, _];

SetUsage @ "
$ColorPattern is a pattern that matches a valid color, like %RGBColor[$$] etc.
"

(**************************************************************************************************)

PrivateVariable[$OpacityPattern]

$OpacityPattern = VeryTransparent | HalfTransparent | PartlyTransparent | Opaque | Opacity[_ ? NumericQ];

SetUsage @ "
$OpacityPattern is a pattern that matches an opacity specification.
"

(**************************************************************************************************)

PrivateVariable[$NotebookOrPathP, $PathP]

$NotebookOrPathP = _NotebookObject | File[_String] | _String;
$PathP = File[_String] | _String;

(**************************************************************************************************)

PrivateFunction[ListOrAssociationOf]

ListOrAssociationOf[pattern_] := {Repeated[pattern]} | Association[Repeated[_ -> pattern]];

(**************************************************************************************************)

PrivateVariable[$ModIntP]

$ModIntP = _Integer ? Positive | Modulo[_Integer ? Positive];

(**************************************************************************************************)

PrivateVariable[$PosIntOrInfinityP]

$PosIntOrInfinityP = _Integer ? Positive | Infinity;

(**************************************************************************************************)

PrivateVariable[$NumberP, $CoordP, $Coord2P, $Coord3P, $CoordPairP, $Coord2PairP, $Coord3PairP]

(* TODO: $Coord2VectorP, etc *)

$NumberP = _ ? NumericQ;

$CoordP = {_ ? NumericQ, _ ? NumericQ} | {_ ? NumericQ, _ ? NumericQ, _ ? NumericQ};
$Coord2P = {_ ? NumericQ, _ ? NumericQ};
$Coord3P = {_ ? NumericQ, _ ? NumericQ, _ ? NumericQ};

$CoordPairP = _List ? CoordinatePairQ;
$Coord2PairP = {$Coord2P, $Coord2P};
$Coord3PairP = {$Coord3P, $Coord3P};

(**************************************************************************************************)

PrivateVariable[$CoordMatP, $CoordMat2P, $CoordMat3P, $CoordMaybeMatP, $CoordMatsP, $CoordMaybeMatsP]

$CoordMat2P = _List ? CoordinateMatrix2DQ;
$CoordMat3P = _List ? CoordinateMatrix3DQ;

$CoordMatP = _List ? CoordinateMatrixQ;
$CoordMaybeMatP = _List ? CoordinateVectorOrMatrixQ;

$CoordMatsP = _List ? CoordinateMatricesQ;
$CoordMaybeMatsP = _List ? CoordinateMatrixOrMatricesQ;

(**************************************************************************************************)

PrivateVariable[$ArcP, $RegionP, $AnnotationP]

headToPattern[e_] := Apply[Alternatives, Blank /@ e];

$ArcP = headToPattern @ {
  Line, InfiniteLine, HalfLine, Arrow, FilledCurve, BezierCurve, BSplineCurve
};

$RegionP = headToPattern @ {
  Cone, FilledTorus, Torus, Cylinder, CapsuleShape,
  Dodecahedron, Icosahedron, Tetrahedron, Octahedron, Hexahedron,
  Parallelepiped, Prism, Pyramid, Simplex,
  Cuboid, Cube
};

(* TODO: handle all wrappers *)
$AnnotationP = headToPattern @ {Annotation, Tooltip, EventHandler, ClickForm};

(**************************************************************************************************)

PrivateVariable[$GPrimVecH, $GPrimVecVecH, $GPrimVecsH]

$GPrimVecH = CompassCurve | AxesFlag;

$GPrimVecVecH = Cuboid | Rectangle | ElbowCurve;

$GPrimVecsH = Point;

PrivateVariable[$GPrimVecRadH, $GPrimVecsRadH]

$GPrimVecRadH = Circle | Disk | Annulus | Cube;

$GPrimVecsRadH = Sphere | Ball | CenteredRectangle | CenteredCuboid;

PrivateVariable[$GPrimPairH, $GPrimPairRadH]

$GPrimPairH = InfiniteLine | HalfLine;

$GPrimPairRadH = Cylinder | Cone | CapsuleShape | StadiumShape;

PrivateVariable[$GPrimVecDeltaH]

(* TOD: InfinitePlane, HalfPlane, ConicHull, etc *)

$GPrimVecDeltaH = VectorCurve | Arrowhead | InfiniteLine | HalfLine;

PrivateVariable[$GPrimMatH, $GPrimMatsH, $GPrimMatsRadH]

$GPrimMatH = BSplineCurve | BezierCurve | Polygon | Polyhedron | RollingCurve | ExtendedArrow | MorphismArrow | PathedText | Simplex;

$GPrimMatsH = Polygon | Polyhedron | Line | Arrow | FilledCurve | Triangle;

$GPrimMatsRadH = Tube

PrivateVariable[$GPrimAnyVecH, $GPrimThruVecH, $GPrimThruH]

$GPrimAnyVecH = Text | Inset | PlaneInset;

$GPrimThruVecH = Translate;

$GPrimThruH = Rotate | GeometricTransformation | Scale | Style | Annotation | Tooltip | StatusArea | PopupWindow | Mouseover | Hyperlink | EventHandler | Button;

PrivateVariable[$GPrimVH, $GPrimVVH, $GPrimVRH, $GPrimVDH, $GPrimAVH]

$GPrimVH = DeleteDuplicates @ Flatten @ Alternatives[$GPrimVecH, $GPrimVecsH, $GPrimMatH, $GPrimMatsH, $GPrimPairH];
$GPrimVRH = DeleteDuplicates @ Flatten @ Alternatives[$GPrimVecRadH, $GPrimVecsRadH, $GPrimMatsRadH, $GPrimPairRadH];
$GPrimVVH = $GPrimVecVecH;
$GPrimVDH = $GPrimVecDeltaH;
$GPrimAVH = $GPrimAnyVecH;

