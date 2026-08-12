page 80224 "VMS APL Concept Code API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'vms';
    APIGroup = 'vmsaplapi';

    EntityCaption = 'Concept Code';
    EntitySetCaption = 'Concept Codes';
    EntityName = 'conceptCode';
    EntitySetName = 'conceptCodes';

    PageType = API;
    SourceTable = "TBGC Concept Table";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    AboutText = 'Read-only API endpoint for pulling concept codes.';
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(conceptCode; Rec."Concept Code")
                {
                    Caption = 'Concept Code';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                }
                field(templateMaster; Rec."Template Master")
                {
                    Caption = 'Template Master';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
            }
        }
    }
}
