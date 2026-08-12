import { useState } from 'react';
import CartItem from './CartItem';
import CheckoutButton from './CheckoutButton';

const formatQuantity = (value) => {
    const numericValue = Number(value) || 0;
    const truncatedValue = Math.trunc(numericValue * 100000) / 100000;

    if (Number.isInteger(truncatedValue)) {
        return String(truncatedValue);
    }

    return truncatedValue.toFixed(5).replace(/0+$/, '').replace(/\.$/, '');
};

const formatAmount = (value) => {
    const numericValue = Number(value) || 0;
    const truncatedValue = Math.trunc(numericValue * 100) / 100;

    if (Number.isInteger(truncatedValue)) {
        return String(truncatedValue);
    }

    return truncatedValue.toFixed(2).replace(/0+$/, '').replace(/\.$/, '');
};

export default function CartSidebar({
    cartItems,
    onUpdateQuantity,
    onRemove,
    onCheckout,
    onAddToDraft,
    locationCode,
    isSubmitting,
    processingAction,
    orderingDisabled,
    draftOrderingDisabled
}) {
    const [showCurrentOrderModal, setShowCurrentOrderModal] = useState(false);

    const total = cartItems.reduce(
        (sum, item) => sum + (Number(item.price) || 0) * (Number(item.quantity) || 0),
        0
    );

    const itemCount = cartItems.reduce(
        (sum, item) => sum + (Number(item.quantity) || 0),
        0
    );

    return (
        <>
            <div className="flex h-full flex-col bg-white border-l border-gray-200 shadow-sm relative z-10">
                <div className="flex items-center justify-between p-4 sm:p-6 border-b border-gray-200 bg-white z-10 shrink-0">
                    <div className="flex min-w-0 items-center gap-3">
                        <h2 className="text-xl font-bold text-gray-900 tracking-tight">Current Order</h2>
                        <button
                            type="button"
                            onClick={() => setShowCurrentOrderModal(true)}
                            disabled={cartItems.length === 0}
                            className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-600 shadow-sm transition hover:border-blue-300 hover:bg-blue-50 hover:text-blue-700 disabled:cursor-not-allowed disabled:border-gray-100 disabled:bg-gray-50 disabled:text-gray-300"
                            aria-label="View Current Order"
                            title="View Current Order"
                        >
                            <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                                <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 12s3.75-6.75 9.75-6.75S21.75 12 21.75 12 18 18.75 12 18.75 2.25 12 2.25 12Z" />
                                <path strokeLinecap="round" strokeLinejoin="round" d="M12 15.75A3.75 3.75 0 1 0 12 8.25a3.75 3.75 0 0 0 0 7.5Z" />
                            </svg>
                        </button>
                    </div>
                    {itemCount > 0 && (
                        <span className="flex h-6 min-w-[1.5rem] items-center justify-center rounded-full bg-blue-100 px-2 text-xs font-bold text-blue-700">
                            {formatQuantity(itemCount)}
                        </span>
                    )}
                </div>

                <div className="flex-1 overflow-y-auto px-4 sm:px-6">
                    {cartItems.length === 0 ? (
                        <div className="flex h-full flex-col items-center justify-center text-gray-500">
                            <svg className="h-16 w-16 text-gray-300 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                            </svg>
                            <p className="text-center font-medium">Cart is empty</p>
                            <p className="text-sm mt-1">Tap an item to add it</p>
                        </div>
                    ) : (
                        <div className="py-2">
                            {cartItems.map((item) => (
                                <CartItem
                                    key={item.cartLineId}
                                    item={item}
                                    onUpdateQuantity={onUpdateQuantity}
                                    onRemove={onRemove}
                                    isSubmitting={isSubmitting}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <CheckoutButton
                    total={total}
                    itemCount={itemCount}
                    onCheckout={onCheckout}
                    onAddToDraft={onAddToDraft}
                    locationCode={locationCode}
                    isSubmitting={isSubmitting}
                    processingAction={processingAction}
                    orderingDisabled={orderingDisabled}
                    draftOrderingDisabled={draftOrderingDisabled}
                />
            </div>

            {showCurrentOrderModal && (
                <div className="fixed inset-0 z-[10002] flex items-center justify-center bg-black/40 p-4 sm:p-6">
                    <div className="flex max-h-[90vh] w-full max-w-4xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl">
                        <div className="flex items-center justify-between border-b border-gray-200 px-5 py-4 sm:px-6">
                            <div>
                                <h3 className="text-xl font-bold text-gray-900">Current Order</h3>
                                <p className="mt-1 text-sm text-gray-500">
                                    {cartItems.length === 0
                                        ? 'No items in the current order.'
                                        : `${formatQuantity(itemCount)} ${Number(itemCount) === 1 ? 'item' : 'items'} in this order`}
                                </p>
                            </div>
                            <button
                                type="button"
                                onClick={() => setShowCurrentOrderModal(false)}
                                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-500 transition hover:bg-gray-50 hover:text-gray-700"
                                aria-label="Close Current Order"
                            >
                                <svg className="h-4 w-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                                    <path fillRule="evenodd" d="M4.22 4.22a.75.75 0 0 1 1.06 0L10 8.94l4.72-4.72a.75.75 0 1 1 1.06 1.06L11.06 10l4.72 4.72a.75.75 0 1 1-1.06 1.06L10 11.06l-4.72 4.72a.75.75 0 0 1-1.06-1.06L8.94 10 4.22 5.28a.75.75 0 0 1 0-1.06Z" clipRule="evenodd" />
                                </svg>
                            </button>
                        </div>

                        <div className="flex-1 overflow-y-auto px-5 py-4 sm:px-6 sm:py-5">
                            {cartItems.length === 0 ? (
                                <div className="flex min-h-48 flex-col items-center justify-center rounded-2xl border border-dashed border-gray-200 bg-gray-50 px-6 text-center text-gray-500">
                                    <p className="text-base font-medium text-gray-700">Current order is empty</p>
                                    <p className="mt-1 text-sm">Add items from the market list to see them here.</p>
                                </div>
                            ) : (
                                <div className="space-y-3">
                                    {cartItems.map((item) => {
                                        const subtotal = (Number(item.price) || 0) * (Number(item.quantity) || 0);

                                        return (
                                            <div
                                                key={item.cartLineId}
                                                className="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm"
                                            >
                                                <div className="flex items-start justify-between gap-4">
                                                    <div className="min-w-0">
                                                        <h4 className="text-base font-semibold text-gray-900">
                                                            {item.brandDescription || item.name}
                                                        </h4>
                                                        <p className="mt-1 text-sm text-gray-500">
                                                            Item No.: {item.id || '-'}
                                                        </p>
                                                        {item.uom && (
                                                            <p className="mt-1 text-sm text-gray-500">
                                                                UOM: {item.uom}
                                                            </p>
                                                        )}
                                                    </div>
                                                    <div className="rounded-full bg-blue-50 px-3 py-1 text-sm font-semibold text-blue-700">
                                                        Qty {formatQuantity(item.quantity)}
                                                    </div>
                                                </div>

                                                <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
                                                    <div className="rounded-xl bg-gray-50 px-3 py-2">
                                                        <div className="text-xs font-medium uppercase tracking-wide text-gray-500">Price</div>
                                                        <div className="mt-1 text-sm font-semibold text-gray-900">P{formatAmount(item.price)}</div>
                                                    </div>
                                                    <div className="rounded-xl bg-gray-50 px-3 py-2">
                                                        <div className="text-xs font-medium uppercase tracking-wide text-gray-500">Quantity</div>
                                                        <div className="mt-1 text-sm font-semibold text-gray-900">{formatQuantity(item.quantity)}</div>
                                                    </div>
                                                    <div className="rounded-xl bg-gray-50 px-3 py-2 col-span-2 sm:col-span-1">
                                                        <div className="text-xs font-medium uppercase tracking-wide text-gray-500">Subtotal</div>
                                                        <div className="mt-1 text-sm font-semibold text-gray-900">P{formatAmount(subtotal)}</div>
                                                    </div>
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            )}
                        </div>

                        <div className="border-t border-gray-200 bg-gray-50 px-5 py-4 sm:px-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <div className="text-sm font-medium text-gray-500">Total</div>
                                    <div className="text-2xl font-bold text-gray-900">P{formatAmount(total)}</div>
                                </div>
                                <button
                                    type="button"
                                    onClick={() => setShowCurrentOrderModal(false)}
                                    className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-blue-700"
                                >
                                    Close
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}
