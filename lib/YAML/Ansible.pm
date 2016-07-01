package YAML::Ansible;

use 5.006;
use strict;
use warnings;

use Carp;
use English qw( -no_match_vars );
use Data::Dumper;
use base qw(YAML);
use YAML qw(LoadFile);
use Exporter qw(import);

our %EXPORT_TAGS = (
    all => [qw(
        getData
        LoadData
        )],
    yaml => \@YAML::EXPORT_OK,
);

our @EXPORT_OK = ( @YAML::EXPORT_OK );
# Symbol to export by default
Exporter::export_tags('all');
#Exporter::export_ok_tags('yaml');

use fields
    'data'
;

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

=head1 METHODS AND SUBROUTINES

There are a few subroutines which are exported, such as LoadData, getData. But you can also use I<YAML>'s subroutines, eg. DumpFile.

    use YAML::Ansible qw(DumpFile);

There are two tags for B<YAML::Ansible>: B<:all> and B<:yaml>. Tag B<:yaml:> export I<YAML> subroutines, and B<:all> export all B<YAML::Ansible> subroutines.

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
        $self->LoadData($param->{file});
    }
    return $self;
}

=pod

=head2 LoadData()

Loads YAML file from given path and set B<data> field to hash structure of yaml file.

=cut

sub LoadData {
    my ( $self, $file );
    if ( ! ref $ARG[0] ) {
        $file = shift;
    }
    else {
        ( $self, $file ) = @ARG;
    }
    my $data = LoadFile($file);
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
    if ( ref $self ne __PACKAGE__ and ref $self eq 'HASH' ) {
        my $tmp = __PACKAGE__->new();
        $tmp->{data} = $self;
        $self = $tmp;
        undef $tmp;
    }
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

=pod

=head2 expandVariables()

Expands Ansible variables from data. Ansible uses "{{ var }}" for variables. Method is recursive.

=cut

sub expandVariables {
    my $self = shift;
    my ( $ref ) = @ARG;

    if ( ! ref $ref ) {
        if ( $ref =~ m/(\$\w+)/g ) {
            $ref =~ s{
                \$
                (\w+)
            }{
                no strict 'refs';
                if ( defined $ENV{$1} ) {
                    $ENV{$1};
                } else {
                    "\$$1";
                }

            }egx;
        }
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
            if ( not ref $ref->{$key} ) {
                $ref->{$key} = $self->expandVariables($ref->{$key});
            }
            else {
                $self->expandVariables($ref->{$key});
            }
        }
        return $ref;
    }
}

=pod

=head2 AUTOLOAD

Autoloads missing subroutines for YAML package.

    use YAML::Ansible qw(:all DumpFile)
    ...
    DumpFile('file.yaml',$yaml_stream);

=cut

sub AUTOLOAD {
    our $AUTOLOAD;
    my $sub = ( split /::/, $AUTOLOAD )[-1];
#    my $mod = ( split /::([^:]+)$/, $AUTOLOAD )[0];
    return if $sub eq 'DESTROY';
    if ( YAML->can($sub) ) {
        return YAML->can($sub)->(@ARG);
    }
    else {
        print STDERR "Undefined subroutine $AUTOLOAD";
    }
}

=head1 AUTHOR

Piotr Rogoza, C<< <piotr.rogoza at lhsystems.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::Ansible

=cut

1;
