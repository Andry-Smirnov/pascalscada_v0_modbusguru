unit dbstructurechecker;

interface

uses
  SysUtils, DB, Classes;

type

  TTableMetadata = class; // forward declaration.
  TDatabaseMetadata = class; // forward declaration.

  TDatabaseObjectState = (dosUnknown, dosChanged, dosDontExists, dosOK);
  TDatabaseNameKind = (dbkTableName, dbkFieldName, dbkIndexName); // must be improved;

  { TDatabaseObject }

  TDatabaseObject = class(TObject)
  protected
    FState: TDatabaseObjectState;
    FGenerateDDL: Boolean;
    function ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean; virtual;
    function GetCurrentState: TDatabaseObjectState; virtual;
    procedure ResetState; virtual;
    function GenerateDDL: Ansistring;
  end;

  // simple index declaration (for primary and unique keys)
  TIndex = class(TDatabaseObject)
  protected
    FTableOwner: TTableMetadata;
    FIndexName: Ansistring;
    FFields: TStringList;
    procedure AddFieldToIndex(FieldName: Ansistring); virtual;
    function GetFieldCount: Longint;
    function GetField(Index: Longint): Ansistring;
  public
    constructor Create(OwnerTable: TTableMetadata; IndexName: Ansistring);
    destructor Destroy; override;

    function GetCurrentState: TDatabaseObjectState; override;

    property IndexName: Ansistring read FIndexName;
    property FieldCount: Longint read GetFieldCount;
    property IndexField[Index: Longint]: Ansistring read GetField;
  end;

  TUniqueIndex = class(TIndex)
  public
    procedure AddFieldToIndex(FieldName: Ansistring); override;
  end;

  TUniqueIndexClass = class of TUniqueIndex;

  TPrimaryKeyIndex = class(TIndex)
  public
    procedure AddFieldToIndex(FieldName: Ansistring); override;
  end;

  TPrimaryKeyIndexClass = class of TPrimaryKeyIndex;

  TFieldLink = record
    SourceField: Ansistring;
    Field: Ansistring;
  end;

  TFieldLinks = array of TFieldLink;

  TForeignKeyRestriction = (fkrNoAction, fkrRestrict, fkrCascade);

  TForeignKey = class(TIndex)
  protected
    SourceTable: TTableMetadata;
    FieldLinks: TFieldLinks;
    FUpdateAction: TForeignKeyRestriction;
    FDeleteAction: TForeignKeyRestriction;
  public
    constructor Create(OwnerTable: TTableMetadata; AIndexName, ASourceTable: Ansistring; UpdateAction: TForeignKeyRestriction = fkrNoAction; DeleteAction: TForeignKeyRestriction = fkrNoAction);
    destructor Destroy; override;
    procedure AddFieldLink(SourceField, Field: Ansistring);
  end;

  TForeignKeyClass = class of TForeignKey;

  { TCollumnDefinition }

  TCollumnDefinition = class(TObject)
  private
    FFieldName: Ansistring;
    FFieldType: TFieldType;
    FNotNull: Boolean;
    FDefaultValue: Ansistring;
    FSize: Longint; //string size
    FOwnerTable: TTableMetadata;
  public
    constructor Create(OnwerTable: TTableMetadata; FieldName: Ansistring; FieldType: TFieldType; Size: Longint = -1; Nullable: Boolean = True; DefaultValue: Ansistring = '');
    destructor Destroy; override;
    property FieldName: Ansistring read FFieldName;
    property FieldType: TFieldType read FFieldType;
    property NotNull: Boolean read FNotNull write FNotNull;
    property DefaultValue: Ansistring read FDefaultValue;
    property Size: Longint read FSize;
  end;

  TCollumnDefinitionClass = class of TCollumnDefinition;

  { TTableMetadata }

  TTableMetadata = class(TDatabaseObject)
  private
    FFields: array of TCollumnDefinition;
    FOwnerDatabase: TDatabaseMetadata;
    FPK: TPrimaryKeyIndex;
    FTableName: Ansistring;
    FUniqueIndexes: array of TUniqueIndex;
  public
    constructor Create(OwnerDatabase: TDatabaseMetadata; TableName: Ansistring);
    destructor Destroy; override;
    function addCollumn(FieldName: Ansistring; FieldType: TFieldType; Size: Longint = -1; NotNull: Boolean = False; DefaultValue: Ansistring = ''): TCollumnDefinition;
    function addPrimaryKey(pkName: Ansistring): TPrimaryKeyIndex;
    function addUniqueIndex(UniqueName: Ansistring): TUniqueIndex;
    function addForeignKey(IndexName, SourceTable: Ansistring; UpdateAction: TForeignKeyRestriction = fkrNoAction; DeleteAction: TForeignKeyRestriction = fkrNoAction): TForeignKey;
  public
    function ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean; override;
    function FieldExists(FieldName: Ansistring; var Field: TCollumnDefinition): Boolean;
    function GetCurrentState: TDatabaseObjectState; override;
    procedure ResetState; override;
    property TableName: Ansistring read FTableName;
    property OwnerDatabase: TDatabaseMetadata read FOwnerDatabase;
  end;

  TTableMetadataClass = class of TTableMetadata;

  { TDatabaseMetadata }

  TDatabaseMetadata = class(TDatabaseObject)
  protected
    FTables: TList;
    FTableMetadataClass: TTableMetadataClass;
  public
    constructor Create; virtual;
    function ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean; override;
    destructor Destroy; override;
    function AddTable(TableName: Ansistring): TTableMetadata;
    procedure DeleteTable(TableName: Ansistring);
    function FindTableDef(TableName: Ansistring; var Index: Longint): TTableMetadata; overload;
    function GetCurrentState: TDatabaseObjectState; override;
    procedure ResetState; override;
  end;

