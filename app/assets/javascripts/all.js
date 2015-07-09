var logged_in;
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

function place_hold(id) {
    var record = id;
    var token = sessionStorage.getItem('token') + 'asdf';
    console.log('placing hold with token ' + token + ' on record id ' + record);
    var hold_params = {"token": token, "record_id": record};
    var jqxhr = $.ajax({
        method: 'GET',
        url: '/mock/place_hold',
        data: hold_params,
        dataType: "json",
        contentType: "application/x-www-form-urlencoded, charset=UTF-8",
        timeout: 15000
    }).done(function(data) {
        if (data['user']['error'] == 'bad token' || data['hold_confirmation'] == 'bad login') {
            /* somehow we failed. we should refresh_login probably */
        } else if (data['hold_confirmation'][0]['message'] == 'Hold was not successfully placed Problem: User already has an open hold on the selected item') {
            var message = "<div class='alert alert-warning'><i class='glyphicon glyphicon-exclamation-sign'></i> Oops! You already have a hold on this item.</div>";
            $('#record-' + record).parent().html(message);
        } else {
            console.log(data['hold_confirmation'][0]['record_id'] + " " + data['hold_confirmation'][0]['message']);
            var message = "<div class='alert alert-success'><i class='glyphicon glyphicon-ok-sign'></i> Your hold was successfully placed.</div>";
            $('#record-' + record).parent().html(message);
        }
    }).fail(function() {
        /* figure out where to write this message. probably an overlay div */
        $('#loginmessage').text('Sorry, something went wrong. Please try again.');
    });
}

