program kd;
{$apptype console}

uses
  SysUtils,
  uKDTree;

var
  KDTree: TKDTree;
  Root, Node: PNode;
  arr, nNearest: TCoordVec;
  Target: TCoord;
  coord: TCoord;
begin
  Randomize;

  // RosettaCode example
  arr := ParseTIntMatrix('[[1,3],[1,8],[2,2],[2,10],[3,6],[4,1],[5,4],[6,8],[7,4],[7,7],[8,2],[8,5],[9,9]]');
  Target := InitCoord([4,8]);

  // Random example
  //arr := RandomVectors(40, 2, 100);
  //Target := InitCoord([50,50]);

  KDTree := TKDTree.Create;
  Root := KDTree.BuildTree(arr);

  writeln('ShowTree');
  KDTree.Enumerate(Root);
  KDTree.ShowTree(Root);
  writeln;

  Writeln('target: ', VectorToStr(Target));

  Node := KDTree.FindNearest(Target, Root);
  Writeln('nearest: ', VectorToStr(Node.Coord));
  writeln;

  Writeln('nNearest');
  KDTree.FindNNearest(Target, Root, 3, nNearest);
  for coord in nNearest do
    writeln(VectorToStr(coord));
  writeln;

  KDTree.Free;
  readln;
end.
