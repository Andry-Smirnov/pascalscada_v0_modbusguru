{$i ../common/language.inc}
{$IFDEF PORTUGUES}
{:
@abstract(Unit de coleções de zonas gráficas e de texto.)
@author(Fabio Luis Girardi)
}
{$ELSE}
{:
@abstract(Unit that implements graphic and text zone collections.)
@author(Fabio Luis Girardi)
}
{$ENDIF}
unit HMIZones;

interface

uses
  Classes, SysUtils, hsutils, Controls, Graphics, hmibasiccolletion
  {$IFNDEF FPC}
  , StdCtrls
  {$ENDIF}
  ;

type
  {$IFDEF PORTUGUES}
  {:
  Define a condição de seleção de uma zona.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Defines the condition of selection of an zone.
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TZoneTypes = (ztEqual, ztRange, ztBit, ztNotEqual, ztOutOfRange, ztGreaterThan, ztLessThan);

  {$IFDEF PORTUGUES}
  {:
  @name é classe que implementa a base de uma zona. Estas zonas são selecionadas
  atraves do valor do tag associado ao objeto dono do conjunto de zonas aplicado
  a expressão de seleção da zona.
  @seealso(TZones)
  @seealso(TZoneTypes)
  }
  {$ELSE}
  {:
  @name is the base class of an animation zone. This zones are selected depending
  of the value of the linked tag and of their select condition.
  @seealso(TZones)
  @seealso(TZoneTypes)
  }
  {$ENDIF}
  TZone = class(THMIBasicColletionItem)
  private
    FValue1: Double;
    FValue2: Double;
    FIncludeV1: Boolean;
    FIncludeV2: Boolean;
    FDefaultZone: Boolean;
    FZoneType: TZoneTypes;

    procedure SetV1(v: Double);
    procedure SetV2(v: Double);
    procedure SetIncV1(v: Boolean);
    procedure SetIncV2(v: Boolean);
    procedure SetAsDefaultZone(v: Boolean);
    procedure SetZoneType(AZoneTypes: TZoneTypes);

  protected
    {: @exclude }
    function GetDisplayName: Ansistring; override;

    {$IFDEF PORTUGUES}
     {:
     Se @true torna a zona padrão, exibindo-a quando nenhuma zona for selecionada
     em função do valor do tag.
     @seealso(ZoneType)
     }
    {$ELSE}
     {:
     If @true makes the zone default, showing it when no animation zone is
     selected depending of the tag value.
     @seealso(ZoneType)
     }
    {$ENDIF}
    property DefaultZone: Boolean read FDefaultZone write SetAsDefaultZone;
  public
    procedure AssignTo(Dest: TPersistent); override;
  published
    {$IFDEF PORTUGUES}
     {:
     Valor principal.
     @seealso(ZoneType)
     }
    {$ELSE}
     {:
     Main value.
     @seealso(ZoneType)
     }
    {$ENDIF}
    property Value1: Double read FValue1 write SetV1;

    {$IFDEF PORTUGUES}
     {:
     Valor secundário.
     @seealso(ZoneType)
     }
    {$ELSE}
     {:
     Secundary value.
     @seealso(ZoneType)
     }
    {$ENDIF}
    property Value2: Double read FValue2 write SetV2;

    {$IFDEF PORTUGUES}
     {:
     Flag auxiliar da proprieade Value1. Altera o critério de seleção.
     @seealso(ZoneType)
     }
    {$ELSE}
     {:
     Auxiliar flag of Value1 property. Changes the selection criteria.
     @seealso(ZoneType)
     }
    {$ENDIF}
    property IncludeValue1: Boolean read FIncludeV1 write SetIncV1;

    {$IFDEF PORTUGUES}
     {:
     Flag auxiliar da proprieade Value2. Altera o critério de seleção.
     @seealso(ZoneType)
     }
    {$ELSE}
     {:
     Auxiliar flag of Value2 property. Changes the selection criteria.
     @seealso(ZoneType)
     }
    {$ENDIF}
    property IncludeValue2: Boolean read FIncludeV2 write SetIncV2;

    {$IFDEF PORTUGUES}
     {:
     @name define qual vai ser a condição que vai selecionar ou descartar a zona
     em questão.

     Seus possíveis valores são:

     @bold(ztEqual:)       O valor do @noAutoLink(Tag) tem que ser igual ao valor
                           da propriedade Value1 da zona para ela ser selecionada.

     @bold(ztRange:)       O valor do @noAutoLink(Tag) tem que estar entre os
                           valores das propriedades Value1 e Value2 (maior que
                           Value1 E menor que Value2) da zona para ela ser
                           selecionada. Value1 é o limite inferior e Value2 é o
                           limite superior. Para incluir Value1 ou Value2  (maior
                           ou igual que Value1 E menor ou igual que Value2) use
                           as propriedades IncludeValue1 e IncludeValue2.

     @bold(ztBit:)         Para a zona ser selecionada, o bit Valor1 da palavra
                           formada pelo @noAutoLink(tag) tem que ter seu valor
                           booleano igual ao da propriedade IncludeValue1.

     @bold(ztNotEqual:)    Para a zona ser selecionada, o valor do @noAutoLink(tag)
                           tem que ser diferente do valor presente na propriedade
                           Value1.

     @bold(ztOutOfRange:)  O valor do @noAutoLink(Tag) não pode estar entre os
                           valores das propriedades Value1 e Value2 (menor que
                           Value1 OU maior que Value2) da zona para ela ser
                           selecionada. Value1 é o limite inferior e Value2 é o
                           limite superior da exclusão do range. Para incluir
                           Value1 ou Value2 (menor ou igual que Value1 OU
                           maior ou igual que Value2) use as propriedades
                           IncludeValue1 e IncludeValue2.

     @bold(ztGreaterThan:) Para a zona ser selecionada, o valor do @noAutoLink(tag)
                           tem que ser maior que o valor da propriedade Value1.
                           Para incluir o valor de Value1 na condição (maior ou
                           igual que) coloque o valor @true IncludeValue1.

     @bold(ztLessThan:)    Para a zona ser selecionada, o valor do @noAutoLink(tag)
                           tem que ser menor que o valor da propriedade Value1.
                           Para incluir o valor de Value1 na condição (menor ou
                           igual que) coloque o valor @true IncludeValue1.

     @seealso(Value1)
     @seealso(Value2)
     @seealso(IncludeValue1)
     @seealso(IncludeValue2)
     @seealso(TZoneTypes)
     @seealso(DefaultZone)
     }
    {$ELSE}
     {:
     @name defines what's the selection condition that will show or not the
     animation zone.

     Their values can be:

     @bold(ztEqual:)       The @noAutoLink(Tag) value must be equal to the
                           Value1 property to show the animation zone.

     @bold(ztRange:)       The @noAutoLink(Tag) value must be between the values
                           of Value1 and Value2 (greater than Value1 AND less
                           than Value2) to show the animation zone. To include
                           the Value1 or Value2 (greater or equal than Value1
                           AND less or equal than Value2) use the properties
                           IncludeValue1 and IncludeValue2.

     @bold(ztBit:)         To select the animation zone with this configuration,
                           the bit number Valor1 of the @noAutoLink(tag) value
                           must be equal of the value of IncludeValue1 property.

     @bold(ztNotEqual:)    To select the animation zone, the @noAutoLink(Tag)
                           value must be different of the Value1 property.

     @bold(ztOutOfRange:)  The value of @noAutoLink(Tag) must be out of the range
                           made by Value1 and Value2 properties (it must be
                           less than Value1 OR greater than Value2 property) to
                           select the animation zone. To Include the Value1 or
                           Value2 (less or equal than Value1 OR greater or equal
                           than Value2 property) use the properties
                           IncludeValue1 and IncludeValue2.

     @bold(ztGreaterThan:) To select the animation zone, the @noAutoLink(tag)
                           value must be greater than Value1 property. To include
                           the Value1, set @true in IncludeValue1 (greater or
                           equal than Value1 property).

     @bold(ztLessThan:)    To select the animation zone, the @noAutoLink(tag)
                           value must be less than Value1 property. To include
                           the Value1, set @true in IncludeValue1 (less or
                           equal than Value1 property).

     @seealso(Value1)
     @seealso(Value2)
     @seealso(IncludeValue1)
     @seealso(IncludeValue2)
     @seealso(TZoneTypes)
     @seealso(DefaultZone)
     }
    {$ENDIF}
    property ZoneType: TZoneTypes read FZoneType write SetZoneType;
  end;

  { TAnimationZone }

  TAnimationZone = class(TZone)
  private
    FBlinkTime: Cardinal;
    FBlinkWith: TAnimationZone;
    FBlinkWithIndex: Longint;
    FReferencedBy: array of TAnimationZone;
    function GetBlinkWithZoneNumber: Longint;
    procedure SetBlinkWithZoneNumber(v: Longint);
    procedure SetBlinkTime(v: Cardinal);
    procedure RemoveBlinkZone;
    procedure AddReference(RefBy: TAnimationZone);
    procedure RemReference(RefBy: TAnimationZone);
  protected
    procedure Loaded; override;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure AssignTo(Dest: TPersistent); override;
  published
    {$IFDEF PORTUGUES}
     {:
     @name informa o tempo em milisegundos que a zona ficara visivel. Após esse
     tempo chama a próxima zona definida por BlinkWith.
     @seealso(BlinkWith)
     @seealso(TZone.DefaultZone)
     }
    {$ELSE}
     {:
     @name is the time in milliseconds that the animation zone will stay visible.
     After this time, shows the next zone (defined by the BlinkWith property).
     @seealso(BlinkWith)
     @seealso(TZone.DefaultZone)
     }
    {$ENDIF}
    property BlinkTime: Cardinal read FBlinkTime write SetBlinkTime;

    {$IFDEF PORTUGUES}
     {:
     @name informa qual será a próxima zona a ser chamada para gerar o efeito de
     pisca/animação após o tempo de exibição da zona.
     @seealso(BlinkTime)
     }
    {$ELSE}
     {:
     @name is the next zone to be shown to do a blink effect/animation after
     BlinkTime milliseconds of the current animation zone.
     @seealso(BlinkTime)
     }
    {$ENDIF}
    property BlinkWith: Longint read GetBlinkWithZoneNumber write SetBlinkWithZoneNumber nodefault;

    property DefaultZone;
  end;


  {$IFDEF PORTUGUES}
  {:
  @name implementa a classe base para uma coleção de zonas.
  @seealso(TZone)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  @name is the base class of a collection of animation zones.
  @seealso(TZone)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TZones = class(THMIBasicColletion)
  public
    //: @exclude
    constructor Create(AOwner: TPersistent; AItemClass: TCollectionItemClass); override;

    {$IFDEF PORTUGUES}
     {:
     @name retorna uma zona em função do valor e dos critérios das zonas
     pertencentes a coleção.
     @param(v Double. Valor numérico a passar pelos critérios de seleção das
            zonas.)

     @return(@name retorna a primeira zona que tenha seu critério de seleção
             satisfeito, ou caso não tenha nenhuma zona escolhida, traz a zona
             marcada como padrão. Se não for escolhida nenhuma zona e não há
             nenhuma zona padrão retorna @nil).
     }
    {$ELSE}
     {:
     @name returns the selected animation zone, depending of select criteria of
     each animation zone.

     @param(v Double. Number that will be used to select a animation zone.)

     @return(@name returns the first animation zone that their criteria match,
     or if no zone was selected, returns the animation zone setted as default.
     If has no animation zone set as default, returns @nil).
     }
    {$ENDIF}
    function GetZoneFromValue(v: Double): TZone; virtual;

    function GetDefaultZone: TZone;
  end;

  {$IFDEF PORTUGUES}
  {:
  Implementa uma zona de texto com várias opções de formatação.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TTextZones)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ELSE}
  {:
  Class of a Text animation zone.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TTextZones)
  @author(Fabio Luis Girardi <fabio@pascalscada.com>)
  }
  {$ENDIF}
  TTextZone = class(TAnimationZone)
  private
    FText: TCaption;
    FColor: TColor;
    FTransparent: Boolean;
    FFont: TFont;
    FHorAlignment: TAlignment;
    FVerAlignment: TTextLayout;

    procedure FontChanges(Sender: TObject);
    procedure SetText(t: TCaption);
    procedure SetColor(c: TColor);
    procedure SetTransparent(b: Boolean);
    procedure SetFont(f: TFont);
    procedure SetHorAlignment(x: TAlignment);
    procedure SetVerAlignment(x: TTextLayout);
  public
    //: @exclude
    constructor Create(aCollection: TCollection); override;
    destructor Destroy; override;
    procedure AssignTo(Dest: TPersistent); override;
  published

    {$IFDEF PORTUGUES}
     {:
     Alinhamento horizontal do texto da zona. Os valores possiveis são:

     @bold(taLeftJustify:) Alinha o texto a esquerda do componente.

     @bold(taRightJustify:) Alinha o texto a direita do componente.

     @bold(taCenter:) Alinha o texto no centro do componente.

     @seealso(Color)
     @seealso(Font)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(VerticalAlignment)
     }
    {$ELSE}
     {:
     Horizontal alignment of the text. The possible values are:

     @bold(taLeftJustify:) Left alignment of the text.

     @bold(taRightJustify:) Right alignment of the text.

     @bold(taCenter:) Centralized alignment of the text.

     @seealso(Color)
     @seealso(Font)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(VerticalAlignment)
     }
    {$ENDIF}
    property HorizontalAlignment: TAlignment read FHorAlignment write SetHorAlignment default taLeftJustify;

    {$IFDEF PORTUGUES}
     {:
     Vertical alignment of the text. The possible values are:

     @bold(tlTop:) Align the text on top of the control.

     @bold(tlCenter:) Align the text on center of the control.

     @bold(tlBottom:) Align the text on bottom of the control.

     @seealso(Color)
     @seealso(Font)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     }
    {$ELSE}

    {$ENDIF}
    property VerticalAlignment: TTextLayout read FVerAlignment write SetVerAlignment default tlTop;

    {$IFDEF PORTUGUES}
     {:
     Texto a ser exibido na zona.
     @seealso(Color)
     @seealso(Font)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ELSE}
     {:
     Text to be shown.
     @seealso(Color)
     @seealso(Font)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ENDIF}
    property Text: TCaption read FText write SetText;

    {$IFDEF PORTUGUES}
     {:
     Cor que será exibida no fundo da zona.
     @seealso(Font)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ELSE}
     {:
     Background color of the text animation zone.
     @seealso(Font)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ENDIF}
    property Color: TColor read FColor write SetColor;

    {$IFDEF PORTUGUES}
     {:
     Caso @false, usa a cor de fundo da zona informada em Color. Caso @true
     deixa o fundo da zona transparente.
     @seealso(Color)
     @seealso(Font)
     @seealso(Text)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ELSE}
     {:
     If @false, uses the background color specified in Color property. If @true
     makes the background transparent.
     @seealso(Color)
     @seealso(Font)
     @seealso(Text)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ENDIF}
    property Transparent: Boolean read FTransparent write SetTransparent;

    {$IFDEF PORTUGUES}
     {:
     Fonte de formatação do texto (forma, tamanho e cor).
     @seealso(Color)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ELSE}
     {:
     Text font (form, size and color).
     @seealso(Color)
     @seealso(Text)
     @seealso(Transparent)
     @seealso(HorizontalAlignment)
     @seealso(VerticalAlignment)
     }
    {$ENDIF}
    property Font: TFont read FFont write SetFont;
  end;

  {$IFDEF PORTUGUES}
  {:
  Coleção de zonas de texto.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TTextZone)
  }
  {$ELSE}
  {:
  Collection of text animation zones.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TTextZone)
  }
  {$ENDIF}
  TTextZones = class(TZones)
  public
    //: @exclude
    constructor Create(aOwner: TPersistent);

    {$IFDEF PORTUGUES}
    //: Adiciona uma nova zona de texto na coleção.
    {$ELSE}
    //: Adds a animation text zone into the collection.
    {$ENDIF}
    function Add: TTextZone;
  end;

  {$IFDEF PORTUGUES}
  {:
  Implementa uma zona gráfica.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TGraphicZones)
  }
  {$ELSE}
  {:
  Class of graphic animation zone.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TGraphicZones)
  }
  {$ENDIF}

  { TGraphicZone }

  TGraphicZone = class(TAnimationZone)
  private
    FILIsDefault: Boolean;
    FFileName: Ansistring;
    FImageList: TImageList;
    FImageIndex: Longint;
    FColor: TColor;
    FTransparent: Boolean;

    procedure SetILAsDefault(b: Boolean);
    procedure SetFileName(fn: Ansistring);
    procedure SetImageList(il: TImageList);
    procedure SetImageIndex(aIndex: Longint);
    procedure SetColor(c: TColor);
    procedure SetTransparent(b: Boolean);
  public
    //: @exclude
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
  published

    {$IFDEF PORTUGUES}
     {:
     Caso as propriedades FileName, ImageList e ImageIndex estejam configuradas
     corretamente, @name permite você escolher qual será o recurso primário.
     Caso @true, o recurso padrão de imagens é o ImageList, caso contrário torna
     a busca de imagens do disco como padrão.
     @seealso(FileName)
     @seealso(ImageList)
     @seealso(ImageIndex)
     }
    {$ELSE}
     {:
     If the properties FileName, ImageList and ImageIndex are configured
     correctly, @name let you choose what's the primary image resource. If @true,
     the primary image resource is the ImageList, if not the primary image
     resource is the image stored on disk pointed by the FileName property.
     @seealso(FileName)
     @seealso(ImageList)
     @seealso(ImageIndex)
     }
    {$ENDIF}
    property ImageListAsDefault: Boolean read FILIsDefault write SetILAsDefault default True;

    {$IFDEF PORTUGUES}
     {:
     Caso a zona seja escolhida, exibe a imagem apontada por esse caminho (caso exista).
     @seealso(ImageListAsDefault)
     }
    {$ELSE}
     {:
     Shows the image pointed by @name (if the file exists) if the graphic
     animation zone is selected.
     @seealso(ImageListAsDefault)
     }
    {$ENDIF}
    property FileName: Ansistring read FFileName write SetFileName nodefault;

    {$IFDEF PORTUGUES}
     {:
     Informa qual a lista de imagens que será usada pela zona gráfica.
     @seealso(ImageListAsDefault)
     @seealso(ImageIndex)
     }
    {$ELSE}
     {:
     What's the ImageList that will be used graphic animation zone.
     @seealso(ImageListAsDefault)
     @seealso(ImageIndex)
     }
    {$ENDIF}
    property ImageList: TImageList read FImageList write SetImageList;

    {$IFDEF PORTUGUES}
     {:
     Informa qual imagem do ImageList que será exibido pela zona gráfica.
     @seealso(ImageListAsDefault)
     @seealso(ImageList)
     }
    {$ELSE}
     {:
     What's the Image Index of ImageList that will be shown if the graphic
     animation zone is selected.
     @seealso(ImageListAsDefault)
     @seealso(ImageList)
     }
    {$ENDIF}
    property ImageIndex: Longint read FImageIndex write SetImageIndex stored True nodefault;

    {$IFDEF PORTUGUES}
     {:
     Informa qual cor será interpretada como transparente pela zona gráfica caso
     a propriedade Transparent esteja habilitada.
     @seealso(Transparent)
     }
    {$ELSE}
     {:
     What's the color that will be interpreted as Transparent if Transparent
     property is @true.
     @seealso(Transparent)
     }
    {$ENDIF}
    property TransparentColor: TColor read FColor write SetColor default clWhite;

    {$IFDEF PORTUGUES}
     {:
     Habilita/desabilita o troca da cor TransparentColor pelo transparente.
     @seealso(TransparentColor)
     }
    {$ELSE}
     {:
     Enables/disables the replacement of the color TransparentColor by the
     transparent.
     @seealso(TransparentColor)
     }
    {$ENDIF}
    property Transparent: Boolean read FTransparent write SetTransparent default True;
  end;

  {$IFDEF PORTUGUES}
  {:
  Coleção de zonas gráficas.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TGraphicZone)
  }
  {$ELSE}
  {:
  Collection of graphic animation zones.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TGraphicZone)
  }
  {$ENDIF}

  { TGraphicZones }

  TGraphicZones = class(TZones)
  public
    //: @exclude
    constructor Create(AOwner: TPersistent);

    {$IFDEF PORTUGUES}
    //: Adiciona uma nova zona gráfica a coleção.
    {$ELSE}
    //: Adds a new graphic animation zone into the collection.
    {$ENDIF}
    function Add: TGraphicZone;
  end;

  //: @exclude
  TColorZone = class;

  {$IFDEF PORTUGUES}
  {:
  Coleção de zonas de cores.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TColorcZone)
  }
  {$ELSE}
  {:
  Collection of color zones.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TColorcZone)
  }
  {$ENDIF}
  TColorZones = class(TZones)
  public
    //: @exclude
    constructor Create(AOwner: TPersistent);

    {$IFDEF PORTUGUES}
    //: Adiciona uma nova zona de cor a coleção.
    {$ELSE}
    //: Adds a new color zone into the collection.
    {$ENDIF}
    function Add: TColorZone;
  end;

  {$IFDEF PORTUGUES}
  {:
  Implementa uma zona de cor.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TColorZones)
  }
  {$ELSE}
  {:
  Class of a color zone.
  @seealso(TZone)
  @seealso(TZones)
  @seealso(TColorZones)
  }
  {$ENDIF}
  TColorZone = class(TAnimationZone)
  private
    FColor: TColor;
    procedure SetColor(AValue: TColor);
  protected
    function GetDisplayName: Ansistring; override;
  published
    property Color: TColor read FColor write SetColor;
  end;

