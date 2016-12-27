package Moonshine::Element;

use strict;
use warnings;
use Ref::Util qw/:all/;
use UNIVERSAL::Object;
use Data::GUID;

our $VERSION = '0.03';

use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our @ISA;
BEGIN { @ISA = ('UNIVERSAL::Object') }
our %HAS;

BEGIN {
    my @ATTRIBUTES =
      qw/accept accept_charset accesskey action align alt async autocomplete
      autofocus autoplay autosave bgcolor border buffered challenge charset checked cite class
      code codebase color cols colspan content contenteditable contextmenu controls coords datetime
      default defer dir dirname disabled download draggable dropzone enctype for form formaction
      headers height hidden high href hreflang http_equiv icon id integrity ismap itemprop keytype
      kind label lang language list loop low manifest max maxlength media method min multiple muted
      name novalidate open optimum pattern ping placeholder poster preload radiogroup readonly rel
      required reversed rows rowspan sandbox scope scoped seamless selected shape size sizes span
      spellcheck src srcdoc srclang srcset start step style summary tabindex target title type usemap
      value width wrap/;

    %HAS = (
        (
            map {
                $_ => sub { undef }
              } @ATTRIBUTES,
            qw/parent/
        ),
        (
            map {
                $_ => sub { [] }
            } qw/data children after_element before_element/
        ),
        tag            => sub { die "$_ is required" },
        attribute_list => sub { \@ATTRIBUTES },
        guid           => sub { Data::GUID->new->as_string },
    );

    for my $attr ( @ATTRIBUTES,
        qw/data tag attribute_list children after_element before_element guid parent/
      )
    {
        no strict 'refs';
        {
            *{"has_$attr"} = sub {
                my $val = $_[0]->{$attr};
                defined $val or return undef;
                is_arrayref($val) and return scalar @{$val};
                is_hashref($val) and return map { $_; }
                  sort { $a <=> $b or $a cmp $b }
                  keys %{$val};
                return 1;
              }
        };
        {
            *{"clear_$attr"} = sub { undef $_[0]->{$attr} }
        };
        {
            *{"$attr"} = sub {
                my $val = $_[0]->{$attr};
                defined $_[1] or return $val;
                is_arrayref($val) && not is_arrayref( $_[1] )
                  and return push @{$val}, $_[1];
                is_hashref($val) && is_hashref( $_[1] )
                  and return
                  map { $_[0]->{$attr}->{$_} = $_[1]->{$_} } keys %{ $_[1] };
                $_[0]->{$attr} = $_[1] and return;
              }
        };
    }
}

sub build_element {
    my ( $self, $build_args, $parent ) = @_;
    
    $build_args->{parent} = $parent // $self;
    if (is_blessed_ref($build_args)){ 
        $build_args->isa('Moonshine::Element') and return $build_args or die "I'm not a Moonshine::Element";
    }
    return $self->new($build_args);
}

sub add_child {
    my $action = 'children';
    if ( defined $_[2] and my $parent = $_[0]->{parent} ) {
        my $guid  = $_[0]->guid;
        my $index = 0;
        ++$index until $parent->children->[$index]->guid eq $guid;
        ++$index if $_[2] eq 'after';
        my $element = $_[0]->build_element( $_[1], $parent );
        splice @{ $parent->{children} }, $index, 0, $element;
        return $element;
    }
    elsif ( defined $_[2] ) {
        $action = sprintf "%s_element", $_[2];
    }

    my $child = $_[0]->build_element( $_[1] );
    $_[0]->$action($child) and return $child;
}

sub add_before_element {
    return $_[0]->add_child( $_[1], 'before' );
}

sub add_after_element {
    return $_[0]->add_child( $_[1], 'after' );
}

sub render {
    my $html_attributes = '';
    for my $attribute ( @{ $_[0]->attribute_list } ) {
        my $html_attribute = $attribute;
        $html_attribute =~ s/_/-/;
        my $has_action = sprintf 'has_%s', $attribute;
        if ( $_[0]->$has_action ) {
            given ( ref $_[0]->{$attribute} ) {
                when (/HASH/) {
                    my $value = '';
                    map {
                        $value and $value .= ' ';
                        $value .= $_[0]->{$attribute}->{$_};
                    } $_[0]->$has_action;
                    $html_attributes .= sprintf '%s="%s" ',
                      $html_attribute, $value;
                }
                when (/ARRAY/) {
                    $html_attributes .= sprintf '%s="%s" ',
                      $html_attribute, ( join ' ', @{ $_[0]->{$attribute} } );
                }
                default {
                    $html_attributes .= sprintf '%s="%s" ',
                      $html_attribute, $_[0]->{$attribute};
                }
            }
        }
    }

    my $tag            = $_[0]->tag;
    my $render_element = $_[0]->_render_element;
    my $html           = sprintf '<%s %s>%s</%s>', $tag, $html_attributes,
      $render_element, $tag;

    if ( $_[0]->has_before_element ) {
        for ( @{ $_[0]->before_element } ) {
            $html = sprintf "%s%s", $_->render, $html;
        }
    }

    if ( $_[0]->has_after_element ) {
        for ( @{ $_[0]->after_element } ) {
            $html = sprintf "%s%s", $html, $_->render;
        }
    }

    return $_[0]->tidy_html($html);
}

