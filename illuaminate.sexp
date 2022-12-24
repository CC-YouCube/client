; -*- mode: Lisp;-*-

;; Folders, files, or patterns to include.
(sources /)

;; Overrides for a specific pattern, file or directory. These are matched
;; in order, so later `at` blocks overwrite earlier ones.
(at /
 ;; Modifications to make to the linter set. For instance, `+all -var:unused`
 ;; will enable all warnings but var:unused.
 ;; Fuck the Police ;)
 (linters -format:table-trailing -doc:undocumented -var:unused -doc:undocumented-arg -var:unused-arg -doc:unresolved-reference)
 
 ;; Control how the illuaminate linter works.
 (lint
   ;; Modules which may have members which are not documented. Modules within this list are skipped by the `var:unresolved-member` warning.
   (dynamic-modules)
   
   ;; List of global variables
   (globals :max
      textutils
      term
      colors
      http
      peripheral
      read
      settings
      fs
      printError
      shell
      parallel
      sleep
      keys
      ;; CraftOS-PC
      periphemu
      config
    )
   
   ;; Whether tables entries should be separated by a comma (',') or semicolon (';').
   (table-separator comma)
   
   ;; The preferred quote mark (' or ").
   (quote double)
   
   ;; Allow setting globals on the top-level of the module.
   (allow-toplevel-global false)
   
   ;; Allow parenthesis which clarify syntactic ambiguities.
   (allow-clarifying-parens false)
   
   ;; Allow empty if or elseif blocks.
   (allow-empty-if false)
   
   ;; Spaces within bracketed terms, such as tables or function calls.
   (bracket-spaces
     ;; Spaces within call arguments.
     (call consistent)
     
     ;; Spaces within function arguments.
     (function-args consistent)
     
     ;; Spaces within parenthesised expressions.
     (parens consistent)
     
     ;; Spaces within tables.
     (table consistent)
     
     ;; Spaces within table indexes.
     (index consistent))))
;; Controls documentation generation.
(doc
  ;; The path(s) where modules are located. This is used for guessing the module name of files, it is ignored when an explicit @module annotation is provided.
  (library-path client/lib)
  
  ;; A list of custom module kinds and their display names.
  (module-kinds)
  
  ;; HTML-specific properties
  (site
    ;; A title to display for the site
    (title "YouCube")
    
    ;; The path to a logo to display for this site.
    (logo :none)
    
    ;; A JavaScript file which should be included in the generated docs. This is appended to the default scripts.
    (scripts :none)
    
    ;; A JavaScript file which should be included in the generated docs. This is appended to the default styles.
    (styles :none)
    
    ;; A link to an website containing hosting code. The URL is a templated string, where `${foo}` is replaced by the contents of `foo` variable.
    ;; This accepts the following variables:
    ;;  - path: The documented source's path, relative to the project root.
    ;;  - sline/eline: The start and end line of the variable's definition.
    ;;  - commit: The current commit hash, as returned by git rev-parse HEAD.
    (source-link :none)
    
    ;; The full URL the site is hosted on (e.g. https://example.com/docs).
    (url :none)
    
    ;; Additional content to be included in the <head> of the generated pages.
    (head :none))
  
  ;; A path to an index file.
  (index :none)
  
  ;; The folder to write to
  (destination doc)
  
  ;; Whether to create an index.json file, with a dump of all terms. This may be useful for querying externally.
  (json-index true))

(at /client/lib/semver.lua(linters -all))
(at /client/lib/argparse.lua(linters -all))