implementation

uses hsstrings;

  { TColorZone }

procedure TColorZone.SetColor(AValue: TColor);
begin
  if FColor = AValue then Exit;
  FColor := AValue;
  NotifyChange;
end;

function TColorZone.GetDisplayName: Ansistring;
begin
  Result := inherited GetDisplayName + ', Result=' + ColorToString(FColor);
end;

{ TAnimationZone }

function TAnimationZone.GetBlinkWithZoneNumber: Longint;
begin
  if FBlinkWith <> nil then
    Result := FBlinkWith.Index
  else
    Result := -1;
end;

procedure TAnimationZone.SetBlinkWithZoneNumber(v: Longint);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FBlinkWithIndex := v;
    Exit;
  end;

  if (v >= 0) and (v < Collection.Count) then
  begin
    if Collection.Items[v] = Self then
      raise Exception.Create(ScannotBlinkWithItSelf);
    FBlinkWith := TAnimationZone(Collection.Items[v]);
    FBlinkWith.AddReference(Self);
  end
  else
  begin
    if v <> -1 then
      raise Exception.Create(SoutOfBounds);
    if FBlinkWith <> nil then
      FBlinkWith.RemReference(Self);
    FBlinkWith := nil;
  end;
end;

procedure TAnimationZone.SetBlinkTime(v: Cardinal);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FBlinkTime := v;
    Exit;
  end;

  if v = FBlinkTime then Exit;
  FBlinkTime := v;
  NotifyChange;
