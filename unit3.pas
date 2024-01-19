unit Unit3;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  StdCtrls, ExtCtrls, EditBtn, IniPropStorage;

type

  { TfSettings }

  TfSettings = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbThumbnail: TCheckBox;
    deNewLocation: TDirectoryEdit;
    edAddText: TEdit;
    gbOutput: TGroupBox;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    rbSameLocation: TRadioButton;
    rbNewLocation: TRadioButton;
    rgResize: TRadioGroup;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure rbSameLocationChange(Sender: TObject);
    procedure rgResizeSelectionChanged(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure SetSettings;
  end;

var
  fSettings: TfSettings;

implementation

{$R *.lfm}

uses Unit1;

  { TfSettings }

procedure TfSettings.rbSameLocationChange(Sender: TObject);
begin
  edAddText.Enabled := rbSameLocation.Checked;
  deNewLocation.Enabled := rbNewLocation.Checked;

end;

procedure TfSettings.rgResizeSelectionChanged(Sender: TObject);
var
  strResize: string = 'Create .png thumbnail file';
  i: integer;
begin
  i := rgResize.ItemIndex - 1;
  Label1.Caption := '';
  cbThumbnail.Caption := strResize;
  cbThumbnail.Enabled := rgResize.ItemIndex > 0;
  if rgResize.ItemIndex > 0 then
  begin
    Label1.Caption := Format('%d x %d', [cWinca[i].Width, cWinca[i].Height]);
    cbThumbnail.Caption := cbThumbnail.Caption + Format(' (%d x %d)',
      [cWinca[i].ThumbWidth, cWinca[i].ThumbHeight]);
  end;
end;

procedure TfSettings.FormCreate(Sender: TObject);
var
  i: integer;
begin
  IniPropStorage1.IniFileName := ChangeFileExt(ParamStr(0), '.ini');
  deNewLocation.Directory := AppDir;
  rgResize.Items.Clear;
  rgResize.Items.Add('No resizing');
  for i := Low(cWinca) to High(cWinca) do
    rgResize.Items.Add(cWinca[i].Name);
  if rgResize.ItemIndex = -1 then
  begin
    rgResize.ItemIndex := 0;
    rgResizeSelectionChanged(Sender);
  end;
end;

procedure TfSettings.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SetSettings;
end;

procedure TfSettings.SetSettings;
begin
  fMain.StatusBar1.Panels[0].Text := rgResize.Items[rgResize.ItemIndex];

  if (rgResize.ItemIndex > 0) and cbThumbnail.Checked then
    fMain.StatusBar1.Panels[1].Text := 'Create thumbnail file'
  else
    fMain.StatusBar1.Panels[1].Text := 'NO thumbnail file';

  if rbSameLocation.Checked then
  begin
    if Length(edAddText.Text) > 0 then
      fMain.StatusBar1.Panels[2].Text :=
        Format('Save output files in source folder and add "%s" to filename',
        [edAddText.Text])
    else
      fMain.StatusBar1.Panels[2].Text := 'Save output files in source folder';
  end
  else if rbNewLocation.Checked then
    fMain.StatusBar1.Panels[2].Text :=
      Format('Save all output files in "%s"', [deNewLocation.Directory]);
end;

end.
