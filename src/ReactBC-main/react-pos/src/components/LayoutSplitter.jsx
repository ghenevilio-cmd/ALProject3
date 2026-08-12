export default function LayoutSplitter({ leftPanel, rightPanel }) {
    return (
        <div className="flex h-screen w-full overflow-hidden bg-gray-50">
            {/* 
        Responsive Split: 
        On very small screens, stack them.
        On large screens (e.g. tablet POS), split 70% / 30% 
      */}
            <div className="flex flex-col lg:flex-row w-full h-full">
                {/* Left Side (Items Grid) */}
                <div className="flex-1 lg:w-[70%] h-[60vh] lg:h-full bg-gray-50 overflow-hidden relative z-0">
                    {leftPanel}
                </div>

                {/* Right Side (Cart Sidebar) */}
                <div className="w-full lg:w-[30%] min-w-[320px] max-w-[450px] h-[40vh] lg:h-full bg-white shadow-xl lg:shadow-[-4px_0_24px_-12px_rgba(0,0,0,0.1)] relative z-10 shrink-0">
                    {rightPanel}
                </div>
            </div>
        </div>
    );
}
