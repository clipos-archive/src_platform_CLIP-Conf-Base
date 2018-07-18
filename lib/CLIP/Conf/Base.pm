# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2008-2018 ANSSI. All Rights Reserved.
package CLIP::Conf::Base;

use 5.008008;
use strict;
use warnings;

use CLIP::Logger ':all';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
clip_import_conf_sep
clip_import_conf
clip_import_conf_many
clip_import_conf_all
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.00';

=head1 NAME

CLIP::Conf::Base - Perl extension to help import variables from CLIP configuration files.

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

  use CLIP::Conf::Base;
  use CLIP::Conf::Base ':all';

=head1 DESCRIPTION

CLIP::Conf::Base provides functions to import variable values from untrusted configuration
files, by first running those values against a pre-defined regular expression. Each of those
functions basically look into a given file, looking for lines that match the following pattern :

	^[name][sep][val]$

where ^ symbolizes the line start, $ an accepted line end (which is to say a newline, possibly
preceded by blank characters and / or a commentary starting with a '#'), and with:

=over 4

=item [name]

The name of the variable to be imported.

=item [sep]

A caller-configured separator string, typically an "=" or one or more whitespaces.

=item [val]

The value to be affected to variable [name]. This value must match a caller-supplied regular 
expression.

=back

Import errors and warnings are output through the CLIP::Logger module.

=head1 EXPORT

No functions are exported by default. The ':all' Exporter tag exports the following:

=over 4

=item *

B<clip_import_conf_sep()>

=item *

B<clip_import_conf()>

=item *

B<clip_import_conf_many()>

=item *

B<clip_import_conf_all()>

=back

=head1 FUNCTIONS

CLIP::Conf::Base provides the following functions:

=cut


###### Consts ######
# Valid characters after a variable assignment
my $g_nl = "[\\s]*(?:#.*)?";

=over 4

=item B<clip_import_conf_sep($file, $name, $re, $sep)>

Imports a single variable named $name from the file $file, using
the $sep separator string and the $re regular expression for the import.
Returns the imported value, or C<undef> in case of error (including the absence
of any definition of $name in $file).
Redefinitions of the same variable in the same file override each other, so that
the returned value is the last valid definition in the file. Such overrides 
are signaled by a warning.

=cut

sub clip_import_conf_sep($$$$) {
	my ($file, $name, $re, $sep) = @_;
	
	my $var = "";

	if (not open IN, "<", "$file") {
		clip_warn "could not open $file for reading";
		return undef;
	}
	my @lines = <IN>;
	close IN;

	foreach my $line (@lines) {
		next if (not $line =~ /^$name$sep($re)$g_nl$/);
		my $tmp = $1;

		clip_warn "redefinition of $name, overriding $var" if ($var);

		$var = $tmp;
	}

	return ($var) ? $var : undef;
}

=item B<clip_import_conf($file, $name, $re)>

Imports a single variable named $name from the file $file, using '=' as 
separator and the $re regular expression to check the imported values.
Returns the last valid definition of $name in $file as a string, or C<undef>
in case of error.

=cut

sub clip_import_conf($$$) {
	my ($file, $name, $re) = @_;

	return clip_import_conf_sep($file, $name, $re, "=");
}

=item B<clip_import_conf_many_sep($file, $names, $re, $sep)>

Imports several variables, whose names are passed through a list referenced by $names,
using the same $sep string as separator and the same $re regular expression for all checks.
Returns a reference to a hash keyed by the variable names and containing their 
imported values, or C<undef> in case of error.
This function does not check that every variable in @{$names} is effectively imported.

=cut

sub clip_import_conf_many_sep($$$$) {
	my ($file, $names, $re, $sep) = @_;


	if (not open IN, "<", "$file") {
		clip_warn "could not open $file for reading";
		return undef;
	}
	my @lines = <IN>;
	close IN;

	my %vars;

	foreach my $line (@lines) {
		foreach my $name (@{$names}) {
			next if (not $line =~ /^$name$sep($re)$g_nl$/);

			my $tmp = $1;

			clip_warn "redefinition of $name, overriding $vars{$name}"
				if (defined ($vars{$name}));

			$vars{$name} = $tmp;
		}
	}

	return \%vars;
}

=item B<clip_import_conf_many($file, $names, $re)>

Imports several variables, whose names are passed through a list referenced by $names,
using '=' as separator and the same $re regular expression for all checks.
Returns a reference to a hash keyed by the variable names and containing their 
imported values, or C<undef> in case of error.
This function does not check that every variable in @{$names} is effectively imported.

=cut

sub clip_import_conf_many($$$) {
	my ($file, $names, $re) = @_;


	return clip_import_conf_many_sep($file, $names, $re, "=");
}

=item B<clip_import_conf_all_sep($file, $names, $re, $sep)>

Imports several variables, whose names are passed through a list referenced by $names,
using the same $sep string as separator and the same $re regular expression for all checks.
Returns a reference to a hash keyed by the variable names and containing their 
imported values, or C<undef> in case of error.
This function returns an error if no valid definition is found in $file for one of the 
variables in @{$names}.

=cut

sub clip_import_conf_all_sep($$$$) {
	my ($file, $names, $re, $sep) = @_;

	my $vars = clip_import_conf_many_sep($file, $names, $re, $sep);

	my $ok = 1;
	foreach my $name (@{$names}) {
		if (not defined($vars->{$name})) {
			clip_warn "failed to import $name from $file";
			$ok = 0;
		}
	}

	return ($ok) ? $vars : undef;
}
	
=item B<clip_import_conf_all($file, $names, $re)>

Imports several variables, whose names are passed through a list referenced by $names,
using '=' as separator and the same $re regular expression for all checks.
Returns a reference to a hash keyed by the variable names and containing their 
imported values, or C<undef> in case of error.
This function returns an error if no valid definition is found in $file for one of the 
variables in @{$names}.

=cut

sub clip_import_conf_all($$$) {
	my ($file, $names, $re) = @_;

	return clip_import_conf_all_sep($file, $names, $re, "=");
}

1;
__END__

=head1 SEE ALSO

CLIP::Logger(3)

=head1 AUTHOR

Vincent Strubel, E<lt>clip@ssi.gouv.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 SGDN

All rights reserved.


=cut
