unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  ExtCtrls, StdCtrls, lclintf;

type

  { TfAbout }

  TfAbout = class(TForm)
    ButtonPanel1: TButtonPanel;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lAbout: TLabel;
    procedure FormActivate(Sender: TObject);
    procedure Label4Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  fAbout: TfAbout;

implementation

{$R *.lfm}

uses Unit1;

  { TfAbout }

procedure TfAbout.Label4Click(Sender: TObject);
begin
  OpenURL((Sender as TLabel).Caption);
end;

procedure TfAbout.FormActivate(Sender: TObject);
var
  i: integer;
  sDevices: string;
begin
  sDevices := '';
  for i := 1 to Length(cWinca) do
    sDevices := sDevices + ', ' + cWinca[i - 1].Name;
  Delete(sDevices, 1, 2);
  lAbout.Caption := Format(lAbout.Caption, [Unit1.cSupportedFileType, sDevices]);
end;

end.