end;

procedure TAnimationZone.RemoveBlinkZone;
begin
  FBlinkWith := nil;
end;

procedure TAnimationZone.AddReference(RefBy: TAnimationZone);
var
  h: Longint;
  i: Longint;
begin
  for i := 0 to High(FReferencedBy) do
    if FReferencedBy[i] = RefBy then Exit;
  h := Length(FReferencedBy);
  SetLength(FReferencedBy, h + 1);
  FReferencedBy[h] := RefBy;
end;

procedure TAnimationZone.RemReference(RefBy: TAnimationZone);
var
  h: Longint;
  i: Longint;
  p: Longint;
  Found: Boolean;
begin
  Found := False;
  for i := 0 to High(FReferencedBy) do
    if FReferencedBy[i] = RefBy then
    begin
      p := i;
      Found := True;
    end;
  if not Found then Exit;
  h := High(FReferencedBy);
  FReferencedBy[p] := FReferencedBy[h];
  SetLength(FReferencedBy, h);
end;

procedure TAnimationZone.Loaded;
begin
  inherited Loaded;
  SetBlinkWithZoneNumber(FBlinkWithIndex);
end;

constructor TAnimationZone.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FBlinkWithIndex := -1;
  if (([csDesigning] * (Collection.Owner as TComponent).ComponentState) = []) or (([csReading, csLoading] * (Collection.Owner as TComponent).ComponentState) <> []) then
  begin
    FValue1 := 0;
    FValue2 := 0;
  end
  else
  begin
    FValue1 := Index;
    FValue2 := FValue1;
  end;
