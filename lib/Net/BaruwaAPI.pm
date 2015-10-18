# -*- coding: utf-8 -*-
# vim: ai ts=4 sts=4 et sw=4
# Net::BaruwaAPI Perl bindings for the Baruwa REST API
# Copyright (C) 2015 Andrew Colin Kissa <andrew@topdog.za.net>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
package Net::BaruwaAPI;

use 5.006;
use JSON::MaybeXS;
use HTTP::Request;
use Carp qw/croak/;
use LWP::UserAgent;
use Types::Standard qw(Str InstanceOf Object);
use Moo;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:DATOPDOG';

has 'api_url' => (is => 'rw', isa => Str, predicate => 'has_api_url');

has 'api_token' => (is => 'rw', isa => Str, predicate => 'has_api_token');

has 'ua' => (
    isa     => InstanceOf['LWP::UserAgent'],
    is      => 'ro',
    lazy    => 1,
    default => sub {
        LWP::UserAgent->new(
            agent       => "BaruwaAPI-Perl",
            cookie_jar  => {},
            keep_alive  => 4,
            timeout     => 60,
        );
    },
);

has 'json' => (
    is => 'ro',
    isa => Object,
    lazy => 1,
    default => sub {
        return JSON::MaybeXS->new( utf8 => 1 );
    }
);

sub _call {
    my ($self) = @_;
    my $request_method = shift @_;
    my $url = shift @_;
    my $data = shift @_;

    my $ua = $self->ua;
    $ua->default_header('Authorization', "Bearer " . $self->api_token);
    $url = $self->api_url . $url;

    my $req = HTTP::Request->new( $request_method, $url );
    $req->accept_decodable;

    if ($data) {
        $req->content($data);
    }
    $req->header( 'Content-Length' => length $req->content );

    my $res = $ua->request($req);

    if ($res->header('Content-Type') and $res->header('Content-Type') =~ 'application/json') {
        my $json = $res->decoded_content;
        $data = eval { $self->json->decode($json) };
        unless ($data) {
            die unless $res->is_error;
            $data = { code => $res->code, message => $res->message };
        }
    } else {
        $data = { code => $res->code, message => $res->message };
    }

    if (not $res->is_success and ref $data eq 'HASH' and exists $data->{message}) {
        my $message = $data->{message};

        if (exists $data->{errors}) {
            $message .= ': '.join(' - ', map { $_->{message} } grep { exists $_->{message} } @{ $data->{errors} });
        }
        croak $message;
    }
    return $data;
}


sub get_users {
    my ($self) = @_;
    return $self->_call('GET', '/users');
}

sub get_user {
    my ($self, $userid) = @_;
    return $self->_call('GET', '/users/' . $userid);
}

sub create_user {
    my ($self, $data) = @_;
    return $self->_call('POST', '/users', $data);
}

sub update_user {
    my ($self, $data) = @_;
    return $self->_call('PUT', '/users', $data);
}

sub delete_user {
    my ($self, $data) = @_;
    return $self->_call('DELETE', '/users', $data);
}

sub set_user_passwd {
    my ($self, $userid, $data) = @_;
    return $self->_call('POST', '/users/chpw/' . $userid);
}

sub get_aliases {
    my ($self, $addressid) = @_;
    return $self->_call('GET', '/aliasaddresses/' . $addressid);
}

sub create_alias {
    my ($self, $userid, $data) = @_;
    return $self->_call('POST', '/aliasaddresses/' . $userid, $data);
}

sub update_alias {
    my ($self, $addressid, $data) = @_;
    return $self->_call('PUT', '/aliasaddresses/' . $addressid, $data);
}

sub delete_alias {
    my ($self, $addressid, $data) = @_;
    return $self->_call('DELETE', '/aliasaddresses/' . $addressid, $data);
}

sub get_domains {
    my ($self) = @_;
    return $self->_call('GET', '/domains');
}

