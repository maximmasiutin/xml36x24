{$A-,B-,D-,E-,F-,G+,I-,L-,N-,O-,P-,Q-,R-,S-,T-,V-,X+}
uses XML36x24,Crt;

procedure Pal;external;
{$L PAL}

var i,x,y,z:integer;a,b,c:byte;L:LongInt;Poly:TPolygon;

function rx:word;begin rx:=Random(360) end;
function ry:word;begin ry:=Random(480) end;

procedure DoDemo;
begin
 SetVideoMode; SetAllPalette(@Pal);
 repeat
  ClearPage(0);
  ClearPage(1);
  SetDoubleRetrace;
  for i:=0 to 1000 do
  begin
   CurColor:=Random(256);
   FillEllipse(rx,ry,Random(50)+10,Random(70)+15);
  end;
  if KeyPressed then Exit;
  for i:=0 to 2000 do
  begin
   CurColor:=Random(256);
   FillEllipse(rx,ry,Random(20)+5,Random(25)+5);
  end;
  if KeyPressed then Exit;
  for i:=0 to 5000 do
  begin
   CurColor:=Random(256);
   FillEllipse(rx,ry,Random(10)+2,Random(15)+3);
  end;
  if KeyPressed then Exit;
  L:=0;
  for i:=0 to 500 do
  begin
   for y:=100 to 380 do
   begin
    CurColor:=Byte(L);FullHorLine(y);
    Inc(L);
   end;
   if KeyPressed then Exit;
  end;
  for i:=0 to 200 do
  begin
   Cls;
   for a:=0 to 200 do
   begin
    CurColor:=Random(256);Line(rx,ry,rx,ry);
   end;
   if KeyPressed then Exit;
  end;
  for a:=0 to 30 do
  begin
   Cls;
   for i:=0 to 400 do
   begin
    CurColor:=Random(256);
    x:=rx;y:=ry;
    FillTriAngle(y+Random(100)-50,x+Random(100)-50,
                 y+Random(100)-50,x+Random(100)-50,
                 y+Random(100)-50,x+Random(100)-50);
   end;
   if KeyPressed then Exit;
  end;
  for a:=0 to 50 do
  begin
   Cls;
   for i:=0 to 550 do
   begin
    CurColor:=Random(256);
    Bar4(rx,ry,Random(150)+1,Random(100)+1);
   end;
   if KeyPressed then Exit;
  end;
  for a:=0 to 40 do
  begin
   Cls;
   for i:=0 to 150 do
   begin
    CurColor:=Random(256);
    Ellipse(rx,ry,20,40);
   end;
   if KeyPressed then Exit;
  end;
  for a:=0 to 40 do
  begin
   Cls;
   for i:=0 to 50 do
   begin
    CurColor:=Random(256);
    Poly[0].Y:=ry;Poly[0].X:=rx;
    Poly[1].Y:=ry;Poly[1].X:=rx;
    Poly[2].Y:=ry;Poly[2].X:=rx;
    Poly[3].Y:=ry;Poly[3].X:=rx;
    ColorPoly(Poly,4);
   end;
   if KeyPressed then Exit;
  end;
  ClearPage(0);
  ClearPage(1);
  CurColor:=$D0;Bar(220-5,150-10,64+220+5,200+150+10);
  for a:=0 to 40 do
  begin
   for i:=0 to 20 do
   begin
    for z:=0 to 10 do
    begin
     CurColor:=Random(256);
     FillEllipse(Random(100)+50,Random(300)+100,Random(20),Random(40));
    end;
    GpCopy(64,100,64,200,0,220,150,0);
   end;
  if KeyPressed then Exit;
  end;
 for a:=0 to 50 do
 begin
  WaitRetrace;
  SetVisualOffset(a*90);
  if KeyPressed then Exit;
 end;
 for a:=50 downto 0 do
 begin
  WaitRetrace;
  SetVisualOffset(a*90);
  if KeyPressed then Exit;
 end;
 SetSingleRetrace;
 ClearPage(0);
 ClearPage(1);
 until False;
end;

begin DoDemo;CloseGraph;ReadKey end.