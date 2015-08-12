/* global variables */
var spinner = '<span class="glyphicon glyphicon-asterisk gly-spin"></span> ';
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
        $('#keep_circ_history-value').parent().html(chvhtml);

        var hhv = $('#keep_hold_history-value').text();
        var hhvhtml = '<input id="hhv" name="hold_history" class="form-control" type="checkbox"' + (hhv == 'true' ? ' checked' : '') + '>';
        $('#keep_hold_history-value').parent().html(hhvhtml);

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

        $('#circ-prefs-buttons').empty();
        $('#circ-prefs-footer').show();

        /* cancel button replaces the panel div with original content and rebinds edit button */
        $('.cancel-circulation-prefs').click(function(e) {
            e.preventDefault();
            $('#panel-circulation-prefs').html(circpanel);
            account_prefs_binds();
        });

        $('.save-circulation-prefs').click(function(e) {
            e.preventDefault();
            var newplv = $('#plv').val();
            var newchv = $('#chv').prop('checked');
            var newhhv = $('#hhv').prop('checked');
            var newdsv = $('#dsv').val();
            $('.save-circulation-prefs').html(spinner + ' Saving...');
            $.post("/mock/update_search_history", {default_search: newdsv, pickup_library: newplv, keep_circ_history: on_off(newchv), keep_hold_history: on_off(newhhv)})
                .done(function(data) {
                    alert_message('success', 'Settings updated.', 20000);
                    $('.save-circulation-prefs').text('Saved!');
                    location.reload();
            });
        });
    });

    $('.edit-user-user').unbind('click');
    $('.edit-user-user').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();

        var uv = $('#username-value').text();
        var uvhtml = '<input id="uv" name="up-username" class="form-control" type="text" value="'+uv+'">';
        $('#username-value').html(uvhtml);

        $('#user-prefs-password').show();
        $('#user-prefs-footer').show();
        $('.edit-user-user').hide();

        user_prefs_cancel_bind(userpanel);
        user_username_save_bind();


    });

    $('.edit-user-alias').unbind('click');
    $('.edit-user-alias').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();

        var hsav = $('#hold_shelf_alias-value').text();
        var hsavhtml = '<input id="hsav" name="up-hold_shelf_alias" class="form-control" type="text" value="'+hsav+'">';
        $('#hold_shelf_alias-value').html(hsavhtml);

        $('#user-prefs-password').show();
        $('#user-prefs-footer').show();
        $('.edit-user-alias').hide();

        user_prefs_cancel_bind(userpanel);
        user_alias_save_bind();

    });

    $('.edit-user-email').unbind('click');
    $('.edit-user-email').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();

        var ev = $('#email-value').text();
        var evhtml = '<input id="ev" name="up-email" class="form-control" type="text" value="'+ev+'">';
        $('#email-value').html(evhtml);

        $('#user-prefs-password').show();
        $('#user-prefs-footer').show();
        $('.edit-user-email').hide();

        user_prefs_cancel_bind(userpanel);
        user_email_save_bind();

    });
/* later
    $('.edit-user-password').unbind('click');
    $('.edit-user-password').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();
        user_prefs_cancel_bind(userpanel);
    }); */

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
        $('#email_notify-value').parent().html(envhtml);

        var pnv = $('#phone_notify-value').text();
        var pnvhtml = '<input id="pnv" name="phone_notify" class="form-control" type="checkbox"' + (pnv == 'true' ? ' checked' : '') + '>';
        $('#phone_notify-value').parent().html(pnvhtml);

        var tnv = $('#text_notify-value').text();
        var tnvhtml = '<input id="tnv" name="text_notify" class="form-control" type="checkbox"' + (tnv == 'true' ? ' checked' : '') + '>';
        $('#text_notify-value').parent().html(tnvhtml);

        $('#notification-prefs-buttons').empty();
        $('#notification-prefs-footer').show();

        $('.cancel-notification-prefs').click(function(e) {
            e.preventDefault();
            $('#panel-notification-prefs').html(notificationpanel);
            account_prefs_binds();
        });

        $('.save-notification-prefs').click(function(e) {
            e.preventDefault();
            $('.save-notification-prefs').html(spinner+' Saving...');
            var pnnv = $('#pnnv').val();
            var tnnv = $('#tnnv').val();
            var env = on_off($('#env').prop('checked'));
            var pnv = on_off($('#pnv').prop('checked'));
            var tnv = on_off($('#tnv').prop('checked'));
            $.post("/mock/update_notifications", {email_notify: env, phone_notify: pnv, text_notify: tnv, phone_notify_number: pnnv, text_notify_number: tnnv})
            .done(function(data) {
                alert_message('success','Notification preferences saved.',10000);
                $('.cancel-notification-prefs').click();
                location.reload();
            });
        });
    });
}

