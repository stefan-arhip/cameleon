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
    Procedure SetSettings;
  end;

var
  fSettings: TfSettings;

implementation

{$R *.lfm}

Uses Unit1;

{ TfSettings }

procedure TfSettings.rbSameLocationChange(Sender: TObject);
begin
  edAddText.Enabled:= rbSameLocation.Checked;
  deNewLocation.Enabled:= rbNewLocation.Checked;


end;

procedure TfSettings.rgResizeSelectionChanged(Sender: TObject);
Var strResize: String= 'Create .png thumbnail file';
    i: Integer;
begin
  i:= rgResize.ItemIndex- 1;
  Label1.Caption:= '';
  cbThumbnail.Caption:= strResize;
  cbThumbnail.Enabled:= rgResize.ItemIndex> 0;
  If rgResize.ItemIndex> 0 Then
    Begin
      Label1.Caption:= Format('%d x %d', [cWinca[i].Width, cWinca[i].Height]);
      cbThumbnail.Caption:= cbThumbnail.Caption+ Format(' (%d x %d)', [cWinca[i].ThumbWidth, cWinca[i].ThumbHeight]);
    End;
end;

procedure TfSettings.FormCreate(Sender: TObject);
Var i: Integer;
begin
  IniPropStorage1.IniFileName:= ChangeFileExt(ParamStr(0), '.ini');
  deNewLocation.Directory:= AppDir;
  rgResize.Items.Clear;
  rgResize.Items.Add('No resizing');
  For i:= Low(cWinca) To High(cWinca) Do
    rgResize.Items.Add(cWinca[i].Name);
  If rgResize.ItemIndex= -1 Then
    Begin
      rgResize.ItemIndex:= 0;
      rgResizeSelectionChanged(Sender);
    End;
end;

procedure TfSettings.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SetSettings;
end;

procedure TfSettings.SetSettings;
Begin
  fMain.StatusBar1.Panels[0].Text:= rgResize.Items[rgResize.ItemIndex];

  If (rgResize.ItemIndex> 0) And cbThumbnail.Checked Then
    fMain.StatusBar1.Panels[1].Text:= 'Create thumbnail file'
  Else
    fMain.StatusBar1.Panels[1].Text:= 'NO thumbnail file';

  If rbSameLocation.Checked Then
    Begin
      If Length(edAddText.Text)> 0 Then
        fMain.StatusBar1.Panels[2].Text:= Format('Save output files in source folder and add "%s" to filename', [edAddText.Text])
      Else
        fMain.StatusBar1.Panels[2].Text:= 'Save output files in source folder';
    End
  Else If rbNewLocation.Checked Then
    fMain.StatusBar1.Panels[2].Text:= Format('Save all output files in "%s"', [deNewLocation.Directory]);
end;

end.