end;

destructor TAnimationZone.Destroy;
var
  i: Integer;
begin
  if Assigned(FBlinkWith) then
    FBlinkWith.RemReference(Self);

  for i := High(FReferencedBy) downto 0 do
  begin
    FReferencedBy[i].RemoveBlinkZone;
    FReferencedBy[i].RemReference(Self);
  end;

  inherited Destroy;
end;

procedure TAnimationZone.AssignTo(Dest: TPersistent);
var
  ADest: TAnimationZone;
begin
  if Dest is TAnimationZone then
  begin
    ADest := Dest as TAnimationZone;

    inherited AssignTo(Dest);

    ADest.BlinkTime := FBlinkTime;
    ADest.BlinkWith := FBlinkWithIndex;
  end
  else
    inherited AssignTo(Dest);
end;

{ TColorZones }

constructor TColorZones.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TColorZone);
end;

function TColorZones.Add: TColorZone;
begin
  Result := TColorZone(inherited Add);
end;

procedure TZone.SetV1(v: Double);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FValue1 := v;
    Exit;
  end;
  if v = FValue1 then Exit;
  if ZoneType = ztBit then
  begin
    if (v > 31) or (v < 0) then
      raise Exception.Create(SztBitcomparationValue1MustBeBetween0And31);
    FValue1 := Int(v);
  end
  else
  begin
    if v > FValue2 then
    begin
      FValue1 := FValue2;
      FValue2 := v;
    end
    else
      FValue1 := v;
  end;
  NotifyChange;
