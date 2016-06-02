//
// https://github.com/showcode
//

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, TreeTypes;

type
  TMainForm = class(TForm)
    pbxDiagram: TPaintBox;
    btnSearch: TButton;
    btnCreateTree: TButton;
    Edit1: TEdit;
    edtDimention: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure pbxDiagramPaint(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnCreateTreeClick(Sender: TObject);
  private
    { Private declarations }
    procedure VisitNode(const Node: TKDNode; IsBest: Boolean);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  RANDOM_POINTS_COUNT = 15;
  RANDOM_MAX_VALUE = 20;


var
  Tree: TKDTree = nil;
  SelectedNode: TKDNode = nil;
  ViewNode: TKDNode = nil;
  BestNode: TKDNode = nil;

procedure RandomPoint(var Point: TKDPoint; Dim: Integer);
var
  I: Integer;
begin
  SetLength(Point, Dim);
  for I := 0 to Dim - 1 do
    Point[I] := Random(RANDOM_MAX_VALUE);
end;

procedure SetId;
var
  Id: Integer;
  Node, Prev: TKDNode;
begin
  Id := 1;
  Node := Tree.Root;
  Prev := Node;
  // выполняем "прямой обход" дерева, при этом прежде чем повернуть направо,
  // будем устанавливать id узла
  while Assigned(Node) do
  begin
    if Prev = Node.Left then
    begin
      Prev := Node;
      Node.Id := Id;
      Inc(Id);
      if Assigned(Node.Right) then
        Node := Node.Right
      else
        Node := Node.Parent;
    end
    else if Prev = Node.Right then
    begin
      Prev := Node;
      Node := Node.Parent;
    end
    else
    begin
      Prev := Node;
      if Assigned(Node.Left) then
        Node := Node.Left
      else
      begin
        Node.Id := Id;
        Inc(Id);
        if Assigned(Node.Right) then
          Node := Node.Right
        else
          Node := Node.Parent;
      end;
    end;
  end;
end;

procedure FillTree(Count: Integer);
var
  I: Integer;
  Point: TKDPoint;
begin
  Randomize;
  for I := 0 to Count - 1 do
  begin
    RandomPoint(Point, Tree.Dimention);
    Tree.Add(Point);
  end;
  SetId;
end;


procedure TMainForm.FormCreate(Sender: TObject);
var
  P: TKDPoint;
begin
  Randomize;
  Tree := TKDTree.Create(2);

  Tree.Add(SetKDPoint(P, [2, 3]));
  Tree.Add(SetKDPoint(P, [5, 4]));
  Tree.Add(SetKDPoint(P, [9, 6]));
  Tree.Add(SetKDPoint(P, [4, 7]));
  Tree.Add(SetKDPoint(P, [8, 1]));
  Tree.Add(SetKDPoint(P, [7, 2]));
  SetId();

end;

procedure TMainForm.btnCreateTreeClick(Sender: TObject);
var
  Dim: Integer;
begin
  // парсинг размерности
  Dim := StrToInt(edtDimention.Text);

  // удаляем старое дерево
  Tree.Clear;
  if Tree.Dimention <> Dim then
  begin
    Tree.Free;
    Tree := TKDTree.Create(Dim);
  end;

  FillTree(RANDOM_POINTS_COUNT);

  pbxDiagram.Repaint;
end;

procedure TMainForm.btnSearchClick(Sender: TObject);
var
  Point: TKDPoint;
  I, First, Last: Integer;
  S: string;
begin
  S := Edit1.Text;
  // парсинг координат точки для поиска
  SetLength(Point, Tree.Dimention);
  First := 1;
  for I := 0 to Length(Point) - 1 do
  begin
    while (First <= Length(S)) and not (S[First] in ['0'..'9']) do
      Inc(First);
    if First = Length(S) + 1 then
      Break;
    Last := First;
    while (Last < Length(S)) and (S[Last + 1] in ['0'..'9']) do
      Inc(Last);

    Point[I] := StrToInt(Copy(S, First, Last - First + 1));
    First := Last + 1;
  end;

  // очищаем предыдущие результаты
  SelectedNode := nil;
  ViewNode := nil;
  BestNode := nil;
  pbxDiagram.Repaint;
  btnSearch.Enabled := False;
  btnCreateTree.Enabled := False;

  // ищем ближайшую точку,
  // процедура VisitNode будет вызываться при просмотре каждого узла
  SelectedNode := Tree.FindBestNearest(Point, VisitNode);

  btnSearch.Enabled := True;
  btnCreateTree.Enabled := True;

  pbxDiagram.Repaint;
end;

procedure TMainForm.VisitNode(const Node: TKDNode; IsBest: Boolean);
begin
  SelectedNode := nil;
  if not IsBest then
  begin
    ViewNode := Node;
    pbxDiagram.Repaint;
    Sleep(500);
    ViewNode := nil;
  end
  else
  begin
    ViewNode := Node;
    pbxDiagram.Repaint;
    Sleep(250);

    ViewNode := nil;
    BestNode := Node;
    pbxDiagram.Repaint;
    Sleep(250);
  end;
end;

procedure TMainForm.pbxDiagramPaint(Sender: TObject);
const
  VSIZE = 20;
  HSIZE = VSIZE * 4;
  VSPACING = VSIZE + 20;
  HSPACING = VSIZE;
var
  Offsets: array of Integer;
  Usage: array of Integer;
  I, MaxUsage, MaxWidth: Integer;

  function NodeToStr(Node: TKDNode): string;
  var
    I: Integer;
  begin
    Result := '(';
    for I := Low(Node.Point) to High(Node.Point) do
    begin
      if I > 0 then
        Result := Result + ',';
      Result := Result + IntToStr(Node.Point[I]);
    end;
    Result := Result + ')';
    //Result:= Format('Id=%d, Axis=%d, %s', [Node.Id, Node.Axis, Result]);
    Result := Format('%d %s', [Node.Id, Result]);
  end;

  procedure DrawNode(Node: TKDNode; Deep: Integer);
  var
    R: TRect;
    Padding: Integer;
    Color: TColor;
  begin
    if Assigned(Node) then
    begin
      // в Offsets содержатся горизонтальные смещения для каждого уровня,
      // чтобы мы знали, в какой позиции рисовать узел
      if High(Offsets) < Deep then
        SetLength(Offsets, Deep + 1);

      Padding := ((MaxWidth div Usage[Deep]) - (HSIZE)) div 2;
      R := Bounds(Offsets[Deep], Deep * (VSIZE + VSPACING), HSIZE, VSIZE);
      OffsetRect(R, Padding, 0);
      // выбираем цвет прямоугольника
      if Node = SelectedNode then
        Color := clRed
      else if Node = ViewNode then
        Color := clGreen
      else if Node = BestNode then
        Color := clBlue
      else
        Color := clLtGray;

      with pbxDiagram.Canvas do
      begin
        // рисуем примоугольник и надпись
        Brush.Color := Color;
        TextRect(R, R.Left + 2, R.Top + 2, NodeToStr(Node));
        Brush.Color := clBlack;
        FrameRect(R);

        // рисуем левый дочерний узел
        if Assigned(Node.Left) then
        begin
          DrawNode(Node.Left, Deep + 1);
          // рисуем соединитель
          MoveTo(R.Left, R.Bottom);
          LineTo(Offsets[Deep + 1] - (MaxWidth div Usage[Deep + 1] div 2), (Deep + 1) * (VSIZE + VSPACING));
        end;

        OffsetRect(R, HSIZE, 0);

        // рисуем правый дочерний узел
        if Assigned(Node.Right) then
        begin
          DrawNode(Node.Right, Deep + 1);
          // рисуем соединитель
          MoveTo(R.Left, R.Bottom);
          LineTo(Offsets[Deep + 1] - (MaxWidth div Usage[Deep + 1] div 2), (Deep + 1) * (VSIZE + VSPACING));
        end;
      end;
      Offsets[Deep] := R.Left + Padding;
    end;
  end;

  // просматриваем дерево и выясняем сколько узлов содержится на каждом уровне
  procedure Scan(Node: TKDNode; Deep: Integer);
  begin
    if Assigned(Node) then
    begin
      if High(Usage) < Deep then
        SetLength(Usage, Deep + 1);
      Inc(Usage[Deep], 1);
      Scan(Node.Left, Deep + 1);
      Scan(Node.Right, Deep + 1);
    end;
  end;

begin
  if Assigned(Tree) and Assigned(Tree.Root) then
  begin
    Scan(Tree.Root, 0);
    // выясняем, на каком уровне содержится максимальное число узлов
    MaxUsage := 0;
    for I := Low(Usage) to High(Usage) do
      if Usage[I] > MaxUsage then
        MaxUsage := Usage[I];

    // расчитываем приемлемую ширину, чтобы нарисовать дерево
    MaxWidth := MaxUsage * (HSIZE + HSPACING);
    if MaxWidth < pbxDiagram.Width then
      MaxWidth := pbxDiagram.Width;
    // рисуем дерево
    DrawNode(Tree.Root, 0);
  end;
end;

end.
