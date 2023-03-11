{ ----------------------------------------------------------------------------
  K Dimension Tree
  Range search for point in multiple dimensions

  Source:
    https://github.com/showcode/kdtree
    https://en.wikipedia.org/wiki/K-d_tree
    https://rosettacode.org/wiki/K-d_tree

  8 March 2023
  Bruce Wernick
  ---------------------------------------------------------------------------- }

unit uKDTree;

interface

uses
  SysUtils;

type
  TCoord = array of integer;
  TCoordVec = array of TCoord;

  TCoordArray = class
  private
    FItems: array of TCoord;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Append(Value: TCoord): integer;
  end;

  TPriorityQueue = class
    type
      TItem = record
        Priority: double;
        Value: TCoord;
      end;
  private
    FItems: array of TItem;
    FCount: integer;
    FSize: integer;
    procedure siftdn(sp, cp: integer);
    procedure siftup(cp: integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Push(Priority: double; Value: TCoord);
    function Pop: TCoord;
    function Empty: boolean;
  end;

  PNode = ^TNode;
  TNode = record
    id: Cardinal;
    Left, Right: PNode;
    Parent: PNode;
    Coord: TCoord;
  end;

  TProc = procedure (np: PNode) of object;

  TKDTree = class
  private
    dim: integer;
    NearestNeighbour: PNode;
    DistMin: Integer;
    NodeCounter: integer;
    Target: TCoord;
    pq: TPriorityQueue;
    function FindParentNode(const arr: TCoord; np: PNode): PNode;
    procedure CheckSubtree(np: PNode; const Coord: TCoord; Depth: integer=0);
  public
    CheckedNodes: integer;
    constructor Create;
    function BuildTree(arr: TCoordVec; Depth: integer=0): PNode;
    procedure Enumerate(np: PNode);
    procedure ShowTree(np: PNode);
    procedure Map(proc: TProc; np: PNode);
    function FindNearest(const Coord: TCoord; np: PNode): PNode;
    procedure FindNNearest(const Coord: TCoord; np: PNode;
      n: integer; var NNearest: TCoordVec);
    procedure CalcDist(np: PNode);
    procedure FindAll(const Coord: TCoord; np: PNode;
      n: integer; var KNearest: TCoordVec);
  end;

function ParseTIntMatrix(input: string): TCoordVec;
function CreateVectors(arr: array of TCoord): TCoordVec;
function InitCoord(const Data: array of const): TCoord;

function RandomVectors(Count: integer = 50; dim: integer = 2;
  min_value: integer = 0; max_value: integer = 100): TCoordVec;

function VectorToStr(const Coord: TCoord): string;
procedure StrToVector(const str: string; var Coord: TCoord);
function DistSq(const Coord1, Coord2: TCoord): integer;


implementation


function CountChar(const input: string; const ch: char): integer;
{- Count occurrences of ch in input string }
var
  p: char;
begin
  Result := 0;
  for p in input do
    if p = ch then inc(Result)
end;

function ParseTIntMatrix(input: string): TCoordVec;
const
  digits = ['0'..'9'];
var
  p, q, n: integer;
  t: string;
  col, row: integer;
  cols, rows: integer;
  IntValue: integer;
begin
  // to simplify the parsing loop,
  // convert string to i,i,i;i,i,i;i,i,i
  input := StringReplace(input, ' ', '', [rfReplaceAll]);
  input := StringReplace(input, '[[', '', [rfReplaceAll]);
  input := StringReplace(input, ']]', '', [rfReplaceAll]);
  input := StringReplace(input, '],[', ';', [rfReplaceAll]);

  // size array according to comma and semicolon count
  rows := 1 + CountChar(input, ';');
  cols := 1 + CountChar(input, ',') div rows;
  SetLength(Result, rows, cols);

  // init counters
  row := 0;
  col := 0;
  n := length(input);
  p := 1;

  while (p <= n) do begin
    q := p; // q = start of digit

    // set p to end of digits
    while (CharInSet(input[p], digits)) and (p <= n) do inc(p);

    // get integer
    t := copy(input, q, p-q);
    IntValue := StrToIntDef(t, 0);
    Result[row][col] := IntValue;

    // check for new row
    if (input[p] = ';') and (p <= n) then begin
      inc(p);
      inc(row);
      col := 0;
      continue;
    end;
    inc(p);
    inc(col);
  end;
end;

function CreateVectors(arr: array of TCoord): TCoordVec;
var
  i, j, n, k: integer;
begin
  n := length(arr);
  k := length(arr[0]);
  SetLength(Result, n);
  for i := 0 to n - 1 do begin
    SetLength(Result[i], k);
    for j := 0 to k - 1 do begin
      Result[i][j] := arr[i][j];
    end;
  end;
end;

function InitCoord(const data: array of const): TCoord;
var
  i, n: integer;
begin
  n := length(data);
  SetLength(Result, n);
  for i := 0 to n - 1 do
    Result[i] := data[i].VInteger;
end;

function AppendCoord(var Coord: TCoordVec; Value: TCoord): integer;
begin
  Result := length(Coord);
  SetLength(Coord, Result + 1);
  Coord[Result] := Value
end;

function RandomVectors(Count: integer = 50; dim: integer = 2;
  min_value: integer = 0; max_value: integer = 100): TCoordVec;

  function Contains(arr: array of TCoord; idx: integer; coord: TCoord): boolean;
  var
    i: integer;
  begin
    Result := False;
    for i := 0 to idx do
      if DistSq(arr[i], coord) < 40 then Exit(True);
  end;

var
  i, j: integer;
  v: integer;
  coord: TCoord;
  unique: boolean;
begin
  SetLength(coord, dim);
  SetLength(Result, Count);
  for i := 0 to Length(Result) - 1 do begin
    SetLength(Result[i], dim);
    repeat
      for j := 0 to dim - 1 do begin
        v := min_value + Random(max_value - min_value);
        coord[j] := v;
      end;
      unique := not Contains(Result, i, coord);
      Result[i] := copy(coord, 0, dim);
    until unique;
  end;
end;

function VectorToStr(const Coord: TCoord): string;
var
  i: integer;
begin
  Result := '(';
  for i := 0 to Length(Coord) - 1 do
    if i = 0 then
      Result := Result + IntToStr(Coord[i])
    else
      Result := Result + ',' + IntToStr(Coord[i]);
  Result := Result + ')';
end;

procedure StrToVector(const str: string; var Coord: TCoord);
var
  i, idx: integer;
  Value: string;
begin
  idx := 0;
  i := 1;
  while (i <= length(str)) and (idx < length(Coord)) do begin
    if CharInSet(str[i], ['0'..'9']) then
      Value := Value + str[i]
    else if Value <> '' then begin
      Coord[idx] := StrToInt(Value);
      Value := '';
      inc(idx);
    end;
    inc(i);
  end;
  if Value <> '' then
    Coord[idx] := StrToInt(Value);
end;

procedure Swap(var arr: TCoordVec; a, b: integer);
var
  temp: TCoord;
begin
  temp := arr[b];
  arr[b] := arr[a];
  arr[a] := temp
end;

(*
procedure Sort(var arr: TCoordVec; axis: integer);
{- Select Sort }
var
  i, j, n: integer;
begin
  n := length(arr);
  for i := 0 to n - 1 do
    for j := i + 1 to n - 1 do
      if arr[j][axis] < arr[i][axis] then
        Swap(arr, i, j)
end;
*)

procedure Sort(var arr: TCoordVec; axis: integer; iLo, iHi: integer);
{- QuickSort }
var
  Lo, Hi: integer;
  pv: integer;
begin
  Lo := iLo; Hi := iHi;
  pv := arr[(Lo + Hi) div 2][axis];
  repeat
    while arr[Lo][axis] < pv do inc(Lo);
    while arr[Hi][axis] > pv do dec(Hi);
    if Lo <= Hi then begin
      Swap(arr, Lo, Hi);
      inc(Lo); dec(Hi);
    end;
  until Lo > Hi;
  if Hi > iLo then Sort(arr, axis, iLo, Hi);
  if Lo < iHi then Sort(arr, axis, Lo, iHi);
end;

function DistSq(const Coord1, Coord2: TCoord): integer;
{- Square of the distance between Coords }
var
  i: integer;
begin
  Result := 0;
  for i := 0 to Length(Coord1) - 1 do
    Result := Result + sqr(Coord1[i] - Coord2[i])
end;

{ TCoordArray }

constructor TCoordArray.Create;
begin
  SetLength(FItems, 0);
end;

destructor TCoordArray.Destroy;
begin
  SetLength(FItems, 0);
  inherited;
end;

procedure TCoordArray.Clear;
begin
  SetLength(FItems, 0);
end;

function TCoordArray.Append(Value: TCoord): integer;
begin
  Result := length(FItems);
  SetLength(FItems, Result + 1);
  FItems[Result] := Value
end;

{ TPriorityQueue }

constructor TPriorityQueue.Create;
begin
  FSize := 0;
  FCount := 0;
end;

destructor TPriorityQueue.Destroy;
begin
  FSize := 0;
  FCount := 0;
  SetLength(FItems, 0);
end;

procedure TPriorityQueue.Clear;
begin
  FSize := 0;
  FCount := 0;
  SetLength(FItems, 0);
end;

procedure TPriorityQueue.siftdn(sp, cp: integer);
{- sift down }
var
  item, parent: TItem;
  pp: integer;
begin
  item := FItems[cp];
  while cp > sp do begin
    pp := (cp - 1) shr 1;
    parent := FItems[pp];
    if item.Priority < parent.Priority then begin
      FItems[cp] := parent;
      cp := pp;
      Continue;
    end;
    Break;
  end;
  Fitems[cp] := item
end;

procedure TPriorityQueue.siftup(cp: integer);
{- sift up }
var
  sp, ep: integer;
  hp, rp: integer;
  item: TItem;
begin
  ep := FCount; // ???
  sp := cp;
  item := FItems[cp];
  hp := 2*cp + 1;
  while hp < ep do begin
    rp := hp + 1;
    if (rp < ep) and not (FItems[hp].Priority < FItems[rp].Priority) then
      hp := rp;
    FItems[cp] := FItems[hp];
    cp := hp;
    hp := 2*cp + 1;
  end;
  FItems[cp] := item;
  siftdn(sp, cp)
end;

procedure TPriorityQueue.Push(Priority: double; Value: TCoord);
{- push item onto priority queue }
begin
  if (FCount + 1 >= FSize) then begin
    if FSize > 0 then
      FSize := FSize * 2
    else
      FSize := 4;
  end;
  SetLength(FItems, FSize);
  FItems[FCount].Priority := Priority;
  FItems[FCount].Value := Value;
  inc(FCount);
  siftdn(0, FCount-1)
end;

function TPriorityQueue.Pop: TCoord;
{- pop item from priority queue }
var
  item, last: TItem;
begin
  last := FItems[FCount-1];
  if FCount > 0 then begin
    dec(FCount);
    item := FItems[0];
    FItems[0] := last;
    siftup(0);
    Exit(item.Value);
  end;
  Result := last.Value
end;

function TPriorityQueue.Empty: boolean;
begin
  Result := FCount <= 0
end;

{ TKDTree }

constructor TKDTree.Create;
begin
  NodeCounter := 1;
  pq := TPriorityQueue.Create
end;

function TKDTree.BuildTree(arr: TCoordVec; depth: integer=0): PNode;
var
  n, axis, median: integer;
begin
  Result := nil;

  n := length(arr);
  if n = 0 then Exit;
  if n = 1 then begin
    New(Result);
    Result.Coord := arr[0];
    Exit;
  end;

  dim := length(arr[0]);
  axis := depth mod dim;
  Sort(arr, axis, 0, n-1);
  median := n div 2;

  New(Result);
  Result.Coord := arr[median];

  Result.Left := BuildTree(Copy(arr, 0, median), depth+1);
  if Result.Left <> nil then
    Result.Left.Parent := Result;

  Result.Right := BuildTree(Copy(arr, median+1, n-median), depth+1);
  if Result.Right <> nil then
    Result.Right.Parent := Result;
end;

procedure TKDTree.Enumerate(np: PNode);
begin
  if np = nil then Exit;
  if np.Left <> nil then
    Enumerate(np.Left);
  np.id := NodeCounter;
  inc(NodeCounter);
  if np.Right <> nil then
    Enumerate(np.Right);
end;

procedure TKDTree.ShowTree(np: PNode);
begin
  if np <> nil then begin
    ShowTree(np.Left);
    Writeln(IntToStr(np.id), ':', VectorToStr(np.Coord));
    ShowTree(np.Right);
  end;
end;

procedure TKDTree.Map(proc: TProc; np: PNode);
{- apply proc to every node in tree }
begin
  if np <> nil then begin
    proc(np);
    Map(proc, np.Left);
    Map(proc, np.Right);
  end;
end;

function TKDTree.FindParentNode(const arr: TCoord; np: PNode): PNode;
var
  next: PNode;
  depth, axis: integer;
begin
  Result := nil;
  depth := 0;
  next := np;
  while next <> nil do begin
    Result := next;
    axis := depth mod length(arr);
    if arr[axis] > Next.Coord[axis] then
      next := next.Right
    else
      next := next.Left;
    inc(depth);
  end;
end;

procedure TKDTree.CheckSubtree(np: PNode;
  const Coord: TCoord; Depth: integer = 0);
{- }
var
  dist, axis: integer;
  plane, targ: integer;
begin
  if np = nil then Exit;
  inc(CheckedNodes);

  dist := DistSq(Coord, np.Coord);

  // record nearest
  if dist < DistMin then begin
    DistMin := dist;
    NearestNeighbour := np;
  end;

  // push node.Coord onto min priority queue
  pq.Push(dist, np.Coord);

  axis := Depth mod dim;
  plane := np.Coord[axis];
  targ := Coord[axis];

  if targ <= plane then
    CheckSubtree(np.left, Coord, depth+1)
  else
    CheckSubtree(np.right, Coord, depth+1);

  // check the other side of the plane
  if sqr(targ - plane) < DistMin then begin
    if targ <= plane then
      CheckSubtree(np.right, Coord, depth+1)
    else
      CheckSubtree(np.left, Coord, depth+1);
  end;

end;

function TKDTree.FindNearest(const Coord: TCoord; np: PNode): PNode;
{- find node nearest to Coord }
var
  Parent: PNode;
begin
  Result := nil;
  if np = nil then Exit;
  CheckedNodes := 0;
  Parent := FindParentNode(Coord, np);
  NearestNeighbour := Parent;
  DistMin := DistSq(Coord, Parent.Coord);
  if DistMin = 0 then Exit(NearestNeighbour);
  pq.Clear; // prepare priority queue
  CheckSubtree(np, Coord);
  Result := NearestNeighbour;
end;

procedure TKDTree.FindNNearest(const Coord: TCoord;
  np: PNode; n: integer; var NNearest: TCoordVec);
{- find the n nearest nodes to Coord }
var
  Count: integer;
  Value: TCoord;
begin
  SetLength(NNearest, 0);
  FindNearest(Coord, np);
  Count := 0;
  while (not pq.Empty) and (Count < n) do begin
    Value := pq.Pop;
    AppendCoord(NNearest, Value);
    inc(Count);
  end;
end;

procedure TKDTree.CalcDist(np: PNode);
{- distance between node and target }
var
  dist: integer;
begin
  dist := DistSq(Target, np.Coord);
  pq.Push(dist, np.Coord);
end;

procedure TKDTree.FindAll(const Coord: TCoord;
  np: PNode; n: integer; var KNearest: TCoordVec);
{- Brute force search }
var
  Count: integer;
  Value: TCoord;
begin
  Target := Coord;
  SetLength(KNearest, 0);
  pq.Clear;
  Map(CalcDist, np);
  Count := 0;
  while (not pq.Empty) and (Count < n) do begin
    Value := pq.Pop;
    AppendCoord(KNearest, Value);
    inc(Count);
  end;
end;

end.
