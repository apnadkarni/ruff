# Copyright (c) 2026, Ashok P. Nadkarni
# All rights reserved.
# See the file LICENSE in the source root directory for license.
#
# Implements the Analyser class which extracts documentation from namespaces
#

namespace eval ruff::private {}
catch {ruff::Collector destroy}
oo::class create ruff::Collector {

    # Dictionary mapping namespaces to their content dictionaries
    # Keys:
    #  Procs - dictionary of procs indexed by fully qualified normalized name
    #  Classes - dictionary of classes indexed by fully qualified normalized name
    #  ExposedProcsRe - regexp denoting public procs (optional)
    #  HiddenProcsRe  - regexp denoting public procs (optional)
    #  ExposedClassesRe - regexp denoting public procs (optional)
    #  HiddenClassesRe  - regexp denoting public procs (optional)
    #
    variable Namespaces

    constructor {} {
        set ns [namespace qualifiers [info object class [self]]]
        namespace path [linsert [namespace path] end $ns ${ns}::private]
        set Namespaces [dict create]
    }

    method addNamespaces {args} {
        foreach fnns [lmap ns $args {
            fqn! $ns
            fnn $ns
        }] {
            if {![namespace exists $fnns]} {
                error "Namespace $fnns does not exist."
            }
            my Collect $fnns
        }
    }

    method getNamespace {ns} {
        fqn! $ns
        set fnn [fnn $ns]
        return [dict get $Namespaces $fnn]
    }

    method getClasses {fqns} {
        
    }

    method getProcNames {ns {pat *}} {
        # Returns a list of fully qualified names of all procedures defined in
        # the passed namespace.
        #   ns - namespace name. If not fully qualified, it is treated as relative
        #        to the caller.
        #   pat - if specified, only those procedure names matching $pat are
        #        returned.
        set fnns [fnn $ns]
        return [info procs $pat]
    }

    method getProcs {fnns audience} {
        # Returns a dictionary keyed by procedure names with the values
        # being dictionaries containing detailed information for the procedure.
        #   fnns - fully normalized namespace
        #   audience - one of `public` or `internal`
        # The dictionaries returned as element values have the following keys:
        #   Name - fully qualified name of the procedure
        #   ParamNames - list of parameter names
        #   ParamDefaults - dictionary mapping parameter names to default values
        #   Body - body of the procedure
        #   Public - boolean indicating if the procedure is exported by
        #     the namespace.

    }

    method HiddenProc? {fnn} {
        # Returns 1 if the passed procedure name is hidden.
        #  fnn - fully normalized namespace containing the name
        set fnns [ns_qualifiers $fnn]
        set name [namespace tail $fnn]
        if {[regexp [dict get $Namespaces $fnns HiddenProcsRe] $name]} {
            return 1
        }
        if {[dict exists $Namespaces $fnns ExportedProcs $name]} {
            return 0
        }
        return [regexp [dict get $Namespaces $fnns PublishedProcsRe] $name]
    }

    method CollectProc {fnn} {
        # Returns the metadata for the specified procedure
        #   fnn - fully normalized procedure name
        # The returned dictionary has the following keys:
        #   Name - Unqualified name of procedure
        #   Body - Procedure body
        #   ParamNames - Names of parameters
        #   ParamDefaults - dictionary mapping parameter names to default values
        #   Hidden - 1 if procedure is hidden, else 0
        #   BuiltIn - 1 if procedure is a Tcl built-in, else 0
        #   Type - set to `proc` indicating it is a procedure

        set param_names [info args $fnn]
        set param_defaults {}
        foreach param_name $param_names {
            if {[info default $fnn $param_name value]} {
                dict set param_defaults $param_name $value
            }
        }
        return [dict create \
                    Name [namespace tail $fnn] \
                    Body [info body $fnn] \
                    ParamNames $param_names \
                    ParamDefaults $param_defaults \
                    Hidden [my HiddenProc? $fnn] \
                    Type proc \
                    BuiltIn [is_builtin $fnn]]
    }

    method CollectProcs fnns {
        # Collects metadata about all procedures defined in a namespace.
        #  fnns - fully normalized namespace name
        # The $Namespaces dictionary `Procs` entry for $fnns is initialized
        # with a dictionary whose keys are names of the procs in the namespace.
        # The corresponding value is a itself a dictionary with the keys:

        # A procedure may be published or hidden. This is determined as per the
        # following rules.
        #  1. If the namespace has a `_ruff(HiddenProcRe)` variable with a
        #  non-empty value, the value is treated as a regular expression and
        #  any procedure that matches it is treated as hidden.
        #  2. Any procedure exported from the namespace is treated as published.
        #  3. If the namespace has a `_ruff(PublishedProcsRe)` variable with a
        #  non-empty value, the value is treated as a regular expression and
        #  any procedure that matches it is treated as published.
        #  4. If a variable is not defined, it defaults to `.*`.
        #  5. If variable is defined with an empty value, it will be treated as
        #  never matching.

        foreach proc_fnn [info procs [ns_canonicalize ${fnns}::*]] {
            set proc_info [my CollectProc $proc_fnn]
            dict set Namespaces $fnns Procs $proc_fnn [my CollectProc $proc_fnn]
        }
    }

    method CollectSubcmd {fnn ens_fnn subcmd builtin hidden} {
        # Returns the metadata for an ensemble subcommand.
        #   fnn - fully normalized name of ensemble subcommand implementation
        #   ens_fnn - fully normalized name of parent ensemble
        #   subcmd - subcommand
        #   builtin - parent ensemble is built-in
        #   hidden - parent ensemble is hidden
        # The returned dictionary has the following keys:
        #   Name - Unqualified name of procedure
        #   Body - Procedure body
        #   ParamNames - Names of parameters
        #   ParamDefaults - dictionary mapping parameter names to default values
        #   Hidden - 1 if procedure is hidden, else 0
        #   BuiltIn - 1 if procedure is a Tcl built-in, else 0
        #   Type - set to `subcommand` indicating it is an ensemble subcommand
        set param_names [info args $fnn]
        set param_defaults {}
        foreach param_name $param_names {
            if {[info default $fnn $param_name value]} {
                dict set param_defaults $param_name $value
            }
        }
        return [dict create \
                    Name "$ens_fnn $subcmd" \
                    Body [info body $fnn] \
                    ParamNames $param_names \
                    ParamDefaults $param_defaults \
                    Hidden $hidden \
                    Ensemble $ens_fnn \
                    Type subcommand \
                    BuiltIn $builtin]
    }

    method CollectEnsembles {fnns} {
        # Collects metadata about all ensembles defined in a namespace.
        #  fnns - fully normalized namespace name
        #
        # Only ensemble commands that satisfy the following are supported:
        # - the ensemble implementation must be in the form of Tcl procedures
        # - the ensemble must not have been configured with the `-parameters`
        #   option as that changes location of arguments
        #
        # Ensembles in the namespace are added to the `Procs` entry in the
        # the $Namespaces dictionary. The key is the FNN of the ensemble and
        # it value is a dictionary with the following keys:
        #   Name - Unqualified name of the ensemble
        #   SubCommands - a dictionary mapping the ensemble subcommand names
        #     to their procedure implementations.
        #   Hidden - 1 if procedure is hidden, else 0
        #   BuiltIn - 1 if procedure is a Tcl built-in, else 0
        #   Type - set to `ensemble`
        #
        # The procedures implementing the subcommands are also added to the
        # `Procs` key. The entries are dictionaries as described in
        # [CollectSubcmd].

        set exposed_re [dict get $Namespaces $fnns PublishedProcsRe]
        set hidden_re [dict get $Namespaces $fnns HiddenProcsRe]

        set exports [dict get $Namespaces $fnns ExportedProcs]

        foreach ens [info commands [ns_canonicalize ${fnns}::*]] {
            if {![namespace ensemble exists $ens]} {
                continue
            }
            array set ens_config [namespace ensemble configure $ens]
            if {[llength $ens_config(-parameters)]} {
                app::log_error "Skipping ensemble command $ens (non-empty -parameters attributes not supported)."
                continue
            }

            # Subcommands may be configured simply listed, mapped to another
            # command, or all exports

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

            set is_builtin [is_builtin $ens]
            set is_hidden [my HiddenProc? $ens]
            set ens_subcmds [dict create ]; # Will hold summary of subcommands
            foreach cmd $cmds {
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
                if {[catch {
                    my CollectSubcmd $real_cmd $ens $cmd $is_builtin $is_hidden
                } result]} {
                    app::log_error "Could not retrieve information for \"$real_cmd\"\
                            implementing ensemble command \"$ens $cmd\": $result"
                    continue
                }
                # Overwrite the command name with the ensemble form
                dict set Namespaces $fnns Procs $real_cmd $result
                dict set ens_subcmds $cmd $real_cmd
            }

            # Now add dummy entry for the ensemble command itself
            dict set Namespaces $fnns Procs $ens \
                [dict create \
                     Name [namespace tail $ens] \
                     SubCommands $ens_subcmds \
                     Hidden $is_hidden \
                     Type ensemble \
                     BuiltIn $is_builtin]
        }
    }

    method CollectClasses {fnn} {
        
    }

    method Collect {fnns} {
        # Analyses the given namespace.
        #  fnns - fully normalized namespace name
        # The $Namespaces member is updated with the namespace information.

        dict unset Namespaces $fnns

        # Set default per-namespace options
        dict set Namespaces $fnns PublishedProcsRe {.+}
        dict set Namespaces $fnns HiddenProcsRe {a^} ; # Will not match anything
        dict set Namespaces $fnns PublishedClassesRe {.+}
        dict set Namespaces $fnns HiddenClassesRe {a^} ; # Will not match anything

        # Validate namespace ruff options so mistyping is reported.
        namespace upvar $fnns  _ruff ruff_opts
        if {[info exists ruff_opts]} {
            foreach {opt val} [array get ruff_opts] {
                switch $opt {
                    PublishedProcsRe -
                    PublishedClassesRe {
                        if {$val eq ""} {
                            set val {a^}; # Should not match anything
                        }
                    }
                    HiddenProcsRe -
                    HiddenClassesRe {
                    }
                    default {
                        error "Unknown ruff option name \"$opt\"."
                    }
                }
                dict set Namespaces $fnns $opt $val
            }
        }

        # Note what procs are exported as a dictionary for quicker lookup.
        # These are unqualified names.
        set exports [dict create]
        foreach export [namespace eval $fnns {namespace export}] {
            dict create exports $export $export
        }
        dict set Namespaces $fnns ExportedProcs $exports

        my CollectProcs $fnns
        my CollectEnsembles $fnns
        my CollectClasses $fnns

        # Namespace specific settings
        if {[info exists ${fnns}::ruff(Preamble)]} {
            dict set Namespaces $fnns Preamble [set ${fnns}::_ruff(Preamble)]
        } elseif {[info exists ${fnns}::_ruff_preamble]} {
            dict set Namespaces $fnns Preamble [set ${fnns}::_ruff_preamble]
        } else {
            dict set Namespaces $fnns Preamble ""
        }
        if {[info exists ${fnns}::_ruff(Options)]} {
            dict set Namespaces $fnns Options [set ${fnns}::_ruff(Options)]
        } else {
            dict set Namespaces $fnns Options [dict create]
        }
    }
}
