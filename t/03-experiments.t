use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Moonshine::Template');
}

package Test::One;

our @ISA; BEGIN { @ISA = 'Moonshine::Template' };

BEGIN { our %HAS =  ( thing => sub { "okay" } ); };

sub build_html {
    my ($self) = shift;

    my $base_element = $self->add_base_element({ tag => "div", class => "content" });
    $base_element->add_child({ tag => "p", class => "testing", data => [$self->{thing}] });
    return $base_element;
}

package Test::Two;

our @ISA; BEGIN { @ISA = 'Moonshine::Template' };

sub config {
    return {
        base_element => {
            tag => 'div',
        },   
        stash => {
            one => 'thing',
            two => 'things',
        }
    }
}

sub build_html {
    my ($self, $base) = @_;

    my $stash = $self->stash;
    my $child_one = $base->add_child({ tag => 'p', data => [ $stash->{one} ]});
    my $child_two = $base->add_child({ tag => 'p', data => [ $stash->{two} ]});
    return $base;
}

package Test::Three;

our @ISA; BEGIN { @ISA = 'Moonshine::Template' };

sub config {
     return {
        base_element => {
            tag => 'div',
        },   
        stash => {
            1 => 'thing',
            2 => 'things',
        }
    }   
}

sub build_html {
    my ($self, $base) = @_;

    # in moonshine world
    for ($self->has_stash) {
        $base->add_child({ tag => 'p', data => [ $self->stash($_) ]});
    }
}

package main;

subtest 'okay' => sub {
    build_and_render({
        class => 'Test::One',
        expected => '<div class="content"><p class="testing">okay</p></div>'
    });
    build_and_render({
        class => 'Test::Two',
        expected => '<div><p>thing</p><p>things</p></div>'
    });
    build_and_render({
        class => 'Test::Three',
        expected => '<div><p>thing</p><p>things</p></div>'
    }); 
};

sub build_and_render {
    my $args = shift;

    ok(my $class = $args->{class}->new($args->{args} // {}));
    is($class->render, $args->{expected}, "render some html - $args->{expected}");
}

sub build_and_die {
    my $args = shift;

    eval { $args->{class}->new; };
    like($@, $args->{exception}, "dead - $args->{exception}");
}

sub add_child_test {
    my $args = shift;

    my $first = $args->{first_class}->new;
    my $second = $args->{second_class}->new;
    my $placement = $args->{placement};

    $first->{base_element}->add_child($second->{base_element}, $placement);
    is($first->render, $args->{expected_render}, "render - $args->{expected_render}");
}

done_testing();

1;








