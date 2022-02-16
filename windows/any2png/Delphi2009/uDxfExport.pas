unit uDxfExport;

//
// Unit: insert any image into DXF with real scale
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

interface
 Uses Classes, SysUtils;

 type
     TimgInfo=record
               imWidthPx,imHeightPx:LongWord;
               imWidthMM,imHeightMM:Double;
               DPI:Double;
              end;

 function ExportToDXF(PicFileName,dxfFileName:String;needFullPath:Boolean):Boolean;
 function SaveToDXF(PicFileName,dxfFileName:String;needFullPath:Boolean;imInfo:TImgInfo):Boolean;

implementation

 Uses FreeBitmap,FreeUtils, FreeImage;
 function SetDelimiter(src:String;olddelim,newdelim:Char):String;
  Begin
   if pos(olddelim,src)>0 then
     src[pos(olddelim,src)] :=newdelim;
   Result :=src;
  End;

 function SaveToDXF(PicFileName,dxfFileName:String;needFullPath:Boolean;imInfo:TImgInfo):Boolean;
   var
      dxf:TStringList;
      I:Integer;
      fn:String;
  Begin
   dxf :=TStringList.Create;
   fn :=Format('%s\dxf2000.dxf',[ExtractFilePath(ParamStr(0))]);
   if FileExists(fn) then
    dxf.LoadFromFile(fn);
   if dxf.Count=0 then
    Begin
     Result :=False;
     Exit;
    End;

   dxf.Strings[35] :=SetDelimiter(Format('%.1f',[imInfo.imWidthMM]),',','.');
   dxf.Strings[37] :=SetDelimiter(Format('%.1f',[imInfo.imHeightMM]),',','.');
   dxf.Strings[49] :=SetDelimiter(Format('%.1f',[imInfo.imWidthMM]),',','.');
   dxf.Strings[51] :=SetDelimiter(Format('%.1f',[imInfo.imHeightMM]),',','.');
   dxf.Strings[1841] :=SetDelimiter(Format('%.16f',[25.4/imInfo.DPI]),',','.');
   dxf.Strings[1849] :=SetDelimiter(Format('%.16f',[25.4/imInfo.DPI]),',','.');
   dxf.Strings[2457] :=SetDelimiter(Format('%.1f',[imInfo.imWidthMM]),',','.');
   dxf.Strings[2459] :=SetDelimiter(Format('%.1f',[imInfo.imHeightMM]),',','.');
   dxf.Strings[2699] :=SetDelimiter(Format('%.1f',[imInfo.imWidthMM]),',','.');
   dxf.Strings[2701] :=SetDelimiter(Format('%.1f',[imInfo.imHeightMM]),',','.');

   dxf.Strings[2115] :='Img_Import';
   if not needFullPath then
    Begin
     while POS('/',PicFileName)>0 do PicFileName[POS('/',PicFileName)] :='\';
     PicFileName :=ExtractFileName(PicFileName);
    End;

   dxf.Strings[2349] :=PicFileName;

   dxf.Strings[1853] :=SetDelimiter(Format('%.1f',[imInfo.imWidthPx/1]),',','.');
   dxf.Strings[1855] :=SetDelimiter(Format('%.1f',[imInfo.imHeightPx/1]),',','.');
   dxf.Strings[2351] :=SetDelimiter(Format('%.1f',[imInfo.imWidthPx/1]),',','.');
   dxf.Strings[2353] :=SetDelimiter(Format('%.1f',[imInfo.imHeightPx/1]),',','.');

   dxf.Strings[1879] :=SetDelimiter(Format('%.1f',[imInfo.imWidthPx/1-0.5]),',','.');
   dxf.Strings[1881] :=SetDelimiter(Format('%.1f',[imInfo.imHeightPx/1-0.5]),',','.');
   dxf.SaveToFile(ChangeFileExt(dxfFileName,'.dxf'));
   Result :=True;
   dxf.Free;
  End;

 function ExportToDXF(PicFileName,dxfFileName:String;needFullPath:Boolean):Boolean;
  var
     frImage:TFreeWinBitmap;
     imInfo:TimgInfo;
  Begin
   frImage :=TFreeWinBitmap.Create;
   frImage.Load(PicFileName);
   Result :=frImage.IsValid;

   imInfo.imWidthPx :=frImage.GetWidth;
   imInfo.imHeightPx :=frImage.GetHeight;
   imInfo.imWidthMM :=frImage.ImageWidthMM;
   imInfo.imHeightMM :=frImage.ImageHeightMM;
   imInfo.DPI :=frImage.DPI_H;

   frImage.Clear;
   frImage.Free;

   if not Result then EXIT;
   Result :=SaveToDXF(PicFileName,dxfFileName,needFullPath,imInfo);


  End;
end.
