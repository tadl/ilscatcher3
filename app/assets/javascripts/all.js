var spinner = '<span class="glyphicon glyphicon-cd gly-spin"></span> ';
var logged_in;
var ready;

ready = function() {
    /* for front page carousels */
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

    /* scroll to top button */
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

    hold_management_binds();
    checkout_management_binds();

    $('#search-button').click(function(event) {
        $(this).html(spinner);
    });

};

$(document).ready(ready);
$(document).on('page:load', ready);
$(document).on('page:fetch', showLoading);
$(document).on('page:receive', hideLoading);

function showLoading() {
    $('#statusMessage').modal('show');
}
function hideLoading() {
    $('#statusMessage').modal('hide');
}

function bind_more_results() {
    $('#more_results').bind('inview', function (event, visible, topOrBottomOrBoth) {
        if (visible == true) {
            // element is now visible in the viewport
            if (topOrBottomOrBoth == 'top') {
                $('#more_results').unbind('inview');
                $('#more_results:first a')[0].click();
                var message = '<div class="alert alert-info"><div class="center-text">Loading more results...</div><div class="progress"><div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="100" aria-valuemax="100" style="width:100%"></div></div></div>';
                $('#load_more_text').html(message)
            }
        }
    });
}

function place_hold(id) {
    // #TODO force holds
    var logged_in = Cookies.get('login');
    target_button = '.record-' + id;
    target_div = '.hold-status-' + id;
    if (logged_in == null) {
        $('#holdlogin').show();
        $(target_button).hide();
    } else {
        $(target_button).hide();
        $(target_div).html('<div class="alert alert-info">'+spinner+'Placing hold</div>');
        $.get("place_hold.js", {record_id: id});
    }
}

function update_login() {
    var cookie_data = JSON.parse(Cookies.get('user'))
    var full_name = cookie_data.full_name.replace('+',' ')
    var holds = cookie_data.holds
    var holds_ready = cookie_data.holds_ready
    var checkouts = cookie_data.checkouts
    var fine = cookie_data.fine
    $('#full_name').text(full_name)
    $('#holds').text(holds)
    $('#holds_ready').text(holds_ready)
    $('#checkouts').text(checkouts)
    $('#fine').text(fine)
}

function login_for_hold(id) { // #TODO remove this because it's unused
    $('#statusMessage').modal('show');
    var username = $('#holdloginuser').val()
    var password = $('#holdloginpass').val()
    $.get("login.js", {username: username, password: password}).done(function(data){
        if (data.error == 'bad username or password') {
            $('#statusMessage').modal('hide')
            $('#holdloginuser').val('')           
            $('#holdloginpass').val('')
            alert('bad login')
        } else {
            $('#statusMessage').modal('hide')
            $('#holdlogin').hide()
            target = '.hold-status-' + id
            $(target).html('getting your hold')
            $.get("place_hold.js", {record_id: id})
        }
    })
}

function login(id) {
    if (typeof id !== 'undefined') { var do_hold = id; } else { var do_hold = 0; }
    $('#statusMessage').modal('show');
    if (do_hold != 0) {
        var username = $('#holdloginuser').val()
        var password = $('#holdloginpass').val()
    } else {
        var username = $('#username').val();
        var password = $('#password').val();
    }
    $.post("login.js", {username: username, password: password})
    .done(function(data) {
        $('#statusMessage').modal('hide')
        if (data.error == 'bad username or password') {
            $('#username').val('');
            $('#password').val('');
            $('#holdloginuser').val('')           
            $('#holdloginpass').val('')
            $('#statusMessage').modal('hide');
            alert_message('danger', 'There was a problem with your username or password. #TODO');
        } else {
            if (do_hold != 0) {
                $('#holdlogin').hide();
                target = '.hold-status-' + id;
                $(target).html('getting your hold');
                $.get("place_hold.js", {record_id: id});
            }
        }
    });
}

function login_cancel(id) {
    if (typeof id !== 'undefined') { var id = id; } else { var id = 0; }
    $('#holdlogin').hide();
    $('.record-'+id).show();
}

function alert_message(type, message, timeout) {
    if (!type.match(/success|info|warning|danger/)) { return; }
    var timestamp = Date.now();
    var iconmap = {success:"ok-sign", info:"info-sign", warning:"question-sign", danger:"remove-sign"};
    if (message == undefined) { return; }
    if (timeout == undefined) { var timeout = 30000; }
    var contents = '<div class="alert alert-' + type + ' alert-dismissible fade in" role="alert" id="alertmessage'+timestamp+'">';
        contents += '<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>';
        contents += '<h4 class="padtop">';
        contents += '<span class="glyphicon glyphicon-' + iconmap[type] + '"></span> ';
        contents += '<span id="alert_message">' + message + '</span>';
        contents += '</h4>';
    contents += '</div>';
    $('#alert_target').append(contents);
    window.setTimeout(function() {
        $('#alertmessage'+timestamp).alert('close');
    }, timeout);
}

/* hold management watchers */
// #TODO all of the .click(function())s should be .on('click', function()...)s
function hold_management_binds() {
    $('.hold-manage').click(function(event) {
        event.preventDefault();
        $(this).removeClass('hold-manage btn-primary').addClass('hold-cancel btn-danger').text('Confirm Cancel').unbind('click');
        hold_management_binds();
        return false;
    });
    $('.hold-cancel').click(function(event) {
        $(this).text('Canceling').prepend(spinner);
    });
    $('.hold-suspend').click(function(event) {
        $(this).text('Suspending').prepend(spinner);
    });
    $('.hold-activate').click(function(event) {
        $(this).text('Activating').prepend(spinner);
    });
}

/* checkout management watchers */
function checkout_management_binds() {
    $('.checkout-renew').click(function(event) {
        $(this).text('Renewing').prepend(spinner);
    });
}

/* details button watcher */
function detect_details_click() {
    $('.details-button').click(function(event) {
        $(this).html(spinner+'Loading Details');
    });
}

/* force hold button watcher */
function force_hold_click(id) {
    $('#force-hold').click(function(event) {
        $('#hold-confirm-force').modal('hide');
        $('#statusMessage').modal('show');
        place_hold(id,null,true);
    });
}

/* password reset function */
function passwordReset() {
    var username = $('#passuser').val();
    var icurl = 'https://apiv2.catalog.tadl.org/account/password_reset';
    $('#passReset').modal('hide');
    showLoading();
    $.get(icurl + '?username=' + username)
        .done(function(data) {
            hideLoading();
            if (data.message == 'complete') {
                alert_message('success', 'Password reset request was received.<br/>Please check your e-mail for further instructions.', 60000);
            } else {
                alert_message('danger', 'Sorry, something went wrong. Please try that again.<br/>Ask a library staff member for assistance if the problem persists. Thank you.', 60000);
            }
        });
}
