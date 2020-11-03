unit ChatProtocol;

interface

uses
  SyncObjs;

const
  PACK_FLAG = $FFBBFFCC;
  MapLength = 19; //地图最大长度
  MapWide = 19; //地图最大宽度

type
  MoveDirect = (MOVEUP, MOVEDOWN, MOVELEFT, MOVERIGHT);

  TUserAccount = array[0..15] of AnsiChar;

  PChatMsgHead = ^TChatMsgHead;

  TChatMsgHead = record
    Flag: Cardinal;
    Size: Integer;
    Command: Integer;
    Param: Integer;
  end;

  PChatMsg = ^TChatMsg;

  TChatMsg = record
    Head: TChatMsgHead;
    Data: array[0..0] of Byte;
  end;

  PCMRegister = ^TCMRegister;

  TCMRegister = record
    Head: TChatMsgHead;
//    Account: TUserAccount;
    UserName: TUserAccount;
    Password: array[0..15] of AnsiChar;
  end;

  PCMLogin = ^TCMLogin;

  TCMLogin = record
    Head: TChatMsgHead;
    UserName: TUserAccount;
    Password: array[0..15] of AnsiChar;
  end;

  PCMUserState = ^TCMUserState;

  TCMUserState = record
    Head: TChatMsgHead;
  end;

  PTCMap = ^TCMap;

  TCMap = record
    Head: TChatMsgHead;
  end;

  PTSMap = ^TSMap;

  TSMap = record
    Head: TChatMsgHead;
    Map: array[0..MapLength, 0..MapWide] of Integer;
  end;

  PPlayerMove = ^TPlayerMove;

  TPlayerMove = record
    head: TChatMsgHead;
    PlayerName: TUserAccount;
    MoveType: MoveDirect;
  end;

  PSMUserState = ^TSMUserState;

  TSMUserState = record
    Head: TChatMsgHead;
    Online: Boolean;
    Account: TUserAccount;
  end;

  PCMChitChat = ^TCMChitChat;

  TCMChitChat = record
    Head: TChatMsgHead;
    DestAccount: TUserAccount;
    Msg: array[0..255] of AnsiChar;
  end;

  PSMChitChat = ^TSMChitChat;

  TSMChitChat = record
    Head: TChatMsgHead;
    SrcAccount: TUserAccount;
    Msg: array[0..255] of AnsiChar;
  end;

  PServerMessage = ^TServerMessage;

  TServerMessage = record
    Head: TChatMsgHead;
    ErrorCode: Integer;
    ErrorInfo: array[0..31] of AnsiChar;
  end;

 // 地图 为二维数组
  MapSign = (PMOVE, PBLOCK, PBOX, PCHARACTRT, PBOMB); //可移动，障碍物，木箱，有角色，炸弹

  TMap = record
    Map: array[0..MapLength, 0..MapWide] of Integer;
  end;

   TPlayerSetBoom = record
    head: TChatMsgHead;
    PlayerName: TUserAccount; //根据用户名寻找坐标
  end;


  PTBombBoom = ^TBombBoom;
  TBombBoom = record
    head: TChatMsgHead;
    Bombx: Integer;
    BombY: Integer;
    BoomW: Integer;
    BoomA: Integer;
    BoomS: Integer;
    BoomD: Integer;
  end;


type
  PChatMsgNode = ^TChatMsgNode;

  TChatMsgNode = record
    Next: PChatMsgNode;
    ChatMsgPtr: PChatMsg;
  end;

  TChatMsgs = class
  protected
    FHeadPtr: PChatMsgNode;
    FTailPtr: PChatMsgNode;
  protected
    procedure AddNodeLinkToTail(HeadPtr, TailPtr: PChatMsgNode); virtual;
  public
    procedure FetchNext(var MsgPtr: PChatMsg); virtual;
    procedure AddTail(ChatMsgPtr: PChatMsg); virtual;
    procedure FetchTo(Dest: TChatMsgs); virtual;
    function IsEmpty: Boolean; virtual;
    procedure Clear; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TLockChatMsgs = class(TChatMsgs)
  private
    FLock: TCriticalSection;
  protected
    procedure AddNodeLinkToTail(HeadPtr, TailPtr: PChatMsgNode); override;
  public
    procedure FetchNext(var MsgPtr: PChatMsg); override;
    procedure AddTail(ChatMsgPtr: PChatMsg); override;
    procedure FetchTo(Dest: TChatMsgs); override;
    procedure Clear; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

