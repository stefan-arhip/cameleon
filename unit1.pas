unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazFileUtils, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, Menus, StdCtrls, StrUtils, fpimage, FPReadBMP, FPWriteBMP,
  BgraBitmap, BgraBitMapTypes, LCLType, Themes, Math, BGRAReadBMP, BGRAReadGif,
  BGRAReadIco, bgrareadjpeg, BGRAReadLzp, BGRAReadPCX, BGRAReadPng, BGRAReadPSD,
  BGRAReadTGA, BGRAReadXPM, BGRAPaintNet, BGRALayers, ClipBrd;

Const cSupportedFileType= '.bmp .gif .jpg .lzp .pcx .pdn .png .psd .tif';
      cWinca: Array [0..2] Of Record
                                Name: String;
                                Width, Height, ThumbWidth, ThumbHeight: Integer;
                              End= ((Name: 'Winca S100';
                                     Width: 420;
                                     Height: 257;
                                     ThumbWidth: 110;
                                     ThumbHeight: 110),

                                    (Name: 'Winca S160 small';
                                     Width: 800;
                                     Height: 480;
                                     ThumbWidth: 166;
                                     ThumbHeight: 108),

                                    (Name: 'Winca S160 large';
                                     Width: 1024;
                                     Height: 600;
                                     ThumbWidth: 166;
                                     ThumbHeight: 108));

type

  { TfMain }

  TfMain = class(TForm)
    ImageList1: TImageList;
    Label1: TLabel;
    lvFiles: TListView;
    MainMenu1: TMainMenu;
    miOpen: TMenuItem;
    miAbout: TMenuItem;
    miSettings: TMenuItem;
    miExit: TMenuItem;
    miHelp: TMenuItem;
    miOptions: TMenuItem;
    miFile: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure miAboutClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Procedure ProcessFiles(Const FileNames: Array Of String);
  end;

var
  fMain: TfMain;
  AppDir, TmpDir: String;

implementation

{$R *.lfm}

Uses Unit2, Unit3;

{ TfMain }

{procedure ReduceBitmapColors(BMPFile: String; BPP: Word);
// http://forum.lazarus.freepascal.org/index.php?topic=13468.0
Var SourceBitmap, TargetBitmap :  TFPMemoryImage;
    FPMedianCutQuantizer : TFPMedianCutQuantizer;
    FPPalette : TFPPalette;
    FPFloydSteinbergDitherer : TFPFloydSteinbergDitherer;
    ImageReader : TFPReaderBMP;
    ImageWriter : TFPWriterBMP;
begin
  If FileExists(BMPFile) Then
    Begin
      SourceBitmap := TFPMemoryImage.Create(0, 0);
      TargetBitmap := TFPMemoryImage.Create(0, 0);
      ImageReader := TFPReaderBMP.Create;
      ImageWriter := TFPWriterBMP.create;
      Try
        SourceBitmap.LoadFromFile(BMPFile);
        FPMedianCutQuantizer := TFPMedianCutQuantizer.Create;
        FPMedianCutQuantizer.Add(SourceBitmap);
        FPPalette := FPMedianCutQuantizer.Quantize;
        FPFloydSteinbergDitherer := TFPFloydSteinbergDitherer.Create(FPPalette);
        FPFloydSteinbergDitherer.Dither(SourceBitmap, TargetBitmap);
        ImageWriter.BitsPerPixel := BPP;
        TargetBitmap.SaveToFile(BMPFile, ImageWriter);
      Finally
        SourceBitmap.Free;
        TargetBitmap.Free;
        FPMedianCutQuantizer.Free;
        FPFloydSteinbergDitherer.Free;
        ImageReader.Free;
        ImageWriter.Free;
      End;
    End;
end;}

Function GetByte(BMPFile: String; Pos, Leng: Longint; Complement: Boolean): String;
Var f: File;
    i: Integer;
    aByte: Byte;
