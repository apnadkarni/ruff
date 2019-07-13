# This file contains a sample that demonstrates Ruff!'s documentation
# features. It also serves as test input.

namespace eval ruff::sample {
    variable _ruffdoc {
        == Introduction

        The code in this namespace illustrates the various documentation
        features in [Ruff!](ruff.html). The corresponding source is
        [here](sample.tcl) or click the *Show source* link below each procedure
        or method documentation to see the source from which the
        documentation was generated. See the main [::ruff] documentation
        for a full description.

        The documentation (such as this section) not specific to a *procedure*
        or *method* is placed in the variable `_ruffdoc` within each namespace.

        == Formatting

        The formatting elements may appear both within `_ruffdoc` content
        as well as proc and method comments.

        === Lists

        This is an **unnumbered list**.
          * First item
          * Second
          item
          across multiple lines
          * Third item

        This is a **definition list**.

          itema - Definition of item A
          itemb - Definition of item B

        === Inline formatting

        Basic markdown inline formatting is supported as
        `code`, *emphasis*, **strong** and ***strong emphasis***.

        === Links

        Links to program elements, e.g. [Derived], and to
        external resources, e.g. [example](https://www.example.com).

        === Preformatted blocks

        ````
        Lines consisting of *3* or more backquotes can be used
        to bracket unformatted content
        like
        this paragraph.
        ````
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
    # This is the second paragraph. The next paragraph
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
    # Bullet lists are indicated by a starting `-` or `*` character.
    # - This is a bullet list iterm
    # * This is also a bullet list item

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
    }
    method overridable_method {} {
        # This method will be overridden in the derived class
        #
        # Calls [base_method]
    }
    method <tag> {} {
        # An explicitly exported method 
    }
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
