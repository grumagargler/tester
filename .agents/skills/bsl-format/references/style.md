# Project BSL Style

Sources checked (representative):
- /home/dmitry/git/n5/src/CommonModules/DocumentPresenter/Module.bsl
- /home/dmitry/git/n5/src/CommonModules/PaymentsTable/Module.bsl
- /home/dmitry/git/n5/src/Documents/Invoice/ObjectModule.bsl
- /home/dmitry/git/n5/src/Documents/CashReceipt/ManagerModule.bsl
- /home/dmitry/git/n5/src/CommonModules/Output/Module.bsl

## Keywords and casing
- Use lowercase for control-flow and other keywords: procedure, function, endprocedure, endfunction, if, then, elsif, else, endif, for each, enddo, while, do, return, continue, break, and, or, not, true, false, undefined, null, new, var, export, val.
- Use `elsif` (not `elseif` or `ElseIf`).

## Indentation
- Indent with tabs (1 tab per block). Do not indent with spaces.
- Preprocessor and region directives at column 1: #if, #else, #endif, #region, #endregion.
- Attribute directives at column 1: &AtServer, &AtClient, etc.

## Spacing
- Space before `(` in calls and control structures: Foo ( Bar ), if ( cond ) then, while ( true ) do.
- Space inside parentheses around parameters: Foo ( Bar, Baz ). For empty calls: Foo ().
- Spaces around binary operators and after commas.
- Spaces around indexers: array [ index ].
- Ternary operator: ? ( cond, a, b ) (space after ?).

## Semicolons
- End statements with semicolons.

## Line breaks / wrapping
- When wrapping long conditions or calls, continue on the next line and indent one extra tab; place `or`/`and` at the start of the continuation line.

## Blank lines
- Prefer a single blank line after a routine signature and before endprocedure/endfunction.
- Keep a single blank line between routines.

## Comments and query strings
- Line comments use //; inline comments are preceded by a space before //.
- Query strings use the `|` prefix on each line; keep `|` at the start of the string line, aligned with surrounding query blocks.

## Outliers
- n5/src/DataProcessors/StandardEventLog/... and some test scripts use a different style (PascalCase keywords, no spaces in calls).
- Preserve the file's existing style when it clearly follows that outlier pattern, unless explicitly asked to normalize to the project default.

## EDT formatter settings (source of truth)
File: n5/.settings/com.e1c.g5.v8.dt.formatter.bsl.prefs
Key values:
- spacesForTabs=false (tabs for indent)
- indentMethodInternal=true
- noindent_preprocessor=true
- alwaysEndWithSemicolon=true
- whitespaceMethodParamsDelimited=true
- invocationEmptyParamsDelimited=true
- autowrapBinary=indent_on_wrap
- autowrapInvocation=indent_on_wrap
- autowrapMethodParameters=indent_on_wrap