Begin
  AssignFile(f, BMPFile);
  Reset(f, 1);
  Seek(f, Pos);
  aByte:= 0;
  Result:= '';
  For i:= 1 To Leng Do
    Begin
      Seek(f, Pos);
      BlockRead(f, aByte, 2);
      If Complement Then
        Begin
          aByte:= 255- aByte;
          If i= 1 Then
            aByte:= aByte+ 1;
        End;
      //Result:= Result+ Format('-%.2d', [aByte]);
      Result:= Result+ Format('%s', [Dec2Numb(aByte, 2, 16)]);
      Inc(Pos, 1);
    End;
  //Delete(Result, 1, 1);
  Closefile(f);
End;

Procedure PutByte(BMPFile, ByteToPut: String; Pos: Longint);
Var f: File;
    i: Integer;
    aByte: Byte;
Begin
  AssignFile(f, BMPFile);
  Reset(f, 1);
  For i:= 1 To Length(ByteToPut) Div 2 Do
    Begin
      Seek(f, Pos);
      aByte:= Hex2Dec(Copy(ByteToPut, (i- 1)* 2+ 1, 2));
      BlockWrite(f, aByte, SizeOf(aByte));
      Inc(Pos, SizeOf(aByte));
    End;
  Closefile(f);
End;

Procedure TfMain.ProcessFiles(Const FileNames: Array Of String);
//Const BGRABlack: TBGRAPixel = (blue: 0; green: 0; red: 0; alpha: 255);
Var aFile, bFile, aResult: String;
    Bmp: TBitmap;
    BmpBGRA, PngBGRA, TmpBGRA: TBGRABitmap;
    wb: TFPWriterBMP;
    NewSize: TPoint;
    Ratio: Extended;
    i: Integer;
    b: Boolean;
    aRect: TRect;
begin
  Label1.Visible:= False;
  lvFiles.Visible:= True;
  For i:= 1 To lvFiles.ColumnCount Do
    lvFiles.Column[i- 1].AutoSize:= True;

  wb:= TFPWriterBMP.Create;
  wb.BitsPerPixel:= 16;
  For aFile In FileNames Do
    With lvFiles.Items.Add Do
      Begin
        Caption:= IntToStr(lvFiles.Items.Count);
        SubItems.Add(aFile);

        If fSettings.rbSameLocation.Checked Then
          bFile:= ExtractFileNameWithoutExt(aFile)+ Format('%s.bmp', [fSettings.edAddText.Text])
        Else If fSettings.rbNewLocation.Checked Then
          bFile:= IncludeTrailingPathDelimiter(fSettings.deNewLocation.Directory)+ LazFileUtils.ExtractFileNameOnly(aFile)+ '.bmp';

        If FileExists(aFile) Then
          If AnsiContainsStr(cSupportedFileType, ExtractFileExt(aFile)) Then
            Begin
              Try
                If LowerCase(ExtractFileExt(aFile))= '.bmp' Then
                  Begin
                    Bmp:= TBitmap.Create;
                    Bmp.LoadFromFile(aFile);
                    BmpBGRA:= TBGRABitmap.Create(Bmp.Width, Bmp.Height);
                    BmpBGRA.Canvas.Draw(0, 0, Bmp);
                    Bmp.Free;
                  End
                Else
                  BmpBGRA:= TBGRABitmap.Create(aFile);

