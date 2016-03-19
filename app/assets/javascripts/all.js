/* global variables */
var spinner = '<span class="glyphicon glyphicon-asterisk gly-spin"></span> ';
var ready;

ready = function() {
    /* for front page carousels */
    $.getScript('/assets/salvattore.min.js');
    $(".tall-carousel").owlCarousel({
        items : 9,
        paginationNumbers : true,
        itemsDesktop : [1199,7],
        itemsDesktopSmall : [980,5],
        itemsTablet: [768,4],
        itemsMobile : [479,2],
        itemsScaleUp : false,
        lazyLoad : true,
    });
    $(".square-carousel").owlCarousel({
        items : 6,
        paginationNumbers : true,
        itemsDesktop : [1199,5],
        itemsDesktopSmall : [980,3],
        itemsTablet: [768,3],
        itemsTabletSmall: false,
        itemsMobile : [479,2],
        lazyLoad : true,
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

    $('.autoload').on('change', function() {
        this.form.submit();
    })

    $('#acctreg').on('click', function() {
        window.location = '/main/register';
    })

    $('a.navi').on('click', function() {
        showLoading();
    });

    $(document).on('click', '.item_details_link', function(e) {
        if (e.which == 1) {
            e.preventDefault();
        }
    });


    $(document).keydown(function(e){
        if (e.which == 37 && $('#previous_link').is(':visible')){ 
            $('#previous_link').click()
        }
        if (e.which == 39 && $('#next_link').is(':visible')){ 
            $('#next_link').click()
        }
    });


    hold_management_binds();
    checkout_management_binds();
    check_images();
};





$(document).ready(ready);

function showLoading() {
    $('#statusMessage').modal('show');
}
function hideLoading() {
    $('#statusMessage').modal('hide');
}

function item_loading_binds() {
    $('a.navi').on('click', function() {
        showLoading();
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

function place_hold(id,force) {
    if (typeof force !== 'undefined') { var force_hold = force; } else { var force_hold = false; }
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
        if (force_hold == true) {
            $.get("place_hold.js", {record_id: id, force: "true"});
        } else {
            $.get("place_hold.js", {record_id: id});
        }
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

function store_lists() {
    $.get('/main/lists.json')
    .done(function(data) {
        if (data.lists) {
            Cookies("lists", JSON.stringify(data.lists));
        }
    });
}

function is_my_list(list_id) {
    var lists = JSON.parse(Cookies.get('lists'))
    var return_value = false
    $.each(lists, function(i, list) {
        if(list.list_id == list_id) {
            return_value = true
        }
    });
    return return_value
}

function show_edit_list(list_id) {
    var show_div = '#edit_details_' + list_id
    var hide_div = '#list_details_' + list_id
    var hide_link = '#link_edit_details_' + list_id
    $(show_div).show();
    $(hide_div).hide();
    $(hide_link).hide();
}

function hide_edit_list(list_id) {
    var hide_div = '#edit_details_' + list_id
    var show_div = '#list_details_' + list_id
    var show_link = '#link_edit_details_' + list_id
    $(hide_div).hide();
    $(show_div).show();
    $(show_link).show();
}

function edit_list(list_id) {
    var new_title = encodeURIComponent($('#edit_list_title_' + list_id).val())
    var new_description = encodeURIComponent($('#edit_list_description_' + list_id).val())
    var url = '/main/edit_list?list_id=' + list_id + '&name=' + new_title + '&description=' + new_description
    if (new_title == '') {
        alert_message("danger","list must have title")
    } else {
        showLoading();
        $.get(url)
        .done(function(data) {
            hideLoading();
            if (data.message == 'success') {
                location.reload();
            }
        });
    }
}

function create_new_list() {
    var list_title = encodeURIComponent($('#new_list_title').val())
    var list_description = encodeURIComponent($('#new_list_description').val())
    if ($("#new_list_private").prop('checked')) {
        var list_privacy = "no";
    } else {
        var list_privacy = "yes";
    }
    var url = '/main/create_list?name=' + list_title + '&description=' + list_description + '&shared=' + list_privacy
    if (list_title == '') {
        alert_message("danger","list must have title")
    } else {
        showLoading();
        $.get(url)
        .done(function(data) {
            if (data.message == 'success') {
                location.reload();
            }
        });
    }
}

function show_create_list() {
    $('#new_list_form').show();
    $('#new_list_link').hide();
}

function hide_create_list() {
    $('#new_list_form').hide();
    $('#new_list_link').show();
}

function delete_list(list_id) {
    var button = '#delete_button_' + list_id;
    $(button).removeClass('btn-default').addClass('btn-danger').html('Click to Confirm').attr("onclick","actually_delete_list(" + list_id + ")");
}

function actually_delete_list(list_id) {
    showLoading();
    url = '/main/destroy_list?list_id=' + list_id
    $.get(url)
    .done(function(data) {
        if (data.message == 'success') {
            location.reload();
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
}

function set_default_list(list_id) {
    showLoading();
    url = '/main/make_default_list?list_id=' + list_id
    $.get(url)
    .done(function(data) {
        if (data.message == 'success') {
            location.reload();
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
}

function set_list_privacy(list_id, action) {
    showLoading();
    url = '/main/share_list?list_id='+ list_id +'&share='+ action
    $.get(url)
    .done(function(data) {
        if (data.message == 'success') {
            location.reload();
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
}

function add_to_list(list_id, record_id) {
    var button = '#add-list-' + record_id
    var buttondropdown = '#button-' + record_id
    $(button).html(spinner+'Adding...').addClass('disabled')
    url = '/main/add_item_to_list?list_id=' + list_id + '&record_id=' + record_id
    $.get(url)
    .done(function(data) {
        hideLoading();
        if (data.message == 'success') {
            $(button).html('Added').attr("onclick","");
            $(buttondropdown).addClass('disabled');
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
}

function remove_from_list(list_id, list_item_id) {
    var button = '#remove_button_' + list_item_id
    $(button).removeClass('btn-primary').addClass('btn-danger').html('Click to Confirm').attr("onclick","actually_remove_from_list(" + list_id + "," + list_item_id + ")");
}

function actually_remove_from_list(list_id, list_item_id) {
    showLoading();
    url = '/main/remove_item_from_list?list_id=' + list_id + '&list_item_id=' + list_item_id
    $.get(url)
    .done(function(data) {
        if (data.message == 'success') {
            location.reload();
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
}

function show_add_note(list_item_id) {
   var target_div = '#new_note_' + list_item_id
   $(target_div).show();
}

function hide_add_note(list_item_id) {
    var target_div = '#new_note_' + list_item_id
    $(target_div).hide();
}

function add_note(list_id, list_item_id) {
    var note_div = '#new_note_text_' + list_item_id
    var note_content = encodeURIComponent($(note_div).val());
    url = '/main/add_note_to_list?list_id=' + list_id + '&list_item_id=' + list_item_id + '&note=' + note_content
    showLoading();
    $.get(url)
    .done(function(data) {
        if (data.message == 'success') {
            location.reload();
        } else {
            hideLoading();
            alert_message("danger","The system encountered an error. Please make sure you are logged in, or try again later.")
        }
    });
}

function show_edit_note(note_id) {
    var div_to_show = '#edit_note_' + note_id
    var div_to_hide = '#note_' + note_id
    var link_to_hide = "#edit_note_link_" + note_id
    $(div_to_show).show();
    $(div_to_hide).hide();
    $(link_to_hide).hide();
}

function hide_edit_note(note_id) {
    var div_to_hide = '#edit_note_' + note_id
    var div_to_show = '#note_' + note_id
    var link_to_show = "#edit_note_link_" + note_id
    $(div_to_show).show();
    $(div_to_hide).hide();
    $(link_to_show).show();
}

function save_edited_note(list_id, note_id) {
    var note_div = '#edit_note_text_' + note_id
    var note_content = encodeURIComponent($(note_div).val());
    var replace_div = "#note_" + note_id
    var div_to_hide = '#edit_note_' + note_id
    var edit_note_link = "#edit_note_link_" + note_id
    url = '/main/edit_note?list_id=' + list_id + '&note_id=' + note_id + '&note=' + note_content
    showLoading();
    $.get(url)
    .done(function(data) {
        hideLoading();
        if (data.message == 'success') {
            if(note_content != '') {
                $(replace_div).text(decodeURIComponent(note_content))
                $(div_to_hide).hide();
                $(replace_div).show();
                $(edit_note_link).show();
            } else {
               $(div_to_hide).hide();
            }
        } else {
            alert_message("danger","The system encountered an error. Please make sure you are logged in, or try again later.")
        }
    });
}

function delete_edited_note(list_id, note_id) {
    var button = '#delete_note_' + note_id
    $(button).removeClass('btn-default').addClass('btn-danger').html('Click to Confirm').attr("onclick","actually_delete_edited_note(" + list_id + "," + note_id + ")");
}

function actually_delete_edited_note(list_id, note_id) {
    var note_div = '#edit_note_text_' + note_id
    var note_content = ''
    var replace_div = "#note_" + note_id
    var div_to_hide = '#edit_note_' + note_id
    var edit_note_link = "#edit_note_link_" + note_id
    url = '/main/edit_note?list_id=' + list_id + '&note_id=' + note_id + '&note=' + note_content
    showLoading();
    $.get(url)
    .done(function(data) {
        hideLoading();
        if (data.message == 'success') {
            if(note_content != '') {
                $(replace_div).text(decodeURIComponent(note_content))
                $(div_to_hide).hide();
                $(replace_div).show();
                $(edit_note_link).show();
            } else {
               $(div_to_hide).hide();
            }
        } else {
            alert_message("danger","The system encountered an error. Please try again later.")
        }
    });
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
    $.post("login.json", {username: username, password: password})
    .done(function(data) {
        $('#statusMessage').modal('hide')
        if (data.error == 'bad username or password') {
            $('#username').val('');
            $('#password').val('');
            $('.holdloginuser-'+id).val('');
            $('.holdloginpass-'+id).val('');
            $('#statusMessage').modal('hide');
            alert_message('danger', 'Login failed. The username or password provided was not valid. Passwords are case-sensitive. Check your Caps-Lock key and try again or contact your local library.');
        } else {
            $.post("login.js", {username: username, password: password});
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
    if (timeout == undefined) { var timeout = 10000; }
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
    $('#force-hold').unbind('click');
    $('#force-hold').click(function(event) {
        $('#hold-confirm-force').modal('hide');
        $('#statusMessage').modal('show');
        place_hold(id,true);
    });
    $('#cancel-force-hold').unbind('click');
    $('#cancel-force-hold').click(function(event) {
        var statusdiv = '.hold-status-'+id;
        var holdbtn = '.hold-'+id;
        $(statusdiv).empty();
        $(holdbtn).show();
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
        $.post("/main/edit_preferences.js")
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

    $('.edit-user-password').unbind('click');
    $('.edit-user-password').click(function(event) {
        event.preventDefault();
        var userpanel = $('#panel-user-prefs').html();

        var upv = '(hidden)';
        var upvhtml = '<div><input id="password1" name="password1" class="form-control" type="password" placeholder="Enter New Password"></div>';
            upvhtml += '<div class="padtop"><input id="password2" name="password2" class="form-control" type="password" placeholder="Enter Again"></div>';
            upvhtml += '<span class="small text-muted">Passwords must be at least 7 characters in length and contain at least one number and one letter.</span>';
        $('#current-password-value').html(upvhtml);

        $('#user-prefs-password').show();
        $('#user-prefs-footer').show();
        $('.edit-user-password').hide();

        user_prefs_cancel_bind(userpanel);
        user_password_save_bind();
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
            tnnvhtml += '<span id="sms_check_result"></span>';
        $('#text_notify_number-value').html(tnnvhtml);
        validate_sms_bind();

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
            $.post("/main/update_notifications", {email_notify: env, phone_notify: pnv, text_notify: tnv, phone_notify_number: pnnv, text_notify_number: tnnv})
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
        $.post("/main/update_user_info", {username: newusername, password: up})
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
        $.post("/main/update_user_info", {hold_shelf_alias: newalias, password: up})
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
        $.post("/main/update_user_info", {email: newemail, password: up})
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

function user_password_save_bind() {
    $('.save-user-prefs').unbind('click');
    $('.save-user-prefs').click(function(e) {
        e.preventDefault();
        var up = $('#up-password').val();
        var newpass1 = $('#password1').val();
        var newpass2 = $('#password2').val();
        if (up == '') {
            alert_message('danger', 'You must enter your current password in order to change your password.', 10000);
            return;
        }
        if (newpass1 == newpass2) {
            var rule = /(?=.*\d)(?=.*[a-zA-Z]).{7,}/;
            if (rule.test(newpass1)) {
                $('.save-user-prefs').html(spinner+' Saving...');
                $.post("/main/update_user_info", {password: up, new_password: newpass1})
                .done(function(data) {
                    if (data.message == 'bad password') {
                        alert_message('danger', 'Sorry, the Current Password was incorrect. Please try again.', 10000);
                    } else if (data.message == 'password does not meet requirements') {
                        alert_message('danger', 'Somehow, this message appeared (password does not meet requirements even though we validate this)');
                    } else if (data.message == 'success') {
                        alert_message('success', 'Password has been changed.', 10000);
                    } else {
                        alert_message('info', data.message, 10000);
                    }
                    $('.cancel-user-prefs').click();
                });
            } else {
                alert_message('danger', 'Password does not meet the complexity requirements. Passwords must be at least 7 characters in length, with at least one number and one letter', 15000);
            }
        } else {
            // blank out values if passwords are not the same
            alert_message('danger', 'Sorry, new passwords do not match. You must enter the same value in both fields.', 10000);
            $('#password1').val('');
            $('#password2').val('');
        }
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
    if ($.isEmptyObject(cids) === true) {
        delete window.cids;
    }
    if ($.isEmptyObject(rids) === true) {
        delete window.rids;
    }
}

function bulk_action_binds() {
    $('#hold-bulk-suspend').unbind('click');
    $('#hold-bulk-suspend').click(function(e) {
        e.preventDefault();
        if (typeof ids !== 'undefined') {
            showLoading();
            $.post('/main/manage_hold.js', {hold_id: ids.toString(), task: 'suspend'})
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
            $.post('/main/manage_hold.js', {hold_id: ids.toString(), task: 'activate'})
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
            $.post('/main/manage_hold.js', {hold_id: ids.toString(), task: 'cancel'})
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
        if ((typeof rids !== 'undefined') || (typeof cids !== 'undefined')) {
            showLoading();
            $.post('/main/renew_checkouts.js', {checkout_ids: cids.toString(), record_ids: rids.toString()})
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


function edit_pickup_loc(hid,rid,state) {
    event.preventDefault();
    $.post("/main/edit_hold_pickup.js",{'hold_id' : hid, 'hold_state' : state})
}

function item_details(item, name) {
    if (!name) {
        $.post("/main/details.js", item)
    } else {
        item.list_name =  name;
        $.post("/main/details.js", item)
    }
}

function validate_sms_bind() {
    var TADL_LAST_NUMBER;
    var digits_trimmed;
    $('#tnnv').on('keyup', function(event) {
        if (event.which !== 0) {
            var original = this.value;
            var digits = this.value.replace(/\D/g, '');
            digits_trimmed = digits.replace(/^1/, '');
            if (digits_trimmed.length == 10) {
                if (TADL_LAST_NUMBER !== digits_trimmed) {
                    TADL_LAST_NUMBER = digits_trimmed;
                    $.ajax({
                        url: 'https://util-ext.catalog.tadl.org/api/v1/lookup/' + digits_trimmed,
                        success: function(data) {
                            if (data.result) {
                                $('#sms_check_result').text("<span class='glyphicon glyphicon-flag text-danger'> We can't determine if this number is capable of receiving text messages.");
                            } else {
                                if (data.carrier.type === 'mobile') {
                                    $('#sms_check_result').text("<span class='glyphicon glyphicon-ok text-success'></span> This number appears capable of receiving text messages.");
                                } else {
                                    $('#sms_check_result').text("<span class='glyphicon glyphicon-remove text-danger'></span> This number might not be able to receive text messages.");
                                }
                            }
                        },
                        dataType: 'json',
                        xhrFields: {
                            withCredentials: true,
                        }
                    });
                }
            }
        }
    });
}

function load_added_content(record_id, isbn) {
    if (isbn && isbn != '') {
        fetch_good_reads(isbn)
    }
    fetch_youtube_trailer(record_id)
}

function fetch_good_reads(isbn) {
    var clean_isbn = isbn.replace(/\D/g,'')
    var url = 'https://reviewcatcher.herokuapp.com/?isbn=' + clean_isbn
    $.get(url)
    .done(function(data) {
        if (data.gr_id) {
            var content = '<span class="goodreads-stars"><a href="' + data.gr_link +'">'
            content = content + data.stars_html + ' on GoodReads.com'
            content = content + '</a></span>'
            $('#goodreads_review').html(content)
        }
    });
}

function fetch_youtube_trailer(record_id) {
    var url = 'https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + record_id
    $.get(url)
    .done(function(data) {
        if (data.message && data.message != 'error') {
            var content = '<div class="embed-responsive embed-responsive-16by9"><iframe src="/util/youtube?id='+ data.message +'" width="100%" style="overflow:hidden;"></iframe></div>'
            $('#trailer').html(content)
        }
    });
}

function load_next(id, list_name) {
    if (list_name != '') {
        var target_name = '#' + id + '_' + list_name
        var next_id = $(target_name).next('li').text()
        var next_link = '#' + next_id + '_' + list_name + ':first a'
        $(next_link)[0].click()
        var owl = $('#slider_' + list_name);
        owl.trigger('owl.next');
    } else {
        var pannel_name = '#item_' + id
        $(pannel_name)[0].scrollIntoView()
        var target_name = '#' + id
        var next_id = $(target_name).next('li').text()
        var next_link = '#' + next_id + ':first a'
        $(next_link)[0].click()
    }
}

function load_previous(id, list_name) {
    if (list_name != '') {
        var target_name = '#' + id + '_' + list_name
        var prev_id = $(target_name).prev('li').text()
        var prev_link = '#' + prev_id + '_' + list_name + ':first a'
        $(prev_link)[0].click()
        var owl = $('#slider_' + list_name);
        owl.trigger('owl.prev');
    } else {
        var pannel_name = '#item_' + id
        $(pannel_name)[0].scrollIntoView()
        var target_name = '#' + id
        var prev_id = $(target_name).prev('li').text()
        var prev_link = '#' + prev_id + ':first a'
        $(prev_link)[0].click()
    }
}

function check_for_previous_and_next(id, list_name) {
    if (list_name) {
        var target = '#' + id + '_' + list_name
    } else {
        var target = '#' + id
    }
    var check_for_next = $(target).next('li').text()
    if (check_for_next != '') {
        $('#next_link').show();
    }
    var check_for_previous = $(target).prev('li').text()
    if (check_for_previous != '') {
        $('#previous_link').show();
    }
}
