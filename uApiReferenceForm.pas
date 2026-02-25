unit uApiReferenceForm;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  uOwmApiReferenceData;

type
  TApiReferenceForm = class(TForm)
    pnlClient: TPanel;
    pnlLeft: TPanel;
    tvEndpoints: TTreeView;
    splMain: TSplitter;
    pnlRight: TPanel;
    pnlHeader: TPanel;
    reEndpoint: TRichEdit;
    lblDescription: TLabel;
    gbRequest: TGroupBox;
    reRequest: TRichEdit;
    splReqResp: TSplitter;
    gbResponse: TGroupBox;
    reResponse: TRichEdit;
    procedure tvEndpointsChange(Sender: TObject; Node: TTreeNode);
  private
    FEndpoints: TOwmApiRefEndpointArray;
    procedure ApplyLanguage;
    procedure BuildTree;
    procedure ClearDetails;
    procedure ShowEndpoint(const AEndpoint: TOwmApiRefEndpoint);
    procedure SetSelectionStyle(ARichEdit: TRichEdit; AStart, ALength: Integer;
      AColor: TColor; AStyles: TFontStyles);
    procedure HighlightWholeWord(ARichEdit: TRichEdit; const AToken: string;
      AColor: TColor; AStyles: TFontStyles);
    procedure ApplyExampleFormatting(ARichEdit: TRichEdit);
    function NodeEndpointIndex(ANode: TTreeNode): Integer;
  public
    class procedure Execute(AOwner: TComponent);
  end;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  uOwmI18n;

class procedure TApiReferenceForm.Execute(AOwner: TComponent);
var
  LForm: TApiReferenceForm;
begin
  LForm := TApiReferenceForm.Create(AOwner);
  try
    LForm.FEndpoints := GetApiReferenceEndpoints;
    LForm.ApplyLanguage;
    LForm.BuildTree;
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TApiReferenceForm.ApplyLanguage;
begin
  Caption := OwmText('apiref.caption', 'API Reference');
  gbRequest.Caption := OwmText('apiref.section.request', 'Request example');
  gbResponse.Caption := OwmText('apiref.section.response', 'Response example');
end;

procedure TApiReferenceForm.BuildTree;
var
  I: Integer;
  LRootWallet: TTreeNode;
  LRootEnhanced: TTreeNode;
  LParent: TTreeNode;
  LNode: TTreeNode;
begin
  tvEndpoints.Items.BeginUpdate;
  try
    tvEndpoints.Items.Clear;

    LRootWallet := tvEndpoints.Items.Add(nil, GetApiReferenceCategoryCaption(arcOracleWallet));
    LRootEnhanced := tvEndpoints.Items.Add(nil, GetApiReferenceCategoryCaption(arcEnhanced));

    for I := 0 to High(FEndpoints) do
    begin
      if FEndpoints[I].Category = arcOracleWallet then
        LParent := LRootWallet
      else
        LParent := LRootEnhanced;

      LNode := tvEndpoints.Items.AddChild(LParent,
        OwmText(FEndpoints[I].NodeTextKey, FEndpoints[I].NodeTextDefault));
      LNode.Data := Pointer(NativeInt(I + 1));
    end;

    LRootWallet.Expand(False);
    LRootEnhanced.Expand(False);

    if LRootWallet.HasChildren then
      tvEndpoints.Selected := LRootWallet.GetFirstChild
    else
      ClearDetails;
  finally
    tvEndpoints.Items.EndUpdate;
  end;
end;

function TApiReferenceForm.NodeEndpointIndex(ANode: TTreeNode): Integer;
begin
  Result := -1;
  if not Assigned(ANode) then
    Exit;

  if NativeInt(ANode.Data) > 0 then
    Result := NativeInt(ANode.Data) - 1;
end;

procedure TApiReferenceForm.ClearDetails;
begin
  reEndpoint.Clear;
  reEndpoint.Lines.Add(OwmText('apiref.placeholder.endpoint', 'Select an endpoint in the tree.'));
  reEndpoint.SelectAll;
  reEndpoint.SelAttributes.Style := [fsBold];
  reEndpoint.SelLength := 0;

  lblDescription.Caption := OwmText('apiref.placeholder.description',
    'Endpoint description and examples will be displayed here.');

  reRequest.Clear;
  reResponse.Clear;
end;

procedure TApiReferenceForm.SetSelectionStyle(ARichEdit: TRichEdit; AStart,
  ALength: Integer; AColor: TColor; AStyles: TFontStyles);
begin
  if ALength <= 0 then
    Exit;

  ARichEdit.SelStart := AStart;
  ARichEdit.SelLength := ALength;
  ARichEdit.SelAttributes.Color := AColor;
  ARichEdit.SelAttributes.Style := AStyles;
end;

