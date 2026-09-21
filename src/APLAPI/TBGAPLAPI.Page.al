page 80226 "TBG Approved Product List API"
{
    PageType = API;
    Caption = 'TBG Product List API';
    APIPublisher = 'tbg';
    APIGroup = 'finance';
    APIVersion = 'v2.0';
    EntityName = 'productList';
    EntitySetName = 'productList';
    SourceTable = "Approved Product List";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                #region System / watermark
                field(SystemId; Rec.SystemId) { }
                field(SystemModifiedAt; Rec.SystemModifiedAt) { }
                field(SystemCreatedAt; Rec.SystemCreatedAt) { }
                #endregion

                #region Keys / identifiers
                field(Entry_No; Rec."Entry No.") { Caption = 'Entry No.'; }
                field(Vendor_No; Rec."Vendor No.") { Caption = 'Vendor No.'; }
                field(Vendor_Name; VendorNameTxt) { Caption = 'Vendor Name'; } // FlowField -> CalcFields
                field(Item_No; Rec."Item No.") { Caption = 'Item No.'; }
                field(Variant_Code; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(Unit_of_Measure_Code; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                #endregion

                #region Pricing
                field(Direct_Unit_Cost; Rec."Direct Unit Cost") { Caption = 'Direct Unit Cost'; }
                field(Minimum_Quantity; Rec."Minimum Quantity") { Caption = 'Minimum Quantity'; }
                field(Currency_Code; Rec."Currency Code") { Caption = 'Currency Code'; }
                #endregion

                #region Validity / status
                field(Starting_Date; Rec."Starting Date") { Caption = 'Starting Date'; }
                field(Ending_Date; Rec."Ending Date") { Caption = 'Ending Date'; }
                field(Inactive; Rec.Inactive) { Caption = 'Inactive'; }
                #endregion

                #region TBGC classification
                field(TBGC_Brand_Code; Rec."TBGC Brand Code") { Caption = 'TBGC Brand Code'; }
                field(TBGC_Brand_Description; Rec."TBGC Brand Description") { Caption = 'TBGC Brand Description'; }
                field(TBGC_Zoning_Code; Rec."TBGC Zoning Code") { Caption = 'TBGC Zoning Code'; }
                field(TBGC_Concept_Code; Rec."TBGC Concept Code") { Caption = 'TBGC Concept Code'; }
                field(TBGC_City; Rec."TBGC City") { Caption = 'TBGC City'; }
                field(Item_Family_Code; Rec."Item Family Code") { Caption = 'Item Family Code'; }
                #endregion

                #region Audit (business metadata — NOT the watermark)
                field(Modified_By; Rec."Modified By") { Caption = 'Modified By'; }
                field(Modified_At; Rec."Modified At") { Caption = 'Modified At'; }
                field(Approved_By; Rec."Approved By:") { Caption = 'Approved By'; }
                #endregion
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Vendor Name");   // only FlowField on this table
        VendorNameTxt := Rec."Vendor Name";
    end;

    var
        VendorNameTxt: Text[100];

}