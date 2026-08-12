export default function CheckoutButton({
    total,
    itemCount,
    onCheckout,
    onAddToDraft,
    locationCode,
    isSubmitting,
    processingAction,
    orderingDisabled,
    draftOrderingDisabled
}) {
    const formatAmount = (value) => {
        const truncatedValue = Math.trunc(Number(value || 0) * 100) / 100;

        if (Number.isInteger(truncatedValue)) {
            return String(truncatedValue);
        }

        return truncatedValue.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
    };

    const baseDisabled = itemCount === 0 || !locationCode || locationCode.trim() === '' || isSubmitting;
    const checkoutDisabled = baseDisabled || orderingDisabled;
    const draftDisabled = baseDisabled || draftOrderingDisabled;
    const isProcessingDraft = processingAction === 'draft';
    const isProcessingCheckout = processingAction === 'checkout';
    const formattedItemCount = Number.isInteger(itemCount)
        ? String(itemCount)
        : (Math.trunc(Number(itemCount || 0) * 100000) / 100000).toFixed(5).replace(/0+$/, '').replace(/\.$/, '');

    return (
        <div className="mt-auto border-t border-gray-200 bg-white p-4 sm:p-6 shadow-[0_-4px_6px_-1px_rgba(0,0,0,0.05)] z-10">
            <div className="flex items-center justify-between mb-4">
                <span className="text-base font-medium text-gray-500">Total</span>
                <span className="text-2xl font-bold text-gray-900">₱{formatAmount(total)}</span>
            </div>

            <div className="flex flex-col gap-3">
                <button
                    onClick={onAddToDraft}
                    disabled={draftDisabled}
                    className={`w-full flex items-center justify-center py-4 px-8 rounded-xl text-lg font-semibold shadow-md transition-all touch-manipulation ${
                        draftDisabled
                            ? 'bg-gray-200 text-gray-500 cursor-not-allowed shadow-none'
                            : 'bg-amber-100 text-amber-900 hover:bg-amber-200 hover:shadow-lg active:scale-[0.98]'
                    }`}
                >
                    {isProcessingDraft && (
                        <span className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></span>
                    )}

                    {!isProcessingDraft && (
                        <svg
                            className="mr-2 h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            strokeWidth="1.8"
                            aria-hidden="true"
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 5v14m-7-7h14" />
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5 3.75h3l1.2 4.5h9.05a.75.75 0 0 1 .72.96l-1.1 3.85a1.5 1.5 0 0 1-1.45 1.09H10.1a1.5 1.5 0 0 1-1.45-1.11L6.2 4.5H5" />
                        </svg>
                    )}

                    <span>{isProcessingDraft ? 'Processing...' : 'Add to Draft'}</span>

                    {!isProcessingDraft && itemCount > 0 && (
                        <span className="ml-2 bg-amber-200 px-2 py-0.5 rounded-full text-sm">
                            {formattedItemCount} {Number(itemCount) === 1 ? 'item' : 'items'}
                        </span>
                    )}
                </button>

                <button
                    onClick={onCheckout}
                    disabled={checkoutDisabled}
                    className={`w-full flex items-center justify-center py-4 px-8 rounded-xl text-lg font-semibold text-white shadow-md transition-all touch-manipulation ${
                        checkoutDisabled
                            ? 'bg-gray-300 cursor-not-allowed shadow-none'
                            : 'bg-blue-600 hover:bg-blue-700 hover:shadow-lg active:scale-[0.98]'
                    }`}
                >
                    {isProcessingCheckout && (
                        <span className="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                    )}

                    {!isProcessingCheckout && (
                        <svg
                            className="mr-2 h-5 w-5"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            strokeWidth="1.8"
                            aria-hidden="true"
                        >
                            <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5" />
                            <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 6.75V5.25A2.25 2.25 0 0 1 9.75 3h4.5A2.25 2.25 0 0 1 16.5 5.25v1.5" />
                            <path strokeLinecap="round" strokeLinejoin="round" d="M5.25 6.75l1.2 11.02A2.25 2.25 0 0 0 8.69 19.8h6.62a2.25 2.25 0 0 0 2.24-2.03l1.2-11.02" />
                            <path strokeLinecap="round" strokeLinejoin="round" d="M10.5 10.5l1.5 1.5 3-3" />
                        </svg>
                    )}

                    <span>{isProcessingCheckout ? 'Processing...' : 'Checkout'}</span>

                    {!isProcessingCheckout && itemCount > 0 && (
                        <span className="ml-2 bg-blue-700 px-2 py-0.5 rounded-full text-sm">
                            {formattedItemCount} {Number(itemCount) === 1 ? 'item' : 'items'}
                        </span>
                    )}
                </button>
            </div>
        </div>
    );
}