procedure TApiReferenceForm.HighlightWholeWord(ARichEdit: TRichEdit;
  const AToken: string; AColor: TColor; AStyles: TFontStyles);
var
  LTextUpper: string;
  LTokenUpper: string;
  LPos: Integer;
  LSearchStart: Integer;
  LBeforeIndex: Integer;
  LAfterIndex: Integer;
begin
  LTextUpper := UpperCase(ARichEdit.Text);
  LTokenUpper := UpperCase(AToken);
  LSearchStart := 1;

  while True do
  begin
    LPos := PosEx(LTokenUpper, LTextUpper, LSearchStart);
    if LPos <= 0 then
      Break;

    LBeforeIndex := LPos - 1;
    LAfterIndex := LPos + Length(LTokenUpper);

    if ((LBeforeIndex < 1) or not CharInSet(LTextUpper[LBeforeIndex], ['A'..'Z', '0'..'9', '_'])) and
       ((LAfterIndex > Length(LTextUpper)) or not CharInSet(LTextUpper[LAfterIndex], ['A'..'Z', '0'..'9', '_'])) then
      SetSelectionStyle(ARichEdit, LPos - 1, Length(LTokenUpper), AColor, AStyles);

    LSearchStart := LPos + Length(LTokenUpper);
  end;
end;

procedure TApiReferenceForm.ApplyExampleFormatting(ARichEdit: TRichEdit);
var
  LText: string;
  I: Integer;
  LTokenStart: Integer;
  LTokenEnd: Integer;
  LCheckPos: Integer;
begin
  ARichEdit.SelectAll;
  ARichEdit.SelAttributes.Name := 'Consolas';
  ARichEdit.SelAttributes.Color := clWindowText;
  ARichEdit.SelAttributes.Style := [];
  ARichEdit.SelLength := 0;

  LText := ARichEdit.Text;
  I := 1;
  while I <= Length(LText) do
  begin
    if LText[I] = '"' then
    begin
      LTokenStart := I;
      Inc(I);
      while I <= Length(LText) do
      begin
        if LText[I] = '\' then
          Inc(I, 2)
        else if LText[I] = '"' then
          Break
        else
          Inc(I);
      end;

      if I > Length(LText) then
        Break;

      LTokenEnd := I;
      LCheckPos := I + 1;
      while (LCheckPos <= Length(LText)) and CharInSet(LText[LCheckPos], [#9, #10, #13, ' ']) do
        Inc(LCheckPos);

      if (LCheckPos <= Length(LText)) and (LText[LCheckPos] = ':') then
        SetSelectionStyle(ARichEdit, LTokenStart - 1, LTokenEnd - LTokenStart + 1, clNavy, [fsBold])
      else
        SetSelectionStyle(ARichEdit, LTokenStart - 1, LTokenEnd - LTokenStart + 1, clGreen, []);
    end;

    Inc(I);
  end;

  HighlightWholeWord(ARichEdit, 'true', clTeal, [fsBold]);
  HighlightWholeWord(ARichEdit, 'false', clTeal, [fsBold]);
  HighlightWholeWord(ARichEdit, 'null', clPurple, [fsBold]);

  ARichEdit.SelStart := 0;
  ARichEdit.SelLength := 0;
end;

procedure TApiReferenceForm.ShowEndpoint(const AEndpoint: TOwmApiRefEndpoint);
var
  LHeader: string;
begin
  if SameText(AEndpoint.Id, 'openapi_doc') then
    LHeader := AEndpoint.Method + ' ' + AEndpoint.Path + sLineBreak +
      OwmText('apiref.content_type_json', 'Content-Type: application/json')
  else
    LHeader := AEndpoint.Method + ' ' + AEndpoint.Path + sLineBreak +
      OwmText('apiref.jsonapi_content_type', 'Content-Type: application/vnd.api+json');

  reEndpoint.Clear;
  reEndpoint.Lines.Add(LHeader);
  reEndpoint.SelectAll;
  reEndpoint.SelAttributes.Style := [fsBold];
  reEndpoint.SelAttributes.Color := clBlack;
  reEndpoint.SelLength := 0;

  lblDescription.Caption := OwmText(AEndpoint.DescriptionKey, AEndpoint.DescriptionDefault);

  reRequest.Lines.Text := AEndpoint.RequestExample;
  ApplyExampleFormatting(reRequest);

  reResponse.Lines.Text := AEndpoint.ResponseExample;
  ApplyExampleFormatting(reResponse);
end;

procedure TApiReferenceForm.tvEndpointsChange(Sender: TObject; Node: TTreeNode);
var
  LIndex: Integer;
begin
  LIndex := NodeEndpointIndex(Node);
  if (LIndex < 0) or (LIndex > High(FEndpoints)) then
  begin
    ClearDetails;
    Exit;
  end;

  ShowEndpoint(FEndpoints[LIndex]);
end;

end.
