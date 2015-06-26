var ready;
ready = function() {
    $(".owl-carousel").owlCarousel();
};

$(document).ready(ready);
$(document).on('page:load', ready);
