unit LogServer;

interface

uses
  System.Classes, System.SyncObjs;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError, llFatal);

  TLogserver = class
  private
    FLogLevel: TLogLevel;
    FLogs: TStrings;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure Debug(LogMsg: AnsiString);
    procedure Info(LogMsg: AnsiString);
    procedure Warn(LogMsg: AnsiString);
    procedure Error(LogMsg: AnsiString);
    procedure Fatal(LogMsg: AnsiString);
    procedure LodingLog(Dest: Tstrings);
    function GetLogMsgLevel(LogMsg: AnsiString): TLogLevel;
  end;

var
  Log: TLogserver;

implementation

uses
  System.SysUtils;

const
  LOG_LEVEL_CHAR: array[TLogLevel] of AnsiChar = ('~', '-', '^', '!', '*');
{ TLogserver }

constructor TLogserver.Create;
begin
  FLogs := TStringList.Create;
  FLock := TCriticalSection.Create;
end;

procedure TLogserver.Debug(LogMsg: AnsiString);
var
  LogInfo: AnsiString;
begin
  LogInfo := LOG_LEVEL_CHAR[llDebug] + datetimetostr(now) + ' ' + LogMsg;
  FLock.Enter;
  try
    FLogs.Add(LogInfo);
  finally
    FLock.Leave;
  end;
end;

destructor TLogserver.Destroy;
begin
  FLock.Free;
  FreeAndNil(FLogs);
  inherited;
end;

procedure TLogserver.Error(LogMsg: AnsiString);
var
  LogInfo: AnsiString;
begin
  LogInfo := LOG_LEVEL_CHAR[llError] + datetimetostr(now) + ' ' + LogMsg;
  FLock.Enter;
  try
    FLogs.Add(LogInfo);
  finally
    FLock.Leave;
  end;
end;

procedure TLogserver.Fatal(LogMsg: AnsiString);
var
  LogInfo: AnsiString;
begin
  LogInfo := LOG_LEVEL_CHAR[llFatal] + datetimetostr(now) + ' ' + LogMsg;
  FLock.Enter;
  try
    FLogs.Add(LogInfo);
  finally
    FLock.Leave;
  end;
end;

function TLogserver.GetLogMsgLevel(LogMsg: AnsiString): TLogLevel;
var
  i: TLogLevel;
begin
  Result := llDebug;
  if Length(LogMsg) > 0 then
  begin
    for i := Low(LOG_LEVEL_CHAR) to High(LOG_LEVEL_CHAR) do
    begin
      if LogMsg[1] = LOG_LEVEL_CHAR[i] then
      begin
        Result := i;
        break;
      end;
    end;
  end;
end;

procedure TLogserver.Info(LogMsg: AnsiString);
var
  LogInfo: AnsiString;
begin
  if Ord(FLogLevel) <= Ord(llInfo) then
  begin
    LogInfo := LOG_LEVEL_CHAR[llInfo] + datetimetostr(now) + ' ' + LogMsg;
    FLock.Enter;
    try
      FLogs.Add(LogInfo);
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TLogserver.LodingLog(Dest: Tstrings);
begin
  FLock.Enter;
  try
    Dest.addstrings(FLogs);
    FLogs.Clear;
  finally
    FLock.Leave;
  end;
end;

procedure TLogserver.Warn(LogMsg: AnsiString);
var
  LogInfo: AnsiString;
begin
  LogInfo := LOG_LEVEL_CHAR[llwarn] + datetimetostr(now) + ' ' + LogMsg;
  FLock.Enter;
  try
    FLogs.Add(LogInfo);
  finally
    FLock.Leave;
  end;
end;

initialization
  Log := TLogserver.Create;

finalization
  FreeAndNil(Log);

end.

