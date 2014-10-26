package GID;
BEGIN {
  $GID::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::VERSION = '0.001';
}
# ABSTRACT: Get It Done - with Perl


use strictures 1;
use Import::Into;
use Package::Stash;

my %gid_packages = (
	DB => 'GID::DB',
	Web => 'GID::Web',
);

my @packages = (
	'utf8' => undef,
	'Carp::Always' => undef,
	'Path::Class' => [qw(
		file
		dir
	)],
	'Carp' => [qw(
		confess
		croak
		carp
	)],
	'File::ShareDir' => [qw(
		dist_dir
		module_dir
		class_dir
	)],
	'File::Copy::Recursive' => [qw(
		dircopy
	)],
	'File::Remove' => [qw(
		remove
	)],
	'List::MoreUtils' => [qw(
		any
		all
		none
		notall
		firstidx
		first_index
		lastidx
		last_index
		insert_after
		insert_after_string
		apply
		indexes
		after_incl
		before_incl
		firstval
		first_value
		lastval
		last_value
		each_array
		each_arrayref
		pairwise
		natatime
		mesh
		zip
		uniq
		distinct
		minmax
		part
	)],
	'Scalar::Util' => [qw(
		blessed
		dualvar
		isweak
		readonly
		refaddr
		reftype
		tainted
		weaken
		isvstring
		looks_like_number
		set_prototype
	)],
	'DDP' => [qw(
		+p
	)],
	'IO::All' => [qw(
		+io
	),[qw(
		-utf8
	)]],
);

my @packages_order;
my %packages_parsed;

my %import_args;

sub import {
	my $target = scalar caller;

	return if defined $import_args{$target};

	my $class = shift;
	my @args = @_;

	$class->_gid_import($target,@args);

	my $stash = Package::Stash->new($target);
	$stash->add_symbol('&package_stash',sub { $stash });

	$stash->add_symbol('&env',sub {
		my $key = join('_',@_);
		return defined $ENV{$key} ? $ENV{$key} : "";
	});
}

sub _gid_import {
	my ( $class, $target, @args ) = @_;
	$class->_gid_load_packages;
	$class->_gid_parse_import_args($target, @args);
	my %include;
	my %exclude;
	my %features;
	%include = %{$import_args{$target}->{include}} if defined $import_args{$target}->{include};
	%exclude = %{$import_args{$target}->{exclude}} if defined $import_args{$target}->{exclude};
	%features = %{$import_args{$target}->{features}} if defined $import_args{$target}->{features};
	for (@packages_order) {
		$class->_gid_import_package(
			$target,
			$_,
			$packages_parsed{$_},
			[\%include,\%exclude,\%features],
			@args
		);
	}
}

sub _gid_load_packages {
	my ( $self ) = @_;

	return if %packages_parsed;

	while (@packages) {
		my $package = shift @packages;
		my $value = shift @packages;
		my @values = ref $value eq 'ARRAY'
			? @{$value}
			: defined $value
				? ($value)
				: ();
		my @package_functions;
		my @package_import_args;
		my @package_features;
		for (@values) {
			if (ref $_ eq '') {
				if ($_ =~ m/^\+([\w^+]+)$/) {
					push @package_functions, $1;
				} elsif ($_ =~ m/^:(\w+)$/) {
					push @package_features, $1;
				} else {
					push @package_functions, $_;
					push @package_import_args, $_;
				}
			} elsif (ref $_ eq 'ARRAY') {
				push @package_import_args, @{$_};
			}
		}
		push @packages_order, $package;
		$packages_parsed{$package} = [
			\@package_functions,
			\@package_import_args,
			\@package_features,
		];
	}
}

sub _gid_parse_import_args {
	my ( $class, $target, @args_list ) = @_;
	my %args;
	for (@args_list) {
		if ($_ =~ m/^-(.*)/) {
			$args{exclude} = {} unless defined $args{exclude};
			$args{exclude}->{$1} = 1;
		} elsif ($_ =~ m/^\+(.*)/) {
			$args{feature} = {} unless defined $args{feature};
			$args{feature}->{$1} = 1;
		} else {
			$args{include} = {} unless defined $args{include};
			if ($gid_packages{$_}) {
				$args{include}->{$gid_packages{$_}} = 1;
			} else {
				$args{include}->{$_} = 1;
			}
		}
	}
	die __PACKAGE__.": you can't define -exclude's and include's on import of GID"
		if defined $args{exclude} and defined $args{include};
	$import_args{$target} = \%args;
}

sub _gid_import_package {
	my ( $class, $target, $import, $package_parse, $include_exclude_features, @args ) = @_;
	my @package_functions = @{$package_parse->[0]};
	my @package_import_args = @{$package_parse->[1]};
	my @package_features = @{$package_parse->[2]};
	my %include = %{$include_exclude_features->[0]};
	my %exclude = %{$include_exclude_features->[1]};
	my %features = %{$include_exclude_features->[2]};
	my $load_package = 0;
	my @use_import_args;
	if (%include) {
		if (defined $include{$import}) {
			$load_package = 1;
		} else {
			for my $pf (@package_functions) {
				if (grep { $_ eq $pf } keys %include) {
					$load_package = 1;
					for my $pia (grep { $_ eq $pf } @package_import_args) {
						push @use_import_args, $pia;
					}
				}
			}
		}
	} elsif (%exclude) {
		unless (defined $exclude{$import}) {
			my @not_excluded_package_functions;
			for my $pf (@package_functions) {
				unless (defined $exclude{$pf}) {
					push @not_excluded_package_functions, $pf;
					for my $pia (grep { $_ eq $pf } @package_import_args) {
						push @use_import_args, $pia;
					}
				}
			}
			if (@not_excluded_package_functions) {
				$load_package = 1;
			}
		}
	} else {
		$load_package = 1;
		@use_import_args = @package_import_args;
	}
	if (%features) {
		# TODO
	}
	if ($load_package) {
		$import->import::into($target,@use_import_args);
	}
}

1;

__END__
=pod

=head1 NAME

GID - Get It Done - with Perl

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use GID;

=head1 DESCRIPTION

This library is made for beginners and people who want to instantly solve
their problems in Perl. It imports lots of standard functions inside your
scope and so makes it easy for you to work with Perl, without thinking about
which modules you need to use. All functions are described in this
documentation.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