function SortTableList(Item1, Item2: Pointer): Longint;


implementation


{ TDatabaseMetadata }

constructor TDatabaseMetadata.Create;
begin
  FTableMetadataClass := TTableMetadata;
end;

function TDatabaseMetadata.ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean;
begin
  Result := True;
end;

destructor TDatabaseMetadata.Destroy;
var
  i: Longint;
begin
  inherited Destroy;
  //starts from the end
  for i := FTables.Count - 1 downto 0 do
  begin
    TTableMetadata(FTables[i]).Destroy;
    FTables.Delete(i);
  end;
  FTables.Destroy;
end;

function TDatabaseMetadata.AddTable(TableName: Ansistring): TTableMetadata;
var
  TableDef: TTableMetadata;
  i: Longint;
begin
  TableDef := FindTableDef(TableName, i);
  Result := nil;
  if TableDef = nil then
  begin
    TableDef := FTableMetadataClass.Create(Self, TableName);
    FTables.Add(TableDef);
    Result := TableDef;
    FTables.Sort(@SortTableList);
  end
  else
    raise Exception.Create('Tabela já existe no metadados.');
end;

procedure TDatabaseMetadata.DeleteTable(TableName: Ansistring);
var
  TableDef: TTableMetadata;
  i: Longint;
begin
  TableDef := FindTableDef(TableName, i);

  if TableDef = nil then
    Exit;

  TableDef.Destroy;
  FTables.Delete(i);
end;

function TDatabaseMetadata.FindTableDef(TableName: Ansistring; var Index: Longint): TTableMetadata;
var
  i: Longint;
begin
  Index := -1;
  Result := nil;
  //binary search here?
  for i := 0 to FTables.Count - 1 do
  begin
    if TTableMetadata(FTables.Items[i]).TableName = TableName then
    begin
      Result := TTableMetadata(FTables.Items[i]);
      Index := i;
      Exit;
    end;
  end;
end;

function TDatabaseMetadata.GetCurrentState: TDatabaseObjectState;
var
  i: Longint;
begin
  Result := dosOK;
  for i := 0 to FTables.Count - 1 do
    case TTableMetadata(FTables[i]).GetCurrentState of
      dosUnknown: raise Exception.Create('Resposta inesperada!');
      dosChanged,
      dosDontExists:  begin
                        Result := dosChanged;
                        Break;
                      end;
      dosOK: Continue;
    end;

end;

procedure TDatabaseMetadata.ResetState;
var
  i: Longint;
begin
  inherited ResetState;
  for i := 0 to FTables.Count - 1 do
  begin
    TTableMetadata(FTables[i]).ResetState;
  end;
end;

{ TCollumnDefinition }

constructor TCollumnDefinition.Create(OnwerTable: TTableMetadata; FieldName: Ansistring; FieldType: TFieldType; Size: Longint; Nullable: Boolean; DefaultValue: Ansistring);
begin

end;

destructor TCollumnDefinition.Destroy;
begin
  inherited Destroy;
end;

{ TDatabaseObject }

function TDatabaseObject.ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean;
begin
  Result := True;
end;

function TDatabaseObject.GetCurrentState: TDatabaseObjectState;
begin
  Result := dosUnknown;
end;

procedure TDatabaseObject.ResetState;
begin
  FState := dosUnknown;
end;

function TDatabaseObject.GenerateDDL: Ansistring;
begin
  Result := '';
end;

{ TTableMetadata }

constructor TTableMetadata.Create(OwnerDatabase: TDatabaseMetadata; TableName: Ansistring);
begin
  inherited Create;
  if (OwnerDatabase = nil) then
    raise Exception.Create('Invalid database');

  if (not OwnerDatabase.ValidateName(TableName, dbkTableName)) then
    raise Exception.Create('Invalid table name');

  FTableName := TableName;
  FOwnerDatabase := OwnerDatabase;
