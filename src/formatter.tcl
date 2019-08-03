# Copyright (c) 2019, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

namespace eval ruff::formatter {}

oo::class create ruff::formatter::Formatter {
    # Data members
    variable References; # Links for cross-reference purposes
    variable Options;    # Document generation options
    variable Namespaces; # Namespaces we are documenting
    variable SortedNamespaces;  # Exactly what it says

    constructor {} {
        # Base class for output formatters.
        namespace path [list ::ruff ::ruff::private]
    }

    method Option {opt {default {}}} {
        # Returns the value of an option.
        # opt - The option whose value is to be returned.
        if {[info exists Options($opt)]} {
            return $Options($opt)
        }
        return $default
    }
    method Option? {opt var} {
        # Check if option exists and store its variable.
        #  opt - The option of interest.
        #  var - The variable in the caller's context to store the value
        # The value of the option is stored in the variable $var in the
        # callers's context. The variable is unmodified if the option does
        # not exist.
        # Returns 1 if the option exists and 0 otherwise.
        if {[info exists Options($opt)]} {
            upvar 1 $var val
            set val $Options($opt)
            return 1
        }
        return 0
    }

    method Begin {} {
        # Begins the actual generation of the documentation set.
        # 
        # This method should be overridden by the concrete formatter.
        # It should generate appropriate content for the header and other
        # parts that are not dependent on the actual content.
        error "Method Begin not overridden."
    }

    method DocumentBegin {ns} {
        # Begins the generation of one document.
        #  ns - the namespace for the document. An empty string is passed
        #       for the main document.
        # This method should be overridden by the concrete formatter.
        # It should take any actions necessary to create a new document
        # in the documentation set. Subsequent calls to [fmtpara] and
        # other formatting methods should add to this document.
        error "Method DocumentBegin not overridden."
    }

    method DocumentEnd {} {
        # Ends the generation of the current document.
        #
        # Returns the completed document.
        #
        # This method should be overridden by the concrete formatter.
        error "Method DocumentEnd not overridden."
    }

    method AddHeading {level text scope {tooltip {}}} {
        # Adds a heading to document content.
        #  level   - The heading level. May be either a numeric level or
        #            a semantic one keying into the HeaderLevels dictionary.
        #  text    - The heading text.
        #  scope   - The documentation scope of the content.
        #  tooltip - Tooltip as list of lines to display in navigation link.
        # This method should be overridden by the concrete formatter.
        error "Method AddHeading not overridden."
    }

    method AddParagraph {lines scope} {
        # Adds a paragraph to document content.
        #  lines  - List of lines in the paragraph.
        #  scope - The documentation scope of the content.
        # This method should be overridden by the concrete formatter.
        error "Method AddParagraph not overridden."
    }

    method AddParagraphText {text scope} {
        # Adds a paragraph to the document content.
        #  text - Paragraph text to add.
        #  scope - The documentation scope of the content.
        # This is similar to [AddParagraph] except that it accepts a
        # text string as the paragraph as opposed to a list of lines.
        return [my AddParagraph [list $text] $scope]
    }

    method AddDefinitions {definitions scope {preformatted none}} {
        # Adds a definitions block to document content.
        #  definitions  - List of definitions.
        #  scope        - The documentation scope of the content.
        #  preformatted - One of `none`, `both`, `term` or `definition`
        #                 indicating which fields of the definition are
        #                 are already formatted.
        # Each element of $definitions is a dictionary with keys `term`
        # and `definition`. The latter is a list of strings comprising
        # the definition content.
        #
        # This method should be overridden by the concrete formatter.
        error "Method AddDefinitions not overridden."
    }

    method AddParameters {parameters scope} {
        # Adds a parameters section to document content.
        #  parameters - List of parameter definitions each being a dictionary
        #               with keys `type` (parameter or option), `term` being
        #               the parameter text and `definition` being the list of
        #               lines comprising the description.
        #  scope      - The documentation scope of the content.
        #
        # This method formats the parameters as a definition list with
        # arguments italized.

        if {[llength $parameters] == 0} {
            return;             # Do not want even heading if not parameters
        }
        my AddHeading parameters Parameters $scope
        # Construct a definition block for the parameters
        set definitions [lmap param $parameters {
            set definition [dict get $param definition]
            set term [my FormatInline [markup_code [dict get $param term]]]
            dict create term $term definition $definition
        }]
        my AddDefinitions $definitions $scope term
        return
    }

    method AddBullets {bullets scope} {
        # Adds a bulleted list to document content.
        #  bullets  - The list of bullets.
        #  scope    - The documentation scope of the content.
        # Each element of $bullets is a list of strings.
        #
        # This method should be overridden by the concrete formatter.
        error "Method AddBullets not overridden."
    }

    method AddPreformattedText {text scope} {
        # Adds preformatted text to document content.
        #  text  - Preformatted text as a string.
        #  scope - The documentation scope of the content.
        # This method should be overridden by the concrete formatter.
        error "Method AddPreformattedText not overridden."
    }

    method AddPreformatted {lines scope} {
        # Adds list of preformatted lines to document content.
        #  lines - Preformatted text as a list of lines.
        #  scope - The documentation scope of the content.
        # [Formatter] provides a base implementation that may be overridden.
        my AddPreformattedText [join $lines \n] $scope
        return
    }

    method AddReferences {xrefs scope {title {}}} {
        # Adds reference list to document content.
        #  xrefs - List of cross references.
        #  scope - The documentation scope of the conent.
        #  title - If not empty, a section title is also added.
        # [Formatter] provides a base implementation that may be overridden.
        if {[llength $xrefs] == 0} {
            return
        }
        if {$title ne ""} {
            my AddHeading nonav $title $scope
        }

        # aa bb -> "[aa], [bb]"
        # NOTE: the , in the join is not purely cosmetic. It is also a
        # workaround for Markdown syntax which treats [x] [y] with
        # only intervening whitespace as one text/linkref pair.
        # This Markdown behaviour differs from the CommonMark Markdown spec.
        my AddParagraphText [join [lmap xref $xrefs {
            markup_reference $xref
        }] ", " ] $scope
        return
    }

    method AddSynopsis {synopsis scope} {
        # Adds a Synopsis section to the document content.
        #  synopsis - List of two elements comprising the command portion
        #             and the parameter list.
        # [Formatter] provides a base implementation that may be overridden.
        my AddHeading nonav Synopsis $scope
        my AddPreformattedText [join $synopsis { }] $scope
        return
    }

    method AddSource {source scope} {
        # Adds a Source code section to the document content.
        #  source - Source code fragment.
        # [Formatter] provides a base implementation that may be overridden.
        my AddHeading nonav Source $scope
        my AddPreformattedText $source $scope
        return
    }

    method AddProcedure {procinfo} {
        # Adds documentation for a procedure or method.
        #  procinfo - dictionary describing the procedure.
        # The passed $procinfo dictionary holds the following keys:
        #  proctype     - `proc` or `method`
        #  display_name - The name to be displayed.
        #  fqn          - The fully qualified name used to construct references.
        #  synopsis     - Procedure synopsis as a 2-element list comprising
        #                 the command portion and the list of arguments.
        #  parameters   - List of parameters in the form of a definition
        #                 list.
        #  summary      - The summary text.
        #  body         - The main description section. A list of paragraphs
        #                 in the form accepted by [AddParagraphs].
        #  returns      - The text for the **Returns** section.
        #  seealso      - The list of cross references.
        #  source       - Source code for the procedure. Should be shown
        #                 if present.
        #
        # Only the proctype and display_name key are mandatory.
        #
        # This method may be overridden by the concrete formatter.

        dict with procinfo {
            # Creates the following locals
            #  proctype, display_name, fqn, synopsis, parameters, summary,
            #  body, seealso, returns, source
            #
            # Only the fqn and proctype are mandatory.
        }

        set scope [namespace qualifiers $fqn]
        if {[info exists summary]} {
            my AddProgramElementHeading proc $fqn $summary
            my AddParagraph $summary $scope
        } else {
            my AddProgramElementHeading proc $fqn
        }

        if {[info exists synopsis]} {
            my AddSynopsis $synopsis $scope
        }

        if {[info exists parameters]} {
            my AddParameters $parameters $scope
        }

        if {[info exists returns]} {
            my AddHeading nonav "Return value" $scope
            my AddParagraph $returns $scope
        }

        if {[info exists body] && [llength $body]} {
            my AddHeading nonav Description $scope
            my AddParagraphs $body $scope
        }

        if {[info exist seealso]} {
            my AddReferences $seealso $scope "See also"
        }

        if {[info exists source]} {
            my AddSource $source $scope
        }

        return

    }

    method CollectHeadingReference {ns heading} {
        # Adds a reference to a heading to the cross-reference table.
        #  ns - Namespace containing the heading
        #  heading - Text of the heading.
        # Returns the reference for the added heading.
        set ref [my HeadingReference $ns $heading]
        set reference [dict create type heading ref $ref]
        dict set References $heading $reference
        dict set References "${ns}::$heading" $reference
        return $ref
    }

    method CollectSymbolReference {ns symbol {ref {}}} {
        # Adds a reference for a symbol in a namespace to the cross-reference
        # table.
        #  ns     - Namespace containing the heading
        #  symbol - Text of the symbol.
        #  ref    - The reference to use. If empty, the reference is constructed
        #           from the symbol.
        # Returns the reference for the added heading.
        if {$ref eq ""} {
            set ref [my SymbolReference $ns $symbol]
        }
        set reference [dict create type symbol ref $ref]
        dict set References $symbol $reference
        return $ref
    }

    method Reference? {lookup refvar} {
        # Looks up the cross-reference table.
        #  lookup - The string to look up.
        #  refvar - Name of a variable in the caller's context to store the
        #           reference.
        # Returns 1 if the reference exists and stores it in $refvar otherwise
        # returns 0 without modifying the variable
        #
        # The value stored in $refvar is a dictionary with keys `type`
        # (`heading` or `symbol`) and `ref` (the reference).
        if {[dict exists $References $lookup]} {
            upvar 1 $refvar ref
            set ref [dict get $References $lookup]
            return 1
        }
        return 0
    }

    method ResolvableReference? {lookup scope refvar} {
        # Resolves a reference by searching through containing scopes.
        #  lookup - The string to look up.
        #  scope  - Namespace scope to search.
        #  refvar - Name of a variable in the caller's context to store result.
        #
        # If resolved successfully, the variable $refvar in the caller's
        # contains a dictionary with keys type (`heading` or `symbol`),
        # the ref, and label (display label).
        #
        # Returns 1 if the reference exists and stores it in $refvar otherwise
        # returns 0 without modifying the variable

        # If the label falls within the specified scope, we will hide the scope
        # in the displayed label. The label may fall within the scope either
        # as a namespace (::) or a class member (.)

        # If reference is not directly present, we will look up search path
        # but only if lookup value is not fully qualified.
        if {![my Reference? $lookup ref] && ! [string match ::* $lookup]} {
            while {$scope ne "" && ![info exists ref]} {
                # Check class (.) and namespace scope (::)
                if {[my Reference? ${scope}.$lookup ref]} {
                    break
                }
                if {[my Reference? ${scope}::$lookup ref]} {
                    break
                }
                set scope [namespace qualifiers $scope]
            }
        }
        if {[info exists ref]} {
            upvar 1 $refvar upref
            set upref $ref
            dict set upref label [trim_namespace $lookup $scope]
            return 1
        }
        return 0
    }

    method HeadingReference {ns heading} {
        # Generates a reference for a heading in a namespace.
        #  ns - the namespace containing the heading
        #  heading - the text of the heading.
        # This method should be overridden by the concrete formatter.
        # Returns the reference to the heading.
        error "Method HeadingReference not overridden."
    }

    method SymbolReference {ns symbol} {
        # Generates a reference for a symbol in a namespace.
        #  ns - the namespace containing the heading
        #  symbol - the text of the symbol.
        # This method should be overridden by the concrete formatter.
        # Returns the reference to the symbol.

        # NOTE: $ns is a separate parameter because although name
        # must be fully qualified, the parent is not necessarily
        # the name space scope because for methods, the class name
        # is the parent but $ns will be the class's parent namespace.

        error "Method SymbolReference not overridden."
    }

    method CollectReferences {ns ns_content} {
        # Collects links to documentation elements in a namespace.
        #  ns - The namespace containing the program elements.
        #  ns_content - Dictionary containing parsed content for the namespace.
        # Returns a dictionary mapping the documentation element name
        # to the text linking to that element.

        # Set up a link for the namespace itself
        my CollectSymbolReference $ns $ns

        # Gather links for preamble headings
        foreach {type content} [dict get $ns_content preamble] {
            if {$type eq "heading"} {
                lassign $content level heading
                my CollectHeadingReference $ns $heading
            }
        }

        # Gather links for procs
        foreach proc_name [dict keys [dict get $ns_content procs]] {
            fqn! $proc_name
            ns_member! $ns $proc_name
            my CollectSymbolReference $ns $proc_name
        }

        # Finally gather links for classes and methods
        # A class name is also treated as a namespace component
        # although that is not strictly true.
        foreach {class_name class_info} [dict get $ns_content classes] {
            ns_member! $ns $class_name
            my CollectSymbolReference $ns $class_name
            set method_info_list [concat [dict get $class_info methods] [dict get $class_info forwards]]
            foreach name {constructor destructor} {
                if {[dict exists $class_info $name]} {
                    lappend method_info_list [dict get $class_info $name]
                }
            }
            foreach method_info $method_info_list {
                # The class name is the scope for methods. Because of how
                # the link target lookup works, we use the namespace
                # operator to separate the class from method. We also
                # store it a second time using the "." separator as that
                # is how they are sometimes referenced.
                set method_name [dict get $method_info name]
                set ref [my CollectSymbolReference $ns ${class_name}::${method_name}]
                my CollectSymbolReference $ns ${class_name}.${method_name} $ref
            }
        }
    }

    method AddParagraphs {paras {scope {}}} {
        # Calls the formatter for each of the passed paragraphs.
        # paras - A flat list of pairs with the first element
        #         in a pair being the type, and the second the content.
        # scope - The namespace scope for the paragraphs.

        foreach {type content} $paras {
            switch -exact -- $type {
                heading {
                    my AddHeading {*}$content $scope
                }
                paragraph {
                    my AddParagraph $content $scope
                }
                definitions {
                    my AddDefinitions $content $scope none
                }
                bullets {
                    my AddBullets $content $scope
                }
                preformatted {
                    my AddPreformatted $content $scope
                }
                seealso -
                default {
                    error "Unknown or unexpected paragraph element type '$type'."
                }
            }
        }
        return
    }

    method Namespaces {} {
        # Returns the list of namespaces being documented.
        return $Namespaces
    }

    method SortedNamespaces {} {
        # Returns the list of namespaces being documented.
        if {![info exists SortedNamespaces]} {
            set SortedNamespaces [lsort $Namespaces]
        }
        return $SortedNamespaces
    }

    method TransformProcOrMethod {procinfo} {
        # Transforms procedure or method information into form required
        # by formatters.
        #   procinfo - Proc or method information in the format returned
        #    by [ruff::private::extract_proc] or [ruff::private::extract_ooclass].
        #
        # The following document options control specific behaviour.
        #   -includesource BOOLEAN - if true, the source code of the
        #    procedure is also included. Default value is false.
        #   -hidenamespace NAMESPACE - if specified as non-empty,
        #    program element names beginning with NAMESPACE are shown
        #    with that namespace component removed.
        #
        # Returns the proc documentation as a dictionary in the form
        # expected by the [AddProcedure] method.
        set includesource [my Option -includesource false]
        set hidenamespace [my Option -hidenamespace ""]

        dict with procinfo {
            # Creates local vars (IF PRESENT):
            # proctype - method or proc
            # name - proc or method name
            # parameters - parameter definitions
            # summary - summary text
            # returns - return value text
            # seealso - cross references
            # class - class (for methods)
        }

        set proc_name    $name
        set parameter_block $parameters; # Since we reuse the name
        set display_name [trim_namespace $proc_name $hidenamespace]

        if {$proctype eq "method"} {
            set scope $class; # Scope is name of class
            set fqn   ${class}::$proc_name
        } else {
            set scope [namespace qualifiers $name]
            set fqn   $proc_name
        }

        # Construct the synopsis and simultaneously the parameter descriptions
        set parameters {}
        set arglist {};             # Used later for synopsis
        foreach param $parameter_block {
            set param_name [dict get $param term]
            if {[dict exists $param definition]} {
                set desc [dict get $param definition]
            } elseif {$param_name eq "args"} {
                set desc [list "Additional options."]
            }
            # The type may be parameter or option
            set param_type [dict get $param type]
            if {$param_type eq "parameter"} {
                lappend arglist $param_name
                if {[dict exists $param default]} {
                    lappend desc "(optional, default [markup_code [dict get $param default]])"
                }
            }

            lappend parameters [list term $param_name definition $desc type $param_type]
        }

        if {$proctype ne "method"} {
            set synopsis [list [namespace tail $display_name] $arglist]
        } else {
            switch -exact -- $proc_name {
                constructor {
                    set synopsis [list "$class create" $arglist]
                }
                destructor  {set synopsis [list "OBJECT destroy"]}
                default  {
                    set synopsis [list "OBJECT $display_name" $arglist]
                }
            }
        }

        if {![info exists summary] || $summary eq ""} {
            if {[info exists returns] && $returns ne ""} {
                set summary $returns
            }
        }

        if {$includesource && [info exists source]} {
            if {[info exists ensemble]} {
                append source "\n# NOTE: showing source of procedure implementing ensemble subcommand."
            }
        }

        set result [dict create \
                        proctype $proctype \
                        display_name $display_name \
                        fqn $fqn]
        foreach key {synopsis parameters summary body returns seealso source} {
            if {[info exists $key]} {
                dict set result $key [set $key]
            }
        }

        return $result
    }

    method AddProcedures {procinfodict} {
        # Adds documentation for procedures.
        # procinfodict - Dictionary keyed by name of the proc.
        #                The associated value is in the format returned by
        #                [ruff::private::extract_proc].

        set proc_names [lsort -dictionary [dict keys $procinfodict]]
        foreach proc_name $proc_names {
            my AddProcedure [my TransformProcOrMethod [dict get $procinfodict $proc_name]]
        }
        return
    }

    method TransformClass {classinfo} {
        # Transforms class information into form required by formatters.
        #   classinfo - Class information in the format returned
        #    by [ruff::private::extract_ooclass].
        #
        # The following document options control specific behaviour.
        #   -includesource - if true, the source code of the
        #    procedure is also included. Default value is false.
        #   -hidenamespace - if non-empty, program element names beginning
        #    with NAMESPACE are shown with that namespace component removed.
        #
        # Returns the class documentation as a dictionary in the form
        # expected by the [AddClass] method.

        set includesource [my Option -includesource false]
        set hidenamespace [my Option -hidenamespace ""]

        dict with classinfo {
            # Creates the following locals
            # name - name of class
            # superclasses - list of superclasses
            # mixins - list of mixin classes
            # subclasses - list of subclasses
            # external_methods - list of {method class} pairs
            # filters - ?
            # constructor - constructor definition
            # destructor - destructor definition
            # methods - list of method definitions
            # forwards - list of forwarded methods
        }

        set fqn          $name
        set display_name [trim_namespace $fqn $hidenamespace]

        foreach var {superclasses subclasses mixins} {
            # NOTE: do not sort the list. Order is important for semantics.
            if {[info exists $var] && [llength [set $var]]} {
                set $var [trim_namespace_multi [set $var] $hidenamespace]
            }
        }

        # TBD - filters need any processing?

        # Methods are summarized as a definition list.
        set method_summaries [list ]

        # NOTE: we do NOT include constructor and destructor in summary
        # as they are implicitly present.
        if {[info exists methods]} {
            foreach method_info $methods {
                set method_name [dict get $method_info name]
                if {[dict exists $method_info summary]} {
                    set summary [dict get $method_info summary]
                } elseif {[dict exists $method_info returns]} {
                    set summary [dict get $method_info returns]
                } else {
                    set summary [list "Not documented."]
                }
                lappend method_summaries [list term $method_name definition $summary]
            }
        }
        if {[info exists forwards]} {
            foreach forward_info $forwards {
                set method_name [dict get $forward_info name]
                set summary [list "Method forwarded to [dict get $forward_info forward]"]
                lappend method_summaries [list term $method_name definition $summary]
            }
        }

        # Also add external methods to the method summary.
        if {[info exists external_methods]} {
            foreach external_method $external_methods {
                lassign $external_method method_name imp_class
                lappend method_summaries [list term $method_name definition [list "See [markup_reference $imp_class.$method_name]"]]
            }
        }

        # Sort the method summary table alphabetically
        set method_summaries [lsort -index 1 $method_summaries]

        set methods [lmap method_info $methods {
            my TransformProcOrMethod $method_info
        }]
        if {[info exists constructor]} {
            set constructor [my TransformProcOrMethod $constructor]
        }
        if {[info exists destructor]} {
            set destructor [my TransformProcOrMethod $destructor]
        }

        set result [dict create fqn $fqn display_name $display_name]
        foreach key {
            superclasses subclasses mixins method_summaries mixins
            filters methods constructor destructor
        } {
            if {[info exists $key]} {
                dict set result $key [set $key]
            }
        }
        return $result
    }

    method AddClass {classinfo} {
        # classinfo dictionary contains the following keys. All except
        # name are optional.
        #  fqn - Fully qualified name of the class
        #  display_name - Name of class for display purposes.
        #  superclasses - List of superclasses.
        #  subclasses - List of subclasses.
        #  mixins - List of mixins.
        #  filters - List of filter methods.
        #  method_summaries - Definition list mapping method name to description.
        #  methods - Dictionary of method definitions in the format generated
        #    by [TransformProcOrMethod].
        #  constructor - Constructor definition in the same format.
        #  destructor - Destructor definition in the same format.
        dict with classinfo {
            # Creates locals for all the classinfo keys listed above.
        }
        my AddProgramElementHeading class $fqn
        set scope $fqn
        if {[info exists method_summaries]} {
            my AddHeading nonav "Method summary" $scope
            # The method names need to be escaped and linked.
            my AddDefinitions [lmap definition $method_summaries {
                set term [dict get $definition term]
                # TBD - The resolution currently only searches the namespace
                # hierarchy, not the class hierarchy so methods defined
                # in superclasses/mixins etc. will not be found. So
                # those we just mark as code.
                if {[my ResolvableReference? $term $scope dontcare]} {
                    dict set definition term [markup_reference $term]
                } else {
                    dict set definition term [markup_code $term]
                }
            }] $scope none
        }
        foreach var {superclasses mixins subclasses filters} {
            if {[info exists $var]} {
                my AddReferences [set $var] $scope [string totitle $var]
            }
        }
        if {[info exists constructor]} {
            my AddProcedure $constructor
        }
        if {[info exists destructor]} {
            my AddProcedure $destructor
        }
        if {[info exists methods]} {
            foreach meth $methods {
                my AddProcedure $meth
            }
        }
        return
    }

    method AddClasses {classinfodict} {
        # Adds documentation for classes.
        # classinfodict - Dictionary keyed by name of the class.
        #                The associated value is in the format returned by
        #                [ruff::private::extract_class].

        set class_names [lsort -dictionary [dict keys $classinfodict]]
        foreach class_name $class_names {
            my AddClass [my TransformClass [dict get $classinfodict $class_name]]
        }
        return
    }

    method generate_document {ns_info args} {
        # Produces documentation in HTML format from the passed in
        # class and proc metainformation.
        #   ns_info - dictionary keyed by namespace containing parsed documentation
        #    about the namespace.
        #   -preamble DICT - a dictionary indexed by a namespace. Each value is
        #    a flat list of pairs consisting of a heading and
        #    corresponding content. These are inserted into the document
        #    before the actual class and command descriptions for a namespace.
        #    The key "::" corresponds to documentation to be printed at
        #    the very beginning.
        #   -includesource BOOLEAN - if true, the source code of the
        #     procedure is also included. Default value is false.
        #   -hidenamespace NAMESPACE - if specified as non-empty,
        #    program element names beginning with NAMESPACE are shown
        #    with that namespace component removed.
        #   -pagesplit SPLIT - if `none`, a single documentation file is produced.
        #    If `namespace`, a separate file is output for every namespace.
        #   -titledesc STRING - the title for the documentation.
        #    Used as the title for the document.
        #    If undefined, the string "Reference" is used.
        #   -stylesheet URLLIST - if specified, the stylesheets passed in URLLIST
        #    are used instead of the built-in styles. Note the built-in YUI is
        #    always included.

        set Namespaces [dict keys $ns_info]
        set References [dict create]

        array set Options \
            [list \
                 -includesource false \
                 -hidenamespace "" \
                 -pagesplit none \
                 -titledesc "" \
                 -modulename "Reference" \
                ]

        array set Options $args

        # First collect all "important" names so as to build a list of
        # linkable targets. These will be used for cross-referencing and
        # also to generate links correctly in the case of
        # duplicate names in different namespaces or classes.
        #

        # First collect section links
        if {[info exists opts(-preamble)]} {
            foreach {type content} $opts(-preamble) {
                if {$type eq "heading"} {
                    lassign $content level heading
                    my CollectHeadingReference "" $heading
                }
            }
        }

        dict for {ns ns_content} $ns_info {
            my CollectReferences $ns $ns_content
        }

        my Begin
        my DocumentBegin ""
        if {[my Option? -preamble preamble] && $preamble ne ""} {
            # Top level documentation
            my AddParagraphs $preamble ""
        }
        if {[my Option -pagesplit none] ne "none"} {
            lappend docs :: [my DocumentEnd]
        }

        foreach ns [my SortedNamespaces] {
            if {[my Option -pagesplit none] ne "none"} {
                my DocumentBegin $ns
            }

            my AddHeading 1 $ns ""

            # Print the preamble for this namespace
            my AddParagraphs [dict get $ns_info $ns preamble] $ns

            if {[dict size [dict get $ns_info $ns procs]]} {
                my AddHeading 2 Commands $ns
                my AddProcedures [dict get $ns_info $ns procs]
            }

            if {[dict size [dict get $ns_info $ns classes]]} {
                my AddHeading 2 Classes $ns
                my AddClasses [dict get $ns_info $ns classes]
            }

            if {[my Option -pagesplit none] ne "none"} {
                lappend docs $ns [my DocumentEnd]
            }
        }
        if {[my Option -pagesplit none] eq "none"} {
            lappend docs :: [my DocumentEnd]
        }

        return $docs
    }

    method FormatInline {text {scope {}}} {
        # Converts Ruff! inline formatting to the output format.
        #  text - Inline text to convert.
        #  scope - Documentation scope for resolving references.
        # This method should be overridden by the concrete subclass.
        error "Method FormatInline not overridden."
    }

    # Credits: tcllib/Caius markdown module
    # This method is here and not in the Html class because other subclasses
    # (notably markdown) also need to use ruff->html inline conversion.
    method ToHtml {text {scope {}}} {
        set text [regsub -all -lineanchor {[ ]{2,}$} $text <br/>]
        set index 0
        set result {}

        set re_backticks   {\A`+}
        set re_whitespace  {\s}
        set re_inlinelink  {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\]\s*\(\s*((?:[^\s\)]+|\([^\s\)]+\))+)?(\s+([\"'])(.*)?\4)?\s*\)}
        set re_reflink     {\A\!?\[((?:[^\]]|\[[^\]]*?\])+)\](?:\s*\[((?:[^\]]|\[[^\]]*?\])*)\])?}
        set re_htmltag     {\A</?\w+\s*>|\A<\w+(?:\s+\w+=(?:\"[^\"]+\"|\'[^\']+\'))*\s*/?>}
        set re_autolink    {\A<(?:(\S+@\S+)|(\S+://\S+))>}
        set re_comment     {\A<!--.*?-->}
        set re_entity      {\A\&\S+;}

        while {[set chr [string index $text $index]] ne {}} {
            switch $chr {
                "\\" {
                    # ESCAPES
                    set next_chr [string index $text [expr $index + 1]]

                    if {[string first $next_chr {\`*_\{\}[]()#+-.!>|}] != -1} {
                        set chr $next_chr
                        incr index
                    }
                }
                {_} {
                    # Unlike Markdown, do not treat underscores as special char
                }
                {*} {
                    # EMPHASIS
                    if {[regexp $re_whitespace [string index $result end]] &&
                        [regexp $re_whitespace [string index $text [expr $index + 1]]]} \
                        {
                            #do nothing
                        } \
                        elseif {[regexp -start $index \
                                     "\\A(\\$chr{1,3})((?:\[^\\$chr\\\\]|\\\\\\$chr)*)\\1" \
                                     $text m del sub]} \
                        {
                            switch [string length $del] {
                                1 {
                                    append result "<em>[my ToHtml $sub $scope]</em>"
                                }
                                2 {
                                    append result "<strong>[my ToHtml $sub $scope]</strong>"
                                }
                                3 {
                                    append result "<strong><em>[my ToHtml $sub $scope]</em></strong>"
                                }
                            }

                            incr index [string length $m]
                            continue
                        }
                }
                {`} {
                    # CODE
                    regexp -start $index $re_backticks $text m
                    set start [expr $index + [string length $m]]

                    if {[regexp -start $start -indices $m $text m]} {
                        set stop [expr [lindex $m 0] - 1]

                        set sub [string trim [string range $text $start $stop]]

                        append result "<code>[my Escape $sub]</code>"
                        set index [expr [lindex $m 1] + 1]
                        continue
                    }
                }
                {!} -
                "[" {
                    # Note: "[", not {[} because latter messes Emacs indentation
                    # LINKS AND IMAGES
                    if {$chr eq {!}} {
                        set ref_type img
                    } else {
                        set ref_type link
                    }

                    set match_found 0
                    set css ""

                    if {[regexp -start $index $re_inlinelink $text m txt url ign del title]} {
                        # INLINE
                        incr index [string length $m]

                        set url [my Escape [string trim $url {<> }]]
                        set txt [my ToHtml $txt $scope]
                        set title [my ToHtml $title $scope]

                        set match_found 1
                    } elseif {[regexp -start $index $re_reflink $text m txt lbl]} {
                        if {$lbl eq {}} {
                            set lbl [regsub -all {\s+} $txt { }]
                        }

                        if {[my ResolvableReference? $lbl $scope code_link]} {
                            # RUFF CODE REFERENCE
                            set url [my Escape [dict get $code_link ref]]
                            set txt [my Escape [dict get $code_link label]]
                            set title $txt
                            if {[dict get $code_link type] eq "symbol"} {
                                set css "class='ruff_cmd'"
                            }
                            incr index [string length $m]
                            set match_found 1
                        } else {
                            app::log_error "Warning: no target found for link \"$lbl\". Assuming markdown reference."
                            set lbl [string tolower $lbl]

                            if {[info exists ::Markdown::_references($lbl)]} {
                                lassign $::Markdown::_references($lbl) url title

                                set url [my Escape [string trim $url {<> }]]
                                set txt [my ToHtml $txt $scope]
                                set title [my ToHtml $title $scope]

                                # REFERENCED
                                incr index [string length $m]
                                set match_found 1
                            }
                        }
                    }
                    # PRINT IMG, A TAG
                    if {$match_found} {
                        if {$ref_type eq {link}} {
                            if {$title ne {}} {
                                append result "<a href=\"$url\" title=\"$title\" $css>$txt</a>"
                            } else {
                                append result "<a href=\"$url\" $css>$txt</a>"
                            }
                        } else {
                            if {$title ne {}} {
                                append result "<img src=\"$url\" alt=\"$txt\" title=\"$title\" $css/>"
                            } else {
                                append result "<img src=\"$url\" alt=\"$txt\" $css/>"
                            }
                        }

                        continue
                    }
                }
                {<} {
                    # HTML TAGS, COMMENTS AND AUTOLINKS
                    if {[regexp -start $index $re_comment $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_autolink $text m email link]} {
                        if {$link ne {}} {
                            set link [my Escape $link]
                            append result "<a href=\"$link\">$link</a>"
                        } else {
                            set mailto_prefix "mailto:"
                            if {![regexp "^${mailto_prefix}(.*)" $email mailto email]} {
                                # $email does not contain the prefix "mailto:".
                                set mailto "mailto:$email"
                            }
                            append result "<a href=\"$mailto\">$email</a>"
                        }
                        incr index [string length $m]
                        continue
                    } elseif {[regexp -start $index $re_htmltag $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }

                    set chr [my Escape $chr]
                }
                {&} {
                    # ENTITIES
                    if {[regexp -start $index $re_entity $text m]} {
                        append result $m
                        incr index [string length $m]
                        continue
                    }

                    set chr [my Escape $chr]
                }
                {$} {
                    # Ruff extension - treat $var as variables name
                    # Note: no need to escape characters but do so
                    # if you change the regexp
                    if {[regexp -start $index {\$\w+} $text m]} {
                        append result "<code>$m</code>"
                        incr index [string length $m]
                        continue
                    }
                }
                {>} -
                {'} -
                "\"" {
                    # OTHER SPECIAL CHARACTERS
                    set chr [my Escape $chr]
                }
                default {}
            }
            append result $chr
            incr index
        }
        return $result
    }
}
