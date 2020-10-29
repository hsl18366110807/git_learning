unit GameProtocol;

interface

uses
  System.SyncObjs;

const
  PACK_FLAG = $FFBBFFCC;
  MapLength = 9;
  MapWide = 9;

type
  PLoginMsgHead = ^TLoginMsgHead;

  TLoginMsgHead = record
    Flag: Cardinal;
    Size: Integer;
    Command: Integer;
    Param: Integer;
  end;

  PLoginMsg = ^TLoginMsg;

  TLoginMsg = record
    Head: TLoginMsgHead;
    UserName: array[0..15] of AnsiChar;
    Password: array[0..15] of AnsiChar;
  end;

  PServerMessage = ^TServerMessage;

  TServerMessage = record
    head: TLoginMsgHead;
    ErrorCode: Integer;
    ErrorInfo: array[0..31] of AnsiChar;
  end;

  MapSign = (MOVE, BLOCK, BOX, CHARACTRT); //可移动，障碍物，木箱，有角色

  TMap = record
    head: TLoginMsgHead;
    Map: array[0..MapLength, 0..MapWide] of Integer;
  end;

const
  C_REGISTER = 1;
  S_REGISTER = 2;
  C_LOGIN = 3;
  S_LOGIN = 4;
  C_MAP = 5;
  S_MAP = 6;

implementation

end.

