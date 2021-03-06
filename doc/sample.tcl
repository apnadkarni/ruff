# This file contains a sample that demonstrates Ruff!'s documentation
# features. It also serves as test input.

namespace eval ruff::sample {
    variable _ruff_preamble {
        ## Introduction

        The code in this namespace illustrates the various documentation
        features in [Ruff!](ruff.html). The corresponding source is
        [here](sample.tcl) or click the *Show source* link below each procedure
        or method documentation to see the source from which the
        documentation was generated. See the main [::ruff] documentation
        for a full description.

        The documentation (such as this section) not specific to a *procedure*
        or *method* is placed in the variable `_ruff_preamble` within each
        namespace.

        ## Formatting

        The formatting elements described below may appear both within
        `_ruff_preamble` content as well as proc and method comments.

        ### Lists

        This is an **unnumbered list**.
        ````
          * First item
          * Second
          item
          across multiple lines
          * Third item
        ````
        This is displayed as

        * First item
        * Second
        item
        across multiple lines
        * Third item


        This is a **definition list**.
        ````
          itema - Definition of item A
          itemb - Definition of item B
            across multiple lines.
        ````

        Definition lists are displayed in an output-specific format.

        itema - Definition of item A
        itemb - Definition of item B
        across multiple lines.

        ### Inline formatting

        ````
        Basic markdown inline formatting is supported as
        `code`, *emphasis*, **strong** and ***strong emphasis***.
        ````
        Basic markdown inline formatting is supported as
        `code`, *emphasis*, **strong** and ***strong emphasis***.

        ### Links

        ````
        Links may be references to program elements, e.g. [Derived], to
        external resources, e.g. [example](https://www.example.com) or
        explicit, e.g. <https://ruff.magicsplat.com>.
        ````
        Links may be references to program elements, e.g. [Derived], to
        external resources, e.g. [example](https://www.example.com) or
        explicit, e.g. <https://ruff.magicsplat.com>.

        ### Preformatted blocks

        ````
        ```
        Lines consisting of *3* or more backquotes can be used
        to bracket unformatted content
        like
        this paragraph.
        ```
        ````

        The remaining sections show how commands and classes are documented.
        Click on the *Show source* link to see the underlying source code
        for the procedure or method from which the documentation was generated.

        ### Images

        Images can be specified using either Markdown or HTML:

        * ![alt img](ruff_logo.png) `![alt img](ruff_logo.png)`
        * <img src='ruff_logo.png'/> `<img src='ruff_logo.png'/>`
    }

    namespace eval ensemble_proc {
        proc cmdA {} {
            # Implements cmdA for an ensemble procedure
        }
    
        proc cmdB {} {
            # Implements cmdB for an ensemble procedure

        }
        namespace export *
        namespace ensemble create
    }
}

proc ruff::sample::proc_without_docs {first_arg second_arg} {
}

proc ruff::sample::proc_full {arg {optarg AVALUE} args} {
    # This first line is the summary line for documentation.
    # arg - first parameter
    # optarg - an optional parameter
    # -switch VALUE - an optional switch
    #
    # This is the general description of the procedure
    # composed of multiple paragraphs. It is separated from
    # the parameter list above by one or more empty comments.
    #
    # This is the second paragraph. The next paragraph (in the *source* comments)
    # starts with the word Returns and hence will be treated
    # by Ruff! as describing the return value.
    #
    # Returns a value. Because it started with the **Returns**
    # keyword, this paragraph is treated as the return value
    # description no matter where it appears.
    #
    # A definition list has a similar form to the argument
    # list. For example, optarg may take the following values:
    #  AVALUE - one possible value
    #  BVALUE - another possible value
    #
    #  CVALUE - a third value but note the intervening blank comment
    #  above in the source code.
    # Bullet lists are indicated by a starting `-` or `*` character.
    # - This is a bullet list iterm
    # * This is also a bullet list item
    #
    # An optional *See also* section may be used to
    # cross-reference other program elements. Each line of this section
    # must be parsable as a Tcl list.
    #
    # See also: proc_without_docs [Base] <https://www.magicsplat.com>
    #   "ensemble_proc cmdA" {ensemble_proc cmdB}


    # This paragraph will be ignored by Ruff! as it is not part
    # of the initial block of comments.

    some code

    #ruff
    # Thanks to the #ruff marker, this paragraph will be
    # included by Ruff! even though it is not in the initial block
    # of comments. This is useful for putting documentation for
    # a feature right next to the code implementing it.

    some more code.
}

proc ruff::sample::character_at {text {pos 0}} {
    # Get the character from a string.
    #  text - Text string.
    #  pos  - Character position. 
    # The command will treat negative values of $pos as offset from
    # the end of the string.
    #
    # Note the use of `Returns:` as opposed to `Returns` (i.e. with a colon) in
    # the source comments. See docs for the difference.
    #
    # Returns: The character at index $pos in string $text.
    set n [string length $text]
    if {[tcl::mathfunc::abs $pos] >= [string length $text]} {
        #ruff
        # An error exception is raised if $pos is not within bounds.
        error "Index $pos out of bounds."
    }
    if {$pos < 0} {
        return [string index $text end$pos]
    } else {
        return [string index $text $pos]
    }
}

oo::class create ruff::sample::Base {
    constructor {arg} {
        # Constructs the class
        #   arg - argument to constructor
        # The constructor for the class should also include
        # general information for the class.
    }
    destructor {
        # Releases all resources and destroys the class
    }
    method base_method {arga argb}  {
        # base_method is defined only in the base class
        # arga - first argument
        # argb - second argument from
        #
        # This is method m1
        #
        # This is a reference to method [<tag>].
        #
        # See also: <tag>
    }
    method overridable_method {} {
        # This method will be overridden in the derived class
        #
        # Calls [base_method]
    }
    method <tag> {} {
        # An explicitly exported method looking like a html tag
        #
        # Verify it also shows in [base_method] description as well
        # as See also section.
    }
    forward fwd_method string range
    export <tag>

}

oo::class create ruff::sample::Mixin {
    method mixed_in_method {arg} {
        # This method will be mixed into a class.
        # arg - an argument to the method
    }
}

oo::class create ruff::sample::Derived {
    superclass ::ruff::sample::Base
    mixin ::ruff::sample::Mixin
    method overridable_method {} {
        # This method overrides the one defined in [Base].
    }
    method added_method {} {
        # Method defined only in [Derived].
    }
}

oo::class create ruff::sample::FunnyMethods {
    constructor {} {
        # Class for testing special characters in method names
    }
    method + {} {
        # Method to test regexp special chars
    }
    method * {} {
        # Method to test regexp special chars
    }
    method > {} {
        # Method to test > escaping in HTML
    }
    method < {} {
        # Method to test < escaping in HTML
    }
    method & {} {
        # Method to test & escaping in HTML
    }
    method _ {} {
        # Method to test underscores
    }
    export + * > < & _

}
