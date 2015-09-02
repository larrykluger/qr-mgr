#!/usr/bin/perl
#
# This program 
# Looks up the requested url in the redirect MySQL database and then directs 
# the requestor to that site.
# Copyright 2012 Larry Kluger 
# License: MIT License
#
# Purpose is to redirect qr codes 
# QR code size: http://www.qrstuff.com/blog/2011/11/23/qr-code-minimum-size
#  http://stackoverflow.com/questions/5609370/recommended-pixel-size-for-qr-code-ver-2-ux-for-qr-codes
#
# CONFIGURATION
my $DBSERVER = 'mysql.pardesusa.org';
my $DBNAME = 'pardes_qr';
my $DBLOGIN = 'login_name';
my $DBPASSWORD = 'password';
my $ROOTURL = '/';  # Use '/' if in web root directory
                                # Include leading and trailing slash if
                                # a sub_directory is used. 
                                # Eg for qr dir, use '/qr/'

my $DBTABLE = 'qr_codes';
# End of configuration!
#
# We want all of the urls for the directory to be handled by this
# program. So please see the .htaccess files
#
# DATABASE SCHEMA sql is at the bottom of this file

use strict;
use warnings;
use CGI;
use CGI::Carp;
use DBI;
$CGI::DISABLE_UPLOADS = 1;  # no uploads

# Start...     
# we always need the db, so login here
my $dbh;
$dbh = DBI->connect("DBI:mysql:$DBNAME:$DBSERVER", $DBLOGIN, $DBPASSWORD)
  or my_die ("Error when opening database connection.");

my $url_path = $ENV{REQUEST_URI};
if (!$url_path) {my_die ("No REQUEST_URI.")};
my $qr_code = substr $url_path, length $ROOTURL;
if (substr($qr_code, -1) eq '/') {chop $qr_code}; # remove trailing /
if (length ($qr_code) > 255) {my_croak ("QR code too long")};
if (length ($qr_code) == 0) {my_croak ("QR code too short")}; # or goto admin page?
 
# lookup the target_url
my ($target_url, $sth, @result);
$sth = $dbh->prepare("SELECT target_url FROM $DBTABLE WHERE qr_code = ?")
  or my_die ("Error when preparing database query.");
$sth->execute($qr_code) # escapes the parameter
  or my_die ("Error when executing database query.");
@result = $sth->fetchrow_array();
if (!@result || !$result[0]) {my_croak ("QR code $qr_code not found!")};
$target_url = $result[0];

# redirect!
print CGI->new->redirect($target_url);

# Bye now!

##################### End of Mainline #####################################
#
#
###########################################################################
#
#                    S U B R O U T I N E S
#
########################################################################### 

sub my_die {
  # my problem!
  my($msg) = @_;
  html_error("We had an internal problem. Please try again later. Thank you.");
  die($msg);
};

sub my_croak {
  # user's problem!
  my($msg) = @_;
  html_error($msg);
  croak($msg);
};

sub html_error {
  my($msg) = @_;
  my $img_dir = "${ROOTURL}cgi-bin";
  
  print CGI->new->header('text/html; charset=utf-8','202 Accepted');
  print html_head();
  print <<HTML;
<body>
  <div class="container">
    <h1>We have a problem!</h1>
    <p>$msg</p>
    <p><img src='$img_dir/train_wreck.jpg' /></p>
    <!-- Copyright: The train picture was published in the US before 1923 and is public domain in the US. See wikipedia train wreck -->
  </div>
</body></html>
HTML

$| = 1; # flush output
}
  
sub html_head {
return <<'HTML';
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>We have a problem</title>
  <style>
    ::-moz-selection { background: #fe57a1; color: #fff; text-shadow: none; }
    ::selection { background: #fe57a1; color: #fff; text-shadow: none; }
    html { padding: 30px 10px; font-size: 20px; line-height: 1.4; color: #737373; background: #f0f0f0; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    html, input { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; }
    body { max-width: 600px; _width: 600px; padding: 30px 20px 50px; border: 1px solid #b3b3b3; border-radius: 4px; margin: 0 auto; box-shadow: 0 1px 10px #a7a7a7, inset 0 1px 0 #fff; background: #fcfcfc; }
    h1 { margin: 0 10px; font-size: 50px; text-align: center; }
    h1 span { color: #bbb; }
    h3 { margin: 1.5em 0 0.5em; }
    p { margin: 1em 0; text-align: center;}
    ul { padding: 0 0 0 40px; margin: 1em 0; }
    .container { max-width: 600px; _width: 480px; margin: 0 auto; }
  </style>
</head>
HTML
}  
  
  
__END__

# SQL for creating the database table
# Table name must match the $DBTABLE constant above
# Note that the table name is also used in the index statements.

CREATE TABLE qr_codes (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  qr_code     VARCHAR(255), 
  target_url  VARCHAR(255)
);

CREATE UNIQUE INDEX qr_codes1 ON qr_codes (qr_code);
CREATE INDEX qr_codes2 ON qr_codes (target_url);
