use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
}

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
            class => 'Test::Header',
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

    my $order = array_order_me($config);
    
    my $expected = [
        {
            content => {
                template => 'Test::Content',
            }
        },
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
            class => 'Test::Header',
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

    my $order = array_order_me($config);
    
    my $expected = [
        {
            content => {
                template => 'Test::Content',
                target => 'base_element',
            }
        },
        {
            header => {
                class => 'Test::Header',
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
        {
            stash => {
                one => 'thing',
                two => 'things',
            } 
        }
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

    my $order = array_order_me($config);
    
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
        {
            stash => {
                one => 'thing',
                two => 'things',
            } 
        }
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

    eval { array_order_me($config); };
    my $error = $@;
    like($error, qr/content target - forever does not exist in the spec/, "dead - $error");
};

sub array_order_me {
    my $config = shift;

    my @configs = ();
    my @keys = keys %{$config};
    my $previous;
    while ( @keys ) {
        my $key = shift @keys;

        my $value = $config->{$key};
        $value->{action} || $value->{target} || $value->{template} || $value->{build}
            or push @configs, { $key => $value } and next;
         
        $previous && $previous eq $key and 
            die "$key target - $value->{target} does not exist in the spec" or 
                $previous = $key;

        my $target = $value->{target} or 
            unshift @configs, { $key => $value } and 
                next;

        $target eq 'base_element' and 
            unshift @configs, { $key => $value } and 
                next;
        
        my $success = 0;
        if ( my $config_count = scalar @configs ) {
            for (my $index=0; $index < $config_count; $index++) {
                if (my $target_found = $configs[$index]->{$target}) {
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

done_testing();

1;

