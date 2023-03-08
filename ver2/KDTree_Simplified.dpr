program KDTree_Simplified;
{$apptype console}

uses
  SysUtils,
  Velthuis.Console,
  uKDTree;

var
  KDTree: TKDTree;
  Root, Node: PNode;
  arr, kNearest: TCoordVec;
  Target: TCoord;
  coord: TCoord;
begin
  Randomize;

  // RosettaCode example
  arr := ParseTIntMatrix('[[2,3],[5,4],[9,6],[4,7],[8,1],[7,2]]');
  Target := InitCoord([9,2]);

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

  Writeln('KNearest');
  KDTree.FindKNearest(Target, Root, 3, kNearest);
  for coord in kNearest do
    writeln(VectorToStr(coord));
  writeln;

  KDTree.Free;
  Pause;
end.
