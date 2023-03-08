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
    destructor Destroy;
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
    CheckedNodes: integer;
    NearestNeighbour: PNode;
    DistMin: Integer;
    NodeCounter: integer;
    Target: TCoord;
    pq: TPriorityQueue;
    function FindParentNode(const arr: TCoord; Tree: PNode): PNode;
    procedure CheckSubtree(Node: PNode;
      const Coord: TCoord; Depth: integer=0);
  public
    constructor Create;
    function BuildTree(arr: TCoordVec; Depth: integer=0): PNode;
    procedure Enumerate(Tree: PNode);
    procedure ShowTree(Node: PNode);
    procedure Map(proc: TProc; Node: PNode);
    function FindNearest(const Coord: TCoord; Tree: PNode): PNode;
    procedure FindKNearest(const Coord: TCoord; Tree: PNode;
      k: integer; var KNearest: TCoordVec);

    procedure CalcDist(node: PNode);
    procedure NaiveSearch(const Coord: TCoord; Tree: PNode;
      k: integer; var KNearest: TCoordVec);
  end;


function ParseTIntMatrix(input: string): TCoordVec;

function CreateVectors(arr: array of TCoord): TCoordVec;

function InitCoord(const Data: array of const): TCoord;

function RandomVectors(Count: integer = 50;
  dim: Integer = 2; max_value: integer = 100): TCoordVec;

function VectorToStr(const Coord: TCoord): string;

procedure StrToVector(const S: string; var Coord: TCoord);


implementation


function CountChar(const input: string; const ch: char): integer;
{- Count occurrences of ch in input string }
var
  p: char;
begin
  Result := 0;
  for p in input do if p = ch then inc(Result)
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
  Coord: TCoord;
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

function InitCoord(const Data: array of const): TCoord;
var
  I: Integer;
begin
  SetLength(Result, Length(Data));
  for I := 0 to Length(Data) - 1 do
    Result[I] := Data[I].VInteger;
end;

function AppendCoord(var Coord: TCoordVec; Value: TCoord): integer;
begin
  Result := length(Coord);
  SetLength(Coord, Result + 1);
  Coord[Result] := Value
end;

function RandomVectors(Count: integer = 50;
  dim: Integer = 2; max_value: integer = 100): TCoordVec;
var
  I, J: Integer;
begin
  SetLength(Result, Count);
  for I := 0 to Length(Result) - 1 do begin
    SetLength(Result[I], dim);
    for J := 0 to dim - 1 do
      Result[I][J] := Random(max_value);
  end;
end;

function VectorToStr(const Coord: TCoord): string;
var
  I: Integer;
begin
  Result := '(';
  for I := 0 to Length(Coord) - 1 do
    if I = 0 then
      Result := Result + IntToStr(Coord[I])
    else
      Result := Result + ',' + IntToStr(Coord[I]);
  Result := Result + ')';
end;

procedure StrToVector(const S: string; var Coord: TCoord);
var
  i, idx: Integer;
  Value: string;
begin
  idx := 0;
  i := 1;
  while (i <= Length(S)) and (idx < Length(Coord)) do begin
    if CharInSet(S[i], ['0'..'9']) then
      Value := Value + S[i]
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
  arr[a] := temp;
end;

(*
procedure Sort(var arr: TCoordVec; Axis: integer);
{- Select Sort }
var
  i, j, n: integer;
begin
  n := length(arr);
  for i := 0 to n - 1 do
    for j := i + 1 to n - 1 do
      if arr[j][Axis] < arr[i][Axis] then
        Swap(arr, i, j)
end;
*)

procedure Sort(var arr: TCoordVec; Axis: integer; iLo, iHi: integer);
{- QuickSort }
var
  Lo, Hi: integer;
  pv: integer;
begin
  Lo := iLo; Hi := iHi;
  pv := arr[(Lo + Hi) div 2][Axis];
  repeat
    while arr[Lo][Axis] < pv do inc(Lo);
    while arr[Hi][Axis] > pv do dec(Hi);
    if Lo <= Hi then begin
      Swap(arr, Lo, Hi);
      inc(Lo); dec(Hi);
    end;
  until Lo > Hi;
  if Hi > iLo then Sort(arr, Axis, iLo, Hi);
  if Lo < iHi then Sort(arr, Axis, Lo, iHi);
end;

function DistSq(const Coord1, Coord2: TCoord): Integer;
{- Square of the distance between Coords }
var
  i: Integer;
  delta: integer;
begin
  Result := 0;
  for i := 0 to Length(Coord1) - 1 do begin
    delta := Coord1[i] - Coord2[i];
    Result := Result + delta * delta;
  end;
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
  Fitems[cp] := item;
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
  siftdn(sp, cp);
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
  siftdn(0, FCount-1);
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
  Result := last.Value;
end;

function TPriorityQueue.Empty: boolean;
begin
  Result := FCount <= 0;
end;

{ TKDTree }

constructor TKDTree.Create;
begin
  NodeCounter := 1;
  pq := TPriorityQueue.Create;
