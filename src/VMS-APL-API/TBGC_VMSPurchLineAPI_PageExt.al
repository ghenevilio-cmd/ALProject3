// ============================================================================
//  TBGC VMS Purchase Line API
//  Exposes the TBGC Brand Code field from Purchase Line through a custom API
//  page in this extension. API pages cannot be extended with pageextension.
// ============================================================================
page 80252 "TBGC VMS Purchase Line API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'systemsintegration';
    APIGroup = 'vmsaplapi';

    EntityCaption = 'TBGC VMS Purchase Line';
    EntitySetCaption = 'TBGC VMS Purchase Lines';
    EntityName = 'tbgcVMSPurchaseLine';
    EntitySetName = 'tbgcVMSPurchaseLines';

    PageType = API;
    SourceTable = "Purchase Line";
    ODataKeyFields = "Document No.", "Line No.";

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    AboutText = 'API endpoint exposing TBGC Brand Code on purchase lines.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(documentNo; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    Editable = false;
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                    Editable = false;
                }
                field(tbgcBrandCode; Rec."TBGC Brand Code")
                {
                    Caption = 'TBGC Brand Code';
                    Editable = false;
                }
            }
        }
    }
}
