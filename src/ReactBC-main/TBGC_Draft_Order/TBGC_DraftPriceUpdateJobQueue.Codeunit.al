codeunit 80222 "TBGC Draft Price Update JQ"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RunUpdateAll();
    end;

    procedure RunUpdateAll(): Integer
    var
        PriceUpdateBuffer: Record "TBGC Draft Price Update Buf" temporary;
        PriceUpdateMgt: Codeunit "TBGC Draft Price Update Mgt";
    begin
        PriceUpdateMgt.BuildPreview(PriceUpdateBuffer);
        exit(PriceUpdateMgt.ApplyUpdates(PriceUpdateBuffer));
    end;
}