end;

procedure TZone.SetV2(v: Double);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FValue2 := v;
    Exit;
  end;

  if v = FValue2 then Exit;
  if v < FValue1 then
  begin
    FValue2 := FValue1;
    FValue1 := v;
  end
  else
    FValue2 := v;
  NotifyChange;
end;

procedure TZone.SetIncV1(v: Boolean);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FIncludeV1 := v;
    Exit;
  end;

  if v = FIncludeV1 then Exit;
  FIncludeV1 := v;
  NotifyChange;
end;

procedure TZone.SetIncV2(v: Boolean);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FIncludeV2 := v;
    Exit;
  end;

  if v = FIncludeV2 then Exit;
  FIncludeV2 := v;
  NotifyChange;
end;

procedure TZone.SetAsDefaultZone(v: Boolean);
var
  i: Longint;
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FDefaultZone := v;
    Exit;
  end;

  if v = FDefaultZone then Exit;

  if v then
    with Collection as TZones do
    begin
      for i := 0 to Count - 1 do
        if (Items[i] <> Self) and (Items[i] is TZone) then
          TZone(Items[i]).DefaultZone := False;
    end;
  FDefaultZone := v;
  NotifyChange;
end;

procedure TZone.SetZoneType(AZoneTypes: TZoneTypes);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FZoneType := AZoneTypes;
    Exit;
  end;

  if AZoneTypes = FZoneType then Exit;

  if (AZoneTypes = ztBit) and ((FValue1 > 31) or (FValue1 < 0)) then
    raise Exception.Create(SztBitcomparationValue1MustBeBetween0And31);
  FZoneType := AZoneTypes;
  NotifyChange;
