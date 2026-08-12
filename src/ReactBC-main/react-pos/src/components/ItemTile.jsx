export default function ItemTile({ item, onAddToCart }) {
return (
    <button
        onClick={() => onAddToCart(item)}
        className="grid w-full grid-cols-[220px_minmax(0,1fr)_220px] items-center gap-4 border-b border-gray-200 bg-white px-4 py-4 text-left hover:bg-blue-100 transition"
    >
        <div className="text-xl font-bold text-gray-900">
            {item.id}
        </div>

        <div>
            <div className="text-xl text-gray-800">
                {item.brandDescription || item.name}
            </div>
            <div className="mt-1 text-sm text-gray-500">
                {item.vendorName || '-'}
            </div>
            <div className="mt-0.5 text-sm text-gray-500">
                UOM: {item.uom || '-'} | Brand: {item.brandCode || '-'}
            </div>
        </div>

        <div className="min-w-0 text-right text-xl font-extrabold leading-tight text-blue-600 break-words">
            <div className="flex items-center justify-end gap-2">
                <span>₱{Number(item.price || 0).toFixed(2)}</span>
                <span className="text-base font-bold">/{item.uomDescription || item.uom || '-'}</span>
            </div>
            <div className="mt-2 inline-flex items-center justify-end gap-2 rounded-full bg-blue-50 px-3 py-1 text-sm font-bold text-blue-700">
                <svg
                    className="h-4 w-4"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth="1.8"
                    aria-hidden="true"
                >
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 5.25h2.18a.75.75 0 0 1 .73.57l.54 2.18m0 0h10.9a.75.75 0 0 1 .72.96l-1.08 3.76a1.5 1.5 0 0 1-1.44 1.09H9.42a1.5 1.5 0 0 1-1.45-1.14L6.95 8m0 0L6.3 5.4A1.5 1.5 0 0 0 4.84 4.25H4.5" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9.75 18.75a.75.75 0 1 1 0 1.5.75.75 0 0 1 0-1.5Zm7.5 0a.75.75 0 1 1 0 1.5.75.75 0 0 1 0-1.5Z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M12 9.75v3.5m-1.75-1.75h3.5" />
                </svg>
                <span>Add to Cart</span>
            </div>
        </div>
    </button>
);
}
