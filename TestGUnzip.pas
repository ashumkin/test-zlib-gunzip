unit TestGUnzip;

interface

uses
  TestFramework;

type
  TTestGUnzip = class(TTestCase)
  published
    procedure TestNormal;
    procedure TestCorrupted;
  end;

implementation

uses
  SysUtils, Classes,
  System.ZLib;

{ TTestGUnzip }

procedure TTestGUnzip.TestCorrupted;
var
  LMemoryStream: TMemoryStream;
  LGZip: TZDecompressionStream;
  LDataStream: TStringStream;
begin
  // this is a
  // $ echo -n Hello, world | gzip -f | xxd -ps -c 40
  LMemoryStream := TMemoryStream.Create;
  LMemoryStream.Size := 32;
  CheckEquals(32, HexToBin('1f8b0800ad5d9f5c0003f348cdc9c9d75128cf2fca490100c2a99aefedcbabca', LMemoryStream.Memory, LMemoryStream.Size));
  StartExpectingException(EZDecompressionError);
  LGZip := TZDecompressionStream.Create(LMemoryStream, 15 + 16);
  LDataStream := TStringStream.Create;
  LDataStream.CopyFrom(LGZip, 0);
end;

procedure TTestGUnzip.TestNormal;
var
  LMemoryStream: TMemoryStream;
  LGZip: TZDecompressionStream;
  LDataStream: TStringStream;
begin
  // this is a
  // $ echo -n Hello, world | gzip -f | xxd -ps -c 40
  LMemoryStream := TMemoryStream.Create;
  LMemoryStream.Size := 32;
  CheckEquals(32, HexToBin('1f8b0800ad5d9f5c0003f348cdc9c9d75128cf2fca490100c2a99ae70c000000', LMemoryStream.Memory, LMemoryStream.Size));
  LGZip := TZDecompressionStream.Create(LMemoryStream, 15 + 16);
  LDataStream := TStringStream.Create;
  LDataStream.CopyFrom(LGZip, 0);
  CheckEquals('Hello, world', LDataStream.DataString);
end;

initialization
  RegisterTest(TTestGUnzip.Suite);
end.
