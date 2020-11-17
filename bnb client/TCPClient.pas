unit TCPClient;

interface

uses
  Classes, SyncObjs, WinSock;

//Client Status  
const
  CS_STOPPED          =   0;
  CS_CONNECTING       =   1;
  CS_RUNNING          =   2;
  CS_DISCONNECTING    =   3;
  CS_CONNECTFAILED    =   4;

const
  SEND_BUF_SIZE = 1024 * 1024;
  RECV_BUF_SIZE = 1024 * 1024;

type
  TTCPClient = class(TThread)
  private
    FPort: Word;
    FHost: String;

    FSocket: TSocket;
    FLock: TCriticalSection;
    FWaitEvent: TEvent;

    FStatus: Integer;

    FSendBuffer: array[0..SEND_BUF_SIZE - 1] of Byte;
    FRecvBuffer: array[0..RECV_BUF_SIZE - 1] of Byte;

    FSendDataSize: Integer;
    FRecvDataSize: Integer;

    procedure SetHost(const Value: String);
    procedure SetPort(const Value: Word);
  private
    procedure RunStop;
    procedure RunConnecting;
    procedure RunRunning;
    procedure RunDisconnecting;
  protected
    procedure LockReadBuffer(var BufPtr: PByte; var BufSize: Integer);
    procedure UnlockReadBuffer(FetchSize: Integer);

    function WriteSendData(DataPtr: PByte; DataSize: Integer): Integer;

    procedure ProcessReadData; virtual;
    procedure Execute; override;
  public
    procedure Connect;
    procedure Disconnect;
    procedure Reset;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Host: String read FHost write SetHost;
    property Port: Word read FPort write SetPort;
    property Status: Integer read FStatus;
  end;

implementation

uses
  Windows, SysUtils, Math;

{ TTCPClient }

procedure TTCPClient.Connect;
var
  Ret: Integer;
begin
  Ret := InterlockedCompareExchange(FStatus, CS_CONNECTING, CS_STOPPED);
  if Ret = CS_STOPPED then
    FWaitEvent.SetEvent;
end;

constructor TTCPClient.Create;
var
  WSAData: TWSAData;
begin
  if WSAStartup(MAKEWORD(1,1), WSAData) <> 0 then
    raise Exception.Create('WSAStartup failed');
  FSocket := INVALID_SOCKET;
  FWaitEvent := TEvent.Create(nil, False, False, '');
  FLock := TCriticalSection.Create;
  inherited Create(False);
end;

destructor TTCPClient.Destroy;
begin
  Terminate;
  FWaitEvent.SetEvent;
  WaitFor;

  FWaitEvent.Free;
  FLock.Free;

  WSACleanup();
  
  inherited;
end;

procedure TTCPClient.Disconnect;
begin
  InterlockedCompareExchange(FStatus, CS_DISCONNECTING, CS_RUNNING);
end;

procedure TTCPClient.Execute;
begin
  while not Terminated do
  begin
    case FStatus of
      CS_STOPPED, CS_CONNECTFAILED: RunStop;
      CS_CONNECTING: RunConnecting;
      CS_RUNNING: RunRunning;
      CS_DISCONNECTING: RunDisconnecting;

    end;
  end;
end;

procedure TTCPClient.LockReadBuffer(var BufPtr: PByte; var BufSize: Integer);
begin
  BufPtr := @FRecvBuffer[0];
  BufSize := FRecvDataSize;
end;

procedure TTCPClient.ProcessReadData;
begin

end;

procedure TTCPClient.Reset;
begin
  InterlockedCompareExchange(FStatus, CS_STOPPED, CS_CONNECTFAILED);
end;

procedure TTCPClient.RunConnecting;
var
  SvrAddr: TSockAddr;