sub _render_element {
    my $element;
    if ( $_[0]->has_children ) {
        for ( @{ $_[0]->children } ) {
            $element .= $_->render;
        }
    }
    $element .= $_[0]->text and return $element;
}

sub text {
    return $_[0]->has_data ? join ' ', @{ $_[0]->{data} } : '';
}

sub tidy_html {
    $_[1] =~ s/\s+>/>/g;
    return $_[1];
}

1;

__END__

=head1 NAME

Moonshine::Element - Build some more html.

=head1 VERSION

Version 0.03 

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Moonshine::Element;

    my $base = Moonshine::Element->new( tag => 'div' );

    my $child = $base->add_child({ tag => 'p' });
    $child->add_before_element({ tag => 'span' });
    $child->add_after_element({ tag => 'span' });

    $base->render
    .......

OUTPUT: <div><span></span><p></p><span></span></div>

=head1 ATTRIBUTES

=head2 Override/Set/Push

    $base->$attribute($p_tag);

=head2 Get

    $base->$attribute;
    $base->{$attribute}

=head2 Defined/Count/Keys
    
    $base->has_$attribute;

=head2 Clear

    $base->clear_$attribute;

=head2 Class Attributes
    

=head3 tag

html tag

=head3 data

Array, that holds the elements content, use text to join

=head3 children

elements can have children

=head3 after_element

Used when the element doesn't have a parent.

=head3 before_element

Used when the element doesn't have a parent.

=head3 attribute_list

List containing all valid attributes (could change per element)

=head3 guid

Unique Identifier 

=head2 HTML ATTRIBUTES

TODO actually apply some validation.

=head3 accept

List of types the server accepts, typically a file type.

Valid Elements: form, input

=head3 accept_charset

List of supportsed charsets

Valid Elements: form

=head3 accesskey

Defines a keyboard shortcut to activate or add focus to the element

Global

=head3 action

The URI of a program that processes the information submitted via the form

Valid Elements: form

=head3 align

Specifies the horizontal alignment of the element

Valid Elements: applet caption col colgroup hr iframe img table tbody td tfoot th thead tr

=head3 alt

Alternative text in case an image can't be displayed

Valid Elements: applet area img input

=head3 async

Indicates that the script should be executed asynchronously

Valid Elements: script

=head3 autofocus

The element should be automatically focused after the page is loaded

Valid Elements: button input keygen select textarea

=head3 autoplay

The audio or video should play as soon as possible

Valid Elements: audio video

=head3 autosave

Previous values should persist dropdowns of selectable values across page loads.

Valid Elements: input

=head3 bgcolor

Background color of the element, Note: This is a legacy attribute. Please use CSS background-color.

Valid Elements: body col colgroup marquee table tbody tfoot td th tr

=head3 border

The Border width. Note: This is a legacy attribute. Please use the CSS border property instead.

Valid Elements: img object table

=head3 buffered

Contains the time range of already buggered media

Valid Elements: audio video

=head3 Challenge

A challenge string that is submitted along with the public key

Valid Elements: keygen

=head3 charset

Declares the character encoding of the page or script

Valid Elements: meta script

=head3 checked

Indicates whether the element should be checked on page load

Valid Elements: command input

=head3 cite

Contains a URI which points to the source of the quote or change

Valid Elements: blockquote

=head3 code

Specifies the URL of the applet's class file to be loaded and executed

Valid Elements: applet

=head3 codebase

This attribute gives the absolute or relative URL of the directory where 
applets' .class files referenced by the code attribute are stored.

Valid Elements: applet

=head3 color

This attribute sets the text color using either a named color or a color 
specified in the hexadecimal #RRGGBB format. Note: This is a legacy attribute. 
Please use the CSS color property instead.

Valid Elements: basefont font hr

=head3 cols

Defines the number of columns in a textarea.

Valid Elements: textarea

=head3 colspan

The colspan attribute defines the number of columns a cell should span.
 
Valid Elements: td, th

=head3 content

A value associated with http-equiv or name depending on the context.

Valid Elements: meta

=head3 contenteditable

Indicates whether the element's content is editable."
  
Valid Elements: 'Global attribute'