end;

function TKDTree.BuildTree(arr: TCoordVec; Depth: integer=0): PNode;
var
  n, K, Axis, Median: integer;
begin
  Result := nil;

  n := length(arr);
  if n = 0 then Exit;
  if n = 1 then begin
    New(Result);
    Result.Coord := arr[0];
    Exit;
  end;

  K := Length(arr[0]);
  Axis := Depth mod K;
  Sort(arr, Axis, 0, n-1);
  Median := Length(arr) div 2;

  New(Result);
  Result.Coord := arr[Median];

  Result.Left := BuildTree(Copy(arr, 0, Median), Depth+1);
  if Result.Left <> nil then
    Result.Left.Parent := Result;

  Result.Right := BuildTree(Copy(arr, Median+1, MaxInt), Depth+1);
  if Result.Right <> nil then
    Result.Right.Parent := Result;

end;

procedure TKDTree.Enumerate(Tree: PNode);
begin
  if Tree = nil then Exit;

  if Tree.Left <> nil then
    Enumerate(Tree.Left);

  Tree.id := NodeCounter;
  inc(NodeCounter);

  if Tree.Right <> nil then
    Enumerate(Tree.Right);
end;

procedure TKDTree.ShowTree(Node: PNode);
begin
  if Node <> nil then begin
    ShowTree(Node.Left);
    Writeln(IntToStr(Node.Id), ':', VectorToStr(Node.Coord));
    ShowTree(Node.Right);
  end;
end;

procedure TKDTree.Map(proc: TProc; Node: PNode);
{- apply proc to every node in tree }
begin
  if Node <> nil then begin
    Map(proc, Node.Left);
    proc(Node);
    Map(proc, Node.Right);
  end;
end;

function TKDTree.FindParentNode(const arr: TCoord; Tree: PNode): PNode;
var
  Next: PNode;
  Depth, Axis: integer;
begin
  Result := nil;
  Depth := 0;
  Next := Tree;
  while Next <> nil do begin
    Result := Next;
    Axis := Depth mod Length(arr);
    if arr[Axis] > Next.Coord[Axis] then
      Next := Next.Right
    else
      Next := Next.Left;
    inc(Depth);
  end;
end;

procedure TKDTree.CheckSubtree(Node: PNode;
  const Coord: TCoord; Depth: integer = 0);
var
  Dist, Axis: integer;
  n: integer;
begin
  if Node = nil then Exit;
  inc(CheckedNodes);

  Dist := DistSq(Coord, Node.Coord);

  // push node.Coord onto min priority queue
  pq.Push(Dist, Node.Coord);

  // record nearest
  if Dist < DistMin then begin
    DistMin := Dist;
    NearestNeighbour := Node;
  end;

  Axis := Depth mod Length(Node.Coord);
  Dist := Node.Coord[Axis] - Coord[Axis];
  if Dist * Dist > DistMin then begin
    if Node.Coord[Axis] > Coord[Axis] then
      CheckSubtree(Node.Left, Coord, Depth+1)
    else
      CheckSubtree(Node.Right, Coord, Depth+1);
  end else begin
    CheckSubtree(Node.Left, Coord, Depth+1);
    CheckSubtree(Node.Right, Coord, Depth+1);
  end;
end;

function TKDTree.FindNearest(const Coord: TCoord; Tree: PNode): PNode;
{- find node nearest to Coord }
var
  Parent: PNode;
begin
  Result := nil;
  if Tree = nil then Exit;
  CheckedNodes := 0;
  Parent := FindParentNode(Coord, Tree);
  NearestNeighbour := Parent;
  DistMin := DistSq(Coord, Parent.Coord);
  if DistMin = 0 then Exit(NearestNeighbour);
  pq.Clear; // prepare priority queue
  CheckSubtree(Tree, Coord);
  Result := NearestNeighbour;
end;

procedure TKDTree.FindKNearest(const Coord: TCoord;
  Tree: PNode; k: integer; var KNearest: TCoordVec);
var
  Count: integer;
  Value: TCoord;
begin
  SetLength(KNearest, 0);
  FindNearest(Coord, Tree);
  Count := 0;
  while (not pq.Empty) and (Count < k) do begin
    Value := pq.Pop;
    AppendCoord(KNearest, Value);
    inc(Count);
  end;
end;

procedure TKDTree.CalcDist(node: PNode);
var
  dist: integer;
begin
  dist := DistSq(Target, node.Coord);
  pq.Push(dist, Node.Coord);
end;

procedure TKDTree.NaiveSearch(const Coord: TCoord;
  Tree: PNode; k: integer; var KNearest: TCoordVec);
{- Brute force search }
var
  Count: integer;
  Value: TCoord;
begin
  Target := Coord;
  SetLength(KNearest, 0);
  pq.Clear;
  Map(CalcDist, Tree);
  Count := 0;
  while (not pq.Empty) and (Count < k) do begin
    Value := pq.Pop;
    AppendCoord(KNearest, Value);
    inc(Count);
  end;
end;

end.