end;

destructor TTableMetadata.Destroy;
begin
  inherited Destroy;
end;

function TTableMetadata.addCollumn(FieldName: Ansistring; FieldType: TFieldType; Size: Longint; NotNull: Boolean; DefaultValue: Ansistring): TCollumnDefinition;
begin

end;

function TTableMetadata.addPrimaryKey(pkName: Ansistring): TPrimaryKeyIndex;
begin

end;

function TTableMetadata.addUniqueIndex(UniqueName: Ansistring): TUniqueIndex;
begin

end;

function TTableMetadata.addForeignKey(IndexName, SourceTable: Ansistring; UpdateAction: TForeignKeyRestriction; DeleteAction: TForeignKeyRestriction): TForeignKey;
begin

end;

function TTableMetadata.ValidateName(Name: Ansistring; NameKind: TDatabaseNameKind): Boolean;
begin
  if FOwnerDatabase <> nil then
    Result := FOwnerDatabase.ValidateName(Name, NameKind)
  else
    raise Exception.Create('Invalid Database');
end;

function TTableMetadata.FieldExists(FieldName: Ansistring; var Field: TCollumnDefinition): Boolean;
begin

end;

function TTableMetadata.GetCurrentState: TDatabaseObjectState;
begin
  Result := inherited GetCurrentState;
end;

procedure TTableMetadata.ResetState;
begin
  inherited ResetState;
end;

constructor TIndex.Create(OwnerTable: TTableMetadata; IndexName: Ansistring);
begin
  //TODO: must validate the index name first with the database driver.
  //TODO: must check if the name of the index don't already exists on schema.
  inherited Create;

  //check if index name is valid.
  if not OwnerTable.ValidateName(IndexName, dbkIndexName) then
    raise Exception.Create('Invalid index name');

  FTableOwner := OwnerTable;
  FIndexName := IndexName;
  FFields := TStringList.Create;
end;

destructor TIndex.Destroy;
begin
  FFields.Destroy;
  inherited Destroy;
end;

procedure TIndex.AddFieldToIndex(FieldName: Ansistring);
var
  AField: TCollumnDefinition;
  Found: Boolean;
  i: Longint;
begin
  if (FTableOwner = nil) or (not FTableOwner.FieldExists(FieldName, AField)) then
    raise Exception.Create('The field does not exist in the table');

  Found := False;
  for i := 0 to FFields.Count - 1 do
    if FFields.Strings[i] = lowercase(FieldName) then
    begin
      Found := True;
      Break;
    end;

  if Found then
    raise Exception.Create('The field already exists in the index');

  FFields.Add(lowercase(FieldName));
end;

function TIndex.GetFieldCount: Longint;
begin
  Result := FFields.Count;
end;

function TIndex.GetField(Index: Longint): Ansistring;
begin
  if (Index < 0) or (Index >= FFields.Count) then
    raise Exception.Create('Out of bounds');

  Result := FFields[Index];
end;

function TIndex.GetCurrentState: TDatabaseObjectState;
begin
  Result := dosUnknown; //TODO: must check itself with database driver.
end;

////////////////////////////////////////////////////////////////////////////////

procedure TUniqueIndex.AddFieldToIndex(FieldName: Ansistring);
begin
  inherited AddFieldToIndex(FieldName);
end;

////////////////////////////////////////////////////////////////////////////////

procedure TPrimaryKeyIndex.AddFieldToIndex(FieldName: Ansistring);
var
  AField: TCollumnDefinition;
begin
  inherited AddFieldToIndex(FieldName);
  if FTableOwner.FieldExists(FieldName, AField) then
    AField.NotNull := True;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TForeignKey.Create(OwnerTable: TTableMetadata; AIndexName, ASourceTable: Ansistring; UpdateAction: TForeignKeyRestriction = fkrNoAction; DeleteAction: TForeignKeyRestriction = fkrNoAction);
begin
  inherited Create(OwnerTable, IndexName);
  FDeleteAction := DeleteAction;
  FUpdateAction := UpdateAction;
  //must find the source table by their name.
end;

destructor TForeignKey.Destroy;
begin
  inherited Destroy;
end;

procedure TForeignKey.AddFieldLink(SourceField, Field: Ansistring);
begin

end;

function SortTableList(Item1, Item2: Pointer): Longint;
begin
  if TTableMetadata(Item1).TableName = TTableMetadata(Item2).TableName then
    Result := 0
  else
  begin
    if TTableMetadata(Item1).TableName < TTableMetadata(Item2).TableName then
      Result := -1
    else
      Result := 1;
  end;
end;

end.
