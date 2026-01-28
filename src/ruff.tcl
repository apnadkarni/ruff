# Copyright (c) 2009-2026, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.

# Ruff! - RUntime Formatting Function
# ...a document generator using introspection
#

package require Tcl
if {[catch {
    package require textutil::adjust
    package require textutil::tabify
} msg ropts]} {
    puts stderr "Ruff! needs packages textutil::adjust and textutil::tabify from tcllib."
    return -options $ropts $msg
}
package require msgcat
msgcat::mcload [file join [file dirname [info script]] msgs]

namespace eval ruff {
    # If you change version here, change in pkgIndex.tcl as well
    variable version 2.8.0
    proc version {} {
        # Returns the Ruff! version.
        variable version
        return $version
    }

    # Export all procs starting with lower case
    namespace export {[a-z]*}

    proc Tcl9 {} {
        if {[package vsatisfies [package require Tcl] 9]} {
            proc Tcl9 {} {return true}
        } else {
            proc Tcl9 {} {return false}
        }
        Tcl9
    }

    variable _ruff_intro {
        # Introduction

        Ruff! (Runtime function formatter) is a documentation generation system
        for programs written in the Tcl programming language. Ruff! uses runtime
        introspection in conjunction with comment analysis to generate reference
        manuals for Tcl programs.

        Ruff! is covered by a liberal BSD open-source license that permits use
        for any purpose.

        ## Why Ruff!

        In comparison with other source code based documentation generators,
        Ruff! produces documentation that not only requires less duplication
        of effort from the programmer, but is also more complete, more
        accurate and more maintainable.

        * Comments in source code do not have to be
        reproduced for documentation purposes.

        * Ruff! requires minimal markup in the comments making it lightweight
        as well as reducing clutter.

        * Supports inline formatting using Markdown syntax.

        * Embedded diagrams in multiple formats

        * Program elements like command arguments, defaults and
        class relationships like inheritance are automatically derived.

        * Maintenance is less of a burden as documentation is automatically
        updated with source modification such as changes to defaults, addition of
        mix-ins etc.

        On the output side,

        * Ruff! supports output formats HTML, Markdown, nroff and
        reStructuredText (experimental).

        * Generated documentation can optionally be split across multiple pages.

        * Hyperlinks between program elements, and optionally source code,
        make navigation easy and efficient.

        * A table of contents and optional searchable index permits quick
        location of command and class documentation.

        * Class relationships are extracted
        and the full API for a class, with inherited and mixed-in methods, is
        flattened and summarized.

        * The HTML formatter includes multiple themes switchable by the end-user.

        The Ruff! documentation itself is produced with Ruff!. Examples of other
        packages documented with Ruff! include
        [iocp](https://iocp.magicsplat.com),
        [cffi](https://cffi.magicsplat.com),
        [CAWT](http://www.cawt.tcl3d.org/download/CawtReference.html),
        [PAWT](http://www.pawt.tcl3d.org/download/PawtReference.html),
        [apave](https://aplsimple.github.io/en/tcl/pave/apave.html),
        [baltip](https://aplsimple.github.io/en/tcl/baltip/baltip.html),
        [hl-tcl](https://aplsimple.github.io/en/tcl/hl_tcl/hl_tcl.html),
        [SpiceGenTcl](https://georgtree.github.io/SpiceGenTcl/),
        [promise](https://tcl-promise.magicsplat.com),
        [obex](https://tcl-obex.magicsplat.com),
        [Woof!](http://woof.sourceforge.net/woof-ug-0.5/html/_woof/woof_manual.html)
        and
        [tcl-vix](https://tcl-vix.magicsplat.com/).

        ## Documentation

        The [::ruff] reference page describes the Ruff! documentation generation
        API. The [::ruff::sample] page shows some sample output for some of the
        Ruff! features along with the associated source code from which
        it was generated.

        ## Downloads

        Download the Ruff! distribution from
        <https://sourceforge.net/projects/magicsplat/files/ruff/>. The
        source code repository is at <https://github.com/apnadkarni/ruff>.

        ## Installation

        To install, extract the distribution to a directory listed in your
        Tcl `auto_path` variable.

        ## Credits

        Ruff! is authored by [Ashok P. Nadkarni](https://www.magicsplat.com) with
        contributions from George Yashin and Nicolas Robert.

        It uses the `textutil` package from
        [tcllib](https://core.tcl-lang.org/tcllib), a modified version of the
        Markdown inline parser from the
        [Caius](http://caiusproject.com/) project, and portions of the
        `nroff` generator from Tcllib's `doctools` package.
    }

    variable _ruff_preamble {

        ## Usage

        ### Usage from a script

        To document a package or packages, first load them into a Tcl
        interpreter. Then load `ruff` and invoke the [document] command to
        document classes and commands within one or more namespaces.

        For example, the following command will document the `NS` namespace using
        the built-in HTML formatter.
        ````
        package require ruff
        ::ruff::document ::NS
        ````
        The output will be written to `NS.html`. The [document] command takes
        a number of options which control what is documented, output formats,
        layouts etc.

        For example, the following will document the namespace `NS`, `NS2` and
        their children, splitting the output across multiple pages.

        ````
        ::ruff::document {::NS ::NS2} -outdir /path/to/docdir -recurse true -pagesplit namespace
        ````

        ### Usage from the command line

        For simpler cases, documentation can also be generated from the command
        line by invoking the `ruff.tcl` script. Assuming the `NS` and `NS2`
        namespaces were implemented by the `mypac` package,

        ````
        tclsh /path/to/ruff.tcl "::NS ::NS2" -preeval "package require mypac" \
                -outfile docs.html -recurse true -pagesplit none
        ````

        All arguments passed to the script are passed to the [document]
        command. The `-preeval` option is required to load the packages being
        documented, generally using the `package require` or `source`
        commands.

        ## Documenting procedures

        Ruff! generates documentation using Tcl's runtime system to gather
        proc and class definitions. Comments in procedure and method
        bodies are further parsed to extract the documentation.

        The structure Ruff! expects is described below. In practice,
        the structure is simple and intuitive though the description may be
        a bit long winded. You can simply look at the documentation
        of the [sample] namespace instead, and click on the **Show source**
        links for each procedure or method there to see the formatting.

        An example procedure may look as follows:
        ```
        proc ruff::sample::character_at {text {pos 0}} {
            # Get the character from a string.
            #  text - Text string.
            #  pos  - Character position. 
            # The command will treat negative values of $pos as offset from
            # the end of the string.
            #
            # Returns the character at index $pos in string $text.
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
        ```
        You can see the generated documentation for the above at 
        [sample::character_at].

        The first block of comments within a procedure *before
        the first line of code* are always processed by Ruff!. Note preceding
        blank lines are OK. We will refer to this block as the lead comment
        block. It is terminated by either a line of code or a blank line.

        Any comments appearing after the first line of code are not
        processed by Ruff! unless immediately preceded by a line beginning
        with `#ruff` which indicates the start of another Ruff! comment
        block.

        The lead comment block begins with a summary that will be used anywhere
        the document output inserts a procedure summary, for example, a tooltip.
        The summary is terminated with a blank comment or by the parameter
        block.

        The parameter block is a definition list (see below) and follows its
        syntactic structure. It only differs from definition lists in that
        it must directly follow the summary line and receives special
        treatment in that the default value, if any for the argument, is
        automatically inserted by Ruff!. Options and switches may also be
        documented here. The parameter block
        is terminated in the same fashion as definition blocks.

        Any blocks following the parameter block, whether part of the lead
        block or appearing in a subsequent comment block marked with a
        leading `#ruff`, are processed as follows.

        * All processed lines are stripped of the leading `#` character and a
        single following space if there is one.

        * A blank line (after the comment character is stripped) ends the
        previous block. Note in the case of lists, it ends the list element
        but not the list itself.

        * A line containing 3 or more consecutive backquote (\`) characters with
        only leading whitespace starts a fenced block. The block is terminated
        by the same sequence of backquotes. By default, all intervening lines
        are passed through to the output unchanged. However, fenced blocks may
        undergo specialized processing. See [Fenced blocks].

        * Lines starting with a `-` or a `*` character followed by at least one
        space begins a bulleted list item block. A list item may be continued
        across multiple lines and is terminated by another list item, a blank
        line or a line with lesser indentation. Note in particular that lines of
        other types will not terminate a list item unless they have less
        indentation.

        * Lines containing a `-` surrounded by whitespace begins a definition
        list element. The text before the `-` separator is the definition term
        and the text after is the description. Both the term and description are
        subject to inline formatting. Definition blocks follow the same rules
        for termination as bullet lists described above.

        * Parameter blocks have the same format as definition lists and are
        distinguished from them only by their presence in the lead block. Unlike
        definition blocks, the term is assumed to be the name of an argument and
        is automatically formatted and not subject to inline formatting.

        * If the line is indented 4 or more spaces, it is treated a
        preformatted line and passed through to the output with the
        the first 4 spaces stripped. No other processing is done on the line.

        * Any line beginning with the word `Returns` is treated as description
        of the return value. It follows the same rules as normal paragraphs
        below with one special case: if the `Returns` is followed by a colon,
        the word `Returns` is not treated as part of the text to be output. Only
        the rest of the text, which must be separated from the colon by at least
        one space, is treated as the paragraph content. The `Returns` is then
        treated only as a marker for the `Returns` section. This is primarily
        to aid in non-English documentation.

        * A line beginning with `See also:` (note the colon) is assumed to begin
        a reference block consisting of a list of program element names
        (such as procedures, classes etc.) and Markdown links. These
        are then automatically linked and listed in the **See also** section of a
        procedure documentation. The list may continue over multiple lines
        following normal paragraph rules. Each line must be parsable as a Tcl list.
        Note the program element names can,
        but need not be, explicitly marked as a program element reference
        using surrounding square brackets. For example, within a `See also:`
        section, both `document` and `[document]` will generate a cross-reference
        link to the documentation for the `document` procedure.

        * A line beginning with `Synopsis:` (note the colon) is assumed to be
        the parameter list in the synopsis to be documented for the procedure or
        method in lieu of the generated argument list. There may be multiple such
        synopses defined. Each synopsis may continue over multiple lines
        following normal paragraph rules. Each synopsis line must be parsable as
        a Tcl list. See the example at [sample::proc_with_custom_synopsis]. A
        custom synopsis is useful when a command takes several different
        argument list forms. The Tcl `socket` command is an example of this.

        * All other lines begin a normal paragraph. The paragraph ends with
        a line of one of the above types.

        ### Tables

        Ruff supports basic Markdown-formatted tables with a header and
        configurable horizontal alignment. Each row of the table must be
        appear on a single line. All rows should have the same number of
        cells. The following is an example of a table with each column
        aligned differently.

        ```
        |Left Aligned|Center Aligned|Right Aligned|Unaligned|
        |:-|:-:|-:|--|
        |Cell 0,0|Cell 0,1|Cell 0,2|Cell 0,3
        |Cell 1,0|Cell 1,1|Cell 1,2|Cell 1,3
        ```

        This is displayed as
        |Left Aligned|Center Aligned|Right Aligned|Unaligned|
        |:-|:-:|-:|--|
        |Cell 0,0|Cell 0,1|Cell 0,2|Cell 0,3
        |Cell 1,0|Cell 1,1|Cell 1,2|Cell 1,3

        The header and separator may be omitted. For example,

        ```
        |Cell 0,0|Cell 0,1|Cell 0,2|
        |Cell 1,0|Cell 1,1|Cell 1,2|
        ```

        is displayed as

        |Cell 0,0|Cell 0,1|Cell 0,2|
        |Cell 1,0|Cell 1,1|Cell 1,2|

        Note however, that if the Markdown formatter is used and its output
        is passed to another Markdown processor, the latter may not support
        tables without headers.

        In the case of the `nroff` output, the `tbl` program needs to be used to
        format the table. On many systems, `man` and `nroff` will automatically
        invoke it if necessary.

        Not all formatters support alignment of columns.

        ### Differences from Markdown

        Note that the block level parsing is similar but not identical to
        Markdown. Amongst other differences, Ruff! has

        * no nested blocks
        * no blockquotes
        * underscores are not used for emphasis due to their prevalence in
        program element names.

        Ruff! adds
        * definition lists
        * words beginning with `$` are treated as variable references
        * specialized processing for fenced blocks with diagramming
        support, captions and alignment

        As a general rule, inline formatting should be kept basic and avoid
        complexities like nested constructs as formatters vary in their
        capabilities. Embedded HTML is also strongly discouraged as most
        formatters will not process it.

        ## Documenting classes

        Class documentation includes methods, properties, superclasses and
        mixins.

        The format for method documentation is as described above for
        procedures. If a property has specialized setter and getter methods,
        their documentation is extracted in the same fashion except that
        only paragraph text is considered and other elements like definition
        lists or diagrams are ignored.

        Information about superclasses and mixins is automatically collected and
        need not be explicitly provided. Note that unlike for procedures and
        methods, Tcl does not provide a means to retrieve the body of the class
        so that comments can be extracted from them. Thus to document
        information about the class as a whole, you can either include it in the
        comments for the constructor, which is often a reasonable place for such
        information, or include it in the general information section as
        described in the next section.

        Classes created from user-defined metaclasses are also included
        in the generated documentation.

        ## Documenting namespaces

        In addition to procedures and classes within a namespace, there may be a
        need to document general information such as the sections you are
        currently reading. For this purpose, Ruff! looks for a variable
        `_ruff_preamble` within each namespace. The indentation of the first
        line of section content is stripped off from all subsequent lines before
        processing (This impacts what constitutes a preformatted line). The
        result is then processed in the same manner as procedure or method
        bodies except for the following differences:

        * There is (obviously) no summary or parameter block.

        * Additionally, content may contain Markdown ATX style
        headings indicated by a prefix of one or more `#` characters followed
        by at least one space.

        The documentation generated from the `_ruff_preamble` content is placed
        before the documentation of the commands in classes for that namespace.

        **Note**: Older versions supported the `_ruffdoc` variable. Though this
        will still work, it is deprecated.

        Content that should lie outside of any namespace can be passed through
        the `-preamble` option to [document]. When generating single page
        output, this is included at the top of the documentation. When
        generating multipage output this forms the content of the main
        documentation page.

        ### Per-namespace options

        A namespace can override certain global options passed to the
        [document] command by storing a dictionary defining one or more
        options in a variable `_ruff_ns_opts` in the namespace. For
        example,

        ```
        namespace eval ns {
            variable _ruff_ns_opts {
                -onlyexports true
                -excludeprocs private.*
                -heading {Heading to be used for the namespace}
            }
        }
        ```

        will override the `-onlyexports` and `-excludeprocs` passed
        to the [document] command.

        The options that can be overridden by a namespace are `-excludeclasses`,
        `-excludeprocs`, `-includeimports`, `-includeprivate` and
        `-onlyexports`. See [document] for their semantics.

        Additionally, the option `-heading` can be specified to override the
        heading used for the namespace, which defaults to its name.


        ## Inline formatting

        Once documentation blocks are parsed as above, their content is subject
        to inline formatting rules using Markdown syntax with some minor
        extensions. Markdown compatibility is only for inline elements noted
        below.

        \`   - `Text surrounded by backquotes is formatted as inline code`.
        `*`    - *Text surrounded by single asterisks is emphasized*.
        `**`   - **Text surrounded by double asterisks is bolded**.
        `***`  - ***Text surrounded by triple asterisks is bold emphasized***.
        `[]`   - Text surrounded by square brackets is treated as a link
        (more below).
        `<>`   - Text in angle brackets are treated as HTML tags and
        auto-links as in Markdown.
        `$`    - Words beginning with `$` are treated as variable names and
        shown as inline code similar to backquotes (non-standard Markdown).

        The default HTML formatter supports other Markdown inline elements
        but other formatters might not.

        Text enclosed in `[]` is checked whether it references a section heading
        or a program element name (namespaces, classes, methods, procedures). If
        so, it is replaced by a link to the section or documentation of that
        element. If the text is not a fully qualified name, it is treated
        relative to the namespace or class within whose documentation the link
        appears. If it is fully qualified, it is displayed relative to the
        namespace of the link location. For example,

        * `[document]` is displayed as [document]
        * `[::ruff::formatters]` is displayed as [::ruff::formatters] if
        referenced from within a section documenting the `::ruff` namespace.

        Alternatively, text different from the section heading or symbol
        can be shown by putting it in another `[]` pair immediately bfore
        the symbol or heading reference.
        For example, `[here][document]` will show as [here][document] and
        link to `document` as before.
        *Note: unlike Markdown, there must be no whitespace between the
        two pairs of `[]` else it will be treated as two separate symbol
        references. This is intentional.*

        If the text does not match a section heading or program element name, it
        is treated as a normal Markdown reference but a warning is emitted.

        ## Fenced blocks

        A line containing 3 or more consecutive backquote (\`) characters with
        only leading whitespace starts a fenced block. The block is terminated
        by the same sequence of backquotes. By default, formatters will pass
        all intervening lines through verbatim to the output. 

        However, the leading line of a fenced block can contain
        additional options for specialized processing. The general form
        of a fenced block is

        ````
        ```?language? ?option value...? ?transform arg...?
        some text
        lines
        ```
        ````

        The `language` token is optional and specifies the programming language
        for the preformatted lines. If present, it must immediately follow
        the backquote without intervening whitespace. Some formatters make
        use of the language to colorize the output.

        The supported options are

        `-align ALIGNMENT` - Aligns the output as per `ALIGNMENT` which may
        be specified as `left`, `right` or `center`.
        `-caption CAPTION` - Adds a caption below the output.

        In addition, a transform can be specified which transforms
        the input lines into some other form as opposed to outputting them
        without modification. The only transform currently implemented is
        `diagram` and is described in [Embedding diagrams].

        Formatters that do not support the language, options or the transforms
        will silently ignore them and do the default processing on the
        block.

        The fenced block below illustrates use of the options.

        ````
        ``` -align center -caption "An example"
        This is a
        center-aligned
        fenced block
        with a caption
        ```
        ````

        This produces

        ``` -align center -caption "An example"
        This is a
        center-aligned
        fenced block
        with a caption
        ```

        The `-caption` option is optional. If specified, it is shown
        below the output and can be linked to using the value of the option.
        For example `[An example]` will link as [An example].


        ## Embedding diagrams

        Diagrams can be embedded in multiple textual description formats
        by specifying the `diagram` transform on [fenced blocks][Fenced blocks].
        The following marks the content as a `ditaa` textual description.

        ````
        ``` diagram
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```
        ````

        The above will produce

        ``` diagram
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```

        The general format of the `diagram` transform is

        ```
        ?fence options? diagram ?GENERATOR ARG ...?
        ```

        where `GENERATOR` is the diagram generator to use and is followed
        by generator-specific arguments. Currently Ruff! supports `kroki` and
        `ditaa` generators.

        If `GENERATOR` is not specified, as above, it defaults to
        `kroki ditaa`. This default can be changed with the `-diagrammer`
        option to the [::ruff::document] command.


        ### Formatter support

        Not all output formats support embedded diagrams. In such cases the
        fenced block is output as standard preformatted text. For this reason,
        it is best to use an ascii diagram format like `ditaa` so flowcharts
        etc. are still readable when displayed in their original text format.
        You can use tools like [asciiflow](https://asciiflow.com) for
        construction of ascii format diagrams.

        ### Diagrams with kroki

        The `kroki` generator is based on the online diagram converter
        at https://kroki.io which can convert multiple input formats.
        For example, the block below in `graphviz` format


        ````
        ``` diagram kroki graphviz
        digraph {
            "Tcl package" -> "HTML document" [label=" Ruff!"]
        }
        ```
        ````

        will produce

        ``` diagram kroki graphviz
        digraph {
            "Tcl package" -> "HTML document" [label=" Ruff!"]
        }
        ```

        The single argument following `diagram kroki` specifies the input
        format for the block and may be [any format](https://kroki.io/#support)
        supported by `kroki`.

        Use of `kroki` requires a network connection and any **one** of the
        following

        * The `kroki` command line executable that can be downloaded
        for several platforms from https://github.com/yuzutech/kroki-cli/releases/,
        **or**

        * The `twapi` extension (Windows only), **or**

        * The `tls` extension

        Ruff! will try each of the above in turn and use the first that is
        available.

        ### Diagrams with ditaa

        The [ditaa](http://ditaa.sourceforge.net/) generator produces images
        from ASCII text diagrams. Although the `kroki` generator also supports
        this format (using `ditaa` on the server side), the `ditaa` generator
        has the advantage of not requiring network access and allowing for
        more control over image generation. Conversely, it needs the `ditaa`
        Java application to be locally installed.

        Ruff! expects that the generator can be invoked by exec'ing `ditaa`.
        On most Linux programs this can be installed through the system package
        manager. On Windows `ditaa` needs to be downloaded from
        its [repository](https://github.com/stathissideris/ditaa/releases)
        as a `jar` file to a directory included in the `PATH` environment variable.
        Then create a batch file containing the following in that same directory.

        ```
        @echo off
        java -jar %~dp0\ditaa-0.11.0-standalone.jar %*
        ```

        You will need Java also installed and available through `PATH`.

        Similarly, on Unix and MacOS, a shell script needs to be placed in
        the path with equivalent content.

        A `ditaa` block is similar to `kroki` block except it does not need
        a generator argument as input format is always the same. Additional
        arguments specified are passed to the `ditaa` executable.
        For example,

        ````
        ``` diagram ditaa --round-corners --scale 0.8 --no-shadows
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```
        ````

        The above will produce

        ``` diagram ditaa --round-corners --scale 0.8 --no-shadows
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```

        Notice the options to control the generated image, something Ruff! cannot
        do with `kroki`.

        Only the following options or their short form equivalent should
        be used with `ditaa` : `--no-antialias`, `--no-separation`, `--round-corners`,
        `--scale`, and `--fixed-slope`. The `--background` and `--transparent`
        options may be specified but may not play well with all Ruff! themes.
        See the `ditaa` documentation for the meaning of these options.

        ### Diagram options

        The options allowed for [fenced blocks][Fenced blocks] may be used with
        `diagram`.

        Below is a captioned and centered version of the previous example.

        ````
        ``` -align center -caption "Centered diagram with caption" diagram ditaa --scale 0.8
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```
        ````

        The result is shown in [Centered diagram with caption].

        ``` -align center -caption "Centered diagram with caption" diagram ditaa --scale 0.8
        +------------+   Ruff!   +---------------+
        | Tcl script |---------->| HTML document |
        +------------+           +---------------+
        ```

        Note that not all formatters support these options. Those not
        understood by the formatter will be silently ignored.

        ## Ruff! directives

        Ruff! directives allow finer control of how content is processed.
        Directives have the prefix `#ruff`. There are currently two directives
        defined -- `#ruff` and `#ruffopt`.

        ### The #ruff directive

        The `#ruff` directive may only be used in procedure and method
        bodies and not in documentation strings processed through
        namespace `_ruff_preamble` variables. It is used to mark comments
        within a procedure or method body that should be processed
        as Ruff! content even though they do not appear in the initial
        comment section at the top of the body.
        The rest of the line after the `#ruff` directive and
        subsequent contiguous comment lines are considered
        documentation lines. Note that this means that `#ruff` on
        a line by itself (possibly with trailing whitespace) is a
        blank line and terminates the previous documentation
        block with succeeding lines comprising a new block.
        On the other hand, if `#ruff` is followed by
        additional text on the same line, it will continue the
        previous documentation block as there will be no blank
        line separator.

        The `#ruff` directive is useful for documenting options and features
        adjacent to their implementation as opposed to at the top of the
        procedure body.

        ### The #ruffopt directive

        The `#ruffopt` directive may be used within procedure bodies as well
        as `_ruff_preamble` documentation strings. It is used to for settings
        that control certain aspects of content processing and has the
        general form

            #ruffopt ?SETTING ?VALUE?...?

        The only setting currently supported are `includedformats` and
        `excludedformats`. Their use is described in [Conditional inclusion].

        ## Conditional inclusion

        Ruff! lets you conditionally include or exclude content based on
        the formatter in use. This is accomplished through the `includedformats`
        and `excludedformats` settings passed to the `#ruffopt` content
        directive using the following syntax.

            #ruffopt includedformats LISTOFFORMATS
            #ruffopt excludedformats LISTOFFORMATS

        For example, to only enable content for HTML

            #ruffopt includedformats html

        Or, to exclude HTML and Markdown

            #ruffopt excludedformats {html markdown}

        Directives are effective until the end of the documentation string
        or procedure body. To only have conditional inclusion to have effect
        for a fragment, you need to reset to default formatters by excluding
        none as in the following example.

            #ruffopt includedformats html
            <div style="ruff_bd"> <table class="ruff_deflist"> <tbody>
            <tr><th>Column1</th><th>Column2</th><th>Column3</th><th>Column4</th><th>Column5</th></tr>
            <tr><td>1</td><td>element1</td><td>element2</td><td>element3</td><td>element4</td></tr>
            <tr><td>2</td><td>element5</td><td>element6</td><td>element7</td><td>element8</td></tr>
            </tbody> </table> </div>
            #ruffopt excludedformats {}

        #ruffopt includedformats html
        <div style="ruff_bd"> <table class="ruff_deflist"> <tbody>
        <tr><th>Column1</th><th>Column2</th><th>Column3</th><th>Column4</th><th>Column5</th></tr>
        <tr><td>1</td><td>element1</td><td>element2</td><td>element3</td><td>element4</td></tr>
        <tr><td>2</td><td>element5</td><td>element6</td><td>element7</td><td>element8</td></tr>
        </tbody> </table> </div>
        #ruffopt excludedformats {}

        The generated content for the fragment above will only show in the HTML
        output. However, succeeding content will be included for all formatters.

        For an example of using in documenting procedures as opposed to documentation
        strings as above, see [::ruff::sample::proc_with_conditional_content] in the sample
        code.

        ## Output

        Ruff! is designed to support multiple output formats through pluggable
        formatters. The command [formatters] returns a list of supported
        formatters. Currently formatters for producing HTML and Markdown are
        implemented.

        In addition, the output may be produced in single or multipage format.

        ### Multipage output

        The generated documentation may be either in a single output file or
        spread across multiple files. This is controlled
        by the `-pagesplit` option to the [document] command. Some formatters
        may not support this feature.

        When generating multipage output, the toplevel generated page contains
        links to the other pages which contain per-namespace documentation.
        The preamble (passed as the `-preamble` option to the [document] command)
        is also placed in this page.

        ### HTML formatter

        The internal HTML formatter offers

        * A table of contents in a movable pane and tooltips
        * Cross referencing
        * Theming support
        * Optional compact output with expandable content for details
        * Toggles for source code display
        * Copy buttons on source listings

        It is also the simplest to use as no other external tools are required.

        The following is a simple example of generating the documentation for
        Ruff! itself in a single page format.

        ```
        ruff::document ::ruff -title "Ruff! reference"
        ```

        To generate documentation, including private namespaces, in multipage
        format:

        ```
        ruff::document ::ruff -recurse true -pagesplit namespace -outdir ./docs -title "Ruff! internal reference"
        ```

        ### Markdown formatter

        The Markdown formatter generates output in generic Github-flavored
        Markdown syntax and expects support for tables in that format.
        It includes cross-linking but does not include a table of contents,
        tooltips or source code display. On the other hand, it allows conversion
        to other formats using external tools.

        The following generates Ruff! documentation in Markdown format and
        then uses `pandoc` to convert it to HTML.
        ```
        ruff::document ::ruff -format markdown -outfile ruff.md -title "Ruff! reference"
        ```
        Then from the shell or Windows command line,
        ```
        pandoc -s -o ruff.html -c ../ruff-md.css --metadata pagetitle="My package" ruff.md
        ```

        When generating HTML from Markdown, it is generally desirable to specify
        a CSS style file. The `ruff-md.css` file provides some *minimal* CSS
        for this purpose.

        ### Nroff formatter

        The Nroff formatter generates documentation in the format required
        for Unix manpages. It generates documentation as a single manpage
        or as a page per namespace with the `-pagesplit namespace` option.
        It does not support navigation links or table of contents.

        ### Sphinx formatter

        The Sphinx formatter generates documentation in reStructuredText
        format in the form expected by the Sphinx documentation system. Note
        it is not directly usable by Python's doctools.

    }

    namespace eval private {
        namespace path [namespace parent]

        variable ruff_dir
        set ruff_dir [file dirname [info script]]
        variable names
        set names(display) "Ruff!"
        set names(longdisplay) "Runtime Function Formatter"

        # Base file name for output. Needed for linking.
        variable output_file_base ""
        # Extension of base output file
        variable output_file_ext ""

        # Dictionary to count number of occurrences of an unqualified name.
        # Currently used to control index format
        variable symbol_occurrences [dict create]
        proc reset_symbol_occurrence_counts {} {
            variable symbol_occurrences
            set symbol_occurrences [dict create]
        }
        proc count_symbol_occurrence {name} {
            variable symbol_occurrences
            dict incr symbol_occurrences $name
        }
        proc number_of_symbol_occurrences {name} {
            variable symbol_occurrences
            if {[dict exists $symbol_occurrences $name]} {
                return [dict get $symbol_occurrences $name]
            }
            return 0
        }
    }
    namespace path private
}

proc ruff::private::is_builtin {fqcmd} {
    variable built_ins
    if {![info exists built_ins]} {
        set built_ins [dict create]
        set ip [interp create]
        foreach built_in [$ip eval {
            # Force autoloaded procs
            catch {package require nosuchpackage}
            set cmds [lmap cmd [info commands] {
                string cat :: $cmd
            }]
            foreach ns [namespace children ::] {
                lappend cmds {*}[info commands ${ns}::*]
            }
            lappend cmds {*}[info class instances ::oo::class]
        }] {
            dict set built_ins $built_in $built_in
        }
        interp delete $ip
    }
    if {![fqn? $fqcmd]} {
        set fqcmd ::$fqcmd
    }
    # ::oo::class.create -> ::oo::class
    set fqcmd [lindex [split $fqcmd .] 0]
    return [dict exists $built_ins $fqcmd]
}

proc ruff::private::builtin_url {fqcmd} {
    if {![is_builtin $fqcmd]} {
        error "$fqcmd is not a built-in command"
    }

    # ::oo::class.create -> ::oo::class
    set fqcmd [lindex [split $fqcmd .] 0]
    return [list "https://www.tcl-lang.org/man/tcl9.0/TclCmd/index.html" $fqcmd]
}

proc ruff::private::ruff_dir {} {
    variable ruff_dir
    return $ruff_dir
}

proc ruff::private::read_asset_file {fn encoding} {
    # Returns contents of an asset.
    #   fn - name of file
    #   encoding - file encoding

    set fd [open [file join [ruff_dir] assets $fn] r]
    fconfigure $fd -encoding $encoding
    set data [read $fd]
    close $fd
    return $data
}

proc ruff::private::ns_canonicalize {name} {
    return [regsub -all {:::*} $name ::]
}

proc ruff::private::fqn? {name} {
    # Returns `1` if $name is fully qualified, else `0`.
    return [string match ::* $name]
}

proc ruff::private::fqn! {name} {
    # Raises an error if $name is not a fully qualified name.
    if {![fqn? $name]} {
        error "\"$name\" is not fully qualified."
    }
}

proc ruff::private::ns_qualifiers {fqn} {
    # This differs from namespace qualifiers in that
    # - it expects fully qualified names
    # - for globals it returns "::", not "" 
    fqn! $fqn
    set fqn [ns_canonicalize $fqn]
    set quals [namespace qualifiers $fqn]
    if {$quals ne "" || $fqn eq "::"} {
        return $quals
    }
    return ::
}

proc ruff::private::ns_member! {fqns name} {
    fqn! $fqns
    fqn! $name
    set parent [ns_qualifiers $name]
    if {$parent ne [ns_canonicalize $fqns]} {
        error "Name \"$name\" does not belong to the \"$fqns\" namespace."
    }
}

proc ruff::private::program_option {opt} {
    variable ProgramOptions
    return $ProgramOptions($opt)
}

proc ruff::private::sanitize_filename {s} {
    return [regsub -all {[^-\w_]} $s -]
}

proc ruff::private::get_namespace_heading {fqns} {
    # Returns the heading to be used for the given namespace.
    #  fqns - fully qualified namespace
    if {[info exists ${fqns}::_ruff_ns_opts] &&
        [dict exists [set ${fqns}::_ruff_ns_opts] heading]} {
        set heading [dict get [set ${fqns}::_ruff_ns_opts] heading]
        if {$heading eq ""} {
            error "The \"heading\" entry in ${ns}::_ruff_ns_opts is empty."
        }
        return $heading
    } else {
        # Adding "Reference" breaks the link anchor
        #return "$ns Reference"
        return $fqns
    }
}

proc ruff::private::make_id {args} {
    # Return an id usable as a unique anchor
    #  args - list of arbitrary strings
    # The generated id should ideally meet the following requirements:
    # - any unique set of args should generate a unique id
    # - the generated id should be such that it will not be transformed by
    #   a formatter as that would make linking difficult.
    # This means that the generated id should not contain any characters other
    # than alphanumerics and "-" because of the restrictions imposed by
    # reStructuredText processing by rst2html. Further it trims leading and
    # trailing "-" and compresses multiple consecutive occurrences into a single
    # "-" so we avoid the - character as well.
    #
    # The current implementation replaces non-alphanumerics with their codepoint
    # value. This is not perfect since (for example) the strings " " and "20"
    # will not generate the same id but it is unlikely that will clash in
    # practice.

    # Use qz to join with the hope it will not occur in practice
    set s [join [lmap arg $args {
        if {$arg eq ""} continue
        set arg
    }] qz]

    foreach {- alnum notalnumchar} [regexp -inline -all {([a-zA-Z0-9]*)([^a-zA-Z0-9]?)} $s] {
        append result $alnum
        if {$notalnumchar ne ""} {
            append result [format %x [scan $notalnumchar %c]]
        }
    }
    return [string cat x $result]
}

proc ruff::private::ns_file_base {ns_or_class {ext {}}} {
    # Returns the file name to use for documenting namespace $ns.
    # ns_or_class - the namespace or class for the file
    # ext - if non-empty, this is used as the file extension.
    #  It should include the initial period.
    variable output_file_base
    variable output_file_ext
    variable ns_file_base_cache
    variable ProgramOptions

    # Methods can also be represented as Class::method so this is a
    # hack to get the real namespace and not the class name
    if {[info object isa class $ns_or_class]} {
        set ns [namespace qualifiers $ns_or_class]
    } else {
        set ns $ns_or_class
    }
    if {![info exists ns_file_base_cache($ns)]} {
        if {$ProgramOptions(-pagesplit) eq "none" || $ns eq "::"} {
            set fn "$output_file_base$output_file_ext"
        } else {
            set fn "${output_file_base}[regsub -all {:+|[^-\w_.]} $ns -]$output_file_ext"
        }
        set ns_file_base_cache($ns) $fn
    }
    if {$ext eq ""} {
        return $ns_file_base_cache($ns)
    } else {
        return "[file rootname $ns_file_base_cache($ns)]$ext"
    }
}

proc ruff::private::markup_escape {text} {
    # Escapes any characters that might be treated as special for markup.
    #  text - The text to escape.
    return [regsub -all {[\\\[\]`*_{}()#]} $text {\\\0}]
}

proc ruff::private::markup_emphasis {text} {
    # Returns the markup text for emphasis.
    #  text - The text to emphasize.

    return "*[markup_escape $text]*"

}
proc ruff::private::markup_reference {symbol} {
    # Returns the markup text for cross-referencing a symbol.
    #  symbol - the symbol to reference
    return "\[$symbol\]"
}

proc ruff::private::markup_code {text} {
    # Returns $text marked up as code using Ruff! syntax.
    #  text - String to markup.

    # If text contains backticks, markup is more complicated.
    if {[string first "`" $text] < 0} {
        return "`$text`"
    }

    # Find the longest consecutive sequence of `
    set matches [regexp -all -inline {`+} $text]
    set n 0
    foreach match $matches {
        if {[string length $match] > $n} {
            set n [string length $match]
        }
    }
    # Number of backticks required is one more than max length of matches
    set sep [string repeat ` [incr n]]
    # Need to separate with spaces.
    return "$sep $text $sep"
}

proc ruff::private::regexp_escape {s} {
    return [string map {
        \\ \\\\ $ \\$ ^ \\^ . \\. ? \\? + \\+ * \\*
        | \\| ( \\( ) \\) [ \\[ ] \\] \{ \\\{ \} \\\}
    } $s]
}

proc ruff::private::namespace_tree {nslist} {
    # Return list of namespaces under the specified namespaces
    array set done {}
    while {[llength $nslist]} {
        set ns [lindex $nslist 0]
        set nslist [lrange $nslist 1 end]
        if {[info exists done($ns)]} {
            # Already recursed this namespace
            continue
        }
        set done($ns) true
        lappend nslist {*}[namespace children $ns]
    }

    return [array names done]
}

proc ruff::private::trim_namespace {name ns} {
    # Removes a namespace (::) or class qualifier (.) from the specified name.
    # name - name from which the namespace is to be removed
    # ns - the namespace to be removed. If empty, $name
    #  is returned as is. To trim the root namespace
    #  pass :: as the value
    #
    # Returns the remaining string after removing $ns
    # from $name. If $name does not begin with $ns, returns
    # it as is.

    if {$ns eq ""} {
        # Note this check must come BEFORE the trim below
        return $name
    }

    # The "namespace" may be either a Tcl namespace or a class
    # in which case the separator is a "." and not ::
    set ns [string trimright $ns :.]
    set nslen [string length $ns]
    if {[string equal ${ns} [string range $name 0 [expr {$nslen-1}]]]} {
        # Prefix matches.
        set tail [string range $name $nslen end]
        # See if next chars are :: or .
        if {[string range $tail 0 1] eq "::"} {
            # Namespace
            return [string range $tail 2 end]
        }
        if {[string index $tail 0] eq "."} {
            # Class
            return [string range $tail 1 end]
        }
    }

    return $name
}

proc ruff::private::trim_namespace_multi {namelist ns} {
    # See trim_namespace for a description. Only difference
    # is that this command takes a list of names instead
    # of a single name.
    set result {}
    foreach name $namelist {
        lappend result [trim_namespace $name $ns]
    }
    return $result
}

proc ruff::private::symbol_ref {word} {
    # Wraps $word with `[]` to mark it as a markdown reference.
    # word - the word to be marked as reference.
    # Returns the marked-up word.
    return "\[$word\]"
}

proc ruff::private::symbol_refs {words} {
    # Wraps elements of a list with `[]` to mark them as markdown references.
    # words - the list of words to be marked as references.
    # Returns the list of marked-up words.
    return [lmap word $words {
        set word "\[$word\]"
    }]
}

proc ruff::private::symbol_refs_string {words {separator {, }}} {
    # Constructs a string from elements of a list with `[]` to mark them as markdown references
    # words - the list of words to be marked as references.
    # separator - string to use as separator between elements
    # Returns a string containing the marked-up words separated by $separator.
    return [join [symbol_refs $words] $separator]
}

proc ruff::private::ensembles {pattern} {
    # Returns list of ensembles matching the pattern
    # pattern - fully namespace qualified pattern to match

    return [lmap cmd [info commands $pattern] {
        if {![namespace ensemble exists $cmd]} {
            continue
        }
        set cmd
    }]
}

proc ruff::private::propertymethod {name} {
    return [regexp {<(ReadProp|WriteProp)(-.+)>} $name]
}

proc ruff::private::sift_names {names} {
    # Given a list of names, separates and sorts them based on their namespace
    # names - a list of names
    #
    # Returns a dictionary indexed by namespace names with corresponding
    # values being a sorted list of names belong to that namespace.

    set namespaces [dict create]
    foreach name [lsort -dictionary $names] {
        set ns [namespace qualifiers $name]
        dict lappend namespaces $ns $name
    }

    return $namespaces
}

proc ruff::private::split_table_row {line} {
    # Splits a line assuming Markdown table row syntax
    #   line - presumed to have Markdown table row syntax
    # Returns a list of cell content

    # insert a space between || to handle empty cells
    return [regexp -inline -all {(?:[^|]|\\\|)+} \
                [regsub -all {\|(?=\|)} \
                     [string trim $line] {| }]]
}

proc ruff::private::parse_line {line mode current_indent}  {
    # Parses a documentation line and returns its meta information.
    # line - line to be parsed
    # mode - parsing mode, must be one of `proc`, `method`, `docstring`
    # current_indent   - the indent of the containing block

    if {![regexp -indices {^\s*(\S.*)$} $line -> indices]} {
        return [list Type blank Indent $current_indent Text ""]
    }
    # indices contains the indices of text after leading whitespace

    set indent [lindex $indices 0]
    set text   [string trimright [string range $line $indent end]]

    # Indent exceeds more than 4 beyond current indent plus the
    # continuation indent if any, it is preformatted.
    set preformatted_min_indent [expr {$current_indent+4}]
    if {$indent >= $preformatted_min_indent} {
        # Note we use $line here, not $text as we want to preserve trailing
        # and leading spaces except for the 4 spaces that mark it as preformatted.
        return [list Type preformatted \
                    Indent $indent \
                    Text [string range $line $preformatted_min_indent end]]
    }

    # Note that $text starts AND ends with a non-whitespace character.
    # Also note order of match cases in switch is importent.
    switch -regexp -matchvar matches -indexvar indices -- $text {
        {^(#+)\s+(\S.*)} {
            # = A Header
            return [list Type heading \
                        Indent $indent \
                        Level [string length [lindex $matches 1]] \
                        Text [lindex $matches 2]]
        }
        {^([-\*]|(?:\d+\.))\s+(.*)$} {
            # - a bullet list element
            # Return: bullet lineindent relativetextindent marker text
            set marker [string range $text 0 [lindex $indices 1 1]]
            if {[regexp {^\d+.} $marker]} {
                set marker 1.
            }
            return [list Type bullet \
                        Indent $indent \
                        RelativeIndent [lindex $indices 2 0] \
                        Marker $marker \
                        Text [lindex $matches 2]]
        }
        {^(\S+)(\s+\S+)?\s+-\s+(.*)$} {
            # term ?term2? - description
            return [list Type definition \
                        Indent $indent \
                        RelativeIndent [lindex $indices 2 0] \
                        Term "[lindex $matches 1][lindex $matches 2]" \
                        Text [lindex $matches 3]]
        }
        {^\|} {
            # Simple table
            return [list Type table \
                        Indent $indent \
                        RelativeIndent [lindex $indices 2 0] \
                        Cells [split_table_row $line]]
        }
        {^(`{3,})(\S*)(.*)$} {
            # ```` Fenced code block
            set fence_options [string trim [lindex $matches 3]]
            return [list Type fence Indent $indent \
                        Text [lindex $matches 1] \
                        Language [lindex $matches 2] \
                        Options $fence_options]
        }
        {^>} {
            # Blockquote
            return [list Type blockquote \
                        Indent $indent \
                        Text [string trim [string trimleft $text >]]]
        }
        default {
            # Normal text line
            if {$mode ne "docstring"} {
                # Within procs and methods, look for special
                # proc-specific keywords
                if {[regexp {^See also\s*:\s*(.*)$} $line -> match]} {
                    return [list Type seealso Indent $indent Text $match]
                }
                if {[regexp {^Returns(\s*:)?($|\s.*$)} $line -> colon match]} {
                    if {$colon eq ""} {
                        # English text like
                        #   Returns some value
                        return [list Type returns Indent $indent Text $text]
                    } else {
                        # Possibly localized. The "Return" should not be part of text
                        return [list Type returns Indent $indent Text [string trimleft $match]]
                    }
                }
                if {[regexp {^Synopsis\s*:\s*(.*)$} $line -> match]} {
                    return [list Type synopsis Indent $indent Text $match]
                }
            }
            if {$indent > $current_indent} {
                return [list Type continuation \
                            Indent $indent \
                            Text $text]
            } else {
                return [list Type normal\
                            Indent $indent \
                            Text $text]
            }
        }
    }
}

proc ruff::private::parse_preformatted_state {statevar} {
    upvar 1 $statevar state

    # Gobble up all lines that are indented starting
    # with the current line. Blank lines are included
    # even if they have fewer than the required indent.
    # However, leading blank lines and trailing blank
    # lines are not included even if they start
    # with leading 4 spaces.

    # Note the Text dictionary element already has
    # the leading 4 spaces stripped.

    set text [dict get $state(parsed) Text]
    unset state(parsed);    # Since we do not maintain this for further lines

    # If a blank line, do not treat as start of
    # preformatted section (Markdown compatibility).
    if {[regexp {^\s*$} $text]} {
        incr state(index)
        return
    }

    set code_block          [list $text]
    set intermediate_blanks [list ]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        regexp -indices {^(\s*)} $line -> leader
        set nspaces [expr {[lindex $leader 1]+1}]
        if {$nspaces == [string length $line]} {
            # Empty or all blanks
            # Intermediate empty lines do not terminate block
            # even if not prefixed by 4 spaces. Collect them
            # to add later if more preformatted lines follow.
            lappend intermediate_blanks [string range $line 4 end]
        } elseif {$nspaces < 4} {
            # Not preformatted
            break
        } else {
            lappend code_block {*}$intermediate_blanks
            set intermediate_blanks {}
            lappend code_block [string range $line 4 end]
        }
    }
    set state(state) body
    lappend state(body) preformatted $code_block
}

proc ruff::private::parse_fence_options {option_line} {
    # Parses options for a fenced block
    #  option_line - the line containing fence options
    #
    # The line is of the form
    # ```
    # [option value ...] [command [arg ...]]
    # ```
    #
    # An option begins with the character `-`. The options end at the
    # first word that does not begin with `-` (skipping option values).
    # The returned dictionary maps each specified option to a value
    # with a special key -command holding the rest of the line, i.e. the
    # command and its arguments
    # 
    # Returns a dictionary of the option values.

    set n [llength $option_line]
    set options [dict create]
    for {set i 0} {$i < $n} {incr i} {
        set option [lindex $option_line $i]
        if {[string index $option 0] ne "-"} {
            # End of options
            break
        }
        if {[incr i] == $n} {
            error "Missing value to go with option \"[lindex $option_line $i]\" in diagram."
        }
        dict set options $option [lindex $option_line $i]
    }

    dict set options Command [lrange $option_line $i end]
    return $options
}

proc ruff::private::parse_fence_state {statevar} {
    upvar 1 $statevar state
    set marker [dict get $state(parsed) Text]
    set marker_indent  [dict get $state(parsed) Indent]
    set options_line [dict get $state(parsed) Options]
    set lang [dict get $state(parsed) Language]
    set code_block {}

    # Gobble up any lines until the matching fence
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        # Explicit check is faster than calling parse_line
        # Note neither pandoc not cmark require marker indentation
        # to be the same.
        if {[regexp "^\s*$marker\s*$" $line]} {
            incr state(index);  # Inform caller which line to look at next
            unset state(parsed); # To indicate next line has not been parsed
            break;  # Found end marker
        } else {
            # Remove the indentation of original marker if present.
            # Smaller indentation is reduced to 0.
            regexp -indices {^(\s*)} $line -> spaces
            set start [lindex $spaces 1]; # Could be -1 also
            incr start
            if {$start < $marker_indent} {
                set line [string range $line $start end]
            } else {
                set line [string range $line $marker_indent end]
            }
            lappend code_block $line
        }
    }

    set fence_options [parse_fence_options $options_line]
    dict set fence_options Fence $marker
    dict set fence_options Language $lang
    # If there is a caption, create anchor for it
    if {[dict exists $fence_options -caption]} {
        $::ruff::gFormatter CollectFigureReference $state(scope) [dict get $fence_options -caption]
    }

    lappend state(body) fenced [list $code_block $fence_options]
    set state(state) body
}

proc ruff::private::extract_seealso_symbols {symbols} {
    # symbols - text line with symbols optionally separated by commas and optional
    #   surrounding square brackets
    return [lmap symbol $symbols {
        set symbol [string trim $symbol ,]; # Permit commas between elements
        if {$symbol eq ""} {
            continue
        }
        set symbol
    }]
}

proc ruff::private::parse_seealso_state {statevar} {
    upvar 1 $statevar state

    if {$state(mode) eq "docstring"} {
        # parse_line should not have returned this for docstrings
        error "Internal error: Got seealso in docstring mode."
    }
    set block_indent [dict get $state(parsed) Indent]
    # The text is a list of symbols separated by spaces
    # and optionally commas.
    lappend state(seealso) {*}[extract_seealso_symbols [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            table -
            blank -
            synopsis -
            seealso -
            blockquote -
            returns {
                break
            }
            normal {
                # If the indent is less than the block indent,
                # treat as a new paragraph.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                # Append symbols at bottom of loop
            }
            preformatted -
            continuation {
                # Append symbols at bottom of loop
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        lappend state(seealso) {*}[extract_seealso_symbols [dict get $state(parsed) Text]]
    }
    set state(state) body
}

proc ruff::private::parse_synopsis_state {statevar} {
    upvar 1 $statevar state

    if {$state(mode) eq "docstring"} {
        # parse_line should not have returned this for docstrings
        error "Internal error: Got synopsis in docstring mode."
    }
    set block_indent [dict get $state(parsed) Indent]
    # The text is a list of parameter names separated by spaces.
    set param_names [dict get $state(parsed) Text]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            table -
            blank -
            synopsis -
            blockquote -
            seealso -
            returns {
                break
            }
            normal {
                # If the indent is less than the block indent,
                # treat as a new paragraph.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                # Append symbols at bottom of loop
            }
            preformatted -
            continuation {
                # Append symbols at bottom of loop
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        set text [dict get $state(parsed) Text]
        if {[llength $text]} {
            lappend param_names {*}$text
        }
    }
    if {[llength $param_names]} {
        lappend state(synopsis) $param_names
    }
    set state(state) body
}


proc ruff::private::parse_returns_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set lines [list [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set text [dict get $state(parsed) Text]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            table -
            blank -
            seealso -
            synopsis -
            blockquote -
            preformatted -
            returns {
                # All special lines terminate normal paragraphs
                break
            }
            continuation {
                lappend lines $text
            }
            normal {
                # If the indent is less than the block indent,
                # treat as a new paragraph.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend lines $text
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }
    if {[llength $lines]} {
        if {$state(mode) eq "docstring"} {
            lappend state(body) paragraph $lines
        } else {
            lappend state(returns) {*}$lines
        }
    }
    if {$state(mode) ne "docstring" && $state(state) eq "init"} {
        set state(state) postsummary
    } else {
        set state(state) body
    }
}

proc ruff::private::parse_bullets_state {statevar} {
    upvar 1 $statevar state

    set list_block {}
    set list_elem [list [dict get $state(parsed) Text]]
    set marker    [dict get $state(parsed) Marker]
    set block_indent [dict get $state(parsed) Indent]

    # between_bullets keeps track of blank lines. If a list item follow
    # a sequence of blank lines, it continues the list. Any other line
    # type will terminate the list.
    set between_bullets false
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set text [dict get $state(parsed) Text]
        switch -exact -- [dict get $state(parsed) Type] {
            blockquote {
                # Not part of list item, even within a bullet, a la GFM
                break
            }
            heading -
            returns -
            fence -
            definition -
            table -
            synopsis -
            seealso {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }
                if {[dict get $state(parsed) Indent] <= $block_indent} {
                    # List element and list terminated if a block starter
                    # appears at the same or less indentation. Note this is
                    # DIFFERENT from normal lines which add to the list
                    # item if at the same indent level.
                    break
                }
                # Note cannot use $text here since that will not contain
                # the full line for these elements
                lappend list_elem [string trimleft $line]
            }
            continuation {
                lappend list_elem $text
                set between_bullets false
            }
            normal {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }

                # If the indent is less than that of list element
                # treat as a new paragraph. This differs from Markdown
                # which treats it as part of the list item.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend list_elem $text
            }
            preformatted {
                # If we are between bullets, this does not continue the list.
                if {$between_bullets} {
                    break
                }
                # As in markdown list continuation prioritized over preformatted
                lappend list_elem [string trim $text]
            }
            blank {
                # Current list item is terminated but not the list.
                # The check for list_elem length is to deal with
                # multiple consecutive blank lines. These should not
                # result in spurious list items.
                if {[llength $list_elem]} {
                    lappend list_block $list_elem
                    set list_elem {}
                }
                set between_bullets true
            }
            bullet {
                if {[dict get $state(parsed) Marker] ne $marker} {
                    break;      # Different list item type
                }
                if {[llength $list_elem]} {
                    lappend list_block $list_elem
                }
                set list_elem [list $text]
                set between_bullets false
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }

    if {[llength $list_elem]} {
        lappend list_block $list_elem
    }

    lappend state(body) bullets [dict create items $list_block marker $marker]
    set state(state) body
}

proc ruff::private::parse_table_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set table [dict create]

    dict lappend table rows [dict get $state(parsed) Cells]
    # Preserve original lines so we can just directly output original lines for
    # markdown formatter
    dict lappend table lines [lindex $state(lines) $state(index)]

    if {[incr state(index)] >= $state(nlines)} {
        # No more lines
        lappend state(body) table $table
        set state(state) body
        return
    }

    # Check the next line to see if it is a header separator line
    set line [lindex $state(lines) $state(index)]
    if {[regexp {^\s*\|?(?:\s*:?-+:?(?:\s*$|\s*\|))+} $line]} {
        foreach cell [split_table_row $line] {
            switch -regexp $cell {
                {:-*:} {dict lappend table alignments center}
                {:-+}  {dict lappend table alignments left}
                {-+:}  {dict lappend table alignments right}
                default  {dict lappend table alignments {}}
            }
        }
        # Reinterpret first row as header
        dict set table header [lindex [dict get $table rows] 0]
        dict set table rows [list]
        dict lappend table lines $line; # Preserve separator for Markdown
        incr state(index); # Continue with next line
    }

    # state(index) contains the index of the next line to process.
    while {$state(index) < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line \
                               $line \
                               $state(mode) $block_indent]
        if {[dict get $state(parsed) Type] ne "table"} {
            break
        }
        dict lappend table rows [dict get $state(parsed) Cells]
        dict lappend table lines $line
        incr state(index)
    }
    lappend state(body) table $table
    set state(state) body
    return
}

proc ruff::private::parse_definitions_state {statevar} {
    upvar 1 $statevar state

    set definition_block {}
    set term         [dict get $state(parsed) Term]
    set definition   [list [dict get $state(parsed) Text]]
    set block_indent [dict get $state(parsed) Indent]

    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        set type [dict get $state(parsed) Type]
        # If $term is empty, then this line just followed a blank line.
        # In that case, we continue with the definition list only
        # if the line is a definition format or is itself blank.
        if {$type ni { definition blank } && ![info exists term]} {
            break
        }
        set text [dict get $state(parsed) Text]
        switch -exact -- $type {
            heading -
            returns -
            fence -
            bullet -
            synopsis -
            blockquote -
            table -
            seealso {
                if {[dict get $state(parsed) Indent] <= $block_indent} {
                    # List element and list terminated if a block starter
                    # appears at the same or less indentation. Note this is
                    # DIFFERENT from normal lines which add to the list
                    # item if at the same indent level.
                    break
                }
                # Note cannot use $text here since that will not contain
                # the full line for these elements
                lappend definition [string trimleft $line]
            }
            continuation {
                lappend definition $text
            }
            normal {
                # If the indent is less than that of list element
                # treat as a new paragraph. This differs from Markdown
                # which treats it as part of the list item.
                if {[dict get $state(parsed) Indent] < $block_indent} {
                    break
                }
                lappend definition $text
            }
            preformatted {
                # As in markdown list continuation prioritized over preformatted
                lappend definition [string trim $text]
            }
            blank {
                # Current definition is terminated but not the list.
                # The check for term is to deal with
                # multiple consecutive blank lines. These should not
                # result in spurious items.
                if {[info exists term]} {
                    lappend definition_block [dict create term $term definition $definition]
                    unset term
                }
            }
            definition {
                if {[info exists term]} {
                    lappend definition_block [dict create term $term definition $definition]
                }
                set term       [dict get $state(parsed) Term]
                set definition [list [dict get $state(parsed) Text]]
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
    }

    if {[info exists term]} {
        lappend definition_block [dict create term $term definition $definition]
    }

    if {$state(mode) ne "docstring" && $state(state) in {init postsummary}} {
        set state(state) body
        set state(parameters) $definition_block
    } else {
        lappend state(body) definitions $definition_block
    }
}

proc ruff::private::parse_normal_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set paragraph [list [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            blank -
            synopsis -
            seealso -
            preformatted -
            blockquote -
            table -
            returns {
                # All special lines terminate normal paragraphs
                break
            }
            continuation -
            normal {
                # Append text at bottom
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        lappend paragraph [string trim [dict get $state(parsed) Text]]
    }
    if {$state(mode) ne "docstring" && $state(state) eq "init"} {
        set state(summary) $paragraph
        set state(state) postsummary
    } else {
        set state(state) body
        lappend state(body) paragraph $paragraph
    }
}

proc ruff::private::parse_blockquote_state {statevar} {
    upvar 1 $statevar state

    set block_indent [dict get $state(parsed) Indent]
    set paragraph [list [dict get $state(parsed) Text]]
    while {[incr state(index)] < $state(nlines)} {
        set line [lindex $state(lines) $state(index)]
        set state(parsed) [parse_line $line $state(mode) $block_indent]
        switch -exact -- [dict get $state(parsed) Type] {
            heading -
            fence -
            bullet -
            definition -
            blank -
            synopsis -
            seealso -
            preformatted -
            table -
            returns {
                # All special lines terminate normal paragraphs
                break
            }
            blockquote -
            continuation -
            normal {
                # Append text at bottom
            }
            default {
                error "Unexpected type [dict get $state(parsed) Type]"
            }
        }
        lappend paragraph [string trim [dict get $state(parsed) Text]]
    }
    set state(state) body
    lappend state(body) blockquote $paragraph
}

proc ruff::private::parse_lines {lines scope {mode proc}} {
    # Creates a documentation parse structure.
    # lines - List of lines comprising the documentation
    # scope - scope (generally fqns)
    # mode - Parsing mode, must be one of `proc`, `method`, `docstring`
    #
    # Returns a dictionary representing the documentation.
    #
    # The parse structure is a dictionary with the following keys:
    # summary - Contains the summary paragraph.
    #           Not applicable if $mode is `docstring`.
    # parameters - List of parameter name and description paragraph pairs.
    #           Not applicable if $mode is `docstring`.
    # body - The main body stored as a list of alternating type and
    #        content elements. The type may be one of `heading`, `blockquote`,
    #        `paragraph`, `list`, `definitions`, `table` or `preformatted`.
    # seealso - The *See also* section containing a list of program element
    #           references. Not applicable if $mode is `docstring`.
    # returns - A paragraph describing the return value.
    #           Not applicable if $mode is `docstring`.
    # synopsis - a list of alternating procname and parameter list
    #           definitions to be used as synopsis instead of the generated
    #           one.
    #
    # Not all elements may be present in the dictionary.
    # A paragraph is returned as a list of lines.

    # The parsing engine is distributed among procedures that carry
    # state around in the state array.

    set state(state)  init
    set state(scope)  $scope
    set state(mode)   $mode
    set state(lines)  $lines
    set state(nlines) [llength $lines]
    set state(index)  0
    set state(body)  {};        # list of alternating type and content
    # Following may be set during parsing
    # set state(summary) {};      # Summary paragraph
    # set state(returns)  {};     # list of paragraphs
    # set state(seealso) {};      # list of symbol references
    # set state(synopsis) {};     # list of command and param list elements
    # set state(parameters) {};   # Parameter definition list

    while {$state(index) < $state(nlines)} {
        # The loop is structured such that the outer loop detects block
        # starts and then for each block type the state function
        # slurps in all lines for that block.
        if {![info exists state(parsed)]} {
            set state(parsed) [parse_line \
                                   [lindex $state(lines) $state(index)] \
                                   $state(mode) \
                                   0]
        }
        set state(block_indent) [dict get $state(parsed) Indent]
        # All state procs expect state(parsed) to contain the
        # parsed format of the line at position state(index) that causes
        # transition to that state.
        switch -exact -- [dict get $state(parsed) Type] {
            blank {
                incr state(index)
                unset state(parsed)
            }
            heading {
                # Headings have to be on a single line
                lappend state(body) heading [list [dict get $state(parsed) Level] [dict get $state(parsed) Text]]
                incr state(index)
                unset state(parsed)
                set state(state) body
            }
            blockquote   { parse_blockquote_state state }
            bullet       { parse_bullets_state state }
            definition   { parse_definitions_state state }
            returns      { parse_returns_state state }
            seealso      { parse_seealso_state state }
            synopsis     { parse_synopsis_state state }
            table        { parse_table_state state }
            continuation {
                # TBD - See if we can get rid of continuation state
                # we do not really use this state.
                parse_normal_state state
            }
            normal       { parse_normal_state state }
            preformatted { parse_preformatted_state state }
            fence        { parse_fence_state state }
            default {
                error "Internal error: Unknown or unexpected line type\
                       \"[dict get $state(parsed) Type]\" returned in top-level\
                       parse of line \"[lindex $state(lines) $state(index)]\"."
            }
        }
    }

    set result [dict create body $state(body)]
    foreach elem {summary parameters seealso synopsis returns} {
        if {[info exists state($elem)]} {
            dict set result $elem $state($elem)
        }
    }
    return $result
}

proc ruff::private::distill_docstring {text} {
    # Splits a documentation string to return the documentation lines
    # as a list.
    # text - documentation string to be parsed
    #
    # If any tabs are present, they are replaced with spaces assuming
    # a tab stop width of 8.

    set lineSettings [dict create SkipLine 0]
    set lines {}
    set state init
    foreach line [split $text \n] {
        set line [textutil::tabify::untabify2 $line]
        if {[regexp {^\s*$} $line]} {
            #ruff
            # Initial blank lines are skipped and
            # multiple empty lines are compressed into one empty line.
            if {$state eq "collecting"} {
                lappend lines ""
                set state empty
            }
            continue
        }
        #ruff
        # The very first non empty line determines the margin. This will
        # be removed from all subsequent lines. Note that this assumes that
        # if tabs are used for indentation, they are used on all lines
        # in consistent fashion.
        if {$state eq "init"} {
            regexp {^(\s*)\S} $line dontcare prefix
            set prefix_len [string length $prefix]
        }
        set state collecting

        # Remove the prefix if it exists from the line
        if {[string match ${prefix}* $line]} {
            set line [string range $line $prefix_len end]
        }

        #ruff
        # A `#ruffopt` directive may appear within a documentation string,
        # even within a literal block!. If you really want a line beginning with
        # `#ruffopt` to be treated as a literal and not a directive, you have
        # to use one of the literal mechanisms that do not have `#ruffopt`
        # starting the line, for example indentation. This is really only an
        # issue when documenting Ruff! itself.
        if {[regexp {^(#ruffopt\S*)(.*)$} $line -> directive rest]} {
            set lineSettings [process_ruffopt $lineSettings $rest]
        } elseif {![dict get $lineSettings SkipLine]} {
            lappend lines $line
        }
    }

    # Returns a list of lines.
    return $lines
}

proc ruff::private::process_ruffopt {currentSettings newOpts} {
    # Processes a `#ruffopts` line
    #   currentSettings - dictionary containing current settings
    #   newOpts - arguments passed to the `#ruffopts` directive
    # Currently on the `excludedformats` and `includedformats` options are
    # defined for `#ruffopts`.
    #
    # The dictionary passed through `currentSettings` may contain the boolean key
    # SkipLine (no others are currently defined). This function will set
    # the value of this based on the `includedformats` and `excludedformats`
    # `#ruffopt` options. Callers should skip documentation lines if this
    # value is true.
    #
    # Returns the modified value for currentSettings.

    variable ProgramOptions

    if {![string is list $newOpts]} {
        # Generate better error message than the default list one
        error "The #ruffopt directive must be followed by a valid Tcl list. \"$rest\" is not a interpretable as a list"
    }
    set n [llength $newOpts]
    for {set i 0} {$i < $n} {incr i} {
        set opt [lindex $newOpts $i]
        if {[incr i] == $n} {
            # Everything currently require a value to be specified
            error "No value specified for #ruffopt option $opt"
        }
        set optval [lindex $newOpts $i]
        switch $opt {
            excludedformats {
                #ruff
                # The `excludedformats` `#ruffopt` option value is a list
                # of output formats for which documentation lines
                # are to be skipped. By default, it is the empty list.
                # The SkipLine value is set to true in the returned settings
                # if the current formatter is in this list.
                if {![string is list $optval]} {
                    error "The option value \"$optval\" for excludedformats is not a list."
                }
                dict set currentSettings SkipLine [expr {$ProgramOptions(-format) in $optval}]
            }
            includedformats {
                #ruff
                
                # The `includedformats` `#ruffopt` option value is a list of
                # output formats for which succeeding documentation lines are to
                # be processed. Its default value is the list containing all
                # formats. The SkipLine setting is set to false in the returned
                # settings if the current formatter is in this list.
                if {![string is list $optval]} {
                    error "The option value \"$optval\" for includedformats is not a list."
                }
                dict set currentSettings SkipLine [expr {$ProgramOptions(-format) ni $optval}]
            }
        }
    }
    return $currentSettings
}

proc ruff::private::distill_body {text} {
    # Given a procedure or method body,
    # returns the documentation lines as a list.
    # text - text to be processed to collect all documentation lines.
    #
    # The first block of contiguous comment lines preceding the
    # first line of code are treated as documentation lines.
    # If any tabs are present, they are replaced with spaces assuming
    # a tab stop width of 8.

    set lineSettings [dict create SkipLine 0]
    set lines {}
    set state init;             # init, collecting or searching
    foreach line [split $text \n] {
        set line [textutil::tabify::untabify2 $line]
        set line [string trim $line]; # Get rid of whitespace
        if {$line eq ""} {
            # Blank lines.
            # If in init state, we will stay in init state
            if {$state ne "init"} {
                set state searching
            }
            continue
        }

        if {[string index $line 0] ne "#"} {
            # Not a comment
            set state searching
            continue
        }

        # Check for directives irrespective of state.
        if {[regexp {^(#ruff\S*)(.*)$} $line -> directive rest]} {
            switch -exact $directive {
                "#ruff" {
                    #ruff
                    # The string `#ruff` at the beginning of a comment line is a
                    # directive that indicates the block should be processed as
                    # a Ruff! documentation block. The rest of the line and
                    # subsequent contiguous comment lines are considered
                    # documentation lines. Note that this means that `#ruff` on
                    # a line by itself (possibly with trailing whitespace) is a
                    # blank line and terminates the previous documentation
                    # block with succeeding lines comprising a new block.
                    # On the other hand, if `#ruff` is followed by
                    # additional text on the same line, it will continue the
                    # previous documentation block as there will be no blank
                    # line separator.
                    if {![dict get $lineSettings SkipLine]} {
                        lappend lines [string range $rest 1 end]
                    }
                    set state collecting
                }
                "#ruffopt" {
                    #ruff
                    # The string `#ruffopt` is a directive to set or reset
                    # certain processing options. The characters following the
                    # directive must be a well formed Tcl list.
                    # For a list of processing options see [process_ruffopt].
                    set lineSettings [process_ruffopt $lineSettings $rest]
                }
                default {
                    error "Unknown Ruff directive \"$line\""
                }
            }
        } elseif {$state ne "searching" && ![dict get $lineSettings SkipLine]} {
            # At this point, state is init or collecting and the line is
            #  - a comment line
            #  - not a directive
            #  - and not being skipped

            if {$line eq "#"} {
                # Empty comment line
                lappend lines {}
                continue;       # No change in state
            }

            #ruff
            # The leading comment character and a single space (if present)
            # are trimmed from the returned lines.
            if {[string index $line 1] eq " "} {
                lappend lines [string range $line 2 end]
            } else {
                lappend lines [string range $line 1 end]
            }
            set state collecting
            continue
        } else {
            # State is "searching" and not a directive so ignore.
        }
    }

    # Returns a list of lines that comprise the raw documentation.
    return $lines
}

proc ruff::private::xdistill_body {text} {
    # Given a procedure or method body,
    # returns the documentation lines as a list.
    # text - text to be processed to collect all documentation lines.
    #
    # The first block of contiguous comment lines preceding the 
    # first line of code are treated as documentation lines.
    # If any tabs are present, they are replaced with spaces assuming
    # a tab stop width of 8.
    variable gFormatter
    set formatter [string tolower [lindex [split [info object class $::ruff::gFormatter] ::] end]]
    set lines {}
    set state init;             # init, collecting or searching
    set includeExcludeFlag false
    foreach line [split $text \n] {
        set line [textutil::tabify::untabify2 $line]
        set line [string trim $line]; # Get rid of whitespace
        if {$line eq ""} {
            # Blank lines.
            # If in init state, we will stay in init state
            if {$state ne "init"} {
                set state searching
            }
            continue
        }

        if {[string index $line 0] ne "#"} {
            # Not a comment
            set state searching
            continue
        }

        # At this point, the line is a comment line
        if {$state eq "searching"} {
            #ruff
            # The string #ruff at the beginning of a comment line
            # anywhere in the passed in text is considered the start
            # of a documentation block. All subsequent contiguous
            # comment lines are considered documentation lines.
            # If after #ruff the words `include` or `exclude` appears 
            # with further arguments, the conditional mode is
            # activated, and arguments are used to decide if we should 
            # include or exclude next lines processing for certain
            # formatter.
            if {[string match "#ruff*" $line]} {
                if {[regexp -nocase {^\s*#ruff\s+include\s+(?:\{([^\}]*)\}|(\S+))\s*$} $line -> braced single]} {
                    if {$braced ne ""} {
                        set names [lrange $braced 0 end]
                    } else {
                        set names [list $single]
                    }
                    if {$formatter ne $names} {
                        set state searching
                        set includeExcludeFlag false
                        continue
                    } else {
                        set includeExcludeFlag true
                    }
                } elseif {[regexp -nocase {^\s*#ruff\s+exclude\s+(?:\{([^\}]*)\}|(\S+))\s*$} $line -> braced single]} {
                    if {$braced ne ""} {
                        set names [lrange $braced 0 end]
                    } else {
                        set names [list $single]
                    }
                    if {$formatter in $names} {
                        set state searching
                        set includeExcludeFlag false
                        continue
                    } else {
                        set includeExcludeFlag true
                    }
                }
                set state collecting
                #ruff
                # Note a #ruff on a line by itself will terminate
                # the previous text block.
                set line [string trimright $line]
                if {$line eq "#ruff"} {
                    lappend lines {}
                } elseif {!$includeExcludeFlag} {
                    #ruff If #ruff is followed by additional text
                    # on the same line, it is treated as a continuation
                    # of the previous text block, if that text block is 
                    # not part of `include` or `exclude` statement
                    lappend lines [string range $line 6 end]
                }
            }
        } else {
            # State is init or collecting

            if {$line eq "#"} {
                # Empty comment line
                lappend lines {}
                continue;       # No change in state
            }

            #ruff
            # The leading comment character and a single space (if present)
            # are trimmed from the returned lines.
            if {[string index $line 1] eq " "} {
                lappend lines [string range $line 2 end]
            } else {
                lappend lines [string range $line 1 end]
            }
            set state collecting
            continue
        }
    }

    # Returns a list of lines that comprise the raw documentation.
    return $lines
}

proc ruff::private::extract_docstring {text scope} {
    # Parses a documentation string to return a structured text representation.
    # text - documentation string to be parsed
    # scope - the scope of the text (generally fqns)
    #
    # The command extracts structured text from the given string
    # as described in the documentation for the distill_docstring
    # and parse commands. The result is further processed to
    # return a list of type and value elements described below:
    #
    # heading   - The corresponding value is a list comprising the heading level
    #             and text.
    # paragraph - The corresponding values is a list containing the lines
    #             for that paragraph.
    # list      - The corresponding value is a list of lists with the outer
    #             list elements being the list items the contents of which
    #             are the lines.
    # definitions - The corresponding value is a list of dictionaries, each
    #             with the keys `term` and `definition`, the latter being
    #             the list of lines making up the definition.
    # table       - The corresponding values is a dictionary with keys
    #             `rows`, `lines`, `alignments` (if there is a header)
    # blockquote - The corresponding values is a list containing the lines
    #             for that block quote paragraph.
    # preformatted - The corresponding value is a list of lines that should
    #             not be formatted.
    #
    # Each element may occur multiple times and are expected to be displayed
    # in the order of their occurrence.

    set doc [parse_lines [distill_docstring $text] $scope docstring]
    set result [dict get $doc body]
    # Just error checking - should not have anykeys other than body
    dict unset doc body
    if {[llength [dict keys $doc]]} {
        app::log_error "Internal error: docstring contains unexpected keys [join [dict keys $doc]]."
    }
    return $result
}

proc ruff::private::extract_proc {procname} {

    # Extracts meta information from a Tcl procedure.
    # procname - name of the procedure
    #
    # The command retrieves metainformation about
    # a Tcl procedure. See the command extract_proc_or_method
    # for details.
    #
    # Returns a dictionary containing metainformation for the command.
    #

    set param_names [info args $procname]
    set param_defaults {}
    foreach name $param_names {
        if {[info default $procname $name val]} {
            lappend param_defaults $name $val
        }
    }
    return [extract_proc_or_method proc \
                $procname \
                [info args $procname] \
                $param_defaults \
                [info body $procname]]
}

proc ruff::private::extract_ensemble {ens} {
    # Extracts metainformation for all subcommands in an ensemble command
    # ens - fully qualified names of the ensemble command
    #
    # Only ensemble commands that satisfy the following are supported:
    # - the ensemble implementation must be in the form of Tcl procedures
    # - the ensemble must not have been configured with the `-parameters`
    #   option as that changes location of arguments
    #
    # Each element of the returned list is of the form returned by [extract_proc]
    # with two changes. The `name` key in the dictionary element is the
    # includes the ensemble name. Secondly, an additional key `ensemble` is
    # added to indicate which ensemble the element belongs to.
    #
    # Returns a list of elements each of the form returned by [extract_proc].

    array set ens_config [namespace ensemble configure $ens]
    if {[llength $ens_config(-parameters)]} {
        app::log_error "Skipping ensemble command $ens (non-empty -parameters attribute)."
    }

    if {[llength $ens_config(-subcommands)]} {
        set cmds $ens_config(-subcommands)
    } elseif {[dict size $ens_config(-map)]} {
        set cmds [dict keys $ens_config(-map)]
    } else {
        set exported [namespace eval $ens_config(-namespace) {namespace export}]
        set cmds {}
        foreach pat $exported {
            foreach cmd [info commands ${ens_config(-namespace)}::$pat] {
                lappend cmds [namespace tail $cmd]
            }
        }
    }
    set ens_subcmds {}
    set ens_cmds [lmap cmd $cmds {
        if {[dict exists $ens_config(-map) $cmd]} {
            set real_cmd [dict get $ens_config(-map) $cmd]
        } else {
            set real_cmd $cmd
        }
        if {![string match ::* $real_cmd]} {
            set real_cmd "${ens_config(-namespace)}::$real_cmd"
        }
        if {[info procs $real_cmd] ne "$real_cmd"} {
            app::log_error "Skipping subcommand \"$cmd\" for ensemble \"$ens\"\
                            because it is not a procedure."
            continue
        }
        if {[catch {extract_proc $real_cmd} result]} {
            app::log_error "Could not retrieve information for \"$real_cmd\"\
                            implementing ensemble command \"$ens $cmd\": $result"
            continue
        }
        dict set ens_subcmds $cmd real_cmd "$ens $cmd"
        if {[dict exists $result summary]} {
            dict set ens_subcmds $cmd summary [dict get $result summary]
        } elseif {[dict exists $result returns]} {
            dict set ens_subcmds $cmd summary [dict get $result returns]
        } else {
            dict set ens_subcmds $cmd summary "Subcommand"
        }
        dict set result name "$ens $cmd"
        dict set result ensemble $ens
        set result
    }]

    # Construct the documentation for the main ensemble command

    set subcmds [lsort -dictionary [dict keys $ens_subcmds]]
    set subcmd_list [join [lmap subcmd $subcmds {
        return -level 0 "\[$subcmd\]\[[dict get $ens_subcmds $subcmd real_cmd]\]"
    }] ", "]

    set body [list ]
    set definitions [lmap subcmd $subcmds {
        list term "\[$subcmd\]\[[dict get $ens_subcmds $subcmd real_cmd]\]" definition [dict get $ens_subcmds $subcmd summary]
    }]
    lappend body paragraph [list "The ensemble supports the following subcommands:"]
    lappend body definitions $definitions
    lappend body paragraph [list "Refer to the documentation of each subcommand for details."]

    dict set ens_info name $ens
    dict set ens_info body $body
    dict set ens_info summary "A command ensemble."
    dict set ens_info parameters \
        [list \
             [list term subcmd definition "One of $subcmd_list" type parameter] \
             [list term args definition "Subcommand arguments" type parameter]]
    dict set ens_info parameters {}
    dict set ens_info synopsis [list "subcommand ..."]
    dict set ens_info class {}
    dict set ens_info proctype proc
    #dict set ens_info source "# $ens ensemble command"

    return [linsert $ens_cmds[set ens_cmds {}] 0 $ens_info]

}

proc ruff::private::extract_ooclass_method {class method} {

    # Extracts metainformation for the method in oo:: class
    # class - name of the class
    #
    # The command retrieves metainformation about
    # a Tcl class method. See the command extract_proc_or_method
    # for details.
    #
    # Returns a dictionary containing documentation related to the command.
    #


    switch -exact -- $method {
        constructor {
            lassign [info class constructor $class] params body
        }
        destructor  {
            set body [info class destructor $class]
            set params {}
        }
        default {
            if {[catch {
                set method_type [info class methodtype $class $method]
            } method_type]} {
                # Could be property methods for *inherited* properties.
                if {[propertymethod $method]} {
                    # Cook up a dummy record
                    return ""
                }
            }
            switch $method_type {
                method {
                    lassign [info class definition $class $method] params body
                }
                PropertyGetter -
                PropertySetter {
                    # Cook up a dummy record
                    return [extract_proc_or_method method $method {} {} {} $class]
                }
                default {
                    error "Unknown method type [info class methodtype $class $method]"
                }
            }
        }
    }


    set param_names {}
    set param_defaults {}
    foreach param $params {
        lappend param_names [lindex $param 0]
        if {[llength $param] > 1} {
            lappend param_defaults [lindex $param 0] [lindex $param 1]
        }
    }

    return [extract_proc_or_method method $method $param_names $param_defaults $body $class]
}


proc ruff::private::extract_proc_or_method {proctype procname param_names
                                            param_defaults body {class ""}} {
    # Helper procedure used by extract_proc and extract_ooclass_method to
    # construct metainformation for a method or proc.
    #  proctype - should be either 'proc' or 'method'
    #  procname - name of the proc or method
    #  param_names - list of parameter names in order
    #  param_defaults - list of parameter name and default values
    #  body - the body of the proc or method
    #  class - the name of the class to which the method belongs. Not used
    #   for proc types.
    #
    # The command parses the $body parameter as described by the distill_body
    # and parse commands and then constructs the metainformation for
    # the proc or method using this along with the other passed arguments.
    # The metainformation is returned as a dictionary with the following keys:
    #  name - name of the proc or method
    #  parameters - a list of parameters. Each element of the
    #   list is a dictionary with keys term, definition and optionally default.
    #  body - a list of paragraphs describing the command. The
    #   list contains heading, blockquote, preformatted, paragraph, list and
    #   definitions as described for the [extract_docstring] command.
    #  returns - a description of the return value of the command (optional)
    #  summary - a copy of the first paragraph if it was present (optional)
    #  source - the source code of the command (optional)
    #  seealso - the corresponding value is a list of symbols (optional).
    #  synopsis - the synopsis to use instead of the generated one for the proc

    variable ProgramOptions

    count_symbol_occurrence [namespace tail $procname]

    array set param_default $param_defaults
    array set params {}
    array set options {}
    set paragraphs {}

    set doc [parse_lines [distill_body $body] :: $proctype]
    # doc -> dictionary with keys summary, body, parameters, returns, seealso
    # and synopsis
    dict set doc name $procname
    dict set doc class $class
    dict set doc proctype $proctype

    # Match up the parameter docs with the passed in parameter info.
    # First collect the documented parameters
    if {[dict exists $doc parameters]} {
        foreach param [dict get $doc parameters] {
            # param is a dict with keys term and definition
            set name [dict get $param term]
            set params($name) $param
        }
    }

    # Construct parameter descriptions. Note those not listed in the
    # actual proc definition are left out even if they are in the params
    # table
    set parameters {}
    foreach name $param_names {
        if {[info exists params($name)]} {
            set paramdata $params($name)
            unset params($name)
        } else {
            if {$name eq "args"} {
                set definition ""
            } else {
                set definition "Not documented."
            }
            set paramdata [dict create term $name definition $definition type parameter]
        }

        # Check if there is a default
        if {[info exists param_default($name)]} {
            dict set paramdata default $param_default($name)
        }

        dict set paramdata type parameter
        lappend parameters $paramdata
    }

    # Add any left over parameters from the documentation in sorted
    # order.
    foreach name [lsort -dictionary [array names params]] {
        dict set params($name) type "option"; # Assume option since not in proc definition
        lappend parameters $params($name)
    }
    dict set doc parameters $parameters

    # TBD - do we need to extract source even if -includesource is not specified
    set source "$proctype $procname "
    set param_list {}
    foreach name $param_names {
        if {[info exists param_default($name)]} {
            lappend param_list [list $name $param_default($name)]
        } else {
            lappend param_list $name
        }
    }


    append source "{$param_list} {\n"
    # We need to reformat the body. If nested inside a namespace eval
    # for example, the body will be indented too much. So we undent the
    # least indented line to 0 spaces and then add 4 spaces for each line.
    append source [::textutil::adjust::indent [::textutil::adjust::undent $body] "    "]
    append source "\n}"
    if {$ProgramOptions(-hidesourcecomments)} {
        regsub -line -all {^\s*#.*$} $source "" source
        regsub -all {\n{2,}} $source "\n" source
    }
    dict set doc source $source
    return $doc
}


proc ruff::private::extract_ooclass {classname args} {
    # Extracts metainformation about the specified class
    # classname - name of the class to be documented
    # -includeprivate BOOLEAN - if true private methods are also included
    #  in the metainformation. Default is false.
    #
    # The metainformation. returned is in the form of a dictionary with
    # the following keys:
    # name - name of the class
    # methods - a list of method definitions for this class in the form
    #  returned by extract_ooclass_method with the additional key
    #  'visibility' which may have values 'public' or 'private'.
    # external_methods - a list of names of methods that are
    #  either inherited or mixed in
    # filters - a list of filters defined by the class
    # forwards - a list of forwarded methods, each element in the
    #  list being a dictionary with keys 'name' and 'forward'
    #  corresponding to the forwarded method name and the forwarding command.
    # properties - a dictionary keyed by property name. Keys of the nested
    #  dictionary are 'readable' (if present readable property),
    #  'writable' (if present, writable property),
    #  'readprop' (if present, a non-default getter method definition),
    #  'writeprop' (if present, a non-default setter method definition),
    # mixins - a list of names of classes mixed into the class
    # superclasses - a list of names of classes which are direct
    #   superclasses of the class
    # subclasses - a list of classes which are direct subclasses of this class
    # constructor - method definition for the constructor in the format
    #   returned by extract_ooclass_method
    # destructor - method definition for the destructor
    #   returned by extract_ooclass_method
    #
    # Each method definition is in the format returned by the
    # extract_ooclass_method command with an additional keys:
    # visibility - indicates whether the method is 'public' or 'private'

    count_symbol_occurrence [namespace tail $classname]

    array set opts {-includeprivate false}
    array set opts $args

    set result [dict create methods {} external_methods {} \
                    filters {} forwards {} properties {} \
                    mixins {} superclasses {} subclasses {} \
                    name $classname \
                   ]

    set property_methods {}
    if {$opts(-includeprivate)} {
        set all_local_methods [info class methods $classname -private]
        set all_methods [info class methods $classname -all -private]
    } else {
        set all_local_methods [info class methods $classname]
        set all_methods [info class methods $classname -all]
        if {[Tcl9]} {
            # Property method are private but we need them to extract
            # property documentations.
            foreach name [info class methods $classname -all -private] {
                if {[regexp {<(ReadProp|WriteProp)(-.+)>} $name]} {
                    lappend property_methods $name
                }
            }
        }
    }
    set public_methods [concat [info class methods $classname -all] $property_methods]
    set external_methods {}

    # Dictionary to hold property information
    set properties {}

    foreach name [concat [lsort -dictionary $all_methods] $property_methods] {
        set implementing_class [locate_ooclass_method $classname $name]
        if {$name ni $property_methods && [lsearch -exact $all_local_methods $name] < 0} {
            # Skip the destroy method which is standard and
            # appears in all classes.
            if {$implementing_class ne "::oo::object" &&
                $name ne "destroy"} {
                lappend external_methods [list $name $implementing_class]
            }
            continue
        }

        # Even if a local method, it may be hidden by a mixin
        # TBD - should we make a note in the documentation somewhere ?
        if {$implementing_class ne $classname} {
            if {![propertymethod $name]} {
                app::log_error "Method $name in class $classname is hidden by class $implementing_class."
            }
        }

        if {[lsearch -exact $public_methods $name] >= 0} {
            set visibility public
        } else {
            set visibility private
        }

        if {! [catch {
            set method_info [extract_ooclass_method $classname $name]
        } msg]} {
            # Empty results indicate method to be ignored
            if {[dict size $method_info] != 0} {
                dict set method_info visibility $visibility
                if {[regexp {<(ReadProp|WriteProp)(-.+)>} $name -> prop_method_type prop_name]} {
                    dict set properties $prop_name [string tolower $prop_method_type] $method_info
                } else {
                    dict lappend result methods $method_info
                }
            }
        } else {
            # Error, may be it is a forwarded method
            if {! [catch {
                set forward [info class forward $classname $name]
            } res]} {
                dict lappend result forwards [dict create name $name forward $forward]
            } else {
                # Log original error
                ruff::app::log_error "Could not introspect method $name in class $classname: $msg"
            }
        }
    }

    foreach name {constructor destructor} {
        if {[info class $name $classname] ne ""} {
            # Class has non-empty constructor or destructor
            dict set result $name [extract_ooclass_method $classname $name]
        }
    }

    dict set result name $classname;   # TBD - should we fully qualify this?
    dict set result external_methods $external_methods
    dict set result filters [info class filters $classname]
    dict set result mixins [lmap mixin [info class mixins $classname] {
        if {[string match "::oo::*" $mixin]} {
            continue
        }
        set mixin
    }]
    dict set result subclasses [info class subclasses $classname]
    # We do not want to list ::oo::object which is a superclass
    # of all classes.
    set classes {}
    foreach class [info class superclasses $classname] {
        if {$class ne "::oo::object"} {
            lappend classes $class
        }
    }
    dict set result superclasses $classes
    if {[Tcl9]} {
        set local_props [info class properties $classname -readable]
        foreach prop_name [info class properties $classname -all -readable] {
            dict set properties $prop_name readable {}
            dict set properties $prop_name inherited [expr {$prop_name ni $local_props}]
        }
        set local_props [info class properties $classname -writable]
        foreach prop_name [info class properties $classname -all -writable] {
            dict set properties $prop_name writable {}
            dict set properties $prop_name inherited [expr {$prop_name ni $local_props}]
        }
    }
    dict set result properties $properties
    return $result
}

proc ruff::private::get_metaclasses {} {
    set metaclasses [list ]
    set pending [list ::oo::class]
    while {[llength $pending]} {
        set pending [lassign $pending metaclass]
        lappend metaclasses $metaclass
        # Add subclasses of the metaclass as metaclasses
        lappend pending {*}[info class subclasses $metaclass]
    }
    return $metaclasses
}

proc ruff::private::matched_any_pattern {value patterns} {
    foreach pattern $patterns {
        if {[string match $pattern $value]} {
            return 1
        }
    }
    return 0
}

proc ruff::private::extract_procs_and_classes {fqns args} {
    # Extracts metainformation for procs and classes
    #
    # fqns - fully qualified namespace containing the procs and classes.
    # -excludeclasses REGEXP - If specified, any classes whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -excludeprocs REGEXP - If specified, any procedures whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -include LIST - `classes` and / or `procs` depending on whether one
    #     or both are to be collected.
    # -includeprivate BOOLEAN - if true private methods are also included.
    #  Default is false.
    # -includeimports BOOLEAN - if true commands imported from other
    #  namespaces are also included. Default is false.
    # -onlyexports BOOLEAN - if true, only procs exported from the namespace
    #  are included.
    #
    # The value of the classes key in the returned dictionary is
    # a dictionary whose keys are class names and whose corresponding values
    # are in the format returned by extract_ooclass.
    # Similarly, the procs key contains a dictionary whose keys
    # are proc names and whose corresponding values are in the format
    # as returned by extract_proc.
    #
    # Returns a dictionary with keys 'classes' and 'procs'
    array set opts {
        -excludeclasses {}
        -excludeprocs {}
        -include {procs classes}
        -includeprivate false
        -includeimports false
        -onlyexports false
    }
    array set opts $args

    # Override with any namespace specific settings
    upvar 0 ${fqns}::_ruff_ns_opts ns_opts
    if {[info exists ns_opts]} {
        array set opts [dict filter $ns_opts key -excludeclasses -excludeprocs \
                            -includeprivate -includeimports -onlyexports]
    }

    # Note the canonicalize is required to handle fqns == "::" which
    # will create :::: in matching pattern otherwise
    set pattern [ns_canonicalize ${fqns}::*]

    set classes [dict create]
    if {"classes" in $opts(-include)} {
        set class_names [list ]
        foreach metaclass [get_metaclasses] {
            lappend class_names {*}[info class instances $metaclass $pattern]
        }
        foreach class_name $class_names {
            # This covers child namespaces as well which we do not want
            # so filter those out. The differing pattern interpretations in
            # Tcl commands 'info class instances' and 'info procs'
            # necessitates this.
            if {[namespace qualifiers $class_name] ne [namespace qualifiers $pattern]} {
                # Class is in not in desired namespace
                # TBD - do we need to do -includeimports processing here?
                continue
            }
            if {$opts(-excludeclasses) ne "" &&
                [regexp $opts(-excludeclasses) [namespace tail $class_name]]} {
                continue
            }

            if {[catch {
                set class_info [extract_ooclass $class_name -includeprivate $opts(-includeprivate)]
            } msg]} {
                app::log_error "Could not document class $class_name: $msg"
            } else {
                dict set classes $class_name $class_info
            }
        }
    }

    set export_patterns [namespace eval $fqns {namespace export}]
    set procs [dict create]
    if {"procs" in $opts(-include)} {
        # Collect procs
        foreach proc_name [info procs $pattern] {
            if {[is_builtin $proc_name]} {
                continue
            }
            set proc_tail [namespace tail $proc_name]
            if {$opts(-excludeprocs) ne "" &&
                [regexp $opts(-excludeprocs) $proc_tail]} {
                continue
            }
            if {$opts(-onlyexports) &&
                ![matched_any_pattern $proc_tail $export_patterns]} {
                continue
            }
            if {(! $opts(-includeimports)) &&
                [namespace origin $proc_name] ne $proc_name} {
                continue;       # Do not want to include imported commands
            }

            if {[catch {
                set proc_info [extract_proc $proc_name]
            } msg]} {
                app::log_error "Could not document proc $proc_name: $msg"
            } else {
                dict set procs $proc_name $proc_info
            }
        }
        # Collect ensembles
        foreach ens_name [ensembles $pattern] {
            if {[is_builtin $ens_name]} {
                continue
            }
            set ens_tail [namespace tail $ens_name]
            if {$opts(-excludeprocs) ne "" &&
                [regexp $opts(-excludeprocs) $ens_tail]} {
                continue
            }
            if {$opts(-onlyexports) &&
                ![matched_any_pattern $ens_tail $export_patterns]} {
                continue
            }
            if {(! $opts(-includeimports)) &&
                [namespace origin $ens_name] ne $ens_name} {
                continue;       # Do not want to include imported commands
            }

            if {[catch {
                set ens_cmds [extract_ensemble $ens_name]
            } msg]} {
                app::log_error "Could not document ensemble command $ens_name: $msg"
            } else {
                foreach ens_info $ens_cmds {
                    dict set procs [dict get $ens_info name] $ens_info
                }
            }
        }
    }

    return [dict create classes $classes procs $procs]
}


proc ruff::private::extract_namespace {fqns args} {
    # Extracts metainformation for procs and objects in a namespace
    # fqns - fully qualified namespace to examine
    #
    # Any additional options are passed on to the extract command.
    #
    # Returns a dictionary containing information for the namespace.

    # The returned dictionary has keys `preamble`, `classes` and `procs`.
    # See [extract_docstring] for format of the `preamble` value
    # and [extract_procs_and_classes] for the others.

    set result [extract_procs_and_classes $fqns {*}$args]
    set preamble [list ]
    if {[info exists ${fqns}::_ruff_preamble]} {
        set preamble [extract_docstring [set ${fqns}::_ruff_preamble] $fqns]
    } elseif {[info exists ${fqns}::_ruffdoc]} {
        foreach {heading text} [set ${fqns}::_ruffdoc] {
            lappend preamble {*}[extract_docstring "## $heading" $fqns]
            lappend preamble {*}[extract_docstring $text $fqns]
        }
    }
    dict set result preamble $preamble
    return $result
}

proc ruff::private::extract_namespaces {namespaces args} {
    # Extracts metainformation for procs and objects in one or more namespace
    # namespaces - list of fully qualified namespace to examine
    #
    # Any additional options are passed on to the extract_namespace command.
    #
    # The dictionary returned is keyed by namespace with nested
    # keys 'classes' and 'procs'. See [extract] for details.
    #
    # Returns a dictionary with the namespace information.

    set result [dict create]
    foreach fqns $namespaces {
        dict set result $fqns [extract_namespace $fqns {*}$args]
    }
    return $result
}


proc ruff::private::get_ooclass_method_path {class_name method_name} {
    # Calculates the class search order for a method of the specified class
    # class_name - name of the class to which the method belongs
    # method_name - method name being searched for
    #
    # A method implementation may be provided by the class itself,
    # a mixin or a superclass.
    # This command calculates the order in which these are searched
    # to locate the method. The primary purpose is to find exactly
    # which class actually implements a method exposed by the class.
    #
    # If a class occurs multiple times due to inheritance or
    # mixins, the LAST occurrence of the class is what determines
    # the priority of that class in method selection. Therefore
    # the returned search path may contain repeated elements.
    #
    # Note that this routine only applies to a class and cannot be
    # used with individual objects which may have their own mix-ins.


    # TBD - do we need to distinguish private/public methods

    set method_path {}
    #ruff
    # Search algorithm:
    #  - Filters are ignored. They may be invoked but are not considered
    #    implementation of the method itself.
    #  - The mixins of a class are searched even before the class itself
    #    as are the superclasses of the mixins.
    foreach mixin [info class mixins $class_name] {
        # We first need to check if the method name is in the public interface
        # for this class. This step is NOT redundant since a derived
        # class may unexport a method from an inherited class in which
        # case we should not have the inherited classes in the path
        # either.
        if {[lsearch -exact [info class methods $mixin -all -private] $method_name] < 0} {
            continue
        }

        set method_path [concat $method_path [get_ooclass_method_path $mixin $method_name]]
    }

    #ruff - next in the search path is the class itself
    if {[Tcl9]} {
        # In Tcl 9, -private behaves differently at least in 9.0b2
        # See https://core.tcl-lang.org/tcl/info/36e5517a6850c193
        if {[lsearch -exact [info class methods $class_name] $method_name] >= 0 ||
            [lsearch -exact [info class methods $class_name -private] $method_name] >= 0} {
            lappend method_path $class_name
        }
    } else {
        if {[lsearch -exact [info class methods $class_name -private] $method_name] >= 0} {
            lappend method_path $class_name
        }
    }

    #ruff - Last in the search order are the superclasses (in recursive fashion)
    foreach super [info class superclasses $class_name] {
        # See comment in mixin code above.
        if {[lsearch -exact [info class methods $super -all -private] $method_name] < 0} {
            continue
        }
        set method_path [concat $method_path [get_ooclass_method_path $super $method_name]]
    }


    #ruff
    # Returns an ordered list containing the classes that are searched
    # to locate a method for the specified class.
    return $method_path
}

proc ruff::private::locate_ooclass_method {class_name method_name} {
    # Locates the class that implements the specified method of a class
    # class_name - name of the class to which the method belongs
    # method_name - method name being searched for
    #
    # The matching class may implement the method itself or through
    # one of its own mix-ins or superclasses.
    #
    # Returns the name of the implementing class or an empty string
    # if the method is not implemented.

    # Note: we CANNOT just calculate a canonical search path for a
    # given class and then search along that for a class that
    # implements a method. The search path itself will depend on the
    # specific method being searched for due to the fact that a
    # superclass may not appear in a particular search path if a
    # derived class hides a method (this is just one case, there may
    # be others). Luckily, get_ooclass_method_path does exactly this.


    set class_path [get_ooclass_method_path $class_name $method_name]

    if {[llength $class_path] == 0} {
        return "";              # Method not found
    }

    # Now we cannot just pick the first element in the path. We have
    # to find the *last* occurrence of each class - that will decide
    # the priority order
    set order [dict create]
    set pos 0
    foreach path_elem $class_path {
        dict set order $path_elem $pos
        incr pos
    }

    return [lindex $class_path [lindex [lsort -integer [dict values $order]] 0] 0]
}


proc ruff::private::load_formatters {} {
    # Loads all available formatter implementations
    foreach formatter [formatters] {
        load_formatter $formatter
    }
}

proc ruff::private::load_formatter {formatter} {
    # Loads the specified formatter implementation
    variable ruff_dir
    if {$formatter ni [formatters]} {
        Abort "Unknown output format \"$formatter\"."
    }
    set class [namespace parent]::formatter::[string totitle $formatter]
    if {![info object isa class $class]} {
        uplevel #0 [list source [file join $ruff_dir formatter_${formatter}.tcl]]
    }
    return $class
}

proc ruff::document {namespaces args} {
    # Generates documentation for commands and classes.
    # namespaces - list of namespaces for which documentation is to be generated.
    # args - Options described below.
    # -autopunctuate BOOLEAN - If `true`, the first letter of definition
    #  descriptions (including parameter descriptions) is capitalized
    #  and a period added at the end if necessary.
    # -compact BOOLEAN - If `true`, documentation is generated in a more
    #  compact form if supported by the formatter. For the built-in HTML formatter
    #  this results in procedure and method details being placed in collapsed
    #  sections that can be expanded on demand.
    # -diagrammer DIAGRAMARGS - arguments to pass to `diagram` processor
    #  if none are specified in the diagram block header. Defaults to
    #  `kroci ditaa`
    # -excludeclasses REGEXP - If specified, any classes whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -excludeprocs REGEXP - If specified, any procedures whose names
    #  match `REGEXPR` will not be included in the documentation.
    # -format FORMAT - The output format. `FORMAT` defaults to `html`.
    # -hidenamespace NAMESPACE - By default, documentation generated by Ruff!
    #  includes namespace qualifiers in all class and proc names. It is possible
    #  to have the generated output leave out the namespace qualifers by adding
    #  the `-hidenamespace NAMESPACE` qualifier to the document generation
    #  commands. This will omit `NAMESPACE` in displayed program element names
    #  and provides a more visually pleasing output with less noise. However,
    #  it may result in ambiguities in case of names being present in more than
    #  one namespace. In particular, some formatters may not cross-link correctly
    #  in such cases.
    # -include LIST - Specifies which program elements are to be documented.
    #  `LIST` must be a list from one or both amongst `classes` or `procs`.
    #  Defaults to both.
    # -includeprivate BOOLEAN - if true private methods are also included
    #  in the generated documentation. Default is false.
    # -includesource BOOLEAN - if true, the source code of the
    #  procedure is also included. Default value is false.
    # -linkassets - if true, CSS and Javascript assets are linked. If false,
    #  they are embedded inline. If unspecified, defaults to `false` if the
    #  `-pagesplit` option is `none` and `true` otherwise. Only supported by the
    #  HTML formatter.
    # -locale STRING - sets the locale of the pre-defined texts in the generated
    #  outputs such as **Description** or **Return value** (Default `en`). To add a
    #  locale for a language, create a message catalog file in the `msgs`
    #  directory using the provided `de.msg` as a template. Only supported by the
    #  HTML formatter.
    # -makeindex BOOLEAN - if true, an index page is generated for classes
    #  and methods. Default value is true. Not supported by all formatters.
    # -navigation OPT - Controls navigation box behaviour when
    #  scrolling. If `scrolled`, the navigation box will scroll vertically
    #  along with the page. Thus it may not visible at all times. If
    #  `sticky`, the navigation box remains visible at all times.
    #  However, this requires the number of links in the box to fit on
    #  the page as they are never scrolled. Note that older browsers
    #  do not support stickiness and will resort to scrolling behaviour.
    #  box (see below). Only supported by the `html` formatter.
    #  (Default `scrolled`)
    # -onlyexports BOOLEAN - if true, only procs exported from namespaces
    #  are included.
    # -outdir DIRPATH - Specifies the output directory path. Defaults to the
    #  current directory.
    # -outfile FILENAME - Specifies the name of the output file.
    #  If the output is to multiple files, this is the name of the
    #  documentation main page. Other files will named accordingly by
    #  appending the namespace. Defaults to a name constructed from the first
    #  namespace specified.
    # -pagesplit SPLIT - if `none`, a single documentation file is produced.
    #  If `namespace`, a separate file is output for every namespace.
    # -preamble TEXT - Any text that should be appear at the beginning
    #  outside of any namespace documentation, for example an introduction
    #  or overview of a package. This shows up as the Start page content
    #  when used with the `-pagesplit namespace` option.
    #  `TEXT` is assumed to be in Ruff! syntax.
    # -preeval SCRIPT - a script to run before generating documentation. This
    #  is generally used from the command line to load the packages being
    #  documented.
    # -product PRODUCTNAME - the short name of the product. If unspecified, this
    #  defaults to the first element in $namespaces. This should be a short name
    #  and is used by formatters to identify the documentation set as a whole
    #  when documenting multiple namespaces.
    # -recurse BOOLEAN - if true, child namespaces are recursively
    #  documented.
    # -section SECTION - the section of the documentation where the pages should
    #  be located. Currently only used by the `nroff` formatter and defaults to
    #  `3tcl`.
    # -sortnamespaces BOOLEAN - If `true` (default) the namespaces are
    #  sorted in the navigation otherwise they are in the order passed in.
    # -title TITLE - This text is shown in a formatter-specific area on every
    #  generated page. The `nroff` formatter for manpages has only a limited
    #  space to display this so `TITLE` should be limited to roughly 50 characters
    #  if that formatter is to be used. If unspecified, it is constructed from
    #  the `-product`.
    # -version VERSION - The version of product being documented.
    #
    # The command generates documentation for one or more namespaces
    # and writes it out to file(s) as per the options shown above.
    # See [Documenting procedures], [Documenting classes] and
    # [Documenting namespaces] for details of the expected source
    # formats and the generation process.
    #

    variable gFormatter

    array set opts {
        -compact 0
        -excludeprocs {}
        -excludeclasses {}
        -format html
        -hidesourcecomments false
        -include {procs classes}
        -includeprivate false
        -includesource false
        -onlyexports false
        -preamble ""
        -recurse false
        -pagesplit none
        -sortnamespaces true
        -locale en
        -section 3tcl
        -preeval ""
        -diagrammer "kroki ditaa"
    }

    array set opts $args

    if {[info exists opts(-output)]} {
        error "Option -output is obsolete. Use -outdir and/or -outfile instead."
    }

    # Load any dependencies
    uplevel #0 $opts(-preeval)

    if {![info exists opts(-makeindex)]} {
        set opts(-makeindex) [expr {$opts(-pagesplit) ne "none"}]
    }
    if {$opts(-pagesplit) eq "none" && $opts(-makeindex)} {
        app::log_error "Option -makeindex ignored when -pagesplit is specified as none."
        set opts(-makeindex) false
    }
    if {![info exists opts(-linkassets)]} {
        set opts(-linkassets) [expr {$opts(-pagesplit) ne "none"}]
    }
    lappend args -linkassets $opts(-linkassets)

    if {![info exists opts(-product)]} {
        set opts(-product) [string trim [lindex $namespaces 0] :]
        lappend args -product $opts(-product)
    }
    if {![info exists opts(-title)]} {
        set opts(-title) [string totitle $opts(-product)]
        lappend args -title $opts(-title)
    }

    ::msgcat::mclocale $opts(-locale)

    namespace upvar private ProgramOptions ProgramOptions
    set ProgramOptions(-hidesourcecomments) $opts(-hidesourcecomments)
    if {$opts(-pagesplit) ni {none namespace}} {
        error "Option -pagesplit must be \"none\" or \"namespace\" "
    }
    set ProgramOptions(-pagesplit) $opts(-pagesplit)
    set ProgramOptions(-makeindex) $opts(-makeindex)
    set ProgramOptions(-diagrammer) $opts(-diagrammer)

    # Fully qualify namespaces
    set namespaces [lmap ns $namespaces {
        if {![string match ::* $ns]} {
            set ns "[string trimright [uplevel 1 {namespace current}] ::]::$ns"
        }
        if {![namespace exists $ns]} {
            error "Namespace $ns does not exist."
        }
        set ns
    }]
    if {[llength $namespaces] == 0} {
        error "At least one namespace needs to be specified."
    }

    set formatter [[load_formatter $opts(-format)] new]
    set gFormatter $formatter
    set ProgramOptions(-format) $opts(-format)

    # Determine output file paths
    array unset private::ns_file_base_cache
    if {![info exists opts(-outdir)]} {
        set opts(-outdir) [pwd]
    } else {
        set opts(-outdir) [file normalize $opts(-outdir)]
    }
    set ProgramOptions(-outdir) $opts(-outdir)

    if {![info exists opts(-outfile)]} {
        # Special cases  - :: -> "", ::foo::bar:: -> ::foo::bar
        set ns [string trimright [lindex $namespaces 0] :]
        if {$ns eq ""} {
            error "Option -outfile must be specified for namespace ::."
        }
        set opts(-outfile) [namespace tail $ns]
    }
    if {[file tail $opts(-outfile)] ne $opts(-outfile)} {
        error "Option -outfile must not include a path."
    }
    set private::output_file_base [file root $opts(-outfile)]
    set private::output_file_ext [file extension $opts(-outfile)]
    if {$private::output_file_ext in {{} .}} {
        set private::output_file_ext .[$formatter extension]
    }

    if {$opts(-recurse)} {
        set namespaces [namespace_tree $namespaces]
    }

    if {$opts(-preamble) ne ""} {
        # TBD - format of -preamble argument passed to formatters
        # is different so override what was passed in.
        lappend args -preamble [extract_docstring $opts(-preamble) ::]
    }
    reset_symbol_occurrence_counts
    set classprocinfodict [extract_namespaces $namespaces \
                               -excludeprocs $opts(-excludeprocs) \
                               -excludeclasses $opts(-excludeclasses) \
                               -onlyexports $opts(-onlyexports) \
                               -include $opts(-include) \
                               -includeprivate $opts(-includeprivate)]

    set docs [$formatter generate_document $classprocinfodict {*}$args]
    if {$opts(-makeindex)} {
        set docindex [$formatter generate_document_index]
        if {$docindex ne ""} {
            lappend docs -docindex $docindex
        }
    }

    $formatter copy_assets $ProgramOptions(-outdir)

    file mkdir $opts(-outdir)
    set output_files [list ]
    foreach {ns doc} $docs {
        set fn [private::ns_file_base $ns]
        set path [file join $opts(-outdir) $fn]
        lappend output_files $path
        set fd [open $path w]
        fconfigure $fd -encoding utf-8
        if {$opts(-format) eq "nroff"} {
            # On Unix, nroff, or at least tbl, does not recognize directives
            # with CRLF line endings. So always force LF for nroff.
            fconfigure $fd -translation lf
        }
        if {[catch {
            puts $fd $doc
        } msg]} {
            close $fd
            error $msg
        }
        close $fd
    }

    $formatter finalize $opts(-outdir) $output_files
    $formatter destroy

    return
}

proc ruff::formatters {} {
    # Gets the available output formatters.
    #
    # The returned values can be passed to [document] to generate
    # documentation in that format.
    #
    # Returns a list of available formatters.
    return {html markdown nroff sphinx}
}

# TBD - where is this used
proc ruff::private::wrap_text {text args} {
    # Wraps a string such that each line is less than a given width
    # and begins with the specified prefix.
    # text - the string to be reformatted
    # The following options may be specified:
    # -width INTEGER - the maximum width of each line including the prefix 
    #  (defaults to 60)
    # -prefix STRING - a string that every line must begin with. Defaults
    #  to an empty string.
    # -prefix1 STRING - prefix to be used for the first line. If unspecified
    #  defaults to the value for the -prefix option if specified
    #  and an empty string otherwise.
    #
    # The given text is transformed such that it consists of
    # a series of lines separated by a newline character
    # where each line begins with the specified prefix and
    # is no longer than the specified width.
    # Further each line is filled with as many characters
    # as possible without breaking a word across lines.
    # Blank lines and leading and trailing spaces are removed.
    #
    # Returns the wrapped and indented text

    set opts [dict merge [dict create -width 60 -prefix ""] $args]

    if {![dict exists $opts -prefix1]} {
        dict set opts -prefix1 [dict get $opts -prefix]
    }

    set prefix [dict get $opts -prefix]
    set prefix1 [dict get $opts -prefix1]

    set width [dict get $opts -width]
    # Reduce the width by the longer prefix length
    if {[string length $prefix] > [string length $prefix1]} {
        incr width  -[string length $prefix]
    } else {
        incr width  -[string length $prefix1]
    }

    # Note the following is not optimal in the sense that
    # it is possible some lines could fit more words but it's
    # simple and quick.

    # First reformat
    set text [textutil::adjust::indent \
                  [::textutil::adjust::adjust $text -length $width] \
                  $prefix]

    # Replace the prefix for the first line. Note that because of
    # the reduction in width based on the longer prefix above,
    # the max specified width will not be exceeded.
    return [string replace $text 0 [expr {[string length $prefix]-1}] $prefix1]
}


source [file join $::ruff::private::ruff_dir formatter.tcl]
source [file join $::ruff::private::ruff_dir diagram.tcl]

################################################################
#### Application overrides

# The app namespace is for commands the application might want to
# override
namespace eval ruff::app {
    namespace export {[a-z]*}
}


proc ruff::app::log_error {msg} {
    # Stub function to log Ruff! errors.
    # msg - the message to be logged
    #
    # When Ruff! encounters errors, it calls this command to
    # notify the user. By default, the command writes $msg
    # to stderr output. An application using the ruff package
    # can redefine this command after loading ruff.
    puts stderr "$msg"
}

proc ruff::Abort {msg} {
    # Log Ruff! error and exit.
    # msg - the message to be logged
    #
    ruff::app::log_error $msg
    exit 1
}

package provide ruff $::ruff::version

# If we are the main script, accept commands.
if {[info exists argv0] &&
    [file dirname [file normalize [info script]/...]] eq [file dirname [file normalize $argv0/...]]} {
    if {[catch {
        ruff::document {*}$::argv
    } result]} {
        puts stderr $result
        puts stderr $::errorInfo
    } else {
        if {$result ne ""} {
            puts stdout $result
        }
    }
}