{$Region '   Png zone   '}
                PngBGRA:= TBGRABitmap.Create(cWinca[fSettings.rgResize.ItemIndex- 1].ThumbWidth,
                                             cWinca[fSettings.rgResize.ItemIndex- 1].ThumbHeight);
                //aRect:= BmpBGRA.GetImageBounds(cAlpha, 0);
                aRect:= BmpBGRA.GetImageBounds([cRed, cGreen, cBlue], 0);
                TmpBGRA:= TBGRABitmap.Create(aRect.Right- aRect.Left, aRect.Bottom- aRect.Top);
                TmpBGRA.CanvasBGRA.CopyRect(0, 0, BmpBGRA.GetPart(aRect), TmpBGRA.ClipRect);

                NewSize.x:= TmpBGRA.Width;
                NewSize.y:= TmpBGRA.Height;
                Ratio:= Math.Min(cWinca[fSettings.rgResize.ItemIndex- 1].ThumbWidth/ NewSize.x,
                                 cWinca[fSettings.rgResize.ItemIndex- 1].ThumbHeight/ NewSize.y);
                NewSize.x:= Round(NewSize.x* Ratio)- 8;
                NewSize.y:= Round(NewSize.y* Ratio)- 8;
                TmpBGRA:= TmpBGRA.Resample(NewSize.x, NewSize.y, rmFineResample) As TBGRABitmap;
                PngBGRA.FillRect(0, 0, PngBGRA.Width, PngBGRA.Height, BGRABlack, dmSet);

                //PngBGRA.CanvasBGRA.FloodFill(0, 0, clRed, fsSurface);
                //PngBGRA.Bitmap.Canvas.Brush.Color:= TmpBGRA.Bitmap.Canvas.Pixels[0, 0];
                //PngBGRA.Bitmap.Canvas.FillRect(0, 0, PngBGRA.Width, PngBGRA.Height);
                PngBGRA.PutImage((PngBGRA.Width- TmpBGRA.Width) Div 2, (PngBGRA.Height- TmpBGRA.Height) Div 2, TmpBGRA, dmDrawWithTransparency, 255);
                //
                //PngBGRA.CanvasBGRA.CopyRect(0,0,PngBGRA.GetPart(aRect),PngBGRA.ClipRect);
                //PngBGRA.Resample(NewSize.x, NewSize.y, rmFineResample);
                //ShowMessageFmt('%d, %d'#13'%d, %d', [aRect.Left, aRect.Top, aRect.Right, aRect.Bottom]);
{$EndRegion}

                BmpBGRA.VerticalFlip;
                If fSettings.rgResize.ItemIndex= 0 Then
                  Begin
                    //BmpBGRA:= BmpBGRA.Resample(BmpBGRA.Width, BmpBGRA.Height, rmFineResample) As TBGRABitmap;
                    b:= False;
                    For i:= Low(cWinca) To High(cWinca) Do
                      Begin
                        If (BmpBGRA.Width<= cWinca[i].Width) And (BmpBGRA.Height<= cWinca[i].Height) Then
                          Begin
                            aResult:= Format('%d x %d image converted to %s.', [BmpBGRA.Width, BmpBGRA.Height, cWinca[i].Name]);
                            b:= True;
                            Break;
                          End;
                      End;
                    If Not b Then
                      aResult:= 'Image resolution is too big!';
                    {If (BmpBGRA.Width<= 1024) And (BmpBGRA.Height<= 600) Then
                      Begin
                        If (BmpBGRA.Width<= 800) And (BmpBGRA.Height<= 480) Then
                          If (BmpBGRA.Width<= 420) And (BmpBGRA.Height<= 257) Then
                            aResult:= Format('%d x %d image converted to S100.', [BmpBGRA.Width, BmpBGRA.Height])
                          Else
                            aResult:= Format('%d x %d image converted to S160.', [BmpBGRA.Width, BmpBGRA.Height])
                        Else
                      End
                    Else
                      aResult:= 'Image resolution is too big!';}
                  End
                Else
                  Begin
{$Region '   Bmp zone   '}
                    NewSize.x:= BmpBGRA.Width;
                    NewSize.y:= BmpBGRA.Height;
                    Ratio:= Math.Min(cWinca[fSettings.rgResize.ItemIndex- 1].Width/ NewSize.x,
                                     cWinca[fSettings.rgResize.ItemIndex- 1].Height/ NewSize.y);
                    NewSize.x:= Round(NewSize.x* Ratio);
                    NewSize.y:= Round(NewSize.y* Ratio);

                    If (BmpBGRA.Width> cWinca[fSettings.rgResize.ItemIndex- 1].Width) Or
                       (BmpBGRA.Height> cWinca[fSettings.rgResize.ItemIndex- 1].Height) Then
                      Begin
                        TmpBGRA:= BmpBGRA.Resample(NewSize.x, NewSize.y, rmFineResample) As TBGRABitmap;
                        BmpBGRA.SetSize(cWinca[fSettings.rgResize.ItemIndex- 1].Width,
                                        cWinca[fSettings.rgResize.ItemIndex- 1].Height);
                        BmpBGRA.FillRect(0, 0, BmpBGRA.Width, BmpBGRA.Height, BGRABlack, dmSet);
                        BmpBGRA.PutImage((BmpBGRA.Width- TmpBGRA.Width) Div 2, (BmpBGRA.Height- TmpBGRA.Height) Div 2, TmpBGRA, dmDrawWithTransparency, 255);
                      End
                    Else
                      Begin
                        TmpBGRA:= BmpBGRA.Resample(BmpBGRA.Width, BmpBGRA.Height, rmFineResample) As TBGRABitmap;
                        BmpBGRA.SetSize(cWinca[fSettings.rgResize.ItemIndex- 1].Width,
                                        cWinca[fSettings.rgResize.ItemIndex- 1].Height);
                        BmpBGRA.FillRect(0, 0, BmpBGRA.Width, BmpBGRA.Height, BGRABlack, dmSet);
                        BmpBGRA.PutImage((BmpBGRA.Width- TmpBGRA.Width) Div 2, (BmpBGRA.Height- TmpBGRA.Height) Div 2, TmpBGRA, dmDrawWithTransparency, 255);
                      End;
{$EndRegion}
                    b:= True;
                    aResult:= Format('%d x %d image converted to %s.', [BmpBGRA.Width,
                                                                        BmpBGRA.Height,
                                                                        cWinca[fSettings.rgResize.ItemIndex- 1].Name]);
                  End;

                If b Then
                  Begin
                    BmpBGRA.SaveToFileUTF8(bFile, wb);
                    If fSettings.cbThumbnail.Enabled And fSettings.cbThumbnail.Checked Then
                      PngBGRA.SaveToFileUTF8(ChangeFileExt(bFile, '.png'));

                    //PutByte(bFile, 'FFFEFFFF', 22);
                    PutByte(bFile, GetByte(bFile, 22, 4, True), 22);
                  End;
                BmpBGRA.Free;
                PngBGRA.Free;
                TmpBGRA.Free;
              Except
                If aFile<> bFile Then
                  DeleteFile(bFile);
                aResult:= 'Error while processing!';
              End;
            End
          Else
            aResult:= Format('Not %s file!', [cSupportedFileType])
        Else
          aResult:= 'File not found!';

        SubItems.Add(aResult);
        If AnsiContainsStr(aResult, ' image converted ') Then
          StateIndex:= 0
        Else
          StateIndex:= 1;
      End;
  wb.Free;
