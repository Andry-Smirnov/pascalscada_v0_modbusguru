unit psbufdataset;

interface

uses
  DB, Classes
  {$IFDEF FPC}
, BufDataset
  {$ELSE}
  , fpsbufdataset
  {$ENDIF}
  ;

type

  { TFPSBufDataSet }

  TFPSBufDataSet = class(TBufDataset)
  public
    {$IFNDEF FPC}
    procedure CopyFromDataset(DataSet: TDataSet; CopyData: Boolean = True);
    {$ENDIF}
  end;

implementation


{$IFNDEF FPC}
{ TFPSBufDataSet }

procedure TFPSBufDataSet.CopyFromDataset(DataSet: TDataSet; CopyData: Boolean = True);
var
  I: Longint;
  F, F1, F2: TField;
  L1, L2: TList;
  N: string;
begin
  //Clear(True);
  // NOT from fielddefs. The data may not be available in buffers !!
  for I := 0 to DataSet.FieldCount - 1 do
  begin
    F := DataSet.Fields[I];
    TFieldDef.Create(FieldDefs, F.FieldName, F.DataType, F.Size, F.Required, F.FieldNo);
  end;
  CreateDataset;
  if CopyData then
  begin
    Open;
    L1 := TList.Create;
    try
      L2 := TList.Create;
      try
        for I := 0 to FieldDefs.Count - 1 do
        begin
          N := FieldDefs[I].Name;
          F1 := FieldByName(N);
          F2 := DataSet.FieldByName(N);
          L1.Add(F1);
          L2.Add(F2);
        end;
        DataSet.DisableControls;
        try
          DataSet.Open;
          while not DataSet.EOF do
          begin
            Append;
            for I := 0 to L1.Count - 1 do
            begin
              F1 := TField(L1[I]);
              F2 := TField(L2[I]);
              case F1.DataType of
                ftString: F1.AsString := F2.AsString;
                ftWideString: F1.AsWideString := F2.AsWideString;
                ftBoolean: F1.AsBoolean := F2.AsBoolean;
                ftFloat: F1.AsFloat := F2.AsFloat;
                ftLargeInt: F1.AsInteger := F2.AsInteger;
                ftSmallInt: F1.AsInteger := F2.AsInteger;
                ftInteger: F1.AsInteger := F2.AsInteger;
                ftDate: F1.AsDateTime := F2.AsDateTime;
                ftTime: F1.AsDateTime := F2.AsDateTime;
                ftDateTime: F1.AsDateTime := F2.AsDateTime;
              end;
            end;
            try
              Post;
            except
              Cancel;
              raise;
            end;
            DataSet.Next;
          end;
        finally
          DataSet.EnableControls;
        end;
      finally
        L2.Free;
      end;
    finally
      L1.Free;
    end;
  end;
end;
{$ENDIF}

end.
