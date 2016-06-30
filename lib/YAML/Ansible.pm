package YAML::Ansible;

use 5.006;
use strict;
use warnings;

use Carp;
use English qw( -no_match_vars );
use Data::Dumper;
use base qw(YAML);
use Exporter qw(import);

our %EXPORT_TAGS = (
    all => [qw(
        LoadFile
        )],
);

# Symbol to export by default
Exporter::export_tags('all');

=head1 NAME

YAML::Ansible - The great new YAML::Ansible!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use YAML::Ansible;

    my $foo = YAML::Ansible->new('file.yaml');
    $foo->getData(qw( path to variable ));


=head1 FUNCTIONS/METHODS

=cut

use fields
    'data'
;

=pod

=head2 new()

Creates a new object of YAML::Ansible

=cut

sub new {
    my $self = shift;
    my ( $param ) = @ARG;
    unless ( ref $self ) {
        $self = fields::new($self);
    }
    if ( defined $param->{file} ) {
        $self->LoadFile($param->{file});
    }
    return $self;
}

=pod

=head2 LoadFile()

Loads YAML file from given path and set B<data> field to hash structure.

=cut

sub LoadFile {
    my ( $self, $file );
    if ( ! ref $ARG[0] ) {
        $file = shift;
    }
    else {
        ( $self, $file ) = @ARG;
    }
    my $data = YAML::LoadFile($file);
    if ( ref $self ) {
        $self->{data} = $data;
    }
    else {
        return $data;
    }
}

=pod

=head2 getData()

Gets configuration for proper path hash reference which contains YAML configuration.
If returned value is scalar and has $ then is evaluated.

    $self->getData( qw(directory root linux) );
    # returns $HOME/$HOSTNAME and it is evaluated to eg. /u/U537501/gdndevfc

If returned value is ref to array then returns array (in list context).

    my @airlines = $self->getData( 'airlines', $HOSTNAME );
    # returns [ AF, AR, AV, CZ, AD ] for gdnvlnx75

=cut

sub getData {
    my $self = shift;
    my @param = @ARG;
    my $ref = $self->{data};
    # breadcrumbs
    my $path = '';
    foreach my $key ( @param ) {
        $path = $path ? "$path->$key" : $key;
        if ( exists $ref->{$key} ) {
            $ref = $ref->{$key};
        }
        else {
            print STDERR "Missing value in data for '$key' for full path: '$path'.\n";
            return;
        }
    }


    return $self->expandVariables($ref);
}

sub expandVariables {
    my $self = shift;
    my ( $ref ) = @ARG;

    if ( ! ref $ref ) {
        if ( my ( @vars ) = $ref =~ m/\{\{([^}]*)\}\}/g ) {
            for my $var ( @vars ) {
                $var =~ s/^\s*|\s$//mg;
                my @path = ( $var );
                if ( $var =~ m{/} ) {
                    @path = split /\//, $var;
                }
                my $value = $self->getData(@path);
                $ref =~ s/\{\{(\s*)$var(\s*)\}\}/$value/g;
            }
        }
        if ( not defined wantarray ) {
            $ARG[0] = $ref;
        }
        return $ref;
    }
    elsif ( ref $ref eq 'ARRAY' ) {
        foreach my $element ( @{$ref} ) {
            $self->expandVariables($element);
        }
        if ( wantarray ) {
            return @{ $ref };
        }
        elsif ( defined wantarray ) {
            return $ref;
        }
    }
    elsif ( ref $ref eq 'HASH' ) {
        for my $key ( keys %{$ref} ) {
            $ref->{$key} = $self->expandVariables($ref->{$key});
        }
        return $ref;
    }

}

=head1 AUTHOR

Piotr Rogoza, C<< <piotr.rogoza at lhsystems.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::Ansible

=cut

1;
