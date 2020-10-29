unit ChatManager;

interface

uses
  ChatProtocol, TCPClient, SyncObjs, Winapi.Windows;

type
  TChatMgr = class(TTCPClient)
  private
    FServerMsgs: TLockChatMsgs;
    FAccount: String;
  protected
    procedure ProcessReadData; override;
  public
    procedure ReadResponse(Msgs: TChatMsgs);
    function RequestRegister(Account: String; Password: String): Integer;
    function RequestLogin(Account: String; Password: String): Integer;
    function RequestUsers: Integer;
    function RequestMap: Integer;
    function RequestSendMsg(Account: String; Msg: String): Integer;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Account: String read FAccount;
  end;

var
  ChatMgr: TChatMgr;

implementation

uses
  SysUtils;

{ TChatMgr }

constructor TChatMgr.Create;
begin
  FServerMsgs := TLockChatMsgs.Create;
 
  inherited Create;
end;

destructor TChatMgr.Destroy;
begin
  inherited;
  FServerMsgs.Free;
end;

procedure TChatMgr.ProcessReadData;
var
  BufPtr: PByte;
  BufSize, FetchSize: Integer;
  MsgPtr: PChatMsg;
begin
  LockReadBuffer(BufPtr, BufSize);

  FetchSize := 0;
  try
    if BufSize <= 0 then
      Exit;

    while BufSize >= SizeOf(TChatMsgHead) do
    begin
      while BufSize >= 4 do
      begin
        if PCardinal(BufPtr)^ <> PACK_FLAG then
        begin
          BufSize := BufSize - 1;
          BufPtr := Pointer(Integer(BufPtr) + 1);
          FetchSize := FetchSize + 1;
        end
        else
          break;
      end;

      if BufSize >= SizeOf(TChatMsgHead) then
      begin
        if PChatMsgHead(BufPtr)^.Size <= BufSize then
        begin
          FetchSize := FetchSize + PChatMsgHead(BufPtr)^.Size;

          GetMem(MsgPtr, PChatMsgHead(BufPtr)^.Size);
          System.Move(BufPtr^, MsgPtr^, PChatMsgHead(BufPtr)^.Size);

          BufSize := BufSize - MsgPtr^.Head.Size;
          BufPtr := Pointer(Integer(BufPtr) + MsgPtr^.Head.Size);

          FServerMsgs.AddTail(MsgPtr);
        end
        else
          break;
      end;
    end;

  finally
    UnlockReadBuffer(FetchSize);
  end;
end;

procedure TChatMgr.ReadResponse(Msgs: TChatMsgs);
begin
  FServerMsgs.FetchTo(Msgs);
end;

function TChatMgr.RequestLogin(Account, Password: String): Integer;
var
  CMLogin: TCMLogin;
begin
  if Length(Account) >= Length(CMLogin.UserName) then
  begin
    Result := -1;
    Exit;
  end;
  
  if Length(Password) >= Length(CMLogin.Password) then
  begin
    Result := -2;
    Exit;
  end;

  Result := 0;

  FAccount := Account;

  FillChar(CMLogin, SizeOf(CMLogin), 0);
  CMLogin.Head.Flag := PACK_FLAG;
  CMLogin.Head.Size := SizeOf(CMLogin);
  CMLogin.Head.Command := C_LOGIN;


  strpcopy(@CMLogin.UserName[0], AnsiString(Account));
  strpcopy(@CMLogin.Password[0], AnsiString(Password));

  if WriteSendData(@CMLogin, SizeOf(CMLogin)) < 0 then
    Result := -3;
end;



function TChatMgr.RequestRegister(Account, Password: String): Integer;
var
  CMReg: TCMRegister;
begin
  if (Length(Account) >= Length(CMReg.UserName)) then
  begin
    Result := -1;
    Exit;
  end;
  
  if (Length(Password) >= Length(CMReg.Password)) then
  begin
    Result := -2;
    Exit;
  end;

  Result := 0;

  FillChar(CMReg, SizeOf(CMReg), 0);
  CMReg.Head.Flag := PACK_FLAG;
  CMReg.Head.Size := SizeOf(CMReg);
  CMReg.Head.Command := C_REGISTER;

  strpcopy(@CMReg.UserName[0], AnsiString(Account));
  strpcopy(@CMReg.Password[0], AnsiString(Password));

  if WriteSendData(@CMReg, SizeOf(CMReg)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestSendMsg(Account, Msg: String): Integer;
var
  CMChitChat: TCMChitChat;
begin
  Result := 0;
  
  FillChar(CMChitChat, SizeOf(CMChitChat), 0);
  CMChitChat.Head.Flag := PACK_FLAG;
  CMChitChat.Head.Size := SizeOf(CMChitChat);
  CMChitChat.Head.Command := CM_SENDMSG;
  StrLCopy(@CMChitChat.DestAccount[0], PAnsiChar(Account), Length(CMChitChat.DestAccount));
  StrLCopy(@CMChitChat.Msg[0], PAnsiChar(Msg), Length(CMChitChat.Msg));

  if WriteSendData(@CMChitChat, SizeOf(CMChitChat)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestUsers: Integer;
var
  CMUserState: TCMUserState;
begin
  Result := 0;

  FillChar(CMUserState, SizeOf(CMUserState), 0);
  CMUserState.Head.Flag := PACK_FLAG;
  CMUserState.Head.Size := SizeOf(CMUserState);
  CMUserState.Head.Command := CM_USER_STATE;

  if WriteSendData(@CMUserState, SizeOf(CMUserState)) < 0 then
    Result := -3;
end;

function TChatMgr.RequestMap: Integer;
var
  CReqMap: TCMap;
begin
  Result := 0;
  FillChar(CReqMap, SizeOf(CReqMap), 0);
  CReqMap.Head.Flag := PACK_FLAG;
  CReqMap.Head.Size := SizeOf(CReqMap);
  CReqMap.Head.Command := C_Map;

  if WriteSendData(@CReqMap, SizeOf(CReqMap)) < 0 then
    Result := -3;

end;



initialization
  ChatMgr := TChatMgr.Create;

finalization
  FreeAndNil(ChatMgr);

end.
