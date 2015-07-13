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

function showLoading() {
    $('#statusMessage').modal('show');
}
function hideLoading() {
    $('#statusMessage').modal('hide');
}

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:fetch', showLoading);
$(document).on('page:receive', hideLoading);

/* add a class to the body when ajax is happening */
/* unfortunately this is/was triggered by endless scroll functionality as
 * well, so this is not going to work out either.
 *
$(document).ajaxStart(function () {
    $('#statusMessageText').text('One moment...');
    $('#statusMessage').modal('show');
}).ajaxComplete(function () {
    $('#statusMessage').modal('hide');
});
 */

function bind_more_results(){
    $('#more_results').bind('inview', function (event, visible, topOrBottomOrBoth) {
      if (visible == true) {
        // element is now visible in the viewport
        if (topOrBottomOrBoth == 'top') {
            $('#more_results').unbind('inview');
            $('#more_results:first a')[0].click();
            var message = '<div class="alert alert-info"><i class="glyphicon glyphicon-search gly-spin"></i> Loading more results...</div>';
            $('#load_more_text').html(message)
        }
      }
    })
}

function place_hold(id,button) {
    var record = id;
    var token = sessionStorage.getItem('token');
    console.log('placing hold with token ' + token + ' on record id ' + record);
    var hold_params = {"token": token, "record_id": record};
    var jqxhr = $.ajax({
        method: 'POST',
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
            $(button).parent().html(message);
        } else {
            console.log(data['hold_confirmation'][0]['record_id'] + " " + data['hold_confirmation'][0]['message']);
            var message = "<div class='alert alert-success'><i class='glyphicon glyphicon-ok-sign'></i> Your hold was successfully placed.</div>";
            $(button).parent().html(message);
        }
    }).fail(function() {
        /* figure out where to write this message. probably an overlay div */
        var message = "<div class='alert alert-danger'><i class='glyphicon glyphicon-exclamation-sign'></i> Sorry, something went horribly wrong. Please try again.</div>";
        $(button).parent().html(message);
    });
}


function holdbutton_click() {
    $('.holdbtn').on("click", function() {
        var logged_in = sessionStorage.getItem('authed');
        var recordid = $(this).attr("id").split('-')[1];
        var thebutton = $(this);
        var buttondiv = $(this).parents().eq(1);
        var buttonhtml = $(this).parents().eq(1).html();
        if (logged_in == null) {
            var contents = $('#holdlogin').html();
            $('#holdlogin').empty();
            $(this).parent().html(contents);
            $("#holdloginsubmit").on("click", function() {
                var username = $('#holdloginuser').val();
                var password = $('#holdloginpass').val();
                $('#holdloginsubmit').text('Logging in...');
                if (username != null || username != '') { sessionStorage.setItem('username', username); }
                var login_params = {"username": username, "password": password};
                var jqxhr = $.ajax({
                    method: 'POST',
                    url: '/mock/login',
                    data: login_params,
                    dataType: "json",
                    contentType: "application/x-www-form-urlencoded, charset=UTF-8",
                    timeout: 15000
                }).done(function(data) {
                    if (data.error == 'bad username or password') {
                        $('#loginmessage').parent().html('<div id="loginmessage" class="alert alert-danger"><i class="glyphicon glyphicon-exclamation-sign"></i> There was a problem with your username or password. Please try again.</div>');
                        $('#holdloginsubmit').text('Log in and place hold');
                        $('#holdloginuser').val('');
                        $('#holdloginpass').val('');
                    } else {
                        sessionStorage.setItem('token', data.token);
                        sessionStorage.setItem('authed', "true");
                        var message = "<div class='alert alert-info'><i class='glyphicon glyphicon-sunglasses'></i> Placing hold...</div>";
                        $(buttondiv).html(message);
                        place_hold(recordid,buttondiv);
                    }
                }).fail(function() {
                    var message = "<div class='alert alert-danger'><i class='glyphicon glyphicon-exclamation-sign'></i> Sorry, something went horribly wrong. Please try again.</div>";
                    $(thebutton).parent().html(message);
                })
            });
            $("#holdlogincancel").on("click", function() {
                $(buttondiv).html(buttonhtml);
                $("#holdlogin").html(contents);
                holdbutton_click();
            });
        } else {
            $(thebutton).text('Placing hold...');
            place_hold(recordid,thebutton);
        }
    });
}
