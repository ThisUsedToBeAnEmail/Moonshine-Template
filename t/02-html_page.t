use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
}

package Test::Header;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub build_html {
    my ($self) = shift;

    my $base_element = $self->add_base_element( { tag => "head" } );
    $base_element->add_child( { tag => "title", data => ['Page Title'] } );
    return $base_element;
}

package Test::Body;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub base_element {
    return { tag => 'body', };
}

sub build_html {
    my ( $self, $base ) = @_;

    my $ul = $base->add_child( { tag => 'ul' } );
    for (qw/one two three/) {
        $ul->add_child( { tag => 'li', class => $_, data => [$_] } );
    }
    return $base;
}

package Test::Footer;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub base_element {
    return { tag => 'footer', };
}

sub build_html {
    my ( $self, $base ) = @_;

    $base->add_child( { tag => 'h1', data => ['lnation'] } );
    return $base;
}

package Test::HTML;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub config {
    return {
        base_element => {
            tag => 'html'
        },
        header => {
            action   => 'add_child',
            template => 'Test::Header',
            target   => 'base_element',
        },
        body => {
            action   => 'add_after_element',
            template => 'Test::Body',
            target   => 'header',
        },
        footer => {
            action   => 'add_child',
            template => 'Test::Footer',
            target   => 'body',
        },
    };
}

sub build_html {
    my ( $self, $base ) = @_;

    my $first_body_child = $self->body->children->[0];
    my $page_header = $first_body_child->add_before_element({ tag => 'h1', data => ['Page Heading']});

    return $base;
}

package Test::HTML2;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

sub config {
    return {
        body => {
            template => 'Test::Body',
        },
        footer => {
            template => 'Test::Footer',
        }
    };
}

sub base_element {
    return { tag => 'html' };
}

sub build_html {
    my ( $self, $base ) = @_;

    my $header = $base->add_child( { tag => 'head' } );
    my $page_title = $header->add_child( { tag => 'title', data => ['Page Title'] } );
    my $body = $base->add_child( $self->body->element );

    my $first_body_child = $body->children->[0];
    my $page_header      = $first_body_child->add_before_element(
        { tag => 'h1', data => ['Page Heading'] } 
    );

    my $footer = $body->add_child( $self->footer->element );

    return $base;
}

package Test::HTML::Simple;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' } 

sub config {
    return {
        base_element => {
            template => 'Test::HTML'
        },
    };
}

sub build_html {
    return $_[1];
}

package Test::HTML::Simple::Body;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' } 

sub config {
    return {
        base_element => {
            template => 'Test::HTML'
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
            class    => 'Test::Header',
            expected => '<head><title>Page Title</title></head>',
        }
    );
    build_and_render(
        {
            class => 'Test::Body',
            expected =>
'<body><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul></body>',
        }
    );
    build_and_render(
        {
            class    => 'Test::Footer',
            expected => '<footer><h1>lnation</h1></footer>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML',
            expected =>
'<html><head><title>Page Title</title></head><body><h1>Page Heading</h1><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul><footer><h1>lnation</h1></footer></body></html>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML2',
            expected =>
'<html><head><title>Page Title</title></head><body><h1>Page Heading</h1><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul><footer><h1>lnation</h1></footer></body></html>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML::Simple',
            expected => '<html><head><title>Page Title</title></head><body><h1>Page Heading</h1><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul><footer><h1>lnation</h1></footer></body></html>'
        }
    );
    build_and_render(
        {
            class => 'Test::HTML::Simple::Body',
            expected => '<html><head><title>Page Title</title></head><body><h1>Page Heading</h1><ul><li class="one">one</li><li class="two">two</li><li class="three">three</li></ul><footer><h1>lnation</h1></footer></body></html>'
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

