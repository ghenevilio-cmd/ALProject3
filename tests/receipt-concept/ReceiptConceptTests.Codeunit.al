#if OMS_RECEIPT_CONCEPT_TESTS
codeunit 80351 "OMS Receipt Concept Tests"
{
    Subtype = Test;

    [Test]
    procedure ActualConceptIsNotLocationDimension()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        AddStore(Store, 'A', '1991', 'DENNYS');
        if Mapping.ResolveConcept(Store, '1991', false) <> 'DENNYS' then
            Error('Location1991 must resolve to conceptDENNYS.');
    end;

    [Test]
    procedure MissingStoreCannotReusePreviousConcept()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        AddStore(Store, 'A', '1991', 'DENNYS');
        Mapping.ResolveConcept(Store, '1991', false);
        asserterror Mapping.ResolveConcept(Store, '9999', false);
        AssertMappingError();
    end;

    [Test]
    procedure DuplicateLocationIsAmbiguous()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        AddStore(Store, 'A', '1991', 'DENNYS');
        AddStore(Store, 'B', '1991', 'DENNYS');
        asserterror Mapping.ResolveConcept(Store, '1991', true);
        AssertMappingError();
    end;

    [Test]
    procedure BlankConceptIsRejected()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        AddStore(Store, 'A', '1991', '');
        asserterror Mapping.ResolveConcept(Store, '1991', false);
        AssertMappingError();
    end;

    [Test]
    procedure BlankLocationIsRejected()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        asserterror Mapping.ResolveConcept(Store, '', false);
        AssertMappingError();
    end;

    [Test]
    procedure MappingRechecksChangedConcept()
    var
        Store: Record "LSC Store" temporary;
        Mapping: Codeunit "OMS2 Receipt Store Mapping";
    begin
        AddStore(Store, 'A', '1991', 'DENNYS');
        Mapping.ResolveConcept(Store, '1991', false);
        Store.Reset();
        Store.Get('A');
        Store."TBGC Concept Code" := 'OTHER';
        Store.Modify(false);
        if Mapping.ResolveConcept(Store, '1991', true) <> 'OTHER' then
            Error('Mapping reused an obsolete concept.');
    end;

    [Test]
    procedure LegacyActionRefusesBeforeReadingReceipt()
    var
        ReceiptPage: Page "OMS2 Posted Receipt Lines API";
        Context: WebServiceActionContext;
        EmptyId: Guid;
    begin
        asserterror ReceiptPage.Undo(Context, EmptyId, EmptyId, EmptyId, 0, '', 0, '', '', '', '', '', 0, 0, 0DT);
        if StrPos(GetLastErrorText(), 'contract is retired') = 0 then
            Error('Legacy action must refuse explicitly before any financial work.');
    end;

    local procedure AddStore(var Store: Record "LSC Store" temporary; StoreNo: Code[10]; LocationCode: Code[10]; Concept: Code[20])
    begin
        Store.Init();
        Store."No." := StoreNo;
        Store."Location Code" := LocationCode;
        Store."TBGC Concept Code" := Concept;
        Store.Insert(false);
    end;

    local procedure AssertMappingError()
    begin
        if StrPos(GetLastErrorText(), 'exactly one store') = 0 then
            Error('Expected a closed mapping refusal.');
    end;
}

#endif
