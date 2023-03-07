program KDTree_Simplified;
{$apptype console}

uses
  SysUtils,
  uKDTree;

var
  KDTree: TKDTree;
  Root, Node: PNode;
  arr: TVectors;
  Target: TCoord;
begin
  Randomize;

  // RosettaCode example
  arr := ParseTIntMatrix('[[2,3],[5,4],[9,6],[4,7],[8,1],[7,2]]');
  Target := InitCoord([9,2]);

  // Big random example
  //arr := RandomVectors(1000, 2, 100);
  //Target := InitCoord([50,50]);

  KDTree := TKDTree.Create;
  Root := KDTree.BuildTree(arr);
  KDTree.Enumerate(Root);
  KDTree.ShowTree(Root);
  Node := KDTree.FindNearest(Target, Root);
  Writeln('target: ', VectorToStr(Target));
  Writeln('nearest: ', VectorToStr(Node.Coord));
  KDTree.Free;
  readln;
end.
