page 80228 "TBG Brand List API"
{
    PageType = API;
    Caption = 'TBG Brand List API';
    APIPublisher = 'tbg';
    APIGroup = 'finance';
    APIVersion = 'v2.0';
    EntityName = 'brandList';
    EntitySetName = 'brandList';
    SourceTable = 80264;
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

                #region Data (all stored — no CalcFields, no Format needed)
                field(Item_No; Rec."Item No.") { Caption = 'Item No.'; }
                field(TBGC_Brand_Code; Rec."TBGC Brand Code") { Caption = 'TBGC Brand Code'; }
                field(TBGC_Brand_Description; Rec."TBGC Brand Description") { Caption = 'TBGC Brand Description'; } // stored
                field(Unit_of_Measure_Code; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                #endregion
            }
        }
    }
}