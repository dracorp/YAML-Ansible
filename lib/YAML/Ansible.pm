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
Exporter::export_ok_tags('yaml');

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

    use YAML::Ansible;

    my $foo = YAML::Ansible->new('file.yaml');
    $foo->getData(qw( path to variable ));
    # or in procedural way
    my $conf = LoadData('file.yaml');
    my $value = getData($conf, qw( path to variable ));

=head1 DESCRIPTION

The I<YAML::Ansible> module implements Ansible YAML and exactly Ansible variables. Ansible uses I<"{{ var }}"> for L<variables|http://docs.ansible.com/ansible/YAMLSyntax.html#gotchas>.
You can use I<"{{ var }}"> and I<"{{ path/to/variable }}"> for nested variables:

    ---
    version: 1.0
    name: foo
    url: "http://foo.com/{{ name }}"
    directory:
        main
            linux: $HOME/out
            windows: c:\out
        temp: tmp
    destination: {{ directory/main/linux }}

You can also use environment variables such as $HOME. Those variables will be expanded if defined. See L<perlvar>.

=head1 GLOBAL OPTIONS

The current options are:

=over

=item Expand

Expand environemt variables from data. The default is 1.

=back

=cut

our $Expand = 1;

=head1 METHODS AND SUBROUTINES

There are a few subroutines which are exported, such as LoadData, getData. But you can also use I<YAML>'s subroutines, eg. DumpFile.

    use YAML::Ansible qw(DumpFile);

There are two tags for I<YAML::Ansible>: I<:all> and I<:yaml>. Tag I<:yaml:> export L<YAML> subroutines, and I<:all> export all I<YAML::Ansible> subroutines.

=head2 new({ file => filepath })

Creates a new object of YAML::Ansible. If a filepath is defined then function load data using I<LoadData> and sets I<data> field used by I<getData>.

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

=head2 LoadData(filepath)

Reads the YAML file from given path and set I<data> field to hash structure of yaml file for OOP. In procedural way returns hash structure.

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
    return;
}

=pod

=head2 getData('path as list')

Gets configuration for proper path hash reference which contains YAML configuration.
If returned value is scalar and has $ then is evaluated.

    $self->getData( qw(directory main linux) );
    # returns $HOME/out and it is evaluated to eg. /home/foo/out

If returned value is ref to array then returns array (in list context).

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
    elsif ( ! ref $self ) {
        print STDERR "The first parameter should be reference to hash.";
        return;
    }
    my $ref = $self->{data};
    my $path = '';                              # breadcrumbs
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

=head2 setData({ path => 'path as list', value => 'value' })

Sets data for path and value.

=cut

sub setData {
    my $self = shift;
    if ( ref $self ne __PACKAGE__ and ref $self eq 'HASH' ) {
        my $tmp = __PACKAGE__->new();
        $tmp->{data} = $self;
        $self = $tmp;
        undef $tmp;
    }
    elsif ( ! ref $self ) {
        print STDERR "The first parameter should be reference to hash.";
        return;
    }
    my ( $param ) = @ARG;
    my @path = @{$param->{path}};
    my $value = $param->{value};
    my $ref = $self->{data};
    my $key = shift @path;
#    my $breadcrumbs = $key;
    while ( scalar @path > 0 ) {
#        $breadcrumbs = "$path->$key";
        $key = shift @path;
        $ref = $ref->{$key}
    }
    $ref->{$key} = $value;
}

=pod

=head2 expandVariables()

Expands Ansible variables from data. Ansible uses "{{ var }}" for variables. Method is recursive. Methods expands also environment variables if they are defined.
As input could be scalar, ref to array or ref to hash.

=cut

sub expandVariables {
    my $self = shift;
    my ( $ref ) = @ARG;

    if ( ! ref $ref ) {
        if ( $Expand and $ref =~ m/(\$\w+)/g ) {
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
        return $ref;
    }
    elsif ( ref $ref eq 'ARRAY' ) {
        foreach my $element ( @{$ref} ) {
            $element = $self->expandVariables($element);
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
    return;
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
    return if $sub eq 'DESTROY';
    if ( YAML->can($sub) ) {
        return YAML->can($sub)->(@ARG);
    }
    else {
        print STDERR "Undefined subroutine $AUTOLOAD";
    }
    return;
}

=head1 AUTHOR

Piotr Rogoza, C<< <piotr.r.public at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YAML::Ansible

=cut

1;