end;

function TZone.GetDisplayName: Ansistring;
begin
  if FDefaultZone then
  begin
    Result := '(Default)';
    Exit;
  end;

  case FZoneType of
    ztEqual: Result := 'Value=' + FloatToStr(Value1);
    ztRange:  begin
                if FIncludeV1 then
                  Result := '(Value>=' + FloatToStr(Value1)
                else
                  Result := '(Value>' + FloatToStr(Value1);

                if FIncludeV2 then
                  Result := Result + ') AND (Value<=' + FloatToStr(Value2) + ')'
                else
                  Result := Result + ') AND (Value<' + FloatToStr(Value2) + ')';
              end;
    ztBit:    begin
                if FIncludeV1 then
                  Result := 'Value.Bit' + FormatFloat('00', FValue1) + '=ON'
                else
                  Result := 'Value.Bit' + FormatFloat('00', FValue1) + '=OFF';
              end;
    ztNotEqual:   Result := 'Value<>' + FloatToStr(Value1);
    ztOutOfRange: begin
                    if FIncludeV1 then
                      Result := '(Value<=' + FloatToStr(Value1)
                    else
                      Result := '(Value<' + FloatToStr(Value1);

                    if FIncludeV2 then
                      Result := Result + ') OR (Value>=' + FloatToStr(Value2) + ')'
                    else
                      Result := Result + ') OR (Value>' + FloatToStr(Value2) + ')';
                  end;
    ztGreaterThan:  begin
                      if FIncludeV1 then
                        Result := '(Value>=' + FloatToStr(Value1) + ')'
                      else
                        Result := '(Value>' + FloatToStr(Value1) + ')';
                    end;
    ztLessThan: begin
                  if FIncludeV1 then
                    Result := '(Value<=' + FloatToStr(Value1) + ')'
                  else
                    Result := '(Value<' + FloatToStr(Value1) + ')';
                end;
  end;
