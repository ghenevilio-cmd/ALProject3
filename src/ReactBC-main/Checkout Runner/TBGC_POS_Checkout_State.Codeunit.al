codeunit 80296 "TBGC POS Checkout State"
{
    SingleInstance = true;

    var
        CartJson: Text;
        ResultJson: Text;
        CheckoutRequest: Boolean;
        CreatedDraftNo: Code[20];
        CreatedDraftNos: Text;

    procedure SetCartJson(NewCartJson: Text)
    begin
        CartJson := NewCartJson;
    end;

    procedure GetCartJson(): Text
    begin
        exit(CartJson);
    end;

    procedure SetResultJson(NewResultJson: Text)
    begin
        ResultJson := NewResultJson;
    end;

    procedure SetCheckoutRequest(NewCheckoutRequest: Boolean)
    begin
        CheckoutRequest := NewCheckoutRequest;
    end;

    procedure GetCheckoutRequest(): Boolean
    begin
        exit(CheckoutRequest);
    end;

    procedure GetResultJson(): Text
    begin
        exit(ResultJson);
    end;

    procedure SetCreatedDraftNo(NewCreatedDraftNo: Code[20])
    begin
        CreatedDraftNo := NewCreatedDraftNo;
    end;

    procedure AddCreatedDraftNo(NewCreatedDraftNo: Code[20])
    begin
        if NewCreatedDraftNo = '' then
            exit;

        CreatedDraftNo := NewCreatedDraftNo;
        if CreatedDraftNos = '' then
            CreatedDraftNos := NewCreatedDraftNo
        else
            CreatedDraftNos += '|' + NewCreatedDraftNo;
    end;

    procedure GetCreatedDraftNo(): Code[20]
    begin
        exit(CreatedDraftNo);
    end;

    procedure GetCreatedDraftNos(): Text
    begin
        exit(CreatedDraftNos);
    end;

    procedure ClearState()
    begin
        Clear(CartJson);
        Clear(ResultJson);
        Clear(CheckoutRequest);
        Clear(CreatedDraftNo);
        Clear(CreatedDraftNos);
    end;
}
