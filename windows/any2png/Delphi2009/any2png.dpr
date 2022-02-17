program any2png;

//
// Program: convert/rotate/crop any image <any2png.exe>
//
// Author: Alexey Oknov <pitrider at mail dot ru>
// 
// Current Version: 1.0.0 (28 Dec 2011)
// 
// License:
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//

{$APPTYPE CONSOLE}

uses
  Windows,
  FreeBitmap,
  FreeUtils,
  FreeImage,
  SysUtils,
  uDxfExport,
  Math;
 

type
  PStrRec = ^StrRec;
  StrRec = packed record
    refCnt: Longint;
    length: Longint;
  end;

  cropRec = Record
             Left:Integer;
             Right:Integer;
             Top:Integer;
             Bottom:Integer;
            End;

const
 rOff = SizeOf(StrRec); { refCnt offset }
 var
    qu:Integer;

function myChangeFileExt(FName:String;ext:String):String;
 var
    i:Word;
    tmp:String;
 Begin
  tmp :='';
  for i:=Length(FName) DownTo 1 Do
   Begin
    if FName[i]='.' then
     Begin
      Result :=copy(FName,1,i)+ext;
      Exit;
     End;
   End;
 End;

function GetFLAG(srs:String;Quality:Integer):Integer;
  var
    ext:String;
 Begin
  ext :='';
  while (pos('.',srs)>0) do
   delete(srs,1,pos('.',srs));

  srs:=UpperCase(srs);
  result :=0;
  if (srs='JPG') or (srs='JPEG') then
   Begin
     case Quality of
      3:Result :=JPEG_QUALITYSUPERB;
      2:Result :=JPEG_QUALITYGOOD;
      1:Result :=JPEG_QUALITYNORMAL;
      0:Result :=JPEG_QUALITYAVERAGE;
     end;
   End;

 End;

Function Set_FileDate(FName:String;Dt:Integer):Integer;
 Begin
  FileSetDate(FName,Dt);
 End;

