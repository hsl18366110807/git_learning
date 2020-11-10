unit Tcpserver;

interface

uses
  System.Classes, System.SyncObjs, Winapi.WinSock, Winapi.Windows,
  System.SysUtils;

type
  TServerStatus = (sStopped, sStarting, sRunning, sStopping);

  TServerEventsReceiver = class
  public
    procedure OnStatusChanged(OldStatus, NewStatus: TServerStatus); virtual; abstract;
  end;

  TTCPClient = class
  private
    FSocket: TSocket;
    FHostAddress: AnsiString;
    FHostPort: Word;
    FReadBuffer: array of Byte;
    FReadBufSize: Integer;
    FSendBuffer: array of Byte;
    FSendBufSize: Integer;
    FReadDataSize: Integer;
    FSendDataSize: Integer;
  protected
    function DoReadData: Boolean;
    function DoSendData: Boolean;
  public
    procedure LockReadBuffer(var BufPtr: PByte; var BufSize: Integer);
    procedure UnLockReadBuffer(FetchSize: Integer);
    constructor Create(ASocket: TSocket; RemoteIP: string; RemotePort: Word);
    destructor Destroy; override;
  public
    function SendData(DataPtr: PByte; DataSize: Integer): Integer;
  end;

  TTcpServer = class(TThread)
  public
    FClients: TList;
  private
    FStatus: TServerStatus;
    FLock: TCriticalSection;
    FSocket: TSocket;
    FIP: AnsiString;
    FPort: Word;
    FEventsReceiver: TServerEventsReceiver;
  private
    FWaitEvent: TEvent;
    FExitThread: Boolean;
    procedure WaitRun;
    procedure WaitStart;
    procedure Working;
    procedure WaitStop;
    procedure WaitStoping;
    procedure DoAccept;
    procedure CloseClients;
    procedure SetStatus(const Value: TServerStatus);
  protected
    procedure Execute; override;
    procedure ClientRemoved(AClient: TTCPClient); virtual;
    procedure ProcessClientIO(AClient: TTCPClient); virtual;
    procedure CheckBombTime; virtual;
    procedure SetShoesProp; virtual;
  protected
    property Status: TServerStatus read FStatus write SetStatus;
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure SetEventsReceiver(Receiver: TServerEventsReceiver);
    procedure Start(IP: AnsiString; port: word);
    procedure Stop(ExitThread: Boolean = False);
  end;

implementation

{ TTcpServer }
uses
  LogServer, Math;

procedure TTcpServer.CheckBombTime;
begin

end;

procedure TTcpServer.ClientRemoved(AClient: TTCPClient);
begin

end;

procedure TTcpServer.CloseClients;
begin

end;

constructor TTcpServer.Create;
var
  WSAData: TWSAData;
begin
  FLock := TCriticalSection.Create;
  FWaitEvent := TEvent.Create(nil, False, False, '');
  FClients := TList.Create;
  FEventsReceiver := TServerEventsReceiver.Create;
  if WSAStartup(MAKEWORD(1, 1), WSAData) <> 0 then
    Log.Fatal('WSAStartup failed, last error : ' + IntToStr(GetLastError));
  FSocket := INVALID_SOCKET;
  inherited Create(False);

end;

destructor TTcpServer.Destroy;
begin
  Stop(True);
  Terminate;
  WaitFor;
  FClients.Free;
  FLock.Free;
  FEventsReceiver.Free;
  WSACleanup();
  inherited;
end;

procedure TTcpServer.DoAccept;
var
  ClientAddr: TSockaddr;
  ClientSocket: TSocket;
  AClient: TTCPClient;
  AddrLen: Integer;
begin
  AddrLen := SizeOf(ClientAddr);
  ClientSocket := accept(FSocket, @ClientAddr, @AddrLen);
  with ClientAddr do
  begin
    AClient := TTCPClient.Create(ClientSocket, AnsiString(inet_ntoa(sin_addr)), ntohs(sin_port));
    FClients.Add(AClient);
  end;
  with AClient do
  begin
    Log.Debug(Format('接受来自 %s:%d 的连接 socket : %d', [FHostAddress, FHostPort, ClientSocket]));
  end;

end;

procedure TTcpServer.Execute;
begin
  while not Terminated do
  begin
    case FStatus of
      sStopped:
        WaitRun;
      sStarting:
        WaitStart;
      sRunning:
        Working;
      sStopping:
        WaitStoping;
    end;
  end;

