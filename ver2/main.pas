unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,
  uKDTree;

type
  TMainForm = class(TForm)
    PaintBox1: TPaintBox;
    procedure PaintBox1Paint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1MouseMove(Sender: TObject;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseEnter(Sender: TObject);
    procedure PaintBox1MouseLeave(Sender: TObject);
  private
    FRect: TRect;
    FWidth: integer;
    FHeight: integer;
    FCanvas: TCanvas;
    Root: PNode;
    arr: TCoordVec;
    KDTree: TKDTree;
    np: PNode;
    cp, pt: TCoord;
    pt2: TCoord;
    nNearest: integer;
    kN, nN: TCoordVec;
    oldCursor: TCursor;
    procedure DrawNode(np: PNode);
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Math,
  txColorDef, txColorConv;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanvas := PaintBox1.Canvas;
  KDTree := TKDTree.Create;
  FWidth := PaintBox1.Width;
  FHeight := PaintBox1.Height;
  arr := RandomVectors(40, 2, FWidth);
  Root := KDTree.BuildTree(arr, 2);
  cp := InitCoord([0, 0]);
  pt := InitCoord([0, 0]);
  SetLength(kN, 0);
  nNearest := 3;
end;

procedure TMainForm.PaintBox1MouseEnter(Sender: TObject);
begin
  // mouse enters paintbox
  oldCursor := Cursor;
  Cursor := crNone;
end;

procedure TMainForm.PaintBox1MouseLeave(Sender: TObject);
begin
  // mouse leaves paintbox
  Cursor := oldCursor;
end;

procedure TMainForm.PaintBox1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  cp := InitCoord([X, Y]);
  KDTree.FindKNearest(cp, Root, nNearest, kN);
  KDTree.NaiveSearch(cp, Root, nNearest, nN);
  PaintBox1.Refresh;
end;

procedure TMainForm.DrawNode(np: PNode);
const
  r = 5;
var
  x, y: integer;
begin
  FCanvas.Pen.Width := 0;
  FCanvas.Brush.Color := clRed;
  x := np.Coord[0];
  y := np.Coord[1];
  FCanvas.Ellipse(x-r, y-r, x+r, y+r);
end;

procedure TMainForm.PaintBox1Paint(Sender: TObject);
const
  r = 5;
var
  x, y: integer;
  i: integer;
begin
  // Clear background
  FCanvas.Brush.Color := clWhite;
  FRect := FCanvas.ClipRect;
  FCanvas.FillRect(FRect);

  // Draw all points from KDTree
  KDTree.Map(DrawNode, Root);

  if (cp[0] = 0) and (cp[1] = 0) then Exit;

  // Draw Crosshairs at cp
  FCanvas.Pen.Width := 1;
  FCanvas.Pen.Style := psSolid;
  FCanvas.Pen.Color := clBlack;
  x := cp[0];
  y := cp[1];
  FCanvas.MoveTo(x, y-10);
  FCanvas.LineTo(x, y+10);
  FCanvas.MoveTo(x-10, y);
  FCanvas.LineTo(x+10, y);

  // Draw line from Mouse to nearest
  FCanvas.Pen.Width := 1;
  FCanvas.Pen.Style := psSolid;
  FCanvas.Pen.Color := clBlack;
  for i := 0 to length(kN) - 1 do begin
    pt := kN[i];
    FCanvas.Pen.Color := clRed;
    FCanvas.MoveTo(cp[0], cp[1]);
    FCanvas.LineTo(pt[0], pt[1]);
    pt2 := nN[i];
    if pt2 <> pt then begin
      FCanvas.Pen.Color := clBlue;
      FCanvas.MoveTo(cp[0], cp[1]);
      FCanvas.LineTo(pt2[0], pt2[1]);
    end;
  end;

  // highlight nearest node
  FCanvas.Pen.Width := 0;
  FCanvas.Pen.Color := clBlue;
  FCanvas.Brush.Color := clBlue;
  pt := kN[0];
  x := pt[0];
  y := pt[1];
  FCanvas.Ellipse(x-r, y-r, x+r, y+r);
end;

end.
