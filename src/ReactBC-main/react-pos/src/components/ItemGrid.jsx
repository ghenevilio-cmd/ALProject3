import { useState } from 'react';
import ItemTile from './ItemTile';

export default function ItemGrid({
    items,
    onAddToCart,
    title,
    subtitle,
    searchQuery,
    onSearchChange,
    onLoadMore,
    hasMoreItems,
    isLoadingItems,
}) {
    const [selectedCategory, setSelectedCategory] = useState('ALL');
    const [sortField, setSortField] = useState('itemNo');
    const [sortDirection, setSortDirection] = useState('asc');
    const normalizedSearchQuery = (searchQuery || '').trim().toLowerCase();
    const categories = [...new Set(
        (items || [])
            .map((item) => item.category)
            .filter((category) => category && category.trim() !== '')
    )].sort();

    const filteredItems = (items || []).filter(item => {
        const matchesCategory =
            selectedCategory === 'ALL' ||
            item.category === selectedCategory;

        return matchesCategory;
    });

    const sortedItems = [...filteredItems].sort((leftItem, rightItem) => {
        const leftValue = sortField === 'vendorNo'
            ? (leftItem.vendorNo || '')
            : (leftItem.id || '');
        const rightValue = sortField === 'vendorNo'
            ? (rightItem.vendorNo || '')
            : (rightItem.id || '');

        const comparison = leftValue.localeCompare(rightValue, undefined, {
            numeric: true,
            sensitivity: 'base',
        });

        return sortDirection === 'asc' ? comparison : comparison * -1;
    });

    const handleScroll = (event) => {
        if (!onLoadMore || isLoadingItems || !hasMoreItems) {
            return;
        }

        const element = event.currentTarget;
        const distanceFromBottom = element.scrollHeight - element.scrollTop - element.clientHeight;
        if (distanceFromBottom <= 160) {
            onLoadMore();
        }
    };

    return (
        <div className="flex h-full flex-col">
            {(title || subtitle) && (
                <div className="px-6 pt-6 pb-1">
                    {title && (
                        <h1 className="text-3xl font-bold leading-tight text-gray-900">
                            {title}
                        </h1>
                    )}
                    {subtitle && (
                        <p className="mt-2 text-sm text-gray-500">
                            {subtitle}
                        </p>
                    )}
                </div>
            )}

            <div className="flex-none px-6 pt-3 pb-1">
                <div className="flex justify-end">
                    <div className="flex flex-wrap items-center gap-3 rounded-md border border-gray-200 bg-white px-3 py-2 shadow-sm">
                        <span className="text-sm font-medium text-gray-500">Sort</span>
                        <select
                            value={sortField}
                            onChange={(e) => setSortField(e.target.value)}
                            className="rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                            <option value="itemNo">Item No.</option>
                            <option value="vendorNo">Vendor No.</option>
                        </select>
                        <select
                            value={sortDirection}
                            onChange={(e) => setSortDirection(e.target.value)}
                            className="rounded-md border-gray-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                        >
                            <option value="asc">Ascending</option>
                            <option value="desc">Descending</option>
                        </select>
                    </div>
                </div>
            </div>

            {/*Search + Category */}
            <div className="flex-none p-6 pt-3 pb-2 flex gap-3">
                {/* Search */}
                <div className="relative flex-1">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                        <svg className="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                            <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
                        </svg>
                    </div>

                    <input
                        type="text"
                        className="block w-full rounded-md border-0 py-3 pl-10 pr-4 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-blue-600 sm:text-lg"
                        placeholder="Search by item no., brand description, vendor name, brand code, or UOM description..."
                        value={searchQuery || ''}
                        onChange={(e) => onSearchChange?.(e.target.value)}
                    />
                </div>

                {/*Category Dropdown */}
                <select
                    value={selectedCategory}
                    onChange={(e) => setSelectedCategory(e.target.value)}
                    className="w-44 rounded-md border-gray-300 shadow-sm text-sm focus:ring-blue-500 focus:border-blue-500"
                >
                    <option value="ALL">All</option>
                    {categories.map((category) => (
                        <option key={category} value={category}>{category}</option>
                    ))}
                </select>
            </div>

            {/* Empty State */}
            {(!items || items.length === 0) && !isLoadingItems && (
                <div className="flex flex-1 items-center justify-center p-8 text-center text-gray-500">
                    <div>
                        <h3 className="text-lg font-medium text-gray-900">
                            {normalizedSearchQuery ? 'No matches found' : 'No items available'}
                        </h3>
                    </div>
                </div>
            )}

            {/* No Results */}
            {items && items.length > 0 && filteredItems.length === 0 && (
                <div className="flex flex-1 items-center justify-center p-8 text-center text-gray-500">
                    <div>
                        <h3 className="text-lg font-medium text-gray-900">No matches found</h3>
                        <p className="mt-1">Try adjusting your filters</p>
                    </div>
                </div>
            )}

            {/* Items */}
            {(sortedItems.length > 0 || isLoadingItems) && (
                <div className="flex-1 overflow-y-auto p-6 pt-4" onScroll={handleScroll}>
                    <div className="flex flex-col gap-2">
                        {sortedItems.map((item) => (
                            <ItemTile key={item.lineId || item.id} item={item} onAddToCart={onAddToCart} />
                        ))}
                        {isLoadingItems && (
                            <div className="py-4 text-center text-sm text-gray-500">
                                Loading items...
                            </div>
                        )}
                        {!isLoadingItems && sortedItems.length > 0 && !hasMoreItems && (
                            <div className="py-3 text-center text-xs text-gray-400">
                                End of list
                            </div>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
}
