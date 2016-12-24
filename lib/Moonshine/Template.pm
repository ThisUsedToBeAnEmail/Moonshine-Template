package Moonshine::Template;

use strict; 
use warnings;

our $VERSION = '0.02';

use Moonshine::Element;

our @ISA; BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS; BEGIN {
    %HAS = ( 
        base_element => sub { undef }
    );
}

sub BUILD {
    my ($self, $build_args) = @_;

    my $base_element_args = $build_args->{base_element};

    !$base_element_args and $self->can('base_element')
        and $base_element_args = $self->base_element;
   
    die "build_html is not defined" unless $self->can('build_html');
    
    my $base_element = $self->build_html($self->add_base_element($base_element_args));
    
    $self->{base_element} = $base_element;
    return;
};

sub add_base_element {
    return defined $_[1] ? Moonshine::Element->new($_[1]) : undef;
}

sub render {
    return $_[0]->{base_element}->render;
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







