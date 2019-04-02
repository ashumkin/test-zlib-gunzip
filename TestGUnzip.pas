unit TestGUnzip;

interface

uses
  Classes,
  System.ZLib,
  TestFramework;

type
  TTestGUnzip = class(TTestCase)
  private
    FMemoryStream: TMemoryStream;
    FDataStream: TStringStream;
    FGZip: TZDecompressionStream;
    function CompressFile: string;
    procedure CorruptGzip(const AFile: string);
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestNormal;
    procedure TestCorrupted;
    procedure TestCharges;
    procedure TestCorruptedCharges;
  end;

implementation

uses
  SysUtils, Windows;

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

procedure TTestGUnzip.SetUp;
begin
  inherited;
  FMemoryStream := TMemoryStream.Create;
  FDataStream := TStringStream.Create;;
  FGZip := nil;
end;

procedure TTestGUnzip.TearDown;
begin
  FreeAndNil(FMemoryStream);
  FreeAndNil(FDataStream);
  FreeAndNil(FGZip);
  inherited;
end;

procedure TTestGUnzip.TestCharges;
var
  LFileStream: TFileStream;
  LFile: string;
begin
  LFile := CompressFile;
  LFileStream := TFileStream.Create(LFile, fmOpenRead);
  try
    FGZip := TZDecompressionStream.Create(LFileStream, 15 + 16);
    FDataStream.CopyFrom(FGZip, 0);
    CheckEquals(57060, FDataStream.Size);
  finally
    FreeAndNil(LFileStream);
  end;
end;

procedure TTestGUnzip.TestCorrupted;
begin
  // this is a
  // $ echo -n Hello, world | gzip -f | xxd -ps -c 40
  FMemoryStream.Size := 32;
  CheckEquals(32, HexToBin('1f8b0800ad5d9f5c0003f348cdc9c9d75128cf2fca490100c2a99aefedEFFF00', FMemoryStream.Memory, FMemoryStream.Size));
  StartExpectingException(EZDecompressionError);
  FGZip := TZDecompressionStream.Create(FMemoryStream, 15 + 16);
  FDataStream.CopyFrom(FGZip, 0);
end;

procedure TTestGUnzip.TestCorruptedCharges;
var
  LFileStream: TFileStream;
  LFile: string;
begin
  LFile := CompressFile;
  CorruptGZip(LFile);
  LFileStream := TFileStream.Create(LFile, fmOpenRead);
  try
    FGZip := TZDecompressionStream.Create(LFileStream, 15 + 16);
    StartExpectingException(EZDecompressionError);
    FDataStream.CopyFrom(FGZip, 0);
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
begin
  // this is a
  // $ echo -n Hello, world | gzip -f | xxd -ps -c 40
  FMemoryStream.Size := 32;
  CheckEquals(32, HexToBin('1f8b0800ad5d9f5c0003f348cdc9c9d75128cf2fca490100c2a99ae70c000000', FMemoryStream.Memory, FMemoryStream.Size));
  FGZip := TZDecompressionStream.Create(FMemoryStream, 15 + 16);
  FDataStream.CopyFrom(FGZip, 0);
  CheckEquals('Hello, world', FDataStream.DataString);
end;

initialization
  RegisterTest(TTestGUnzip.Suite);
end.