/* helper functions for account prefs binds */
function on_off (val) {
    return val == true ? 'on' : 'off';
}

function location_map (name) {
    var locations = {
        "All Locations": 22,
        "Woodmere": 23,
        "Interlochen": 24,
        "Kingsley": 25,
        "Peninsula": 26,
        "Fife Lake": 27,
        "East Bay": 28
    };
    return locations[name];
}

function user_prefs_cancel_bind(panelhtml) {

    $('.cancel-user-prefs').unbind('click');
    $('.cancel-user-prefs').click(function(e) {
        e.preventDefault();
        $('#panel-user-prefs').html(panelhtml);
        account_prefs_binds();
    });
}

function user_username_save_bind() {
    $('.save-user-prefs').unbind('click');
    $('.save-user-prefs').click(function(e) {
        e.preventDefault();
        $('.save-user-prefs').html(spinner+' Saving...');
        var newusername = $('#uv').val();
        var up = $('#up-password').val();
        console.log('update username value');
        $.post("/mock/update_user_info", {username: newusername, password: up})
        .done(function(data) {
            if (data.message == 'bad password') {
                alert_message('danger', 'Sorry, there was a problem with your password. Please try again.', 10000);
            } else if (data.message == 'password required') {
                alert_message('danger', 'You must enter your password to make this change. Please try again.', 10000);
            } else if (data.message == 'username is already taken') {
                alert_message('danger', 'Sorry, that username is already taken. Please try another.', 10000);
            } else if (data.message == 'success') {
                alert_message('success', 'Username successfully changed.', 10000);
                location.reload();
            } else {
                alert_message('info', data.message, 10000);
            }
            $('.cancel-user-prefs').click();
        });
    });
}

function user_alias_save_bind() {
    $('.save-user-prefs').unbind('click');
    $('.save-user-prefs').click(function(e) {
        e.preventDefault();
        $('.save-user-prefs').html(spinner+' Saving...');
        var up = $('#up-password').val();
        var newalias = $('#hsav').val();
        console.log('update hold shelf alias value');
        $.post("/mock/update_user_info", {hold_shelf_alias: newalias, password: up})
        .done(function(data) {
            if (data.message == 'bad password') {
                alert_message('danger', 'Sorry, there was a problem with your password. Please try again.', 10000);
            } else if (data.message == 'password required') {
                alert_message('danger', 'You must enter your password to make this change. Please try again.', 10000);
            } else if (data.message == 'alias in use') {
                alert_message('danger', 'Sorry, that alias is already taken. Please try another.', 10000);
            } else if (data.message == 'success') {
                alert_message('success', 'Alias successfully changed.', 10000);
                location.reload();
            } else {
                alert_message('info', data.message, 10000);
            }
            $('.cancel-user-prefs').click();
        });
    });
}

function user_email_save_bind() {
    $('.save-user-prefs').unbind('click');
    $('.save-user-prefs').click(function(e) {
        e.preventDefault();
        $('.save-user-prefs').html(spinner+' Saving...');
        var up = $('#up-password').val();
        var newemail = $('#ev').val();
        console.log('update email value');
        $.post("/mock/update_user_info", {email: newemail, password: up})
        .done(function(data) {
            if (data.message == 'bad password') {
                alert_message('danger', 'Sorry, there was a problem with your password. Please try again.', 10000);
            } else if (data.message == 'password required') {
                alert_message('danger', 'You must enter your password to make this change. Please try again.', 10000);
            } else if (data.message == 'invalid email address') {
                alert_message('danger', 'Sorry, that is not a valid email address. Please try entering it again.', 10000);
            } else if (data.message == 'success') {
                alert_message('success', 'Email address successfully changed.', 10000);
                location.reload();
            } else {
                alert_message('info', data.message, 10000);
            }
            $('.cancel-user-prefs').click();
        });
    });
}