sub get_domain {
    my ($self, $domainid) = @_;
    return $self->_call('GET', '/domains/' . $domainid);
}

sub create_domain {
    my ($self, $data) = @_;
    return $self->_call('POST', '/domains', $data);
}

sub update_domain {
    my ($self, $domainid, $data) = @_;
    return $self->_call('PUT', '/domains/' . $domainid, $data);
}

sub delete_domain {
    my ($self, $domainid) = @_;
    return $self->_call('DELETE', '/domains/' . $domainid);
}

sub get_domainaliases {
    my ($self, $domainid) = @_;
    return $self->_call('GET', '/domainaliases/' . $domainid);
}

sub get_domainalias {
    my ($self, $domainid, $aliasid) = @_;
    return $self->_call('GET', '/domainaliases/' . $domainid . '/' . $aliasid);
}

sub create_domainalias {
    my ($self, $domainid, $data) = @_;
    return $self->_call('POST', '/domainaliases/' . $domainid, $data);
}

sub update_domainalias {
    my ($self, $domainid, $aliasid, $data) = @_;
    return $self->_call('PUT', '/domainaliases/' . $domainid . '/' . $aliasid, $data);
}

sub delete_domainalias {
    my ($self, $domainid, $aliasid, $data) = @_;
    return $self->_call('DELETE', '/domainaliases/' . $domainid . '/' . $aliasid, $data);
}

sub get_deliveryservers {
    my ($self, $domainid) = @_;
    return $self->_call('GET', '/deliveryservers/' . $domainid);
}

sub get_deliveryserver {
    my ($self, $domainid, $serverid) = @_;
    return $self->_call('GET', '/deliveryservers/' . $domainid . '/' . $serverid);
}

sub create_deliveryserver {
    my ($self, $domainid) = @_;
    return $self->_call('POST', '/deliveryservers/' . $domainid);
}

sub update_deliveryserver {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('PUT', '/deliveryservers/' . $domainid . '/' . $serverid, $data);
}

sub delete_deliveryserver {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('DELETE', '/deliveryservers/' . $domainid . '/' . $serverid, $data);
}

sub get_authservers {
    my ($self, $domainid) = @_;
    return $self->_call('GET', '/authservers/' . $domainid);
}

sub get_authserver {
    my ($self, $domainid, $serverid) = @_;
    return $self->_call('GET', '/authservers/' . $domainid . '/' . $serverid);
}

sub create_authserver {
    my ($self, $domainid, $data) = @_;
    return $self->_call('POST', '/authservers/' . $domainid, $data);
}

sub update_authserver {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('PUT', '/authservers/' . $domainid . '/' . $serverid, $data);
}

sub delete_authserver {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('DELETE', '/authservers/' . $domainid . '/' . $serverid, $data);
}

sub get_ldapsettings {
    my ($self, $domainid, $serverid, $settingsid) = @_;
    return $self->_call('GET', '/ldapsettings/' . $domainid . '/' . $serverid . '/' . $settingsid);
}

sub create_ldapsettings {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('POST', '/ldapsettings/' . $domainid . '/' . $serverid, $data);
}

sub update_ldapsettings {
    my ($self, $domainid, $serverid, $settingsid, $data) = @_;
    return $self->_call('PUT', '/ldapsettings/' . $domainid . '/' . $serverid . '/' . $settingsid, $data);
}

sub delete_ldapsettings {
    my ($self, $domainid, $serverid, $settingsid, $data) = @_;
    return $self->_call('DELETE', '/ldapsettings/' . $domainid . '/' . $serverid . '/' . $settingsid, $data);
}

sub get_radiussettings {
    my ($self, $domainid, $serverid, $settingsid) = @_;
    return $self->_call('GET', '/radiussettings/' . $domainid . '/' . $serverid . '/' . $settingsid);
}

sub create_radiussettings {
    my ($self, $domainid, $serverid, $data) = @_;
    return $self->_call('POST', '/radiussettings/' . $domainid . '/' . $serverid, $data);
}