=head3 contextmenu

Defines the ID of a &lt;menu&gt; element which will serve as the element's context menu.
  
Valid Elements: 'Global attribute'

=head3 controls

Indicates whether the browser should show playback controls to the user.
  
Valid Elements: audio, video

=head3 coords

A set of values specifying the coordinates of the hot-spot region.

Valid Elements: area

=head3 datetime

Indicates the date and time associated with the element.
  
Valid Elements: del ins time

=head3 default

Indicates that the track should be enabled unless the user's preferences indicate something different.

Valid Elements: track

=head3 defer

Indicates that the script should be executed after the page has been parsed.
  
Valid Elements: script

=head3 dir

Defines the text direction. Allowed values are ltr (Left-To-Right) or rtl (Right-To-Left)
  
Valid Elements: 'Global attribute'

=head3 dirname
  
Valid Elements: input, textarea

=head3 disabled

Indicates whether the user can interact with the element.

Valid Elements: button, command, fieldset, input, keygen, optgroup, option, select, textarea'

=head3 download

Indicates that the hyperlink is to be used for downloading a resource.

Valid Elements: a, area

=head3 draggable

Defines whether the element can be dragged.

Valid Elements: 'Global attribute'

=head3 dropzone

Indicates that the element accept the dropping of content on it.
  
Valid Elements: 'Global attribute'

=head3 enctype
 
Defines the content type of the form date when the method is POST.
  
Valid Elements: form

=head3 for

Describes elements which belongs to this one.
  
Valid Elements: label, output

=head3 form

Indicates the form that is the owner of the element.
  
Valid Elements: button, fieldset, input, keygen, label, meter, object, output, progress, select, textarea'

=head3 formaction

Indicates the action of the element, overriding the action defined in the form'
  
Valid Elements: input, button

=head3 headers

IDs of the th elements which applies to this element.

Valid Elements: td, th

=head3 height

Specifies the height of elements listed here. For all other elements, 
use the CSS height property. Note: In some instances, such as div, 
this is a legacy attribute, in which case the CSS height property 
should be used instead.
  
Valid Elements: canvas, embed, iframe, img, input, object&gt, video

=head3 hidden

Prevents rendering of given element, while keeping child elements, e.g. script elements, active.

Valid Elements: 'Global attribute'

=head3 high

Indicates the lower bound of the upper range.

Valid Elements: meter

=head3 href

The URL of a linked resource.
  
Valid Elements: a, area, base, link

=head3 hreflang

Specifies the language of the linked resource.

Valid Elements: a, area, link

=head3 http-equiv
  
Valid Elements: meta

=head3 icon

Specifies a picture which represents the command.

Valid Elements: command

=head3 id

Often used with CSS to style a specific element. The value of this attribute must be unique.

Valid Elements: 'Global attribute'

=head3 integrity

Security Feature that allows browsers to verify what they fetch.A MDN Link
  
Valid Elements: link, script

=head3 ismap

Indicates that the image is part of a server-side image map.

Valid Elements: img

=head3 itemprop
  
Valid Elements: 'Global attribute'

=head3 keytype

Specifies the type of key generated.

Valid Elements: 'keygen'

=head3 kind

Specifies the kind of text track.
  
Valid Elements: track

=head3 label

Specifies a user-readable title of the text track.
  
Valid Elements: track

=head3 lang

Defines the language used in the element.
  
Valid Elements: 'Global attribute'

=head3 language

Defines the script language used in the element.
  
Valid Elements: script

=head3 list

Identifies a list of pre-defined options to suggest to the user.
  
Valid Elements: input

=head3 loop

Indicates whether the media should start playing from the start when it's finished.
  
Valid Elements: audio, bgsound, marquee, video

=head3 low
 
Indicates the upper bound of the lower range.

Valid Elements: meter

=head3 manifest
 
Specifies the URL of the document's cache manifest.
  
Valid Elements: html

=head3 max
 
Indicates the maximum value allowed.

Valid Elements: input, meter, progress

=head3 maxlength

Defines the maximum number of characters allowed in the element.

Valid Elements: input, textarea

=head3 media

Specifies a hint of the media for which the linked resource was designed.
  
Valid Elements: a, area, link, source, style

=head3 method

Defines which HTTP method to use when submitting the form. Can be GET (default) or POST .

Valid Elements: form

=head3 min

Indicates the minimum value allowed.

Valid Elements: input, meter

=head3 multiple

Indicates whether multiple values can be entered in an input of the type email or file.

Valid Elements: input, select

=head3 muted

Indicates whether the audio will be initially silenced on page load.

Valid Elements: video

=head3 name
 
Name of the element. For example used by the server to identify the fields in form submits.
  
