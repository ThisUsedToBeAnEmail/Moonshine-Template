use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
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
                    },
                },
            },
        },
    };
}

sub build_html {
    return $_[1];
}

package main;

subtest "build_and_render" => sub {
    build_and_render(
        {
            class => 'Test::HTML',
            expected =>
              '<html><head><title>Page Title</title></head><body></body></html>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML::Content',
            expected =>
'<div><h1>Hello World</h1><p>No, it will not make you blind.</p></div>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML::Wrapper',
            expected =>
'<html><head><title>Page Title</title></head><body><div><h1>Hello World</h1><p>No, it will not make you blind.</p></div></body></html>'
        }
    );
};

sub build_and_render {
    my $args = shift;

    ok( my $class = $args->{class}->new( $args->{args} // {} ) );
    is( $class->render, $args->{expected},
        "render some html $args->{class} - $args->{expected}" );
}

done_testing();

1;