const
  C_REGISTER = 1;
  S_REGISTER = 2;
  C_LOGIN = 3;
  S_LOGIN = 4;
  C_Map = 5;
  S_Map = 6;
  C_MOVE = 7;
  C_BOOM = 8;
  S_BOMBBOOM = 9;
  CM_USER_STATE = 5;
  SM_USER_STATE = 6;
  CM_SENDMSG = 7;
  SM_SENDMSG = 8;

implementation

{ TChatMsgs }

procedure TChatMsgs.AddNodeLinkToTail(HeadPtr, TailPtr: PChatMsgNode);
begin
  if FHeadPtr <> nil then
  begin
    FTailPtr^.Next := HeadPtr;
    FTailPtr := TailPtr;
  end
  else
  begin
    FHeadPtr := HeadPtr;
    FTailPtr := TailPtr;
  end;
end;

procedure TChatMsgs.AddTail(ChatMsgPtr: PChatMsg);
var
  NewNodePtr: PChatMsgNode;
begin
  NewNodePtr := AllocMem(SizeOf(PChatMsgNode));
  NewNodePtr^.ChatMsgPtr := ChatMsgPtr;

  if FHeadPtr = nil then
  begin
    FHeadPtr := NewNodePtr;
    FTailPtr := FHeadPtr;
  end
  else
  begin
    FTailPtr^.Next := NewNodePtr;
    FTailPtr := NewNodePtr;
  end;
end;

procedure TChatMsgs.FetchTo(Dest: TChatMsgs);
begin
  if FTailPtr <> nil then
  begin
    Dest.AddNodeLinkToTail(FHeadPtr, FTailPtr);

    FHeadPtr := nil;
    FTailPtr := nil;
  end;
end;

procedure TChatMsgs.Clear;
var
  LinkPtr, OldPtr: PChatMsgNode;
begin
  LinkPtr := FHeadPtr;
  FHeadPtr := nil;
  FTailPtr := nil;

  while LinkPtr <> nil do
  begin
    OldPtr := LinkPtr;
    LinkPtr := LinkPtr^.Next;

    FreeMem(OldPtr^.ChatMsgPtr);
    FreeMem(OldPtr);
  end;
end;

constructor TChatMsgs.Create;
begin

end;

destructor TChatMsgs.Destroy;
begin
  Clear;

  inherited;
end;

procedure TChatMsgs.FetchNext(var MsgPtr: PChatMsg);
var
  FetchNodePtr: PChatMsgNode;
begin
  MsgPtr := nil;
  if FHeadPtr <> nil then
  begin
    FetchNodePtr := FHeadPtr;
    FHeadPtr := FHeadPtr^.Next;
    if FHeadPtr = nil then
      FTailPtr := nil;

    MsgPtr := FetchNodePtr^.ChatMsgPtr;

    FreeMem(FetchNodePtr);
  end;
end;

function TChatMsgs.IsEmpty: Boolean;
begin
  Result := (FHeadPtr = nil);
end;

{ TLockChatMsgs }

procedure TLockChatMsgs.AddNodeLinkToTail(HeadPtr, TailPtr: PChatMsgNode);
begin
  FLock.Enter;
  try
    inherited;
  finally
    FLock.Leave;
  end;
end;

procedure TLockChatMsgs.AddTail(ChatMsgPtr: PChatMsg);
begin
  FLock.Enter;
  try
    inherited;
  finally
    FLock.Leave;
  end;
end;

procedure TLockChatMsgs.FetchTo(Dest: TChatMsgs);
begin
  FLock.Enter;
  try
    inherited;
  finally
    FLock.Leave;
  end;
end;

procedure TLockChatMsgs.Clear;
begin
  FLock.Enter;
  try
    inherited;
  finally
    FLock.Leave;
  end;
end;

constructor TLockChatMsgs.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
end;

destructor TLockChatMsgs.Destroy;
begin
  FLock.Enter;
  try
    inherited;
  finally
    FLock.Leave;
  end;

  FLock.Free;
end;

procedure TLockChatMsgs.FetchNext(var MsgPtr: PChatMsg);
var
  FetchNodePtr: PChatMsgNode;
begin
  MsgPtr := nil;

  FLock.Enter;
  try
    FetchNodePtr := FHeadPtr;
    if FHeadPtr <> nil then
    begin
      FHeadPtr := FHeadPtr^.Next;
      if FHeadPtr = nil then
        FTailPtr := nil;
    end;
  finally
    FLock.Leave;
  end;

  if FetchNodePtr <> nil then
  begin
    MsgPtr := FetchNodePtr^.ChatMsgPtr;
    FreeMem(FetchNodePtr);
  end;
end;

end.

