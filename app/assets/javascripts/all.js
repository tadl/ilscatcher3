var ready;
ready = function() {
    $(".tall-carousel").owlCarousel({
        items : 9,
        paginationNumbers : true,
        itemsDesktop : [1199,7],
        itemsDesktopSmall : [980,5],
        itemsTablet: [768,4],
        itemsMobile : [479,2],
        itemsScaleUp : false,
    });
    $(".square-carousel").owlCarousel({
        items : 7,
        paginationNumbers : true,
        itemsDesktop : [1199,5],
        itemsDesktopSmall : [980,3],
        itemsTablet: [768,3],
        itemsTabletSmall: false,
        itemsMobile : [479,1],
    });
    $('[data-toggle="tooltip"]').tooltip()
};

$(document).ready(ready);
$(document).on('page:load', ready);

function bind_more_results(){
    $('#more_results').bind('inview', function (event, visible, topOrBottomOrBoth) {
      if (visible == true) {
        // element is now visible in the viewport
        if (topOrBottomOrBoth == 'top' || 'bottom' || 'both') {
            $('#more_results').unbind('inview');
            $('#more_results:first a')[0].click();
        }
      }
    })
}




