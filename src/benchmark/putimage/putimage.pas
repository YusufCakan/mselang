program putimage;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
{$ifdef mswindows}{$apptype console}{$endif}
uses
 {$ifdef FPC}{$ifdef unix}cthreads,cwstring,{$endif}{$endif}
 sysutils{$ifdef fpc},msetypes{$endif};
type
{$ifndef fpc}
 word = card16;
 pword = ^word;
 tdatetime = flo64;
{$endif}
 pcard16 = ^card16;

const
 runs = 1001; //odd because of XORPut
 screenwidth = 1024;
 screenheight = 768;

       { bitblt operators  }
       NormalPut     = 0;
       CopyPut       = 0;
       XORPut        = 1;
       OrPut         = 2;
       AndPut        = 3;
       NotPut        = 4;

type
 screenty = array[0..screenheight-1,0..screenwidth-1] of card16;
var
  ClipPixels: Boolean;  { Should cliiping be enabled }

  StartXViewPort: smallint; { absolute }
  StartYViewPort: smallint; { absolute }
  ViewWidth : smallint;
  ViewHeight: smallint;
  PTCWidth: Integer;
  PTCHeight: Integer;
  ColorMask: Word;

 screen1,screen2: screenty;
 activescreen: pword;

 bitmap: record
  width: int32;
  height: int32;
  reserved: int32;
  pixels: array[0..screenheight-1,0..screenwidth-1] of card16;
 end;
 
function ptc_surface_lock(): pword;
begin
 result:= activescreen;
end;

Procedure ptc_PutImageproc(X,Y: smallint; var Bitmap; BitBlt: Word; bpp16:boolean);
type
  pt = array[0..{$ifdef cpu16}16382{$else}$fffffff{$endif}] of word;
  ptw = array[0..2] of longint;
var
  pixels:Pword;
  k: longint;
  i, j, y1, x1, deltaX, deltaX1, deltaY: smallint;
  JxW, I_JxW: Longword;
Begin
  inc(x,startXViewPort);
  inc(y,startYViewPort);
  { width/height are 1-based, coordinates are zero based }
  x1 := ptw(Bitmap)[0]+x-1; { get width and adjust end coordinate accordingly }
  y1 := ptw(Bitmap)[1]+y-1; { get height and adjust end coordinate accordingly }
  deltaX := 0;
  deltaX1 := 0;
  k := 3 * sizeOf(Longint) div sizeOf(Word); { Three reserved longs at start of bitmap }
 { check which part of the image is in the viewport }
  if clipPixels then
    begin
      if y < startYViewPort then
        begin
          deltaY := startYViewPort - y;
          inc(k,(x1-x+1)*deltaY);
          y := startYViewPort;
         end;
      if y1 > startYViewPort+viewHeight then
        y1 := startYViewPort+viewHeight;
      if x < startXViewPort then
        begin
          deltaX := startXViewPort-x;
          x := startXViewPort;
        end;
      if x1 > startXViewPort + viewWidth then
        begin
          deltaX1 := x1 - (startXViewPort + viewWidth);
          x1 := startXViewPort + viewWidth;
        end;
    end;
  pixels := ptc_surface_lock;
  If bpp16 Then
    Begin
      case BitBlt of
        XORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] xor pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        ORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] or pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        AndPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] and pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        NotPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k] xor $FFFF;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        Else
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
      End; {case}
    End
  Else
    Begin
      case BitBlt of
        XORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] xor (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        ORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] or (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        AndPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] and (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        NotPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := (pt(bitmap)[k] and ColorMask) xor ColorMask;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        Else
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k] and ColorMask;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
      End; {case}    
    End;
//  ptc_surface_unlock;
//  ptc_update;
end;


Procedure ptc_PutImageprocmse(X,Y: smallint; var Bitmap; BitBlt: Word; bpp16:boolean);
type
  pt = array[0..{$ifdef cpu16}16382{$else}$fffffff{$endif}] of word;
  ptw = array[0..2] of longint;
var
  pixels:Pword;
  k: longint;
  i, j, y1, x1, deltaX, deltaX1, deltaY: smallint;
  JxW, I_JxW: Longword;
  sourcepo,destpo,endpo: pcard16;
