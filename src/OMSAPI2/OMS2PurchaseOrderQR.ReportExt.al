/// <summary>
/// Gives the purchase order print (report 405 "Order") a QR code of the purchase order number, so a receiver
/// can scan the paper PO instead of typing its number.
///
/// The QR is rendered by Business Central's own "Dynamics 2D" image provider, so it needs no barcode font on
/// the service tier. It is encoded at High error correction because the TBGPurchaseOrder layout places the
/// company logo over its centre, and High is the level that still reads with that part covered.
///
/// The image travels as base64 text; the RDLC layout turns it back into bytes with Convert.FromBase64String.
/// </summary>
reportextension 80201 "OMS2 Purchase Order QR" extends Order
{
    dataset
    {
        add("Purchase Header")
        {
            column(PONoQRCode; PONoQRCode) { }
        }
        modify("Purchase Header")
        {
            trigger OnAfterAfterGetRecord()
            begin
                PONoQRCode := EncodeQRCode("Purchase Header"."No.");
            end;
        }
    }

    var
        PONoQRCode: Text;

    local procedure EncodeQRCode(Value: Text): Text
    var
        BarcodeEncodeSettings2D: Record "Barcode Encode Settings 2D";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        BarcodeImageProvider2D: Interface "Barcode Image Provider 2D";
        InStr: InStream;
    begin
        if Value = '' then
            exit('');

        BarcodeEncodeSettings2D."Error Correction Level" := BarcodeEncodeSettings2D."Error Correction Level"::High;
        BarcodeImageProvider2D := Enum::"Barcode Image Provider 2D"::Dynamics2D;
        TempBlob := BarcodeImageProvider2D.EncodeImage(Value, Enum::"Barcode Symbology 2D"::"QR-Code", BarcodeEncodeSettings2D);
        TempBlob.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;
}
