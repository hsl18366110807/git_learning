unit mainform;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Tcpgameserver, Vcl.ExtCtrls, Tcpserver, Data.DB,
  ZAbstractRODataset, ZAbstractDataset, ZDataset, ZAbstractConnection,
  ZConnection;

const
  UM_EVENT_STATUS_CHANGED = WM_USER + 1000;

type
  TEventsReceiver = class(TServerEventsReceiver)
  private
    FHandle: THandle;
  public
    procedure OnStatusChanged(OldStatus, NewStatus: TServerStatus); override;
  public
    constructor Create(OwnerHandle: THandle);
  end;



  TFormMain = class(TForm)
    StartButton: TButton;
    IPLabel: TLabel;
    IPEdit: TEdit;
    PortLabel: TLabel;
    PortEdit: TEdit;
    PageControl1: TPageControl;
    Timer1: TTimer;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    LogRichEdit: TRichEdit;
    procedure StartButtonClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FStarted: Boolean;
    LogUI: TStrings;
    FSvrEventReceiver: TEventsReceiver;
  private
    procedure MsgEventStatusChanged(var Msg: TMessage); message UM_EVENT_STATUS_CHANGED;
  end;

var
  FormMain: TFormMain;
implementation

uses
  LogServer;
{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
begin
  LogUI := TStringList.Create;
  FSvrEventReceiver := TEventsReceiver.Create(Handle);
  FTcpgameserver.SetEventsReceiver(FSvrEventReceiver);
  Log.Info('程序启动');
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Timer1.Enabled := False;
  FreeAndNil(LogUI);
end;

procedure TFormMain.MsgEventStatusChanged(var Msg: TMessage);
begin
  FStarted := False;
  case TServerStatus(Msg.LParam) of
    sStopped:
      begin
        IPEdit.ReadOnly := False;
        PortEdit.ReadOnly := False;
        StartButton.Caption := '启动';
        StartButton.Enabled := True;
      end;
    sStarting:
      begin
        IPEdit.ReadOnly := True;
        PortEdit.ReadOnly := True;
        StartButton.Enabled := False;
      end;
    sRunning:
      begin
        IPEdit.ReadOnly := True;
        PortEdit.ReadOnly := True;
        StartButton.Caption := '停止';
        StartButton.Enabled := True;
        FStarted := True;
      end;
    sStopping:
      begin
        IPEdit.ReadOnly := True;
        PortEdit.ReadOnly := True;
      end;
  end;
end;

procedure TFormMain.StartButtonClick(Sender: TObject);
begin
  if length(IPEdit.Text) = 0 then
  begin
    ShowMessage('请设置IP地址');
    Exit;
  end;
  if Length(PortEdit.Text) = 0 then
  begin
    ShowMessage('请设置端口号');
    Exit;
  end;
  if not FStarted then
  begin
    FTcpgameserver.start(IPEdit.Text, StrToInt(PortEdit.Text));
  end
  else
  begin
    FTcpgameserver.Stop;
  end;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
const
  LOG_COLOR: array[TLogLevel] of TColor = ($00BFBFBF, $0066EE00, $000088FF, $0000AAFF, $0000FFFF);
var
  i: Integer;
  LogLevel: TLogLevel;
  LogMsg: AnsiString;
begin
  Log.LodingLog(LogUI);
  for i := 0 to LogUI.Count - 1 do
  begin
    LogMsg := LogUI.Strings[i];
    LogLevel := Log.GetLogMsgLevel(LogMsg);
    LogRichEdit.sellength := 0;
    LogRichEdit.SelAttributes.color := LOG_COLOR[LogLevel];
    LogRichEdit.lines.Add(Copy(LogMsg, 2, Length(LogMsg)));
  end;
  LogUI.Clear;
end;

{ TEventsReceiver }

constructor TEventsReceiver.Create(OwnerHandle: THandle);
begin
  FHandle := OwnerHandle;
end;

procedure TEventsReceiver.OnStatusChanged(OldStatus, NewStatus: TServerStatus);
begin
  PostMessage(FHandle, UM_EVENT_STATUS_CHANGED, Ord(OldStatus), Ord(NewStatus));
end;

end.

