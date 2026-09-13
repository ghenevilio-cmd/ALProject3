/*
 * The OMS document references OMS used to stamp on a purchase order, and the payload hashes that protected
 * their replay.
 *
 * Business Central owns document identity now: OMS sends a hidden command id, correlates the standard purchase
 * order by its TBGC Draft Order No., and stores the official Posted Receipt No. it gets back. Nothing writes
 * or reads these four fields any more.
 *
 * They are marked Removed rather than deleted, so their field numbers stay reserved and any code that still
 * reaches for one fails to compile instead of silently reading a blank. Their validation and the replay guard
 * that rode on them are gone with them — a field that cannot be written has nothing to validate.
 */
tableextension 80225 "OMS2 Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(80206; "OMS PO Ref. No."; Code[11])
        {
            Caption = 'OMS PO Ref. No.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS now correlates purchase orders by TBGC Draft Order No.';
            ObsoleteTag = '1.1.2.21';
        }
        field(80207; "OMS Receiving Ref. No."; Code[11])
        {
            Caption = 'OMS Receiving Ref. No.';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS now stores the official Business Central Posted Receipt No.';
            ObsoleteTag = '1.1.2.21';
        }
        field(80208; "OMS PO Payload Hash"; Code[64])
        {
            Caption = 'OMS PO Payload Hash';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS v2 stores replay hashes in its technical command table.';
            ObsoleteTag = '1.1.2.21';
        }
        field(80209; "OMS Receiving Payload Hash"; Code[64])
        {
            Caption = 'OMS Receiving Payload Hash';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS v2 stores replay hashes in its technical command table.';
            ObsoleteTag = '1.1.2.21';
        }
    }

    keys
    {
        // Indexed the retired OMS reference, which nothing looks a purchase order up by any more.
        key(OMS2PoReference; "OMS PO Ref. No.")
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'OMS now correlates purchase orders by TBGC Draft Order No.';
            ObsoleteTag = '1.1.2.21';
        }
    }
}
