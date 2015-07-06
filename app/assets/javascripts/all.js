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

    var offset = 450;
    var duration = 300;
    $(window).scroll(function() {
        if ($(this).scrollTop() > offset) {
            $('.back-to-top').fadeIn(duration);
        } else {
            $('.back-to-top').fadeOut(duration);
        }
    });
    $('.back-to-top').click(function(event) {
        event.preventDefault();
        $('html, body').animate({scrollTop: 0}, duration);
        return false;
    });

};

$(document).ready(ready);
$(document).on('page:load', ready);

/* add a class to the body when ajax is happening */
$(document).ajaxStart(function () {
    $('body').addClass('wait');
}).ajaxComplete(function () {
    $('body').removeClass('wait');
});

function bind_more_results(){
    $('#more_results').bind('inview', function (event, visible, topOrBottomOrBoth) {
      if (visible == true) {
        // element is now visible in the viewport
        if (topOrBottomOrBoth == 'top') {
            $('#more_results').unbind('inview');
            $('#more_results:first a')[0].click();
            $('#load_more_text').html("Loading More Results...")
        }
      }
    })
}