sub update_radiussettings {
    my ($self, $domainid, $serverid, $settingsid, $data) = @_;
    return $self->_call('PUT', '/radiussettings/' . $domainid . '/' . $serverid . '/' . $settingsid, $data);
}

sub delete_radiussettings {
    my ($self, $domainid, $serverid, $settingsid, $data) = @_;
    return $self->_call('DELETE', '/radiussettings/' . $domainid . '/' . $serverid . '/' . $settingsid, $data);
}

sub get_organizations {
    my ($self) = @_;
    return $self->_call('GET', '/organizations');
}

sub get_organization {
    my ($self, $orgid) = @_;
    return $self->_call('GET', '/organizations/' . $orgid);
}

sub create_organization {
    my ($self, $data) = @_;
    return $self->_call('POST', '/organizations', $data);
}

sub update_organization {
    my ($self, $orgid, $data) = @_;
    return $self->_call('PUT', '/organizations/' . $orgid, $data);
}

sub delete_organization {
    my ($self, $orgid) = @_;
    return $self->_call('DELETE', '/organizations/' . $orgid);
}

sub get_relay {
    my ($self, $relayid) = @_;
    return $self->_call('GET', '/relays/' . $relayid);
}

sub create_relay {
    my ($self, $orgid, $data) = @_;
    return $self->_call('POST', '/relays/' . $orgid, $data);
}

sub update_relay {
    my ($self, $relayid, $data) = @_;
    return $self->_call('PUT', '/relays/' . $relayid, $data);
}

sub delete_relay {
    my ($self, $relayid, $data) = @_;
    return $self->_call('DELETE', '/relays/' . $relayid, $data);
}

sub get_status {
    my ($self) = @_;
    return $self->_call('GET', '/status');
}

no Moo;

1;

__END__

=head1 NAME

Net::BaruwaAPI - Perl bindings for Baruwa REST API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Baruwa Enterprise Edition L<https://www.baruwa.com> is a fully fledged Mail
Security solution, based on best of breed open source software packages.
It provides protection from spam, viruses, phishing attempts and malware.

This distribution provides easy methods to access Baruwa servers via the
REST API.

Check L<https://www.baruwa.com/docs/api> for more details of the REST API.
Read L<Net::BaruwaAPI> for API usage.

    use Net::BaruwaAPI;
    my $api = Net::BaruwaAPI->new(
        api_token => 'oauth token',
        api_url => 'https://baruwa.example.com/api/v1'
    );

=head1 METHODS

=head2 get_users

    my $data = $api->get_users();

=head2 get_user($userid)

    my $data = $api->get_user($userid);

=head2 create_user($data)

    my $data = $api->create_user($data);

=head2 update_user($data)

    my $data = $api->update_user($data);

=head2 delete_user($data)

    my $data = $api->delete_user($data);

=head2 set_user_passwd($userid, $data)

    my $data = $api->set_user_passwd($userid, $data);

=head2 get_aliases($addressid)

    my $data = $api->get_aliases($addressid);

=head2 create_alias($userid, $data)

    my $data = $api->create_alias($userid, $data);

=head2 update_alias($addressid, $data)

    my $data = $api->update_alias($addressid, $data);

=head2 delete_alias($addressid, $data)

    my $data = $api->delete_alias($addressid, $data);

=head2 get_domains

    my $data = $api->get_domains();

=head2 get_domain($domainid)

    my $data = $api->get_domain($domainid);

=head2 create_domain($data)

    my $data = $api->create_domain($data);

=head2 update_domain($domainid, $data)

    my $data = $api->update_domain($domainid, $data);

=head2 delete_domain($domainid)

    my $data = $api->delete_domain($domainid);

=head2 get_domainaliases($domainid)

    my $data = $api->get_domainaliases($domainid);