Function Get_FileDate(FName:String):Integer;
  var
    h:THandle;
 Begin
  try
   h :=FileOpen(FName,fmOpenRead);
   Result :=-1;
  if h>-1 then
   Begin
    Result :=FileGetDate(h);
   End;
  FileClose(h);
  except
   Write(#09,'Error Getting Date');
  End;
 End;

Function GetFIF(ext_:String):FREE_IMAGE_FORMAT;
 Begin
  if UpperCase(ext_)='.BMP' then
   Result :=FIF_BMP;
  if (UpperCase(ext_)='.JPG')or(UpperCase(ext_)='.JPEG') then
   Result :=FIF_JPEG;
  if UpperCase(ext_)='.PNG' then
   Result :=FIF_PNG;
  if (UpperCase(ext_)='.TIF')or(UpperCase(ext_)='.TIFF') then
   Result :=FIF_TIFF;
  if UpperCase(ext_)='.GIF' then
   Result :=FIF_GIF;
  if UpperCase(ext_)='.PSD' then
   Result :=FIF_PSD;
 End;
Procedure CorrectImageDPI(cTypeINT:Integer;var fbmp:TFreeWinBitmap);
 var
   dpiX,dpiY:Double;
 Begin
  dpiX :=FBMp.GetHorizontalResolution;
  dpiY :=FBMp.GetVerticalResolution;
  case cTypeINT of
   $04:FBmp.ConvertTo4Bits;
   $08:FBmp.ConvertTo8Bits;
   $0F:FBmp.ConvertTo16Bits555;
   $18:FBmp.ConvertTo24Bits;
   $32:FBmp.ConvertToRGBF;
  end;
  if dpiX<>FBMp.GetHorizontalResolution then
   FBMp.SetHorizontalResolution(dpiX);
  if dpiY<>FBMp.GetVerticalResolution then
   FBMp.SetVerticalResolution(dpiY);
 End;

function CorrectDPI(src:String;new_dpi:Double):Boolean;
 var
   dpiX,dpiY:Double;
   FBitmap: TFreeWinBitmap;
   Age:Integer;
 Begin
  FBitmap :=TFreeWinBitmap.Create;
  FBitmap.Load(src);
  if FBitmap.IsValid then
   Begin
    Age :=Get_FileDate(src);
    dpiX :=FBitMap.GetHorizontalResolution*2.54;
    dpiY :=FBitMap.GetVerticalResolution*2.54;
    if dpiX<>new_dpi then
      FBitMap.SetHorizontalResolution(new_dpi/2.54);
    if dpiY<>new_dpi then
     FBitMap.SetVerticalResolution(new_dpi/2.54);
    FBitmap.Save(src,GetFLAG(src,qu));
    Set_FileDate(src,Age);
   End;
  FreeAndNil(FBitmap);
 End;

function GetCrop(crop:String):cropRec;
  var
    ar:Array of Integer;
 Begin
  while (Length(crop)>0) and (crop[1]='(') do
   Delete(crop,1,1);
  while (Length(crop)>0) and (crop[Length(crop)]=')') do
   Delete(crop,Length(crop),1);

  SetLength(ar,0);
  while (crop<>'') do
   Begin
    SetLength(ar,HIGH(ar)+2);
    if pos(',',crop)>0 then
     begin
      try
       ar[HIGH(ar)] :=strtoint(copy(crop,1,pos(',',crop)-1));
      except
       if UpperCase(copy(crop,1,pos(',',crop)-1))='AUTO' then
        ar[HIGH(ar)] :=-1;
      end;
      Delete(crop,1,pos(',',crop));
     end
      else
       Begin
        try
         ar[HIGH(ar)] :=strtoint(crop);
        except

        end;
        crop :='';
       End;
   End;
   Result.Left :=ar[0];
   Result.Right :=ar[1];
   Result.Top :=ar[2];
   Result.Bottom :=ar[3];
 End;

function Convert(src,dest,ctype,dpi,crop:String):Boolean;

 var
    FBitmap,tmpF: TFreeWinBitmap;
    cTypeINT,cod, I, J,Age:Integer;
    dpiX,dpiY,scale,new_dpi:Double;
    ext_:String;
    imgInfo:TImgInfo;
    imgF:FREE_IMAGE_FORMAT;
    cr:cropRec;
    pxC:PRGBQUAD;
    pxC2:PRGBQUAD;
 Begin
  FBitmap :=TFreeWinBitmap.Create;
  if FileExists(src) then
   Begin
    Age :=Get_FileDate(src);
    write('LOADING "'+ExtractFileName(src)+'"...');
    FBitmap.Load(src);
    if FBitmap.IsValid then
     Begin
      ext_:=UpperCase(ExtractFileExt(dest));
      if ext_='.DXF' then
       Begin
        imgInfo.imWidthPx :=FBitMap.GetWidth;
        imgInfo.imHeightPx :=FBitMap.GetHeight;
        imgInfo.imWidthMM :=FBitMap.ImageWidthMM;
        imgInfo.imHeightMM :=FBitMap.ImageHeightMM;
        imgInfo.DPI :=FBitMap.DPI_H;
        writeln(#09,'IMPORTING TO "'+ExtractFileName(dest)+'"');
        SaveToDXF(src,dest,false,imgInfo);
       End
        else
         Begin
          dpiX :=FBitMap.GetHorizontalResolution;
          dpiY :=FBitMap.GetVerticalResolution;
          Write('OK');
          Val(ctype,cTypeINT,cod);
          if cod<>0 then Begin
           cTypeINT:=$FF;
           ctype :='is';
          End
           else
            ctype :=ctype +'-bit';
          write(#09,'CONVERTING: ');
         try
          new_dpi :=StrToFloat(dpi)/2.54;
         except
          new_dpi :=dpix;
         end;
         if crop<>'' then
          Begin
           cr :=GetCrop(crop);
           new(pxC);
           new(pxC2);
           writeln;
           write('Getting Left:', cr.left,#09);
           if cr.Left=-1 then
            Begin
             for I := 0 to FBitmap.GetWidth-1 do
              Begin
               if cr.Left>-1 then Break;
               for J := 1 to FBitmap.GetHeight-1 do
                Begin
                 FBitmap.GetPixelColor(I,J,pxC);
                 if (pxC^.rgbBlue OR pxC^.rgbGreen OR pxC^.rgbRed)<>$FF then
                  Begin
                   cr.Left :=I;
                   break;
                  End;
                End;
              End;
             if cr.Left=-1 then cr.Left :=0;
            End;
           writeln(cr.Left);
           write('Getting Top:');
           if cr.Top=-1 then
            Begin
             for I := 0 to FBitmap.GetHeight-1 do
              Begin
               if cr.Top>-1 then Break;
               for J := 0 to FBitmap.GetWidth-1 do
                Begin
                 FBitmap.GetPixelColor(I,J,pxC);
                 if (pxC^.rgbBlue OR pxC^.rgbGreen OR pxC^.rgbRed)<>$FF then
                  Begin
                   cr.Top :=I;
                   break;
                  End;
                End;
              End;
             if cr.Top=-1 then cr.Top :=0;
            End;
           writeln(cr.Top);
           write('Getting Right:');
           if cr.Right=-1 then
            Begin
             for I := 0 to FBitmap.GetWidth-1 do
              Begin
               if cr.Right>-1 then Break;
               for J := 0 to FBitmap.GetHeight-1 do
                Begin
                 FBitmap.GetPixelColor(fBitmap.GetWidth-I,fBitmap.GetHeight-J,pxC);
                 if (pxC^.rgbBlue OR pxC^.rgbGreen OR pxC^.rgbRed)<>$FF then
                  Begin
                   cr.Right :=I;
                   break;
                  End;
                End;
              End;
             if cr.Right=-1 then cr.Right :=0;
            End;
           writeln(cr.Right);
           write('Getting Bottom:');
           if cr.Bottom=-1 then
            Begin
             for I := 0 to FBitmap.GetHeight-1 do
              Begin
               if cr.Top>-1 then Break;
               for J := 0 to FBitmap.GetWidth-1 do
                Begin
                 FBitmap.GetPixelColor(fBitmap.GetHeight-I,fBitmap.GetWidth-J,pxC);
                 if (pxC^.rgbBlue AND pxC^.rgbGreen AND pxC^.rgbRed)<>$FF then
                  Begin
                   cr.Bottom :=I;
                   break;
                  End;
                End;
              End;
             if cr.Bottom=-1 then cr.Bottom :=0;
            End;
           writeln(cr.Bottom);
           dispose(pxC);

           try
            tmpF :=TFreeWinBitmap.Create;
           except
            writeln('Error creating');
           end;
           try
            tmpF.Assign(FBitmap);
           except
            writeln('Error Assining');
           end;
           FBitmap.Clear;

           if dpiX<>tmpF.GetHorizontalResolution then
            tmpF.SetHorizontalResolution(dpiX);
           if dpiY<>tmpF.GetVerticalResolution then
            tmpF.SetVerticalResolution(dpiY);

           writeln('[',0,',',0,',',tmpF.GetWidth,',',tmpF.GetHeight,'] Croping to [',cr.Left,',',cr.Top,',',tmpF.GetWidth-cr.Right,',',tmpF.GetHeight-cr.Bottom,']');
           tmpF.CopySubImage(cr.Left,cr.Top,(tmpF.GetWidth-cr.Right),(tmpF.GetHeight-cr.Bottom),FBitmap);
           tmpF.Clear;
           FreeAndNIL(tmpF);
           if dpiX<>FBitmap.GetHorizontalResolution then
            FBitmap.SetHorizontalResolution(dpiX);
           if dpiY<>FBitmap.GetVerticalResolution then
            FBitmap.SetVerticalResolution(dpiY);
          End;

         CorrectImageDPI(cTypeInt,FBitMap);
         if dpi<>'' then
          Begin
           write(#09,'RESIZING TO "'+dpi+'" dpi');
           scale :=FBitmap.DPI_H/(new_dpi*2.54);
           FBitmap.Rescale(ceil(FBitmap.GetWidth/scale),ceil(FBitmap.GetHeight/scale),FILTER_LANCZOS3);
           FBitmap.SetHorizontalResolution(new_dpi);
           FBitmap.SetVerticalResolution(new_dpi);
          End;
         if ((Ext_='.JPG')or(Ext_='.JPEG')) and (FBitmap.GetBitsPerPixel<8) then
           Begin
            Ext_ :='.PNG';
            Dest :=myChangeFileExt(dest,'png');
           End;

         if ((Ext_='.PNG') and (FBitmap.GetBitsPerPixel>=8)) then
           Begin
            Ext_ :='.JPG';
            Dest :=myChangeFileExt(dest,'JPG');
           End;

          imgF :=GetFIF(Ext_);
          if (FBitmap.GetBitsPerPixel>=16)and(not FBitmap.CanSave(imgF)) then
           Begin

           End;

          FBitmap.Save(dest,GetFLAG(dest,qu));
          Set_FileDate(dest,Age);
          write(#09,'SAVING TO "'+dest+'"',#09,FBitmap.GetBitsPerPixel,#09,FBitmap.GetImageType);
          if not FBitmap.CanSave(imgF) then
           Write(#09,'write error');
          WriteLn;
          Result :=FBitmap.CanSave(imgF);
         End;
        End
         Else
          Writeln('FALSE');
   End;
  FreeAndNil(FBitmap);
 End;

 function RotateImg(FName:String;Angle:Double):Boolean;
  var
     FBitmap: TFreeWinBitmap;
     dpiX,dpiY:Double;
     Age:Integer;
  Begin
   Age:=Get_FileDate(FName);
   FBitmap :=TFreeWinBitmap.Create;
   Write('FileLoading...');
   FBitmap.Load(FName);
   Result :=False;
   if FBitmap.IsValid then
    Begin
     Write('OK');
     dpiX :=FBitMap.GetHorizontalResolution;
     dpiY :=FBitMap.GetVerticalResolution;
     Result :=FBitmap.Rotate(-Angle);

     if dpiX<>FBitMap.GetHorizontalResolution then
      FBitMap.SetHorizontalResolution(dpiX);
     if dpiY<>FBitMap.GetVerticalResolution then
      FBitMap.SetVerticalResolution(dpiY);
     FBitmap.Save(FName,GetFLAG(FName,qu));
     Set_FileDate(FName,Age);
    End
     else
       Write('FALSE');
   FreeAndNil(FBitmap);
  End;

 procedure ScanDir(dr,mask,ext2,ctype,dpi,crop,rot:String);
  const regExt:array [0..6] of String =('BMP','JPG','JPEG','PNG','TIFF','TIF','DXF');

  var
   sr: TSearchRec;
   FileAttrs,I: Integer;
   ext_:String;
  Begin
   WriteLn('Scanning dir...',dr);
   FileAttrs :=0;
   FileAttrs :=FileAttrs+faAnyFile;
   if Not DirectoryExists(dr) then Begin  Writeln('not directory...'); EXIT; End;
   if (dr[length(dr)]<>'\') or (dr[length(dr)]<>'/') then dr :=dr+'\';
   if FindFirst(dr+mask,FileAttrs,sr)=0 then
    begin
     repeat
      ext_ :=UpperCase(ExtractFileExt(sr.Name));
//       if (sr.Attr and FileAttrs) = sr.Attr then
     ext_ :=ext2;
     for I := 0 to HIGH(regExt) do
      if UpperCase(Ext2)=regEXT[I] then
       begin
        ext_ :=LowerCase(ext_);
        break
       end;

       if ext2<>ext_ then
         begin
          WriteLN('"'+ext2+'" - ����������� �������� ������ �����...');
          continue;
         end;

      if rot<>'' then
       RotateImg(dr+sr.Name,strtofloat(rot))
        else
         Convert(dr+sr.Name,dr+myChangeFileExt(sr.Name,ext_),ctype,dpi,crop);
     until FindNext(sr) <> 0;
     FindClose(sr);
    end;
  End;

 Function GetParam(prm:String):String;
  var
     I:SmallInt;
  Begin
   Result :='';
   I :=2;
   while I<ParamCount do
    begin
     if UpperCase(ParamStr(I))=UpperCase(prm) then
      Begin
       Result :=ParamStr(I+1);
       Break
      End;
     inc(I,2)
    end;
  End;

//=================================================================
 var
    mask,ext,cType,src,dpi,rot,c_dpi, crop,q:String;
    p:AnsiString;

begin
 if ParamCount>0 then
  Begin
   src :=ParamStr(1);
   cType :=GetParam('-COLOR_TYPE');
   mask :=GetParam('-MASK');
   ext :=GetParam('-RES_EXT');
   dpi :=GetParam('-SET_DPI');
   rot :=GetParam('-ROTATE');
   c_dpi :=GetParam('-CORRECT_DPI');
   crop :=GetParam('-CROP');
   q :=GetParam('-QUALITY');

   qu :=-1;
   if q<>'' then
    qu :=strtoint(q);

   if c_dpi<>'' then
    Begin
     try
      CorrectDPI(src,strtofloat(c_dpi));
     except
      CorrectDPI(src,300);
     end;
     exit;
    End;

   if mask='' then mask:='*.tif*';
   if ext='' then ext :='png';

   if fileExists(SRC) then
    Begin
       if rot<>'' then
        Begin
         try
          RotateImg(src,strtofloat(rot));
         except
         end;
         Exit;
        End;
      if not Convert(SRC,myChangeFileExt(SRC,EXT),ctype,dpi,crop) then  Halt(4);
    End
     else
       ScanDir(SRC,mask,ext,ctype,dpi,crop,rot);
  End
   else
    Begin
     WriteLn('To convert "file_name" to 4-bit png type next: any2png file_name -res_ext PNG -color_type 4');
     WriteLn('To convert all tif-files in "dir_name" to 4-bit bmp type next: any2png dir_name -mask *.tif -res_ext BMP -color_type 4');
     WriteLn('To SET new DPI use -SET_DPI [value]...default value is 300 dpi');
     WriteLn('To CORRECT DPI use -CORRECT_DPI [value]...default value is 300 dpi');
     WriteLn('To CROP Size use -CROP (Left,Right,Top,Bottom) in pixels');
     WriteLn('To ROTATE image use -ROTATE [value]');
     WriteLn('Default -RES_EXT is PNG');
     WriteLn('Default -MASK is *.tif*');
     WriteLn('Default -COLOR_TYPE is original color');

     Write('Press [Enter] to continue...');
     ReadLN;
    End;
end.
