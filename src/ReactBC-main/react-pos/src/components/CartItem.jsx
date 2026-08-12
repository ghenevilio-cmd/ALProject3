import { useEffect, useState } from 'react';

const QUANTITY_DECIMALS = 5;
const QUANTITY_STEP = 0.00001;

const truncateDecimals = (value, decimals = QUANTITY_DECIMALS) => {
    const numericValue = Number(value);

    if (Number.isNaN(numericValue)) {
        return 0;
    }

    const factor = 10 ** decimals;
    return Math.trunc(numericValue * factor) / factor;
};

const formatQuantity = (value) => {
    if (value === '') {
        return '';
    }

    const truncatedValue = truncateDecimals(value);

    if (Number.isInteger(truncatedValue)) {
        return String(truncatedValue);
    }

    return truncatedValue.toFixed(QUANTITY_DECIMALS).replace(/0+$/, '').replace(/\.$/, '');
};

const formatAmount = (value) => {
    const truncatedValue = truncateDecimals(value, 2);

    if (Number.isInteger(truncatedValue)) {
        return String(truncatedValue);
    }

    return truncatedValue.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
};

export default function CartItem({ item, onUpdateQuantity, onRemove, isSubmitting }) {
    const [draftQuantity, setDraftQuantity] = useState(() => formatQuantity(item.quantity));

    useEffect(() => {
        setDraftQuantity(formatQuantity(item.quantity));
    }, [item.quantity]);

    const handleQuantityChange = (value) => {
        if (value === '') {
            setDraftQuantity('');
            return;
        }

        if (/^\d*(\.\d{0,5})?$/.test(value)) {
            setDraftQuantity(value);
        }
    };

    const handleQuantityBlur = () => {
        const parsedValue = Number(draftQuantity);

        if (draftQuantity === '' || Number.isNaN(parsedValue) || parsedValue <= 0) {
            onRemove(item.cartLineId);
            return;
        }

        const normalizedQuantity = truncateDecimals(parsedValue);
        setDraftQuantity(formatQuantity(normalizedQuantity));
        onUpdateQuantity(item.cartLineId, normalizedQuantity);
    };

    return (
        <div className="py-4 border-b border-gray-100 last:border-0">
            <div className="min-w-0">
                <h4
                    className="text-sm font-medium text-gray-900 leading-5 break-words"
                    style={{
                        display: '-webkit-box',
                        WebkitLineClamp: 3,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                    }}
                    title={item.brandDescription || item.name}
                >
                    {item.brandDescription || item.name}
                </h4>
                <div className="text-xs text-gray-500 truncate mt-1">
                    {item.id || item.name}
                </div>
                <div className="text-xs text-gray-500 mt-0.5">
                    ₱{formatAmount(item.price || 0)}
                </div>
            </div>

            <div className="mt-3 flex items-center gap-2">
                <div className="flex items-center gap-1 bg-gray-50 rounded-lg p-1 border border-gray-200 shrink-0">
                    <button
                        onClick={() => {
                            const currentQty = Number(item.quantity) || 0;
                            const newQty = truncateDecimals(currentQty - 1);

                            if (newQty >= QUANTITY_STEP) {
                                onUpdateQuantity(item.cartLineId, newQty);
                            } else {
                                onRemove(item.cartLineId);
                            }
                        }}
                        className="flex h-8 w-8 items-center justify-center rounded-md bg-white text-gray-600 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 active:scale-95 transition-transform touch-manipulation disabled:opacity-50 disabled:cursor-not-allowed"
                        aria-label="Decrease quantity"
                        disabled={isSubmitting || Number(item.quantity) <= QUANTITY_STEP}
                    >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 12H4" />
                        </svg>
                    </button>

                    <input
                        type="text"
                        inputMode="decimal"
                        value={draftQuantity}
                        onChange={(e) => handleQuantityChange(e.target.value)}
                        onBlur={handleQuantityBlur}
                        disabled={isSubmitting}
                        className="w-24 rounded-md border border-gray-300 bg-white px-2 py-1 text-center font-semibold tabular-nums text-gray-900 outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    />

                    <button
                        onClick={() => {
                            const currentQty = Number(item.quantity) || 0;
                            onUpdateQuantity(item.cartLineId, truncateDecimals(currentQty + 1));
                        }}
                        className="flex h-8 w-8 items-center justify-center rounded-md bg-white text-gray-600 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 active:scale-95 transition-transform touch-manipulation disabled:opacity-50 disabled:cursor-not-allowed"
                        disabled={isSubmitting}
                        aria-label="Increase quantity"
                    >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                        </svg>
                    </button>
                </div>

                <div className="ml-auto text-right text-sm font-semibold text-gray-900">
                    ₱{formatAmount((item.price || 0) * (Number(item.quantity) || 0))}
                </div>

                <button
                    onClick={() => onRemove(item.cartLineId)}
                    className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-red-50 text-red-600 shadow-sm ring-1 ring-inset ring-red-200 hover:bg-red-100 active:scale-95 transition-transform touch-manipulation disabled:opacity-50 disabled:cursor-not-allowed"
                    disabled={isSubmitting}
                    aria-label="Remove item"
                    title="Remove item"
                >
                    <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor">
                        <path fillRule="evenodd" d="M4.22 4.22a.75.75 0 011.06 0L10 8.94l4.72-4.72a.75.75 0 111.06 1.06L11.06 10l4.72 4.72a.75.75 0 11-1.06 1.06L10 11.06l-4.72 4.72a.75.75 0 01-1.06-1.06L8.94 10 4.22 5.28a.75.75 0 010-1.06z" clipRule="evenodd" />
                    </svg>
                </button>
            </div>
        </div>
    );
}