=head2 get_domainalias($domainid, $aliasid)

    my $data = $api->get_domainalias($domainid, $aliasid);

=head2 create_domainalias($domainid, $data)

    my $data = $api->create_domainalias($domainid, $data);

=head2 update_domainalias($domainid, $aliasid, $data)

    my $data = $api->update_domainalias($domainid, $aliasid, $data);

=head2 delete_domainalias($domainid, $aliasid, $data)

    my $data = $api->delete_domainalias($domainid, $aliasid, $data);

=head2 get_deliveryservers($domainid)

    my $data = $api->get_deliveryservers($domainid);

=head2 get_deliveryserver($domainid, $serverid)

    my $data = $api->get_deliveryserver($domainid, $serverid);

=head2 create_deliveryserver($domainid, $data)

    my $data = $api->create_deliveryserver($domainid, $data);

=head2 update_deliveryserver($domainid, $serverid, $data)

    my $data = $api->update_deliveryserver($domainid, $serverid, $data);

=head2 delete_deliveryserver($domainid, $serverid, $data)

    my $data = $api->delete_deliveryserver($domainid, $serverid, $data);

=head2 get_authservers($domainid)

    my $data = $api->get_authservers($domainid);

=head2 get_authserver($domainid, $serverid)

    my $data = $api->get_authserver($domainid, $serverid);

=head2 create_authserver($domainid, $data)

    my $data = $api->create_authserver($domainid, $data);

=head2 update_authserver($domainid, $serverid, $data)

    my $data = $api->update_authserver($domainid, $serverid, $data);

=head2 delete_authserver($domainid, $serverid, $data)

    my $data = $api->delete_authserver($domainid, $serverid, $data);

=head2 get_ldapsettings($domainid, $serverid, $settingsid)

    my $data = $api->get_ldapsettings($domainid, $serverid, $settingsid);

=head2 create_ldapsettings($domainid, $serverid, $data)

    my $data = $api->create_ldapsettings($domainid, $serverid, $data);

=head2 update_ldapsettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->update_ldapsettings($domainid, $serverid, $settingsid, $data);

=head2 delete_ldapsettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->delete_ldapsettings($domainid, $serverid, $settingsid, $data);

=head2 get_radiussettings($domainid, $serverid, $settingsid)

    my $data = $api->get_radiussettings($domainid, $serverid, $settingsid);

=head2 create_radiussettings($domainid, $serverid, $data)

    my $data = $api->create_radiussettings($domainid, $serverid, $data);

=head2 update_radiussettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->update_radiussettings($domainid, $serverid, $settingsid, $data);

=head2 delete_radiussettings($domainid, $serverid, $settingsid, $data)

    my $data = $api->delete_radiussettings($domainid, $serverid, $settingsid, $data);

=head2 get_organizations

    my $data = $api->get_organizations();

=head2 get_organization($orgid)

    my $data = $api->get_organization($orgid);

=head2 create_organization($data)

    my $data = $api->create_organization($data);

=head2 update_organization($orgid, $data)

    my $data = $api->update_organization($orgid, $data);

=head2 delete_organization($orgid)

    my $data = $api->delete_organization($orgid);

=head2 get_relay($relayid)

    my $data = $api->get_relay($relayid);

=head2 create_relay($orgid, $data)

    my $data = $api->create_relay($orgid, $data);

=head2 update_relay($relayid, $data)

    my $data = $api->update_relay($relayid, $data);

=head2 delete_relay($relayid, $data)

    my $data = $api->delete_relay($relayid, $data);

=head2 get_status

    my $data = $api->get_status();

=head1 AUTHOR

Andrew Colin Kissa, C<< <andrew at topdog.za.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-baruwaapi at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-BaruwaAPI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::BaruwaAPI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-BaruwaAPI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-BaruwaAPI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-BaruwaAPI>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-BaruwaAPI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Andrew Colin Kissa.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at L<http://mozilla.org/MPL/2.0/>.


=cut