function item_select(id) {
    if (typeof ids !== 'object') ids = [];
    var index = $.inArray(id, ids);
    var element = $('.select-'+id);
    var selectedText = '<span class="glyphicon glyphicon-ok"></span> Selected';
    var deselectedText = 'Select';
    if (index == -1) {
        ids.push(id);
        $(element).removeClass('btn-default select-btn').addClass('selected-btn btn-success').html(selectedText);
    } else {
        ids.splice(index, 1);
        $(element).removeClass('btn-success selected-btn').addClass('btn-default select-btn').html(deselectedText);
    }
    if ($.isEmptyObject(ids) === true) {
        delete window.ids;
    }
}

function checkout_select(cid,rid) {
    if (typeof cids !== 'object') cids = [];
    if (typeof rids !== 'object') rids = [];
    var cindex = $.inArray(cid, cids);
    var rindex = $.inArray(rid, rids);
    var element = $('.select-'+rid);
    var selectedText = '<span class="glyphicon glyphicon-ok"></span> Selected';
    var deselectedText = 'Select';
    if ((cindex == -1) && (rindex == -1)) {
        cids.push(cid);
        rids.push(rid);
        $(element).removeClass('btn-default select-btn').addClass('selected-btn btn-success').html(selectedText);
    } else {
        cids.splice(cindex, 1);
        rids.splice(rindex, 1);
        $(element).removeClass('btn-success selected-btn').addClass('btn-default select-btn').html(deselectedText);
    }
    console.log(rids);
    console.log(cids);
}

function bulk_action_binds() {
    $('#hold-bulk-suspend').unbind('click');
    $('#hold-bulk-suspend').click(function(e) {
        e.preventDefault();
        if (typeof ids !== 'undefined') {
            showLoading();
            $.post('/mock/manage_hold.js', {hold_id: ids.toString(), task: 'suspend'})
            .done(function() {
                hideLoading();
                delete window.ids;
            });
        } else {
            alert_message('warning', 'Error: You must select at least one item before performing bulk operations.', 15000);
        }
    });

    $('#hold-bulk-activate').unbind('click');
    $('#hold-bulk-activate').click(function(e) {
        e.preventDefault();
        if (typeof ids !== 'undefined') {
            showLoading();
            $.post('/mock/manage_hold.js', {hold_id: ids.toString(), task: 'activate'})
            .done(function() {
                hideLoading();
                delete window.ids;
            });
        } else {
            alert_message('warning', 'Error: You must select at least one item before performing bulk operations.', 15000);
        }
    });

    $('#hold-bulk-cancel').unbind('click');
    $('#hold-bulk-cancel').click(function(e) {
        e.preventDefault();
        if (typeof ids !== 'undefined') {
            showLoading();
            $.post('/mock/manage_hold.js', {hold_id: ids.toString(), task: 'cancel'})
            .done(function() {
                hideLoading();
                delete window.ids;
            });
        } else {
            alert_message('warning', 'Error: You must select at least one item before performing bulk operations.', 15000);
        }
    });

    $('#checkout-bulk-renew').unbind('click');
    $('#checkout-bulk-renew').click(function(e) {
        e.preventDefault();
        if ((typeof rids !== 'undefined') && (typeof cids !== 'undefined')) {
            showLoading();
            $.post('/mock/renew_checkouts.js', {checkout_ids: cids.toString(), record_ids: rids.toString()})
            .done(function() {
                hideLoading();
                delete window.cids;
                delete window.rids;
            });
        } else {
            alert_message('warning', 'Error: You must select at least one item before performing bulk operations.', 15000);
        }
    });
    
    $('#select-all').unbind('click');
    $('#select-all').click(function(e) {
        $('.select-btn').click();
    });

    $('#select-none').unbind('click');
    $('#select-none').click(function(e) {
        $('.selected-btn').click();
    });
}