end;

procedure TZone.AssignTo(Dest: TPersistent);
var
  ADest: TZone;
begin
  if Dest is TZone then
  begin
    ADest := Dest as TZone;

    ADest.FValue1 := FValue1;
    ADest.FValue2 := FValue2;
    ADest.FIncludeV1 := FIncludeV1;
    ADest.FIncludeV2 := FIncludeV2;
    ADest.FDefaultZone := FDefaultZone;
    ADest.FZoneType := FZoneType;
  end
  else
    inherited AssignTo(Dest);
end;

//############################################################
// TZones implementation
//############################################################

constructor TZones.Create(AOwner: TPersistent; AItemClass: TCollectionItemClass);
begin
  inherited Create(AOwner, AItemClass);
end;

//seleciona a zona de acordo com seu critério de seleção
//se duas zonas responderem a um valor, ele irá retornar
//a primeira zona encontrada

//Selects a animation zone depending of their select criteria.
function TZones.GetZoneFromValue(v: Double): TZone;
var
  i: Longint;
  Value: Longint;
  Bit: Longint;
  found: Boolean;
begin
  Result := nil;
  found := False;
  for i := 0 to Count - 1 do
  begin

    if (not found) and TZone(Items[i]).DefaultZone then
    begin
      Result := TZone(Items[i]);
      found := True;
      Continue;
    end;

    with Items[i] as TZone do
      case ZoneType of
        ztEqual:  if v = Value1 then
                    begin
                      Result := Self.Items[i] as TZone;
                      Break;
                    end;
        ztRange:  if ((v > FValue1) or (FIncludeV1 and (v >= FValue1))) and ((v < FValue2) or (FIncludeV2 and (v <= FValue2))) then
                    begin
                      Result := Self.Items[i] as TZone;
                      Break;
                    end;
        ztBit:  begin
                  Bit := Trunc(Value1);
                  Value := Trunc(v);
                  Bit := Power(2, Bit);
                  if ((Value and Bit) = Bit) = FIncludeV1 then
                  begin
                    Result := Self.Items[i] as TZone;
                    Break;
                  end;
                end;
        ztNotEqual: if v <> Value1 then
                      begin
                        Result := Self.Items[i] as TZone;
                        Break;
                      end;
        ztOutOfRange: if ((v < FValue1) or (FIncludeV1 and (v <= FValue1))) or ((v > FValue2) or (FIncludeV2 and (v >= FValue2))) then
                        begin
                          Result := Self.Items[i] as TZone;
                          Break;
                        end;
        ztGreaterThan:  if ((v > FValue1) or (FIncludeV1 and (v >= FValue1))) then
                          begin
                            Result := Self.Items[i] as TZone;
                            Break;
                          end;
        ztLessThan: if ((v < FValue1) or (FIncludeV1 and (v <= FValue1))) then
                      begin
                        Result := Self.Items[i] as TZone;
                        Break;
                      end;
      end; //end do case
  end; //end do for
end;

function TZones.GetDefaultZone: TZone;
var
  i,
  Value,
  Bit: Longint;
  Found: Boolean;
begin
  Result := nil;
  Found := False;
  for i := 0 to Count - 1 do
  begin
    if (not Found) and TZone(Items[i]).DefaultZone then
    begin
      Result := TZone(Items[i]);
      Exit;
    end;
  end;
end;

//############################################################
// TTextZone implementation
//############################################################

constructor TTextZone.Create(aCollection: TCollection);
begin
  inherited Create(aCollection);
  FFont := TFont.Create;
  FFont.OnChange := @FontChanges;
  FVerAlignment := tlTop;
  FHorAlignment := taLeftJustify;
end;

destructor TTextZone.Destroy;
begin
  FreeAndNil(FFont);
  inherited Destroy;
end;

procedure TTextZone.AssignTo(Dest: TPersistent);
var
  ADest: TTextZone;
