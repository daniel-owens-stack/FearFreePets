// prevents header overlapping when using anchor tags
    jQuery('a[href^="#"]').on('click', function(e) {
    e.preventDefault(); // Prevent default anchor behavior

    var target = jQuery(this.hash);
    var offset = 20; // Adjust this value (in pixels) to control how far from the top

    if (target.length) {
        var targetPosition = target.offset().top - offset;
        jQuery('html, body').animate({
            scrollTop: targetPosition < 0 ? 0 : targetPosition // Ensures it won't scroll past the top
        }, 1000); // Adjust speed (1000 ms = 1 second)
    }
});