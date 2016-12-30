# NAME

Moonshine::Template - Template some more html.

# VERSION

Version 0.03 

# SYNOPSIS

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
          
           package Test::HTML;

           our @ISA;
           BEGIN { @ISA = 'Moonshine::Template' }

           sub config {
                   return {
                           base_element => {
                                   tag => 'html',
                           },
                           header => {
                                   build => {
                                           tag => 'head',
                                   },
                                   target => 'base_element',
                           },
                           page_title => {
                                   build => {
                                           tag  => 'title',
                                           data => 'Page Title',
                                   },
                                   target => 'header',
                           },
                           body => {
                                   build => {
                                           tag => 'body',
                                   },
                                   action => 'add_after_element',
                                   target => 'header',
                           },
                   };
           }

           sub build_html {
                   return $_[1];
           }

           package Test::HTML::Content;

           our @ISA;
           BEGIN { @ISA = 'Moonshine::Template' }

           sub config {
                   return {
                           base_element => {
                                   tag => 'div',
                           },
                           title => {
                                   tag  => 'h1',
                                   data => 'Hello World',
                           },
                           description => {
                                   tag  => 'p',
                                   data => 'No, it will not make you blind.'
                           }
                   };
           }

           sub build_html {
                   my ( $self, $base ) = @_;

                   $base->add_child( $self->title );
                   $base->add_child( $self->description );
                   return $base;
           }

           package Test::HTML::Wrapper;

           our @ISA;
           BEGIN { @ISA = 'Moonshine::Template' }

           sub config {
                   return {
                           base_element => {
                                   template      => 'Test::HTML',
                                   template_args => {
                                           config => {
                                                   content => {
                                                           template => 'Test::HTML::Content',
                                                           target   => 'body',
                                                   }
                                           }
                                   }
                           }
                   };
           }

           sub build_html {
                   return $_[1];
           }

# Template

## build\_html

Required - Your entry point to build some templated html.

## base\_element

Required - look here - [Moonshine::Element](https://metacpan.org/pod/Moonshine::Element).

## config

Optional - use with care.

# Render

    my $html = Test::HTML::Wrapper->new->render;
    
        ....
        <html>
                <head>
                        <title>Page Title</title>
                </head>
                <body>
                        <div>
                                <h1>Hello World</h1>
                                <p>No, it will not make you blind.</p>
                        </div>
                </body>
        </html>

# AUTHOR

Robert Acock <ThisUsedToBeAnEmail@gmail.com>

# CONFIGURATION AND ENVIRONMENT

# INCOMPATIBILITIES

# LICENSE AND COPYRIGHT

Copyright 2016 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