begin
  if Dest is TTextZone then
  begin
    ADest := Dest as TTextZone;

    inherited AssignTo(Dest);

    ADest.FText := FText;
    ADest.FColor := FColor;
    ADest.FTransparent := FTransparent;
    ADest.FHorAlignment := FHorAlignment;
    ADest.FVerAlignment := FVerAlignment;
    ADest.FFont.Assign(FFont);
  end
  else
    inherited AssignTo(Dest);
end;

procedure TTextZone.SetText(t: TCaption);
begin
  FText := t;
  NotifyChange;
end;

procedure TTextZone.SetHorAlignment(x: TAlignment);
begin
  FHorAlignment := x;
  NotifyChange;
end;

procedure TTextZone.SetVerAlignment(x: TTextLayout);
begin
  FVerAlignment := x;
  NotifyChange;
end;

procedure TTextZone.SetColor(c: TColor);
begin
  FColor := c;
  NotifyChange;
end;

procedure TTextZone.SetTransparent(b: Boolean);
begin
  FTransparent := b;
  NotifyChange;
end;

procedure TTextZone.SetFont(f: TFont);
begin
  FFont.Assign(f);
end;


procedure TTextZone.FontChanges(Sender: TObject);
begin
  NotifyChange;
end;

//############################################################
// TTextZones implementation
//############################################################
constructor TTextZones.Create(aOwner: TPersistent);
begin
  inherited Create(aOwner, TTextZone);
end;

function TTextZones.Add: TTextZone;
begin
  Result := TTextZone(inherited Add);
end;

//############################################################
// TGraphicZone implementation
//############################################################

constructor TGraphicZone.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FILIsDefault := True;
  FTransparent := True;
  FImageList := nil;
  FImageIndex := -1;
  FColor := clWhite;
end;

procedure TGraphicZone.Assign(Source: TPersistent);
var
  Src: TGraphicZone;
begin
  if Source is TGraphicZone then
  begin
    Src := Source as TGraphicZone;

    FValue1 := Src.FValue1;
    FValue2 := Src.FValue2;
    FIncludeV1 := Src.FIncludeV1;
    FIncludeV2 := Src.FIncludeV2;
    FDefaultZone := Src.FDefaultZone;
    FZoneType := Src.FZoneType;
    FImageList := Src.FImageList;
    FImageIndex := Src.FImageIndex;
    FBlinkTime := Src.FBlinkTime;
    BlinkWith := Src.BlinkWith;
  end
  else
    inherited Assign(Source);
end;

procedure TGraphicZone.SetILAsDefault(b: Boolean);
var
  Notify: Boolean;
begin
  Notify := (FILIsDefault <> b);
  FILIsDefault := b;
  if Notify then
    NotifyChange;
end;

procedure TGraphicZone.SetFileName(fn: Ansistring);
var
  Notify: Boolean;
begin
  if (Trim(fn) <> '') and (not FileExists(fn)) then
    raise Exception.Create(SfileNotFound);

  Notify := (fn <> FFileName);
  FFileName := fn;
  if Notify then
    NotifyChange;
end;

procedure TGraphicZone.SetImageList(il: TImageList);
begin
  if [csReading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FImageList := il;
    Exit;
  end;

  if il = FImageList then Exit;

  if Assigned(FImageList) then
    FImageList.RemoveFreeNotification(TGraphicZones(Collection).Owner as TComponent);

  FImageList := il;

  if il = nil then
    SetImageIndex(-1)
  else if FImageIndex >= il.Count then
    SetImageIndex(-1);

  NotifyChange;
end;

procedure TGraphicZone.SetImageIndex(aIndex: Longint);
var
  Notify: Boolean;
begin
  if [csReading, csLoading] * THMIBasicColletion(Collection).CollectionState <> [] then
  begin
    FImageIndex := aIndex;
    Exit;
  end;

  if FImageList <> nil then
  begin
    if (aIndex >= 0) and (aIndex <= (FImageList.Count - 1)) then
    begin
      Notify := (FImageIndex <> aIndex);
      FImageIndex := aIndex;
    end
    else
    begin
      Notify := FImageIndex <> -1;
      FImageIndex := -1;
    end;
  end
  else
  begin
    Notify := FImageIndex <> -1;
    FImageIndex := -1;
  end;

  if Notify then
    NotifyChange;
end;

procedure TGraphicZone.SetColor(c: TColor);
var
  Notify: Boolean;
begin
  Notify := (FColor <> c);
  FColor := c;
  if Notify then
    NotifyChange;
end;

procedure TGraphicZone.SetTransparent(b: Boolean);
var
  Notify: Boolean;
begin
  Notify := (FTransparent <> b);
  FTransparent := b;
  if Notify then
    NotifyChange;
end;

//############################################################
// TGraphicZones implementation
//############################################################
constructor TGraphicZones.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TGraphicZone);
end;

function TGraphicZones.Add: TGraphicZone;
begin
  Result := TGraphicZone(inherited Add);
end;

end.