end;

procedure TfMain.FormDropFiles(Sender: TObject; Const FileNames: Array Of String);
Begin
  ProcessFiles(FileNames)
end;

procedure TfMain.FormCreate(Sender: TObject);
Var strFilter: String;
begin
  AppDir:= ExcludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
  TmpDir:= ExcludeTrailingPathDelimiter(SysUtils.GetTempDir);
  //.bmp .gif .jpg .lzp .pcx .pdn .png .psd .tif
  //Bitmap files [*.bmp]|*.bmp|All files [*.*]|*.*
  strFilter:= StringsReplace(cSupportedFileType, ['.', ' '], ['*.', ';'], [rfReplaceAll]);
  OpenDialog1.Filter:= Format('Supported files (%s)|%s|All files (*.*)|*.*',
                             [strFilter, strFilter]);
end;

procedure TfMain.FormActivate(Sender: TObject);
begin
  fSettings.SetSettings;
end;

procedure TfMain.miAboutClick(Sender: TObject);
begin
  fAbout.ShowModal;
end;

procedure TfMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.miOpenClick(Sender: TObject);
Var FileNames: Array Of String;
    s: String;
    i: Integer;
begin
  If OpenDialog1.Execute Then
    Begin
      SetLength(FileNames, OpenDialog1.Files.Count);
      i:= 0;
      For s In OpenDialog1.Files Do
        Begin
          FileNames[i]:= s;
          Inc(i);
        End;
      ProcessFiles(FileNames);
    End;
end;

procedure TfMain.miSettingsClick(Sender: TObject);
begin
  fSettings.ShowModal;
end;

Initialization
  BGRAPaintNet.RegisterPaintNetFormat;

end.

