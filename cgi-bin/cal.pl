#!/usr/bin/perl -w

use Net::CalDAVTalk;
use JSON::XS;
use CGI;

my $cgi = CGI->new();

my $cdt = Net::CalDAVTalk->new(url => 'http://foo/');

my $action = $cgi->param('action') || '';
my $ical = $cgi->param('ical');
my $api = $cgi->param('api');

my $uploadfh = $cgi->upload('icalfile');
if ($uploadfh) {
  $ical = join('', <$uploadfh>);
}

if ($action eq 'toical') {
  my $args = eval { decode_json($api) };
  error('invalid json', $@) unless $args;
  my $vcal = eval { $cdt->_argsToVCalendar($args) };
  error('invalid api object', $@) unless $vcal;
  $ical = $vcal->as_string();
}
elsif ($action eq 'toapi') {
  my @events = eval { $cdt->vcalendarToEvents($ical) };
  error('invalid ical', $@) if $@;
  error('no events') unless @events;
  $api = encode_json(@events > 1 ? \@events : $events[0]);
}

print $cgi->header();

print $cgi->start_html(
  -title => "API conversion",
);

print $cgi->start_form();

print "<table border=1>\n";
print "<tr><th>API</th><th></th><th>iCal</th></tr>\n";
print "<tr><td>";
print $cgi->textarea(
  -name => 'api',
  -default => $api || '',
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
  -default => $ical || '',
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
  print start_html(
    -title => "API conversion",
  );

  print "<h1>Here's an error</h1>\n";
  print "<h2>$error</h2>";
  if ($message) {
    print "<p>" . escapeHTML($message) . "</p>";
  }

  print end_html();

  exit 0;
}
