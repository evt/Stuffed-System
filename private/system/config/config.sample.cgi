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

# default charset for text/html content-type (IE, will give errors on "utf8" in the HTTP header of the Ajax response
$config->{default_charset} = 'utf-8';

# default Perl IO layer for files, "binary" for ":raw" and "text" for "encoding(UTF-8)"
$config->{default_file_layer} = 'binary';

# strip HTML comments from the templates when they are compiled
$config->{strip_html_comments} = '1';

# strip tab characters when the templates are compiled
$config->{strip_tabs} = '1';

# strip new line characters when the templates are compiled
$config->{strip_new_lines} = '1';

# location of svnversion utilty, part of subversion
$config->{svnversion} = 'svnversion';

# ============================================================================
# error logging

# enable logging of critical errors, critical errors happen when die is called or system dies on its own 
$config->{log_critical_errors} = '0';

# default name of the critical errors log file, physical or relative to the system's root
$config->{critical_errors_file} = 'private/.ht_errors.critical.log';

# print out actual critical errors in the visitor's browser, otherwise only a generic message is displayed
$config->{display_critical_errors} = 1;

# enable logging of all errors, critical and those displayed through an ->error method of Output.pm 
$config->{log_all_errors} = '0';

# default name of all errors log file, physical or relative to the system's root
$config->{all_errors_file} = 'private/.ht_errors.all.log';

# package or action not found errors handling
$config->{use_404} = '0';
$config->{error_404_URL} = '';

# log browser errors to a file, they are reported through the browser_error action
$config->{log_browser_errors} = 1;

# default name of the browser errors log file, physical or relative to the system's root
$config->{browser_errors_file} = 'private/.ht_errors.browser.log';

# ============================================================================
# Redis configuration

$config->{redis_host} = 'localhost';
$config->{redis_port} = 6379;

# ============================================================================
# Sphinx configuration

$config->{sphinx_host} = 'localhost';
$config->{sphinx_port} = 9312;

# ============================================================================

1;