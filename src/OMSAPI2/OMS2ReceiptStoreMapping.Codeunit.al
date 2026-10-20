codeunit 80263 "OMS2 Receipt Store Mapping"
{
    procedure ResolveConcept(var Store: Record "LSC Store"; LocationCode: Code[10]; LockMapping: Boolean): Code[20]
    var
        Concept: Text;
    begin
        Store.Reset();
        if LocationCode = '' then
            Error(MappingErr);
        Store.SetLoadFields("Location Code", "TBGC Concept Code");
        Store.SetRange("Location Code", LocationCode);
        if LockMapping then
            Store.LockTable()
        else
            Store.ReadIsolation := IsolationLevel::ReadCommitted;
        if not Store.FindSet(LockMapping) then
            Error(MappingErr);
        Concept := Store."TBGC Concept Code";
        Concept := UpperCase(Concept.Trim());
        if (Concept = '') or (StrLen(Concept) > 20) or (Store.Next() <> 0) then
            Error(MappingErr);
        exit(Concept);
    end;

    var
        MappingErr: Label 'The receipt location must match exactly one store with a valid purchasing concept. Correct the store mapping before continuing.';
}
