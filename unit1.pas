unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Unit2,
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids, ExtCtrls, Math, StrUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label1: TLabel;
    StringGrid1: TStringGrid;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure StringGrid1Selection(Sender: TObject; aCol, aRow: Integer);
  private
    { private declarations }
    procedure UpdateStringGrid();

  public
    { public declarations }
  end;

var
  Form1: TForm1;
  LockFile : File;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.UpdateStringGrid();
var
  //row : Integer = 0;
  info : TSearchRec;
  datestr : String;
  btnsEnabled : Boolean = true;
  ps : TStringList;
  ssName : String;
begin
  ps := TStringList.Create;
  protSS(ps);
  with StringGrid1 do
  begin
    RowCount:= 1;
    If FindFirst (_('#btrfs/#snapsubdir/#ssprefix*'),faDirectory,info)=0 then
    begin
      Repeat
        RowCount := RowCount + 1;
        With info do
        begin
          ssName := RightStr(Name,Length(Name)-Length(_('#ssprefix')));
          DateTimeToString(datestr,'yyyy/mm/dd    hh:mm',FileDateToDateTime(Time));
          Cells[0, RowCount-1] := datestr;
          Cells[1, RowCount-1] := ssName;
          //check if protected
          if ps.IndexOf(ssName)<>-1 then
            Cells[2, RowCount-1] := 'JA';
        end;
      Until FindNext(info)<>0;
    end;

    // Disable Buttons if no Snapshots available
    if RowCount <=1 then btnsEnabled := false;
    Button2.Enabled:= btnsEnabled;
    Button3.Enabled:= btnsEnabled;

    // Set current Row
    StringGrid1Selection(Self, 0, min(RowCount,1));
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  ssName : String;
begin
  // come up with a new Snapshot-Name
  DateTimeToString(ssName, 'yyyymmddhhmmss', Now);
  execShell(_('btrfs sub snap "#btrfs/@" "#btrfs/#snapsubdir/#ssprefix')+'Neuer Snapshot ' + ssName+'"');

  // update Snapshot-Data
  UpdateStringGrid();
  with StringGrid1 do Row := RowCount-1;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  ssName : String;
  trashName : String;
begin
  // come up with a new Trash-Name
  DateTimeToString(trashName, 'yyyymmddhhmmss', Now);
  ssName := StringGrid1.Cells[1,StringGrid1.Row];
  execShell(_('mv "#btrfs/#snapsubdir/#ssprefix')+ssName+_('" "#btrfs/#trashdir/#trashprefix')+trashName+'"');

  // update Snapshot-Data
  UpdateStringGrid();
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  ssName : String;
  trashName : String;
begin
  ssName := StringGrid1.Cells[1,StringGrid1.Row];
  // Ask if reboot is OK
  if MessageDlg(
    'Neustart erforderlich!',
    'Um das System in den gewählten Zustand zurückzuversetzen,'+#13+
    'ist ein sofortiger Neustart erforderlich.'+#13+#13+
    'Rollback zu Snapshot:'+#13+ssName+#13+#13+
    'Soll der Vorgang wirklich fortgesetzt werden?'
    , mtConfirmation, [mbCancel,mbYes],0) = mrYes then
  begin
    // come up with a name for the old state
    DateTimeToString(trashName, 'yyyymmddhhmmss', Now);
    execShell(_('mv "#btrfs/@" "#btrfs/#trashdir/#trashprefix')+trashName+'"');
    execShell(_('btrfs sub snap "#btrfs/#snapsubdir/#ssprefix')+ssName+_('" "#btrfs/@"'));

    // restart the computer
    Sleep(2000);
    execShell('reboot');
  end;
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  // mount btrfs-root (if not mounted)
  if exitVal(_('mount | grep #btrfs'))<>0 then
     execShell(_('mount #hdd #btrfs #mntopt'));

  // open dummy-file so that mount-point cannot be unmounted
  AssignFile(LockFile, _('#btrfs/.lock'));
  Rewrite(LockFile);

  // populate Snapshot-Data
  UpdateStringGrid();
end;


procedure TForm1.FormDestroy(Sender: TObject);
begin
  CloseFile(LockFile);
end;

procedure TForm1.Label1Click(Sender: TObject);
begin

end;



procedure TForm1.StringGrid1Selection(Sender: TObject; aCol, aRow: Integer);
begin
  // Disable Delete-Button if protected
  if StringGrid1.Cells[2,aRow]='JA' then
    Button2.Enabled := False
  else
    Button2.Enabled := True;

  if (ACol=1) and (ARow=1) then
  begin
    StringGrid1.Options:=StringGrid1.Options+[goEditing];
  end else
  begin
    StringGrid1.Options:=StringGrid1.Options-[goEditing];
  end;
end;


end.

