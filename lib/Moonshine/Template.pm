package Moonshine::Template;

use strict;
use warnings;

our $VERSION = '0.02';

use Moonshine::Element;
use Ref::Util qw/:all/;

our @ISA;
BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS;

BEGIN {
    %HAS = ( base_element => sub { undef }, );
}

sub BUILD {
    my ( $self, $build_args ) = @_;

    my $config = $build_args->{config} // $self->can('config') && $self->config;

    my $base_element = $self->add_base_element( $build_args->{base_element}
          // delete $config->{base_element} );

    if ( defined $config ) {
        $config = $self->_process_config( $config, $base_element );
    }

    die "build_html is not defined" unless $self->can('build_html');

    $base_element = $self->build_html($base_element);

    $self->{base_element} = $base_element;
    return;
}

sub add_base_element {
    my ( $self, $base_element_args ) = @_;
    !$base_element_args
      and $self->can('base_element')
      and $base_element_args = $self->base_element;
    return
      defined $base_element_args
      ? Moonshine::Element->new($base_element_args)
      : undef;
}

sub render {
    return $_[0]->{base_element}->render;
}

sub _process_config {
    my ( $self, $config, $element ) = @_;

    my $ordered_config = $self->_config_to_arrayref($config);

    for ( @{$ordered_config} ) {
        my $key   = ( keys %{$_} )[0];
        my $value = $_->{$key};

        grep { defined $value->{$_}, } qw/action target template tag/ or next;

        $value->{tag}
          and $config->{$key} = $self->add_base_element($value)
          and next;

        if ( my $template = $value->{template} ) {
            my $template_args = $value->{template_args} // {};
            my $processed_template_element =
              $template->new($template_args)->{base_element};
            if ( my $target = $value->{target} ) {
                my $actual_target =
                  $target eq 'base_element' ? $element : $config->{$target};
                my $action = $value->{action} // 'add_child';
                $actual_target->$action($processed_template_element);
            }
            $config->{$key} = $processed_template_element;
        }

    }

    for ( keys %{$config} ) {
        _make_shine( $_, $config );
    }

    return $config;
}

sub _config_to_arrayref {
    my ( $self, $config ) = @_;

    my @configs = ();
    my @keys    = keys %{$config};
    my $previous;
    while (@keys) {
        my $key = shift @keys;

        my $value = $config->{$key};

        grep { defined $value->{$_}, } qw/action target template tag/
          or push @configs, { $key => $value }
          and next;

        $previous && $previous eq $key
          and die "$key target - $value->{target} does not exist in the spec"
          or $previous = $key;

        my $target = $value->{target}
          or unshift @configs, { $key => $value }
          and next;

        $target eq 'base_element'
          and unshift @configs, { $key => $value }
          and next;

        my $success = 0;
        if ( my $config_count = scalar @configs ) {
            for ( my $index = 0 ; $index < $config_count ; $index++ ) {
                if ( my $target_found = $configs[$index]->{$target} ) {
                    splice @configs, $index + 1, 0, { $key => $value };
                    $success = 1;
                    last;
                }
            }
        }
        unless ($success) {
            push @keys, $key;
        }
    }

    return \@configs;
}

sub _make_shine {
    my ( $key, $config ) = @_;

    {
        no strict 'refs';
        no warnings 'redefine';
        {
            *{"has_$key"} = sub {
                my $val = $config->{$key};
                defined $val or return undef;
                is_arrayref($val) and return scalar @{$val};
                is_hashref($val) and return map { $_; }
                  sort { $a <=> $b or $a cmp $b }
                  keys %{$val};
                return 1;
              }
        };
        {
            *{"$key"} = sub {
                my $val = $config->{$key};
                defined $_[1] or return $val;
                is_arrayref($val) && not is_arrayref( $_[1] )
                  and return push @{$val}, $_[1];
                is_hashref($val) and ( is_hashref( $_[1] )
                    and return
                    map { $config->{$_} = $_[1]->{$_} } keys %{ $_[1] } )
                  or ( is_scalarref( \$_[1] ) and return $val->{ $_[1] } );
                $config->{$key} = $_[1] and return;
              }
        };
    };

    return 1;
}

1;

__END__

=head1 NAME

Moonshine::Template - Template some more html.

=head1 VERSION

Version 0.2 


=head1 SYNOPSIS

    package MyApp::Template::World

    our @ISA; BEGIN { @ISA = 'Moonshine::Template' }

    ***** now you have a choice - however a base element is required *****
    sub base_element {
       return {
          tag => 'div'
          class => 'test'
       }
    }

    sub build_html {
        my ($self, $base) = @_;

        my $ul = $base->add_child({ tag => 'ul' });
    	for (qw/one two three/) {
            $ul->add_child({ tag => 'li', class => $_, data => [ $_ ] });
        }
        return $base;
    }
 
    ***** or *****
    MyApp::Template::World->new({ base_element => { tag => div, class => test }});
    
    sub build_html {
        my ($self, $base) = @_;
        ...
    }                          


    ***** or *****
    sub build_html {
       my $self = shift; 

       my $base = $self->add_base_element({ tag => 'div' });
       ...
    }
           
    package My::Template;

    My::Template->new( config => ... );

    sub config { 
        return {
            header => {
                title => 'Page1',
                content => 'just a hash',
            },
            body => {
               paragraph1 => 'something something',
            },
            content => {
                1 => 'some more content',
                2 => 'some other thing',
                3 => 'something else',
            },
            footer => {
               name => 'lnation',
               email => 'thisusedtobeanemail@gmail.com',
            }
        };
    };

    sub build_html {
        my ($self, $base) = @_;

        $base->add_child($self->header->{title});
        ....
    }
   
    ......          

    package Test::Template;

    sub config {
        return {
            base_element => {
                tag => 'html',
            },
            header => {
                template => 'Test::Header',
                template_args => {
                    title => 'Some title',
                    content => {
                        paragraph1 => 'some more text',
                    }
                },
                target => 'base_element'
            },
            body => {
                template => 'Test::Body',
                template_args => {
                    content => 'Some more text',
                },
                action => 'add_after_element',
                target => 'header',
            },
            footer => {
                target => 'body',
                action => 'add_child',
                ....
            }
        };
    }          


=head1 Template

=head2 build_html

Required - Your entry point to build some templated html.

=head2 base_element

Required - look here - L<Moonshine::Element>.
  
=head1 Render

    my $html = MyApp::Template::World->new->render;
    ....
    <div class="content"><ul><li class="one">one</li><li class="two">two</li><li
    class="three">three</li></ul></div>

=head1 AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>

=head1 CONFIGURATION AND ENVIRONMENT

=head1 INCOMPATIBILITIES

=head1 LICENSE AND COPYRIGHT
 
Copyright 2016 Robert Acock.
 
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:
 
L<http://www.perlfoundation.org/artistic_license_2_0>
 
Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.
 
If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.
 
This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
 
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.
 
Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.







