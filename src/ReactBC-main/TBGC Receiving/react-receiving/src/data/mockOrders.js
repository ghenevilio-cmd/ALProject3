const mockOrders = [
  {
    documentNo: 'PO-000123',
    vendorNo: 'V000110',
    vendorName: 'Sample Vendor 01',
    status: 'Late Released',
    orderDate: '2026-04-01',
    releasedDate: '2026-04-02T15:42:00',
    lastReceiptDate: '2026-04-08',
    receivedQty: 12,
    remainingQty: 8,
    expectedReceiptDate: '2026-04-03',
    systemModifiedBy: 'f3c8a4d2-5cb0-4f2b-9b0a-2d6a1d6f88f1',
    systemModifiedAt: '2026-04-09T16:25:00',
    locationCode: 'MAIN',
  },
  {
    documentNo: 'PO-000124',
    vendorNo: 'V000210',
    vendorName: 'Sample Vendor 02',
    status: 'Released',
    orderDate: '2026-04-03',
    releasedDate: '2026-04-03T10:15:00',
    lastReceiptDate: '',
    receivedQty: 0,
    remainingQty: 20,
    expectedReceiptDate: '2026-04-06',
    systemModifiedBy: '8f9a36c7-7549-4e25-a0ab-1fbbce6f2a44',
    systemModifiedAt: '2026-04-10T09:10:00',
    locationCode: 'MAIN',
  },
];

export default mockOrders;
