package GID::Class;
BEGIN {
  $GID::Class::AUTHORITY = 'cpan:GETTY';
}
{
  $GID::Class::VERSION = '0.001';
}
# ABSTRACT: Making your classes with GID


use strictures 1;
use Import::Into;
use Scalar::Util qw( blessed );

use GID ();
use MooX ();

sub import {
	my $class = shift;
	my $target = scalar caller;
	my @args = @_;

	GID->import::into($target,@args);

	my $stash = $target->package_stash;
	my @gid_methods = $stash->list_all_symbols('CODE');

	MooX->import::into($target,qw(
		ClassStash
		HasEnv
		Options
		Types::MooseLike
	));

	$target->can('extends')->('GID::Object');

	$target->class_stash->around_method('has',sub {
		my $has = shift;
		my $attribute_arg = shift;
		my @attribute_args = @_;
		my @attributes = ref $attribute_arg eq 'ARRAY' ? @{$attribute_arg} : ($attribute_arg);
		for my $attribute (@attributes) {
			if (grep { $attribute eq $_ } @gid_methods) {
				my $gid_method = $target->class_stash->get_method($attribute);
				$target->class_stash->remove_method($attribute);
				$has->($attribute,@attribute_args);
				$target->class_stash->around_method($attribute,sub {
					my $attribute_method = shift;
					my @args = @_;
					if (blessed $args[0]) {
						return $attribute_method->(@args);
					} else {
						return $gid_method->(@args);
					}
				});
			} else {
				$has->($attribute,@attribute_args);
			}
		}
	});

}

1;
__END__
=pod

=head1 NAME

GID::Class - Making your classes with GID

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package MyApp::Class;
  use GID::Class;

  has last_index => ( is => 'rw' );

  sub test_last_index {
    return last_index { $_ eq 1 } ( 1,1,1,1 );
  }

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

