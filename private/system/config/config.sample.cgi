# ============================================================================
#
#                        ___
#                    ,yQ$SSS$Q',      ,'yQQQL
#                  j$$"`     `?$'  ,d$P"```'$$,
#           i_L   I$;            `$``       `$$,
#                                 `          I$$
#           .:yQ$$$$,            ;        _,d$$'
#        ,d$$P"^```?$b,       _,'  ;  ,:d$$P"
#     ,d$P"`        `"?$$Q#QPw`    $d$$P"`
#   ,$$"         ;       ``       ;$?'
#   $$;        ,dI                I$;
#   `$$,    ,d$$$`               j$I
#     ?$S#S$P'j$'                $$;         Copyright (c) Stuffed Guys
#       `"`  j$'  __....,,,.__  j$I              www.stuffedguys.org
#           j$$'"``           ',$$
#           I$;               ,$$'
#           `$$,         _.:u$$:`
#             "?$$Q##Q$$SP$"^`
#                `````
#
# ============================================================================

$config->{debug} = '1';
$config->{log_errors} = '0';
$config->{default_pkg} = 'system';
$config->{form_max_size} = 1048576*50; # 50 megs

# sessions
$config->{sessions_ip_in_cookie} = '1';
$config->{sessions_lifetime} = '3600';

# mail
$config->{mail_system} = 'sendmail'; # or 'smtp'
$config->{sendmail_path} = '/usr/sbin/sendmail';
$config->{smtp_server} = '';

# cookies
$config->{cookies_domain} = '';
$config->{cookies_path} = '/';
$config->{cookies_prefix} = '';
$config->{p3p_compact_policy} = 'CUR ADM OUR NOR STA NID';
$config->{p3p_enable} = '1';
$config->{p3p_policy_location} = '';

# paths and urls, need to be corrected for each installation
$config->{cgi_url} = '/index.cgi';
$config->{public_path} = '/Users/sergey/Code/Idefit/public';
$config->{public_url} = '/public';
$config->{default_host} = 'localhost';

# main database
$config->{db_type} = 'MySQL';
$config->{db_host} = 'localhost';
$config->{db_name} = '';
$config->{db_port} = '3306';
$config->{db_user} = '';
$config->{db_pass} = '';
$config->{db_prefix} = ''; # ss_

# package or action not found errors handling
$config->{use_404} = '0';
$config->{error_404_URL} = '';

# save warnings in the errors log or in the db (ss_system_warnings)
$config->{warnings_to_db} = '1';

# the following ips are allowed to enable db debugging with __debug_db=1 URL parameter
# (subnets are specified with *)
$config->{allow_debug_db_ips} = [qw(127.0.0.1)];

# mark queries with yellow in the __debug_db output if they are slower then the num
# of seconds specified here (0 -- disables the feature);
$config->{warning_query_secs} = '0';

# database replication, separate database for SELECT queries
$config->{enable_read_db} = '0';
$config->{read_db_host} = 'localhost';
$config->{read_db_name} = '';
$config->{read_db_port} = '3306';
$config->{read_db_user} = '';
$config->{read_db_pass} = '';
# always read the following tables from the main database
$config->{skip_read_tables} = [qw(system_sessions)];

# if enabled, a "stopped.html" template in system package will be displayed
# on all requests to the system
$config->{system_stopped} = 0;

# unique ID of the system (server), passed in the response as an HTTP header
$config->{system_id} = 'local';

# default name of the server errors log file, physical or relative to the system's root
$config->{errors_file} = 'private/.ht_errors.log';

# print out actual errors in the visitor's browser, otherwise only a generic 
# message is displayed
$config->{display_errors} = 1;

# default charset for text/html content-type (IE, will give errors on "utf8" in the HTTP header of the Ajax response
$config->{default_charset} = 'utf-8';

# strip HTML comments from the templates when they are compiled
$config->{strip_html_comments} = '1';

# strip tab characters when the templates are compiled
$config->{strip_tabs} = '1';

# strip new line characters when the templates are compiled
$config->{strip_new_lines} = '1';

# log browser errors to a file, they are reported through the browser_error action
$config->{log_browser_errors} = 1;

# default name of the browser errors log file, physical or relative to the system's root
$config->{browser_errors_file} = 'private/.ht_errors.browser.log';

# location of svnversion utilty, part of subversion
$config->{svnversion} = 'svnversion';

1;