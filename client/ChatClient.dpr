program ChatClient;

uses
  Forms,
  Controls,
  FormMain in 'FormMain.pas' {FrmMain},
  FormLogin in 'FormLogin.pas' {FrmLogin},
  ChatManager in 'ChatManager.pas',
  TCPClient in 'TCPClient.pas',
  ChatProtocol in 'ChatProtocol.pas',
  FormMap in 'FormMap.pas' {FrmMap};

//  {$R}
//  var,


//uses
//  Forms,
//  Controls,
//  FormMain in 'FormMain.pas' {FrmMain},
//  FormLogin in 'FormLogin.pas' {FrmLogin},
//  ChatManager in 'ChatManager.pas',
//  TCPClient in 'TCPClient.pas',
//  ChatProtocol in '..\Common\ChatProtocol.pas';

{$R *.res}

var
  ExitApp: Boolean;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  ExitApp := False;
  repeat
    FrmLogin := TFrmLogin.Create(Application);
    if FrmLogin.ShowModal = mrCancel then
    begin
      ExitApp := True;
      break;
    end
    else
      break;
  until False;

  if not ExitApp then
  begin
    Application.CreateForm(TFrmMap, FrmMap);
    Application.Run;
  end;
end.

