unit TestGUnzip;

interface

uses
  TestFramework;

type
  TTestGUnzip = class(TTestCase)
  private
    function CompressFile: string;
    procedure CorruptGzip(const AFile: string);
  published
    procedure TestNormal;
    procedure TestCorrupted;
    procedure TestCharges;
    procedure TestCorruptedCharges;
  end;

implementation

uses
  SysUtils, Classes, Windows,
  System.ZLib;

{ TTestGUnzip }

procedure TTestGUnzip.CorruptGzip(const AFile: string);
var
  i: byte;
  LFile: TFileStream;
begin
  LFile := TFileStream.Create(AFile, fmOpenReadWrite);
  try
    LFile.Seek(-256, soFromEnd);
    for i := 0 to 255 do
      LFile.Write(i, SizeOf(Byte));
  finally
    FreeAndNil(LFile);
  end;
end;

procedure TTestGUnzip.TestCharges;
var
  LGZip: TZDecompressionStream;
  LDataStream: TStringStream;
  LFileStream: TFileStream;
  LFile: string;
begin
  LFile := CompressFile;
  LFileStream := TFileStream.Create(LFile, fmOpenRead);
  try
    LGZip := TZDecompressionStream.Create(LFileStream, 15 + 16);
    LDataStream := TStringStream.Create;
    LDataStream.CopyFrom(LGZip, 0);
    CheckEquals(57060, LDataStream.Size);
  finally
    FreeAndNil(LFileStream);
  end;
end;

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
  CheckEquals(32, HexToBin('1f8b0800ad5d9f5c0003f348cdc9c9d75128cf2fca490100c2a99aefedEFFF00', LMemoryStream.Memory, LMemoryStream.Size));
  StartExpectingException(EZDecompressionError);
  LGZip := TZDecompressionStream.Create(LMemoryStream, 15 + 16);
  LDataStream := TStringStream.Create;
  LDataStream.CopyFrom(LGZip, 0);
end;

procedure TTestGUnzip.TestCorruptedCharges;
var
  LGZip: TZDecompressionStream;
  LDataStream: TStringStream;
  LFileStream: TFileStream;
  LFile: string;
begin
  LFile := CompressFile;
  CorruptGZip(LFile);
  LFileStream := TFileStream.Create(LFile, fmOpenRead);
  try
    LGZip := TZDecompressionStream.Create(LFileStream, 15 + 16);
    LDataStream := TStringStream.Create;
    StartExpectingException(EZDecompressionError);
    LDataStream.CopyFrom(LGZip, 0);
  finally
   FreeAndNil(LFileStream);
  end;
end;

function TTestGUnzip.CompressFile: string;
var
  LResStream: TResourceStream;
  LCompressStream: TFileStream;
begin
  LResStream := TResourceStream.Create(HInstance, 'CHARGES', RT_RCDATA);
  try
    Result := ExpandFileName('Charges.gz');
    DeleteFile(PChar(Result));
    LCompressStream := TFileStream.Create(Result, fmOpenWrite or fmCreate);
    try
      with TZCompressionStream.Create(LCompressStream, TZCompressionLevel.zcMax, 15 or 16) do
        try
          CopyFrom(LResStream, 0);
        finally
          Free;
        end;
    finally
      FreeAndNil(LCompressStream);
    end;
  finally
    FreeAndNil(LResStream);
  end;
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
