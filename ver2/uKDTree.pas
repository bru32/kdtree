{ ----------------------------------------------------------------------------
  K Dimension Tree
  Range search for point in multiple dimensions

  Source:
    https://github.com/showcode/kdtree
    https://en.wikipedia.org/wiki/K-d_tree
    https://rosettacode.org/wiki/K-d_tree

  25 February 2023
  Bruce Wernick
  ---------------------------------------------------------------------------- }

unit uKDTree;

interface

uses
  SysUtils;

type
  TCoord = array of Integer;
  TVectors = array of TCoord;

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
    CheckedNodes: Integer;
    NearestNeighbour: PNode;
    DistMin: Integer;
    NodeCounter: Integer;
    function FindParentNode(const arr: TCoord; Tree: PNode): PNode;
    procedure CheckSubtree(Node: PNode;
      const Coord: TCoord; Depth: Integer=0);
  public
    constructor Create;
    function BuildTree(arr: TVectors; Depth: Integer=0): PNode;
    procedure Enumerate(Tree: PNode);
    procedure ShowTree(Node: PNode);
    procedure Map(proc: TProc; Node: PNode);
    function FindNearest(const Coord: TCoord; Tree: PNode): PNode;
  end;


function ParseTIntMatrix(input: string): TVectors;

function CreateVectors(arr: array of TCoord): TVectors;

function InitCoord(const Data: array of const): TCoord;

function RandomVectors(Count: integer = 50;
  dim: Integer = 2; max_value: integer = 100): TVectors;

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

function ParseTIntMatrix(input: string): TVectors;
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

function CreateVectors(arr: array of TCoord): TVectors;
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

function RandomVectors(Count: integer = 50;
  dim: Integer = 2; max_value: integer = 100): TVectors;
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
  I, Idx: Integer;
  Value: string;
begin
  Idx := 0;
  I := 1;
  while (I <= Length(S)) and (Idx < Length(Coord)) do begin
    if CharInSet(S[I], ['0'..'9']) then
      Value := Value + S[I]
    else if Value <> '' then begin
      Coord[Idx] := StrToInt(Value);
      Value := '';
      inc(Idx);
    end;
    inc(I);
  end;
  if Value <> '' then
    Coord[Idx] := StrToInt(Value);
end;

procedure Swap(var arr: TVectors; I, J: integer);
var
  T: TCoord;
begin
  T := arr[J];
  arr[J] := arr[I];
  arr[I] := T;
end;

(*
procedure Sort(var arr: TVectors; Axis: Integer);
{- Select Sort }
var
  I, J: Integer;
begin
  for I := 0 to Length(arr) - 1 do
    for J := I + 1 to Length(arr) - 1 do
      if arr[J][Axis] < arr[I][Axis] then
        Swap(arr, I, J);
end;
*)

procedure Sort(var arr: TVectors; Axis: integer; iLo, iHi: integer);
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

function DistSq(const V1, V2: TCoord): Integer;
{- Square of the distance between V1 and V2 }
var
  K: Integer;
  delta: integer;
begin
  Result := 0;
  for K := 0 to Length(V1) - 1 do begin
    delta := V1[K] - V2[K];
    Result := Result + delta * delta;
  end;
end;

{ TKDTree }

constructor TKDTree.Create;
begin
  NodeCounter := 1;
end;

function TKDTree.BuildTree(arr: TVectors; Depth: Integer=0): PNode;
var
  n, K, Axis, Median: Integer;
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

  Tree.Id := NodeCounter;
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
  Depth, Axis: Integer;
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
  const Coord: TCoord; Depth: Integer = 0);
var
  Dist, Axis: Integer;
begin
  if Node = nil then Exit;
  inc(CheckedNodes);
  Dist := DistSq(Coord, Node.Coord);
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
  CheckSubtree(Tree, Coord);
  Result := NearestNeighbour;
end;

end.
