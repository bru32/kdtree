//
// https://github.com/showcode
//

program kd;

{$APPTYPE CONSOLE}

uses
  SysUtils;

const
  MAX_VALUE = 100; // максимальное значение координат, чтобы не было длинных чисел
  VECTORS_COUNT = 10; // сколько случайных векторов будут генерироваться 

type
  // определение вектора как массива координат
  // вектор однозначно определяет положение точки в пространстве
  TVector = array of Integer;
  // определение списка векторов
  TVectors = array of TVector;

  // определение узла дерева
  PNode = ^TNode;

  TNode = record
    Parent, Right, Left: PNode;// связи с соседними узлами
    V: TVector; // значение
    Id: Cardinal; // id элемента
  end;


  procedure InitVector(var V: TVector; const Coords: array of const);
  var
    I: Integer;
  begin
    SetLength(V, Length(Coords));
    for I := 0 to Length(Coords) - 1 do
      V[I] := Coords[I].VInteger;
  end;

  // генерация массива векторов со случайными координатами
  procedure GenerateVectors(var Arr: TVectors; Count, dim: Integer);
  var
    I, J: Integer;
  begin
    Randomize;
    SetLength(Arr, Count);
    for I := 0 to Length(Arr) - 1 do
    begin
      SetLength(Arr[I], dim);
      for J := 0 to dim - 1 do
        Arr[I][J] := Random(MAX_VALUE);
    end;
  end;

  // здесь мы сортируем массив векторов по указаной оси
  procedure Sort(var Arr: TVectors; Axis: Integer);
  var
    I, J: Integer;
    T: TVector;
  begin
    // примитивная сортировка по возрастанию
    for I := 0 to Length(Arr) - 1 do
      for J := I + 1 to Length(Arr) - 1 do
        if Arr[J][Axis] < Arr[I][Axis] then
        begin
          T := Arr[J];
          Arr[J] := Arr[I];
          Arr[I] := T;
        end;
  end;


  // рекурсивная функция для построения дерева из набора векторов
  function BuildKdTree(Arr: TVectors; Depth: Integer = 0): PNode;
  var
    K, Axis, Median: Integer;
  begin
    Result := nil;
    if Length(Arr) = 0 then
      Exit;

    // если вектор только один, то создаем лист дерева и возращаем его
    if Length(Arr) = 1 then
    begin
      New(Result);
      Result.V := Arr[0];
      Exit;
    end;

    // сдесь нам нужно выбрать плоскость по медиане и разбить на две части
    K := Length(Arr[0]); // получаем размерность вектора
    Axis := Depth mod K; // вычисляем ось, по которой будем разбивать

    Sort(Arr, Axis); // сортируем векторы по выбранной оси
    Median := Length(Arr) div 2; // средний элемент - искомая медиана

    // создаем узел
    New(Result);
    Result.V := Arr[Median];
    // и создаем дочерние узлы, при это разделяя список векторов
    Result.Left := BuildKdTree(Copy(Arr, 0, Median), Depth + 1);
    if Result.Left <> nil then
      Result.Left.Parent := Result;
    Result.Right := BuildKdTree(Copy(Arr, Median + 1, MaxInt), Depth + 1);
    if Result.Right <> nil then
      Result.Right.Parent := Result;
  end;


var
  NodeCounter: Integer = 1;// просто счетчик для генерации id узлов

  // присваиваем id узлам согласно заданию
  procedure Enumerate(Tree: PNode);
  begin
    if Tree = nil then
      Exit;

    if Tree.Left <> nil then
      Enumerate(Tree.Left);

    Tree.Id := NodeCounter;
    NodeCounter := NodeCounter + 1;

    if Tree.Right <> nil then
      Enumerate(Tree.Right);
  end;


  { Процедуры для поиска }


  // вспомогательня процедура для поиска
  // рекурсивный поиск листа по заданному вектору
  function FindParentNode(const Arr: TVector; Tree: PNode): PNode;
  var
    Next: PNode;
    Depth, Axis: Integer;
  begin
    Result := nil;
    Depth := 0;
    Next := Tree;
    while Next <> nil do
    begin
      Result := Next;

      //    Write(Format(' -> %d', [Result.Id]));
      //    Sleep(500);

      Axis := Depth mod Length(Arr);
      if Arr[Axis] > Next.V[Axis] then
        Next := Next.Right
      else
        Next := Next.Left;
      Depth := Depth + 1;
    end;
    //  Writeln;
  end;

  // вычисляем квадрат расстояния между 2мя точками
  function DistanceSquare(const V1, V2: TVector): Integer;
  var
    K: Integer;
  begin
    Result := 0;
    for K := 0 to Length(V1) - 1 do
      Result := Result + (V1[K] - V2[K]) * (V1[K] - V2[K]);
  end;

