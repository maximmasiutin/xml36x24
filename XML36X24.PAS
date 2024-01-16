{ VGA X-Mode 360x240(480)x256-Color Library           }
{ Copyright (C) 1995 by FRIENDS Software              }
{ Author: Maxim Masiutin                              }
{ To contact the author, mail to 2:469/84@fidonet.org }

{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X-}
unit XML36x24;

interface

type
   TPoint      = record Y,X : integer end;
   TArrOfPoint = array[0..16382] of TPoint;
   PArrOfPoint = ^TArrOfPoint;
   TPolygon    = array[0..31] of record x,y : integer end;

var
	  ImageOffset		  : word;
	  CurColor		  : byte;
	  BackgroundColor	  : byte;
	  CurX			  : Integer;
	  CurY			  : Integer;

	  CurPalette		  : pointer;
	  LineMode		  : byte;

	  ScrY2 		  : Word;
	  ScrY			  : Word;
	  PageSize		  : Word;
	  LinePoints		  : PArrOfPoint;
	  LinePointsPos 	  : word;

procedure SetVideoMode;

procedure PutBitMap(x,y,h,v:word;p:pointer);	  { align X by 4 and h by 8 }
procedure GetBitMap(x,y,h,v:word;p:pointer);	  { align X by 4 and h by 8 }

procedure PutTranspBitMap(x,y,h,v:word;p:pointer);{ align X by 4 and h by 8 }

procedure Cls;
procedure ClearPage(Page:byte);
procedure PageCopy(Page1,Page2:byte);
procedure GPcopy(x,y,w,h:Integer;Page1:Byte;dx,dy:Integer;Page2:Byte);
procedure SetActivePage(Page:byte);
procedure SetVisualPage(Page:byte);
procedure SetVisualOffset(Ofs:Word);
procedure WaitRetrace;
procedure SetAllPalette(Pal:pointer);
procedure Line(x1,y1,x2,y2 : Integer);
procedure HorizLine(x1,x2,y : Integer);
procedure FullHorLine(y:Integer);
procedure GridHorLine(y:Integer;C1,C2,C3,C4:byte);
procedure VertLine(x,y1,y2 : Integer);
procedure Clipping(x1,y1,x2,y2 : Integer);
procedure PutPixel(x,y : Integer);
procedure PutTPoint(P : TPoint);
function  GetPixel(x,y : Integer) : Byte;
procedure Rectangle(x1,y1,x2,y2 : Integer);
procedure Bar(x1,y1,x2,y2 : Integer);
procedure Bar4(x,y,w,h : Integer);
procedure SetCurPos(X,Y:Integer); Inline($8F/$06/CurY/$8F/$06/CurX);
procedure MoveRel(dx,dy : integer);
procedure LineTo(X,Y : Integer);
procedure LineRel(DX,DY : Integer);
procedure Ellipse(x,y,RadX,RadY : Word);
procedure FillEllipse(x,y,RadX,RadY : Word);
procedure ColorPoly(var Bounds; Num : Integer);
procedure TriAngle(x1,y1,x2,y2,x3,y3 : Word);
procedure FillTriAngle(y1,x1,y2,x2,y3,x3 : Word);
procedure CloseGraph;inline($B8/$03/$00/$CD/$10);
procedure AssignLinePoints(p:pointer);inline($C6/$06/LineMode/$01/
					     $BB/LinePoints/
					     $58/$89/$07/$58/$89/$47/$02/
					     $C7/$06/LinePointsPos/$00/$00);
procedure SetDoubleRetrace;
procedure SetSingleRetrace;

implementation

procedure SetVideoMode; 					     external;
procedure SetDoubleRetrace;					     external;
procedure SetSingleRetrace;					     external;

procedure PutBitMap;						     external;
procedure GetBitMap;						     external;
procedure PutTranspBitMap;					     external;

procedure Line; 						     external;
procedure HorizLine;						     external;
procedure FullHorLine;						     external;
procedure GridHorLine;						     external;
procedure VertLine;						     external;
procedure Clipping;						     external;
procedure PutPixel;						     external;
procedure PutTPoint;						     external;
function  GetPixel;						     external;
procedure Bar;							     external;
procedure Bar4; 						     external;
procedure InternalEllipse(x,y,RadX,RadY : Word; What : Byte);	near;external;
procedure ColorPoly;						     external;
procedure Cls;							     external;
procedure ClearPage;						     external;
procedure PageCopy;						     external;
procedure GPCopy;						     external;
procedure SetActivePage;					     external;
procedure SetVisualPage;					     external;
procedure SetVisualOffset;					     external;
procedure WaitRetrace;						     external;
procedure SetAllPalette;					     external;

{$L XML36x24}

procedure Rectangle;
begin
 HorizLine(x1, x2, y1); HorizLine(x1, x2, y2);
 VertLine(x1, y1, y2);	VertLine(x2, y1, y2);
end;

procedure LineTo;
begin Line(CurX, CurY, X, Y); CurX:=X; CurY:=Y end;

procedure MoveRel(dx,dy : integer);
begin Inc(CurX,Dx);Inc(CurY,Dy) end;

procedure LineRel;
begin Line(CurX, CurY, CurX+DX, CurY+DY); Inc(CurX, DX); Inc(CurY, DY) end;

procedure Ellipse;
begin InternalEllipse(x,y,RadX,RadY,0); end;

procedure FillEllipse;
begin InternalEllipse(x,y,RadX,RadY,1); end;

procedure FillTriAngle;
begin ColorPoly(x3,3) end;

procedure TriAngle;
begin
 SetCurPos(x1,y1); LineTo(x2,y2); LineTo(x3,y3); LineTo(x1,y1) end;

end.