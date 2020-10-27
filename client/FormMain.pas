unit FormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls, ExtCtrls, ChatProtocol;

type
  TFrmMain = class(TForm)
    redtChat: TRichEdit;
    lbOnlines: TListBox;
    Label1: TLabel;
    mmInput: TMemo;
    bbtnSend: TBitBtn;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bbtnSendClick(Sender: TObject);
  private
    FMsgs: TChatMsgs;
  private
    procedure UpdateUserState(UserStatePtr: PSMUserState);
    procedure ReceiveOthersMsg(ChitChatPtr: PSMChitChat);
  private
    { Private declarations }
    procedure ProcessServerMsgs;
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  ChatManager;

{$R *.dfm}

procedure TFrmMain.bbtnSendClick(Sender: TObject);
var
  DstAccount: String;
begin
  if mmInput.Text = '' then
    Exit;

  if lbOnlines.ItemIndex >= 0 then
  begin
    DstAccount := lbOnlines.Items[lbOnlines.ItemIndex];
    redtChat.Lines.Add(Format('你 -> %s : %s', [DstAccount, mmInput.Text]));
    ChatMgr.RequestSendMsg(DstAccount, mmInput.Text);
  end
  else
  begin
    ShowMessage('没有选择要发送消息的对象');
  end;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  Caption := '帐号 : ' + ChatMgr.Account;
  FMsgs := TChatMsgs.Create;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FMsgs.Free;  
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  ChatMgr.RequestUsers;
end;

procedure TFrmMain.ProcessServerMsgs;
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
          SM_USER_STATE: UpdateUserState(PSMUserState(ServerMsgPtr));

          SM_SENDMSG: ReceiveOthersMsg(PSMChitChat(ServerMsgPtr));
        end;
      finally
        FreeMem(MsgPtr);
      end;
    end;
  end;
end;

procedure TFrmMain.ReceiveOthersMsg(ChitChatPtr: PSMChitChat);
var
  MsgText: String;
begin
  MsgText := Format('%s -> 你 : %s', [ChitChatPtr^.SrcAccount, ChitChatPtr^.Msg]);

  redtChat.Lines.Add(MsgText);
end;

procedure TFrmMain.Timer1Timer(Sender: TObject);
begin
  ProcessServerMsgs;
end;

procedure TFrmMain.UpdateUserState(UserStatePtr: PSMUserState);
var
  Idx: Integer;
begin
  if UserStatePtr^.Account = ChatMgr.Account then
    Exit;
  
  Idx := lbOnlines.Items.IndexOf(String(UserStatePtr^.Account));
  if (Idx >= 0) and (not UserStatePtr^.Online) then
  begin
    lbOnlines.Items.Delete(Idx);
  end
  else
  begin
    if (Idx < 0) and UserStatePtr^.Online then
      lbOnlines.Items.Add(String(UserStatePtr^.Account));
  end;
end;

end.
