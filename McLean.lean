module

-- Intentionally empty, save for the `module` header above: the module-system audit
-- (`lake exe module-system`) enumerates this root alongside every `McLean/**/*.lean` file
-- and requires each to opt into the module system, with no exemption for an empty file.
--
-- The `lean_lib` glob `McLean.*` in lakefile.toml determines the library's contents, and
-- both audits (`lake exe axioms`, `lake exe module-system`) enumerate the source tree
-- themselves. Nothing imports this file, so adding a module never requires editing it and
-- two PRs that each add a module never conflict here.
