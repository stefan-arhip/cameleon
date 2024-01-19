unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazFileUtils, Forms, Controls, Graphics, Dialogs,
  ComCtrls, ExtCtrls, Menus, StdCtrls, StrUtils, fpimage, FPReadBMP, FPWriteBMP,
  BgraBitmap, BgraBitMapTypes, LCLType, Themes, Math, BGRAReadBMP, BGRAReadGif,
  BGRAReadIco, bgrareadjpeg, BGRAReadLzp, BGRAReadPCX, BGRAReadPng, BGRAReadPSD,
  BGRAReadTGA, BGRAReadXPM, BGRAPaintNet, BGRALayers, ClipBrd;

const
  cSupportedFileType = '.bmp .gif .jpg .lzp .pcx .pdn .png .psd .tif';
  cWinca: array [0..2] of record
      Name: string;
      Width, Height, ThumbWidth, ThumbHeight: integer;
      end
  = ((Name: 'Winca S100';
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
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure miAboutClick(Sender: TObject);
    procedure miExitClick(Sender: TObject);
    procedure miOpenClick(Sender: TObject);
    procedure miSettingsClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure ProcessFiles(const FileNames: array of string);
  end;

var
  fMain: TfMain;
  AppDir, TmpDir: string;

implementation

{$R *.lfm}

uses Unit2, Unit3;

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

function GetByte(BMPFile: string; Pos, Leng: longint; Complement: boolean): string;
var
  f: file;
  i: integer;
  aByte: byte;
begin
  AssignFile(f, BMPFile);
  Reset(f, 1);
  Seek(f, Pos);
  aByte := 0;
  Result := '';
  for i := 1 to Leng do
  begin
    Seek(f, Pos);
    BlockRead(f, aByte, 2);
    if Complement then
    begin
      aByte := 255 - aByte;
      if i = 1 then
        aByte := aByte + 1;
    end;
    //Result:= Result+ Format('-%.2d', [aByte]);
    Result := Result + Format('%s', [Dec2Numb(aByte, 2, 16)]);
    Inc(Pos, 1);
  end;
  //Delete(Result, 1, 1);
  Closefile(f);
end;

procedure PutByte(BMPFile, ByteToPut: string; Pos: longint);
var
  f: file;
  i: integer;
  aByte: byte;
begin
  AssignFile(f, BMPFile);
  Reset(f, 1);
  for i := 1 to Length(ByteToPut) div 2 do
  begin
    Seek(f, Pos);
    aByte := Hex2Dec(Copy(ByteToPut, (i - 1) * 2 + 1, 2));
    BlockWrite(f, aByte, SizeOf(aByte));
    Inc(Pos, SizeOf(aByte));
  end;
  Closefile(f);
end;

procedure TfMain.ProcessFiles(const FileNames: array of string);
//Const BGRABlack: TBGRAPixel = (blue: 0; green: 0; red: 0; alpha: 255);
var
  aFile, bFile, aResult: string;
  Bmp: TBitmap;
  BmpBGRA, PngBGRA, TmpBGRA: TBGRABitmap;
  wb: TFPWriterBMP;
  NewSize: TPoint;
  Ratio: extended;
  i: integer;
  b: boolean;
  aRect: TRect;
begin
  Label1.Visible := False;
  lvFiles.Visible := True;
  for i := 1 to lvFiles.ColumnCount do
    lvFiles.Column[i - 1].AutoSize := True;

  wb := TFPWriterBMP.Create;
  wb.BitsPerPixel := 16;
  for aFile in FileNames do
    with lvFiles.Items.Add do
    begin
      Caption := IntToStr(lvFiles.Items.Count);
      SubItems.Add(aFile);

      if fSettings.rbSameLocation.Checked then
        bFile := ExtractFileNameWithoutExt(aFile) +
          Format('%s.bmp', [fSettings.edAddText.Text])
      else if fSettings.rbNewLocation.Checked then
        bFile := IncludeTrailingPathDelimiter(fSettings.deNewLocation.Directory) +
          LazFileUtils.ExtractFileNameOnly(aFile) + '.bmp';

      if FileExists(aFile) then
        if AnsiContainsStr(cSupportedFileType, ExtractFileExt(aFile)) then
        begin
          try
            if LowerCase(ExtractFileExt(aFile)) = '.bmp' then
            begin
              Bmp := TBitmap.Create;
              Bmp.LoadFromFile(aFile);
              BmpBGRA := TBGRABitmap.Create(Bmp.Width, Bmp.Height);
              BmpBGRA.Canvas.Draw(0, 0, Bmp);
              Bmp.Free;
            end
            else
              BmpBGRA := TBGRABitmap.Create(aFile);

            {$Region '   Png zone   '}
            PngBGRA := TBGRABitmap.Create(
              cWinca[fSettings.rgResize.ItemIndex - 1].ThumbWidth,
              cWinca[fSettings.rgResize.ItemIndex - 1].ThumbHeight);
            //aRect:= BmpBGRA.GetImageBounds(cAlpha, 0);
            aRect := BmpBGRA.GetImageBounds([cRed, cGreen, cBlue], 0);
            TmpBGRA := TBGRABitmap.Create(aRect.Right - aRect.Left,
              aRect.Bottom - aRect.Top);
            TmpBGRA.CanvasBGRA.CopyRect(0, 0, BmpBGRA.GetPart(aRect),
              TmpBGRA.ClipRect);

            NewSize.x := TmpBGRA.Width;
            NewSize.y := TmpBGRA.Height;
            Ratio := Math.Min(cWinca[fSettings.rgResize.ItemIndex - 1].ThumbWidth /
              NewSize.x, cWinca[fSettings.rgResize.ItemIndex -
              1].ThumbHeight / NewSize.y);
            NewSize.x := Round(NewSize.x * Ratio) - 8;
            NewSize.y := Round(NewSize.y * Ratio) - 8;
            TmpBGRA := TmpBGRA.Resample(NewSize.x, NewSize.y, rmFineResample) as
              TBGRABitmap;
            PngBGRA.FillRect(0, 0, PngBGRA.Width, PngBGRA.Height, BGRABlack, dmSet);

            //PngBGRA.CanvasBGRA.FloodFill(0, 0, clRed, fsSurface);
            //PngBGRA.Bitmap.Canvas.Brush.Color:= TmpBGRA.Bitmap.Canvas.Pixels[0, 0];
            //PngBGRA.Bitmap.Canvas.FillRect(0, 0, PngBGRA.Width, PngBGRA.Height);
            PngBGRA.PutImage((PngBGRA.Width - TmpBGRA.Width) div
              2, (PngBGRA.Height - TmpBGRA.Height) div 2, TmpBGRA,
              dmDrawWithTransparency, 255);

            //PngBGRA.CanvasBGRA.CopyRect(0,0,PngBGRA.GetPart(aRect),PngBGRA.ClipRect);
            //PngBGRA.Resample(NewSize.x, NewSize.y, rmFineResample);
            //ShowMessageFmt('%d, %d'#13'%d, %d', [aRect.Left, aRect.Top, aRect.Right, aRect.Bottom]);
            {$EndRegion}

            BmpBGRA.VerticalFlip;
            if fSettings.rgResize.ItemIndex = 0 then
            begin
              //BmpBGRA:= BmpBGRA.Resample(BmpBGRA.Width, BmpBGRA.Height, rmFineResample) As TBGRABitmap;
              b := False;
              for i := Low(cWinca) to High(cWinca) do
              begin
                if (BmpBGRA.Width <= cWinca[i].Width) and
                  (BmpBGRA.Height <= cWinca[i].Height) then
                begin
                  aResult :=
                    Format('%d x %d image converted to %s.',
                    [BmpBGRA.Width, BmpBGRA.Height, cWinca[i].Name]);
                  b := True;
                  Break;
                end;
              end;
              if not b then
                aResult := 'Image resolution is too big!';
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
            end
            else
            begin
              {$Region '   Bmp zone   '}
              NewSize.x := BmpBGRA.Width;
              NewSize.y := BmpBGRA.Height;
              Ratio := Math.Min(cWinca[fSettings.rgResize.ItemIndex - 1].Width /
                NewSize.x, cWinca[fSettings.rgResize.ItemIndex -
                1].Height / NewSize.y);
              NewSize.x := Round(NewSize.x * Ratio);
              NewSize.y := Round(NewSize.y * Ratio);

              if (BmpBGRA.Width > cWinca[fSettings.rgResize.ItemIndex - 1].Width) or
                (BmpBGRA.Height > cWinca[fSettings.rgResize.ItemIndex -
                1].Height) then
              begin
                TmpBGRA :=
                  BmpBGRA.Resample(NewSize.x, NewSize.y, rmFineResample) as TBGRABitmap;
                BmpBGRA.SetSize(cWinca[fSettings.rgResize.ItemIndex - 1].Width,
                  cWinca[fSettings.rgResize.ItemIndex - 1].Height);
                BmpBGRA.FillRect(0, 0, BmpBGRA.Width,
                  BmpBGRA.Height, BGRABlack, dmSet);
                BmpBGRA.PutImage((BmpBGRA.Width - TmpBGRA.Width) div
                  2, (BmpBGRA.Height - TmpBGRA.Height) div 2, TmpBGRA,
                  dmDrawWithTransparency, 255);
              end
              else
              begin
                TmpBGRA :=
                  BmpBGRA.Resample(BmpBGRA.Width, BmpBGRA.Height, rmFineResample) as
                  TBGRABitmap;
                BmpBGRA.SetSize(cWinca[fSettings.rgResize.ItemIndex - 1].Width,
                  cWinca[fSettings.rgResize.ItemIndex - 1].Height);
                BmpBGRA.FillRect(0, 0, BmpBGRA.Width,
                  BmpBGRA.Height, BGRABlack, dmSet);
                BmpBGRA.PutImage((BmpBGRA.Width - TmpBGRA.Width) div
                  2, (BmpBGRA.Height - TmpBGRA.Height) div 2, TmpBGRA,
                  dmDrawWithTransparency, 255);
              end;
              {$EndRegion}
              b := True;
              aResult := Format('%d x %d image converted to %s.',
                [BmpBGRA.Width, BmpBGRA.Height,
                cWinca[fSettings.rgResize.ItemIndex - 1].Name]);
            end;

            if b then
            begin
              BmpBGRA.SaveToFileUTF8(bFile, wb);
              if fSettings.cbThumbnail.Enabled and
                fSettings.cbThumbnail.Checked then
                PngBGRA.SaveToFileUTF8(ChangeFileExt(bFile, '.png'));

              //PutByte(bFile, 'FFFEFFFF', 22);
              PutByte(bFile, GetByte(bFile, 22, 4, True), 22);
            end;
            BmpBGRA.Free;
            PngBGRA.Free;
            TmpBGRA.Free;
          except
            if aFile <> bFile then
              DeleteFile(bFile);
            aResult := 'Error while processing!';
          end;
        end
        else
          aResult := Format('Not %s file!', [cSupportedFileType])
      else
        aResult := 'File not found!';

      SubItems.Add(aResult);
      if AnsiContainsStr(aResult, ' image converted ') then
        StateIndex := 0
      else
        StateIndex := 1;
    end;
  wb.Free;
end;

procedure TfMain.FormDropFiles(Sender: TObject; const FileNames: array of string);
begin
  ProcessFiles(FileNames);
end;

procedure TfMain.FormCreate(Sender: TObject);
var
  strFilter: string;
begin
  AppDir := ExcludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
  TmpDir := ExcludeTrailingPathDelimiter(SysUtils.GetTempDir);
  //.bmp .gif .jpg .lzp .pcx .pdn .png .psd .tif
  //Bitmap files [*.bmp]|*.bmp|All files [*.*]|*.*
  strFilter := StringsReplace(cSupportedFileType, ['.', ' '],
    ['*.', ';'], [rfReplaceAll]);
  OpenDialog1.Filter := Format('Supported files (%s)|%s|All files (*.*)|*.*',
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
var
  FileNames: array of string;
  s: string;
  i: integer;
begin
  if OpenDialog1.Execute then
  begin
    SetLength(FileNames, OpenDialog1.Files.Count);
    i := 0;
    for s in OpenDialog1.Files do
    begin
      FileNames[i] := s;
      Inc(i);
    end;
    ProcessFiles(FileNames);
  end;
end;

procedure TfMain.miSettingsClick(Sender: TObject);
begin
  fSettings.ShowModal;
end;

initialization
  BGRAPaintNet.RegisterPaintNetFormat;

end.