begin
  if FSocket = INVALID_SOCKET then
  begin
    FSocket := socket(AF_INET, SOCK_STREAM, 0);
    if FSocket = INVALID_SOCKET then
      raise Exception.Create('Create socket failed');

    SvrAddr.sin_family := AF_INET;
    SvrAddr.sin_addr.S_addr := inet_addr(PAnsiChar(AnsiString(FHost)));
    SvrAddr.sin_port := htons(FPort);

    if WinSock.connect(FSocket, SvrAddr, SizeOf(SvrAddr)) = SOCKET_ERROR then
    begin
      CloseSocket(FSocket);
      FSocket := INVALID_SOCKET;
      FStatus := CS_CONNECTFAILED;
      Exit;
    end;
  end;

  FStatus := CS_RUNNING;
end;

procedure TTCPClient.RunDisconnecting;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    CloseSocket(FSocket);
    FSocket := INVALID_SOCKET;
    FStatus := CS_STOPPED;

    FSendDataSize := 0;
    FRecvDataSize := 0;
  end;
end;

procedure TTCPClient.RunRunning;
var
  RFD, WFD: TFDSet;
  TimeOut: TTimeVal;
  SendBytes, RecvBytes, RemainBytes: Integer;
  ReadData: Boolean;
begin
  FD_ZERO(RFD);
  FD_ZERO(WFD);
  FD_SET(FSocket, RFD);
  FD_SET(FSocket, WFD);

  TimeOut.tv_sec := 0;
  TimeOut.tv_usec := 100000;
  ReadData := False;
  if select(RFD.fd_count + 1, @RFD, @WFD, nil, @TimeOut) > 0 then
  begin
    if FD_ISSET(FSocket, RFD) then
    begin
      FLock.Enter;
      try
        RemainBytes := RECV_BUF_SIZE - FRecvDataSize;
        if RemainBytes > 0 then
        begin
          RecvBytes := recv(FSocket, FRecvBuffer[FRecvDataSize], Min(RemainBytes, 512), 0);
          if RecvBytes > 0 then
          begin
            FRecvDataSize := FRecvDataSize + RecvBytes;
            ReadData := True;
          end;
        end;
      finally
        FLock.Leave;
      end;
    end;

    if FD_ISSET(FSocket, WFD) then
    begin
      FLock.Enter;
      try
        if FSendDataSize > 0 then
        begin
          SendBytes := send(FSocket, FSendBuffer[0], Min(FSendDataSize, 512), 0);
          if SendBytes > 0 then
          begin
            RemainBytes := FSendDataSize - SendBytes;
            if RemainBytes > 0 then
              Move(FSendBuffer[SendBytes], FSendBuffer[0], RemainBytes);
            FSendDataSize := RemainBytes;
          end;
        end;
      finally
        FLock.Leave;
      end;
    end;
  end;

  if ReadData then
    ProcessReadData;
end;

procedure TTCPClient.RunStop;
begin
  FWaitEvent.WaitFor(INFINITE);
end;

procedure TTCPClient.SetHost(const Value: String);
begin
  if CS_STOPPED = FStatus then
    FHost := Value
  else
    raise Exception.Create('TCP client is running, can not change host');  
end;

procedure TTCPClient.SetPort(const Value: Word);
begin
  if CS_STOPPED = FStatus then
    FPort := Value
  else
    raise Exception.Create('TCP client is running, can not change port');
end;

procedure TTCPClient.UnlockReadBuffer(FetchSize: Integer);
begin
  if (FetchSize > FRecvDataSize) or (FetchSize < 0) then
    raise Exception.Create('Fetch size error');

  Move(FRecvBuffer[FetchSize], FRecvBuffer[0], FetchSize);
  FRecvDataSize := FRecvDataSize - FetchSize;
end;

function TTCPClient.WriteSendData(DataPtr: PByte; DataSize: Integer): Integer;
var
  RemainSize, CopySize: Integer;
begin
  if FStatus <> CS_RUNNING then
  begin
    Result := -1;
    Exit;
  end;

  FLock.Enter;
  try
    RemainSize := SEND_BUF_SIZE - FSendDataSize;
    CopySize := Min(DataSize, RemainSize);

    if CopySize > 0 then
    begin
      Move(DataPtr^, FSendBuffer[FSendDataSize], CopySize);
      FSendDataSize := FSendDataSize + CopySize;
    end;

    Result := CopySize;
  finally
    FLock.Leave;
  end;
end;

end.
