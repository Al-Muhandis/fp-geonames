unit geonames;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson;

type

  TLogMessageEvent = procedure(Sender: TObject; LogType: TEventType; const Msg: String) of object;
  TVerbosityStyle = (vsDefault, vsShort, vsMedium, vsLong, vsFull);

  { TGeoNamesParser }

  TGeoNamesParser = class
  private
    FGetParams: TStrings;
    FJSONResponse: TJSONObject;
    FFormatSettings: TFormatSettings;
    FOnLogMessage: TLogMessageEvent;
    FResponse: String;
    FRequestBody: String;
    FUserName: String;
    procedure DebugMessage(const Msg: String);
    procedure ErrorMessage(const Msg: String);
    function GetJSONResponse: TJSONObject;
    procedure InfoMessage(const Msg: String);
    function SendAPIMethod(const AMethod: String): Boolean;
    procedure SetGeoNameID(AValue: Cardinal);
    procedure SetLatitude(AValue: Double);
    procedure SetLongitude(AValue: Double);
    procedure SetRequestBody(AValue: String);
    procedure SetStyle(AValue: TVerbosityStyle);
    procedure SetUserName(AValue: String);
  public
    constructor Create;
    destructor Destroy; override;
    function findNearby(ALatitude, ALongitude: Double): Boolean;
    function findNearbyPlaceName(ALatitude, ALongitude: Double): Boolean;
    function get(AGeoNameID: Cardinal): Boolean;
    function timezone(ALatitude, ALongitude: Double): Boolean;
    property GeoNameID: Cardinal write SetGeoNameID;
    property JSONResponse: TJSONObject read GetJSONResponse;
    property Latitude: Double write SetLatitude;
    property Longitude: Double write SetLongitude;
    property OnLogMessage: TLogMessageEvent read FOnLogMessage write FOnLogMessage;
    property RequestBody: String read FRequestBody write SetRequestBody;
    property Response: String read FResponse;
    property Style: TVerbosityStyle write SetStyle;
    property UserName: String read FUserName write SetUserName;
  published

  end;

implementation

uses
  fphttpclient, jsonscanner, jsonparser;

const
  api_url = 'http://api.geonames.org/';
  VerbosityStyleStrings: array[TVerbosityStyle] of PChar = ('medium','short','medium','long','full');

{ TGeoNamesParser }


procedure TGeoNamesParser.DebugMessage(const Msg: String);
begin
  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, etDebug, Msg);
end;

procedure TGeoNamesParser.ErrorMessage(const Msg: String);
begin
  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, etError, Msg);
end;

function TGeoNamesParser.GetJSONResponse: TJSONObject;
var
  lParser: TJSONParser;
begin
  if not Assigned(FJSONResponse) then
  begin
    if FResponse<>EmptyStr then
    begin
      lParser := TJSONParser.Create(FResponse);
      try
        try
          FJSONResponse := lParser.Parse as TJSONObject;
        except
          FJSONResponse := nil;
        end;
      finally
        lParser.Free;
      end;
    end
  end;
  Result:=FJSONResponse;
end;

procedure TGeoNamesParser.InfoMessage(const Msg: String);
begin
  if Assigned(FOnLogMessage) then
    FOnLogMessage(Self, etInfo, Msg);
end;

function TGeoNamesParser.SendAPIMethod(const AMethod: String): Boolean;
var
  HTTP: TFPHTTPClient;
begin
  HTTP:=TFPHTTPClient.Create(nil);
  FGetParams.Values['username']:=FUserName;
  try
    try
  //    AParams;                                          url encode???
      FResponse:=HTTP.Get(API_URL+AMethod+'JSON'+'?'+FGetParams.DelimitedText);
      Result:=True;
    except
      Result:=False;
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TGeoNamesParser.SetGeoNameID(AValue: Cardinal);
begin
  FGetParams.Values['geonameId']:=IntToStr(AValue);
end;

procedure TGeoNamesParser.SetLatitude(AValue: Double);
begin
  FGetParams.Values['lat']:=FloatToStr(AValue, FFormatSettings);
end;

procedure TGeoNamesParser.SetLongitude(AValue: Double);
begin
  FGetParams.Values['lng']:=FloatToStr(AValue, FFormatSettings);
end;

procedure TGeoNamesParser.SetRequestBody(AValue: String);
begin
  if FRequestBody=AValue then Exit;
  FRequestBody:=AValue;
end;

procedure TGeoNamesParser.SetStyle(AValue: TVerbosityStyle);
begin
  FGetParams.Values['style']:=VerbosityStyleStrings[AValue]
end;

procedure TGeoNamesParser.SetUserName(AValue: String);
begin
  if FUserName=AValue then Exit;
  FUserName:=AValue;
end;

constructor TGeoNamesParser.Create;
begin
  inherited Create;
  FFormatSettings:=DefaultFormatSettings;
  FFormatSettings.DecimalSeparator:='.';
  FJSONResponse:=nil;
  FGetParams:=TStringList.Create;
  FGetParams.StrictDelimiter:=True;
  FGetParams.Delimiter:='&';
end;

destructor TGeoNamesParser.Destroy;
begin
  if Assigned(FJSONResponse) then
    FJSONResponse.Free;
  FGetParams.Free;
  inherited Destroy;
end;

// example http://api.geonames.org/findNearbyJSON?formatted=true&lat=48.865618158309374&lng=2.344207763671875&fclass=P&fcode=PPLA&fcode=PPL&fcode=PPLC&username=demo&style=full
function TGeoNamesParser.findNearby(ALatitude, ALongitude: Double): Boolean;
begin
  Latitude:=ALatitude;
  Longitude:=ALongitude;
  Result:=SendAPIMethod('findNearby');
end;

// example http://api.geonames.org/findNearbyPlaceNameJSON?formatted=true&lat=47.3&lng=9&username=demo&style=full
function TGeoNamesParser.findNearbyPlaceName(ALatitude, ALongitude: Double
  ): Boolean;
begin
  Latitude:=ALatitude;
  Longitude:=ALongitude;
  Result:=SendAPIMethod('findNearbyPlaceName');
end;

// http://api.geonames.org/getJSON?formatted=true&geonameId=6295630&username=demo&style=full
function TGeoNamesParser.get(AGeoNameID: Cardinal): Boolean;
begin
  GeoNameID:=AGeoNameID;
  Result:=SendAPIMethod('get');
end;

// http://api.geonames.org/timezoneJSON?formatted=true&lat=47.01&lng=10.2&username=demo&style=full
function TGeoNamesParser.timezone(ALatitude, ALongitude: Double): Boolean;
begin
  Latitude:=ALatitude;
  Longitude:=ALongitude;
  Result:=SendAPIMethod('timezone');
end;

end.

