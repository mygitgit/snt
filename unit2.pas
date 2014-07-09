unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  RegExpr, IniFiles, Process, Classes, SysUtils;

type
  EShellException = Class(Exception);

  TStrArray = Array of String;

function execShell(shellCMD : String; raiseExcept : Boolean = true) : Integer;
function exitVal(shellCMD : String) : Integer;
function _(a : String) : String;
procedure protSS(var s : TStringList);

implementation


//Replaces #-tokens with
//values from ini-File
function _(a : String) : String;
var
  re: TRegExpr;
  i : TIniFile;
  match, exchg : String;
begin
  i := TIniFile.Create('./config.ini');
  re := TRegExpr.Create;
  re.Expression := '(#.+?\b)';
  if re.Exec(a) then
  repeat
       match := re.Match[1];
       exchg := i.readString('Tokens',RightStr(re.Match[1],Length(re.Match[1])-1),'');
       a := StringReplace(a, match, exchg, [rfReplaceAll]);
       writeln(match + ' -> ' + exchg);
  until not re.ExecNext;
  re.Free;
  i.Free;
  _ := a;
  writeln(_);
end;

procedure protSS(var s : TStringList);
var
  i : TIniFile;
  a : String;
  count : Integer;
  keylist : TStringList;
begin
  s.Create;
  i := TIniFile.Create('./config.ini');
  keyList := TStringList.Create;
  i.ReadSection('ProtectedSnapshots', keylist);
  for count := 0 to keyList.Count-1 do
  begin
    a := i.readString('ProtectedSnapshots',keyList.ValueFromIndex[count],'');
    s.Add(a);
    writeln('a= '+a);
  end;
  i.Free;
end;

function execShell(shellCMD : String; raiseExcept : Boolean = true) : Integer;
var
    hprocess: TProcess;
    outp : TStringList;
    //sPass : String;
begin
   //sPass := 'abc';
   hProcess := TProcess.Create(nil);

   hProcess.Executable := '/bin/sh';
   hprocess.Parameters.Add('-c');

  //shellCMD := 'echo ' + sPass  + ' | sudo -S ' + shellCMD;
  hprocess.Parameters.add(shellCMD);

  hProcess.Options := hProcess.Options + [poWaitOnExit, poUsePipes];
  hProcess.Execute;

  // Dump output to console
  outp := TStringlist.Create;
  outp.LoadfromStream(hProcess.Output);
  writeln(outp.Text);

  execShell := hProcess.ExitStatus;
  hProcess.Free;

  if (execShell<>0) AND (raiseExcept) then
     Raise EShellException.Create(shellCMD);
end;

function exitVal(shellCMD : String) : Integer;
begin
     exitVal := execShell(shellCMD, false);
end;


end.

