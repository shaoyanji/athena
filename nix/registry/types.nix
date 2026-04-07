{
  registryEntry = {
    name = "string";
    source = "path-or-fetch-spec";
    startupView = "bool";
    kind = "entry-kind";
  };

  startupView = {
    name = "string";
    entries = "list";
  };

  profile = {
    name = "string";
    description = "string";
    default = "bool";
    shell = "devShell-name";
    packages = "list";
    tools = "list";
    skills = "list";
    startupViews = "list";
  };

  package = {
    name = "string";
    description = "string";
    output = "flake-package-name";
    kind = "package-kind";
  };

  tool = {
    name = "string";
    description = "string";
    kind = "tool-kind";
    package = "optional-package-name";
  };

  skill = {
    name = "string";
    description = "string";
    portability = "portable|runtime-local|conceptual";
    status = "real|seed|planned";
  };
}
