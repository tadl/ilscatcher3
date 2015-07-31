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
    slider_image_binds();

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

function slider_image_binds() {
    $('.carousel-item').click(function(event) {
        $(this).addClass('zoom');
    });
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
    target_button = '.hold-' + id;
    target_div = '.hold-status-' + id;
    login_div = '.holdlogin-' + id;
    if (logged_in == null) {
        $(login_div).show();
        $(target_button).hide();
    } else {
        $(target_button).hide();
        $(target_div).html('<div class="alert alert-info">'+spinner+'Placing hold...</div>');
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

function login(id) {
    if (typeof id !== 'undefined') { var do_hold = id; } else { var do_hold = 0; }
    $('#statusMessage').modal('show');
    if (do_hold != 0) {
        var username = $('.holdloginuser-'+id).val()
        var password = $('.holdloginpass-'+id).val()
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
            $('.holdloginuser-'+id).val('');
            $('.holdloginpass-'+id).val('');
            $('#statusMessage').modal('hide');
            alert_message('danger', 'There was a problem with your username or password. #TODO');
        } else {
            if (do_hold != 0) {
                $('.holdlogin-'+id).hide();
                target = '.hold-status-' + id;
                message = '<div class="alert alert-info">'+spinner+'Logged in, placing hold now...</div>';
                $(target).html(message)
                $.get("place_hold.js", {record_id: id});
            }
        }
    });
}

function login_cancel(id) {
    if (typeof id !== 'undefined') { var id = id; } else { var id = 0; }
    $('.holdlogin-'+id).hide();
    $('.hold-'+id).show();
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
    $('.hold-manage').unbind('click');
    $('.hold-cancel').unbind('click');
    $('.hold-suspend').unbind('click');
    $('.hold-activate').unbind('click');

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
    $('.checkout-renew').unbind('click');
    $('.checkout-renew').click(function(event) {
        $(this).text('Renewing').prepend(spinner);
    });
}

