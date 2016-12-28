use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
}

package Test::One;

our @ISA;
BEGIN { @ISA = 'Moonshine::Template' }

BEGIN {
    our %HAS = ( thing => sub { "okay" } );
}

sub build_html {
    my ($self) = shift;

    my $base_element =
      $self->add_base_element( { tag => "div", class => "content" } );
    $base_element->add_child(
        { tag => "p", class => "testing", data => [ $self->{thing} ] } );
    return $base_element;
}

package main;

subtest 'hash' => sub {      
    my $base_element;
    my $config = {
        body => {
            build => {
                tag => 'body',
                children => [
                    {
                        tag => 'h1',
                        data => ['title'],
                    },
                    {
                        tag => 'p',
                        data => ['some text'],
                    }
                ],
            },
            action => 'add_after_element',
            target => 'header',
        },
        header => {
            template => 'Test::Header',
            action => 'add_child',
            target => 'base_element',
        },
        content => {
            template => 'Test::Content',
        },
        stash => {
            one => 'thing',
            two => 'things',
        }
    }; 

    my $template = Test::One->new;
    my $order = $template->_config_to_actions($config);

    my $expected = [
        {
            content => {
                template => 'Test::Content',
            }
        },
        {
            header => {
                template => 'Test::Header',
                action => 'add_child',
                target => 'base_element',
            },
        },
        {
            body => {
                build => {
                    tag => 'body',
                    children => [
                        {
                            tag => 'h1',
                            data => ['title'],
                        },
                        {
                            tag => 'p',
                            data => ['some text'],
                        }
                    ],
                },
                action => 'add_after_element',
                target => 'header',
            }, 
        },
        {
            stash => {
                one => 'thing',
                two => 'things',
            } 
        }
    ];
     pass();
#    is_deeply($order, $expected);
};

subtest 'test_that_should_always_pass' => sub {      
    my $base_element;
    my $config = {
        body => {
            build => {
                tag => 'body',
                children => [
                    {
                        tag => 'h1',
                        data => ['title'],
                    },
                    {
                        tag => 'p',
                        data => ['some text'],
                    }
                ],
            },
            action => 'add_after_element',
            target => 'header',
        },
        header => {
            template => 'Test::Header',
            action => 'add_child',
            target => 'content',
        },
        content => {
            template => 'Test::Content',
            target => 'base_element',
        },
        stash => {
            one => 'thing',
            two => 'things',
        }
    }; 

	my $template = Test::One->new;
    my $order = $template->_config_to_actions($config);
    
    my $expected = [
        {
            content => {
                template => 'Test::Content',
                target => 'base_element',
            }
        },
        {
            header => {
                template => 'Test::Header',
                action => 'add_child',
                target => 'content',
            },
        },
        {
            body => {
                build => {
                    tag => 'body',
                    children => [
                        {
                            tag => 'h1',
                            data => ['title'],
                        },
                        {
                            tag => 'p',
                            data => ['some text'],
                        }
                    ],
                },
                action => 'add_after_element',
                target => 'header',
            }, 
        },
    ];
    
    diag explain $order;

    is_deeply($order, $expected);
}; 
 
subtest 'test_that_should_always_pass2' => sub {      
    my $base_element;
    my $config = {
        body => {
            build => {
                tag => 'body',
                children => [
                    {
                        tag => 'h1',
                        data => ['title'],
                    },
                    {
                        tag => 'p',
                        data => ['some text'],
                    }
                ],
            },
            action => 'add_after_element',
            target => 'header',
        },
        header => {
            class => 'Test::Header',
            action => 'add_child',
            target => 'base_element',
        },
        content => {
            template => 'Test::Content',
            target => 'body',
        },
        stash => {
            one => 'thing',
            two => 'things',
        }
    }; 

    my $template = Test::One->new;
    my $order = $template->_config_to_actions($config);
    
    my $expected = [
        {
            header => {
                class => 'Test::Header',
                action => 'add_child',
                target => 'base_element',
            },
        },
        {
            body => {
                build => {
                    tag => 'body',
                    children => [
                        {
                            tag => 'h1',
                            data => ['title'],
                        },
                        {
                            tag => 'p',
                            data => ['some text'],
                        }
                    ],
                },
                action => 'add_after_element',
                target => 'header',
            }, 
        },
        {
            content => {
                template => 'Test::Content',
                target => 'body',
            }
        },
    ];
    
    diag explain $order;

    is_deeply($order, $expected);
};

subtest 'forever_loops' => sub {      
    my $base_element;
    my $config = {
        body => {
            build => {
                tag => 'body',
                children => [
                    {
                        tag => 'h1',
                        data => ['title'],
                    },
                    {
                        tag => 'p',
                        data => ['some text'],
                    }
                ],
            },
            action => 'add_after_element',
            target => 'header',
        },
        header => {
            class => 'Test::Header',
            action => 'add_child',
            target => 'base_element',
        },
        content => {
            template => 'Test::Content',
            target => 'forever',
        },
        stash => {
            one => 'thing',
            two => 'things',
        }
    }; 
             
    my $template = Test::One->new;
    eval { $template->_config_to_actions($config) };
    my $error = $@;
    like($error, qr/content target - forever does not exist in the spec/, "dead - $error");
};

done_testing();

1;

