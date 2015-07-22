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

function place_hold(id,button,force) {
    var record = id;
    force = typeof force !== 'undefined' ? force : false;
    var token = sessionStorage.getItem('token');
    var hold_params = {"token": token, "record_id": record};
    var jqxhr = $.ajax({
        method: 'POST',
        url: '/mock/place_hold',
        data: hold_params,
        dataType: "json",
        contentType: "application/x-www-form-urlencoded, charset=UTF-8",
        timeout: 15000
    }).done(function(data) {
        $('#statusMessage').modal('hide');
        if (data['user']['error'] == 'bad token' || data['hold_confirmation'] == 'bad login') {
            $.get("login.js", {update: "true"});
        } else if (data['hold_confirmation'][0]['error'] == true) {
            if (data['hold_confirmation'][0]['message'] == 'Hold was not successfully placed Problem: User already has an open hold on the selected item') {
                var message = "<div class='alert alert-warning'><i class='glyphicon glyphicon-exclamation-sign'></i> Oops! You already have a hold on this item.</div>";
                $(button).parent().html(message);
                $.get( "login.js", { "token": token, "update": "true" } );
            } else if (data['hold_confirmation'][0]['message'] == 'Hold was not successfully placed Problem: The item you have attempted to place on hold is already checked out to the requestor.') {
                var message = "<div class='alert alert-warning'><i class='glyphicon glyphicon-exclamation-sign'></i> Oops! You already have this item checked out. Please return the item before placing a hold on it again.</div>";
                $(button).parent().html(message);
                $.get( "login.js", { "token": token, "update": "true" } );
            } else if (data['hold_confirmation'][0]['message'] == 'Placing this hold could result in longer wait times.') {
                // complicated things
                // and this is why we should do this with a template:
                $(button).parent().empty();
                $('#hold-confirm-force').modal('show');
            }
        } else {
            var message = "<div class='alert alert-success'><i class='glyphicon glyphicon-ok-sign'></i> Your hold was successfully placed.</div>";
            $(button).parent().html(message);
            $.get( "login.js", { "token": token, "update": "true" } );
        }
    }).fail(function() {
        $('#statusMessage').modal('hide');
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
                $('#statusMessage').modal('show');
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
                        $('#statusMessage').modal('hide');
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
                    $('#statusMessage').modal('hide');
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
            $('#statusMessage').modal('show');
            $(thebutton).text('Placing hold...');
            place_hold(recordid,thebutton);
        }
    });
}

function update_login(){
    var full_name = sessionStorage.getItem('full_name');
    var holds = sessionStorage.getItem('holds');
    var holds_ready = sessionStorage.getItem('holds_ready');
    var checkouts = sessionStorage.getItem('checkouts');
    var fine = sessionStorage.getItem('fine');
    $('#full_name').text(full_name);
    $('#holds').text(holds);
    $('#holds_ready').text(holds_ready);
    $('#checkouts').text(checkouts);
    $('#fine').text(fine);
}

function login() {
    $('#statusMessage').modal('show');
    var username = $('#username').val();
    var password = $('#password').val();
    $.post("login.js", {username: username, password: password, update: "true"});
}

function logout() {
    sessionStorage.clear();
    delete_cookie('login');
    $.get("login.js", {update: "true"});
}

function delete_cookie(name) {
    document.cookie = name + '=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
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
