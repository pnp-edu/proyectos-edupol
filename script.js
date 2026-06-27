document.addEventListener('DOMContentLoaded', () => {
    // Filter chips interaction
    const filterChips = document.querySelectorAll('.filter-chip');
    
    filterChips.forEach(chip => {
        chip.addEventListener('click', () => {
            // Remove active class from all
            filterChips.forEach(c => c.classList.remove('active'));
            // Add active to clicked
            chip.classList.add('active');
        });
    });

    // Horizontal scrolling with mouse wheel for app lists
    const appLists = document.querySelectorAll('.app-list');
    
    appLists.forEach(list => {
        list.addEventListener('wheel', (e) => {
            if (e.deltaY !== 0) {
                e.preventDefault();
                list.scrollLeft += e.deltaY;
            }
        });
    });
});
