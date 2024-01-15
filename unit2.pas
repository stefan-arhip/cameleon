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

Uses Unit1;

{ TfAbout }

procedure TfAbout.Label4Click(Sender: TObject);
begin
  OpenURL((Sender As TLabel).Caption);
end;

procedure TfAbout.FormActivate(Sender: TObject);
Var i: Integer;
    sDevices: String;
begin
  sDevices:= '';
  For i:= 1 To Length(cWinca) Do
    sDevices:= sDevices+ ', '+ cWinca[i- 1].Name;
  Delete(sDevices, 1, 2);
  lAbout.Caption:= Format(lAbout.Caption, [Unit1.cSupportedFileType, sDevices]);
end;

end.

