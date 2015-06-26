var ready;
ready = function() {
    $(".tall-carousel").owlCarousel({
        items : 9,
        paginationNumbers : true,
    });
    $(".square-carousel").owlCarousel({
        items : 7,
        paginationNumbers : true,
    });
};

$(document).ready(ready);
$(document).on('page:load', ready);