Begin
  inc(x,startXViewPort);
  inc(y,startYViewPort);
  { width/height are 1-based, coordinates are zero based }
  x1 := ptw(Bitmap)[0]+x-1; { get width and adjust end coordinate accordingly }
  y1 := ptw(Bitmap)[1]+y-1; { get height and adjust end coordinate accordingly }
  deltaX := 0;
  deltaX1 := 0;
  k := 3 * sizeOf(Longint) div sizeOf(Word); { Three reserved longs at start of bitmap }
 { check which part of the image is in the viewport }
  if clipPixels then
    begin
      if y < startYViewPort then
        begin
          deltaY := startYViewPort - y;
          inc(k,(x1-x+1)*deltaY);
          y := startYViewPort;
         end;
      if y1 > startYViewPort+viewHeight then
        y1 := startYViewPort+viewHeight;
      if x < startXViewPort then
        begin
          deltaX := startXViewPort-x;
          x := startXViewPort;
        end;
      if x1 > startXViewPort + viewWidth then
        begin
          deltaX1 := x1 - (startXViewPort + viewWidth);
          x1 := startXViewPort + viewWidth;
        end;
    end;
  pixels := ptc_surface_lock;
  If bpp16 Then
    Begin
      case BitBlt of
        XORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] xor pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        ORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] or pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        AndPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] and pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        NotPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k] xor $FFFF;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        Else
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k];
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
      End; {case}
    End
  Else
    Begin
      case BitBlt of
        XORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);

                sourcepo:= @pt(bitmap)[k];
                destpo:= @pixels[jxw+x];
                endpo:= destpo+x1-x;
                inc(k,x1-x+1);
                while destpo <= endpo do begin
                 destpo^:= destpo^ xor sourcepo^ and colormask;
                 inc(sourcepo);
                 inc(destpo);
                end;
{
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] xor (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
}
                inc(k,deltaX1);
              End;
          End;
        ORPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] or (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        AndPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    I_JxW:=i+JxW;
                    pixels[I_JxW] := pixels[I_JxW] and (pt(bitmap)[k] and ColorMask);
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        NotPut:
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := (pt(bitmap)[k] and ColorMask) xor ColorMask;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
        Else
          Begin
            for j:=Y to Y1 do
              Begin
                JxW:=j*PTCWidth;
                inc(k,deltaX);
                for i:=X to X1 do
                  begin
                    pixels[i+JxW] := pt(bitmap)[k] and ColorMask;
                    inc(k);
                  end;
                inc(k,deltaX1);
              End;
          End;
      End; {case}    
    End;
//  ptc_surface_unlock;
//  ptc_update;
end;

procedure checkscreen(const screen: screenty);
var
 i1,i2: int32;
begin
 for i1:= 0 to high(screen) do begin
  for i2:= 0 to high(screen[0]) do begin
   if screen[i1,i2] <> bitmap.pixels[i1,i2] then begin
    writeln('**** PIXELERROR ****');
    exit;
   end;
  end;
 end;
end;

var
 c1: card16;
 i1,i2: int32;
 t1,t2: tdatetime;
begin
 ptcwidth:= screenwidth;
 ptcheight:= screenheight;
 viewwidth:= screenwidth;
 viewheight:= screenheight;
 colormask:= $ffff;
// bitmap.width:= length(bitmap.pixels[0]); //mselang bug
// bitmap.height:= length(bitmap.pixels);
 bitmap.width:= screenwidth;
 bitmap.height:= screenheight;
 for i1:= 0 to high(bitmap.pixels) do begin
  for i2:= 0 to high(bitmap.pixels[0]) do begin
   bitmap.pixels[i1,i2]:= i1+i2;
  end;
 end;
 activescreen:= @screen1;
 t1:= now();
 for i1:= 0 to runs - 1 do begin
  ptc_putimageproc(0,0,bitmap,xorput,false);
 end;
 t2:= now();
 writeln(runs,' runs');
 writeln('origin ',((t2-t1)*24*60*60*1000)/runs,' ms per put');
 checkscreen(screen1);
 activescreen:= @screen2;
 t1:= now();
 for i1:= 0 to runs - 1 do begin
  ptc_putimageprocmse(0,0,bitmap,xorput,false);
 end;
 t2:= now();
 writeln('mse ',((t2-t1)*24*60*60*1000)/runs,' ms per put');
 checkscreen(screen2);
 
end.
