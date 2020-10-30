unit GameProtocol;

interface

uses
  System.SyncObjs, System.SysUtils;

const
  PACK_FLAG = $FFBBFFCC;
  MapLength = 19;
  MapWide = 19;
  BoomTime = 5000;
  BoomScope = 5;
type
  MoveDirect = (MOEVUP, MOVEDOWN, MOVELEFT, MOVERIGHT);

  PGameMsgHead = ^TGameMsgHead;

  TGameMsgHead = record
    Flag: Cardinal;
    Size: Integer;
    Command: Integer;
    Param: Integer;
  end;

  PLoginMsg = ^TLoginMsg;

  TLoginMsg = record
    Head: TGameMsgHead;
    UserName: array[0..15] of AnsiChar;
    Password: array[0..15] of AnsiChar;
  end;

  PServerMessage = ^TServerMessage;

  TServerMessage = record
    head: TGameMsgHead;
    ErrorCode: Integer;
    ErrorInfo: array[0..31] of AnsiChar;
  end;

  MapSign = (MOVE, BLOCK, BOX, CHARACTRT); //���ƶ����ϰ��ľ�䣬�н�ɫ

  TMap = record
    head: TGameMsgHead;
    Map: array[0..MapLength, 0..MapWide] of Integer;
  end;

  PPlayerMove = ^TPlayerMove;

  TPlayerMove = record
    head: TGameMsgHead;
    PlayerName: AnsiString;
    MoveType: MoveDirect;
  end;

  PPlayerSetBoom = ^TPlayerSetBoom;

  TPlayerSetBoom = record
    head: TGameMsgHead;
    PlayerName: AnsiString; //�����û���Ѱ������
  end;

  TBombBoom = record
    head: TGameMsgHead;
    Bombx: Integer;
    BombY: Integer;
  end;

  TPlayerDeadEvent = record
    head: TGameMsgHead;
    UserName: AnsiString;
    PlayerPosX: Integer;
    PlayerPosY: Integer;
  end;

  TBomb = class
  public
    BombID: Integer;
    Timer: TDateTime;
  private
    BombPosX: Integer;
    BombPosY: Integer;
  public
    constructor Create(x: Integer; y: Integer);
    property FBombPosX: Integer read BombPosX;
    property FBombPosY: Integer read BombPosY;
  end;

const
  C_REGISTER = 1;
  S_REGISTER = 2;
  C_LOGIN = 3;
  S_LOGIN = 4;
  C_MAP = 5;
  S_MAP = 6;
  C_MOVE = 7;
  C_BOOM = 8;
  S_BOMBBOOM = 9;
  S_PlayerDead = 10;

implementation

{ TBOMB }

{ TBOMB }

constructor TBOMB.Create(x, y: Integer);
begin
  Timer := Now;
  BombPosX := x;
  BombPosY := y;
end;

end.