end;

procedure TTcpServer.ProcessClientIO(AClient: TTCPClient);
begin

end;

procedure TTcpServer.SetEventsReceiver(Receiver: TServerEventsReceiver);
begin
  FLock.Enter;
  try
    FEventsReceiver := Receiver;
  finally
    FLock.Leave;
  end;
end;

procedure TTcpServer.SetShoesProp;
begin

end;

procedure TTcpServer.SetStatus(const Value: TServerStatus);
var
  OldStatus: TServerStatus;
begin
  if FStatus <> Value then
  begin
    OldStatus := FStatus;
    FStatus := Value;
    if FEventsReceiver <> nil then
    begin
      FEventsReceiver.OnStatusChanged(OldStatus, FStatus);
    end;
  end;
end;

procedure TTcpServer.Start(IP: AnsiString; port: word);
var
  Starttable: Boolean;
begin
  FLock.Enter;
  try
    if FStatus = sStopped then
    begin
      FIP := IP;
      FPort := port;
      Status := sStarting;
      Starttable := True;
      FWaitEvent.SetEvent;
    end
    else
    begin
      Starttable := False;
    end;
  finally
    FLock.Leave;
  end;
  if not Starttable then
  begin
    Log.Error('服务器不是停止状态, 无法启动');
  end;

end;

procedure TTcpServer.Stop(ExitThread: Boolean = False);
begin
  FLock.Enter;
  try
    Status := sStopping;
    FWaitEvent.SetEvent;
    FExitThread := ExitThread;
  finally
    FLock.Leave;
  end;
end;

procedure TTcpServer.WaitRun;
begin
  FWaitEvent.WaitFor(INFINITE);
end;

procedure TTcpServer.WaitStart;
var
  SockAddr: TSockAddr;
begin
  if FSocket = INVALID_SOCKET then
  begin
    FSocket := socket(AF_INET, SOCK_STREAM, 0);
    if FSocket <> INVALID_SOCKET then
    begin
      SockAddr.sin_family := AF_INET;
      SockAddr.sin_port := htons(FPort);
      SockAddr.sin_addr.S_addr := inet_addr(PAnsiChar(FIP));
      if bind(FSocket, SockAddr, SizeOf(SockAddr)) <> 0 then
      begin
        Log.Fatal(Format('Bind %s:%d failed.', [FIP, FPort]));
        Status := sStopped;
        closesocket(FSocket);
        FSocket := INVALID_SOCKET;
        Exit;
      end;
      if listen(FSocket, 10) <> 0 then
      begin
        LOG.Fatal(Format('Listen %s:%d failed.', [FIP, FPort]));
        FStatus := sStopped;
        closesocket(FSocket);
        FSocket := INVALID_SOCKET;
        Exit;
      end;
      Log.Info(Format('服务启动 %s:%d', [FIP, FPort]));
      Status := sRunning;
    end
    else
    begin
      Log.Info('Create server socket failed');
      Status := sStopped;
    end;

  end;

end;

procedure TTcpServer.WaitStop;
begin

end;

procedure TTcpServer.WaitStoping;
var
  i: Integer;
begin
  if FSocket <> INVALID_SOCKET then
  begin
    CloseSocket(FSocket);
    FSocket := INVALID_SOCKET;
  end;

  for i := 0 to FClients.Count - 1 do
  begin
    TTCPClient(FClients.Items[i]).Free;
  end;
  FClients.Clear;

  Status := sStopped;
  Log.Info('服务停止');
end;

procedure TTcpServer.Working;
var
  RFD, WFD, EFD: TFDSet;
  Timeout: TTimeVal;
  SelectResult, i: Integer;
  NeedCheckSockets: array of TSocket;
  CheckedCount: Integer;
  AClient: TTCPClient;
  PropTime: Integer;
