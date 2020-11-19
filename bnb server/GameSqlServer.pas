unit GameSqlServer;

interface

uses
  System.Classes, System.SysUtils, System.SyncObjs, Data.DB, ZAbstractRODataset,
  ZAbstractDataset, ZDataset, ZAbstractConnection, ZConnection, System.TypInfo,
  LogServer;

type
  SQLType = (INSERT, DELETE, UPDATE, SELECT);

type
  TSQLserver = class
    ZConnection: TZConnection;
    ZQuery: TZQuery;
  private
    FLock: TCriticalSection;
    RetStatus: Boolean;
    FSqlOrd: AnsiString;
    function ReadSQL: Boolean;
    function WriteSQL: Boolean;
    function Instersql: Boolean;
    function DeleteSql: Boolean;
    function UpdateSql: Boolean;
    function SelectSql: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function SetSqlList(sql: AnsiString): Boolean;
  end;

var
  SQLserver: TSQLserver;

implementation

{ TSQLserver }

constructor TSQLserver.Create;
begin
  FLock := TCriticalSection.Create;
  ZConnection := TZConnection.Create(ZConnection);
  ZQuery := TZQuery.Create(ZQuery);
  ZConnection.User := 'root';
  ZConnection.Password := '123456';
  ZConnection.Database := 'test';
  ZConnection.Protocol := 'mysql';
  ZConnection.HostName := '127.0.0.1';
//  ZConnection.LibraryLocation := 'C:\Users\haoshengli\Desktop\libmysql.dll';
  ZConnection.Name := 'ZConnection';
  ZConnection.Connect;
  ZQuery.Connection := ZConnection;
  log.Info('数据库服务启动');
end;

function TSQLserver.DeleteSql: Boolean;
begin

end;

destructor TSQLserver.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TSQLserver.Instersql: Boolean;
begin
  if WriteSQL then
    Result := True
  else
    Result := False;
end;

function TSQLserver.ReadSQL: Boolean;
var
  SqlString: AnsiString;
begin
  if Length(FSqlOrd) <> 0 then
  begin
    SqlString := FSqlOrd;
  end;
  ZQuery.Close;
  ZQuery.SQL.Text := SqlString;
  ZQuery.Open;
  if ZQuery.RecordCount >= 1 then
  begin
    Result := True; //数据库中存在数据
  end
  else
  begin
    Result := False;
  end;

end;

function TSQLserver.SelectSql: Boolean;
var
  signal: Boolean;
begin
  signal := ReadSQL;
  Result := signal;
end;

function TSQLserver.SetSqlList(sql: AnsiString): Boolean;
var
  OperatorStr: string;
  OperatorType: SQLType;
begin
  FLock.Enter;
  try
    FSqlOrd := sql;
  finally
    FLock.Leave;
  end;
  OperatorStr := Copy(FSqlOrd, 0, (Pos(' ', FSqlOrd)) - 1);
  if System.SysUtils.CompareStr(OperatorStr, 'INSERT') = 0 then
  begin
    Result := Instersql();
  end
  else if System.SysUtils.CompareStr(OperatorStr, 'DELETE') = 0 then
  begin
    Result := DeleteSql();
  end
  else if System.SysUtils.CompareStr(OperatorStr, 'UPDATE') = 0 then
  begin
    Result := UpdateSql();
  end
  else if System.SysUtils.CompareStr(OperatorStr, 'SELECT') = 0 then
  begin
    Result := SelectSql();
  end;

end;

function TSQLserver.UpdateSql: Boolean;
begin

end;

function TSQLserver.WriteSQL: Boolean;
var
  SqlString: AnsiString;
begin
  if Length(FSqlOrd) <> 0 then
  begin
    SqlString := FSqlOrd;
  end;
  ZQuery.Close;
  ZQuery.SQL.Text := SqlString;
  ZQuery.ExecSQL;
  if ZQuery.RowsAffected <> 0 then
  begin
    Result := True;
  end
  else
  begin
    Result := False;
  end;
end;

initialization
  SQLserver := TSQLserver.Create;

finalization
  SQLserver.Free;

end.

