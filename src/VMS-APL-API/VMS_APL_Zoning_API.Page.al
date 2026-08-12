page 80223 "VMS APL Zone Code API"
{
    APIVersion = 'v2.0';
    APIPublisher = 'vms';
    APIGroup = 'vmsaplapi';

    EntityCaption = 'Zone Code';
    EntitySetCaption = 'Zone Codes';
    EntityName = 'zoneCode';
    EntitySetName = 'zoneCodes';

    PageType = API;
    SourceTable = "TBGC Zoning Table";
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    AboutText = 'Read-only API endpoint for pulling zone codes.';
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
                field(zoneCode; Rec."Zoning Code")
                {
                    Caption = 'Zone Code';
                    Editable = false;
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
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
