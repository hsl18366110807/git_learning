program gameserver;

uses
  Vcl.Forms,
  mainform in 'mainform.pas' {FormMain},
  Tcpgameserver in 'Tcpgameserver.pas',
  LogServer in 'LogServer.pas',
  Tcpserver in 'Tcpserver.pas',
  GameProtocol in 'GameProtocol.pas',
  GameSqlServer in 'GameSqlServer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