/* details button watcher */
function detect_details_click() {
    $('.details-button').unbind('click');
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

/* account preferences watchers */
function account_prefs_binds() {
    $('.edit-circulation-prefs').unbind('click');
    $('.edit-circulation-prefs').click(function(event) {
        event.preventDefault();
        var circpanel = $('#panel-circulation-prefs').html();
        var plv = $('#pickup_library-value').text();
        var plvhtml = '<select id="plv" name="pickup_library" class="form-control">';
        plvhtml += '<option value="23"' + (plv == 'Woodmere' ? ' selected' : '') + '>Woodmere</option>';
        plvhtml += '<option value="24"' + (plv == 'Interlochen' ? ' selected' : '') + '>Interlochen</option>';
        plvhtml += '<option value="25"' + (plv == 'Kingsley' ? ' selected' : '') + '>Kingsley</option>';
        plvhtml += '<option value="26"' + (plv == 'Peninsula' ? ' selected' : '') + '>Peninsula</option>';
        plvhtml += '<option value="27"' + (plv == 'Fife Lake' ? ' selected' : '') + '>Fife Lake</option>';
        plvhtml += '<option value="28"' + (plv == 'East Bay' ? ' selected' : '') + '>East Bay</option>';
        plvhtml += '</select>';
        $('#pickup_library-value').html(plvhtml);

        var chv = $('#keep_circ_history-value').text();
        var chvhtml = '<input id="chv" name="circulation_history" class="form-control" type="checkbox"' + (chv == 'true' ? ' checked' : '') + '>';
        $('#keep_circ_history-value').html(chvhtml);

        var hhv = $('#keep_hold_history-value').text();
        var hhvhtml = '<input id="hhv" name="hold_history" class="form-control" type="checkbox"' + (hhv == 'true' ? ' checked' : '') + '>';
        $('#keep_hold_history-value').html(hhvhtml);

        var dsv = $('#default_search-value').text();
        var dsvhtml = '<select id="dsv" name="default_search" class="form-control">';
        dsvhtml += '<option value="22"' + (dsv == 'All Locations' ? 'selected' : '') + '>All Locations</option>';
        dsvhtml += '<option value="23"' + (dsv == 'Woodmere' ? 'selected' : '') + '>Woodmere</option>';
        dsvhtml += '<option value="24"' + (dsv == 'Interlochen' ? 'selected' : '') + '>Interlochen</option>';
        dsvhtml += '<option value="25"' + (dsv == 'Kingsley' ? 'selected' : '') + '>Kingsley</option>';
        dsvhtml += '<option value="26"' + (dsv == 'Peninsula' ? 'selected' : '') + '>Peninsula</option>';
        dsvhtml += '<option value="27"' + (dsv == 'Fife Lake' ? 'selected' : '') + '>Fife Lake</option>';
        dsvhtml += '<option value="28"' + (dsv == 'East Bay' ? 'selected' : '') + '>East Bay</option>';
        dsvhtml += '</select>';
        $('#default_search-value').html(dsvhtml);

        var editbutton = $('#circ-prefs-buttons').html();
        var savecancelbuttons = '<a href="#" class="btn btn-danger btn-xs cancel-circulation-prefs">Cancel</a>';
        savecancelbuttons += '<a href="#" class="btn btn-success btn-xs save-circulation-prefs">Save</a>';

        $('#circ-prefs-buttons').html(savecancelbuttons);

        /* cancel button replaces the panel div with original content and rebinds edit button */
        $('.cancel-circulation-prefs').click(function(e) {
            e.preventDefault();
            $('#panel-circulation-prefs').html(circpanel);
            account_prefs_binds();
        });

        $('.save-circulation-prefs').click(function(e) {
            e.preventDefault();
            var plv = $('#plv').val();
            var chv = $('#chv').prop('checked');
            var hhv = $('#hhv').prop('checked');
            var dsv = $('#dsv').val();
            console.log(plv + '|' + chv + '|' + hhv + '|' + dsv);
        });

    });


    $('.edit-user-prefs').unbind('click');
    $('.edit-user-prefs').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();

        var uv = $('#username-value').text();
        var uvhtml = '<input id="uv" name="up-username" class="form-control" type="text" value="'+uv+'">';
        $('#username-value').html(uvhtml);

        var hsav = $('#hold_shelf_alias-value').text();
        var hsavhtml = '<input id="hsav" name="up-hold_shelf_alias" class="form-control" type="text" value="'+hsav+'">';
        $('#hold_shelf_alias-value').html(hsavhtml);

        var ev = $('#email-value').text();
        var evhtml = '<input id="ev" name="up-email" class="form-control" type="text" value="'+ev+'">';
        $('#email-value').html(evhtml);

        var editbutton = $('#user-prefs-buttons').html();
        var savecancelbuttons = '<a href="#" class="btn btn-danger btn-xs cancel-user-prefs">Cancel</a>';
        savecancelbuttons += '<a href="#" class="btn btn-success btn-xs save-user-prefs">Save</a>';
        $('#user-prefs-buttons').html(savecancelbuttons);

        $('.cancel-user-prefs').click(function(e) {
            e.preventDefault();
            $('#panel-user-prefs').html(userpanel);
            account_prefs_binds();
        });

        $('.save-user-prefs').click(function(e) {
            e.preventDefault();
            var uv = $('#uv').val();
            var hsav = $('#hsav').val();
            var ev = $('#ev').val();
            console.log(uv + '|' + hsav + '|' + ev);
        });



    });

    $('.edit-notification-prefs').unbind('click');
    $('.edit-notification-prefs').click(function(event) {
        event.preventDefault();
        var notificationpanel = $('#panel-notification-prefs').html();

        var pnnv = $('#phone_notify_number-value').text();
        var pnnvhtml = '<input id="pnnv" name="np-phone_notify_number" class="form-control" type="text" value="'+pnnv+'">';
        $('#phone_notify_number-value').html(pnnvhtml);

        var tnnv = $('#text_notify_number-value').text();
        var tnnvhtml = '<input id="tnnv" name="np-text_notify_number" class="form-control" type="text" value="'+tnnv+'">';
        $('#text_notify_number-value').html(tnnvhtml);

        var env = $('#email_notify-value').text();
        var envhtml = '<input id="env" name="email_notify" class="form-control" type="checkbox"' + (env == 'true' ? ' checked' : '') + '>';
        $('#email_notify-value').html(envhtml);

        var pnv = $('#phone_notify-value').text();
        var pnvhtml = '<input id="pnv" name="phone_notify" class="form-control" type="checkbox"' + (pnv == 'true' ? ' checked' : '') + '>';
        $('#phone_notify-value').html(pnvhtml);

        var tnv = $('#text_notify-value').text();
        var tnvhtml = '<input id="tnv" name="text_notify" class="form-control" type="checkbox"' + (tnv == 'true' ? ' checked' : '') + '>';
        $('#text_notify-value').html(tnvhtml);


        var editbutton = $('#notification-prefs-buttons');
        var savecancelbuttons = '<a href="#" class="btn btn-danger btn-xs cancel-notification-prefs">Cancel</a>';
        savecancelbuttons += '<a href="#" class="btn btn-success btn-xs save-notification-prefs">Save</a>';
        $('#notification-prefs-buttons').html(savecancelbuttons);

        $('.cancel-notification-prefs').click(function(e) {
            e.preventDefault();
            $('#panel-notification-prefs').html(notificationpanel);
            account_prefs_binds();
        });
        $('.save-notification-prefs').click(function(e) {
            e.preventDefault();
            var pnnv = $('#pnnv').val();
            var tnnv = $('#tnnv').val();
            var env = $('#env').prop('checked');
            var pnv = $('#pnv').prop('checked');
            var tnv = $('#tnv').prop('checked');
            console.log(pnnv + '|' + tnnv + '|' + env + '|' + pnv + '|' + tnv);
        });

    });
}