var
  CheckedNodes: Integer; // количество проверенных узлов
  NearestNeighbour: PNode; // наиболее близкий узел
  DistMin: Integer; // расстояние между найденой точкой и искомой точкой

  // вспомогательная процедура для поиска
  procedure CheckSubtree(Node: PNode; const V: TVector; Depth: Integer = 0);
  var
    Dist, Axis: Integer;
  begin
    if Node = nil then
      Exit;

    // показываем, что проверяем данный узел
    Write(Format(' -> %d', [Node.Id]));
    Sleep(150);

    CheckedNodes := CheckedNodes + 1;

    // если точка в данном узле ближе, чем предыдущие, делаем ее вероятным результатом
    Dist := DistanceSquare(V, Node.V);
    if Dist < DistMin then
    begin
      DistMin := Dist;
      NearestNeighbour := Node;
    end;

    // вычисляем растояние до искомой точки в текущей плоскости
    Axis := Depth mod Length(Node.V);
    Dist := Node.V[Axis] - V[Axis];

    if Dist * Dist > DistMin then
    begin
      // выбираем для поиска ту полуплоскость в которой находится искомая точка
      if Node.V[Axis] > V[Axis] then
        CheckSubtree(Node.Left, V, Depth + 1)
      else
        CheckSubtree(Node.Right, V, Depth + 1);
    end
    else
    begin
      // если расстояние до искомой точки в текущей плоскости меньше чем растояние
      // в пространстве, проверяем все низлежащие подпространства
      CheckSubtree(Node.Left, V, Depth + 1);
      CheckSubtree(Node.Right, V, Depth + 1);
    end;
  end;

  // поиск ближайшего соседнего узла,
  function FindNearest(const V: TVector; Tree: PNode): PNode;
  var
    Parent: PNode;
  begin
    Result := nil;
    if Tree = nil then
      Exit;

    CheckedNodes := 0;// сбрасываем счетчик проверенных узлов

    // ищем наиболее подходящий узел в дереве
    Parent := FindParentNode(V, Tree);
    NearestNeighbour := Parent;

    DistMin := DistanceSquare(V, Parent.V);
    if DistMin = 0 then
    begin
      // если мы сдесь, значит искомая точка есть в дереве
      Result := NearestNeighbour;
      Exit;
    end;

    // ищем заново, по ходу дела, отбрасывая полупространства, далекие от нашей точки
    CheckSubtree(Tree, V);
    Result := NearestNeighbour;

    Writeln;
  end;


  { Вспомогательные процедуры для ввода-вывода }


  // для удобства вывода на консоль
  function VectorToStr(const V: TVector): string;
  var
    I: Integer;
  begin
    Result := '<';
    for I := 0 to Length(V) - 1 do
      if I = 0 then
        Result := Result + IntToStr(V[I])
      else
        Result := Result + ',' + IntToStr(V[I]);
    Result := Result + '>';
  end;

  // для удобства ввода с консоли
  procedure StrToVector(const S: string; var V: TVector);
  var
    I, Idx: Integer;
    Value: string;
  begin
    Idx := 0;
    I := 1;
    while (I <= Length(S)) and (Idx < Length(V)) do
    begin
      if S[I] in ['0'..'9'] then
        Value := Value + S[I]
      else if Value <> '' then
      begin
        V[Idx] := StrToInt(Value);
        Value := '';
        Idx := Idx + 1;
      end;
      I := I + 1;
    end;

    if Value <> '' then
      V[Idx] := StrToInt(Value);
  end;

  // вывод дерева на косоль
  procedure ShowTree(Node: PNode);
  begin
    if Node <> nil then
    begin
      ShowTree(Node.Left);
      Writeln(IntToStr(Node.Id), ':', VectorToStr(Node.V));
      ShowTree(Node.Right);
    end;
  end;




var
  Root, Node: PNode;
  Points: TVectors;
  S: string;
  K: Integer;
  V: TVector;
begin
  // запрашиваем размерность
  Writeln('Please, input k and press ''return''.');
  Readln(S);
  K := StrToInt(S);
  // генерируем случайные вектора и строим дерево
  GenerateVectors(Points, VECTORS_COUNT, K);
  Root := BuildKdTree(Points);
  // нумеруем узлы дерева, начиная с самого левого узла до самого правого
  Enumerate(Root);

  // покажем дерево
  Writeln('Nodes in tree:');
  ShowTree(Root);

  // ожидаем ввода координат вектора для поиска (через запятую или пробел)
  Writeln('Please, input coordinates for search and press ''return''.');
  Readln(S);
  SetLength(V, K);
  repeat
    StrToVector(S, V);

    // начинаем поиск
    Writeln('Searching ', VectorToStr(V), '...');
    Node := FindNearest(V, Root);
    if Node <> nil then
    begin
      // если растояние до найденой точки равно 0,
      // то значит искомая точка присутствует в дереве
      if DistMin = 0 then
      begin
        Writeln(Format('this point found in node with id = %d', [Node.Id]));
      end
      else
      begin
        // иначе говорим, что нашли ближайшую к искомой точку
        Writeln(Format('found nearest point in node %d:', [Node.Id]), VectorToStr(Node.V));
        Writeln(Format('distance = %f', [Sqrt(DistMin)]));
      end;
      Writeln(Format('checked nodes = %d', [CheckedNodes]));
    end;


    Writeln;
    Writeln('Input new vector or nothing to exit.');
    Readln(S);
  until S = '';
end.
