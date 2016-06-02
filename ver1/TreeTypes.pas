//
// https://github.com/showcode
//

unit TreeTypes;

interface

uses
  SysUtils;

type
  // определение типа точки
  TKDPoint = array of Integer;
  // определение набора точек
  TKDPoints = array of TKDPoint;

  // предварительная декларация
  TKDNode = class;

  // определение типа процедуры, для обратных вызовов при поиске в дереве
  TFindCallback = procedure(const Node: TKDNode; IsBest: Boolean) of object;

  // узел дерева, содержащий точку
  TKDNode = class
  private
    FId: Integer;
    FAxis: Integer;
    FPoint: TKDPoint;
    FRight: TKDNode;
    FParent: TKDNode;
    FLeft: TKDNode;
    function Distance2To(const Point: TKDPoint): Integer;
    function Equal(const Point: TKDPoint): Boolean;
    function FindParent(const Point: TKDPoint; Callback: TFindCallback = nil): TKDNode;
    function Insert(const Point: TKDPoint): TKDNode;
  public
    constructor Create(Point: TKDPoint; Axis: Integer);
    destructor Destroy; override;

    property Axis: Integer read FAxis; // ось по которой разбивается плоскость
    property Point: TKDPoint read FPoint; // точка
    property Id: Integer read FId write FId; // идентификатор узла

    property Parent: TKDNode read FParent; // родительский узел и дочерние
    property Left: TKDNode read FLeft;
    property Right: TKDNode read FRight;
  end;

  TKDTree = class
  private
    FDim: Integer;
    FRoot: TKDNode;
    procedure FindBest(Node: TKDNode; const Point: TKDPoint; var BestNode: TKDNode; var BestDistance: Integer;
      Deep: Integer; Callback: TFindCallback = nil);
  public
    constructor Create(Dimention: Integer);
    destructor Destroy; override;

    function Add(const Point: TKDPoint): TKDNode;
    function FindBestNearest(const Point: TKDPoint; Callback: TFindCallback): TKDNode;
    procedure Clear;

    property Root: TKDNode read FRoot;
    property Dimention: Integer read FDim;
  end;

function SetKDPoint(var Point: TKDPoint; const Coords: array of const): TKDPoint;

implementation

function SetKDPoint(var Point: TKDPoint; const Coords: array of const): TKDPoint;
var
  K: Integer;
begin
  SetLength(Point, Length(Coords));
  for K := 0 to High(Point) do
    Point[K] := Coords[K].VInteger;
  Result := Point;
end;

{ TKDNode }

constructor TKDNode.Create(Point: TKDPoint; Axis: Integer);
begin
  FAxis := Axis;
  FPoint := Point;
  FLeft := nil;
  FRight := nil;
  FParent := nil;
  FId := 0;
end;

function TKDNode.FindParent(const Point: TKDPoint; Callback: TFindCallback = nil): TKDNode;
var
  Next: TKDNode;
begin
  Result := nil;
  Next := Self;
  // спускаемся до листьев, выбирая узлы которые лежат в той же
  // полуплоскости, что и заданная точка
  while Next <> nil do
  begin
    Result := Next;

    if Assigned(Callback) then
      Callback(Result, False);

    if Point[Next.Axis] > Next.Point[Next.Axis] then
      Next := Next.Right
    else
      Next := Next.Left;
  end;
end;

function TKDNode.Insert(const Point: TKDPoint): TKDNode;
var
  Parent: TKDNode;
  Axis: Integer;
begin
  Result := nil;
  // ищем родителя для точки
  Parent := FindParent(Point);
  if Parent.Equal(Point) then
    Exit;

  // создаем узел и связываем его с родительским
  Axis := (Parent.Axis + 1) mod Length(Point);
  Result := TKDNode.Create(Point, Axis);
  Result.FParent := Parent;
  if Point[Parent.Axis] > Parent.Point[Parent.Axis] then
    Parent.FRight := Result
  else
    Parent.FLeft := Result;
end;

destructor TKDNode.Destroy;
begin
  FLeft.Free;
  FRight.Free;
  inherited;
end;

function TKDNode.Distance2To(const Point: TKDPoint): Integer;
var
  Axis: Integer;
begin
  Result := 0;
  // вычисляем квадрат расстояния между точками
  for Axis := Low(FPoint) to High(FPoint) do
    Result := Result + (FPoint[Axis] - Point[Axis]) * (FPoint[Axis] - Point[Axis]);
end;

function TKDNode.Equal(const Point: TKDPoint): Boolean;
var
  Axis: Integer;
begin
  Result := False;
  // сравниваем точки по координатам
  for Axis := Low(FPoint) to High(FPoint) do
    if FPoint[Axis] <> Point[Axis] then
      Exit;
  Result := True;
end;

{ TKDTree }

constructor TKDTree.Create(Dimention: Integer);
begin
  FDim := Dimention;
  FRoot := nil;
end;

destructor TKDTree.Destroy;
begin
  inherited;
  Clear;
end;

function TKDTree.Add(const Point: TKDPoint): TKDNode;
begin
  if Root = nil then
  begin
    FRoot := TKDNode.Create(Point, 0);
    Result := Root;
  end
  else
  begin
    Result := Root.Insert(Point);
  end;
end;

function TKDTree.FindBestNearest(const Point: TKDPoint; Callback: TFindCallback): TKDNode;
var
  Distance: Integer;
begin
  Result := nil;
  if Root = nil then
    Exit;
  // согласно концепции, выполняем обычный поиск узла, который мог бы стать
  // родителем нашей точки и принимаем этот узел как "лучший результат"
  Result := Root.FindParent(Point, Callback);
  Distance := Result.Distance2To(Point);
  // проверяем, может это та самая точка
  if Result.Equal(Point) then
    Exit;

  if Assigned(Callback) then
    Callback(Result, True);

  // выполняем поиск по дереву, пытаясь найти узел с минимальной дистанцией
  FindBest(Root, Point, Result, Distance, 0, Callback);
end;

procedure TKDTree.FindBest(Node: TKDNode; const Point: TKDPoint; var BestNode: TKDNode; var BestDistance: Integer;
  Deep: Integer; Callback: TFindCallback = nil);
var
  Distance: Integer;
begin
  if Node = nil then
    Exit;

  // если точка данного узла ближе, чем предыдущие, делаем ее "лучшим результатом"
  Distance := Node.Distance2To(Point);
  if Distance < BestDistance then
  begin
    BestDistance := Distance;
    BestNode := Node;
  end;

  if Assigned(Callback) then
    Callback(Node, BestNode = Node);

  // теперь нужно проверить, может существует более лучшая точка в других плоскостях

  // вычисляем растояние до искомой точки в текущей плоскости
  Distance := Node.Point[Node.Axis] - Point[Node.Axis];

  // если расстояние до искомой точки в текущей плоскости меньше чем растояние
  // в пространстве, проверяем все низлежащие подпространства
  if (Distance * Distance) <= BestDistance then
  begin
    FindBest(Node.Left, Point, BestNode, BestDistance, Deep + 1, Callback);
    FindBest(Node.Right, Point, BestNode, BestDistance, Deep + 1, Callback);
  end
  else // выбираем для поиска ту полуплоскость в которой находится искомая точка
  if Node.Point[Node.Axis] > Point[Node.Axis] then
    FindBest(Node.Left, Point, BestNode, BestDistance, Deep + 1, Callback)
  else
    FindBest(Node.Right, Point, BestNode, BestDistance, Deep + 1, Callback);
end;

procedure TKDTree.Clear;
begin
  FreeAndNil(FRoot);
end;

end.
