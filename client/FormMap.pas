unit FormMap;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ChatProtocol, Vcl.StdCtrls,  ChatManager;

type
  TFrmMap = class(TForm)
    Button1: TButton;
    btn1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
//    procedure btn1Click(Sender: TObject);
  private
    Fmsgs: TChatMsgs;
//    FMap:
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMap: TFrmMap;

implementation

{$R *.dfm}

procedure TFrmMap.btn1Click(Sender: TObject);
begin
//
end;

procedure TFrmMap.Button1Click(Sender: TObject);
var
  MsgPtr: PChatMsg;
  ServerMsgPtr: PServerMessage;
begin
  ChatMgr.ReadResponse(FMsgs);
  while not FMsgs.IsEmpty do
  begin
    FMsgs.FetchNext(MsgPtr);

    if MsgPtr <> nil then
    begin
      ServerMsgPtr := PServerMessage(MsgPtr);
      try
        case ServerMsgPtr^.Head.Command of
          S_REGISTER:
          begin
//            StopWait;
            ChatMgr.Disconnect;

            if ServerMsgPtr^.ErrorCode = 0 then
              MessageDlg('◊¢≤·≥…π¶, «Î ‰»Î’ ªß√‹¬Îµ«¬Ω!', mtInformation, [mbOK], 0)
            else
              MessageDlg('◊¢≤· ß∞‹', mtError, [mbOK], 0);

          end;

          S_LOGIN:
          begin
//            StopWait;

            if ServerMsgPtr^.ErrorCode <> 0 then
            begin
              ChatMgr.Disconnect;
              MessageDlg('µ«¬Ω ß∞‹ : ' + String(ServerMsgPtr^.ErrorInfo), mtError, [mbOK], 0);
            end
            else
            begin
              ModalResult := mrOK;
            end;
          end;

          S_Map:
          begin

          ShowMessage(' ’µΩ map');

          end;

        end;
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
end;

procedure TFrmMap.FormCreate(Sender: TObject);
begin
//
  FMsgs := TChatMsgs.Create;
  ChatMgr.RequestMap;
end;

end.
