#!/usr/bin/perl -w

use Net::CalDAVTalk;
use JSON::XS;
use CGI;
use Encode qw(encode_utf8 decode_utf8);

use strict;
use warnings;

my $cgi = CGI->new();

my $cdt = Net::CalDAVTalk->new(url => 'http://foo/');

my $action = $cgi->param('action') || '';
my $ical = decode_utf8 $cgi->param('ical');
my $api = decode_utf8 $cgi->param('api');

my $uploadfh = $cgi->upload('icalfile');
if ($uploadfh) {
  $ical = join('', <$uploadfh>);
}

if ($action eq 'toical') {
  my $args = eval { JSON::XS::decode_json($api) };
  error('invalid json', $@) unless $args;
  my $vcal = eval { $cdt->_argsToVCalendar($args) };
  use Data::Dumper;
  error('invalid api object', Dumper($args) . $@) unless $vcal;
  $ical = $vcal->as_string();
}
elsif ($action eq 'toapi') {
  my @events = eval { $cdt->vcalendarToEvents($ical) };
  error('invalid ical', $@) if $@;
  error('no events') unless @events;
  $api = JSON::XS->new->pretty(1)->canonical(1)->encode(@events > 1 ? \@events : $events[0]);
}

print $cgi->header(-charset=>'utf-8');

print $cgi->start_html(
  -title => "API conversion",
);

print $cgi->start_form(
 '-accept-charset' => 'utf-8',
);

print "<table border=1>\n";
print "<tr><th>API</th><th></th><th>iCal</th></tr>\n";
print "<tr><td>";
print $cgi->textarea(
  -name => 'api',
  -default => encode_utf8 $api || '',
  -override => 1,
  -rows => '20',
  -columns => '60',
);
print "</td><td>";

print $cgi->submit('action', 'toical');
print "<br>\n";
print $cgi->submit('action', 'toapi');

print "</td><td>";
print $cgi->textarea(
  -name => 'ical',
  -default => encode_utf8 $ical || '',
  -override => 1,
  -rows => '20',
  -columns => '60',
);
print "</td></tr>\n";
print "</table>\n";

print $cgi->end_form();

print $cgi->end_html();

exit 0;

sub error {
  my $error = shift;
  my $message = shift;

  print $cgi->header(-charset=>'utf-8');
  print $cgi->start_html(
    -title => "API conversion error",
  );

  print "<h1>Conversion Error:</h1>\n";
  print "<h2>$error</h2>";
  if ($message) {
    print "<p>" . $cgi->escapeHTML($message) . "</p>";
  }

  print $cgi->end_html();

  exit 0;
}