begin
  SetLength(NeedCheckSockets, FClients.Count);
  for i := 0 to FClients.Count - 1 do
  begin
    NeedCheckSockets[i] := TTCPClient(FClients.Items[i]).FSocket;
  end;
  CheckedCount := 0;
  repeat
    FD_ZERO(RFD);
    FD_ZERO(WFD);
    FD_ZERO(EFD);
    FD_SET(FSocket, RFD);
    FD_SET(FSocket, WFD);
    FD_SET(FSocket, EFD);
    while (RFD.fd_count < FD_SETSIZE) and (CheckedCount < Length(NeedCheckSockets)) do
    begin
      FD_SET(NeedCheckSockets[CheckedCount], RFD);
      FD_SET(NeedCheckSockets[CheckedCount], WFD);
      FD_SET(NeedCheckSockets[CheckedCount], EFD);
      Inc(CheckedCount);
    end;
    Timeout.tv_sec := 0;
    Timeout.tv_usec := 100000;
    SelectResult := select(RFD.fd_count + 1, @RFD, @WFD, @EFD, @Timeout);
    if SelectResult > 0 then
    begin
      if FD_ISSET(FSocket, RFD) then
      begin
        DoAccept;
      end;

      for i := FClients.Count - 1 downto 0 do
      begin
        AClient := TTCPClient(FClients.Items[i]);
        if FD_ISSET(AClient.FSocket, RFD) then
        begin
          if not AClient.DoReadData then
          begin
            Log.Debug(Format('Client %s:%d socket : %d disconnected', [AClient.FHostAddress, AClient.FHostPort, AClient.FSocket]));
            FClients.Delete(i);
            ClientRemoved(AClient);
            AClient.Free;
            continue;
          end;
        end;
        if FD_ISSET(AClient.FSocket, WFD) then
        begin
          if not AClient.DoSendData then
          begin
            Log.Debug(Format('Client socket : %d disconnected', [AClient.FSocket]));
            FClients.Delete(i);
            ClientRemoved(AClient);
            AClient.Free;
            continue;
          end;
        end;
      end;
    end;
  until CheckedCount >= Length(NeedCheckSockets);
  for i := 0 to FClients.Count - 1 do
  begin
    ProcessClientIO(FClients.Items[i]);
  end;
  CheckBombTime;
  SetShoesProp;
end;




{ TTCPClient }

constructor TTCPClient.Create(ASocket: TSocket; RemoteIP: string; RemotePort: Word);
begin
  inherited Create;
  FReadBufSize := 64 * 1024;
  FSendBufSize := 64 * 1024;
  SetLength(FReadBuffer, FReadBufSize);
  SetLength(FSendBuffer, FSendBufSize);
  FSocket := ASocket;
  FHostAddress := RemoteIP;
  FHostPort := RemotePort;
end;

destructor TTCPClient.Destroy;
begin
  if FSocket <> INVALID_SOCKET then
    CloseSocket(FSocket);
  inherited;
end;

function TTCPClient.DoReadData: Boolean;
var
  RemainSize, ReadSize: Integer;
begin
  Result := True;
  RemainSize := FReadBufSize - FReadDataSize;
  if RemainSize > 0 then
  begin
    ReadSize := recv(FSocket, FReadBuffer[FReadDataSize], Min(256, RemainSize), 0);
    FReadDataSize := FReadDataSize + ReadSize;
    Result := (ReadSize > 0);
  end;

end;

function TTCPClient.DoSendData: Boolean;
var
  BufSize, WriteSize: Integer;
begin
  Result := True;
  if FSendDataSize > 0 then
  begin
    WriteSize := send(FSocket, FSendBuffer[0], Min(256, FSendDataSize), 0);
    Move(FSendBuffer[WriteSize], FSendBuffer[0], FSendDataSize - WriteSize);
    FSendDataSize := FSendDataSize - WriteSize;
    Result := (WriteSize > 0);
  end;
end;

procedure TTCPClient.LockReadBuffer(var BufPtr: PByte; var BufSize: Integer);
begin
  BufPtr := @FReadBuffer[0];
  BufSize := FReadDataSize;
end;

function TTCPClient.SendData(DataPtr: PByte; DataSize: Integer): Integer;
begin
  if (DataSize <= 0) or (DataSize > FSendBufSize - FSendDataSize) then
  begin
    Result := -1;
    Exit;
  end;

  System.Move(DataPtr^, FSendBuffer[FSendDataSize], DataSize);
  FSendDataSize := FSendDataSize + DataSize;
end;

procedure TTCPClient.UnLockReadBuffer(FetchSize: Integer);
begin
  if (FetchSize > FReadDataSize) or (FetchSize < 0) then
    raise Exception.Create('Fetch size error');
  Move(FReadBuffer[FetchSize], FReadBuffer[0], FetchSize);
  FReadDataSize := FReadDataSize - FetchSize;
end;

end.