Valid Elements: button, form, fieldset, iframe, input, keygen, 
object, output, select, textarea, map, meta, param

=head3 novalidate

This attribute indicates that the form shouldn't be validated when submitted.
  
Valid Elements: form

=head3 open

Indicates whether the details will be shown on page load.

Valid Elements: details

=head3 optimum
 
Indicates the optimal numeric value.

Valid Elements: meter

=head3 pattern

Defines a regular expression which the element's value will be validated against.

Valid Elements: input

=head3 ping
  
Valid Elements: a, area

=head3 placeholder

Provides a hint to the user of what can be entered in the field.

Valid Elements: input, textarea

=head3 poster

A URL indicating a poster frame to show until the user plays or seeks.

Valid Elements: video

=head3 preload

Indicates whether the whole resource, parts of it or nothing should be preloaded.

Valid Elements: audio, video

=head3 radiogroup
  
Valid Elements: command

=head3 readonly
 
Indicates whether the element can be edited.

Valid Elements: input, textarea

=head3 rel

Specifies the relationship of the target object to the link object.

Valid Elements: a, area, link

=head3 required
 
Indicates whether this element is required to fill out or not.

Valid Elements: input, select, textarea

=head3 reversed

Indicates whether the list should be displayed in a descending order 
instead of a ascending.

Valid Elements: ol

=head3 rows

Defines the number of rows in a text area.

Valid Elements: 'textarea'

=head3 rowspan

Defines the number of rows a table cell should span over.

Valid  Elements: td, th

=head3 sandbox
 
Valid Elements: iframe

=head3 scope

Valid Elements: th

=head3 scoped
  
Valid Elements: style

=head3 seamless
  
Valid Elements: iframe

=head3 selected
 
Defines a value which will be selected on page load.

Valid Elements: option

=head3 shape
  
Valid Elements: a, area

=head3 size
 
Defines the width of the element (in pixels). If the element's type 
attribute is text or password then it's the number of characters.

Valid Elements: input, select

=head3 sizes
 
Valid Elements: link, img, source

=head3 span
  
Valid Elements: col, colgroup

=head3 spellcheck
  
Indicates whether spell checking is allowed for the element.

Valid Elements: Global attribute

=head3 src
 
The URL of the embeddable content.

Valid Elements: audio, embed, iframe, img, input, script, source, track, video

=head3 srcdoc
  
Valid Elements: iframe

=head3 srclang
  
Valid Elements: track

=head3 srcset
  
Valid Elements: img

=head3 start
 
Defines the first number if other than 1.
  
Valid Elements: ol

=head3 step

Valid input

=head3 style

Defines CSS styles which will override styles previously set.

Valid Elements: 'Global attribute'

=head3 summary
  
Valid Elements: table

=head3 tabindex

Overrides the browser's default tab order and follows the one specified instead.

Valid Elements: 'Global attribute'

=head3 target
  
Valid Elements: a, area, base, form

=head3 title

Text to be displayed in a tooltip when hovering over the element.

Valid Elements: 'Global attribute'

=head3 type
 
Defines the type of the element.
  
Valid Elements: button, input, command, embed, object, script, source, style, menu

=head3 usemap
  
Valid Elements: img, input, object

=head3 value

Defines a default value which will be displayed in the element on page load.
  
Valid Elements: button, option, input, li, meter, progress, param

=head3 width

For the elements listed here, this establishes the element's width. Note: For 
all other instances, such as &lt;div&gt; , this is a legacy attribute, in which 
case the CSS width a property should be used instead.
  
Valid Elements: canvas, embed, iframe, img, input, object, video'

=head3 wrap

Indicates whether the text should be wrapped.

Valid Elements: textarea

=head1 SUBROUTINES

=head2 add_child

Accepts a Hash reference that is used to build a new Moonshine::Element
which is pushed into that elements children attribute.

    $base->add_child(
        {
            tag => 'div'
            ....
        }
    );

=head2 add_before_element

Accepts a Hash reference that is used to build a new Moonshine::Element, if the current
element has a parent, we slice in the new element before the current. If no parent exists the new element
is pushed in the before_element attribute.

    $base->add_before_element(
        {
            tag => 'div',
            ....
        }
    );

=head2 add_after_element

Accepts a Hash reference that is used to build a new Moonshine::Element, if the current
element has a parent, we slice in the new element after the current. If no parent exists the new element
is pushed in the after_element attribute.

    $base->add_after_element(
        {
            tag => 'div',
            ....
        }
    );

=head2 render

Render the Element as html.

    $base->render;

All attributes set on an 'Element' will be rendered. There is currently no Attribute to Element
validation.

Html attributes can be HashRef's (keys sorted and values joined), ArrayRef's(joined), or just Scalars.

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

