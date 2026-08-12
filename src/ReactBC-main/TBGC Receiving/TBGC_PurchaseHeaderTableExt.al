tableextension 80298 "TBGC Purchase Header Rcvg" extends "Purchase Header"
{
    fields
    {
        field(80205; "TBGC Draft Order No."; Code[20])
        {
            Caption = 'Draft Order No.';
            DataClassification = CustomerContent;
        }
        field(80204; "TBGC Original Created By"; Code[50])
        {
            Caption = 'Original CREATED BY';
            DataClassification = CustomerContent;
        }
        field(80201; "TBGC Released Date"; Date)
        {
            Caption = 'TBGC Released Date';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Use TBG Released Date (60210) on Purchase Header instead.';
            ObsoleteTag = '2026-04-20';
        }
        field(80202; "TBGC Released Date Time"; DateTime)
        {
            Caption = 'TBGC Released Date Time';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Use TBG Released DateTime (60211) on Purchase Header instead.';
            ObsoleteTag = '2026-04-20';
        }
    }
}
